# Issue #349 validation note — Make & Break de-gating

Environment: Linux 6.8.0-110-generic. Xcode/iOS Simulator are not available in this worker, so native Swift/Xcode test execution was not possible here.

Commands run:

```text
xcodebuild -version
# /bin/bash: xcodebuild: command not found

swift --version
# /bin/bash: swift: command not found

grep -RIn --exclude-dir=.git "settings-loop-v2-toggle" Features Shared Domain Tests wiki docs
# Tests/MatherUITests/ScreenshotTests.swift:58: asserts the toggle is absent
# Tests/MatherUITests/ScreenshotTests.swift:208: asserts the toggle is absent

grep -RIn --exclude-dir=.git "Keys.makeBreakLoopV2Enabled: true" Shared/FeatureFlags.swift
# Shared/FeatureFlags.swift:163: default is registered true

grep -RIn --exclude-dir=.git "feature.makeBreakLoopV2Enabled\", \"NO" Tests/MatherUITests Tests/MatherTests
# Tests/MatherUITests/ScreenshotTests.swift:368 and :383 keep explicit legacy launch coverage

git diff --check
# passed with no whitespace errors
```
