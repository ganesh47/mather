import unittest
import plistlib
import tempfile
import zipfile
from pathlib import Path

from ci_scripts.xcode_cloud_testflight import (
    AppStoreConnectClient,
    ReleaseError,
    altool_auth_args,
    choose_app_store_export,
    find_build,
    inspect_ipa,
    normalize_private_key,
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
        self.assertEqual(choose_app_store_export(artifacts)["id"], "expected")

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
            choose_app_store_export(artifacts)

    def test_finds_expected_build_number(self) -> None:
        builds = [
            {"id": "old", "attributes": {"version": "148"}},
            {"id": "new", "attributes": {"version": "149"}},
        ]
        self.assertEqual(find_build(builds, "149")["id"], "new")
        self.assertIsNone(find_build(builds, "150"))

    def test_individual_key_altool_arguments(self) -> None:
        args = altool_auth_args(
            key_id="KEY",
            issuer_id="",
            private_key_path=__import__("pathlib").Path("/tmp/key.p8"),
        )
        self.assertIn("--api-key-subject", args)
        self.assertIn("user", args)

    def test_team_key_altool_arguments(self) -> None:
        args = altool_auth_args(
            key_id="KEY",
            issuer_id="ISSUER",
            private_key_path=__import__("pathlib").Path("/tmp/key.p8"),
        )
        self.assertNotIn("--api-key-subject", args)
        self.assertIn("ISSUER", args)

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
                expected_bundle_id="com.ganesh47.Mather",
                expected_version="2.6.94",
                expected_build_number="149",
            )
        self.assertEqual(observed["CFBundleVersion"], "149")

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
                    expected_bundle_id="com.ganesh47.Mather",
                    expected_version="2.6.94",
                    expected_build_number="149",
                )


if __name__ == "__main__":
    unittest.main()
