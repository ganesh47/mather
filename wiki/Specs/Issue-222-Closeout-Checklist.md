# Issue #222 Closeout Checklist

**Issue:** [#222](https://github.com/ganesh47/mather/issues/222)  
**Audit date:** 2026-04-19  
**Scope:** current worktree only (`chore/issue-222-closeout-evidence`)  
**Purpose:** map reopened recovery slices `RX1` through `RX6` and closeout validation criteria to concrete repo evidence, separating implemented repo truth from still-missing closeout evidence.

## Audit basis
- Repo code, tests, and wiki content were audited in this worktree.
- The `RX1`...`RX6` labels come from the reopened issue recovery comment:
  - `RX1` surface and configuration truth
  - `RX2` route truth
  - `RX3` Gravity Split truth
  - `RX4` embedded Sum Sprint truth
  - `RX5` embedded Bond Blast truth
  - `RX6` release-truth validation and honest re-close
- No fresh local `xcodebuild` run was possible in this environment because `xcodebuild` is not installed here. Closeout status below therefore relies on source, tests already in repo, and prior GitHub issue/CI notes rather than a new simulator or device pass from this worktree.

## RX Status

| Slice | Status | Done in repo | Still missing for closeout |
|---|---|---|---|
| `RX1` surface and configuration truth | Partial | `SliceConfig` now clamps targets to `1...20` in `Domain/SliceModels.swift`. Problem generation spans `1...20` and avoids immediate repeats in `Domain/ProblemGenerator.swift`. Child and parent surfaces say `Make & Break 1–20` in `Features/VerticalSlice1/HomeView.swift`, `Features/ParentSummary/SettingsView.swift`, and `App/MatherApp.swift`. Tests cover `1...20` range and non-anchored starts in `Tests/MatherTests/ProblemGeneratorTests.swift`. | Legacy specs still present old milestone framing and naming in `wiki/Specs/VS1-Make-and-Break-to-10.md`, `wiki/Specs/VS1-Acceptance-Evidence-Matrix.md`, and `wiki/Specs/VS1-Closeout-Validation-Note.md`. No fresh release-surface proof from this worktree. |
| `RX2` route truth | Done in repo | `makeBreakLoopV2Enabled` explicitly gates the reopened route in `Shared/FeatureFlags.swift`. The recovery route is encoded as `concrete -> gravitySplit -> sumSprint -> bondMatch -> done` in `Domain/SliceStateMachine.swift`, selected by `routeMode` in `Domain/VerticalSliceEngine.swift`, and exercised by `loopV2RoutesConcreteToGravitySplitToSumSprintToBondBlast` in `Tests/MatherTests/VerticalSliceEngineTests.swift` plus route-order assertions in `Tests/MatherTests/SliceStateMachineTests.swift`. | No new end-to-end simulator trace artifact or real-device artifact is checked into the repo for closeout. |
| `RX3` Gravity Split truth | Done in repo | Gravity Split is reset from a zero state via `GravitySplitState(problem:)` on stage entry in `Domain/VerticalSliceEngine.swift`. Tests verify zero start, unsolved entry, no tilt auto-solve, and tap-built completion in `Tests/MatherTests/VerticalSliceEngineTests.swift`. Settings and smoke-check copy call out the stage in `Features/ParentSummary/SettingsView.swift`. | No manual multi-launch or multi-target validation note is present in repo. |
| `RX4` embedded Sum Sprint truth | Done in repo | Loop V2 advances `gravitySplit -> sumSprint` in `Domain/SliceStateMachine.swift`. The engine creates a per-problem micro-burst in `Domain/VerticalSliceEngine.swift`, backed by `SumSprintBurstState.make(for:)` in `Domain/SliceModels.swift`. Tests assert that each embedded burst stays within `1...3` cards in `Tests/MatherTests/VerticalSliceEngineTests.swift`. | No explicit pacing note or measured timing evidence across multiple loops is present in repo. |
| `RX5` embedded Bond Blast truth | Done in repo | Loop V2 advances `sumSprint -> bondMatch` in `Domain/SliceStateMachine.swift`. The engine initializes a per-problem `BondMatchState` in `Domain/VerticalSliceEngine.swift`. `Tests/MatherTests/VerticalSliceEngineTests.swift` verifies transition into Bond Blast and advancement to the next problem after all pairs are matched. Compact-layout UI coverage keeps Bond Blast actions reachable in `Tests/MatherUITests/CompactLayoutTests.swift`. | No checked-in pacing artifact from a longer run demonstrates Bond Blast staying loop-sized in actual session play. |
| `RX6` release-truth validation and honest re-close | Missing | The repo contains smoke-test guidance and export verification steps in `Features/ParentSummary/SettingsView.swift`. Issue comments record that draft PR `#247` was green in GitHub CI and that CI instability was no longer the blocker. | This worktree does not contain the recovery-board docs referenced in issue comments (`wiki/Specs/Issue-222-Execution-Board.md`, `wiki/Specs/Issue-222-Validation-Lane.md`, `wiki/Specs/Issue-222-Recovery-Execution-Lane.md`). No fresh green local simulator run, no real-device E2E note, no pacing signoff, no rollout recommendation, and no concise closeout note are present in repo. |

## Validation Criteria

| Validation criterion | Status | Evidence | Gap |
|---|---|---|---|
| Targets span `1...20` | Done in repo | `Domain/SliceModels.swift`, `Domain/ProblemGenerator.swift`, `Tests/MatherTests/ProblemGeneratorTests.swift` | No fresh runtime validation note from this worktree |
| Session no longer always starts at `6` | Done in repo | randomized-start test in `Tests/MatherTests/ProblemGeneratorTests.swift` | Deterministic test mode still intentionally starts with `6`; closeout should distinguish test fixture behavior from shipped runtime behavior |
| Exact 4-stage loop per target | Done in repo | `Domain/SliceStateMachine.swift`, `Domain/VerticalSliceEngine.swift`, `Tests/MatherTests/VerticalSliceEngineTests.swift`, `Tests/MatherTests/SliceStateMachineTests.swift` | No checked-in simulator trace or screen recording proving the loop outside unit tests |
| Gravity Split starts at zero and is child-built | Done in repo | `Domain/VerticalSliceEngine.swift`, `Tests/MatherTests/VerticalSliceEngineTests.swift` | No manual validation note across multiple targets |
| Sum Sprint appears in every loop in short form | Done in repo | `Domain/VerticalSliceEngine.swift`, `Domain/SliceModels.swift`, `Tests/MatherTests/VerticalSliceEngineTests.swift` | No pacing evidence across at least 5 loops |
| Bond Blast appears in every loop as short capstone | Done in repo | `Domain/SliceStateMachine.swift`, `Domain/VerticalSliceEngine.swift`, `Tests/MatherTests/VerticalSliceEngineTests.swift` | No pacing evidence from a longer session run |
| Session pacing still feels good | Missing closeout evidence | existing smoke-test checklist in `Features/ParentSummary/SettingsView.swift` | No measured session-duration or pilot note in repo |
| Rollout remains gated until QA signoff | Done in repo | `makeBreakLoopV2Enabled` defaults to off in `Shared/FeatureFlags.swift`; settings expose the gate in `Features/ParentSummary/SettingsView.swift` | No explicit rollout recommendation note yet |
| Honest re-close backed by release-truth evidence | Missing | none beyond source/test audit and prior issue comments | Need a concise validation note with CI result, simulator/device evidence, pacing signoff, and close recommendation |

## Missing Artifacts Blocking Honest Close

- A short release-truth validation note for issue `#222` that records:
  - latest CI status
  - one simulator end-to-end result
  - one real-device end-to-end result
  - pacing/signoff result
  - rollout recommendation for `makeBreakLoopV2Enabled`
- Recovery-board docs referenced in the issue comments are absent from this worktree:
  - `wiki/Specs/Issue-222-Execution-Board.md`
  - `wiki/Specs/Issue-222-Validation-Lane.md`
  - `wiki/Specs/Issue-222-Recovery-Execution-Lane.md`
- Legacy VS1 spec docs still describe the old `"Make & Break to 10"` framing and should not be treated as issue `#222` closeout evidence without an explicit update or supersession note.

## Close Recommendation

Do **not** close issue `#222` from this worktree alone.

The reopened loop is substantially implemented in repo code and tests (`RX2` through `RX5`, with most of `RX1`), but `RX6` remains open because the repo still lacks a concise release-truth evidence package. The next honest closeout step is to add a short validation note after a fresh simulator pass, a real-device pass, pacing confirmation, and a rollout recommendation for the recovery flag.
