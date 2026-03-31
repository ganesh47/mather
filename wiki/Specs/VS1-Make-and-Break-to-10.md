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

## Alpha Data Policy (Personal Test Scope)
- Scope: This slice is for local alpha testing only, personal-family devices, no App Store distribution.
- Data location: all logs and exports are written to the app container (`Library/Application Support/` or `Documents/`) and remain device-local by default.
- Allowed local fields:
  - session id
  - start/end timestamps
  - problem id and target values
  - touch interaction summaries (attempt count, action type, timings)
  - optional local child labels for internal use (e.g., `childAlias`, age band) if you choose to add them later in this alpha
- Data sharing: export is manual only (share sheet); no background sync or API submission.
- Review hygiene: if you later move beyond alpha/private testing, remove/obfuscate local labels and add a privacy review before any external transfer.

## Implementation Plan (Build Slice)

### 1) Project structure for alpha implementation
- App module: `Mather` (single target first).
- Suggested folders:
  - `App/` (App entry, scene, root navigation)
  - `Features/VerticalSlice1/` (views, state, domain models)
  - `Shared/` (design tokens, utilities)
  - `Domain/` (problem generation + session rules)
  - `Persistence/` (SwiftData models/repo + JSONL exporter)
  - `Assets/` (optional images/audio if included)
- Keep code in one branch per milestone and behind one feature flag.

### 2) Minimal implementation milestones
- **M1 App shell**
  - Root app scaffold, routing, one feature flag, simple settings entry.
- **M2 CPA engine**
  - Problem generator (`target` and decomposition rule set).
  - Stage state machine: Concrete -> Pictorial -> Abstract -> Transfer -> Done.
- **M3 Interaction views**
  - Ten-frame + counters (drag or tap-add path).
  - Split buckets for number bonds.
  - Equation keypad input and validation view.
- **M4 Audio + feedback**
  - `AVSpeechSynthesizer` prompts and transitions.
  - Non-punitive UI states + small celebratory feedback at milestones.
- **M5 Data/observability**
  - JSONL writer + parent summary calculation.
  - Share export from Settings.

### 3) Asset strategy for VS1 (fast, low-risk)
- **Prefer generated UI primitives first**
  - Counters, ten-frame, buckets, cards, separators built in SwiftUI shapes.
  - Large buttons and chips use SF Symbols + custom palette variables.
- **Optional character asset**
  - One friendly guide character with 3 states (neutral, celebrate, gentle retry).
  - Single PNG/SVG is sufficient for alpha.
- **Audio**
  - 4–6 short in-house/royalty-free cues (tap, place, retry, success).
  - Text-to-speech used for all first-run instructions.
- **Where to source**
  - Alpha: internal placeholders + local generated assets to avoid licensing friction.
  - After first pilot: either AI-generated custom assets (if you want unique look) or licensed set from a known package.

### 4) Asset licensing + generation policy
- For this alpha: avoid web-copied random images unless explicitly checked for reuse rights.
- If AI-generated, keep a simple provenance note in the wiki (prompt + tool + date) for traceability.
- Keep one consistent color/shape system from day 1 to avoid churn.

### 5) Testing and iteration protocol
- Pre-pilot checklist:
  - Runs on iPad and iPhone simulator with `verticalSlice1Enabled = true`.
  - No hard crash in quick drag/place sequence.
  - Parent export creates a readable JSONL file.
- Pilot gates:
  - 1–3 kids for 10–15 minutes total.
  - Compare completion rate, frustration points, and transfer-item pass.
- Post-pilot decision:
  - keep same content and tune thresholds **or**
  - switch input mode (tap-first or 3-option choice) and retest quickly.

### 6) Local implementation assumptions (important)
- No auth/login, no network, no cloud sync in VS1.
- Data stored under local app sandbox only.
- Any future external use (analytics upload/icloud/parent accounts) requires a separate ADR and feature expansion plan.

## Suggested local dependency set
- SwiftData (local persistence and summaries)
- AVFoundation (`AVSpeechSynthesizer`)
- SwiftUI + Observation (`@Observable`) for state
- OSLog for development diagnostics (non-authoritative)
- Foundation `Codable` for JSONL event logging
- Optional later: PencilKit, Vision, Speech, App Intents

## Interaction and control choices (for this slice)
- Input baseline: drag + tap with big targets; avoid small precision drag for 5-year-olds.
- Pencil optional in M1 for this slice; keep fallback controls for non-Apple-Pencil sessions.
- No live camera capture/voice-to-text in first slice.
- Keep all math values within 0–10 initially to reduce cognitive load and reduce failure noise.

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

## Open Questions (resolved with alpha defaults + maturity gates)

### Q1) Exact session length target (4–6 minutes vs fixed 6 problems)
- **Decision**: Use **hybrid cap**: `6 problems` OR `7-minute max`, whichever comes first.
- **Research rationale**: Slice-level attention target from current research is 10–12 minutes for ages 5–7 with a preferred shorter flow for this age; the 10-minute global guidance supports a 6-problem loop while retaining a hard timeout guard for variance.
- **Maturity**: **M0 (implemented default)**
- **Pilot adjustment trigger**: If median completion is consistently <3:30 and confusion is low, increase to 7–8 problems. If median completion >7:00 or visible fatigue appears, reduce to 5 problems and keep hard timeout.

### Q2) Problem list strategy (fixed set vs random permutation)
- **Decision**: Use a **two-mode generator**:
  - **Test mode**: fixed ordered seed list for reproducibility.
  - **Family mode**: random permutation with a per-device seed.
- **Research rationale**: For first measurement loops, fixed sequencing reduces confounds and supports comparable telemetry; later random order supports engagement and anti-learning effects.
- **Maturity**: **M1 (test mode first, family mode behind flag next sprint)**.

### Q3) Transfer question pattern (specific fixed example vs adaptive)
- **Decision**: Use **adaptive abstract→concrete transfer**:
  - Build from current target range, preferably values 3–9.
  - Keep one transfer per session using a single equation where both addends are 1–9 and sum ≤10.
  - Prefer addends with non-round structure first (`3 + 5`, `2 + 6`, `4 + 3`) to make decomposition visible.
- **Research rationale**: Transfer should test concept portability across representational mode, not memorization of one fixed pair.
- **Maturity**: **M0 (algorithmic rule with fixed cap; addend set configurable by session seed)**.

### Q4) Audio pacing strictness at launch
- **Decision**: On first launch, play `intro + first stage prompt` once automatically, then switch to **tap-to-repeat + contextual spoken hints** for all later steps.
- **Research rationale**: Children 5–7 need low-friction flow; first-run auto voice supports accessibility, while manual replay prevents cognitive overload from repetitive narration.
- **Maturity**: **M0 (default behavior)**.

## Maturity Ladder for VS1 Decisions
- **M0 (hard defaults)**: can be implemented immediately without ambiguity.
  - 6-problem/7-minute hybrid cap.
  - Test mode fixed ordering.
  - Adaptive transfer question generation with bounded operands.
  - Auto-intro then manual replay.
- **M1 (observability-driven evolution)**: changes only after pilot outcome review.
  - Move to random ordering by default.
  - Tune session cap for fatigue curves.
  - Tighten/reduce/expand transfer complexity.
- **M2 (post-pilot expansion)**: introduce new modes and broader pedagogy.
  - Child-chosen targets.
  - Voice command shortcuts.
  - Gesture/pencil-first variants.

## References
- Related research: [[Research/Math-App-Vision]]
- Related ADRs: [[ADRs/ADR-0001-record-architecture-decisions]], [[ADRs/ADR-0002-personal-distribution-not-app-store]]
- Relevant issue: #1 (Research) completed, with this spec intended as next implementation artifact.
