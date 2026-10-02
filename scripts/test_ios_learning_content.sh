#!/bin/bash
set -euo pipefail
repo_root=$(cd "$(dirname "$0")/.." && pwd)
task_dir=$(mktemp -d)
trap 'rm -rf "$task_dir"' EXIT
source "$repo_root/scripts/ios_learning_sources.sh"
swiftc -swift-version 6 -parse-as-library -target "$(uname -m)-apple-macosx14.0" \
    "${ios_learning_sources[@]}" "$repo_root/Services/IOSLearningContentStore.swift" \
    "$repo_root/scripts/IOSLearningContentSmoke.swift" -o "$task_dir/smoke"
"$task_dir/smoke" "$@"
