# Spec: Vertical Slice 1 — Make & Break to 10

**Issue**: #TBD (to be linked to a Feature Spec issue)
**Status**: draft
**Author**: @ganesh47
**Date**: 2026-03-31

## Overview
Build and validate the first complete “testable vertical slice” proving Mather’s core hypothesis: for ages 5–7, a CPA-first, concrete-to-abstract math interaction increases engagement and learning retention better than text-heavy worksheet style.

The slice is intentionally narrow: one high-leverage objective, one repeated session loop, and one parent-facing summary.

Core experience: **Make & Break to 10**.

- Child makes a target number with concrete counters.
- Splits the same number into two addends (number-bond style).
- Confirms equivalent abstract equation.
- Includes one reverse-direction transfer item per session (abstract -> concrete).

## User Stories
- As a child (age 5–7), I want to manipulate objects to make numbers and split them so I can understand addition as joining and part-part-whole.
- As a child, I want immediate visual/audio feedback and clear, gentle hints so I can continue without frustration.
- As a parent, I want a short summary of what math objective my child practiced and what to do next.
- As a product owner, I want exportable, non-PII local session telemetry to evaluate whether this slice should be expanded.

## Acceptance Criteria
### Functional
- [ ] Child starts a session from Home in ≤1 tap with no mandatory reading.
- [ ] Session follows CPA sequence in one coherent task: Concrete → Pictorial → Abstract.
- [ ] At least one problem in each session includes an abstract-to-concrete transfer step.
- [ ] Child can build target number in ten-frame using touch/drag only.
- [ ] Child can split built number into two groups and map to an equation.
- [ ] Final abstract answer accepts numeric input and validates correctness.
- [ ] Session ends naturally after configured problem set (max 6–8 items) with no hard stop timer.
- [ ] Parent summary shows objective, completion count, first-attempt accuracy, and next-step recommendation.

### UX/Experience
- [ ] All interaction controls in child flow are touch targets at least 80x80 pt.
- [ ] Child flow has no mandatory reading; all first-time instructions are spoken.
- [ ] Wrong answer state never uses punitive language; feedback is gentle and actionable.
- [ ] Audio feedback exists for major transitions (start, correct, retry, done).
- [ ] Session median duration (pilot target) is under 6 minutes.

### Engineering
- [ ] App runs on iPad target and iPhone simulator (for CI) without feature-privileged crash paths.
- [ ] Feature flag guard wraps incomplete capabilities.
- [ ] All session events are recorded locally and are exportable.
- [ ] No network calls in this alpha vertical slice; local session identifiers and local-only metadata are acceptable.
- [ ] Build compiles with scheme `Mather` and no placeholder compile-time blockers.

## Design

### SwiftUI Views
- `HomeView`
  - Large “Play” CTA, visual character prompt, optional tiny settings access.
- `SessionConfigView`
  - Sets difficulty band (6–10 in phase 1), fixed problem count, and starts slice.
- `SliceSessionView`
  - Hosts stage state machine for one problem.
- `ConcreteBuildView`
  - Ten-frame and draggable counters (or tap-to-add controls on smaller screens if needed).
- `SplitView`
  - Child drags counter groups into two buckets and sees color-based decomposition.
- `EquationResolveView`
  - Minimal keypad + equation text slot(s), accepts 0–10 numeric input.
- `TransferCheckView`
  - Abstract prompt first, then concrete reconstruction.
- `FeedbackBannerView`
  - Neutral redirect / success cues.
- `SessionSummaryView` (child)
  - “Play again” and “Done” choices.
- `ParentSummaryView`
  - Skill practiced, mastery estimate, completion rate, next step.
- `SettingsView`
  - Debug mode, reset logs, export session data, test mode toggles.

### Data Model
- `SliceConfig`
  - `maxProblems: Int`, `targetRange: ClosedRange<Int>`, `showTransfer: Bool`, `audioEnabled: Bool`.
- `SliceProblem`
  - `id`, `target: Int`, `decompositionA: Int`, `decompositionB: Int`, `skillTag`, `difficultyTier`.
- `ProblemState`
  - `stage: .concrete/.pictorial/.abstract/.transfer/.done`, `attempts`, `isCorrect`, `timeSpentMs`.
- `SliceSession`
  - `sessionId`, `startedAt`, `endedAt`, `problems: [ProblemSession]`, `schemaVersion`.
- `ProblemSession`
  - `problemId`, `givenAt`, `events: [SliceEvent]`, `firstTryCorrect`, `attemptCount`, `retryCount`.
- `SliceEvent`
  - `type`, `timestamp`, `payload`.
- `ParentDigest`
  - `firstAttemptAccuracy`, `medianLatencyMs`, `problemsCompleted`, `transferCorrect`, `nextTargetHint`.

### Navigation
- Start at `HomeView`.
- Child path: `HomeView` → `SessionConfigView` → `SliceSessionView` → optional `SessionSummaryView`.
- Parent path: `HomeView` (small admin affordance or gesture) → `SettingsView`/`ParentSummaryView`.
- Session and settings should not require separate login/account.

### State Management
- Use Swift’s `@Observable` for in-memory state:
  - `VerticalSliceEngine` (session orchestration)
  - `TelemetryWriter` (event buffer + flush)
  - `FeatureFlagService`
- Persist session summaries with SwiftData.
- Keep render state unidirectional from model → view.

## Feature Flag
`FeatureFlags.verticalSlice1Enabled` (default: `false` in release; can be toggled from settings for controlled testing).

## Platform & Sensor Plan for VS1
### In-scope now
- `SwiftUI` + gestures as primary interaction backbone.
- `AVFoundation` (`AVSpeechSynthesizer`) for spoken child instructions/feedback.
- `SwiftData` for local session persistence.
- `OSLog` + JSONL exporter from local documents directory.

### Out-of-scope (intentionally deferred)
- Live camera capture and `Vision` workflows.
- Speech-to-text command inputs via `Speech`.
- Full Siri/App Intents surface area.
- `CoreMotion`-driven controls.
- PencilKit-freeform annotation as primary input.

### Why this plan is sensor-safe
- We can later layer camera, speech, pencil, and motion into the same architecture via separate interaction adapters without rewriting core CPA logic.
- Deferring heavy-sensor dependency keeps first build reliable and suitable for a family-pilot on a known iOS/iPadOS stack.

## Telemetry (local only, alpha data policy)
Write one JSONL file per session with schema version.

For this alpha phase (personal/local testing only), local identifiers or PII labels are acceptable and stay on-device unless explicitly exported for your own analysis. No remote upload pipeline is used.

### Events
- `session_start`
  - `timestamp`, `appVersion`, `deviceClass`, `featureFlags`, `schemaVersion`
- `problem_presented`
  - `problemId`, `target`, `stage`, `difficultyTag`
- `interaction`
  - `problemId`, `action` (`drag`, `place`, `select`, `submit`), `value`, `durationMs`
- `hint_used`
  - `problemId`, `hintType`, `atAttempt`
- `problem_completed`
  - `problemId`, `attempts`, `timeMs`, `transferDirection` (`concrete_to_abstract`/`abstract_to_concrete`)
- `session_end`
  - `problemsPresented`, `problemsCompleted`, `medianResponseMs`, `firstAttemptAccuracy`, `selfReportedFun`

### Export
- Share-sheet export of JSONL file(s) from Settings.

## Out of Scope
- Full curriculum graph / adaptive scheduler.
- Cross-child profiles, school/teacher mode, multi-day spaced repetition engine.
- Multiplayer, leaderboard, social features.
- Monetization, IAP, parental gate flows tied to App Store compliance.

## Open Questions
- [ ] Exact session length target for this slice: 4–6 minutes vs fixed 6 problems.
- [ ] Initial problem generator seed set: fixed list vs random permutation.
- [ ] Should transfer question be `3 + 5`, `4 + 6`, or child-picked target for phase-1 validity?
- [ ] How strict should audio pacing be on first launch: auto-play once + tap-to-replay vs always manual?

## References
- Related research: [[Research/Math-App-Vision]]
- Related ADRs: [[ADRs/ADR-0001-record-architecture-decisions]], [[ADRs/ADR-0002-personal-distribution-not-app-store]]
- Relevant issue: #1 (Research) completed, with this spec intended as next implementation artifact.
