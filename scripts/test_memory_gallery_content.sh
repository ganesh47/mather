#!/bin/bash
set -euo pipefail
repo_root=$(cd "$(dirname "$0")/.." && pwd)
task_dir=$(mktemp -d)
trap 'rm -rf "$task_dir"' EXIT
swiftc -swift-version 6 -parse-as-library -target "$(uname -m)-apple-macosx14.0" \
    "$repo_root/Domain/MemoryContent.swift" \
    "$repo_root/Domain/MemoryGalleryTVRound.swift" \
    "$repo_root/Domain/MemoryGalleryContentPack.swift" \
    "$repo_root/Services/MemoryGalleryContentStore.swift" \
    "$repo_root/scripts/MemoryGalleryContentSmoke.swift" \
    -o "$task_dir/smoke"
"$task_dir/smoke" "$@"
