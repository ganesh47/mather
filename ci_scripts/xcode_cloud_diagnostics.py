"""Read-only Xcode Cloud and existing TestFlight distribution diagnostics."""

import json
import os
from datetime import datetime, timezone

if __package__:
    from .xcode_cloud_testflight import AppStoreConnectClient, PLATFORMS, prerelease_version_id
else:
    from xcode_cloud_testflight import AppStoreConnectClient, PLATFORMS, prerelease_version_id


def distribution_report(client, *, app_id, tag, build_run_id=""):
    """Return observed build and group states without changing any distribution."""
    report = {"checked_at": datetime.now(timezone.utc).isoformat(), "tag": tag,
              "app_id": app_id, "platforms": {}, "groups": []}
    version = tag.removeprefix("v")
    groups = client.pages(f"/v1/apps/{app_id}/betaGroups"
                          "?fields[betaGroups]=name,isInternalGroup,hasAccessToAllBuilds&limit=200")
    memberships = {}
    for group in groups:
        memberships[group["id"]] = {
            build["id"] for build in client.pages(
                f"/v1/betaGroups/{group['id']}/builds?fields[builds]=version&limit=200")
        }
        report["groups"].append({"id": group["id"], **group.get("attributes", {})})
    for key, platform in PLATFORMS.items():
        version_id = prerelease_version_id(client, app_id=app_id, version=version, platform=platform)
        builds = client.pages(f"/v1/preReleaseVersions/{version_id}/builds"
                              "?fields[builds]=version,processingState,uploadedDate,expired,expirationDate&limit=200") if version_id else []
        build = max(builds, key=lambda b: b.get("attributes", {}).get("uploadedDate", "")) if builds else None
        if build is None:
            report["platforms"][key] = {"marketing_version": version, "build": None,
                                         "issue": "No build found for the requested version and platform"}
            continue
        detail = client.request(f"/v1/builds/{build['id']}/buildBetaDetail"
                                "?fields[buildBetaDetails]=internalBuildState,externalBuildState")["data"].get("attributes", {})
        attrs = build.get("attributes", {})
        group_results = []
        for group in groups:
            internal = group.get("attributes", {}).get("isInternalGroup")
            state = detail.get("internalBuildState" if internal is True else "externalBuildState")
            assigned = build["id"] in memberships[group["id"]]
            group_results.append({"id": group["id"], "name": group.get("attributes", {}).get("name"),
                                  "isInternalGroup": internal, "assigned": assigned, "build_state": state,
                                  "available": internal is not None and assigned and attrs.get("expired") is False
                                  and attrs.get("processingState") == "VALID" and state == "IN_BETA_TESTING"})
        report["platforms"][key] = {"marketing_version": version, "platform": platform.app_store_platform,
                                     "build_id": build["id"], **attrs, **detail, "groups": group_results}
        localizations = client.pages(f"/v1/builds/{build['id']}/betaBuildLocalizations"
                                     "?fields[betaBuildLocalizations]=locale,whatsNew&limit=200")
        report["platforms"][key]["test_notes"] = [
            {"id": item["id"], "locale": item.get("attributes", {}).get("locale"),
             "provided": bool((item.get("attributes", {}).get("whatsNew") or "").strip())}
            for item in localizations
        ]
    review = client.request(f"/v1/apps/{app_id}/betaAppReviewDetail"
                            "?fields[betaAppReviewDetails]=contactFirstName,contactLastName,contactPhone,contactEmail,demoAccountRequired")["data"]
    report["review_contact"] = {
        "id": review["id"], "demoAccountRequired": review.get("attributes", {}).get("demoAccountRequired"),
        "provided": {name: bool((review.get("attributes", {}).get(name) or "").strip())
                     for name in ["contactFirstName", "contactLastName", "contactPhone", "contactEmail"]}
    }
    app_localizations = client.pages(f"/v1/apps/{app_id}/betaAppLocalizations"
                                     "?fields[betaAppLocalizations]=locale,description,feedbackEmail,privacyPolicyUrl&limit=200")
    report["app_localizations"] = [
        {"id": item["id"], "locale": item.get("attributes", {}).get("locale"),
         "provided": {name: bool((item.get("attributes", {}).get(name) or "").strip())
                      for name in ["description", "feedbackEmail", "privacyPolicyUrl"]}}
        for item in app_localizations
    ]
    if build_run_id:
        run = client.request(f"/v1/ciBuildRuns/{build_run_id}")["data"]
        attrs = run.get("attributes", {})
        report["cloud_run"] = {"id": build_run_id, "number": attrs.get("number"),
                               "completionStatus": attrs.get("completionStatus"),
                               "sourceCommit": attrs.get("sourceCommit"),
                               "workflow": run.get("relationships", {}).get("workflow", {}).get("data")}
    return report


def main():
    client = AppStoreConnectClient(key_id=os.environ["APP_STORE_CONNECT_KEY_ID"],
                                   issuer_id=os.environ.get("APP_STORE_CONNECT_ISSUER_ID", ""),
                                   private_key=os.environ["APP_STORE_CONNECT_PRIVATE_KEY"])
    tag = os.environ["RELEASE_TAG"]
    workflow = "08111c64-7aa6-4651-b181-b86c25543bc5"
    print("Workflow conditions and archive actions:", client.request(f"/v1/ciWorkflows/{workflow}?fields[ciWorkflows]=name,isEnabled,manualTagStartCondition,manualBranchStartCondition,tagStartCondition,actions")["data"]["attributes"], flush=True)
    repository = client.request(f"/v1/ciWorkflows/{workflow}/repository")["data"]
    print("Workflow repository:", repository["id"], repository["attributes"], flush=True)
    for repository_id in dict.fromkeys(["3d717c8d-4c65-4f36-821b-94e10b4f639a", repository["id"]]):
        refs = client.pages(f"/v1/scmRepositories/{repository_id}/gitReferences?fields[scmGitReferences]=name,canonicalName,isDeleted,kind&limit=200")
        print("Repository", repository_id, "reference count:", len(refs), flush=True)
        for ref in refs:
            a = ref["attributes"]
            if a.get("kind") == "BRANCH" or a.get("name") == tag or a.get("canonicalName") == f"refs/tags/{tag}":
                print(ref["id"], a, flush=True)
    report = distribution_report(client, app_id=os.environ["APP_STORE_CONNECT_APP_ID"], tag=tag,
                                 build_run_id=os.environ.get("RESUME_BUILD_RUN_ID", ""))
    print("TestFlight distribution report:", json.dumps(report, sort_keys=True), flush=True)


if __name__ == "__main__":
    main()
