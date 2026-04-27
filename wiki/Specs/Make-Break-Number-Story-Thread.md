# Make & Break Number Story Quest — Implementation Plan

**Status:** Implementation-ready plan for issue #400  
**Issue:** https://github.com/ganesh47/mather/issues/400  
**Lane:** lane-e-story-vocabulary in progress
**Last updated:** 2026-04-27

## Scope lock

Build **Make & Break: Number Story Quest** on the existing Make & Break V2 loop.

In-scope for #400:

1. Parent-facing target cap: **Up to 10** or **Up to 20**.
2. Deterministic curated story prompts bound to each `SliceProblem`.
3. A lightweight **Story Anchor** pre-stage before Make It.
4. Story-aware target recall in embedded Sum Sprint and Bond Blast.
5. Optional Apple Intelligence/FoundationModels story variation that is availability-gated, sanitized, and fallback-first.
6. Room Quest fusion only as a future note.

Out of scope for #400:

- Caps above 20.
- Large-number/grouped hundreds/tens representation.
- Timers or pressure language.
- Letting AI choose or mutate math facts.
- Folding unrelated geometry/compass/protractor labs into Make & Break.

## Current repo truth inspected

- `Domain/SliceModels.swift`
  - `SliceConfig` already carries `minTarget` / `maxTarget` and clamps to `1...20`.
  - `SliceStage` currently starts at `.concrete`; no story stage exists yet.
- `Domain/ProblemGenerator.swift`
  - Deterministic seed spans `1...20`.
  - Generation already filters by `config.targetRange`.
- `Features/VerticalSlice1/SessionConfigView.swift`
  - Exposes theme, problem count, and speech prompts.
  - Does not expose target cap before this issue slice.
- `Domain/SliceStateMachine.swift`
  - Make & Break V2 route is `concrete -> gravitySplit -> sumSprint -> bondMatch -> done`.
- `Domain/VerticalSliceEngine.swift`
  - `updateConfig(minTarget:maxTarget:)` already exists.
  - Embedded Sum Sprint/Bond Blast state is initialized from `currentProblem`.
- `Domain/SliceModels.swift`
  - `SumSprintBurstState.make(for:)` already derives cards from the actual `SliceProblem` target/decomposition.
  - `BondMatchState.makePairs(for:)` already derives complements from the target.
- `Features/VerticalSlice1/SliceSessionView.swift`
  - Renders concrete, Gravity Split, Sum Sprint, Bond Blast.
  - Story badge/anchor can be added here after domain support lands.
- `Services/MemoryCardDescribeService.swift` and related Memory AI files
  - Closest existing AI seam; current live FoundationModels path is fallback/stub-oriented.

## Milestones

### M0 — Parent target cap exposure (safe first slice)

**Goal:** Parent can select `Up to 10` or `Up to 20` before starting a session, and generated problems respect it.

Files:

- `Features/VerticalSlice1/SessionConfigView.swift`
  - Add two cap buttons: `Up to 10`, `Up to 20`.
  - On tap call `engine.updateConfig(minTarget: 1, maxTarget: cap)`.
  - Add accessibility identifiers:
    - `target-cap-up-to-10`
    - `target-cap-up-to-20`
- `Tests/MatherTests/ProblemGeneratorTests.swift`
  - Assert deterministic generation under max 10 filters out targets above 10.
  - Assert random generation under max 10 never emits targets above 10 and decompositions still sum to target.

Acceptance:

- Default remains `1...20`.
- Selecting `Up to 10` changes only `SliceConfig.maxTarget`/range; no route churn.
- Tests prove generator honors the selected cap.

### M1 — Curated story model and generator

**Goal:** Every `SliceProblem` has a deterministic story prompt whose numbers exactly match the problem.

**Implementation status:** Landed in Lane C / `feat/issue-400-c-story-prompts` as deterministic story-domain code only. Story Anchor UI/routing and AI variation remain in later milestones.

Add:

- `Domain/NumberStoryModels.swift`
  - `NumberStoryPrompt`
  - `NumberStoryTemplateID`
- `Domain/NumberStoryGenerator.swift`
  - `static func prompt(for problem: SliceProblem, themeId: String) -> NumberStoryPrompt`
  - Curated packs for Space Cargo, Vehicle Garage, Garden Seed Shop, and Festival Prep.
  - Number-band representation hints for singles, ten-frames, tens/ones, hundreds/tens/ones, and 1000 blocks.

Rules:

- `prompt.target == problem.target`.
- `prompt.leftPart == problem.decompositionA`.
- `prompt.rightPart == problem.decompositionB`.
- Spoken intro is short, concrete, and reading-light.
- No generated text in this milestone.
- Theme selection is deterministic. Vehicle theme maps to Vehicle Garage; classic uses curated non-vehicle packs by target band; explicit pack IDs can request Space, Garden, or Festival.

Tests:

- `Tests/MatherTests/NumberStoryGeneratorTests.swift`
  - Story numbers match `SliceProblem` for representative targets 6, 10, 14, 20, 37, 100, 250, and 1000.
  - Generated story contains the exact target and both parts.
  - Deterministic output is stable for the same problem/theme.
  - Prompt language avoids timer, pressure, shame, danger, punishment, scarcity panic, and rescue-in-danger terms.

Acceptance:

- No story can drift from math truth.
- Story text is available without network/AI/FoundationModels.

### M2 — Story Anchor pre-stage

**Goal:** Add a short encoding stage before Make It.

Files:

- `Domain/SliceModels.swift`
  - Add `SliceStage.storyAnchor` with title `Story`.
  - Consider `SliceEventType.storyAnchorStarted` / `storyAnchorCompleted` if telemetry is needed immediately.
- `Domain/SliceStateMachine.swift`
  - Make & Break V2 route becomes `storyAnchor -> concrete -> gravitySplit -> sumSprint -> bondMatch -> done`.
  - Legacy route can remain unchanged unless product wants Story Anchor everywhere.
- `Domain/VerticalSliceEngine.swift`
  - Initialize first problem at `.storyAnchor` for Make & Break V2.
  - Expose `currentStoryPrompt` derived from `currentProblem` and selected theme.
  - Speak `storyPrompt.spokenIntro` when entering anchor.
- `Features/VerticalSlice1/SliceSessionView.swift`
  - Add `StoryAnchorView` with title, one-line story, target badge, and primary action `Make it`.

Tests:

- `Tests/MatherTests/SliceStateMachineTests.swift`
  - V2 route includes Story Anchor before concrete.
- `Tests/MatherTests/VerticalSliceEngineTests.swift`
  - Starting V2 session enters Story Anchor.
  - Advancing Story Anchor enters concrete without changing problem.

Acceptance:

- Child hears/sees the story target before building.
- Story Anchor is not a quiz/failure gate.

### M3 — Story-aware Sum Sprint and Bond Blast recall

**Lane E status:** Gravity Split, embedded Sum Sprint, and Bond Blast now use `NumberStoryStageVocabulary` to derive child-facing story labels, instructions, and accessibility reminders from `NumberStoryPrompt`. Math truth remains owned by `SliceProblem`, `SumSprintBurstState.make(for:)`, and `BondMatchState.makePairs(for:)`.

**Goal:** Reinforce the same story target during recall stages.

Files:

- `Domain/SliceModels.swift`
  - Extend `SumSprintBurstState` or add adjacent view model with optional story target/title.
  - Keep math-card generation deterministic from `SliceProblem`.
- `Features/VerticalSlice1/SliceSessionView.swift`
  - Display story badge/title in Sum Sprint.
- `Features/VerticalSlice1/BondMatchView.swift`
  - Display the story target reminder in Bond Blast.

Tests:

- Unit tests for story-aware burst view model preserving `problem.target`.
- UI/snapshot/accessibility test for story badge appearing in at least one stage.

Acceptance:

- Sum Sprint/Bond Blast remind the child of the same story target.
- No timer or racing language is introduced.

### M4 — Optional Apple Intelligence variation layer

**Goal:** AI can vary wording only when available and valid; curated fallback remains default truth.

Files:

- `Services/NumberStoryService.swift`
  - Orchestrates curated fallback + optional adapter.
- `Services/NumberStoryAIAdapter.swift`
  - `isAvailable`
  - `storyPrompt(for:) async throws -> NumberStoryDraft?`
- `Services/FoundationModelsNumberStoryAIAdapter.swift`
  - Availability-gated implementation; may initially return unavailable like Memory adapter.
- `Domain/NumberStoryValidator.swift`
  - Enforce exact target/parts, max length, child-safe language, no off-device instructions.

Tests:

- unavailable AI returns curated fallback.
- invalid AI draft falls back.
- valid AI draft may replace only narrative wording, never math values.

Acceptance:

- AI is never required for the feature.
- AI cannot change target/decomposition.
- Failure path is silent and safe.

### M5 — Future Room Quest fusion note

Room Quest can later become a concrete story variant where the child collects the two parts around the room. Do not include it in #400 implementation beyond preserving a clean seam and avoiding off-device instructions in non-Room-Quest stories.

## File map

| Area | Files | Notes |
| --- | --- | --- |
| Config/cap | `Features/VerticalSlice1/SessionConfigView.swift`, `Domain/SliceModels.swift`, `Domain/VerticalSliceEngine.swift`, `Tests/MatherTests/ProblemGeneratorTests.swift` | M0 only needs config UI + generator tests because model/generator already support 1...20. |
| Story domain | `Domain/NumberStoryModels.swift`, `Domain/NumberStoryGenerator.swift`, `Tests/MatherTests/NumberStoryGeneratorTests.swift` | New deterministic core. |
| Route/stage | `Domain/SliceModels.swift`, `Domain/SliceStateMachine.swift`, `Domain/VerticalSliceEngine.swift`, `Tests/MatherTests/SliceStateMachineTests.swift`, `Tests/MatherTests/VerticalSliceEngineTests.swift` | Add Story Anchor to V2 route. |
| Child UI | `Features/VerticalSlice1/SliceSessionView.swift`, new `Features/VerticalSlice1/StoryAnchorView.swift`, `Features/VerticalSlice1/BondMatchView.swift` | Story Anchor + reminder badges. |
| AI variation | `Services/NumberStoryService.swift`, `Services/NumberStoryAIAdapter.swift`, `Services/FoundationModelsNumberStoryAIAdapter.swift`, `Domain/NumberStoryValidator.swift` | Optional/fallback-first. |
| Existing AI reference | `Services/MemoryCardDescribeService.swift`, Memory AI adapter files | Pattern to copy, not a dependency. |

## Test map

Minimum test gates by milestone:

- M0:
  - `ProblemGeneratorTests.deterministicGenerationRespectsParentFacingTargetCap`
  - `ProblemGeneratorTests.randomGenerationRespectsUpToTenCap`
  - `git diff --check`
  - Xcode test target when macOS/Xcode is available.
- M1:
  - `NumberStoryGeneratorTests` for consistency, determinism, and exact-number inclusion.
- M2:
  - `SliceStateMachineTests` for Story Anchor route.
  - `VerticalSliceEngineTests` for session start and transition behavior.
- M3:
  - Unit test for story reminder view model.
  - One UI/accessibility path proving the story badge is reachable.
- M4:
  - AI unavailable fallback.
  - AI invalid draft fallback.
  - AI valid draft sanitizer success.

## Acceptance criteria for #400 completion

- Parent can choose max target **10** or **20** before a Make & Break session.
- Generated problems respect the selected cap.
- Every problem has a curated story prompt tied to the exact `SliceProblem` values.
- Story Anchor appears before Make It in the V2 flow.
- Sum Sprint and Bond Blast display or speak the same story target reminder.
- Apple Intelligence is optional, availability-gated, sanitized, and fallback-first.
- Tests cover target cap generation, story-number consistency, unavailable-AI fallback, and at least one story-aware UI path.
- Room Quest appears only as a future integration note.

## Risks and mitigations

| Risk | Mitigation |
| --- | --- |
| Story text diverges from math truth | Generate story from `SliceProblem`; validate exact target/parts; fallback on any mismatch. |
| Story Anchor makes sessions feel slow | Keep one short spoken line and one tap to continue; no assessment gate. |
| Sum Sprint becomes too busy | Use a small badge/title, not long text on every card. |
| AI introduces unsafe or wrong text | Fallback-first service, strict validator, no AI math authority. |
| Cap UI implies support above 20 | Only expose `10` and `20` until representation/generator work expands. |
| Existing deterministic tests become brittle | Add cap-specific tests without changing default deterministic sequence. |

## First implementation slice status

A small safe M0 slice is feasible and should be PR-sized:

- Add `Up to 10` / `Up to 20` buttons to `SessionConfigView`.
- Wire buttons to existing `engine.updateConfig(minTarget: 1, maxTarget: cap)`.
- Add generator tests proving cap behavior.

This avoids broad story UI churn while establishing the parent-facing cap required by #400.
