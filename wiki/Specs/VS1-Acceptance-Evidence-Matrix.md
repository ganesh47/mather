# VS1 Acceptance Evidence Matrix

**Scope:** Vertical Slice 1 — Make & Break to 10  
**Purpose:** map spec acceptance criteria to current implementation evidence without closing the milestone yet

## Functional

| Acceptance criterion | Current status | Evidence |
|---|---|---|
| Child starts a session from Home in ≤1 tap with no mandatory reading | Implemented | `Features/VerticalSlice1/HomeView.swift` (`Play` CTA routes directly to session setup), `Tests/MatherUITests/ScreenshotTests.swift` (`testScreenshot_SessionConfig`) |
| Session follows CPA sequence in one coherent task: Concrete → Pictorial → Abstract | Implemented | `Domain/SliceStateMachine.swift`, `Domain/VerticalSliceEngine.swift`, child stage views in `Features/VerticalSlice1/` |
| At least one problem in each session includes an abstract-to-concrete transfer step | Implemented | `Domain/VerticalSliceEngine.swift` transfer stage routing, `Features/VerticalSlice1/TransferCheckView.swift`, tests in `Tests/MatherTests/TransferExactRebuildTests.swift` and `TransferIntentTests.swift` |
| Child can build target number in ten-frame using touch/drag only | Implemented | `Features/VerticalSlice1/ConcreteBuildView.swift`, `Features/VerticalSlice1/CounterView.swift`, UI tests in `Tests/MatherUITests/ScreenshotTests.swift` |
| Child can split built number into two groups and map to an equation | Implemented | `Features/VerticalSlice1/SplitView.swift`, `Features/VerticalSlice1/EquationResolveView.swift`, engine state in `Domain/VerticalSliceEngine.swift` |
| Final abstract answer accepts numeric input and validates correctness | Implemented | `Features/VerticalSlice1/EquationResolveView.swift`, validation in `Domain/VerticalSliceEngine.swift` |
| Session ends naturally after configured problem set (max 6–8 items) with no hard stop timer | Implemented | `Features/VerticalSlice1/SessionConfigView.swift` (4...8 stepper), `Domain/VerticalSliceEngine.swift` session advancement and finish flow |
| Parent summary shows objective, completion count, first-attempt accuracy, and next-step recommendation | Implemented | `Features/ParentSummary/ParentSummaryView.swift`, `Persistence/TelemetryWriter.swift` digest generation, `Domain/SliceModels.swift` (`ParentDigest`) |

## UX / Experience

| Acceptance criterion | Current status | Evidence |
|---|---|---|
| All interaction controls in child flow are touch targets at least 80x80 pt | Implemented with test-backed hardening | Large action styles in `Features/VerticalSlice1/VS1SharedUI.swift`, direct interaction controls in child views, related fixes in closed milestone issues #31, #63 |
| Child flow has no mandatory reading, all first-time instructions are spoken | Implemented | `Services/SpeechService.swift`, prompt routing in `Domain/VerticalSliceEngine.swift`, replay action in `Features/VerticalSlice1/SliceSessionView.swift` |
| Wrong answer state never uses punitive language, feedback is gentle and actionable | Implemented | failure-message generation in `Domain/VerticalSliceEngine.swift`, `Features/VerticalSlice1/FeedbackBannerView.swift` |
| Audio feedback exists for major transitions (start, correct, retry, done) | Implemented | `Services/SpeechService.swift`, transition prompts in `Domain/VerticalSliceEngine.swift` |
| Session median duration (pilot target) is under 6 minutes | Not yet validated | requires pilot session evidence, not just code |

## Engineering

| Acceptance criterion | Current status | Evidence |
|---|---|---|
| App runs on iPad target and iPhone simulator (for CI) without feature-privileged crash paths | Implemented and CI-covered | current GitHub Actions CI, `Tests/MatherUITests/CompactLayoutTests.swift`, `Tests/MatherUITests/ScreenshotTests.swift` |
| Feature flag guard wraps incomplete capabilities | Implemented | `Shared/FeatureFlags.swift`, `Features/VerticalSlice1/HomeView.swift`, `App/AppModel.swift`, `Domain/VerticalSliceEngine.swift` |
| All session events are recorded locally and are exportable | Implemented | `Persistence/TelemetryWriter.swift`, local JSONL export via `Features/ParentSummary/SettingsView.swift` |
| No network calls in this alpha vertical slice, local session identifiers and local-only metadata are acceptable | Implemented by architecture | local-only telemetry in `Persistence/TelemetryWriter.swift`; no network stack in child/session implementation path |
| Build compiles with scheme `Mather` and no placeholder compile-time blockers | Implemented | GitHub Actions CI on `Mather` scheme, latest repaired main/PR CI status |

## Remaining closeout-only gaps
- Pilot evidence for session median duration under 6 minutes
- Short written pilot findings note
- Explicit milestone close decision
