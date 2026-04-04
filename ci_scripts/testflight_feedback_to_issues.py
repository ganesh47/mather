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
LABEL_COLORS = {
    "source:testflight": "0e8a16",
    "type:feedback": "1d76db",
}


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
) -> Any:
    body = None
    request_headers = {"Accept": "application/json"}
    if headers:
        request_headers.update(headers)
    if payload is not None:
        body = json.dumps(payload).encode("utf-8")
        request_headers["Content-Type"] = "application/json"

    request = urllib.request.Request(url, data=body, headers=request_headers, method=method)
    try:
        with urllib.request.urlopen(request) as response:
            content = response.read()
    except urllib.error.HTTPError as exc:
        details = exc.read().decode("utf-8", errors="replace")
        raise RuntimeError(f"{method} {url} failed: {exc.code} {details}") from exc

    if not content:
        return None
    return json.loads(content)


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


def issue_exists(config: Config, feedback_id: str) -> bool:
    query = urllib.parse.quote(
        f'repo:{config.github_repository} is:issue "ASC Feedback ID: {feedback_id}"'
    )
    result = github_request(config, f"/search/issues?q={query}")
    return result.get("total_count", 0) > 0


def build_issue_title(feedback: dict[str, Any], kind: str) -> str:
    feedback_id = feedback["id"]
    build = get_related_resource(feedback, "build") or {}
    build_attrs = build.get("attributes", {})
    build_number = first_non_empty(build_attrs.get("version"))
    title = f"TestFlight {kind} feedback {feedback_id}"
    if build_number:
        title += f" (build {build_number})"
    return title


def build_issue_body(config: Config, feedback: dict[str, Any], kind: str) -> str:
    attrs = feedback.get("attributes", {})
    build = get_related_resource(feedback, "build") or {}
    build_attrs = build.get("attributes", {})

    submitted_at = first_non_empty(
        attrs.get("submittedDate"),
        attrs.get("createdDate"),
    )
    comment = first_non_empty(
        attrs.get("comment"),
        attrs.get("notes"),
    )
    build_version = first_non_empty(
        build_attrs.get("version"),
        attrs.get("buildVersion"),
    )
    app_version = first_non_empty(attrs.get("appVersion"))
    build_uploaded_at = first_non_empty(build_attrs.get("uploadedDate"))
    screenshot_count = len(attrs.get("screenshots") or [])
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
        "## Feedback",
        comment or "_No tester comment included in API payload._",
        "",
        "## Privacy",
        "Raw TestFlight payload, tester contact details, device metadata, and screenshot URLs are intentionally omitted from GitHub.",
        "Review the linked item in App Store Connect for full details and attachments.",
        "",
        "<!-- ASC Feedback Sync -->",
        f"<!-- ASC Feedback ID: {feedback['id']} -->",
    ]
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
    print(f"Fetched {len(feedback_items)} {kind} feedback item(s)")

    for feedback in feedback_items:
        feedback_id = feedback["id"]
        if issue_exists(config, feedback_id):
            print(f"Skipping existing issue for feedback {feedback_id}")
            continue

        title = build_issue_title(feedback, kind)
        body = build_issue_body(config, feedback, kind)
        issue = create_issue(config, title, body, labels)
        created_count += 1
        print(f"Created issue #{issue['number']} for feedback {feedback_id}")

    return created_count


def parse_labels() -> list[str]:
    raw = os.environ.get("TESTFLIGHT_FEEDBACK_ISSUE_LABELS", "")
    if not raw.strip():
        return DEFAULT_ISSUE_LABELS
    labels = [part.strip() for part in raw.split(",") if part.strip()]
    return labels or DEFAULT_ISSUE_LABELS


def main() -> int:
    config = load_config()
    labels = parse_labels()
    ensure_labels(config, labels)

    created = 0
    created += sync_feedback_kind(
        config,
        endpoint=f"/v1/apps/{config.asc_app_id}/betaFeedbackCrashSubmissions",
        kind="crash",
        labels=labels,
    )
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
