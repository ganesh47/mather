import unittest
import argparse
import copy
import plistlib
import tempfile
import urllib.error
import zipfile
from pathlib import Path
from unittest.mock import MagicMock, patch

from ci_scripts.xcode_cloud_testflight import (
    AppStoreConnectClient,
    PLATFORMS,
    ReleaseError,
    altool_command_args,
    altool_auth_args,
    choose_app_store_export,
    choose_workflow_for_platform,
    ensure_internal_beta_group_access,
    find_build,
    find_git_reference,
    find_existing_tag_build,
    inspect_ipa,
    normalize_private_key,
    normalized_tag_condition,
    prerelease_version_id,
    run_altool,
    matching_tag_build,
    prepare_tag_trigger,
    tag_start_condition,
    validate_resumed_tag_build,
    release,
    workflow_supports_platform,
)


class XcodeCloudTestFlightTests(unittest.TestCase):
    def test_unconstrained_matcher_normalizes_apple_null_and_empty_fields(self) -> None:
        condition = tag_start_condition("v2.9.0")
        observed = copy.deepcopy(condition)
        observed["filesAndFoldersRule"]["matchers"] = [{"directory": None, "fileName": "", "fileExtension": None}]
        self.assertEqual(normalized_tag_condition(observed), condition)
        self.assertEqual(observed["filesAndFoldersRule"]["matchers"][0]["directory"], None)

    def test_matcher_normalization_preserves_actual_file_constraints(self) -> None:
        condition = tag_start_condition("v2.9.0")
        condition["filesAndFoldersRule"]["matchers"] = [{"directory": "App", "fileName": None, "fileExtension": "swift"}]
        normalized = normalized_tag_condition(condition)
        self.assertEqual(normalized["filesAndFoldersRule"]["matchers"], [{"directory": "App", "fileExtension": "swift"}])
        self.assertNotEqual(normalized, tag_start_condition("v2.9.0"))

    def tag_run_response(self) -> dict:
        return {"data": [{
            "type": "ciBuildRuns", "id": "run-162",
            "attributes": {"number": 162, "completionStatus": "FAILED", "isPullRequestBuild": False},
            "relationships": {
                "workflow": {"data": {"type": "ciWorkflows", "id": "release"}},
                "sourceBranchOrTag": {"data": {"type": "scmGitReferences", "id": "tag-id"}},
                "pullRequest": {"data": None},
            },
        }], "included": [{
            "type": "scmGitReferences", "id": "tag-id",
            "attributes": {
                "kind": "TAG", "name": "v2.9.0", "canonicalName": "refs/tags/v2.9.0",
                "isDeleted": False,
            },
        }], "links": {"next": None}}

    def test_tag_preparation_changes_only_exact_trigger_and_reads_back(self) -> None:
        condition = tag_start_condition("v2.9.0")
        before = {"data": {"attributes": {"isEnabled": True, "tagStartCondition": None},
                  "relationships": {"repository": {"data": {"id": "repo"}}}}}
        after = copy.deepcopy(before)
        after["data"]["attributes"]["tagStartCondition"] = condition
        client = MagicMock()
        client.request.side_effect = [before, {}, after]
        prepare_tag_trigger(client, workflow_id="release", repository_id="repo", tag="v2.9.0")
        self.assertEqual(client.request.call_args_list[1].kwargs, {
            "method": "PATCH", "payload": {"data": {
                "type": "ciWorkflows", "id": "release", "attributes": {"tagStartCondition": condition},
            }},
        })

    def test_tag_preparation_rejects_unsafe_pattern_or_changed_workflow(self) -> None:
        for tag in ("main", "v2.9.*", "refs/tags/v2.9.0"):
            with self.subTest(tag=tag), self.assertRaises(ReleaseError):
                tag_start_condition(tag)
        for enabled, repository, condition in (
            (False, "repo", None), (True, "another-repo", None),
            (True, "repo", {"source": {"isAllMatch": True}}),
        ):
            client = MagicMock()
            client.request.return_value = {"data": {
                "attributes": {"isEnabled": enabled, "tagStartCondition": condition},
                "relationships": {"repository": {"data": {"id": repository}}},
            }}
            with self.subTest(enabled=enabled, repository=repository, condition=condition):
                with self.assertRaises(ReleaseError):
                    prepare_tag_trigger(client, workflow_id="release", repository_id="repo", tag="v2.9.0")
                self.assertEqual(client.request.call_count, 1)

    def test_tag_preparation_requires_confirmed_readback(self) -> None:
        client = MagicMock()
        before = {"data": {"attributes": {"isEnabled": True, "tagStartCondition": None},
                  "relationships": {"repository": {"data": {"id": "repo"}}}}}
        client.request.side_effect = [before, {}, before]
        with self.assertRaisesRegex(ReleaseError, "did not confirm"):
            prepare_tag_trigger(client, workflow_id="release", repository_id="repo", tag="v2.9.0")

    def test_preparation_rolls_forward_only_a_single_managed_version_tag(self) -> None:
        before = {"data": {"attributes": {
            "isEnabled": True, "tagStartCondition": tag_start_condition("v2.9.0"),
            "manualTagStartCondition": {"source": {"isAllMatch": True, "patterns": []}},
        }, "relationships": {"repository": {"data": {"id": "repo"}}}}}
        after = copy.deepcopy(before)
        after["data"]["attributes"]["tagStartCondition"] = tag_start_condition("v2.9.1")
        client = MagicMock()
        client.request.side_effect = [before, {}, after]
        prepare_tag_trigger(client, workflow_id="release", repository_id="repo", tag="v2.9.1")
        self.assertEqual(client.request.call_args_list[1].kwargs["payload"]["data"]["attributes"], {
            "tagStartCondition": tag_start_condition("v2.9.1"),
            "manualTagStartCondition": before["data"]["attributes"]["manualTagStartCondition"],
        })

    def test_preparation_resends_and_verifies_all_existing_start_conditions(self) -> None:
        before = {"data": {"attributes": {
            "isEnabled": True, "tagStartCondition": None,
            "manualTagStartCondition": {"source": {"isAllMatch": True, "patterns": []}},
            "branchStartCondition": {"source": {"isAllMatch": False, "patterns": [{"pattern": "main", "isPrefix": False}]}},
            "scheduledStartCondition": {"schedule": "existing-schedule"},
        }, "relationships": {"repository": {"data": {"id": "repo"}}}}}
        after = copy.deepcopy(before)
        after["data"]["attributes"]["tagStartCondition"] = tag_start_condition("v2.9.0")
        client = MagicMock()
        client.request.side_effect = [before, {}, after]
        prepare_tag_trigger(client, workflow_id="release", repository_id="repo", tag="v2.9.0")
        payload = client.request.call_args_list[1].kwargs["payload"]["data"]["attributes"]
        for field in ("branchStartCondition", "scheduledStartCondition", "manualTagStartCondition"):
            self.assertEqual(payload[field], before["data"]["attributes"][field])

    def test_explicit_manual_tag_restore_recovers_prior_all_tag_setting(self) -> None:
        before = {"data": {"attributes": {"isEnabled": True, "tagStartCondition": tag_start_condition("v2.9.0")},
                  "relationships": {"repository": {"data": {"id": "repo"}}}}}
        after = copy.deepcopy(before)
        after["data"]["attributes"]["manualTagStartCondition"] = {"source": {"isAllMatch": True, "patterns": []}}
        client = MagicMock()
        client.request.side_effect = [before, {}, after]
        prepare_tag_trigger(client, workflow_id="release", repository_id="repo", tag="v2.9.0", restore_manual_tags=True)
        self.assertEqual(client.request.call_args_list[1].kwargs["payload"]["data"]["attributes"]["manualTagStartCondition"], after["data"]["attributes"]["manualTagStartCondition"])

    def test_preparation_detects_a_cleared_sibling_condition(self) -> None:
        before = {"data": {"attributes": {
            "isEnabled": True, "tagStartCondition": None,
            "manualTagStartCondition": {"source": {"isAllMatch": True, "patterns": []}},
        }, "relationships": {"repository": {"data": {"id": "repo"}}}}}
        after = copy.deepcopy(before)
        after["data"]["attributes"].update(tagStartCondition=tag_start_condition("v2.9.0"), manualTagStartCondition=None)
        client = MagicMock()
        client.request.side_effect = [before, {}, after]
        with self.assertRaisesRegex(ReleaseError, "manualTagStartCondition"):
            prepare_tag_trigger(client, workflow_id="release", repository_id="repo", tag="v2.9.0")

    def test_same_tag_preparation_is_idempotent(self) -> None:
        client = MagicMock()
        client.request.return_value = {"data": {"attributes": {
            "isEnabled": True, "tagStartCondition": tag_start_condition("v2.9.0"),
        }, "relationships": {"repository": {"data": {"id": "repo"}}}}}
        prepare_tag_trigger(client, workflow_id="release", repository_id="repo", tag="v2.9.0")
        self.assertEqual(client.request.call_count, 2)
        self.assertTrue(all(call.kwargs.get("method", "GET") == "GET" for call in client.request.call_args_list))

    def test_preparation_preserves_custom_trigger_configuration(self) -> None:
        for change in ("prefix", "all", "multiple", "files", "cancel"):
            condition = tag_start_condition("v2.8.1")
            if change == "prefix": condition["source"]["patterns"][0]["isPrefix"] = True
            if change == "all": condition["source"]["isAllMatch"] = True
            if change == "multiple": condition["source"]["patterns"].append({"pattern": "v2.8.2", "isPrefix": False})
            if change == "files": condition["filesAndFoldersRule"]["matchers"] = [{"directory": "App"}]
            if change == "cancel": condition["autoCancel"] = True
            client = MagicMock()
            client.request.return_value = {"data": {"attributes": {
                "isEnabled": True, "tagStartCondition": condition,
            }, "relationships": {"repository": {"data": {"id": "repo"}}}}}
            with self.subTest(change=change), self.assertRaises(ReleaseError):
                prepare_tag_trigger(client, workflow_id="release", repository_id="repo", tag="v2.9.0")
            self.assertEqual(client.request.call_count, 1)

    def test_matching_tag_build_accepts_recoverable_failed_exports(self) -> None:
        response = self.tag_run_response()
        self.assertEqual(matching_tag_build(response, workflow_id="release", tag="v2.9.0")["id"], "run-162")

    def test_matching_tag_build_rejects_other_sources(self) -> None:
        for change in ("workflow", "branch", "tag", "deleted", "canceled", "pr", "missing_ref"):
            response = self.tag_run_response()
            run = response["data"][0]
            ref = response["included"][0]["attributes"]
            if change == "workflow": run["relationships"]["workflow"]["data"]["id"] = "other"
            if change == "branch": ref["kind"] = "BRANCH"
            if change == "tag": ref["name"] = "v2.8.1"
            if change == "deleted": ref["isDeleted"] = True
            if change == "canceled": run["attributes"]["completionStatus"] = "CANCELED"
            if change == "pr": run["attributes"]["isPullRequestBuild"] = True
            if change == "missing_ref": response["included"] = []
            with self.subTest(change=change):
                self.assertIsNone(matching_tag_build(response, workflow_id="release", tag="v2.9.0"))

    def test_existing_tag_build_preserves_included_resources_across_pages(self) -> None:
        client = MagicMock()
        client.request.side_effect = [{"data": [], "links": {"next": "next-page"}}, self.tag_run_response()]
        self.assertEqual(find_existing_tag_build(client, workflow_id="release", tag="v2.9.0"), ("run-162", "162"))
        self.assertEqual(client.request.call_args_list[1].args, ("next-page",))

    def test_existing_tag_build_waits_for_automatic_start(self) -> None:
        client = MagicMock()
        client.request.side_effect = [{"data": [], "links": {}}, self.tag_run_response()]
        with patch("ci_scripts.xcode_cloud_testflight.time.sleep") as sleep:
            self.assertEqual(find_existing_tag_build(client, workflow_id="release", tag="v2.9.0", timeout_seconds=60), ("run-162", "162"))
        sleep.assert_called_once()

    def test_resumed_run_must_match_tag_and_workflow(self) -> None:
        client = MagicMock()
        response = self.tag_run_response()
        response["data"] = response["data"][0]
        client.request.return_value = response
        self.assertEqual(validate_resumed_tag_build(client, build_run_id="run-162", workflow_id="release", tag="v2.9.0"), ("run-162", "162"))
        with self.assertRaisesRegex(ReleaseError, "does not match"):
            validate_resumed_tag_build(client, build_run_id="run-162", workflow_id="release", tag="v2.8.1")

    def test_prepare_only_never_discovers_builds_or_publishes(self) -> None:
        args = argparse.Namespace(tag="v2.9.0", platform="all", workflow_id="release", repository_id="repo", prepare_tag_trigger=True, build_run_id="", force_new_build=False)
        with (
            patch.dict("os.environ", {"APP_STORE_CONNECT_APP_ID": "app", "APP_STORE_CONNECT_KEY_ID": "key", "APP_STORE_CONNECT_PRIVATE_KEY": "placeholder"}, clear=True),
            patch("ci_scripts.xcode_cloud_testflight.AppStoreConnectClient"),
            patch("ci_scripts.xcode_cloud_testflight.resolve_workflows", return_value={"release": list(PLATFORMS.values())}),
            patch("ci_scripts.xcode_cloud_testflight.prepare_tag_trigger") as prepare,
            patch("ci_scripts.xcode_cloud_testflight.find_existing_tag_build") as find,
            patch("ci_scripts.xcode_cloud_testflight.find_git_reference") as reference,
            patch("ci_scripts.xcode_cloud_testflight.start_build_run") as start,
            patch("ci_scripts.xcode_cloud_testflight.publish_platform") as publish,
        ):
            release(args)
        prepare.assert_called_once()
        find.assert_not_called()
        reference.assert_not_called()
        start.assert_not_called()
        publish.assert_not_called()

    def test_release_reuses_automatic_run_before_reference_lookup(self) -> None:
        args = argparse.Namespace(
            tag="v2.9.0", platform="all", workflow_id="release", repository_id="repo",
            prepare_tag_trigger=False, build_run_id="", output_dir=None, force_new_build=False,
            cloud_timeout_seconds=1800, poll_seconds=20,
        )
        with (
            patch.dict("os.environ", {"APP_STORE_CONNECT_APP_ID": "app", "APP_STORE_CONNECT_KEY_ID": "key", "APP_STORE_CONNECT_PRIVATE_KEY": "placeholder"}, clear=True),
            patch("ci_scripts.xcode_cloud_testflight.AppStoreConnectClient"),
            patch("ci_scripts.xcode_cloud_testflight.resolve_workflows", return_value={"release": list(PLATFORMS.values())}),
            patch("ci_scripts.xcode_cloud_testflight.find_existing_tag_build", return_value=("auto-run", "162")),
            patch("ci_scripts.xcode_cloud_testflight.find_git_reference") as reference,
            patch("ci_scripts.xcode_cloud_testflight.start_build_run") as start,
            patch("ci_scripts.xcode_cloud_testflight.wait_for_export", return_value=({}, "162")),
            patch("ci_scripts.xcode_cloud_testflight.publish_platform") as publish,
        ):
            release(args)
        reference.assert_not_called()
        start.assert_not_called()
        self.assertEqual(publish.call_count, 2)

    def test_automatic_run_appearing_after_first_lookup_bypasses_stale_tag_index(self) -> None:
        args = argparse.Namespace(
            tag="v2.9.0", platform="all", workflow_id="release", repository_id="repo",
            prepare_tag_trigger=False, build_run_id="", output_dir=None, force_new_build=False,
            cloud_timeout_seconds=1800, poll_seconds=20,
        )
        with (
            patch.dict("os.environ", {"APP_STORE_CONNECT_APP_ID": "app", "APP_STORE_CONNECT_KEY_ID": "key", "APP_STORE_CONNECT_PRIVATE_KEY": "placeholder"}, clear=True),
            patch("ci_scripts.xcode_cloud_testflight.AppStoreConnectClient") as client,
            patch("ci_scripts.xcode_cloud_testflight.resolve_workflows", return_value={"release": list(PLATFORMS.values())}),
            patch("ci_scripts.xcode_cloud_testflight.find_existing_tag_build", side_effect=[None, ("auto-run", "162")]),
            patch("ci_scripts.xcode_cloud_testflight.find_git_reference", side_effect=ReleaseError("stale tag index")) as reference,
            patch("ci_scripts.xcode_cloud_testflight.start_build_run") as start,
            patch("ci_scripts.xcode_cloud_testflight.wait_for_export", return_value=({}, "162")),
            patch("ci_scripts.xcode_cloud_testflight.publish_platform") as publish,
        ):
            client.return_value.request.return_value = {"data": {"attributes": {"tagStartCondition": tag_start_condition("v2.9.0")}}}
            release(args)
        reference.assert_not_called()
        start.assert_not_called()
        self.assertEqual(publish.call_count, 2)

    def test_fresh_retry_bypasses_failed_run_recovery(self) -> None:
        args = argparse.Namespace(
            tag="v2.9.0", platform="all", workflow_id="release", repository_id="repo",
            prepare_tag_trigger=False, build_run_id="", output_dir=None, force_new_build=True,
            cloud_timeout_seconds=1800, poll_seconds=20,
        )
        with (
            patch.dict("os.environ", {"APP_STORE_CONNECT_APP_ID": "app", "APP_STORE_CONNECT_KEY_ID": "key", "APP_STORE_CONNECT_PRIVATE_KEY": "placeholder"}, clear=True),
            patch("ci_scripts.xcode_cloud_testflight.AppStoreConnectClient"),
            patch("ci_scripts.xcode_cloud_testflight.resolve_workflows", return_value={"release": list(PLATFORMS.values())}),
            patch("ci_scripts.xcode_cloud_testflight.find_existing_tag_build") as recover,
            patch("ci_scripts.xcode_cloud_testflight.find_git_reference", return_value="exact-tag") as reference,
            patch("ci_scripts.xcode_cloud_testflight.start_build_run", return_value=("fresh-run", "163")) as start,
            patch("ci_scripts.xcode_cloud_testflight.wait_for_export", return_value=({}, "163")),
            patch("ci_scripts.xcode_cloud_testflight.publish_platform") as publish,
        ):
            release(args)
        recover.assert_not_called()
        reference.assert_called_once()
        start.assert_called_once()
        self.assertEqual(start.call_args.kwargs["git_reference_id"], "exact-tag")
        self.assertEqual(publish.call_count, 2)


    def test_git_tag_waits_for_reference_sync(self) -> None:
        client = MagicMock()
        client.pages.side_effect = [[], [{"id": "tag-id", "attributes": {
            "name": "v2.7.0", "kind": "TAG", "isDeleted": False,
        }}]]
        with patch("ci_scripts.xcode_cloud_testflight.time.sleep") as sleep:
            self.assertEqual(find_git_reference(client, "repo", "v2.7.0"), "tag-id")
        self.assertEqual(client.pages.call_count, 2)
        sleep.assert_called_once()

    def test_git_tag_never_falls_back_to_branch_or_deleted_tag(self) -> None:
        client = MagicMock()
        client.pages.return_value = [{"id": "wrong", "attributes": {
            "name": "v2.7.0", "kind": kind, "isDeleted": deleted,
        }} for kind, deleted in [("BRANCH", False), ("TAG", True)]]
        with self.assertRaisesRegex(ReleaseError, "cannot see Git tag"):
            find_git_reference(client, "repo", "v2.7.0", timeout_seconds=0)

    def test_missing_git_tag_times_out(self) -> None:
        client = MagicMock()
        client.pages.return_value = []
        with (
            patch("ci_scripts.xcode_cloud_testflight.time.monotonic", side_effect=[0, 0, 181]),
            patch("ci_scripts.xcode_cloud_testflight.time.sleep") as sleep,
            self.assertRaisesRegex(ReleaseError, "after 180s"),
        ):
            find_git_reference(client, "repo", "v2.7.0")
        sleep.assert_called_once_with(15)

    def test_normalizes_escaped_private_key(self) -> None:
        self.assertEqual(
            normalize_private_key("BEGIN\\nsecret\\nEND"),
            "BEGIN\nsecret\nEND\n",
        )

    def test_team_token_uses_issuer(self) -> None:
        client = AppStoreConnectClient(
            key_id="key",
            issuer_id="issuer",
            private_key="not used in this test",
        )
        self.assertEqual(client.issuer_id, "issuer")

    def test_get_retries_transient_app_store_connect_timeout(self) -> None:
        client = AppStoreConnectClient(
            key_id="key",
            issuer_id="issuer",
            private_key="not used in this test",
        )
        response = MagicMock()
        response.__enter__.return_value.read.return_value = b'{"data": []}'
        with (
            patch.object(client, "token", return_value="token"),
            patch(
                "ci_scripts.xcode_cloud_testflight.urllib.request.urlopen",
                side_effect=[urllib.error.URLError("timed out"), response],
            ) as urlopen,
            patch("ci_scripts.xcode_cloud_testflight.time.sleep") as sleep,
        ):
            result = client.request("/v1/builds")

        self.assertEqual(result, {"data": []})
        self.assertEqual(urlopen.call_count, 2)
        sleep.assert_called_once_with(2)

    def test_selects_only_app_store_export(self) -> None:
        artifacts = [
            {
                "attributes": {
                    "fileType": "LOG_BUNDLE",
                    "fileName": "logs.zip",
                }
            },
            {
                "id": "expected",
                "attributes": {
                    "fileType": "ARCHIVE_EXPORT",
                    "fileName": "Mather 2.6.94 app-store.zip",
                },
            },
        ]
        self.assertEqual(
            choose_app_store_export(artifacts, platform=PLATFORMS["tvos"])["id"],
            "expected",
        )

    def test_matches_archive_workflow_by_platform(self) -> None:
        workflow = {
            "id": "shared",
            "attributes": {
                "actions": [
                    {"actionType": "ARCHIVE", "platform": "IOS"},
                    {"actionType": "ARCHIVE", "platform": "TVOS"},
                ]
            },
        }
        self.assertTrue(workflow_supports_platform(workflow, PLATFORMS["ios"]))
        self.assertTrue(workflow_supports_platform(workflow, PLATFORMS["tvos"]))

    def test_prefers_manual_release_workflow_for_ios(self) -> None:
        workflows = [
            {
                "id": "automatic",
                "attributes": {
                    "name": "Continuous Integration",
                    "isEnabled": True,
                    "actions": [{"actionType": "ARCHIVE", "platform": "IOS"}],
                },
            },
            {
                "id": "release",
                "attributes": {
                    "name": "TestFlight Release",
                    "isEnabled": True,
                    "manualTagStartCondition": {"source": {}},
                    "actions": [{"actionType": "ARCHIVE", "platform": "IOS"}],
                },
            },
        ]
        selected = choose_workflow_for_platform(workflows, PLATFORMS["ios"])
        self.assertEqual(selected["id"], "release")

    def test_rejects_missing_ios_archive_workflow(self) -> None:
        workflows = [
            {
                "id": "tvos-only",
                "attributes": {
                    "name": "tvOS Release",
                    "isEnabled": True,
                    "actions": [{"actionType": "ARCHIVE", "platform": "TVOS"}],
                },
            }
        ]
        with self.assertRaises(ReleaseError):
            choose_workflow_for_platform(workflows, PLATFORMS["ios"])

    def test_rejects_ambiguous_app_store_exports(self) -> None:
        artifacts = [
            {
                "attributes": {
                    "fileType": "ARCHIVE_EXPORT",
                    "fileName": f"Mather {index} app-store.zip",
                }
            }
            for index in range(2)
        ]
        with self.assertRaises(ReleaseError):
            choose_app_store_export(artifacts, platform=PLATFORMS["ios"])

    def test_finds_expected_build_number(self) -> None:
        builds = [
            {"id": "old", "attributes": {"version": "148"}},
            {"id": "new", "attributes": {"version": "149"}},
        ]
        self.assertEqual(find_build(builds, "149")["id"], "new")
        self.assertIsNone(find_build(builds, "150"))

    def test_selects_platform_specific_prerelease_version(self) -> None:
        class Client:
            def pages(self, _: str) -> list[dict]:
                return [
                    {"id": "ios", "attributes": {"platform": "IOS"}},
                    {"id": "tvos", "attributes": {"platform": "TV_OS"}},
                ]

        client = Client()
        self.assertEqual(
            prerelease_version_id(
                client,
                app_id="app",
                version="2.6.103",
                platform=PLATFORMS["ios"],
            ),
            "ios",
        )
        self.assertEqual(
            prerelease_version_id(
                client,
                app_id="app",
                version="2.6.103",
                platform=PLATFORMS["tvos"],
            ),
            "tvos",
        )

    def test_adds_valid_build_to_only_missing_internal_beta_groups(self) -> None:
        client = MagicMock()
        client.pages.side_effect = [
            [
                {
                    "type": "betaGroups",
                    "id": "internal-current",
                    "attributes": {
                        "name": "Family",
                        "isInternalGroup": True,
                        "hasAccessToAllBuilds": False,
                    },
                },
                {
                    "type": "betaGroups",
                    "id": "internal-missing",
                    "attributes": {
                        "name": "Developers",
                        "isInternalGroup": True,
                        "hasAccessToAllBuilds": False,
                    },
                },
                {
                    "type": "betaGroups",
                    "id": "external",
                    "attributes": {
                        "name": "Public Beta",
                        "isInternalGroup": False,
                        "hasAccessToAllBuilds": False,
                    },
                },
            ],
            [{"type": "builds", "id": "build-160"}],
            [{"type": "builds", "id": "older-build"}],
        ]
        build = {
            "type": "builds",
            "id": "build-160",
            "attributes": {"version": "160", "processingState": "VALID"},
        }

        added = ensure_internal_beta_group_access(
            client,
            app_id="app-1",
            build=build,
        )

        self.assertEqual([group["id"] for group in added], ["internal-missing"])
        self.assertEqual(client.pages.call_count, 3)
        self.assertEqual(
            client.pages.call_args_list[0].args[0],
            "/v1/apps/app-1/betaGroups"
            "?fields[betaGroups]=name,isInternalGroup,hasAccessToAllBuilds&limit=200",
        )
        client.request.assert_called_once_with(
            "/v1/builds/build-160/relationships/betaGroups",
            method="POST",
            payload={
                "data": [
                    {"type": "betaGroups", "id": "internal-missing"}
                ]
            },
        )

    def test_skips_beta_group_post_when_valid_build_is_already_internal(self) -> None:
        client = MagicMock()
        client.pages.side_effect = [
            [
                {
                    "type": "betaGroups",
                    "id": "internal",
                    "attributes": {
                        "name": "Family",
                        "isInternalGroup": True,
                        "hasAccessToAllBuilds": True,
                    },
                }
            ],
            [{"type": "builds", "id": "build-160"}],
        ]

        added = ensure_internal_beta_group_access(
            client,
            app_id="app-1",
            build={
                "type": "builds",
                "id": "build-160",
                "attributes": {"processingState": "VALID"},
            },
        )

        self.assertEqual(added, [])
        client.request.assert_not_called()

    def test_rejects_beta_group_assignment_before_build_is_valid(self) -> None:
        client = MagicMock()

        with self.assertRaisesRegex(ReleaseError, "not VALID"):
            ensure_internal_beta_group_access(
                client,
                app_id="app-1",
                build={
                    "type": "builds",
                    "id": "build-160",
                    "attributes": {"processingState": "PROCESSING"},
                },
            )

        client.pages.assert_not_called()
        client.request.assert_not_called()

    def test_rejects_individual_key_for_altool(self) -> None:
        with self.assertRaises(ReleaseError):
            altool_auth_args(key_id="KEY", issuer_id="")

    def test_team_key_altool_arguments(self) -> None:
        args = altool_auth_args(key_id="KEY", issuer_id="ISSUER")
        self.assertEqual(args, ["--apiKey", "KEY", "--apiIssuer", "ISSUER"])

    def test_validate_app_uses_file_and_tvos_options(self) -> None:
        args = altool_command_args(
            "--validate-app",
            platform=PLATFORMS["tvos"],
            ipa_path=Path("/tmp/MatherTV.ipa"),
            key_id="KEY",
            issuer_id="ISSUER",
        )
        self.assertEqual(
            args[:8],
            [
                "xcrun",
                "altool",
                "--validate-app",
                "-f",
                "/tmp/MatherTV.ipa",
                "-t",
                "tvos",
                "--apiKey",
            ],
        )

    def test_upload_app_uses_file_and_tvos_options(self) -> None:
        args = altool_command_args(
            "--upload-app",
            platform=PLATFORMS["tvos"],
            ipa_path=Path("/tmp/MatherTV.ipa"),
            key_id="KEY",
            issuer_id="ISSUER",
        )
        self.assertEqual(args[2:7], [
            "--upload-app",
            "-f",
            "/tmp/MatherTV.ipa",
            "-t",
            "tvos",
        ])

    def test_upload_app_uses_ios_options(self) -> None:
        args = altool_command_args(
            "--upload-app",
            platform=PLATFORMS["ios"],
            ipa_path=Path("/tmp/Mather.ipa"),
            key_id="KEY",
            issuer_id="ISSUER",
        )
        self.assertEqual(args[2:7], [
            "--upload-app",
            "-f",
            "/tmp/Mather.ipa",
            "-t",
            "ios",
        ])

    def test_rejects_unknown_altool_command(self) -> None:
        with self.assertRaises(ReleaseError):
            altool_command_args(
                "--delete-app",
                platform=PLATFORMS["tvos"],
                ipa_path=Path("/tmp/MatherTV.ipa"),
                key_id="KEY",
                issuer_id="ISSUER",
            )

    def test_altool_runs_beside_standard_private_keys_directory(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            workspace = Path(directory)
            key_path = workspace / "private_keys" / "AuthKey_KEY.p8"
            with patch("ci_scripts.xcode_cloud_testflight.subprocess.run") as run:
                run_altool(
                    "--validate-app",
                    platform=PLATFORMS["tvos"],
                    ipa_path=workspace / "MatherTV.ipa",
                    key_id="KEY",
                    issuer_id="ISSUER",
                    private_key_path=key_path,
                )
        run.assert_called_once()
        self.assertEqual(run.call_args.kwargs["cwd"], workspace)
        self.assertTrue(run.call_args.kwargs["check"])

    def test_inspects_expected_tvos_ipa(self) -> None:
        info = {
            "CFBundleIdentifier": "com.ganesh47.Mather",
            "CFBundleShortVersionString": "2.6.94",
            "CFBundleVersion": "149",
            "CFBundleSupportedPlatforms": ["AppleTVOS"],
            "ITSAppUsesNonExemptEncryption": False,
        }
        with tempfile.TemporaryDirectory() as directory:
            ipa_path = Path(directory) / "MatherTV.ipa"
            with zipfile.ZipFile(ipa_path, "w") as archive:
                archive.writestr(
                    "Payload/MatherTV.app/Info.plist",
                    plistlib.dumps(info),
                )
            observed = inspect_ipa(
                ipa_path,
                platform=PLATFORMS["tvos"],
                expected_bundle_id="com.ganesh47.Mather",
                expected_version="2.6.94",
                expected_build_number="149",
            )
        self.assertEqual(observed["CFBundleVersion"], "149")

    def test_inspects_expected_ios_ipa(self) -> None:
        info = {
            "CFBundleIdentifier": "com.ganesh47.Mather",
            "CFBundleShortVersionString": "2.6.103",
            "CFBundleVersion": "158",
            "CFBundleSupportedPlatforms": ["iPhoneOS"],
            "ITSAppUsesNonExemptEncryption": False,
        }
        with tempfile.TemporaryDirectory() as directory:
            ipa_path = Path(directory) / "Mather.ipa"
            with zipfile.ZipFile(ipa_path, "w") as archive:
                archive.writestr(
                    "Payload/Mather.app/Info.plist",
                    plistlib.dumps(info),
                )
            observed = inspect_ipa(
                ipa_path,
                platform=PLATFORMS["ios"],
                expected_bundle_id="com.ganesh47.Mather",
                expected_version="2.6.103",
                expected_build_number="158",
            )
        self.assertEqual(observed["CFBundleSupportedPlatforms"], ["iPhoneOS"])

    def test_rejects_ipa_for_wrong_platform(self) -> None:
        info = {
            "CFBundleIdentifier": "com.ganesh47.Mather",
            "CFBundleShortVersionString": "2.6.103",
            "CFBundleVersion": "158",
            "CFBundleSupportedPlatforms": ["AppleTVOS"],
            "ITSAppUsesNonExemptEncryption": False,
        }
        with tempfile.TemporaryDirectory() as directory:
            ipa_path = Path(directory) / "MatherTV.ipa"
            with zipfile.ZipFile(ipa_path, "w") as archive:
                archive.writestr(
                    "Payload/MatherTV.app/Info.plist",
                    plistlib.dumps(info),
                )
            with self.assertRaises(ReleaseError):
                inspect_ipa(
                    ipa_path,
                    platform=PLATFORMS["ios"],
                    expected_bundle_id="com.ganesh47.Mather",
                    expected_version="2.6.103",
                    expected_build_number="158",
                )

    def test_rejects_wrong_build_number(self) -> None:
        info = {
            "CFBundleIdentifier": "com.ganesh47.Mather",
            "CFBundleShortVersionString": "2.6.94",
            "CFBundleVersion": "148",
            "CFBundleSupportedPlatforms": ["AppleTVOS"],
            "ITSAppUsesNonExemptEncryption": False,
        }
        with tempfile.TemporaryDirectory() as directory:
            ipa_path = Path(directory) / "MatherTV.ipa"
            with zipfile.ZipFile(ipa_path, "w") as archive:
                archive.writestr(
                    "Payload/MatherTV.app/Info.plist",
                    plistlib.dumps(info),
                )
            with self.assertRaises(ReleaseError):
                inspect_ipa(
                    ipa_path,
                    platform=PLATFORMS["tvos"],
                    expected_bundle_id="com.ganesh47.Mather",
                    expected_version="2.6.94",
                    expected_build_number="149",
                )


if __name__ == "__main__":
    unittest.main()
