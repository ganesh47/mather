# Spec: Room Quest — Future Vertical Slice

**Issue**: ganesh47/mather#143
**Status**: Draft — pending pilot gate (≥3 successful family sessions)
**Date**: 2026-04-10
**Research base**: `wiki/Research/Room-Scale-Embodied-Math-Gameplay.md`

---

## Overview

Room Quest is a **companion slice** to VS1 ("Make & Break to 10"). It extends VS1's Concrete phase into physical room-scale play: the child walks to two parent-seeded spots in one room, collects physical tokens at each, and returns to the iPad to complete the Pictorial and Abstract stages as normal.

Room Quest is **not** a replacement for VS1. It is a separate route gated by a feature flag, routed by a sibling engine (`RoomQuestEngine`), and invisible to users until the parent enables it in Settings.

**Pilot gate**: This spec becomes an implementation ticket only after ≥3 successful family pilot sessions are logged. Until that gate is met, Room Quest is research/draft.

---

## User Stories

**Child**
- "I walk to the red dot and pick up some things, then to the blue dot, then bring them back."
- "I hear what to do — I don't need to read anything."

**Parent**
- "I put the spot cards down in under a minute and tap Ready."
- "I know where my child can and can't go — the app helps me set that."
- "If something goes wrong, I can stop it immediately."

**Product**
- "I can tell if room movement improves abstract-stage accuracy across sessions, not just novelty."

---

## Baseline MVP: "Find & Group" Loop

### Step-by-step sequence

```
[Pre-session: Parent Setup]
1. Parent opens Settings → enables Room Quest
2. Parent taps "Start Room Quest" → sees setup screen:
   "Today's target is 7. Place 3 red tokens at the red spot-card.
    Place 4 blue tokens at the blue spot-card."
3. Parent places 2 colour-coded spot-cards at safe locations in one room.
   Spot-card quantities determined by engine (decompositionA, decompositionB).
4. Parent taps "Ready".

[Room Phase]
5. iPad: "Let's make 7! Walk to the red dot and pick up everything there."
   [Child walks to spot 1, picks up 3 red tokens — spoken count prompt plays]
6. iPad: "Great — now walk to the blue dot."
   [Child walks to spot 2, picks up 4 blue tokens]
7. iPad: "Bring them all back to me!"
   [Child returns to iPad home base]
8. Parent taps "We're back" (or child taps large iPad button).

[On-Screen CPA — identical to VS1]
9. SplitView (Pictorial): groups 3 / 4 pre-populated from room-phase quantities.
   Child sees their physical work reflected on-screen immediately.
10. EquationResolveView (Abstract): child types 3 + 4 = 7.
11. TransferCheckView (Transfer, optional): same as VS1.
12. Session summary: parent digest includes room_quest metrics.
```

### Spot-card quantities

The engine selects `decompositionA` as spot 1 quantity, `decompositionB` as spot 2 quantity — the same decomposition used in VS1 for this problem. The parent setup screen shows the exact quantities to place at each spot. Physical tokens can be any countable objects the family has (coins, cubes, toy cars, beans).

---

## Acceptance Criteria

### Functional (future implementation ticket gate)
- [ ] Room phase completes in ≤ 4 minutes for a typical family session
- [ ] Child requires no reading during room phase
- [ ] Parent setup completes in ≤ 60 seconds (median across pilot sessions)
- [ ] Session resumable if child or parent pauses mid-room-phase
- [ ] SplitView and EquationResolveView play identically to VS1 after room phase
- [ ] No new runtime permissions required for baseline mode
- [ ] All child-facing instructions delivered by `SpeechService`; no on-screen text required during room phase
- [ ] Telemetry records `setup_time_ms`, `spots_visited`, `room_phase_duration_ms` per session
- [ ] Feature flag `roomQuestEnabled` is `false` by default; parent enables in Settings

### Safety (non-negotiable — must be designed in from day one)
- [ ] One-time parent safety acknowledgement shown before first Room Quest session
- [ ] Hard 4-minute room-phase timer with automatic "let's finish on screen" fallback
- [ ] Immediate pause button always visible during room phase; no unlock required
- [ ] No mechanic encourages running, jumping, backwards walking, or device use while moving
- [ ] App silences/fades during room phase — no AR overlay while child is walking

### UX / Experience
- [ ] Spot-card colour matches VS1 warm (left) / accent (right) palette
- [ ] All room-phase prompts are short, spoken, and action-led (≤8 words each)
- [ ] On return to iPad, child immediately sees their physical work on-screen (SplitView pre-populated)
- [ ] Parent sees `room_quest` section in parent digest after session

---

## Safety Guardrails (Non-Negotiable)

These are product-level constraints that cannot be relaxed in any implementation:

1. **One-room only**: Spot-cards must be placed within the same room as the iPad home base, within line of sight.
2. **No-go acknowledgement**: Before first session, parent confirms spot locations are away from stairs, windows, balcony, kitchen.
3. **Hard timer**: Room phase has a 4-minute cap. If exceeded, app transitions directly to on-screen phases with whatever quantities were collected.
4. **Instant pause**: Large accessible "Pause" button always on-screen during room phase. No confirmation required.
5. **No speed rewards**: Nothing in the game mechanic rewards the child for moving quickly.
6. **No device-while-moving**: iPad stays on its home-base surface during room phase. App audio bridges the gap.

---

## Out of Scope (Baseline)

- LiDAR, ARKit, camera, or any sensor beyond what VS1 already uses
- Automatic spot detection or computer-vision-based quantity counting
- Multiplayer or shared-session between two devices
- Outdoor, multi-room, or hallway play
- Target numbers beyond VS1 scope (>10)
- Timer-based pressure mechanics
- Leaderboard, stars economy, or inter-session scoring

---

## Architecture Sketch (for future implementation ticket)

### New files

```
Domain/
  RoomQuestEngine.swift          @MainActor final class
                                 — phase state machine (setup → spot(i) → returning → onScreen → complete)
                                 — spot quantities, room-phase timer, telemetry calls

Features/
  RoomQuest/
    RoomSetupView.swift          Parent setup screen: quantities, spot-card instructions, Ready button
    SpotPromptView.swift         Per-spot screen shown on iPad during room phase
                                 (large colour, spoken prompt, no child interaction required)
    RoomSessionView.swift        Top-level coordinator: routes between setup, spot prompts, on-screen phases
    RoomSummaryView.swift        Parent digest: room_quest metrics alongside VS1 digest
```

### Modified files

```
App/RootView.swift               Add .roomQuest to Route enum; route to RoomSessionView
App/AppModel.swift               Instantiate RoomQuestEngine; inject shared services
Shared/FeatureFlags.swift        Add roomQuestEnabled: Bool (default false)
Persistence/TelemetryWriter.swift  Add room_quest event types; bump schema_version
```

### Unchanged files

```
Domain/VerticalSliceEngine.swift    — no changes
Domain/SliceStateMachine.swift      — no changes
Domain/SliceModels.swift            — no changes (SliceStage not extended)
Features/VerticalSlice1/*           — no changes
Domain/ProblemGenerator.swift       — no changes
```

### RoomQuestEngine phase state

```swift
enum RoomPhase {
    case setup                  // parent placing spot-cards
    case spot(index: Int)       // child walking to spot i
    case returning              // child walking back to iPad
    case onScreen               // SplitView → EquationResolveView → Transfer
    case complete               // session done
}
```

### Services (shared, no new code)

| Service | Used For |
|---|---|
| `SpeechService` | All room-phase spoken prompts |
| `HapticsService` | Confirmation haptic on return to home base |
| `TelemetryWriter` | `room_quest_*` events (new event types only) |

---

## Telemetry Events (for TelemetryWriter extension)

```jsonl
{"type":"room_quest_started","sessionId":"...","targetNumber":7,"spotQuantities":[3,4],"ts":"..."}
{"type":"room_quest_setup_complete","setupTimeMs":42000,"ts":"..."}
{"type":"spot_visited","spotIndex":0,"quantityAtSpot":3,"ts":"..."}
{"type":"spot_visited","spotIndex":1,"quantityAtSpot":4,"ts":"..."}
{"type":"room_phase_complete","roomPhaseDurationMs":93000,"spotsVisited":2,"ts":"..."}
{"type":"room_phase_abandoned","reason":"timeout|parent_abort|child_return","ts":"..."}
{"type":"room_quest_completed","totalDurationMs":340000,"abstractFirstAttemptCorrect":true,"ts":"..."}
```

---

## Enhanced Path — LiDAR Anchors (Deferred)

**Condition for opening**: ≥3 successful baseline pilot sessions logged.

**What it adds**: Virtual spot anchors placed via `ARWorldTrackingConfiguration`. Parent walks to each location once and taps to drop a virtual anchor. Child navigates to AR waypoints shown on the iPad (held at hip height during walking — mitigating some motion-sickness risk vs. held at eye level).

**Hardware gate**: iPhone 15 Pro only (LiDAR required for `ARWorldTrackingConfiguration` with scene mesh). iPhone 16e is excluded from enhanced path.

**Open questions before implementation**:
- Does AR overlay during child movement help or harm math legibility for ages 4–6?
- Does the orange camera indicator (required for `AVCaptureDevice`) confuse or concern parents?
- Does holding the iPad at hip height while walking reduce motion-sickness risk to acceptable levels?
- Is 2-minute parent setup time (anchor placement) acceptable vs. 60-second baseline?

**Not planned** until pilot gate is met and these questions are answered by on-device observation.

---

## Pilot Gate Definition

Room Quest moves from Draft → Active implementation when **all three** of the following are met:

1. ≥3 family sessions completed (parent + child, child aged 4–6)
2. Room phase completed within 4 minutes in ≥2 of 3 sessions
3. Abstract stage first-attempt accuracy ≥ 70% across the 3 sessions (equivalent to or better than VS1 baseline)

If the gate is not met after 5 pilot attempts, the direction should be reviewed and this spec should be updated with findings.
