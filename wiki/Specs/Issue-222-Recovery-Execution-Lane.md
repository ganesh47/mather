# Issue #222 Recovery Execution Lane

Date: 2026-04-19
Status: recovery / reopened against shipped product truth

## Why this exists
Issue #222 was previously closed, but shipped product truth does not satisfy the promised scope.
Current released behavior still presents Make & Break as 1-10 in real UI surfaces and does not yet deliver the promised repeated 4-stage per-target loop end to end.

This document resets execution against what is actually shipped, not prior planning or bookkeeping.

## Shipped truth baseline
Observed/reported and corroborated from current code:
- Make & Break still presents as "Make & Break to 10" in live UI surfaces.
- Current stage routing still reflects the older path and semantics.
- Bond Blast semantics are still split awkwardly across `pictorial` and `bondMatch`.
- Gravity Split zero-start child-built behavior is not established as shipped truth.
- Sum Sprint exists as a standalone route, but not yet as the promised embedded per-target loop stage in shipped behavior.

## What actually landed from the prior #222 lane
### Merged PRs tied to the prior execution lane
- PR #234 — `feat(vs1): expand 1-20 target generation groundwork`
- PR #235 — `feat(vs1): add loop-v2 stage routing scaffold`

### What that means
These PRs are real, but they appear to have landed as groundwork/scaffolding rather than full shipped product completion.
The user-observed release behavior is the source of truth: the end-to-end promised delta is still missing.

## Missing product delta still required
1. 1-20 range in real UI and real shipped behavior
2. repeated 4-stage loop per target:
   - Make it
   - Gravity Split
   - Sum Sprint
   - Bond Blast
3. Gravity Split zero-start child-built behavior
4. Sum Sprint + Bond Blast integrated in every target loop
5. release-truth validation before reclosing #222

## Recovery execution slices

### RX1 — surface and configuration truth
Goal:
- make the real product present as 1-20, not 1-10

Scope:
- update live UI strings still saying "Make & Break to 10"
- verify/configure actual target generation used in shipped sessions
- verify V2 path can be reached in the real product path, not only in code scaffolding

Done when:
- shipped/tested UI shows 1-20 language where appropriate
- real session targets demonstrably include the broader range

### RX2 — route truth
Goal:
- make the actual shipped stage order follow the promised repeated loop

Scope:
- connect the real child-facing route to the V2 loop path
- remove dependence on old semantics where `pictorial` still acts like Bond Blast
- ensure every target follows the same four-stage order

Done when:
- end-to-end session trace proves per-target loop order in simulator/device runs

### RX3 — Gravity Split truth
Goal:
- fix Gravity Split to start unsolved from zero and require child-built adjustment

Scope:
- zero-start state
- child-controlled plus/minus interaction
- no effectively pre-solved entry state
- no accidental auto-complete

Done when:
- repeated launches across multiple targets prove unsolved entry and child-built completion

### RX4 — embedded Sum Sprint truth
Goal:
- integrate Sum Sprint into each target cycle as a short embedded stage

Scope:
- replace placeholder behavior with real embedded micro-session
- ensure pacing is short and repeatable
- preserve standalone Sum Sprint route if desired, but do not rely on it for #222 closure

Done when:
- every target loop includes a short Sum Sprint stage in real product behavior

### RX5 — embedded Bond Blast truth
Goal:
- make Bond Blast appear per target, not only under older/ambiguous semantics

Scope:
- clean up stage semantics
- make Bond Blast a true per-target micro-capstone
- verify pacing across multiple targets

Done when:
- every target loop includes Bond Blast in the intended position and pacing remains acceptable

### RX6 — release-truth validation and honest re-close
Goal:
- validate the actual release behavior before reclosing #222

Required evidence:
- green CI on final recovery PRs
- simulator trace showing multiple target loops in correct order
- current main/release screen recording or screenshots demonstrating the corrected flow
- real-device smoke validation if release candidate behavior is still uncertain
- issue close comment explicitly referencing shipped truth and validation evidence

## Non-goal
Do not treat issue closure, merged scaffolding PRs, or planning artifacts as completion evidence by themselves.
Only shipped behavior and validation evidence count.

## Coordinator note
Future status updates should clearly separate:
- scaffolding landed
- code path exists behind flag
- shipped product truth
- validated release truth

#222 should only be reclosed after RX1–RX6 are satisfied.
