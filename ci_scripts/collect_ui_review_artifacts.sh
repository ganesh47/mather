#!/usr/bin/env bash
set -euo pipefail

DEVICE_FAMILY="${DEVICE_FAMILY:-iphone}"
BUNDLE="${1:-UITestResults-${DEVICE_FAMILY}.xcresult}"
VIDEO="${2:-ci-videos/ui-tests-${DEVICE_FAMILY}.mp4}"
SCREENSHOT_DIR="${3:-ci-screenshots}"
DEVICE_STATE_DIR="${4:-ci-device-state}"
CONTACT_SHEET_DIR="${5:-ci-contact-sheets}"

mkdir -p "$SCREENSHOT_DIR" "$DEVICE_STATE_DIR" "$CONTACT_SHEET_DIR"

extract_screenshots() {
  if [[ ! -d "$BUNDLE" ]]; then
    echo "No xcresult bundle found at $BUNDLE, skipping screenshot extraction"
    return 0
  fi

  local export_dir="$SCREENSHOT_DIR/exported"
  rm -rf "$export_dir"
  mkdir -p "$export_dir"

  # Xcode 16+: bulk-export attachments as a directory. The exported filenames
  # preserve enough attachment context for review while avoiding xcresult JSON
  # schema churn across Xcode releases.
  xcrun xcresulttool export \
    --path "$BUNDLE" \
    --output-path "$export_dir" \
    --type directory 2>/dev/null || true

  local count=0
  while IFS= read -r -d '' png; do
    count=$((count + 1))
    local base
    base="$(basename "$png")"
    cp "$png" "$SCREENSHOT_DIR/${DEVICE_FAMILY}-${count}-${base}"
  done < <(find "$export_dir" -name "*.png" -print0 | sort -z)

  rm -rf "$export_dir"
  echo "Extracted $count in-app PNG screenshot(s) from $BUNDLE"
}

capture_device_state() {
  if ! command -v xcrun >/dev/null 2>&1; then
    echo "xcrun is unavailable; skipping device-state screenshot"
    return 0
  fi

  local sim_id="${SIM_DESTINATION#id=}"
  if [[ -z "${sim_id:-}" || "$sim_id" == "$SIM_DESTINATION" ]]; then
    sim_id="$(xcrun simctl list devices booted \
      | grep -E '\\([-A-F0-9]+\\)' | head -1 \
      | sed -E 's/.*\\(([A-F0-9-]+)\\).*/\\1/' || true)"
  fi

  if [[ -z "${sim_id:-}" ]]; then
    echo "No booted simulator found for device-state screenshot"
    return 0
  fi

  # Keep simulator/home-screen state out of the in-app screenshot artifact so
  # review screenshots cannot confuse Mather with the UI test host app.
  xcrun simctl io "$sim_id" screenshot \
    "$DEVICE_STATE_DIR/device-home-state-${DEVICE_FAMILY}.png" 2>/dev/null || true
}

make_contact_sheet() {
  if [[ ! -s "$VIDEO" ]]; then
    echo "No UI review video found at $VIDEO, skipping contact sheet"
    return 0
  fi

  if ! command -v ffmpeg >/dev/null 2>&1; then
    echo "ffmpeg is unavailable; uploading video without contact sheet"
    return 0
  fi

  local sheet="$CONTACT_SHEET_DIR/ui-review-contact-sheet-${DEVICE_FAMILY}.jpg"
  ffmpeg -hide_banner -loglevel error -y \
    -i "$VIDEO" \
    -vf "fps=1/4,scale=360:-1,tile=3x4" \
    -frames:v 1 \
    "$sheet" || {
      echo "Unable to generate contact sheet from $VIDEO"
      rm -f "$sheet"
      return 0
    }

  echo "Generated contact sheet: $sheet"
}

write_manifest() {
  local manifest="$SCREENSHOT_DIR/manifest-${DEVICE_FAMILY}.txt"
  {
    echo "Mather UI review artifact manifest"
    echo "device_family=$DEVICE_FAMILY"
    echo "result_bundle=$BUNDLE"
    echo "video=$VIDEO"
    echo
    echo "in_app_screenshots:"
    find "$SCREENSHOT_DIR" -maxdepth 1 -name "*.png" -print | sort
    echo
    echo "device_state_screenshots:"
    find "$DEVICE_STATE_DIR" -maxdepth 1 -name "*.png" -print | sort
    echo
    echo "contact_sheets:"
    find "$CONTACT_SHEET_DIR" -maxdepth 1 \( -name "*.jpg" -o -name "*.png" \) -print | sort
  } > "$manifest"
}

extract_screenshots
capture_device_state
make_contact_sheet
write_manifest
