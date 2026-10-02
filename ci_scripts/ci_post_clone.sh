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

# Even when Apple indexes only main, stamp a release version only when an
# unambiguous remote version tag points at this exact checkout. Ordinary branch
# builds without a matching release tag retain the development placeholder.
cd "$CI_PRIMARY_REPOSITORY_PATH"
VERSION=$(python3 ci_scripts/resolve_cloud_release_tag.py)
if [ -n "$VERSION" ]; then
  echo "--- ci_post_clone: stamping MARKETING_VERSION=${VERSION} from verified release commit ---"
  sed -i '' "s/MARKETING_VERSION: .*/MARKETING_VERSION: ${VERSION}/" project.yml
else
  echo "--- ci_post_clone: no matching release tag — keeping development version ---"
fi

if [ -n "${CI_BUILD_NUMBER:-}" ]; then
  echo "--- ci_post_clone: stamping CURRENT_PROJECT_VERSION=${CI_BUILD_NUMBER} ---"
  sed -i '' "s/CURRENT_PROJECT_VERSION: .*/CURRENT_PROJECT_VERSION: ${CI_BUILD_NUMBER}/" \
    "$CI_PRIMARY_REPOSITORY_PATH/project.yml"
else
  echo "--- ci_post_clone: no CI_BUILD_NUMBER — keeping CURRENT_PROJECT_VERSION as-is ---"
fi

echo "--- ci_post_clone: regenerating Mather.xcodeproj ---"
cd "$CI_PRIMARY_REPOSITORY_PATH"
xcodegen generate

echo "--- ci_post_clone: done ---"
