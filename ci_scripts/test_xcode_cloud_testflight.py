import unittest
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
    find_build,
    inspect_ipa,
    normalize_private_key,
    prerelease_version_id,
    run_altool,
    workflow_supports_platform,
)


class XcodeCloudTestFlightTests(unittest.TestCase):
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
