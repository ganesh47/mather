#!/usr/bin/env python3
"""Recover and publish the signed tvOS export produced by Xcode Cloud.

Xcode Cloud creates a valid App Store export for MatherTV, but Apple also
attempts Development and Ad Hoc exports for the tvOS archive. Those additional
exports require a registered Apple TV and cause the archive action to be marked
failed even though the App Store IPA is usable.

This helper starts the dedicated release workflow, waits for the tvOS App Store
export, uploads it with altool, and verifies that the build reaches internal
TestFlight testing.
"""

from __future__ import annotations

import argparse
import json
import os
import plistlib
import shutil
import subprocess
import sys
import tempfile
import time
import urllib.error
import urllib.parse
import urllib.request
import zipfile
from pathlib import Path
from typing import Any

import jwt


ASC_BASE = "https://api.appstoreconnect.apple.com"
DEFAULT_POLL_SECONDS = 20
DEFAULT_CLOUD_TIMEOUT_SECONDS = 30 * 60
DEFAULT_TESTFLIGHT_TIMEOUT_SECONDS = 20 * 60


class ReleaseError(RuntimeError):
    """A release step could not complete safely."""


def normalize_private_key(value: str) -> str:
    return value.replace("\\n", "\n").strip() + "\n"


class AppStoreConnectClient:
    def __init__(self, *, key_id: str, private_key: str, issuer_id: str = "") -> None:
        self.key_id = key_id
        self.private_key = normalize_private_key(private_key)
        self.issuer_id = issuer_id.strip()

    def token(self) -> str:
        now = int(time.time())
        identity = {"iss": self.issuer_id} if self.issuer_id else {"sub": "user"}
        payload = {
            **identity,
            "aud": "appstoreconnect-v1",
            "iat": now,
            "exp": now + 19 * 60,
        }
        return jwt.encode(
            payload,
            self.private_key,
            algorithm="ES256",
            headers={"alg": "ES256", "kid": self.key_id, "typ": "JWT"},
        )

    def request(
        self,
        path_or_url: str,
        *,
        method: str = "GET",
        payload: dict[str, Any] | None = None,
    ) -> dict[str, Any]:
        url = (
            path_or_url
            if path_or_url.startswith("https://")
            else f"{ASC_BASE}{path_or_url}"
        )
        body = json.dumps(payload).encode() if payload is not None else None
        headers = {
            "Authorization": f"Bearer {self.token()}",
            "Accept": "application/json",
        }
        if body is not None:
            headers["Content-Type"] = "application/json"
        request = urllib.request.Request(url, data=body, headers=headers, method=method)
        try:
            with urllib.request.urlopen(request, timeout=60) as response:
                content = response.read()
        except urllib.error.HTTPError as exc:
            details = exc.read().decode(errors="replace")
            raise ReleaseError(f"{method} {url} failed ({exc.code}): {details}") from exc
        if not content:
            return {}
        return json.loads(content)

    def pages(self, path: str) -> list[dict[str, Any]]:
        items: list[dict[str, Any]] = []
        url = path
        while url:
            response = self.request(url)
            items.extend(response.get("data", []))
            url = response.get("links", {}).get("next", "")
        return items


def find_git_reference(
    client: AppStoreConnectClient, repository_id: str, tag: str
) -> str:
    path = (
        f"/v1/scmRepositories/{repository_id}/gitReferences"
        "?fields[scmGitReferences]=name,canonicalName,isDeleted,kind&limit=200"
    )
    for reference in client.pages(path):
        attributes = reference["attributes"]
        if (
            attributes.get("name") == tag
            and attributes.get("kind") == "TAG"
            and not attributes.get("isDeleted")
        ):
            return reference["id"]
    raise ReleaseError(f"Xcode Cloud cannot see Git tag {tag!r}")


def start_build_run(
    client: AppStoreConnectClient,
    *,
    workflow_id: str,
    git_reference_id: str,
) -> tuple[str, str]:
    payload = {
        "data": {
            "type": "ciBuildRuns",
            "attributes": {},
            "relationships": {
                "workflow": {
                    "data": {"type": "ciWorkflows", "id": workflow_id}
                },
                "sourceBranchOrTag": {
                    "data": {
                        "type": "scmGitReferences",
                        "id": git_reference_id,
                    }
                },
            },
        }
    }
    build_run = client.request("/v1/ciBuildRuns", method="POST", payload=payload)["data"]
    number = str(build_run["attributes"]["number"])
    return build_run["id"], number


def choose_app_store_export(artifacts: list[dict[str, Any]]) -> dict[str, Any] | None:
    exports = [
        artifact
        for artifact in artifacts
        if artifact.get("attributes", {}).get("fileType") == "ARCHIVE_EXPORT"
        and "app-store" in artifact.get("attributes", {}).get("fileName", "").lower()
    ]
    if len(exports) > 1:
        names = ", ".join(item["attributes"]["fileName"] for item in exports)
        raise ReleaseError(f"Multiple tvOS App Store exports found: {names}")
    return exports[0] if exports else None


def wait_for_tv_export(
    client: AppStoreConnectClient,
    *,
    build_run_id: str,
    timeout_seconds: int,
    poll_seconds: int,
) -> tuple[dict[str, Any], str]:
    deadline = time.monotonic() + timeout_seconds
    archive_action_id = ""
    build_number = ""
    last_state = ""

    while time.monotonic() < deadline:
        run = client.request(f"/v1/ciBuildRuns/{build_run_id}")["data"]
        build_number = str(run["attributes"]["number"])
        actions = client.pages(
            f"/v1/ciBuildRuns/{build_run_id}/actions"
            "?fields[ciBuildActions]=name,executionProgress,completionStatus&limit=200"
        )
        archive = next(
            (
                action
                for action in actions
                if action.get("attributes", {}).get("name") == "Archive - tvOS"
            ),
            None,
        )
        if archive:
            archive_action_id = archive["id"]
            attrs = archive["attributes"]
            state = f"{attrs.get('executionProgress')}/{attrs.get('completionStatus')}"
            if state != last_state:
                print(f"Xcode Cloud build {build_number}: tvOS archive {state}", flush=True)
                last_state = state

            if attrs.get("executionProgress") == "COMPLETE":
                artifacts = client.pages(
                    f"/v1/ciBuildActions/{archive_action_id}/artifacts?limit=200"
                )
                export = choose_app_store_export(artifacts)
                if export:
                    return export, build_number

                issues = client.pages(
                    f"/v1/ciBuildActions/{archive_action_id}/issues?limit=200"
                )
                messages = "; ".join(
                    issue.get("attributes", {}).get("message", "Unknown issue")
                    for issue in issues
                )
                raise ReleaseError(
                    "tvOS archive completed without an App Store export"
                    + (f": {messages}" if messages else "")
                )
        time.sleep(poll_seconds)

    raise ReleaseError(
        f"Timed out waiting for tvOS export from Xcode Cloud run {build_run_id}"
    )


def download_ipa(export: dict[str, Any], destination: Path) -> Path:
    attributes = export["attributes"]
    download_url = attributes["downloadUrl"]
    archive_path = destination / attributes["fileName"]
    print(f"Downloading {attributes['fileName']} ({attributes['fileSize']} bytes)", flush=True)
    with urllib.request.urlopen(download_url, timeout=120) as response:
        with archive_path.open("wb") as output:
            shutil.copyfileobj(response, output)
    if archive_path.stat().st_size != attributes["fileSize"]:
        raise ReleaseError(
            f"Downloaded size for {archive_path.name} does not match Xcode Cloud"
        )

    with zipfile.ZipFile(archive_path) as archive:
        ipa_members = [
            member
            for member in archive.infolist()
            if not member.is_dir() and member.filename.lower().endswith(".ipa")
        ]
        if len(ipa_members) != 1:
            raise ReleaseError(
                f"Expected one IPA in {archive_path.name}, found {len(ipa_members)}"
            )
        ipa_path = destination / Path(ipa_members[0].filename).name
        with archive.open(ipa_members[0]) as source, ipa_path.open("wb") as output:
            shutil.copyfileobj(source, output)
    return ipa_path


def inspect_ipa(
    ipa_path: Path,
    *,
    expected_bundle_id: str,
    expected_version: str,
    expected_build_number: str,
) -> dict[str, Any]:
    with zipfile.ZipFile(ipa_path) as archive:
        info_plists = [
            member
            for member in archive.infolist()
            if member.filename.startswith("Payload/")
            and member.filename.count("/") == 2
            and member.filename.endswith(".app/Info.plist")
        ]
        if len(info_plists) != 1:
            raise ReleaseError(
                f"Expected one app Info.plist in {ipa_path.name}, "
                f"found {len(info_plists)}"
            )
        with archive.open(info_plists[0]) as info_file:
            info = plistlib.load(info_file)

    checks = {
        "CFBundleIdentifier": expected_bundle_id,
        "CFBundleShortVersionString": expected_version,
        "CFBundleVersion": expected_build_number,
    }
    for key, expected in checks.items():
        observed = str(info.get(key, ""))
        if observed != str(expected):
            raise ReleaseError(
                f"{ipa_path.name} has {key}={observed!r}; expected {expected!r}"
            )
    if "AppleTVOS" not in info.get("CFBundleSupportedPlatforms", []):
        raise ReleaseError(f"{ipa_path.name} is not a tvOS application")
    if info.get("ITSAppUsesNonExemptEncryption") is not False:
        raise ReleaseError(
            f"{ipa_path.name} does not declare exempt encryption usage"
        )
    return info


def altool_auth_args(*, key_id: str, issuer_id: str) -> list[str]:
    if not issuer_id:
        raise ReleaseError(
            "altool requires a team App Store Connect API key with an issuer ID"
        )
    return ["--apiKey", key_id, "--apiIssuer", issuer_id]


def run_altool(
    command: str,
    *,
    ipa_path: Path,
    key_id: str,
    issuer_id: str,
    private_key_path: Path,
) -> None:
    args = altool_command_args(
        command,
        ipa_path=ipa_path,
        key_id=key_id,
        issuer_id=issuer_id,
    )
    print(f"Running Apple {command.removeprefix('--').replace('-', ' ')}", flush=True)
    subprocess.run(args, check=True, cwd=private_key_path.parent.parent)


def altool_command_args(
    command: str,
    *,
    ipa_path: Path,
    key_id: str,
    issuer_id: str,
) -> list[str]:
    if command not in {"--validate-app", "--upload-app"}:
        raise ReleaseError(f"Unsupported altool command: {command}")
    return [
        "xcrun",
        "altool",
        command,
        "-f",
        str(ipa_path),
        "-t",
        "tvos",
        *altool_auth_args(
            key_id=key_id,
            issuer_id=issuer_id,
        ),
        "--output-format",
        "json",
    ]


def prerelease_version_id(
    client: AppStoreConnectClient, *, app_id: str, version: str
) -> str | None:
    params = urllib.parse.urlencode(
        {
            "filter[app]": app_id,
            "filter[version]": version,
            "fields[preReleaseVersions]": "version,platform",
            "limit": "20",
        }
    )
    versions = client.pages(f"/v1/preReleaseVersions?{params}")
    match = next(
        (
            item
            for item in versions
            if item.get("attributes", {}).get("platform") == "TV_OS"
        ),
        None,
    )
    return match["id"] if match else None


def find_build(
    builds: list[dict[str, Any]], build_number: str
) -> dict[str, Any] | None:
    return next(
        (
            build
            for build in builds
            if str(build.get("attributes", {}).get("version")) == str(build_number)
        ),
        None,
    )


def wait_for_internal_testflight(
    client: AppStoreConnectClient,
    *,
    app_id: str,
    version: str,
    build_number: str,
    timeout_seconds: int,
    poll_seconds: int,
) -> str:
    deadline = time.monotonic() + timeout_seconds
    last_state = ""
    while time.monotonic() < deadline:
        version_id = prerelease_version_id(client, app_id=app_id, version=version)
        if version_id:
            builds = client.pages(
                f"/v1/preReleaseVersions/{version_id}/builds"
                "?fields[builds]=version,processingState,uploadedDate,"
                "usesNonExemptEncryption&limit=200"
            )
            build = find_build(builds, build_number)
            if build:
                processing_state = build["attributes"]["processingState"]
                if processing_state != last_state:
                    print(
                        f"TestFlight tvOS {version} ({build_number}): "
                        f"{processing_state}",
                        flush=True,
                    )
                    last_state = processing_state
                if processing_state in {"FAILED", "INVALID"}:
                    raise ReleaseError(
                        f"TestFlight rejected tvOS build {build_number}: "
                        f"{processing_state}"
                    )
                if processing_state == "VALID":
                    try:
                        detail = client.request(
                            f"/v1/builds/{build['id']}/buildBetaDetail"
                            "?fields[buildBetaDetails]=internalBuildState"
                        )
                    except ReleaseError:
                        detail = {}
                    internal_state = (
                        detail.get("data", {})
                        .get("attributes", {})
                        .get("internalBuildState")
                    )
                    if internal_state == "IN_BETA_TESTING":
                        return build["id"]
                    print(
                        f"Build is valid; waiting for internal testing "
                        f"({internal_state or 'pending'})",
                        flush=True,
                    )
        time.sleep(poll_seconds)
    raise ReleaseError(
        f"Timed out waiting for tvOS {version} ({build_number}) in TestFlight"
    )


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument("--workflow-id", required=True)
    parser.add_argument("--repository-id", required=True)
    parser.add_argument("--tag", required=True)
    parser.add_argument("--build-run-id", default="")
    parser.add_argument(
        "--artifact-only",
        action="store_true",
        help="Download and inspect the IPA without validating or uploading it.",
    )
    parser.add_argument(
        "--output-dir",
        type=Path,
        help="Keep downloaded files in this directory (otherwise use a temp dir).",
    )
    parser.add_argument(
        "--cloud-timeout-seconds",
        type=int,
        default=DEFAULT_CLOUD_TIMEOUT_SECONDS,
    )
    parser.add_argument(
        "--testflight-timeout-seconds",
        type=int,
        default=DEFAULT_TESTFLIGHT_TIMEOUT_SECONDS,
    )
    parser.add_argument("--poll-seconds", type=int, default=DEFAULT_POLL_SECONDS)
    return parser.parse_args()


def required_env(name: str) -> str:
    value = os.environ.get(name, "").strip()
    if not value:
        raise ReleaseError(f"Missing required environment variable: {name}")
    return value


def release(args: argparse.Namespace) -> None:
    app_id = required_env("APP_STORE_CONNECT_APP_ID")
    bundle_id = os.environ.get("TVOS_BUNDLE_ID", "com.ganesh47.Mather").strip()
    issuer_id = os.environ.get("APP_STORE_CONNECT_ISSUER_ID", "").strip()
    key_id = required_env("APP_STORE_CONNECT_KEY_ID")
    private_key_path = os.environ.get("APP_STORE_CONNECT_PRIVATE_KEY_PATH", "").strip()
    if private_key_path:
        private_key = Path(private_key_path).read_text()
    else:
        private_key = required_env("APP_STORE_CONNECT_PRIVATE_KEY")
    client = AppStoreConnectClient(
        key_id=key_id,
        issuer_id=issuer_id,
        private_key=private_key,
    )

    build_run_id = args.build_run_id
    build_number = ""
    if not build_run_id:
        reference_id = find_git_reference(client, args.repository_id, args.tag)
        build_run_id, build_number = start_build_run(
            client,
            workflow_id=args.workflow_id,
            git_reference_id=reference_id,
        )
        print(
            f"Started Xcode Cloud build {build_number} ({build_run_id}) "
            f"for {args.tag}",
            flush=True,
        )

    export, observed_build_number = wait_for_tv_export(
        client,
        build_run_id=build_run_id,
        timeout_seconds=args.cloud_timeout_seconds,
        poll_seconds=args.poll_seconds,
    )
    build_number = build_number or observed_build_number

    version = args.tag.removeprefix("v")
    if args.output_dir:
        args.output_dir.mkdir(parents=True, exist_ok=True)
        workspace_context = _ExistingDirectory(args.output_dir)
    else:
        workspace_context = tempfile.TemporaryDirectory(prefix="mather-tv-release-")

    with workspace_context as workspace:
        workspace_path = Path(workspace)
        ipa_path = download_ipa(export, workspace_path)
        info = inspect_ipa(
            ipa_path,
            expected_bundle_id=bundle_id,
            expected_version=version,
            expected_build_number=build_number,
        )
        print(f"tvOS App Store IPA ready: {ipa_path}", flush=True)
        print(
            f"Verified {info['CFBundleIdentifier']} {info['CFBundleShortVersionString']} "
            f"({info['CFBundleVersion']}) for AppleTVOS",
            flush=True,
        )
        if args.artifact_only:
            return

        private_key_directory = workspace_path / "private_keys"
        private_key_directory.mkdir(mode=0o700)
        private_key_path = private_key_directory / f"AuthKey_{key_id}.p8"
        private_key_path.write_text(normalize_private_key(private_key))
        private_key_path.chmod(0o600)
        run_altool(
            "--validate-app",
            ipa_path=ipa_path,
            key_id=key_id,
            issuer_id=issuer_id,
            private_key_path=private_key_path,
        )
        run_altool(
            "--upload-app",
            ipa_path=ipa_path,
            key_id=key_id,
            issuer_id=issuer_id,
            private_key_path=private_key_path,
        )
        build_id = wait_for_internal_testflight(
            client,
            app_id=app_id,
            version=version,
            build_number=build_number,
            timeout_seconds=args.testflight_timeout_seconds,
            poll_seconds=args.poll_seconds,
        )
        print(
            f"tvOS {version} ({build_number}) is IN_BETA_TESTING "
            f"(build {build_id})",
            flush=True,
        )


class _ExistingDirectory:
    def __init__(self, path: Path) -> None:
        self.path = path

    def __enter__(self) -> str:
        return str(self.path)

    def __exit__(self, *_: object) -> None:
        return None


def main() -> int:
    try:
        release(parse_args())
    except (ReleaseError, subprocess.CalledProcessError, zipfile.BadZipFile) as exc:
        print(f"Release failed: {exc}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
