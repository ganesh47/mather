# Mather clawpatch setup

This directory keeps the repo-specific clawpatch configuration durable.

Mather uses `project.yml` as the source of truth for the Xcode project. Do not hand-edit `Mather.xcodeproj`; regenerate it with `xcodegen generate` and verify the generated project is committed with `git diff --exit-code Mather.xcodeproj`.

The configured validation commands mirror the GitHub Actions unit-test lane:

- run `xcodegen generate`
- verify the generated Xcode project is clean
- resolve package dependencies
- build for testing on an iOS simulator
- run `MatherTests`

If clawpatch reports Apple mapper issues such as malformed test-suite labels or weak source-to-test adjacency, treat those as mapper/upstream limitations unless a repo-local override is added intentionally. Repo changes should still follow the normal Mather branch, PR, CI, and release path.
