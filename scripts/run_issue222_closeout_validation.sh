#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

SCHEME="Mather"
TEST_ID="MatherUITests/ScreenshotTests/testScreenshot_Issue222LoopV2_AcrossTwoTargets"
TIMESTAMP="$(date -u +"%Y%m%dT%H%M%SZ")"
ARTIFACT_DIR="$ROOT_DIR/artifacts/issue222-closeout-validation/$TIMESTAMP"

SIMULATOR_NAMES=(
  "iPhone 16"
  "iPad Pro 13-inch (M4)"
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
  if grep -q 'BlueprintName = "MatherUITests"' "$ROOT_DIR/Mather.xcodeproj/xcshareddata/xcschemes/Mather.xcscheme" 2>/dev/null || \
     grep -q 'MatherUITests' "$ROOT_DIR/Mather.xcodeproj/project.pbxproj"; then
    echo "xcodegen not found; using the checked-in Mather.xcodeproj."
  else
    echo "error: xcodegen is not installed and the checked-in Mather.xcodeproj does not include MatherUITests." >&2
    echo "hint: install xcodegen or prepend a temporary xcodegen binary to PATH before running this script." >&2
    exit 1
  fi
else
  echo "error: xcodegen is not installed and Mather.xcodeproj is missing." >&2
  exit 1
fi

resolve_simulator_id() {
  local simulator_name="$1"
  xcrun simctl list devices available | awk -v name="$simulator_name" '
    index($0, name " (") {
      if (match($0, /\(([0-9A-F-]+)\)/)) {
        print substr($0, RSTART + 1, RLENGTH - 2)
        exit
      }
    }
  '
}

for simulator_name in "${SIMULATOR_NAMES[@]}"; do
  simulator_id="$(resolve_simulator_id "$simulator_name")"
  if [[ -z "$simulator_id" ]]; then
    echo "error: could not find an available simulator named '$simulator_name'." >&2
    exit 1
  fi

  result_name="${simulator_name// /-}"
  result_bundle="$ARTIFACT_DIR/${result_name}.xcresult"

  echo
  echo "Running $TEST_ID on $simulator_name ($simulator_id)"
  echo "Result bundle: $result_bundle"

  xcodebuild test \
    -project Mather.xcodeproj \
    -scheme "$SCHEME" \
    -destination "id=$simulator_id" \
    -only-testing:"$TEST_ID" \
    -resultBundlePath "$result_bundle" \
    CODE_SIGNING_ALLOWED=NO
done

echo
echo "Issue #222 closeout validation complete."
echo "xcresult bundles:"
find "$ARTIFACT_DIR" -maxdepth 1 -name '*.xcresult' -print | sort
