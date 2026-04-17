# Spec: Room Quest — Sensor-Driven Scavenger Mode

**Status**: Draft
**Date**: 2026-04-11
**Supersedes direction in**: `Room-Quest-Future-Vertical-Slice.md` where the old baseline assumed a mostly manual parent-seeded physical-card flow
**Research base**:
- `wiki/Research/Room-Scale-Embodied-Math-Gameplay.md`
- `wiki/Research/Room-Quest-Sensor-Capabilities-and-Design-Direction.md`

---

## Overview

Room Quest should be redesigned as a **sensor-driven scavenger mode** that uses the best available device capabilities without pretending to have exact indoor positioning when it does not.

The product goal is:
- make setup and exploration feel magical and device-guided
- use higher-precision hardware when available
- still work well on lower-capability devices
- stay honest about what is being sensed

This means:
- **not GPS-first indoor gameplay**
- **not altitude-only room localization**
- **not a purely manual card-only baseline**
- **yes to marker-guided stations with camera recognition and motion/audio assistance**
- **yes to LiDAR-enhanced setup/anchoring on devices that actually support it**

---

## Product framing

Room Quest is a **device-guided embodied scavenger math mode**.

The child should feel:
- “the device is guiding me to the next station”
- “I found the station and unlocked the next clue”
- “my movement matters”

The parent should feel:
- “setup is simple and trustworthy”
- “the device is using visible, understandable signals”
- “the game still works even if advanced sensors are unavailable”

---

## Design principles

1. **Station identity must be explicit**
   - The app should know a station because it scanned a marker or confirmed a target, not because it guessed a room coordinate from noisy sensors.

2. **High-precision hardware enhances, but does not redefine, the loop**
   - LiDAR improves anchoring and delight on supported devices.
   - It should not be required for the core experience.

3. **No fake exactness**
   - Indoors, GPS and altitude are not reliable enough for child-trustworthy exact location claims.

4. **The app guides; the child still plays physically**
   - Movement should remain central.
   - The device should support and enrich the movement, not replace it with a pure screen task.

5. **Graceful degradation is a core requirement**
   - Same activity concept must work across iPhone 15 Pro, iPhone 16e, and iPad Air with capability-aware differences.

6. **Fallbacks are part of the primary design**
   - Scan failure, motion noise, lighting problems, or parent assist should not collapse the session.

---

## Hardware tiers

### Tier A: LiDAR-enhanced
**Devices**: iPhone 15 Pro-class hardware

Capabilities used:
- camera marker detection
- ARKit plane/image anchoring
- LiDAR-enhanced scene understanding
- motion / heading
- audio / haptics

What this unlocks:
- faster station registration during setup
- more stable anchored visual effects
- richer “portal” / “beacon” station presentation
- better confidence in placing virtual guidance near a real station

### Tier B: camera + motion baseline
**Devices**: iPhone 16e, iPad Air, and any non-LiDAR supported device

Capabilities used:
- camera marker detection
- motion / heading
- audio / haptics
- optional ARKit image detection without LiDAR-specific assumptions

What this supports:
- full marker-guided scavenger mode
- station scan confirmation
- motion/audio guidance
- simpler visual feedback than Tier A

### Explicit non-goals
- GPS-first room positioning
- UWB-dependent station finding
- altitude-defined station identity

---

## Capability matrix

| Capability | iPhone 15 Pro | iPhone 16e | iPad Air | Required for baseline? |
|---|---:|---:|---:|---:|
| Camera marker detection | Yes | Yes | Yes | Yes |
| Motion guidance | Yes | Yes | Yes | Yes |
| Spoken/audio cues | Yes | Yes | Yes | Yes |
| LiDAR-enhanced anchor stability | Yes | No | No | No |
| UWB peer ranging | Yes | No | Do not assume | No |
| GNSS/GPS | Yes | Yes | Cellular only | No |
| Barometric altitude | Yes | Yes | Yes | No |

---

## Core interaction model

### Setup
1. Parent chooses Room Quest.
2. App asks parent to place **physical station markers** in safe locations.
3. Parent scans each station once with the device.
4. App confirms station registration and associates each with a role:
   - red station
   - blue station
   - optional bonus station in future modes
5. App shows a compact “ready to hunt” summary.

### Play loop
1. App gives the child a clue or mission.
2. Child moves through the room with the device-guided flow.
3. On arrival, child scans or confirms the station.
4. App unlocks a count / collection / grouping challenge.
5. Child completes embodied math action.
6. App guides to the next station.
7. Session returns to on-screen CPA representation and abstraction.

---

## Recommended station mechanics

### Station format
Each station has:
- a printable visual marker with strong recognition contrast
- a child-facing identity, such as color + icon + friendly name
- enough visual uniqueness to prevent station confusion

Recommended station identities for MVP:
- **Red Rocket station**
- **Blue Bubble station**

This is better than “station 1 / station 2” because it is easier for 4–6 year olds to remember and easier to voice-prompt.

### Station registration
During setup:
- parent places the marker
- app asks parent to scan it once
- app stores a station record with:
  - role
  - marker identity
  - optional anchor transform
  - fallback label

### Station arrival confirmation
Primary confirmation:
- camera sees the station marker

Fallback confirmation:
- large “I found Red Rocket” button
- optional parent-assist confirmation path

The session must continue even when vision confirmation is flaky.

---

## MVP gameplay loops

### Loop A: Find and Count
**Goal**: simplest embodied baseline

1. Child gets clue to find a station.
2. Child scans/confirms station.
3. App says how many objects to count or tap at the station.
4. Child performs the count action.
5. App transitions to the next clue or back to on-screen representation.

Use when:
- earliest implementation
- lowest engineering risk
- validating the station-guided hunt feel

### Loop B: Find and Gather
**Goal**: better CPA continuity

1. Child finds Red Rocket station.
2. Child collects the first group.
3. Child finds Blue Bubble station.
4. Child collects the second group.
5. App returns to on-screen split/equation stage.

Use when:
- CPA connection to VS1 is the main priority
- physical grouping should map directly to part-part-whole

### Loop C: Find and Unlock
**Goal**: stronger scavenger fantasy

1. Child finds station.
2. Marker scan “unlocks” a challenge card or creature clue.
3. Child completes a tiny count/grouping interaction.
4. App reveals the next station.

Use when:
- delight is more important than shortest loop
- after Loop A proves robust

### Recommendation
Implementation order should be:
1. **Loop A**
2. **Loop B**
3. **Loop C**

This keeps first shipping risk low.

---

## Guidance systems

### Required guidance
- spoken prompts
- clear station color/identity
- large arrival confirmation state
- on-screen fallback if scan is hard

### Preferred guidance
- warmer/colder audio cue design
- heading / orientation hints where useful
- motion-reactive delight feedback

### Optional Tier A guidance
- anchored AR beacon or creature near the station
- visual trail or portal effect during setup and confirmation

---

## Sensor policy

### Camera / image detection
**Use** as the primary station confirmation mechanism.

Use cases:
- register station during setup
- confirm arrival during play
- unlock the next clue or count interaction

### Motion sensors
**Use** for approximate guidance and delight, not exact localization.

Use cases:
- turn/heading prompts
- device-reactive cues
- rough movement progress
- celebratory feedback

### LiDAR
**Use** only as an enhancement on supported hardware.

Use cases:
- stabilize station anchoring
- improve setup confidence
- support richer AR overlays

Do not require LiDAR for correctness.

### GPS / GNSS
**Do not use** for in-room station positioning.

Allowed use:
- none for baseline gameplay
- potentially future outdoor modes only

### Altitude / barometer
**Do not use** as the primary station-finding mechanic.

Allowed use:
- optional secondary hinting in future multi-floor research
- not part of the baseline Room Quest spec

### UWB
**Do not require** for this version.

Reason:
- needs peer/accessory ecosystem
- unavailable on some target devices
- too much setup complexity for family baseline use

---

## Functional requirements

- [ ] Room Quest works on iPhone 15 Pro, iPhone 16e, and iPad Air with capability-aware behavior.
- [ ] Parent can register stations by scanning markers during setup.
- [ ] Child can confirm a station by scanning or using a large fallback confirmation control.
- [ ] Core scavenger loop works without LiDAR.
- [ ] LiDAR-capable devices provide enhanced anchoring but not exclusive mechanics.
- [ ] Gameplay never claims exact indoor coordinates unless the system truly has a trustworthy basis.
- [ ] The post-room CPA handoff remains clear and pedagogically coherent.
- [ ] Station identity remains understandable even if camera confirmation temporarily fails.

---

## UX requirements

- [ ] Child language must describe what the device is actually doing.
- [ ] The app should say “scan the red marker” or “find the blue station”, not imply hidden GPS magic.
- [ ] Parent setup should stay within a realistic home-use budget.
- [ ] Failure modes must be soft: if scanning fails, the child can still continue without technical frustration.
- [ ] Sensor differences across hardware should improve polish, not fracture the game concept.
- [ ] Station names/icons must be memorable for pre-readers.

---

## Safety requirements

- [ ] No gameplay requires staring through the device while walking fast.
- [ ] No requirement for exact continuous camera-up navigation.
- [ ] Parent setup includes safe placement guidance.
- [ ] Fallback controls exist if camera or motion sensing is awkward in a real home.
- [ ] The device can be lowered between scan moments; core navigation must not require constant camera framing.

---

## Architecture direction

### New capability layer
Introduce a Room Quest capability model, for example:

```swift
struct RoomQuestCapabilities {
    let supportsMarkerDetection: Bool
    let supportsMotionGuidance: Bool
    let supportsLiDAREnhancement: Bool
    let supportsPrecisePeerRanging: Bool
}
```

This allows the engine/view layer to choose the best mode honestly.

### Suggested subsystems
- `RoomQuestEngine`
- `RoomQuestStationRegistry`
- `RoomQuestSensorCoordinator`
- `RoomQuestSetupView`
- `RoomQuestHuntView`
- `RoomQuestMarkerScannerView`
- `RoomQuestArrivalFallbackView`

### Important separation
Do not bake device-specific heuristics directly into gameplay copy.
Gameplay copy should express a stable child experience; capability selection should happen below that layer.

---

## Fallback logic

### If marker scan fails
- show large “I found the red station” fallback
- allow parent assist path
- keep the station visually identifiable by icon/color
- do not hard-fail the session

### If motion guidance is noisy
- keep spoken directional prompts simple
- remove warmer/colder precision language
- never present movement hints as exact measurements

### If LiDAR is absent
- use marker-confirmed stations with lighter visual effects
- preserve the same core loop and success criteria

### If lighting is poor
- use explicit prompt: “Move closer to the red marker”
- allow immediate fallback confirmation after a short retry window

---

## Rollout plan

### Phase 1: capability-aware scavenger skeleton
- marker registration
- station confirmation
- spoken prompts
- fallback confirmation path
- simplest loop: Find and Count

### Phase 2: CPA-connected embodied math
- Find and Gather loop
- explicit handoff back into on-screen split/equation flow
- telemetry for station success/fallback rate

### Phase 3: delight layer
- warmer/colder guidance
- station personality
- unlock animations
- optional small AR embellishments on all hardware

### Phase 4: LiDAR enhancement
- improved station anchoring on iPhone 15 Pro class
- richer beacon/portal visuals
- stronger setup flow for spatial continuity

---

## Suggested telemetry

```jsonl
{"type":"room_quest_started","deviceTier":"A|B","loop":"find_and_count","ts":"..."}
{"type":"room_station_registered","stationRole":"red","scanSucceeded":true,"ts":"..."}
{"type":"room_station_found","stationRole":"red","method":"scan|fallback|parent_assist","ts":"..."}
{"type":"room_guidance_hint_used","hintType":"audio_warmer|turn_prompt|none","ts":"..."}
{"type":"room_scan_failed","stationRole":"blue","lighting":"unknown","ts":"..."}
{"type":"room_quest_completed","loop":"find_and_count","usedFallback":true,"ts":"..."}
```

Important product-learning questions:
- how often does scan confirmation fail?
- how often do families need fallback confirmation?
- does LiDAR meaningfully improve success or just polish?

---

## Open questions

- [ ] Should the child carry the device during the hunt, or should the parent hold it for scan/checkpoint moments?
- [ ] What marker format balances reliability and kid-friendly aesthetics best?
- [ ] Is station arrival primarily scan-confirmed, or can some flows support touch-confirmed completion after audio clueing?
- [ ] How much AR is delightful before it becomes distracting or unsafe?
- [ ] Should iPad Air be a preferred family setup device because of its screen size, despite weaker high-end sensing than iPhone 15 Pro?

---

## Recommendation

Proceed with the next design stage as:

**Room Quest = marker-guided embodied scavenger math with hardware-tier enhancements**

Specifically:
- baseline around **camera markers + spoken guidance + motion/audio cues**
- enhance with **LiDAR-supported anchoring** on iPhone 15 Pro-class hardware
- explicitly reject **GPS/altitude indoor positioning** as the core mechanic
- ship against a phased rollout that starts with the simplest stable loop first

---

## References
- `wiki/Research/Room-Scale-Embodied-Math-Gameplay.md`
- `wiki/Research/Room-Quest-Sensor-Capabilities-and-Design-Direction.md`
- Apple Nearby Interaction docs
- Apple ARKit docs
- Apple device technical specs for iPhone 15 Pro, iPhone 16e, and iPad Air
