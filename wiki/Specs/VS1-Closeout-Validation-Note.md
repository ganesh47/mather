# VS1 Closeout Validation Note

**Status:** in progress  
**Scope:** documentation and validation only, not milestone closure

## Purpose
Capture the current validation state of VS1 "Make & Break to 10" without closing the milestone yet.

## Current position
VS1 is implemented and represented in code, tests, and CI, but final milestone closeout remains intentionally deferred.

## What is validated
- Core child flow exists and is testable end-to-end:
  - Home -> Session setup -> Concrete -> Pictorial -> Abstract -> Transfer -> Session complete
- Reopened issue #222 loop now has a deterministic simulator evidence lane:
  - `Tests/MatherUITests/ScreenshotTests.swift` includes `testScreenshot_Issue222LoopV2_AcrossTwoTargets`
  - It clears `Make it -> Gravity Split -> Sum Sprint -> Bond Blast` twice in one session for deterministic targets 6 and 9
  - Each pass attaches screenshots to the `.xcresult`, so the route is inspectable without reconstructing the session manually
- Parent-facing flows exist:
  - Parent Summary
  - Settings
  - local JSONL export via share sheet
- CI currently covers:
  - unit tests for engine/generator/history/theme behavior
  - UI tests for compact layout and screenshot flows
- iPhone compact-layout smoke coverage exists in `Tests/MatherUITests/ScreenshotTests.swift` and `Tests/MatherUITests/CompactLayoutTests.swift`.

## What is not yet fully closed out
- Real pilot evidence for the target median session duration under 6 minutes.
- A concise written summary of pilot observations:
  - completion rate
  - transfer success rate
  - frustration points
  - whether the current pacing is appropriate
- Formal milestone close decision.

## Recommended next closeout inputs
1. Run or summarize real pilot sessions.
2. Record median duration and major observations.
3. Run `scripts/run_issue222_closeout_validation.sh` and confirm the iPhone + iPad result bundles contain the issue #222 loop screenshots.
4. Then decide whether to close the milestone.

## Practical runner
Use the local runner when you need fresh simulator evidence for issue #222:

```bash
scripts/run_issue222_closeout_validation.sh
```

It will:
- regenerate the project with `xcodegen` when available, otherwise reuse the checked-in `Mather.xcodeproj`
- run the deterministic issue #222 screenshot test on `iPhone 16` and `iPad Pro 13-inch (M4)` simulators
- write per-device `.xcresult` bundles under `artifacts/issue222-closeout-validation/<timestamp>/`

Open the `.xcresult` bundles in Xcode's report navigator to review the attached screenshots for:
- target 6 concrete, gravity split, sum sprint, and bond blast
- target 9 concrete, gravity split, sum sprint, and bond blast

## Important note
This page is a staging note only. It should support milestone review, not replace it.
