#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

SCHEME="Mather"
TEST_ID="MatherUITests/ScreenshotTests/testScreenshot_Issue222LoopV2_AcrossTwoTargets"
TIMESTAMP="$(date -u +"%Y%m%dT%H%M%SZ")"
ARTIFACT_DIR="$ROOT_DIR/artifacts/issue222-closeout-validation/$TIMESTAMP"

DESTINATIONS=(
  "platform=iOS Simulator,name=iPhone 16,OS=latest"
  "platform=iOS Simulator,name=iPad Pro 13-inch (M4),OS=latest"
)

mkdir -p "$ARTIFACT_DIR"

if ! command -v xcodebuild >/dev/null 2>&1; then
  echo "error: xcodebuild is required to run simulator validation." >&2
  exit 1
fi

if command -v xcodegen >/dev/null 2>&1; then
  echo "Generating Xcode project..."
  xcodegen generate
elif [[ -f "$ROOT_DIR/Mather.xcodeproj/project.pbxproj" ]]; then
  echo "xcodegen not found; using the checked-in Mather.xcodeproj."
else
  echo "error: xcodegen is not installed and Mather.xcodeproj is missing." >&2
  exit 1
fi

for destination in "${DESTINATIONS[@]}"; do
  simulator_name="$(sed -E 's/.*name=([^,]+).*/\1/' <<<"$destination")"
  result_name="${simulator_name// /-}"
  result_bundle="$ARTIFACT_DIR/${result_name}.xcresult"

  echo
  echo "Running $TEST_ID on $simulator_name"
  echo "Result bundle: $result_bundle"

  xcodebuild test \
    -project Mather.xcodeproj \
    -scheme "$SCHEME" \
    -destination "$destination" \
    -only-testing:"$TEST_ID" \
    -resultBundlePath "$result_bundle" \
    CODE_SIGNING_ALLOWED=NO
done

echo
echo "Issue #222 closeout validation complete."
echo "xcresult bundles:"
find "$ARTIFACT_DIR" -maxdepth 1 -name '*.xcresult' -print | sort
