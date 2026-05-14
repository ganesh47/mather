#!/usr/bin/env python3
"""Sync TestFlight feedback from App Store Connect into GitHub issues."""

from __future__ import annotations

import json
import os
import sys
import time
import urllib.error
import urllib.parse
import urllib.request
from dataclasses import dataclass
from typing import Any

import jwt


APP_STORE_CONNECT_API_BASE = "https://api.appstoreconnect.apple.com"
GITHUB_API_BASE = "https://api.github.com"
DEFAULT_ISSUE_LABELS = ["source:testflight", "type:feedback"]
CRASH_ISSUE_LABELS = ["source:testflight", "type:bug"]
LABEL_COLORS = {
    "source:testflight": "0e8a16",
    "type:feedback": "1d76db",
    "type:bug": "d73a4a",
}
TRANSIENT_HTTP_STATUS_CODES = {500, 502, 503, 504}
DEFAULT_HTTP_RETRIES = 3


@dataclass(frozen=True)
class Config:
    asc_app_id: str
    asc_issuer_id: str
    asc_key_id: str
    asc_private_key: str
    github_token: str
    github_repository: str

    @property
    def github_owner(self) -> str:
        return self.github_repository.split("/", 1)[0]

    @property
    def github_repo(self) -> str:
        return self.github_repository.split("/", 1)[1]


def require_env(name: str) -> str:
    value = os.environ.get(name, "").strip()
    if not value:
        raise RuntimeError(f"Missing required environment variable: {name}")
    return value


def load_config() -> Config:
    return Config(
        asc_app_id=require_env("APP_STORE_CONNECT_APP_ID"),
        asc_issuer_id=require_env("APP_STORE_CONNECT_ISSUER_ID"),
        asc_key_id=require_env("APP_STORE_CONNECT_KEY_ID"),
        asc_private_key=require_env("APP_STORE_CONNECT_PRIVATE_KEY").replace("\\n", "\n"),
        github_token=require_env("GITHUB_TOKEN"),
        github_repository=require_env("GITHUB_REPOSITORY"),
    )


def build_asc_token(config: Config) -> str:
    now = int(time.time())
    payload = {
        "iss": config.asc_issuer_id,
        "aud": "appstoreconnect-v1",
        "iat": now,
        "exp": now + 19 * 60,
    }
    headers = {
        "alg": "ES256",
        "kid": config.asc_key_id,
        "typ": "JWT",
    }
    return jwt.encode(payload, config.asc_private_key, algorithm="ES256", headers=headers)


def request_json(
    url: str,
    *,
    method: str = "GET",
    headers: dict[str, str] | None = None,
    payload: dict[str, Any] | None = None,
    retries: int = DEFAULT_HTTP_RETRIES,
    retry_statuses: set[int] | None = None,
) -> Any:
    body = None
    request_headers = {"Accept": "application/json"}
    if headers:
        request_headers.update(headers)
    if payload is not None:
        body = json.dumps(payload).encode("utf-8")
        request_headers["Content-Type"] = "application/json"

    transient_statuses = retry_statuses or TRANSIENT_HTTP_STATUS_CODES
    last_error: urllib.error.HTTPError | None = None
    for attempt in range(retries + 1):
        request = urllib.request.Request(url, data=body, headers=request_headers, method=method)
        try:
            with urllib.request.urlopen(request) as response:
                content = response.read()
            if not content:
                return None
            return json.loads(content)
        except urllib.error.HTTPError as exc:
            last_error = exc
            if exc.code not in transient_statuses or attempt >= retries:
                details = exc.read().decode("utf-8", errors="replace")
                raise RuntimeError(f"{method} {url} failed: {exc.code} {details}") from exc
            print(
                f"{method} request failed with transient HTTP {exc.code}; "
                f"retrying ({attempt + 1}/{retries})",
                file=sys.stderr,
            )
            time.sleep(2 ** attempt)

    if last_error is not None:
        details = last_error.read().decode("utf-8", errors="replace")
        raise RuntimeError(f"{method} {url} failed: {last_error.code} {details}") from last_error
    return None


def asc_get(config: Config, path_or_url: str, params: dict[str, str] | None = None) -> Any:
    if path_or_url.startswith("http://") or path_or_url.startswith("https://"):
        url = path_or_url
    else:
        url = f"{APP_STORE_CONNECT_API_BASE}{path_or_url}"
    if params:
        query = urllib.parse.urlencode(params)
        url = f"{url}?{query}"
    return request_json(
        url,
        headers={"Authorization": f"Bearer {build_asc_token(config)}"},
    )


def github_request(
    config: Config,
    path: str,
    *,
    method: str = "GET",
    payload: dict[str, Any] | None = None,
) -> Any:
    url = f"{GITHUB_API_BASE}{path}"
    return request_json(
        url,
        method=method,
        payload=payload,
        headers={
            "Authorization": f"Bearer {config.github_token}",
            "X-GitHub-Api-Version": "2022-11-28",
        },
    )


def ensure_labels(config: Config, labels: list[str]) -> None:
    for label in labels:
        try:
            github_request(
                config,
                f"/repos/{config.github_repository}/labels",
                method="POST",
                payload={
                    "name": label,
                    "color": LABEL_COLORS.get(label, "ededed"),
                },
            )
            print(f"Created label: {label}")
        except RuntimeError as exc:
            if "already_exists" in str(exc) or "Validation Failed" in str(exc):
                continue
            raise


def fetch_feedback_collection(config: Config, path: str) -> list[dict[str, Any]]:
    params = {
        "include": "build",
        "limit": "200",
        "sort": "-createdDate",
    }
    items: list[dict[str, Any]] = []
    next_url: str | None = path

    while next_url:
        response = asc_get(config, next_url, params if next_url == path else None)
        included = response.get("included", [])
        included_map = {(entry["type"], entry["id"]): entry for entry in included}
        for entry in response.get("data", []):
            entry["_included_map"] = included_map
            items.append(entry)
        next_url = response.get("links", {}).get("next")

    return items


def get_related_resource(
    feedback: dict[str, Any], relationship_name: str
) -> dict[str, Any] | None:
    relation = feedback.get("relationships", {}).get(relationship_name, {})
    related = relation.get("data")
    if not related:
        return None
    return feedback.get("_included_map", {}).get((related["type"], related["id"]))


def first_non_empty(*values: Any) -> str | None:
    for value in values:
        if isinstance(value, str) and value.strip():
            return value.strip()
    return None


def list_existing_feedback_issues(config: Config) -> dict[str, dict[str, Any]]:
    feedback_issues: dict[str, dict[str, Any]] = {}
    page = 1

    while True:
        issues = github_request(
            config,
            (
                f"/repos/{config.github_repository}/issues"
                f"?state=all&per_page=100&page={page}&labels=source:testflight"
            ),
        )
        if not issues:
            break

        for issue in issues:
            if "pull_request" in issue:
                continue
            body = issue.get("body") or ""
            marker = "<!-- ASC Feedback ID: "
            start = body.find(marker)
            if start == -1:
                continue
            start += len(marker)
            end = body.find(" -->", start)
            if end == -1:
                continue
            feedback_id = body[start:end].strip()
            if feedback_id:
                feedback_issues[feedback_id] = issue

        if len(issues) < 100:
            break
        page += 1

    return feedback_issues


def list_existing_feedback_ids(config: Config) -> set[str]:
    return set(list_existing_feedback_issues(config))


def build_issue_title(feedback: dict[str, Any], kind: str) -> str:
    feedback_id = feedback["id"]
    build = get_related_resource(feedback, "build") or {}
    build_attrs = build.get("attributes", {})
    build_number = first_non_empty(build_attrs.get("version"))
    title = f"TestFlight {kind} feedback {feedback_id}"
    if build_number:
        title += f" (build {build_number})"
    return title


def redact_for_privacy(value: Any) -> str | None:
    if not isinstance(value, str):
        return None
    trimmed = value.strip()
    if not trimmed:
        return None
    lowered = trimmed.lower()
    if "@" in trimmed or any(token in lowered for token in ["iphone", "ipad", "ios ", "ipados", "device", "serial", "identifier", "email"]):
        return "_redacted for privacy_"
    return trimmed


def extract_metadata(attrs: dict[str, Any], build_attrs: dict[str, Any]) -> dict[str, str]:
    metadata = {
        "iOS version": first_non_empty(
            attrs.get("osVersion"),
            attrs.get("operatingSystemVersion"),
            attrs.get("deviceOsVersion"),
        ) or "_unknown_",
        "Device model": redact_for_privacy(
            first_non_empty(
                attrs.get("deviceModel"),
                attrs.get("deviceClass"),
                attrs.get("deviceType"),
            )
        ) or "_unknown_",
        "Locale": first_non_empty(attrs.get("locale"), attrs.get("language")) or "_unknown_",
        "App version": first_non_empty(attrs.get("appVersion"), build_attrs.get("appVersionString")) or "_unknown_",
        "Build number": first_non_empty(build_attrs.get("version"), attrs.get("buildVersion")) or "_unknown_",
    }
    return metadata


def summarize_crash_context(attrs: dict[str, Any]) -> list[str]:
    lines: list[str] = []

    crash_type = first_non_empty(
        attrs.get("crashType"),
        attrs.get("type"),
        attrs.get("exceptionType"),
    )
    if crash_type:
        lines.append(f"- Crash type: `{crash_type}`")

    signal = first_non_empty(attrs.get("signal"), attrs.get("exceptionSignal"))
    if signal:
        lines.append(f"- Signal: `{signal}`")

    fault_module = redact_for_privacy(
        first_non_empty(attrs.get("faultingModule"), attrs.get("bundleIdentifier"))
    )
    if fault_module:
        lines.append(f"- Faulting module: {fault_module}")

    incident = redact_for_privacy(first_non_empty(attrs.get("incidentId"), attrs.get("diagnosticId")))
    if incident:
        lines.append(f"- Crash incident id: {incident}")

    if not lines:
        lines.append("- Apple did not expose structured crash fields in this payload beyond the submission record.")

    return lines


def fetch_crash_log_text(config: Config, feedback_id: str) -> str | None:
    """Fetch a beta feedback crash log when App Store Connect exposes one."""
    endpoints = [
        f"/v1/betaFeedbackCrashSubmissions/{feedback_id}/crashLog",
    ]
    for endpoint in endpoints:
        try:
            response = asc_get(config, endpoint)
        except RuntimeError as exc:
            print(f"Crash log unavailable for feedback {feedback_id}: {exc}")
            continue
        data = response.get("data") if isinstance(response, dict) else None
        if not isinstance(data, dict):
            continue
        attrs = data.get("attributes", {})
        log_text = first_non_empty(
            attrs.get("logText"),
            attrs.get("text"),
            attrs.get("content"),
        )
        if log_text:
            return log_text
    return None


def _sanitize_crash_log_fragment(value: str) -> str:
    """Keep crash snippets useful while dropping addresses/UUID-like values."""
    import re

    sanitized = re.sub(r"0x[0-9A-Fa-f]+", "0x…", value.strip())
    sanitized = re.sub(
        r"\b[0-9A-Fa-f]{8}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{12}\b",
        "<uuid>",
        sanitized,
    )
    sanitized = re.sub(r"/[^\s]+", "<path>", sanitized)
    return sanitized[:240]


def summarize_crash_log_text(log_text: str, app_module: str = "Mather") -> list[str]:
    """Return a privacy-safe, short crash summary from raw ASC crash log text.

    The raw log can contain device and tester-adjacent diagnostics, so only
    exception/termination lines and the first app-module stack frames are kept.
    """
    lines = [line.rstrip() for line in log_text.splitlines()]
    summary: list[str] = []

    for prefix in ["Exception Type:", "Exception Codes:", "Termination Reason:"]:
        match = next((line for line in lines if line.strip().startswith(prefix)), None)
        if match:
            summary.append(f"- {prefix[:-1]}: `{_sanitize_crash_log_fragment(match.split(':', 1)[1])}`")

    crashed_thread = next(
        (line.strip() for line in lines if line.strip().lower().startswith("thread") and "crashed" in line.lower()),
        None,
    )
    if crashed_thread:
        summary.append(f"- Crashed thread: `{_sanitize_crash_log_fragment(crashed_thread)}`")

    app_frames: list[str] = []
    for line in lines:
        stripped = line.strip()
        # Only keep actual numeric stack frames, not process metadata such as
        # "Process: Mather", "Path:", "Identifier:", or binary image lines.
        parts = stripped.split()
        if len(parts) < 4 or not parts[0].isdigit() or parts[1] != app_module:
            continue
        frame_no = parts[0]
        module = parts[1]
        symbol = " ".join(parts[3:])
        app_frames.append(f"  - frame {frame_no} `{module}`: `{_sanitize_crash_log_fragment(symbol)}`")
        if len(app_frames) >= 6:
            break

    if app_frames:
        summary.append("- Top app frames:")
        summary.extend(app_frames)

    return summary


def build_crash_log_summary_section(config: Config, feedback_id: str) -> list[str]:
    log_text = fetch_crash_log_text(config, feedback_id)
    if not log_text:
        return []
    summary = summarize_crash_log_text(log_text)
    if not summary:
        return []
    return [
        "## Privacy-safe crash log summary",
        "<!-- ASC Crash Log Summary -->",
        *summary,
        "",
        "Raw App Store Connect crash diagnostics are intentionally not copied into GitHub.",
        "",
    ]


def _crash_log_summary_text(section: list[str]) -> str:
    return "\n".join(section).rstrip()


def _replace_existing_crash_log_summary(body: str, replacement: str) -> str | None:
    heading = "## Privacy-safe crash log summary"
    marker = "<!-- ASC Crash Log Summary -->"
    start = body.find(heading)
    if start == -1 or marker not in body[start:]:
        return None

    next_heading = body.find("\n## ", start + len(heading))
    if next_heading == -1:
        return body[:start].rstrip() + "\n\n" + replacement + "\n"
    return body[:start].rstrip() + "\n\n" + replacement + "\n" + body[next_heading:]


def _has_feature_level_app_frame(summary_text: str) -> bool:
    feature_tokens = [
        "AngleCannon",
        "MotionService",
        "GameplayStage",
        "AppModel",
        "LabView",
        "BondBlast",
        "SoundDetection",
    ]
    return any(token in summary_text for token in feature_tokens)


def _summary_should_refresh(existing: str, replacement: str) -> bool:
    if existing.strip() == replacement.strip():
        return False
    # Prefer a refreshed summary when Apple/Xcode later exposes symbolicated
    # feature frames. This lets an issue like #1097 move from app-entry-only
    # frames to actionable frames without copying the raw crash log.
    return _has_feature_level_app_frame(replacement) or not _has_feature_level_app_frame(existing)


def update_existing_crash_issue_if_possible(
    config: Config,
    *,
    feedback: dict[str, Any],
    issue: dict[str, Any],
) -> bool:
    if issue.get("state") != "open":
        return False
    body = issue.get("body") or ""
    section = build_crash_log_summary_section(config, feedback["id"])
    if not section:
        return False

    summary_text = _crash_log_summary_text(section)
    existing_replaced = _replace_existing_crash_log_summary(body, summary_text)
    action = "with"
    if existing_replaced is None:
        updated_body = body.rstrip() + "\n\n" + summary_text + "\n"
    else:
        if not _summary_should_refresh(body, summary_text):
            return False
        updated_body = existing_replaced
        action = "with refreshed"

    github_request(
        config,
        f"/repos/{config.github_repository}/issues/{issue['number']}",
        method="PATCH",
        payload={"body": updated_body},
    )
    print(f"Updated issue #{issue['number']} {action} privacy-safe crash log summary")
    return True


def build_issue_body(config: Config, feedback: dict[str, Any], kind: str) -> str:
    attrs = feedback.get("attributes", {})
    build = get_related_resource(feedback, "build") or {}
    build_attrs = build.get("attributes", {})

    submitted_at = first_non_empty(
        attrs.get("submittedDate"),
        attrs.get("createdDate"),
    )
    comment = redact_for_privacy(
        first_non_empty(
            attrs.get("comment"),
            attrs.get("notes"),
        )
    )
    build_version = first_non_empty(
        build_attrs.get("version"),
        attrs.get("buildVersion"),
    )
    app_version = first_non_empty(attrs.get("appVersion"))
    metadata = extract_metadata(attrs, build_attrs)
    build_uploaded_at = first_non_empty(build_attrs.get("uploadedDate"))
    screenshots = attrs.get("screenshots") or []
    screenshot_count = len(screenshots)
    asc_link = (
        f"https://appstoreconnect.apple.com/apps/{config.asc_app_id}/testflight/ios"
    )

    lines = [
        f"New TestFlight {kind} feedback was pulled from App Store Connect.",
        "",
        "## Summary",
        f"- Feedback kind: `{kind}`",
        f"- ASC Feedback ID: {feedback['id']}",
        f"- App Apple ID: `{config.asc_app_id}`",
        f"- Submitted: {submitted_at or '_unknown_'}",
        f"- App version: {app_version or '_unknown_'}",
        f"- Build number: {build_version or '_unknown_'}",
        f"- Build uploaded: {build_uploaded_at or '_unknown_'}",
        f"- Screenshot count: {screenshot_count if kind == 'screenshot' else 0}",
        f"- App Store Connect: {asc_link}",
        "",
        "## Minimum metadata",
        f"- iOS version: {metadata['iOS version']}",
        f"- Device model: {metadata['Device model']}",
        f"- Locale: {metadata['Locale']}",
        f"- App version: {metadata['App version']}",
        f"- Build number: {metadata['Build number']}",
        "",
        "## Feedback",
        comment or "_No tester comment included in API payload._",
        "",
    ]

    if kind == "crash":
        lines.extend([
            "## Crash context",
            *summarize_crash_context(attrs),
            "",
            "## Triage prompts",
            "- Confirm the minimum metadata block is populated before deeper enrichment.",
            "- Reproduce on the same build number before code changes.",
            "- Compare the crash time against recent telemetry or UI flow changes.",
            "- Pull full crash details from App Store Connect locally rather than copying raw diagnostics into GitHub.",
            "",
        ])
        lines.extend(build_crash_log_summary_section(config, feedback["id"]))

    if kind == "screenshot":
        lines.extend([
            "## Enrichment prompts",
            "- Confirm the minimum metadata block is populated before product triage.",
            "- Use the screenshot plus build number/iOS version to compare against current shipped UI.",
            "",
        ])

    if kind == "screenshot" and screenshots:
        lines.extend(["## Screenshots"])
        for index, screenshot in enumerate(screenshots, start=1):
            screenshot_url = screenshot.get("url")
            if not screenshot_url:
                continue
            lines.extend(
                [
                    f"### Screenshot {index}",
                    f"![TestFlight feedback screenshot {index}]({screenshot_url})",
                    "",
                ]
            )

    lines.extend(
        [
        "## Privacy",
        "GitHub issues intentionally omit raw TestFlight payloads, tester identity/contact fields, exact device identifiers, and full crash diagnostics.",
        "For crash submissions, only minimal triage-safe metadata should appear here; inspect the full Apple record inside App Store Connect when deeper debugging is required.",
        "Screenshots embedded here use temporary signed Apple feedback URLs and may expire.",
        "Review the linked item in App Store Connect for the original feedback record.",
        "",
        "<!-- ASC Feedback Sync -->",
        f"<!-- ASC Feedback ID: {feedback['id']} -->",
        ]
    )
    return "\n".join(lines)


def create_issue(config: Config, title: str, body: str, labels: list[str]) -> dict[str, Any]:
    return github_request(
        config,
        f"/repos/{config.github_repository}/issues",
        method="POST",
        payload={"title": title, "body": body, "labels": labels},
    )


def sync_feedback_kind(
    config: Config,
    *,
    endpoint: str,
    kind: str,
    labels: list[str],
) -> int:
    created_count = 0
    feedback_items = fetch_feedback_collection(config, endpoint)
    existing_feedback_issues = list_existing_feedback_issues(config)
    print(f"Fetched {len(feedback_items)} {kind} feedback item(s)")
    print(f"Found {len(existing_feedback_issues)} existing TestFlight issue marker(s)")

    for feedback in feedback_items:
        feedback_id = feedback["id"]
        existing_issue = existing_feedback_issues.get(feedback_id)
        if existing_issue:
            if kind == "crash":
                update_existing_crash_issue_if_possible(
                    config,
                    feedback=feedback,
                    issue=existing_issue,
                )
            print(f"Skipping existing issue for feedback {feedback_id}")
            continue

        title = build_issue_title(feedback, kind)
        body = build_issue_body(config, feedback, kind)
        issue = create_issue(config, title, body, labels)
        existing_feedback_issues[feedback_id] = issue
        created_count += 1
        print(f"Created issue #{issue['number']} for feedback {feedback_id}")

    return created_count


def parse_labels() -> list[str]:
    raw = os.environ.get("TESTFLIGHT_FEEDBACK_ISSUE_LABELS", "")
    if not raw.strip():
        return DEFAULT_ISSUE_LABELS
    labels = [part.strip() for part in raw.split(",") if part.strip()]
    return labels or DEFAULT_ISSUE_LABELS


def selected_kinds() -> set[str]:
    raw = os.environ.get("TESTFLIGHT_FEEDBACK_ONLY_KIND", "").strip()
    if not raw:
        return {"crash", "screenshot"}
    return {part.strip().lower() for part in raw.split(",") if part.strip()}


def main() -> int:
    config = load_config()
    labels = parse_labels()
    ensure_labels(config, list(dict.fromkeys(labels + CRASH_ISSUE_LABELS)))

    kinds = selected_kinds()
    created = 0
    if "crash" in kinds:
        created += sync_feedback_kind(
            config,
            endpoint=f"/v1/apps/{config.asc_app_id}/betaFeedbackCrashSubmissions",
            kind="crash",
            labels=CRASH_ISSUE_LABELS,
        )
    if "screenshot" in kinds:
        created += sync_feedback_kind(
            config,
            endpoint=f"/v1/apps/{config.asc_app_id}/betaFeedbackScreenshotSubmissions",
            kind="screenshot",
            labels=labels,
        )
    print(f"Created {created} new GitHub issue(s)")
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except Exception as exc:  # noqa: BLE001
        print(str(exc), file=sys.stderr)
        raise
