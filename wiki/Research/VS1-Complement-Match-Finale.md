# Research: VS1 Complement Match Finale

**Issue**: ganesh47/mather#137
**Status**: Completed
**Date**: 2026-04-09

## Question
How should Mather add a final drag-and-match complement stage to VS1 so children can pair two numbers that make the same total, without weakening the current CPA loop or creating frustrating motor demands for ages 5–7?

## Context
- Current VS1 already completes a coherent CPA loop: Concrete -> Pictorial -> Abstract -> Transfer.
- A proposed follow-on capability would add one more finale where the child matches decomposition pairs for the target total, for example `6` as `1+5`, `2+4`, and `3+3`.
- The desired interaction is playful, direct-manipulation-first, and should include live motivational sounds during matching.
- Existing Mather research already constrains this space:
  - child touch interactions must stay large, obvious, and reading-light
  - precision-heavy free drag is risky for 5-year-olds
  - math should remain visually transparent, not hidden behind decorative play
  - audio should provide immediate, warm feedback without punitive cues

## Prior Research Synthesis
- `Math-App-Vision` supports CPA-native gameplay, immediate audio/visual feedback, large magnetic drop zones, and gentle bounce-back on wrong drops.
- `Playful-Themes-for-VS1` recommends direct manipulation with constrained movement, not open freeform drag maps, especially for younger children.
- Existing VS1 spec requires large touch targets, spoken instructions, and gentle actionable retry states.

## Options Evaluated

### Option A: Freeform drag pairing board
The child drags any number token anywhere on an open canvas and manually connects or positions it against another number token.

Strengths:
- feels playful at first glance
- gives maximum movement freedom

Weaknesses:
- highest precision burden
- increased hand occlusion risk
- harder to communicate valid drop states
- more likely to frustrate 5-year-olds
- greater implementation complexity for collision, placement, and accessibility fallback

### Option B: Constrained snap-to-match board
The child drags large number cards from one column or lane to matching complement targets in another column. When the dragged card gets close enough to the correct partner, it snaps into place and locks visually.

Strengths:
- preserves direct manipulation while reducing precision demands
- makes success states obvious
- keeps quantity structure central
- easier to add immediate sound cues and gentle retry behavior
- simpler to test and instrument than freeform placement

Weaknesses:
- slightly less "open play" feeling than a free canvas
- requires careful visual design so it feels game-like rather than worksheet-like

### Option C: Tap-select then tap-match only
The child taps one number, then taps its matching complement partner.

Strengths:
- lowest motor burden
- easiest accessibility fallback
- straightforward to implement and test

Weaknesses:
- loses much of the tactile drag-play feeling desired for the finale
- less differentiated from the current transfer stage

## Comparison

| Criterion | Option A: Freeform drag | Option B: Snap-to-match | Option C: Tap-match only |
|---|---|---|---|
| Learning clarity | Medium | High | High |
| Motor suitability for age 5–7 | Low | High | Very high |
| Play feel | Medium to high | High | Medium |
| Implementation risk | High | Medium | Low |
| Accessibility fallback burden | High | Medium | Low |
| Fit with current VS1 architecture | Low | High | Medium |

## Recommendation
Adopt **Option B: constrained snap-to-match board** as the recommended design for a follow-on VS1 finale.

Recommended experience:
- show the target total clearly at the top, e.g. `Make 6`
- present a bounded set of complement pairs for that target
- use large draggable number cards and large magnetic snap targets
- lock correct pairs visually once matched
- on incorrect drop, animate a gentle bounce-back rather than a harsh failure state
- play immediate non-verbal feedback sounds for pickup, snap, correct pair, and stage completion
- keep spoken prompts short and action-led, for example: `Match the two numbers that make 6.`

## Decision
- **Decided in research**: use a **snap-constrained complement matching** stage, not open freeform drag.
- **Recommended product framing**: treat this as a **follow-on VS1 capability** that extends the current finale, rather than silently redefining the already-implemented VS1 acceptance criteria.
- **Recommended naming**: `Complement Match Finale`.

## Proposed Capability Shape
- Target range stays bounded to VS1 targets up to 10.
- Child pairs complement facts for the session total, e.g. for `6`: `1+5`, `2+4`, `3+3`.
- Stage score should be derived from:
  - successful matches completed
  - retry count / mismatched drops
  - completion time
- Child-facing feedback should emphasize progress and completion, not error count.
- Parent/telemetry-facing metrics can include complement-match accuracy and retries.

## Recommended Audio Behavior
Use two layers of audio feedback:

1. **Spoken prompts**
   - first-time stage prompt
   - contextual encouragement after a correct match or near completion

2. **Short live sound effects**
   - pickup / hover cue
   - snap / place cue
   - correct match chime
   - gentle retry cue
   - bigger completion celebration cue

This should be implemented as a lightweight sound-effect path alongside speech, rather than relying on TTS alone.

## Implementation Implications
Likely follow-on repo touchpoints:
- `Domain/SliceModels.swift`
  - add a new stage such as `.pairMatch` or `.bondMatch`
- `Domain/SliceStateMachine.swift`
  - extend stage progression rules
- `Domain/VerticalSliceEngine.swift`
  - add match-stage state, prompt routing, scoring, and telemetry events
- `Features/VerticalSlice1/`
  - add a new `ComplementMatchView.swift`
- `Services/`
  - add a lightweight sound-effect service beside `SpeechService`
- `Persistence/TelemetryWriter.swift`
  - record match-stage interaction and summary fields

## Non-Goals
- freeform open-canvas dragging
- tiny or precision-only drop targets
- detached points/leaderboard scoring
- story-heavy interstitials that interrupt the math action

## References
- [Math App Vision](Research-Math-App-Vision)
- [Playful Themes for VS1](Research-Playful-Themes-for-VS1)
- [VS1 Make & Break to 10](../Specs/VS1-Make-and-Break-to-10.md)
