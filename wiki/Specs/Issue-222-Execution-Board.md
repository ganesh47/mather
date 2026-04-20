# Issue #222 Execution Board

Source issue: https://github.com/ganesh47/mather/issues/222

## Goal
Ship issue #222 as a controlled sequence of small PRs that converts VS1 from its current mostly VS1-style flow into a repeatable per-target loop:

1. Make it
2. Gravity Split
3. Standard Sum Sprint
4. Bond Blast

across randomized targets in the 1-20 range, while keeping session pacing short and validation visible at each merge point.

---

## Remaining execution checklist after PR #234

Legend: `DONE`, `IN PR`, `NEXT`, `BLOCKED`, `GATE`

| Work item | Owner role | Status | Depends on | Merge gate |
| --- | --- | --- | --- | --- |
| PR #234, target range and randomized sequencing groundwork | Engine owner | IN PR | None | Review merged, generator tests green, no fixed 6 anchor in samples |
| PR2, per-target loop routing in engine/state machine | Engine owner | NEXT | PR #234 | Exact order is `Make it -> Gravity Split -> Sum Sprint -> Bond Blast`, old route remains safe behind flag or replacement is complete |
| PR3, Gravity Split zero-state plus/minus interaction | Gameplay owner | BLOCKED | PR2 | Starts from zero, never enters solved, success only after child action |
| PR4, embedded Sum Sprint micro-burst per target | Fluency systems owner | BLOCKED | PR2 | Present in every loop, 1-3 facts, returns to same target loop, pacing stays tight |
| PR5, per-target Bond Blast micro-capstone | Gameplay owner | BLOCKED | PR2, preferably after PR4 for pacing tune | Present in every loop, short capstone, returns to next target cleanly |
| PR6, release hardening and cutover | QA and release owner | BLOCKED | PR3, PR4, PR5 | Full 4-stage loop works across 1-20, copy updated, telemetry reviewed, rollout flag decision made |

### Merge order
1. Merge PR #234.
2. Land PR2 as the architecture hinge.
3. Run PR3 and PR4 in parallel once PR2 lands.
4. Land PR5 after PR4 is visible enough to tune total loop pacing.
5. Finish with PR6 and rollout review.

### Non-negotiable gates before closing #222
- No session is anchored to 6 by default.
- Every target runs all 4 stages in order.
- Gravity Split never feels pre-solved.
- Sum Sprint and Bond Blast are both loop-sized, not standalone-length.
- Session duration remains inside pacing budget on repeated targets.
- New flow is protected by a rollout flag until QA signoff.

## Recommended release strategy
- Use a temporary umbrella flag for the new loop, for example `feature.makeBreakLoopV2Enabled`.
- Keep existing shipped VS1 flow intact until the full loop passes QA.
- Merge each phase behind flags where needed, then enable only after the final integration checkpoint.
- Prefer 5 small PRs plus 1 release-hardening PR, rather than one large rewrite.

---

## Dependency map

### Hard dependencies
1. PR1 session model and generator expansion must land before any loop integration PR.
2. PR2 stage-routing refactor must land before Sum Sprint and per-target Bond Blast can be inserted cleanly.
3. PR3 Gravity Split zero-state fix depends on PR2 routing contract.
4. PR4 Sum Sprint micro-burst embedding depends on PR2 routing and PR1 target generation.
5. PR5 Bond Blast per-target capstone depends on PR2 routing and should integrate after PR4 so pacing can be tuned with the full loop visible.
6. PR6 release hardening depends on all previous PRs.

### Can be developed in parallel after PR2
- Gravity Split implementation work
- Sum Sprint micro-session work
- Bond Blast micro-capstone work

---

## Execution board

## Phase 0, spec lock and instrumentation contract

### Outcome
Freeze the exact loop contract before touching flow logic.

### PR0 scope
- Add or update a spec note covering:
  - loop order is exactly `Make it -> Gravity Split -> Sum Sprint -> Bond Blast`
  - loop repeats per target
  - targets span 1-20
  - target order is randomized with repeat control
  - Sum Sprint is 1-3 facts per target in V1
  - Bond Blast is micro-sized per target, not last-problem-only
- Define telemetry names for:
  - target presented
  - stage entered/completed
  - loop completed
  - session completed
  - stage duration by target
- Add acceptance matrix rows for issue #222.

### Validation gate
- Product and engineering agree on stage order and pacing budget.
- No unresolved ambiguity around whether Bond Blast remains last-problem-only. For #222 V1, it should not.

### Merge checkpoint
- Spec approved.
- Telemetry/event names agreed.

---

## Phase 1, expand session model from VS1 6-10 into randomized 1-20 targets

### Outcome
The engine can produce sane target sequences for the new loop without yet changing the UI flow.

### PR1 scope
- Update `SliceConfig` defaults and labels from 6-10 / to 10 language to 1-20 language where appropriate.
- Replace the current deterministic seed and random generator behavior in `ProblemGenerator` so it:
  - supports 1-20
  - avoids boring immediate repeats
  - avoids wild difficulty whiplash where possible
  - still supports deterministic test mode
- Add generator rules for decomposition quality:
  - avoid too many trivial `0 + n` cases unless intentionally sampled
  - include both symmetric and asymmetric decompositions
  - preserve reproducibility in tests
- Update session-summary titles and parent-facing strings that still say "Make & Break to 10".

### Suggested tests
- generator returns only 1-20 targets
- deterministic mode snapshot covers the new range
- randomized sessions do not always start at 6
- repeat suppression works
- decomposition invariants always sum to target

### Validation gate
- A 20-30 session sample looks varied by inspection.
- No regressions in existing session start or summary flows.

### Merge checkpoint
- Safe to merge independently because it only broadens problem generation and copy.

---

## Phase 2, refactor stage routing to support a true per-target 4-stage loop

### Outcome
The state machine and engine can express the new loop directly instead of forcing it through current VS1 assumptions.

### PR2 scope
- Refactor `SliceStage`, `SliceStateMachine`, and `VerticalSliceEngine` so one target can route through:
  - concrete make stage
  - gravity split stage
  - sum sprint micro-stage
  - bond blast micro-stage
  - next target
- Remove the current "Bond Blast only on last problem" assumption from stage progression.
- Decide whether current `pictorial` maps to Bond Blast micro-capstone or whether a new dedicated stage enum is cleaner. Recommendation: introduce explicit stage naming now if it simplifies future maintenance.
- Decide what happens to `abstract` and `transfer` in loop V2. Recommendation: do not leave them half-alive in the same path. Either gate old VS1 route vs new loop route, or fully define their role in V2.
- Add a dedicated loop-progress model so per-target completion is explicit.

### Suggested tests
- state machine transitions for new loop order
- each target advances to next target only after Bond Blast completion
- feature-flagged old route still works until cutover
- session completion occurs after final target loop, not after a leftover legacy stage condition

### Validation gate
- Engine can run the new order with placeholder implementations for later stages.
- Team agrees the migration path from legacy stage names is understandable.

### Merge checkpoint
- This is the architecture PR. Do not merge unless old and new routes are both testable or the replacement is complete enough to keep the app usable.

---

## Phase 3, fix Gravity Split so it starts from zero and feels earned

### Outcome
Gravity Split becomes playable and child-driven.

### PR3 scope
- Change `GravitySplitState` initialization so the split starts from 0, not near-solved.
- Make plus/minus taps the required V1 interaction path.
- Keep tilt only as optional polish behind a separate flag if retained.
- Prevent auto-solve on stage entry and on first sensor sample.
- Tune prompts and success logic so the child clearly understands they are building the split.
- Add simple reset behavior if needed.

### Suggested tests
- stage starts with left/right at zeroed child-built state per approved rule
- entering Gravity Split never begins solved
- taps can reach all valid split values
- success only triggers after child adjustment reaches target decomposition
- tilt, if still enabled, cannot instantly solve on entry

### Validation gate
- Manual playtest: 10 consecutive entries should never feel pre-solved.
- 5-year-old comprehension check: controls are understandable without explanation overload.

### Merge checkpoint
- Merge only after playability signoff, because this is the issue's sharpest defect.

---

## Phase 4, embed Sum Sprint as a micro-burst inside every target loop

### Outcome
Sum Sprint appears in every loop without turning the session into a long fluency detour.

### PR4 scope
- Reuse `SumSprintEngine` as a per-target embedded micro-session, not a standalone route.
- Add a loop-scoped session builder that selects 1-3 facts tied to the current target or current difficulty band.
- Define completion contract clearly:
  - one correct answer may be enough for target 1-5
  - two to three facts for higher targets if pacing still holds
- Keep existing standalone Sum Sprint capability intact unless intentionally retired.
- Record telemetry separately for embedded vs standalone Sum Sprint.

### Suggested tests
- every target loop enters Sum Sprint when loop V2 flag is on
- embedded Sum Sprint exits back to the same target loop, not home or standalone summary
- card count stays within V1 limit
- total loop time remains within pacing budget in tests or instrumentation

### Validation gate
- Median added time per target stays inside agreed budget, recommended 10-20 seconds.
- Fluency content feels like reinforcement, not mode-switch whiplash.

### Merge checkpoint
- Merge when embedded flow is stable, even if fact-selection tuning remains modest.

---

## Phase 5, make Bond Blast a per-target micro-capstone

### Outcome
Bond Blast happens on every target as the playful finish, instead of only at the session end.

### PR5 scope
- Rework Bond Blast entry criteria so it fires once per target loop.
- Scale pair count and animation length down to loop-sized pacing.
- Preserve delight, but shorten completion time and celebration hold time.
- Ensure target-specific prompts and pair generation still match the active target.
- Review whether motion/clap enhancements remain sensible in a per-target cadence. Recommendation: tap-first baseline, sensors optional.

### Suggested tests
- Bond Blast appears for every target in loop V2
- target-specific pair generation stays correct across 1-20
- completion returns to next target, not legacy summary path
- pacing does not stack excessive delays across multi-target sessions

### Validation gate
- End-to-end sessions feel consistent across at least 6 targets.
- Total session duration still fits the product window.

### Merge checkpoint
- Merge after real-device playtest, because delight and pacing matter more than unit coverage alone here.

---

## Phase 6, release hardening and cutover

### Outcome
The new loop is ready to ship broadly.

### PR6 scope
- Update screenshots, UI tests, and settings labels.
- Clean up stale "to 10" copy and obsolete route assumptions.
- Add or update parent summary language for the new loop.
- Run end-to-end QA with flags on and off.
- Remove dead legacy code only if the new loop is clearly stable. Otherwise keep one release of dual-path safety.

### Required validation matrix
- Unit tests pass
- UI smoke tests pass
- deterministic mode remains stable
- manual test on small targets 1-5
- manual test on large targets 16-20
- no stage starts solved
- no session starts anchored to 6
- every target shows all 4 stages in order
- total session duration still acceptable
- summaries and telemetry remain coherent

### Release checkpoint
- Enable the umbrella flag for internal testing first.
- Ship to a limited audience or test cohort.
- Review telemetry for:
  - loop completion rate
  - stage abandonment rate
  - median stage duration
  - session duration
  - high-friction targets
- Only then promote to default-on.

---

## Recommended PR sequence
1. PR0 spec lock and acceptance matrix
2. PR1 generator and 1-20 session groundwork
3. PR2 loop routing/state-machine refactor
4. PR3 Gravity Split zero-state fix
5. PR4 embedded Sum Sprint micro-burst
6. PR5 per-target Bond Blast micro-capstone
7. PR6 release hardening, QA, and cutover

If parallelizing after PR2:
- Track A: PR3 Gravity Split
- Track B: PR4 Sum Sprint embedding
- Track C: PR5 Bond Blast resizing
- Final integrator PR: PR6

---

## Recommended ownership split
- Product/design: pacing budget, target randomization rules, micro-stage success criteria
- Engine/state owner: PR2 integration contract
- Gameplay owner: PR3 and PR5 feel tuning
- Fluency/learning systems owner: PR4 fact-selection and pacing
- QA/release owner: PR6 validation matrix and rollout gates

---

## Key risks and mitigations

### Risk: loop becomes too long
Mitigation: lock stage-level time budgets before implementation, keep Sum Sprint to 1-3 facts, reduce Bond Blast pair count and celebration delays.

### Risk: legacy VS1 assumptions fight the new architecture
Mitigation: use a loop V2 flag and isolate routing changes in PR2 before feature work branches off.

### Risk: Gravity Split is still confusing
Mitigation: tap-first V1, no preloaded solved state, manual playability signoff before broader merge.

### Risk: 1-20 randomization feels chaotic
Mitigation: generator should suppress immediate repeats and optionally band jumps, plus keep deterministic fixtures for testing.

### Risk: telemetry becomes incomparable with old VS1 sessions
Mitigation: version the loop mode in session payloads and distinguish embedded vs standalone Sum Sprint.

---

## Definition of done for issue #222
Issue #222 is done when a child can run a session in which each randomized target from the 1-20 range follows the same four-stage order, Gravity Split starts unsolved from zero and requires active adjustment, Sum Sprint and Bond Blast both appear as short per-target stages, and the resulting session still feels short, legible, and repeatable.
