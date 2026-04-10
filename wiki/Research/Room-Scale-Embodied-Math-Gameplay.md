# Research: Room-Scale Embodied Math Gameplay for a Future Vertical Slice

**Issue**: ganesh47/mather#143
**Status**: Completed
**Date**: 2026-04-10

---

## Overview

This document evaluates whether Mather should pursue a future "Room Quest" vertical slice — an embodied, room-scale math activity for ages 4–6 set within an apartment. It builds on existing research in `Math-App-Vision.md` (§8), `VS1-Sensor-Finale.md`, and `ADR-0006-sensor-finale-stage.md`, extending from device-scale embodied play (tilt, shake, haptics) to whole-body locomotion play.

**Scope**: Apartment. iPhone 15 Pro and iPhone 16e. iOS 18. Ages 4–6. CPA-coherent. No LiDAR required for baseline.

**Recommendation (summary)**: **Conditional Go**. A baseline no-LiDAR room-scale mode is pedagogically justified, motorically safe, and apartment-practicable when properly constrained. The strongest candidate loop is **"Find & Group"**: parent seeds 2 numbered spot-cards in one room; child walks to each, counts the quantity, then returns to the iPad home base to complete Pictorial and Abstract stages on-screen. An enhanced LiDAR path is deferred pending pilot evidence.

---

## 1. Theoretical Foundation — Why Room-Scale?

### 1.1 Embodied Cognition Extended to Locomotion

The existing Mather research base (Math-App-Vision §8) documents that gesture and kinesthetic engagement improve math learning and recall in children (Goldin-Meadow, 2009; Ping & Goldin-Meadow, 2008). Device tilt and shake extend the "Concrete" phase of the CPA model beyond the screen surface. Room-scale movement takes this one step further: the child's entire body — locomotion, reaching, grasping — becomes part of the learning act.

Wilson (2002) identifies six views of embodied cognition. The one most relevant to room-scale play is the **"cognition is for acting"** view: mental representations are shaped by the motor and perceptual demands of real-world tasks. For early arithmetic, this means that walking *to* a quantity, picking it *up*, and carrying it *back* creates a richer sensorimotor representation of that number than tapping a counter on a screen alone.

Alibali & Nathan (2012) extend this to mathematics instruction specifically, showing that teachers who use representational gestures (pointing at objects, moving hands to simulate grouping) produce better student outcomes. When the child *is* the actor — moving through space to construct a quantity — the effect is stronger than when they observe it.

### 1.2 Spatial Reasoning and Number-Sense in Early Childhood

Verdine et al. (2014) found that spatial assembly skills at age 3 predicted mathematics achievement at age 5, even after controlling for general cognitive ability, vocabulary, and executive function. This link between spatial competence and numerical reasoning is one of the best-replicated findings in developmental psychology.

Room-scale play directly exercises spatial reasoning: the child must maintain a mental model of "I am going to spot 1 to get some, then to spot 2 to get more, then back to home". This is a navigation task layered on top of a counting task, which may strengthen the encoding of part-part-whole relationships more than a screen-only equivalent.

Clements & Sarama (2020) note that children develop number-line mental models earlier and more robustly when counting experiences involve physical movement and spatial layout, not just static symbol manipulation.

### 1.3 What Room-Scale Adds that Device-Scale Cannot

| Dimension | Device-scale (VS1/Bond Blast) | Room-scale (proposed) |
|---|---|---|
| Embodied action | Tap, tilt, shake | Walk, reach, carry, return |
| Body involvement | Wrists and fingers | Whole body; bilateral coordination |
| Spatial memory demand | Low — screen is always present | Medium — child must remember route and quantities |
| Social/parent engagement | Parent watches screen | Parent seeds spots; child moves; stronger joint attention |
| Narrative potential | Counter on iPad screen | "Go get 3 red tokens from the bookshelf" |
| Motivation for movement | Incidental (tilt = alive) | Intrinsic (moving IS the task) |

The key addition is **locomotion + spatial memory as a learning amplifier**. The child must encode the quantity at spot 1, hold it in working memory, then combine it with the quantity at spot 2 before returning. This is a richer concrete experience than counting tokens on a screen.

### 1.4 What Room-Scale Risks Losing vs. Device-Scale

Room-scale play introduces risks that screen-only play does not:

- **Math legibility**: Counters on a 2×5 grid make subitizing trivial. Physical tokens scattered across a room do not. The design must maintain quantity transparency.
- **Pace control**: The iPad controls pacing in VS1. A child roaming a room does not have a natural pace boundary — attention and momentum can scatter.
- **Failure isolation**: On-screen mismatches are isolated, quiet, and self-contained. Room-phase failures (wrong count, dropped items) involve physical recovery that can frustrate young children.
- **Safety**: The room introduces hazards that the screen does not.

These risks are manageable with proper constraints (see §7). They are not reasons to rule out room-scale play; they are reasons to design it carefully.

---

## 2. Math Concepts Best Suited to Room-Scale Play (Ages 4–6)

### 2.1 Part-Part-Whole / Number Bonds — Strong Fit

Physically collecting items from two spots and bringing them together is a bodily enactment of part-part-whole: "I have 3 from spot 1, I have 4 from spot 2, together that makes 7." This is exactly the number-bond concept VS1 teaches. Room-scale play can deepen the concrete phase of the same loop without requiring a new math concept.

**Verdict**: Strong fit. Primary candidate.

### 2.2 Counting and Cardinality — Strong Fit

Walking to a spot and counting items there (touching each one, saying the count aloud with the spoken prompt) is a canonical embodied counting act. Gelman & Gallistel's (1978) counting principles — one-to-one correspondence, stable-order, cardinality — are all naturally exercised by physically handling tokens at a distance.

**Verdict**: Strong fit. Directly serves number-bond activities.

### 2.3 Addition and Subtraction Stories — Medium Fit

"There are 6 cars. 2 drove away. How many are left?" could be staged as a room activity (6 tokens in a zone, child removes 2, returns with 4). But subtraction requires the child to think counterfactually ("there were more"), which is harder to ground spatially. At age 4–5, joining (addition) is more concrete than separating (subtraction) in spatial terms.

**Verdict**: Medium fit. Extend from number bonds once baseline is validated.

### 2.4 Comparison and Ordering — Weak Fit

Ordering quantities across a room introduces ambiguity: which spot has more? Which is first? Children at this age frequently confuse spatial proximity with quantity, especially across distances. Keeping comparison on-screen (where counters are aligned in the same frame) is safer.

**Verdict**: Weak fit. Keep on-screen.

### 2.5 Early Measurement — Defer

Length, area, and volume measurement require consistent units and comparison — concepts that are abstract even when handled concretely. A room-scale activity could involve stepping (informal measurement), but the pedagogical demands exceed VS1's scope.

**Verdict**: Defer to a future research strand.

### 2.6 Concept × Room-Scale Suitability Matrix

| Math Concept | Room-Scale Fit | Reason |
|---|---|---|
| Number bonds (part-part-whole) | **High** | Physical grouping is a natural enactment |
| Counting and cardinality | **High** | Touching/carrying objects grounds one-to-one |
| Addition (joining) stories | **Medium** | Embodied joining works; narrative overhead is higher |
| Subtraction (separating) | **Low** | Counterfactual reasoning harder to ground spatially |
| Comparison / ordering | **Low** | Spatial confusion likely across distances |
| Measurement (informal) | **Defer** | Concept exceeds VS1 scope |

---

## 3. Activity Loop Candidates

### 3.1 "Find & Group" — Recommended

**Shape**: Parent seeds 2 numbered spot-cards at safe locations in one room. The iPad announces the target number and sends the child to spot 1. The child picks up (or touches) the tokens at spot 1. The iPad then sends the child to spot 2 for the remainder. The child returns to the iPad home base. On return, SplitView on-screen already reflects the two groups — the child confirms the split, then completes the Abstract stage as normal.

**Why this works**:
- The two-spot structure directly produces a part-part-whole split — the primary VS1 concept
- Physical handling of tokens makes cardinality concrete (child counts as they pick up)
- Return to home base is a clear, child-friendly narrative ("bring it back to me")
- The on-screen Pictorial and Abstract stages are unchanged from VS1 — no new pedagogy needed
- Parent setup is minimal: 2 spot-cards + a set of physical tokens (coins, cubes, beads)

**Why "Find & Group" not "Find & Count"**: The child doesn't just count — they *group* (collect from two sources). This is the physical encoding of part-part-whole, not just cardinality. The naming matters for the pedagogical log too: telemetry can distinguish spot-visit events from simple count confirmations.

**Sequence**:
```
[Parent seeds spots]
 ↓
iPad: "Today we're making 7. Walk to the red dot and pick up some."
 ↓
Child walks to spot 1, picks up 3 tokens, spoken count prompt plays
 ↓
iPad: "Great. Now walk to the blue dot for the rest."
 ↓
Child walks to spot 2, picks up 4 tokens
 ↓
iPad: "Bring them back."  Child returns.
 ↓
[Pictorial: SplitView — groups 3 / 4 already filled]
 ↓
[Abstract: EquationResolveView — child types 3 + 4 = 7]
 ↓
[Optional Transfer: same as VS1]
 ↓
Session summary — room_quest metrics included
```

### 3.2 "Two-Zone Sort" — Backup

**Shape**: Two floor zones (marked with mat or tape) in one room. A set of tokens is placed centrally. The iPad announces a target number. The child picks up tokens one at a time and places them into either zone — left or right — as they count. When all tokens are sorted, the child confirms the split on the iPad.

**Why it works**: Sorting into zones is spatial grouping — a natural physical analog to SplitView. The zones can be colour-coded to match VS1's warm/accent palette.

**Why it's the backup**: The two-zone sort requires the child to make the split decision themselves (which zone?) during the room phase, before the on-screen confirmation. This introduces a metacognitive step that is appropriate for ages 6–7 but may overwhelm ages 4–5. "Find & Group" avoids this by seeding the split into the spot quantities in advance.

**Use case**: Two-Zone Sort may be the right mode for a slightly older cohort (age 6–7) once the baseline is validated.

### 3.3 "Treasure Hunt — Clue to Count" — Deferred

**Shape**: Audio clue leads child to a hidden spot; child finds and counts the hidden quantity; returns to iPad to enter the value.

**Why deferred**: Parent setup time is higher (hiding items + ensuring child can find them), clue design is a separate content problem, and incorrect counts require recovery choreography. This is compelling as a later mode but adds too many variables for a first pilot.

### 3.4 Rejected: Open Sandbox / Freeform Roaming

An open roaming mode with no fixed spots would mean the child picks up any items anywhere in any quantity. This makes the room-phase outcome unpredictable for the iPad and requires real-time quantity tracking (camera or manual parent input). The Playful-Themes research note (Issue #79) confirmed that freeform map mechanics obscure quantity structure for age 5 even on-screen. Room-scale freeform is strictly worse on both dimensions.

**Decision**: Exclude from all baseline designs.

---

## 4. CPA Mapping for the Recommended Loop

The CPA framework must be preserved end-to-end. Room-scale play must not bypass it.

| CPA Stage | VS1 Implementation | Room Quest Implementation |
|---|---|---|
| **Concrete** | Child taps counters on iPad screen to build target | Child physically walks to spots, handles physical tokens, returns to iPad |
| **Pictorial** | SplitView — coloured circles in two groups on-screen | SplitView — same view, but groups pre-populated from room-phase quantities |
| **Abstract** | EquationResolveView — child types the equation | EquationResolveView — identical; no change |
| **Transfer** | TransferCheckView — child rebuilds split from memory | TransferCheckView — identical; no change |

Room Quest adds a richer Concrete phase and hands off cleanly to the existing Pictorial/Abstract/Transfer chain. No new pedagogy is needed after the room phase ends. This is the key architectural insight: **Room Quest is a Concrete phase enhancement, not a replacement of the full CPA loop.**

The on-screen SplitView will receive the room-phase quantities from the engine (left_count from spot 1, right_count from spot 2) and pre-populate the split. The child sees their physical work reflected on screen immediately — this is the "return" moment that makes the concrete-to-pictorial transition legible.

---

## 5. Motor Suitability (Ages 4–6)

### 5.1 Room-Phase Interactions

| Interaction | Motor Demand | Suitable for Age 4? | Suitable for Age 6? |
|---|---|---|---|
| Walk to a spot 2–4 m away | Gross locomotion | Yes (age 2+) | Yes |
| Pick up a token (coin / cube) | Palmar grasp | Yes (age 3+) | Yes |
| Carry tokens back to iPad | Bilateral gross motor | Yes | Yes |
| Place tokens in a pile / bag | Gross placement | Yes | Yes |
| Touch a spot-card to confirm | Gross tap | Yes | Yes |
| Tap iPad screen at home base | 80×80 pt targets | Yes (VS1 validated) | Yes |

All room-phase interactions require only gross motor ability — palmar grasp, walking, carrying. No pincer grip, no precision alignment, no fine motor demand in the room phase.

### 5.2 Age-Specific Considerations

**Age 4**: Walking pace is slower; attention can drift mid-route; holding a small quantity of tokens may challenge working memory. The "Find & Group" loop mitigates this by keeping the two-spot route short (≤4 m each), using audio prompts at each step, and capping the token quantity at ≤5 per spot (total ≤10, matching VS1 target range).

**Age 5**: The target cohort. Walking to two spots and returning is within comfortable executive-function and motor capacity. Spoken prompts at each step remove any reading or planning burden.

**Age 6**: Comfortable with the entire room-phase loop. Two-Zone Sort may be appropriate as an extension.

### 5.3 Items Not Suitable

- Precision item placement (align tokens in an exact grid in the room) — too fine motor
- Running between spots — safety risk; no game mechanic should incentivise speed
- Balancing or stacking tokens at the spot — unnecessary motor demand

---

## 6. Sensor and Input Analysis

### 6.1 No New Sensors Required for Baseline Mode

The baseline "Find & Group" loop does not require any sensor that VS1 does not already use:

- **CMMotionManager** (tilt/shake): already in `MotionService.swift`. Could provide background motion feedback during room phase (e.g., slight haptic when child returns to home base), but not required.
- **SpeechService** (AVSpeechSynthesizer): already in place. Required — all room-phase prompts are spoken.
- **HapticsService** (CHHapticEngine): already in place. Optional confirmation haptic on iPad touch at home base.

No new `import` statements, no new frameworks, no new permissions for baseline.

### 6.2 What CMMotionManager Could Add (Step Counting) — Deferred

`CMPedometer` (CoreMotion) can estimate step count without any permission. This could be used to confirm the child has walked a certain distance before the iPad advances the prompt. However, step counting introduces latency and failure modes (child standing still, child being carried). For a first pilot, the simpler approach is parent-confirmable: the parent taps a "ready" button when the child has returned to home base.

**Decision**: Defer step counting to a second iteration if pilots show children skip the room phase.

### 6.3 ARKit / LiDAR — Excluded

LiDAR is not present on iPhone 16e (confirmed: Apple iPhone 16e specifications). Full `ARWorldTrackingConfiguration` would:
- Restrict the mode to iPhone 15 Pro only
- Add motion-sickness risk for children (Munafo et al., 2017 — VR/AR headsets induce motion sickness at measurable rates; handheld AR exhibits the same visually-induced effects at lower intensity but still relevant for 4–6 year olds)
- Obscure physical tokens with virtual overlays, potentially weakening math legibility
- Require `NSCameraUsageDescription` and add the orange dot indicator during sessions

No pedagogical benefit justifies these costs for number bonds to 10. LiDAR anchors are considered in the enhanced path (see §9) but gated on pilot evidence.

### 6.4 Camera (AVCaptureDevice) — Excluded

Same reasoning as ADR-0006: camera access triggers an orange indicator dot, raises safeguarding concerns for a child-facing family app, and is not needed for baseline quantity tracking. All quantity confirmation is done by the child manually (touching spot-card, returning to iPad).

### 6.5 UWB / Ultra-Wideband Positioning — Not Useful at Room Scale

iPhone 15 Pro and 16e both have UWB (U2 chip). UWB enables precision relative positioning (±10 cm) — used by AirDrop direction finding and Find My precision. However:
- UWB peer-to-peer ranging requires two UWB-capable devices within ~30 m
- A second device (AirTag, another iPhone) would need to be placed at each spot
- Setup complexity exceeds the 60-second parent budget
- Positioning precision is overkill for "is child at spot?" (a simple audio cue suffices)

**Decision**: UWB excluded from baseline. Could be revisited if the mode needs indoor navigation at larger scales (multi-room, not apartment-appropriate).

### 6.6 Parent-Seeded Physical Markers — The Right Approach

The baseline relies on **printable spot-cards** (numbered 1 and 2, colour-coded to match VS1's warm/accent palette) that the parent places at safe locations before the session. Each spot-card includes a simple sticker tab or QR-free visual the child can recognise. The spot quantities are set in the app by the parent during setup (e.g., "put 3 red tokens at spot 1, put 4 blue tokens at spot 2").

This approach:
- Requires zero sensors beyond what VS1 already uses
- Puts setup control in the parent's hands (safe-zone definition is implicit in where they place the cards)
- Makes the child's task unambiguous: "go to the red card, pick up everything there"
- Supports any physical token the family has: coins, cubes, beans, toy cars

---

## 7. Apartment Safety Constraints

Safety is a **non-negotiable design constraint**, not a feature to bolt on later. These constraints shape the activity loop, not just the UI.

### 7.1 Bounded Play Zone

- Maximum: one room at a time, or two immediately adjacent zones within sight of the iPad home base
- The iPad home base (table, floor mat) is the anchor — the child must always be able to return without turning a corner or leaving sight of the device
- No multi-room routing in baseline mode

### 7.2 No-Go Areas (Non-Negotiable)

The following areas must never be reachable from a spot-card without passing a safety decision:
- Balcony / window access
- Kitchen (stovetop, knives, hot surfaces)
- Stairs or elevated surfaces
- Hallways leading out of the designated room
- Charging cables or cables on floor

These constraints must be surfaced to the parent during setup — not enforced by the app (the app cannot know the room layout), but acknowledged via a simple one-time in-app safety checklist before the first room-quest session.

### 7.3 Anti-Patterns — Mechanics the App Must Not Incentivise

| Anti-pattern | Why it's dangerous | Design rule |
|---|---|---|
| Running between spots | Fall risk, collision | No speed-based reward; no countdown timer |
| Looking through iPad while walking | Collision risk | App silences/fades during room phase; no AR overlay |
| Walking backwards | Trip/fall | No mechanic that requires backwards movement |
| Jumping at spots | Fall risk | No height-related mechanics |
| Carrying many small tokens | Dropping, frustration | Maximum 5 tokens per spot (confirmed by VS1 target range ≤10) |

### 7.4 Session Length

- Room phase: hard cap of 4 minutes (two spot visits should complete in <2 minutes for a focused child)
- If the room phase timer expires, the iPad plays a "let's come back" prompt and offers a direct path to the on-screen stages with default values
- Total session: room phase (≤4 min) + on-screen CPA (same as VS1: ~3–5 min) = ≤9 min

### 7.5 Parent Setup Time

The 60-second setup budget is a design constraint:
- Parent opens the app → selects Room Quest → sees "Place spot 1 here with N tokens, spot 2 here with M tokens"
- Parent places 2 spot-cards + tokens → taps "Ready" in the app
- Child starts room phase

If setup reliably exceeds 90 seconds in pilot, the mode will not be adopted by families. Setup simplicity is a first-class acceptance criterion.

### 7.6 Stop/Pause/Reset

- **Immediate pause**: a large accessible button on the iPad home-base screen, always visible during room phase, no unlock required
- **Parent abort**: same large button; pressing it returns to the session summary immediately
- **Child return**: if child returns to iPad without completing room phase, the app detects touch and offers "finish on screen" — no progress is lost

---

## 8. Parent Setup and Control Requirements

### 8.1 Pre-Session Setup

1. Parent opens Settings → enables Room Quest (`roomQuestEnabled = true`)
2. Parent opens a new session → selects "Room Quest" mode
3. App shows: "Today's target is 7. Place 3 red tokens at spot 1. Place 4 blue tokens at spot 2."
   - Spot quantities are determined by the engine from the problem's decomposition (decompositionA at spot 1, decompositionB at spot 2)
   - Token colours match VS1's warm (left) and accent (right) palette
4. Parent places spot-cards in safe locations in one room, places tokens on each card
5. Parent taps "Ready" — app transitions to child-facing room-phase start screen

### 8.2 In-Session Presence

Room Quest is not a solo-child mode. The parent remains present or within sight during the room phase. This is not a design flaw — the VS1 research (App-Vision §4) notes that the most effective learning happens with parental joint attention. The room phase is a shared activity.

### 8.3 Override and Pause

As described in §7.6. The pause button is always on-screen during room phase, accessible without PIN or app unlock.

### 8.4 Safe-Zone Acknowledgement

Before the first Room Quest session ever, the parent sees a one-time safety checklist:
- "Spot cards are placed in a safe area away from stairs, windows, and the kitchen"
- "Your child can reach both spots and return to the iPad without crossing dangerous areas"
- "You will stay nearby during play"

Parent taps "Confirm" once per device. This acknowledgement is stored in `UserDefaults` (not gated by telemetry). It is shown again if the parent changes device or re-installs.

### 8.5 Setup-Time Gate

Pilot sessions will log `setup_time_ms` (time between "Start Room Quest" and "Ready" button tap). If median setup time exceeds 90 seconds across pilot sessions, the mode is not suitable for home use and the product direction should be reconsidered.

---

## 9. Baseline vs. Enhanced Comparison

| Dimension | Baseline (no LiDAR) | Enhanced (LiDAR, future) |
|---|---|---|
| Hardware | iPhone 15 Pro & 16e | iPhone 15 Pro only |
| Physical tokens | Required (coins, cubes) | Optional (AR virtual items) |
| Parent setup | Spot-cards + tokens (~60s) | Virtual anchor placement (~2 min) |
| Child instruction delivery | Audio-only; simple | Audio + AR overlay |
| Math legibility | High (physical tokens) | Medium (AR items may occlude physical view) |
| Motion-sickness risk | None | Low–medium (Munafo 2017) |
| New permissions | None | `NSCameraUsageDescription` |
| New framework | None | ARKit + RealityKit |
| LiDAR availability | Both devices | iPhone 15 Pro only |
| Pilot gate | Open now | After ≥3 successful baseline pilots |
| Recommendation | **Pilot now** | **Defer** |

The enhanced LiDAR path is architecturally plausible (RoomQuestEngine could accept an optional `ARSession` dependency injected at construction) but the pedagogical and safety case for AR overlay during room play has not been established for ages 4–6. The baseline must succeed first.

---

## 10. Architecture Fit (Repo-Informed)

### 10.1 Should NOT Extend VerticalSliceEngine

`VerticalSliceEngine` is a tightly-coupled `@MainActor final class` that manages a specific CPA loop for VS1: `SliceStage` state, `BondMatchState`, `ProblemGenerator` output, haptic events, speech prompts, and session telemetry. Extending it to support a room-phase pre-cursor would require:
- Adding room-specific state (`spotQuantities`, `roomPhaseCompleted`, `currentSpotIndex`)
- Adding new stage cases to `SliceStage` that don't fit the Pictorial/Abstract domain
- Mixing VS1-specific prompt logic with room-phase prompt logic

This would destabilise VS1 — one of the best-tested parts of the codebase — and violate the principle that VS1 remains unchanged after Bond Blast (ADR-0006 consequence).

### 10.2 Recommended Architecture: Sibling Engine and Sibling Route

```
App/
  AppModel.swift         ← add roomQuestEngine: RoomQuestEngine
  RootView.swift         ← add case .roomQuest to Route enum

Domain/
  RoomQuestEngine.swift  ← @MainActor final class (new)
                            mirrors VerticalSliceEngine structure:
                            @Observable, published state,
                            methods called by child views

Features/
  RoomQuest/
    RoomSessionView.swift   ← top-level coordinator view (new)
    SpotPromptView.swift    ← per-spot screen; audio prompt + confirm button (new)
    RoomSetupView.swift     ← parent setup: quantities, spot-card placement (new)
    RoomSummaryView.swift   ← post-session parent digest (new)

Shared/
  FeatureFlags.swift      ← add roomQuestEnabled: Bool (default false)

Persistence/
  TelemetryWriter.swift   ← add room_quest event schema (extend existing JSONL)
```

### 10.3 Shared Services (No Changes Required)

| Service | Shared As-Is | Reason |
|---|---|---|
| `SpeechService` | Yes | All room-phase prompts spoken via existing API |
| `HapticsService` | Yes | Confirmation haptics on return to home base |
| `MotionService` | Yes (optional) | Could provide ambient feedback; not required |
| `TelemetryWriter` | Extend | New event types only; schema-versioned |

### 10.4 Files Unchanged by Room Quest

- `Domain/VerticalSliceEngine.swift` — no changes
- `Domain/SliceStateMachine.swift` — no changes
- `Domain/SliceModels.swift` — no changes (SliceStage not modified)
- `Features/VerticalSlice1/*` — no changes
- `Domain/ProblemGenerator.swift` — no changes (RoomQuestEngine has its own problem source)

### 10.5 Feature Flag

```swift
// Shared/FeatureFlags.swift
var roomQuestEnabled: Bool  // default: false
```

Room Quest is invisible to users until this flag is enabled in Settings. The flag gates the route, not just a feature within VS1.

### 10.6 RoomQuestEngine Shape

```swift
@MainActor
@Observable
final class RoomQuestEngine {
    // Published state consumed by SwiftUI views
    private(set) var phase: RoomPhase = .setup   // .setup, .spot(index), .returning, .onScreen, .complete
    private(set) var targetNumber: Int = 0
    private(set) var spotQuantities: [Int] = []   // [decompositionA, decompositionB]
    private(set) var collectedQuantities: [Int] = []
    private(set) var setupTimeMs: Int = 0

    // Forwarded to VS1 views after room phase
    var splitLeftCount: Int { collectedQuantities.first ?? 0 }
    var splitRightCount: Int { collectedQuantities.last ?? 0 }

    func startSetup() { ... }
    func confirmSetup() { ... }      // parent taps "Ready"
    func confirmSpot(_ index: Int) { ... }  // child returns from spot
    func startOnScreenPhase() { ... }
    func completeSession() { ... }
}
```

---

## 11. Telemetry and Product-Learning Plan

### 11.1 Engagement vs. Novelty — How to Tell the Difference

The central product-learning question is: does room-scale movement improve **learning transfer** (can the child do the on-screen abstract stage faster/more accurately after a room phase?) or just **session engagement** (does the child seem more excited)?

Novelty produces a high first-session effect that decays. Learning transfer produces a flat or growing effect across sessions. Telemetry must be able to distinguish these.

**Signal for learning transfer**: `abstract_stage_first_attempt_accuracy` in sessions with room phase vs. sessions without (within-child comparison across sessions).

**Signal for engagement only**: High room-phase completion rate in session 1, declining in sessions 3–5.

### 11.2 Proposed Telemetry Events

All events follow the existing JSONL schema in `TelemetryWriter.swift` with `schema_version` bump:

```jsonl
{"type":"room_quest_started","sessionId":"...","targetNumber":7,"spotQuantities":[3,4],"ts":...}
{"type":"room_quest_setup_complete","setupTimeMs":42000,"ts":...}
{"type":"spot_visited","spotIndex":0,"quantityAtSpot":3,"ts":...}
{"type":"spot_visited","spotIndex":1,"quantityAtSpot":4,"ts":...}
{"type":"room_phase_complete","roomPhaseDurationMs":93000,"spotsVisited":2,"ts":...}
{"type":"room_phase_abandoned","reason":"timeout|parent_abort|child_return","ts":...}
{"type":"room_quest_completed","totalDurationMs":340000,"abstractAccuracy":1.0,"ts":...}
```

These are additive — existing VS1 event types are unchanged.

### 11.3 Parent Digest Additions

`ParentDigest` (already in the codebase) gains new optional fields:

```swift
struct RoomQuestDigest {
    let spotsVisited: Int
    let roomPhaseDurationMs: Int
    let setupTimeMs: Int
    let roomPhaseCompleted: Bool
}
```

Shown in `ParentSummaryView` alongside the existing VS1 summary when the session included a room phase.

### 11.4 Local-First Compatibility

All new events are JSONL-appended by `TelemetryWriter` with no network calls. The export path (share sheet) works unchanged. Schema versioning (`schema_version: 2`) is added to the session-start event header; parsers should tolerate unknown fields.

---

## 12. Recommendation and Next Steps

### 12.1 Verdict: Conditional Go

The research supports proceeding with a baseline "Find & Group" pilot. The theoretical grounding (embodied cognition, spatial reasoning → number sense, CPA extension) is strong. The motor suitability is confirmed for ages 4–6. The apartment-safety constraints are manageable. The architecture does not destabilise VS1.

**Condition**: The pilot gate is ≥3 successful family sessions (parent + child complete the room phase and on-screen phases) before an implementation ticket is opened for productionisation. Session success = room phase completes within 4 minutes and abstract stage completes on first attempt.

### 12.2 Recommended Baseline MVP: "Find & Group"

- Two spot-cards, seeded by parent before session
- Maximum 10 physical tokens total (matching VS1 target range)
- Audio-only room-phase prompts via SpeechService
- Hard 4-minute room-phase timer
- Returns to VS1-identical SplitView, EquationResolveView, TransferCheckView
- Telemetry as specified in §11

### 12.3 Backup: "Two-Zone Sort"

If "Find & Group" proves cognitively too easy for older children in the target range (age 6–7), "Two-Zone Sort" is the natural progression — it asks the child to decide the split, not just collect it.

### 12.4 Enhanced Path: LiDAR Anchors — Deferred

Gated on baseline pilot success. Opens as a separate research issue once ≥3 pilot sessions are logged. Hardware gate: iPhone 15 Pro only. The open question before the enhanced path is whether AR overlay during movement helps or harms math legibility for this age group — that question cannot be answered without baseline pilot data.

### 12.5 Next Steps

1. **This research** closes issue #143
2. Spec file: `wiki/Specs/Room-Quest-Future-Vertical-Slice.md` (produced alongside this document)
3. Pilot gate: run ≥3 family sessions using physical spot-cards and manual app logging
4. If gate met: open implementation issue for `RoomQuestEngine`, `RoomSessionView`, `SpotPromptView`, and telemetry extension
5. If gate not met: document why in a follow-up research note; Room Quest direction may be paused

---

## 13. References

- Alibali, M. W., & Nathan, M. J. (2012). Embodiment in mathematics teaching and learning: Evidence from learners' and teachers' gestures. *Journal of the Learning Sciences*, 21(2), 247–286.
- Clements, D. H., & Sarama, J. (2020). *Learning and teaching early math: The learning trajectories approach* (3rd ed.). Routledge.
- Gelman, R., & Gallistel, C. R. (1978). *The child's understanding of number*. Harvard University Press.
- Goldin-Meadow, S. (2009). How gesture promotes learning throughout childhood. *Child Development Perspectives*, 3(2), 106–111.
- Goldin-Meadow, S., & Beilock, S. L. (2010). Action's influence on thought: The case of gesture. *Perspectives on Psychological Science*, 5(6), 664–674.
- Munafo, J., Diedrick, M., & Stoffregen, T. A. (2017). The virtual reality head-mounted display Oculus Rift induces motion sickness and is sexist in its effects. *Experimental Brain Research*, 235, 889–901.
- Ping, R., & Goldin-Meadow, S. (2008). Hands in the air: Using ungrounded iconic gestures to teach children conservation of quantity. *Developmental Psychology*, 44(5), 1277–1287.
- Verdine, B. N., Golinkoff, R. M., Hirsh-Pasek, K., Newcombe, N. S., Filipowicz, A. T., & Chang, A. (2014). Deconstructing building blocks: Preschoolers' spatial assembly performance relates to early mathematical skills. *Child Development*, 85(3), 1062–1076.
- Wilson, M. (2002). Six views of embodied cognition. *Psychonomic Bulletin & Review*, 9(4), 625–636.
- Apple Developer Documentation: [Core Motion](https://developer.apple.com/documentation/coremotion), [ARKit](https://developer.apple.com/documentation/arkit), [AVFoundation](https://developer.apple.com/documentation/avfoundation)
- Apple Human Interface Guidelines: [Accessibility — Gestures](https://developer.apple.com/design/human-interface-guidelines/accessibility)
- iPhone 16e Technical Specifications: https://www.apple.com/iphone-16e/specs/ (LiDAR scanner: not present)
- Mather internal research: `wiki/Research/Math-App-Vision.md` (§8 Embodied Interaction)
- Mather internal research: `wiki/Research/VS1-Sensor-Finale.md`
- Mather internal decisions: `wiki/ADRs/ADR-0006-sensor-finale-stage.md`
- Mather internal research: `wiki/Research/Playful-Themes-for-VS1.md`
