# Research: Playful Themes for VS1

**Issue**: ganesh47/mather#79
**Status**: Completed
**Date**: 2026-04-04

## Question
How should Mather add playful, reusable child themes to VS1, starting with a Vehicle theme, without weakening the current CPA learning loop or destabilizing the already-complete VS1 milestone?

## Context
- [Issue #10](https://github.com/ganesh47/mather/issues/10) marks VS1 "Make & Break to 10" as complete as of 2026-04-03. This work is therefore a follow-on research track, not a reopen of unfinished VS1 scope.
- The current app already has strong child-friendly colour work and direct-manipulation improvements, but the core concrete/pictorial representations are still mostly circles, buckets, and counters.
- Recent UX feedback issues reinforce the need to keep child interaction direct, tactile, and visually obvious:
  - [#62](https://github.com/ganesh47/mather/issues/62) and [#75](https://github.com/ganesh47/mather/issues/75): transfer should be direct manipulation, not detached stepper controls.
  - [#64](https://github.com/ganesh47/mather/issues/64) and [#74](https://github.com/ganesh47/mather/issues/74): child attention should be drawn back to the math relation, not just the tapped object.
  - [#63](https://github.com/ganesh47/mather/issues/63) and [#76](https://github.com/ganesh47/mather/issues/76): compactness and visual calm matter on smaller screens.

## Repo Audit: What Is Generic vs Hard-Coded

### Generic enough already
- `Domain/SliceModels.swift`
  - `SliceProblem`, `SliceConfig`, and `ProblemState` do not assume circles or vehicles.
- `Domain/ProblemGenerator.swift`
  - Generates number targets and decompositions; no visual coupling.
- Core CPA state flow
  - `SliceStage` and `SliceStateMachine` model the learning progression, not a specific art theme.

### Currently hard-coded to circle/counter language or visuals
- `Features/VerticalSlice1/ConcreteBuildView.swift`
  - Fixed 2x5 grid of circular counters.
  - Prompt copy is "Make" and the fallback hint says "tap the circles."
- `Features/VerticalSlice1/SplitView.swift`
  - Pictorial stage still renders rows of dots inside two buckets.
- `Features/VerticalSlice1/TransferCheckView.swift`
  - Uses circles to rebuild the whole from the equation.
- `Domain/VerticalSliceEngine.swift`
  - Spoken prompts and retry hints reference "counters" and "circles."
  - Parent digest remains objective-level only; no theme context is recorded.
- `Persistence/TelemetryWriter.swift`
  - Telemetry schema has no theme identifier or scene metadata.
- `Shared/MatherTheme.swift`
  - Central palette exists, but it is a global app palette, not a content-theme system.

## Prior Research Synthesis
- [Math App Vision](https://github.com/ganesh47/mather/wiki/Research-Math-App-Vision) already established the non-negotiables:
  - conceptual-first, fluency-second
  - play-based learning
  - CPA progression for each new concept
  - no mandatory reading in the child flow
  - touch-first interaction with calm, meaningful feedback
- The existing VS1 spec already encodes several constraints that theming must preserve:
  - touch targets at least 80x80 pt
  - direct manipulation in the child flow
  - spoken instructions before reading-dependent UI
  - concrete -> pictorial -> abstract coherence

## External Findings

### 1) Themeing helps only when quantity stays visually transparent
- The U.S. Institute of Education Sciences early-math practice guide recommends a developmental progression from subitizing small groups to counting, comparison, and basic operations, rather than hiding quantity inside decorative surfaces.
- The Education Endowment Foundation guidance on manipulatives stresses that manipulatives work best when they are chosen deliberately to reveal the mathematical structure, not when they become decorative distractions.
- Practical implication for Mather:
  - a "car" can replace a counter only if the child can still immediately perceive "how many" and "how the whole is structured"
  - the 2x5 pattern remains pedagogically valuable because it supports subitizing and "5 + some more" recognition

### 2) Open map play is engaging, but freeform drag adds cost for 5-year-olds
- Apple’s platform guidance continues to anchor touch interaction around generous hit regions and direct manipulation. Mather’s stricter 80x80 pt rule is still the right child-specific standard.
- Research on tablet interaction for young children consistently warns about precision drag demands, hand occlusion, and visually overloaded tasks. Direct tap, snap, and constrained placement outperform open-ended precision movement for this age band.
- Practical implication for Mather:
  - a vehicle theme should prefer snap-to-bay parking, tap-to-place, or short constrained drags
  - an open parking-lot map with many possible positions is much riskier than a structured "parking frame"

### 3) Story context can raise motivation, but should not interrupt the math
- Prior Mather research already pointed to the DragonBox pattern: math should be the play, not a quiz interrupting a story wrapper.
- Khan Academy Kids’ creative tooling shows that children respond well to movable themed objects, but that mode is open-ended creation, not tightly scaffolded concept instruction.
- Practical implication for Mather:
  - the theme should give the counters a playful identity and scene, but the math action must remain central and immediately legible
  - narration should stay short and action-led: "Park 7 vehicles" is fine; a story script is not needed inside VS1

### 4) Asset sourcing should bias toward provenance simplicity
- For a private family app, the lowest-risk asset path is still in-house vector/SwiftUI art or AI-generated assets with a provenance note.
- If third-party assets are used, licensing must be explicit and traceable. Creative Commons attribution requirements and marketplace-specific license terms vary.
- Practical implication for Mather:
  - prefer simple original vector shapes and scene pieces first
  - if using external icon/vehicle sets, record source URL, license, author, and any attribution obligations in the wiki

## Product Benchmarks

### DragonBox Numbers
- Strong fit with Mather’s philosophy because the objects themselves are the math model, not decoration layered on top.
- Takeaway: make the themed object feel like the quantity, not merely like a sticker placed after the math is done.

### Khan Academy Kids
- Strong use of characters, stickers, and open-ended creation keeps engagement high.
- Takeaway: playful identity and movable objects help motivation, but free-create mechanics should not replace the structured CPA loop.

### Numberblocks-style visual identity
- Strong recognition comes from repeated, consistent visual structure tied to number meaning.
- Takeaway: Mather should keep a stable mathematical frame underneath any theme so the child learns the pattern, not a one-off scene gimmick.

## Options Evaluated

### Option A: Visual Theme Skin Over Current VS1 Loop
Replace circles/counters with themed objects and scene framing, while preserving the current interaction structure and 2x5 quantity layout.

Example Vehicle implementation:
- concrete = a 2x5 parking frame with vehicles parked into marked bays
- pictorial = two parking zones / garages showing the split
- abstract = unchanged equation stage, with light vehicle-themed framing only
- transfer = rebuild the parking frame from the equation

Strengths:
- lowest engineering risk
- preserves current CPA and subitizing behavior
- easiest path to a reusable theme framework
- compatible with current iPhone/iPad layouts and recent UX learnings

Weaknesses:
- less "wow" than a freeform map
- can feel cosmetic if the theme does not reach prompts, motion, and celebration

### Option B: Vehicle-First Parking-Lot Map Mechanic
Rework the concrete phase around a small parking-lot map where the child moves cars, SUVs, trucks, and construction vehicles into spaces or zones.

Potential implementation shape:
- concrete = move vehicles around a parking lot scene
- pictorial = split into two lots or work zones
- abstract = equation remains the same
- transfer = rebuild the lot from the equation

Strengths:
- richer play fantasy
- stronger thematic identity
- more room for differentiated object types and future missions

Weaknesses:
- highest motor and visual complexity
- much greater risk of obscuring quantity structure
- larger art burden and state-management burden
- likely requires new interaction rules, layout work, and telemetry/schema expansion

## Comparison

| Criterion | Option A: Structured Theme Skin | Option B: Parking-Lot Map Mechanic |
|---|---|---|
| Learning fidelity | High — keeps ten-frame/subitizing legible | Medium — depends on strong constraints to avoid losing quantity clarity |
| Implementation cost | Low to medium | High |
| Extensibility to more themes | High — easy to swap asset packs and vocabulary | Medium — each theme may want custom mechanics |
| Touch simplicity | High — tap and short snap interactions | Medium to low — drag and spatial placement become central |
| Art/content cost | Low to medium | High |
| Risk to current VS1 stability | Low | High |
| Milestone fit | Safe as follow-on polish/spec work | Needs a separate feature spec after research |

## Recommendation
Adopt **Option A as the first implementation path**, but design it as a **Vehicle-first theme framework**, not as a one-off art swap.

More specifically:
- Keep the mathematical structure fixed:
  - 2x5 parking frame for the whole
  - two clear parking zones for the split
  - abstract equation stage unchanged
  - transfer stage rebuilding the same structured frame
- Let Vehicle be the first content pack:
  - small car, SUV, truck, van, construction vehicle variants
  - distinct but count-equivalent silhouettes
  - parking-lot background, bays, road markings, celebration cues
- Defer the open/freeform parking-lot map mechanic to a later spec unless testing shows children need more fantasy play than the structured scene provides.

This recommendation keeps the most important thing true: the theme should make the math more inviting, not less visible.

## Decision
- **Decided in research**: use a reusable theme layer with **Vehicle as the first structured theme**.
- **Not decided for implementation yet**: whether to ship only a visual+vocabulary theme first or also include telemetry/config support in v1 of the theme framework.
- **Explicitly deferred**: freeform parking-lot map interaction as a separate post-research feature spec.

## Proposed Theme Contract
This is the minimum contract the future implementation/spec should evaluate.

| Field | Purpose |
|---|---|
| `id` | Stable theme identifier, e.g. `vehicle` |
| `displayName` | Parent-facing theme label |
| `concreteScene` | Whole-number scene definition, e.g. parking frame with 10 bays |
| `pictorialScene` | Split scene definition, e.g. two parking zones / garages |
| `tokenSet` | Renderable quantity items, e.g. cars/SUVs/trucks |
| `vocabulary` | Spoken/action verbs, e.g. park, move, rebuild |
| `palette` | Theme colours layered on top of `MatherTheme` accessibility constraints |
| `motionStyle` | Placement, success, and transition animation hooks |
| `celebrationStyle` | Theme-specific reward moment |
| `accessibilityRules` | Contrast, target sizing, and reading-free guardrails |

## Proposed Repo Touchpoints for a Future Spec

### Domain/config
- `SliceConfig`
  - candidate future field: `themeID`
- `SliceProblem`
  - likely unchanged unless a future theme needs scene metadata

### Engine and prompts
- `VerticalSliceEngine`
  - prompt generation should pull from theme vocabulary instead of hard-coded "counters" and "circles"
  - retry hints should stay mathematically clear even when nouns change

### Views
- `ConcreteBuildView`
  - replace `counterCell` with themed token slots
- `SplitView`
  - replace dot rows/buckets with themed split containers while keeping part-part-whole clarity
- `TransferCheckView`
  - themed whole-number reconstruction should stay direct-manipulation first
- `SliceSessionView`
  - theme-aware background accents and celebration treatment

### Telemetry and summaries
- `TelemetryWriter`
  - future schema candidate: add `theme_id` to `session_start` and possibly `problem_presented`
- `ParentDigest` / summaries
  - optional future inclusion of theme context for parent recall, not for pedagogy scoring

## Vehicle Theme Mapping

### Concrete: Make the whole
- Scene: a structured parking frame with 10 visible bays in a familiar lot.
- Action: tap or short-drag to park vehicles into bays.
- Quantity cue: full top row of 5 bays remains visually distinct from the second row.
- Object variety: randomize vehicle silhouettes/colors lightly, but every occupied bay still counts as exactly one.

### Pictorial: Break the whole
- Scene: two destination zones such as "left garage" and "right garage" or two parking sections.
- Action: move parked vehicles between the two sections.
- Quantity cue: both sides must remain quickly countable at a glance.

### Abstract: Write the equation
- Keep the current equation stage mostly unchanged.
- Theme contribution should be framing and vocabulary, not extra visual clutter.

### Transfer: Show it again
- Equation remains the prompt.
- Child rebuilds the structured parking frame from the equation using direct vehicle placement.
- Avoid "More/Less" style detached controls; recent repo issues already push in this direction.

## Future Theme Framework

### Good candidate themes after Vehicle
- **Animals on a farm**
  - strong child appeal, easy countable silhouettes, natural split into pens/barns
- **Dinosaurs in habitats**
  - high fantasy value, but must keep silhouettes simple
- **Space mission**
  - rockets/rovers in docking bays; strong visual identity, but risk of over-stylization
- **Construction site**
  - close cousin to Vehicle; useful if kept as a subtheme rather than a separate top-level theme

### Theme-selection rubric
- Quantity remains instantly visible at 0–10.
- Whole structure can map cleanly to a 2x5 or similarly constrained arrangement.
- Split state can be shown without extra explanation text.
- Tokens are visually distinct but not semantically unequal in value.
- Scene nouns and verbs are easy to speak and understand for a pre-reader.
- Assets can be sourced or created with clear provenance.

## Milestone-Fit Call

### Safe as follow-on VS1 polish / low-risk spec work
- theme vocabulary and scene framing
- structured vehicle token art
- parking-lot ten-frame reskin
- theme-aware celebration and subtle motion
- feature-flagged theme selection if it does not alter core problem logic

### Should be handled as a separate feature spec
- open/freeform parking map with multiple valid positions
- object classes with different gameplay behavior
- nontrivial telemetry schema expansion
- adaptive theme rotation or mastery-by-theme analytics
- theme-specific mechanics that alter CPA stage rules

## Risks
- Over-themed visuals could hide the whole/part structure and reduce subitizing.
- Mixed vehicle sizes could accidentally imply mixed numeric values unless every token is clearly "one."
- Open map drag could create frustration because of occlusion, precision demands, and unclear success states.
- Theme proliferation without a contract could hard-code each scene separately and create content debt.

## Follow-On Issue Map
- **Research issue**: document and socialize the recommendation.
- **Future spec issue**: "Vehicle theme framework for VS1 structured scenes."
- **Likely implementation slices**:
  - theme model + vocabulary abstraction
  - concrete vehicle parking frame
  - split/transfer scene reskins
  - asset provenance note and content pipeline

## Sources
- [Teaching Math to Young Children (IES / What Works Clearinghouse)](https://ies.ed.gov/ncee/wwc/Docs/practiceguide/early_math_pg_111313.pdf)
- [Using manipulatives and representations in mathematics (Education Endowment Foundation)](https://educationendowmentfoundation.org.uk/education-evidence/guidance-reports/maths-ks-2-3)
- [How to use creative tools inside the Khan Kids app](https://khankids.zendesk.com/hc/en-us/articles/21188738836763-How-to-use-creative-tools-inside-the-Khan-Kids-app)
- [What license can I use for my icons? (The Noun Project)](https://help.thenounproject.com/hc/en-us/articles/200584247-What-license-can-I-use-for-my-icons)
- [Creative Commons licenses overview](https://creativecommons.org/share-your-work/cclicenses/)
- [Math App Vision research](https://github.com/ganesh47/mather/wiki/Research-Math-App-Vision)
- [VS1 Make & Break to 10 spec](https://github.com/ganesh47/mather/blob/main/wiki/Specs/VS1-Make-and-Break-to-10.md)
