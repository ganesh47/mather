#!/bin/bash
set -euo pipefail
repo_dir="$(cd "$(dirname "$0")/.." && pwd)"
task_dir="$(mktemp -d "${TMPDIR:-/tmp}/mather-companion-tests.XXXXXX")"
trap 'rm -rf "$task_dir"' EXIT
mkdir -p "$task_dir/Sources/Mather" "$task_dir/Tests/MatherTests"
cp "$repo_dir/Domain/LearningHandoff.swift" "$repo_dir/Services/LearningHandoffStore.swift" "$task_dir/Sources/Mather/"
cp "$repo_dir/Tests/MatherTests/LearningHandoffTests.swift" "$task_dir/Tests/MatherTests/"
cat > "$task_dir/Package.swift" <<'PACKAGE'
// swift-tools-version: 6.0
import PackageDescription
let package = Package(name: "ManualCompanionProof", platforms: [.macOS(.v14)],
    products: [.library(name: "Mather", targets: ["Mather"])],
    targets: [.target(name: "Mather"), .testTarget(name: "MatherTests", dependencies: ["Mather"])])
PACKAGE
swift test --disable-sandbox --package-path "$task_dir" --jobs 2
