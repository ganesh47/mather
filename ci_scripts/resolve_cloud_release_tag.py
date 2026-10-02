#!/usr/bin/env python3
"""Resolve a release version only from remote tags on the exact checked-out commit."""
import os
import re
import subprocess
import sys

VERSION_TAG = re.compile(r"v[0-9]+\.[0-9]+\.[0-9]+")


def release_tag_for_commit(head, references, requested_tag=""):
    refs = {}
    for line in references.splitlines():
        parts = line.split()
        if len(parts) != 2:
            continue
        sha, ref = parts
        if not re.fullmatch(r"[0-9a-fA-F]{40}", sha):
            continue
        refs[ref] = sha.lower()
    tags = {}
    for ref, sha in refs.items():
        if not ref.startswith("refs/tags/") or ref.endswith("^{}"):
            continue
        tag = ref.removeprefix("refs/tags/")
        if VERSION_TAG.fullmatch(tag):
            tags[tag] = refs.get(ref + "^{}", sha)
    if requested_tag:
        if not VERSION_TAG.fullmatch(requested_tag) or tags.get(requested_tag) != head.lower():
            raise ValueError("The requested release tag does not match the checked-out commit")
        return requested_tag
    matches = [tag for tag, sha in tags.items() if sha == head.lower()]
    if len(matches) > 1:
        raise ValueError("Multiple release versions point at this commit; an explicit release tag is required")
    return matches[0] if matches else ""


def main():
    head = subprocess.check_output(["git", "rev-parse", "HEAD"], text=True).strip()
    refs = subprocess.check_output(["git", "ls-remote", "--tags", "origin", "refs/tags/v*"], text=True)
    try:
        tag = release_tag_for_commit(head, refs, os.environ.get("CI_TAG", ""))
    except ValueError as error:
        print(str(error), file=sys.stderr)
        return 1
    if tag:
        print(tag.removeprefix("v"))
    return 0


if __name__ == "__main__":
    sys.exit(main())
