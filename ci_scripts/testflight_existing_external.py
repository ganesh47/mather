"""Opt-in distribution of an exact released build to existing external groups.

This API-only operation never builds/uploads, creates groups/testers/public
links, changes contact/legal metadata, or replaces existing nonempty test notes.
Beta-review submission is distinct from availability; the receipt reports both.
"""

import json
import os
from datetime import datetime, timezone
from pathlib import Path

if __package__:
    from .xcode_cloud_testflight import (
        AppStoreConnectClient, PLATFORMS, ReleaseError, find_build,
        prerelease_version_id, required_env, resolve_release_tag_commit,
        verify_build_source,
    )
else:
    from xcode_cloud_testflight import (
        AppStoreConnectClient, PLATFORMS, ReleaseError, find_build,
        prerelease_version_id, required_env, resolve_release_tag_commit,
        verify_build_source,
    )


ELIGIBLE_STATES = {
    "READY_FOR_BETA_SUBMISSION", "WAITING_FOR_BETA_REVIEW", "IN_BETA_REVIEW",
    "BETA_APPROVED", "READY_FOR_BETA_TESTING", "IN_BETA_TESTING",
}


def review_submissions(client, build_id):
    return client.pages(f"/v1/betaAppReviewSubmissions?filter[build]={build_id}"
                        "&fields[betaAppReviewSubmissions]=betaReviewState,submittedDate&limit=200")


def beta_detail(client, build_id):
    return client.request(f"/v1/builds/{build_id}/buildBetaDetail"
                          "?fields[buildBetaDetails]=internalBuildState,externalBuildState,autoNotifyEnabled")["data"]


def valid_external_build(build):
    attrs = (build or {}).get("attributes", {})
    if not isinstance(attrs.get("expirationDate"), str):
        return False
    try:
        expiry = datetime.fromisoformat(attrs.get("expirationDate", "").replace("Z", "+00:00"))
    except (ValueError, TypeError):
        return False
    return (bool(build) and attrs.get("expired") is False and attrs.get("processingState") == "VALID"
            and attrs.get("buildAudienceType") == "APP_STORE_ELIGIBLE" and expiry.tzinfo is not None
            and expiry > datetime.now(timezone.utc))


def validate_review(submissions):
    if len(submissions) > 1 or any(
        item.get("attributes", {}).get("betaReviewState") not in
        {"WAITING_FOR_REVIEW", "IN_REVIEW", "APPROVED"} for item in submissions
    ):
        raise ReleaseError("Existing beta review is rejected or unknown; no automatic resubmission")


def external_plan(client, *, app_id, tag, build_run_id, workflow_id, expected_sha, notes):
    """Validate both exact platform builds and all prerequisites before writing."""
    verify_build_source(client, build_run_id, expected_sha, workflow_id)
    run = client.request(f"/v1/ciBuildRuns/{build_run_id}")["data"]
    number = run.get("attributes", {}).get("number")
    if run.get("attributes", {}).get("completionStatus") != "SUCCEEDED" or not number:
        raise ReleaseError("External distribution requires the successful exact-tag Cloud run")
    groups = client.pages(f"/v1/apps/{app_id}/betaGroups"
                          "?fields[betaGroups]=name,isInternalGroup&limit=200")
    if any(g.get("attributes", {}).get("isInternalGroup") is not True and
           g.get("attributes", {}).get("isInternalGroup") is not False for g in groups):
        raise ReleaseError("Unknown existing group kind; distribution scope cannot be established")
    external = [g for g in groups if g["attributes"]["isInternalGroup"] is False]
    if not external:
        return []
    contact = client.request(f"/v1/apps/{app_id}/betaAppReviewDetail"
                             "?fields[betaAppReviewDetails]=contactFirstName,contactLastName,contactPhone,contactEmail,demoAccountRequired")["data"]["attributes"]
    if contact.get("demoAccountRequired") is not False or any(
        not (contact.get(k) or "").strip() for k in
        ["contactFirstName", "contactLastName", "contactPhone", "contactEmail"]
    ):
        raise ReleaseError("Existing review contact/demo information needs owner attention")
    locales = client.pages(f"/v1/apps/{app_id}/betaAppLocalizations"
                           "?fields[betaAppLocalizations]=locale,description,feedbackEmail,privacyPolicyUrl&limit=200")
    if not locales or any(not (item.get("attributes", {}).get(k) or "").strip()
                          for item in locales for k in ["description", "feedbackEmail", "privacyPolicyUrl"]):
        raise ReleaseError("Existing app test information is incomplete; no contact or policy edits made")
    plan = []
    for key, platform in PLATFORMS.items():
        if not isinstance(notes.get(key), str) or not notes[key].strip():
            raise ReleaseError(f"Missing reviewed {key} What to Test notes")
        version_id = prerelease_version_id(client, app_id=app_id, version=tag.removeprefix("v"), platform=platform)
        builds = client.pages(f"/v1/preReleaseVersions/{version_id}/builds"
                              "?fields[builds]=version,processingState,expired,expirationDate,buildAudienceType&limit=200") if version_id else []
        build = find_build(builds, str(number))
        if not valid_external_build(build):
            raise ReleaseError(f"Exact {key} build is missing, expired, unreadable, or internal-only")
        detail = beta_detail(client, build["id"])
        if (detail["attributes"].get("internalBuildState") != "IN_BETA_TESTING"
                or detail["attributes"].get("externalBuildState") not in ELIGIBLE_STATES):
            raise ReleaseError(f"Exact {key} build is not ready for external distribution")
        submissions = review_submissions(client, build["id"])
        validate_review(submissions)
        localizations = client.pages(f"/v1/builds/{build['id']}/betaBuildLocalizations"
                                     "?fields[betaBuildLocalizations]=locale,whatsNew&limit=200")
        plan.append({"platform": key, "build": build, "detail": detail, "groups": external,
                     "localizations": localizations, "notes": notes[key].strip()})
    return plan


def distribute_plan(client, plan):
    results = []
    for item in plan:
        build_id = item["build"]["id"]
        # Re-read each build before its writes. Never submit twice after a
        # partial failure; an existing waiting/approved submission is retained.
        detail = beta_detail(client, build_id)
        build = client.request(f"/v1/builds/{build_id}"
                               "?fields[builds]=version,processingState,expired,expirationDate,buildAudienceType")["data"]
        if not valid_external_build(build) or build["attributes"]["version"] != item["build"]["attributes"]["version"]:
            raise ReleaseError("Exact build eligibility changed; distribution stopped")
        submissions = review_submissions(client, build_id)
        validate_review(submissions)
        state = detail["attributes"].get("externalBuildState")
        if state not in ELIGIBLE_STATES:
            raise ReleaseError("External build state changed; distribution stopped")
        missing = []
        for group in item["groups"]:
            current = client.request(f"/v1/betaGroups/{group['id']}?fields[betaGroups]=isInternalGroup")["data"]
            if current.get("attributes", {}).get("isInternalGroup") is not False:
                raise ReleaseError("Existing external group changed; distribution stopped")
            members = client.pages(f"/v1/betaGroups/{group['id']}/builds?fields[builds]=version&limit=200")
            if not any(b["id"] == build_id for b in members):
                missing.append({"type": "betaGroups", "id": group["id"]})
        localizations = client.pages(f"/v1/builds/{build_id}/betaBuildLocalizations"
                                     "?fields[betaBuildLocalizations]=locale,whatsNew&limit=200")
        english = next((loc for loc in localizations if loc.get("attributes", {}).get("locale") == "en-US"), None)
        if english and not (english.get("attributes", {}).get("whatsNew") or "").strip():
            client.request(f"/v1/betaBuildLocalizations/{english['id']}", method="PATCH", payload={"data": {
                "type": "betaBuildLocalizations", "id": english["id"], "attributes": {"whatsNew": item["notes"]}}})
        elif not english:
            client.request("/v1/betaBuildLocalizations", method="POST", payload={"data": {
                "type": "betaBuildLocalizations", "attributes": {"locale": "en-US", "whatsNew": item["notes"]},
                "relationships": {"build": {"data": {"type": "builds", "id": build_id}}}}})
        # Existing tester delivery starts after Apple's approval. This changes
        # only the selected build's notification setting, never tester records.
        if detail["attributes"].get("autoNotifyEnabled") is not True:
            client.request(f"/v1/buildBetaDetails/{detail['id']}", method="PATCH", payload={"data": {
                "type": "buildBetaDetails", "id": detail["id"], "attributes": {"autoNotifyEnabled": True}}})
        if missing:
            client.request(f"/v1/builds/{build_id}/relationships/betaGroups", method="POST", payload={"data": missing})
        submissions = review_submissions(client, build_id)
        validate_review(submissions)
        state = beta_detail(client, build_id)["attributes"].get("externalBuildState")
        if state not in ELIGIBLE_STATES:
            raise ReleaseError("External build state changed after group assignment; distribution stopped")
        if not submissions and state == "READY_FOR_BETA_SUBMISSION":
            client.request("/v1/betaAppReviewSubmissions", method="POST", payload={"data": {
                "type": "betaAppReviewSubmissions", "relationships": {"build": {"data": {"type": "builds", "id": build_id}}}}})
        observed = beta_detail(client, build_id)["attributes"]
        groups = []
        for group in item["groups"]:
            members = client.pages(f"/v1/betaGroups/{group['id']}/builds?fields[builds]=version&limit=200")
            assigned = any(b["id"] == build_id for b in members)
            groups.append({"id": group["id"], "name": group["attributes"].get("name"), "assigned": assigned,
                           "available": assigned and observed.get("externalBuildState") == "IN_BETA_TESTING"})
        results.append({"platform": item["platform"], "build_id": build_id,
                        "build_number": build["attributes"]["version"],
                        "expired": build["attributes"]["expired"],
                        "expirationDate": build["attributes"]["expirationDate"], **observed,
                        "groups": groups, "review": review_submissions(client, build_id)})
    return results


def main():
    tag = required_env("RELEASE_TAG")
    run_id = required_env("RESUME_BUILD_RUN_ID")
    source_sha = resolve_release_tag_commit(tag)
    client = AppStoreConnectClient(key_id=required_env("APP_STORE_CONNECT_KEY_ID"),
                                   issuer_id=os.environ.get("APP_STORE_CONNECT_ISSUER_ID", ""),
                                   private_key=required_env("APP_STORE_CONNECT_PRIVATE_KEY"))
    plan = external_plan(client, app_id=required_env("APP_STORE_CONNECT_APP_ID"), tag=tag,
                         build_run_id=run_id, workflow_id="08111c64-7aa6-4651-b181-b86c25543bc5",
                         expected_sha=source_sha,
                         notes=json.loads(Path(__file__).with_name("testflight-test-notes.json").read_text()))
    print("Existing external distribution:", json.dumps({"tag": tag, "source_sha": source_sha, "cloud_run": run_id,
          "checked_at": datetime.now(timezone.utc).isoformat(), "platforms": distribute_plan(client, plan)}), flush=True)


if __name__ == "__main__":
    main()
