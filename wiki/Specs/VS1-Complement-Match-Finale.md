# Spec: VS1 Complement Match Finale

**Issue**: #137
**Status**: implemented in shipped slice, follow-up polish remains
**Author**: @ganesh47
**Date**: 2026-04-09

## Overview
Add a final complement-matching stage to the VS1 make-and-break flow so the child pairs two numbers that compose the session total, using large snap-to-match drag interactions with immediate audio feedback. This stage extends the same mathematical idea already taught in VS1, but emphasizes flexible decomposition families through a more game-like finale.

## User Stories
- As a child, I want to drag number cards to matching partners so I can discover all the pairs that make the same total.
- As a child, I want quick sounds and celebrations when I match correctly so the last stage feels fun and motivating.
- As a parent, I want this stage to reinforce number bonds without adding reading-heavy instructions.
- As a product owner, I want telemetry on retries, accuracy, and completion time so we can evaluate whether this stage helps or frustrates children.

## Acceptance Criteria
### Functional
- [x] A final complement-match stage can be enabled for VS1 problems with totals up to 10.
- [x] The child can complete the stage using large tap-or-drag matching targets with strong snap-like completion behavior.
- [x] The stage presents valid complement pairs for the target total, including symmetric pairs such as `3 + 3` when applicable.
- [x] Correct matches lock visually and are not accidentally broken by later interactions.
- [x] Incorrect drops or wrong partner taps keep the child in the same stage with gentle retry feedback.
- [x] Stage completion is determined by all required complement pairs being matched.
- [x] Stage telemetry records matches, mismatches, drag starts, near-target events, and completion progression locally.
- [x] The child flow remains usable without mandatory reading.

### UX / Experience
- [x] All cards and targets use the existing large child-friendly touch baseline.
- [x] The stage uses calm, low-clutter layout with a bounded visible pair set.
- [x] Each correct match produces immediate motivating feedback.
- [x] Retry feedback is gentle and non-punitive.
- [x] Full-stage completion produces a larger celebration than individual pair matches.

### Engineering
- [x] The new stage integrates into the existing `SliceStage` progression without breaking existing VS1 flows when disabled.
- [x] Telemetry captures pair-match interaction events locally.
- [x] Audio/haptic feedback supports spoken prompts plus low-latency interaction feedback.
- [x] Unit/UI tests cover successful complement-match flow.

## Design

### Product Framing
This is a follow-on VS1 capability, not a retroactive rewrite of the already-implemented base milestone. It now ships as a gated additive finale under the existing Bond Blast framing.

### Interaction Model
- The top of the screen shows the target total.
- One side presents draggable number cards.
- The other side presents complement targets or partner cards.
- A card dragged close to the correct partner snaps into place.
- A correct pair locks and animates subtly.
- An incorrect drop gently bounces back.
- The stage completes once all required pairs are matched.

### Pair Set Rules
For a target `n`, generate unique complement pairs `(a, b)` where:
- `a + b = n`
- `a <= b` to avoid duplicate facts
- include doubles like `(3,3)` when `n` is even

Examples:
- `6` -> `(1,5)`, `(2,4)`, `(3,3)`
- `7` -> `(1,6)`, `(2,5)`, `(3,4)`
- `8` -> `(1,7)`, `(2,6)`, `(3,5)`, `(4,4)`

### SwiftUI Views
- `ComplementMatchView`
  - renders draggable number cards, snap targets, locked matches, and per-pair feedback
- `SliceSessionView`
  - routes to the complement-match stage when enabled
- optional small supporting subviews:
  - `ComplementMatchCardView`
  - `ComplementMatchLaneView`
  - `ComplementMatchCelebrationView`

### Data Model
Potential new model additions:
- `SliceStage`
  - add `.pairMatch` or `.bondMatch`
- `ComplementPair`
  - `id`, `leftValue`, `rightValue`, `isMatched`
- `ComplementMatchState`
  - active drag item
  - matched pair ids
  - mismatch count
  - startedAt / completedAt

### Navigation
Suggested progression:
- `Concrete -> Bond Blast -> Abstract -> Transfer -> Bond Blast Finale -> Done` in the current shipped naming model

Rollout path:
- gate the finale between `Transfer -> Done` and `Transfer -> Bond Blast Finale -> Done` using `FeatureFlags.vs1BondMatchEnabled`

### State Management
Keep orchestration inside `VerticalSliceEngine`.
- engine owns generated pair set, score counters, prompt text, and completion logic
- view owns transient drag gesture state only
- telemetry events are emitted from engine-level match confirmations and stage completion

## Feature Flag
Implemented flag:
- `FeatureFlags.vs1BondMatchEnabled`

## Telemetry
Suggested additional local events:
- `pair_match_started`
- `pair_drag_started`
- `pair_dropped`
- `pair_matched`
- `pair_mismatch`
- `pair_match_completed`

Suggested summary fields:
- `pairs_total`
- `pairs_matched`
- `pair_mismatch_count`
- `pair_match_time_ms`

## Audio
Recommended split:
- spoken prompt path remains in `SpeechService`
- new lightweight sound effect service handles:
  - pickup
  - snap
  - correct match
  - retry
  - stage completion celebration

## Accessibility / Child Safety Constraints
- no precise tiny drag targets
- strong magnetic drop regions
- visible matched-state lock-in
- optional future tap-select/tap-match fallback for accessibility or compact layouts
- no punitive wording or harsh failure sounds

## Out of Scope
- open free-canvas dragging
- multiplayer or competitive scoring
- public leaderboard / stars economy
- remote telemetry sync
- expanding target values beyond current VS1 scope in the first iteration

## Open Questions
- [ ] Should this stage always appear, or only on the final problem in a session?
- [ ] Should compact iPhone layout use the same drag interaction or a tap-match fallback?
- [ ] Should scoring feed only telemetry, or also influence parent summary wording?
- [ ] Should the stage replace current transfer in some configurations, or always follow it?

## References
- Related research: [VS1 Complement Match Finale](../Research/VS1-Complement-Match-Finale.md)
- Related research: [Math App Vision](../Research/Math-App-Vision.md)
- Related research: [Playful Themes for VS1](../Research/Playful-Themes-for-VS1.md)
- Related spec: [VS1 Make & Break to 10](VS1-Make-and-Break-to-10.md)
