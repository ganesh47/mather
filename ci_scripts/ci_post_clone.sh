#!/bin/sh
# Xcode Cloud post-clone hook — regenerates the Xcode project from project.yml
# and stamps MARKETING_VERSION from the git tag when triggered by a tag push.
#
# Environment variables provided by Xcode Cloud:
#   CI_TAG          — set when triggered by a tag (e.g. "v0.1.2"), empty otherwise
#   CI_BUILD_NUMBER — monotonically increasing build number (used for CFBundleVersion)
#
# See: https://developer.apple.com/documentation/xcode/writing-custom-build-scripts

set -e

echo "--- ci_post_clone: installing XcodeGen ---"
brew install xcodegen

# Stamp MARKETING_VERSION from the git tag so Apple accepts the archive.
# project.yml ships with "0.1.0-dev" as a dev placeholder; release builds
# must use a clean semver string like "0.1.2" (no -dev suffix).
if [ -n "${CI_TAG:-}" ]; then
  VERSION="${CI_TAG#v}"   # strip leading "v": v0.1.2 → 0.1.2
  echo "--- ci_post_clone: stamping MARKETING_VERSION=${VERSION} from tag ${CI_TAG} ---"
  sed -i '' "s/MARKETING_VERSION: .*/MARKETING_VERSION: ${VERSION}/" \
    "$CI_PRIMARY_REPOSITORY_PATH/project.yml"
else
  echo "--- ci_post_clone: no tag — keeping MARKETING_VERSION as-is (dev build) ---"
fi

echo "--- ci_post_clone: regenerating Mather.xcodeproj ---"
cd "$CI_PRIMARY_REPOSITORY_PATH"
xcodegen generate

echo "--- ci_post_clone: done ---"
