import unittest
from ci_scripts.resolve_cloud_release_tag import release_tag_for_commit


class CloudReleaseTagTests(unittest.TestCase):
    def test_lightweight_and_peeled_annotated_tags(self):
        head = "a" * 40
        for refs in [f"{head} refs/tags/v2.9.0\n", f"{'b' * 40} refs/tags/v2.9.0\n{head} refs/tags/v2.9.0^{{}}\n"]:
            self.assertEqual(release_tag_for_commit(head, refs), "v2.9.0")

    def test_branch_dev_commits_and_nonversion_tags_do_not_stamp(self):
        head = "a" * 40
        refs = f"{head} refs/tags/latest\n{head} refs/tags/v2.9.0-dev\n{'b' * 40} refs/tags/v2.9.0\n"
        self.assertEqual(release_tag_for_commit(head, refs), "")

    def test_multiple_matching_versions_require_explicit_tag(self):
        head = "a" * 40
        refs = f"{head} refs/tags/v2.9.0\n{head} refs/tags/v2.9.1\n"
        with self.assertRaisesRegex(ValueError, "Multiple release versions"):
            release_tag_for_commit(head, refs)
        self.assertEqual(release_tag_for_commit(head, refs, "v2.9.1"), "v2.9.1")

    def test_requested_tag_must_match_head_and_be_valid(self):
        head = "a" * 40
        refs = f"{'b' * 40} refs/tags/v2.9.0\n"
        for tag in ["v2.9.0", "main", "v2.9.0-dev"]:
            with self.assertRaises(ValueError):
                release_tag_for_commit(head, refs, tag)
