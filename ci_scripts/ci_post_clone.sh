#!/bin/sh
# Xcode Cloud post-clone hook — regenerates the Xcode project from project.yml.
# Xcode Cloud reads the committed .xcodeproj at workflow-setup time but runs this
# script after cloning before building, so the generated project is always current.
#
# See: https://developer.apple.com/documentation/xcode/writing-custom-build-scripts

set -e

echo "--- ci_post_clone: installing XcodeGen ---"
brew install xcodegen

echo "--- ci_post_clone: regenerating Mather.xcodeproj ---"
cd "$CI_PRIMARY_REPOSITORY_PATH"
xcodegen generate

echo "--- ci_post_clone: done ---"
