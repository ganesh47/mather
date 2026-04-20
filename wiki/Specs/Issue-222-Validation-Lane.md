# Issue #222 Validation Lane

Source issue: https://github.com/ganesh47/mather/issues/222

This is the QA and release lane for the remaining work after PR #234 (PR1 groundwork).

## Baseline after PR #234
PR #234 establishes the generator/session groundwork. The remaining validation lane starts at PR2.

## CI gates required on every remaining PR
A PR is not done until all of the following are green on the PR branch:

- `CI / Build & Test`
- `CodeQL / Analyze Actions Workflows`
- `Dependency Review / Dependency Review`
- `Workflow Lint / actionlint` when workflow files change

Required PR evidence:
- link or screenshot of green GitHub checks
- short test note listing any added or updated automated coverage
- explicit note if simulator-only validation was done and which device/runtime was used

## Device-validation checkpoints
Because #222 changes learning flow and pacing, automated checks alone are not enough.

### Required manual validation environments before issue close
- 1 iPhone simulator run on the current CI-supported runtime
- 1 real-device run on iPhone or iPad before PR6 is called done

### Manual validation target bands
Use at least these target samples:
- low: 1, 2, 5
- mid: 8, 10, 12
- high: 16, 18, 20

### Core manual assertions
- session does not anchor on 6
- each target follows `Make it -> Gravity Split -> Sum Sprint -> Bond Blast`
- no stage appears pre-solved on entry
- stage exits return to the same target loop until Bond Blast completes
- pacing still feels short and legible across a multi-target session
- summary/copy/telemetry still make sense

## Evidence package expected on each PR
Post this in the PR body or a review comment before marking ready to merge:

- `Automated:` tests added/updated, plus green checks
- `Simulator:` device + OS + what was exercised
- `Manual:` observed behavior against the PR-specific checklist below
- `Artifacts:` screenshot, short screen recording, or xcresult/artifact link when UI changed
- `Risks left:` anything deferred to a later PR

---

## PR2, loop routing/state-machine refactor

### Done only if
- automated tests prove the per-target route order is exactly 4 stages
- old path remains safe behind flag, or replacement path is fully coherent
- session completion happens only after final target Bond Blast
- no legacy last-problem-only Bond Blast assumption remains in the new route

### Required evidence
- unit test coverage for state-machine transitions and loop completion
- one simulator trace or screen recording showing 2 full target loops back-to-back
- note naming the flag/path used for old-vs-new routing

### Release risk to watch
- silent routing regressions that skip or duplicate a stage

---

## PR3, Gravity Split zero-state fix

### Done only if
- Gravity Split always enters unsolved from zero-state per approved contract
- plus/minus interaction can reach valid decompositions across low and high targets
- success never fires on entry or first idle sensor sample
- any retained tilt behavior cannot auto-solve the stage

### Required evidence
- tests covering unsolved entry and success-only-after-child-action
- manual validation on targets 2, 5, 10, 18, 20
- short recording or screenshots proving entry state is unsolved on at least 3 separate launches

### Release risk to watch
- stage still feels pre-solved or confusing despite passing unit tests

---

## PR4, embedded Sum Sprint micro-burst

### Done only if
- every target loop enters Sum Sprint in loop V2
- embedded Sum Sprint returns to the same target loop, not summary/home
- fact count stays within 1-3 cards per target in V1
- added time per target stays within the agreed micro-burst budget

### Required evidence
- tests proving loop entry/exit and card-count bounds
- simulator validation on low, mid, and high target bands
- timing evidence from instrumentation, logs, or measured playthrough notes for at least 5 loops

### Release risk to watch
- fluency stage bloats session length or feels like a separate mode switch

---

## PR5, Bond Blast per-target micro-capstone

### Done only if
- Bond Blast appears for every target, not only the last one
- completion returns to next target instead of a legacy summary path
- target-specific pair generation remains correct through 20
- celebration timing is shortened enough to preserve session pacing

### Required evidence
- tests for per-target entry and correct target-specific content
- real UI evidence, screenshot or recording, from at least 3 different targets including one in 16-20
- manual pacing note from a 6-target end-to-end run

### Release risk to watch
- delight is preserved, but cumulative animation delay makes sessions drag

---

## PR6, release hardening and cutover

### Done only if
- all prior PR gates are satisfied together in one end-to-end flagged run
- copy, summaries, screenshots, and labels no longer contradict the 1-20 loop
- flag-off legacy path still works if dual-path safety remains
- flag-on path completes full sessions across low and high targets without stage-order defects
- telemetry or session logs are coherent enough to review rollout health

### Required evidence
- full green CI on the release PR
- one simulator end-to-end run with artifacts
- one real-device end-to-end run with artifacts
- release checklist comment including: target sample set used, total session duration, any friction points, and ship recommendation

### Ship recommendation threshold
PR6 should only be called done when QA can state all of the following:
- loop order is stable
- Gravity Split is no longer pre-solved
- Sum Sprint and Bond Blast are present on every target
- pacing is acceptable across a full session
- no blocker remains for limited-flag rollout

---

## Issue #222 close criteria
Issue #222 is ready to close only after PR6 supplies:
- green CI
- real-device validation evidence
- end-to-end 1-20 loop proof
- pacing signoff
- rollout recommendation for the loop flag
