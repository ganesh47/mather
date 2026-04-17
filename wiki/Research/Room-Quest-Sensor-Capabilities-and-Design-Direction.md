# Research: Room Quest Sensor Capabilities and Hardware-Tier Design

**Status**: Draft
**Date**: 2026-04-11
**Context**: follow-on research to `Room-Scale-Embodied-Math-Gameplay.md` after product direction changed from parent-seeded manual spots to a more device-driven, sensor-aware scavenger experience.

---

## Overview

This note revises the earlier Room Quest framing. The new product goal is **not** a purely manual room activity with parent-seeded physical cards. The goal is a **sensor-aware scavenger setup with the device**, using the best available hardware on each supported Apple device while degrading gracefully when higher-precision sensors are unavailable.

Key constraint: the app must stay **honest** about what it can actually sense. It should not pretend to know exact in-room coordinates when the device cannot reliably provide them.

The right design is therefore **tiered**:

1. **Marker + camera baseline** for broadest compatibility
2. **Motion/audio guidance enhancement** on all supported devices
3. **LiDAR-enhanced spatial anchoring** on hardware that actually has it
4. **No GPS/altitude-only room positioning**, because those primitives are too coarse or too noisy for child-trustworthy in-room play

---

## Hardware capability summary

### iPhone 15 Pro

Official / grounded capabilities relevant to Room Quest:
- **LiDAR scanner**: yes
- **ARKit plane / image detection**: yes
- **Barometer / relative altitude**: yes
- **Precision dual-frequency GNSS**: yes
- **Ultra Wideband (UWB)**: yes, second-generation
- **Accelerometer / gyroscope / magnetometer**: yes
- **Camera**: yes

Implication:
- iPhone 15 Pro is the only device in this target set that can support a strong **spatial-anchor enhanced mode** without pretending.
- It is still **not** a reason to use GPS for in-room position.

### iPhone 16e

Grounded capability read:
- **LiDAR scanner**: no
- **UWB**: no
- **Barometer**: yes
- **GNSS**: yes
- **Accelerometer / gyroscope / magnetometer**: yes
- **Camera**: yes

Implication:
- iPhone 16e can support a good **marker + motion + audio** Room Quest.
- It cannot support the same LiDAR anchor mode as iPhone 15 Pro.
- It should not be marketed as giving high-precision indoor positioning.

### iPad Air

Grounded capability read for current iPad Air family:
- **LiDAR scanner**: no
- **UWB**: not officially listed / not a dependable product assumption
- **Barometer**: yes
- **GNSS**: only on cellular variants; Wi‑Fi models use Wi‑Fi/iBeacon location, not true GPS
- **Accelerometer / gyroscope / compass**: yes
- **Camera**: yes
- **ARKit plane / image detection**: yes

Implication:
- iPad Air is suitable for **marker-based scavenger setup** and on-screen guided play.
- It should not be treated as a high-precision spatial anchor device.
- Large-screen UX may actually make marker scanning and child guidance easier than on phone.

---

## Why GPS and altitude are the wrong primary mechanic

### GPS / GNSS

Even strong phone GNSS is the wrong primitive for in-room play:
- indoor accuracy is too coarse
- signal quality is environment-dependent
- room-level differentiation is unreliable
- it creates a fake promise of precision the app cannot consistently keep

Conclusion:
- **Do not base Room Quest on GPS coordinates inside a room**.
- GPS may be useful only for coarse outdoors or neighborhood-scale gameplay, which is a different product.

### Barometer / relative altitude

Barometer data is useful for **coarse vertical change**, but not as a standalone room-position mechanic:
- Apple exposes relative altitude, not a guaranteed indoor “which spot are you at” signal
- readings are noisy enough that child-facing exactness would be dishonest
- useful for “did the user go upstairs/downstairs” style hints, not for “you found the blue station”

Conclusion:
- **Do not base Room Quest location on altitude changes alone**.
- Relative altitude can be a soft secondary signal at most.

---

## Why UWB is not the baseline answer

Nearby Interaction / UWB is powerful, but not the simple answer here.

Important constraint:
- Apple’s UWB peer ranging requires **another compatible peer or accessory** and token exchange
- that means another device or dedicated accessory at each station
- this is too much setup for a family math game baseline

Implication:
- even on iPhone 15 Pro, UWB is not a practical default Room Quest mechanic unless the product later introduces dedicated accessories
- iPhone 16e does not have UWB anyway

Conclusion:
- **Do not anchor the Room Quest spec around UWB** for now.

---

## Best-fit sensing stack by reliability

### Tier 1: camera markers + image detection (recommended baseline)

Use printed visual markers / spot cards that the device can detect with camera-based image recognition.

Why this is the best baseline:
- works on iPhone 15 Pro, iPhone 16e, and iPad Air
- honest and legible: “scan this marker” is understandable to parent and child
- avoids fake location precision
- enables magical moments without expensive hardware assumptions
- supports explicit station identity: red station, blue station, number station, shape station

Possible uses:
- station registration during setup
- child confirms arrival by scanning a marker
- marker unlocks next clue, sound, or count challenge
- marker can encode station type without QR-code ugliness if custom art is used

### Tier 2: motion + heading + step-like guidance (recommended enhancement)

Use device motion and orientation to create a “treasure hunt” feel without claiming exact coordinates.

Good uses:
- warmer/colder cues
- compass-like turn prompts
- “walk a little farther” hints
- step-count flavored progress, if reliable enough in testing
- celebratory motion interactions when station is reached

Bad uses:
- claiming exact distances in meters indoors
- claiming exact room coordinates

### Tier 3: LiDAR-enhanced anchor mode (recommended only for 15 Pro-class hardware)

On LiDAR devices, the app can offer a better setup and stronger AR anchoring:
- faster plane understanding
- more stable anchor placement
- better persistence of virtual station placement during a session
- richer “place the portal here” setup flow

But even here, the design should remain **marker-first or anchor-assisted**, not pure free-space coordinate magic.

Why:
- marker confirmation is still easier for children to understand
- AR drift still exists
- camera-up walking is a safety and comfort concern

Recommendation:
- use LiDAR to improve setup quality and anchor stability, not as the only station identity mechanism

---

## Recommended product direction

### Core principle

Room Quest should become a **device-guided scavenger experience** with hardware tiers:

- **Baseline on all supported devices**: printed markers + camera recognition + spoken guidance + motion/audio feedback
- **Enhanced on higher-end hardware**: more stable AR anchoring and richer spatial setup on LiDAR devices

### Honest capability framing

The product should say things like:
- “Scan the red station to start”
- “Find the blue marker”
- “The device will guide you”
- “Listen for hotter/colder clues”

It should **not** say things like:
- “The device knows your exact room location”
- “Walk to these coordinates”
- “Use GPS to find the station indoors”

---

## Spec implications

The prior Room Quest draft should be revised in these ways:

1. **Change baseline from fully parent-seeded manual spots to marker-assisted stations**
   - parent still places stations physically
   - but the device now participates in station discovery/confirmation

2. **Replace line-of-sight / same-room wording with device-guided setup language**
   - clearer and more magical
   - less misleading

3. **Add hardware-tier capability matrix**
   - iPhone 15 Pro: marker + motion/audio + LiDAR-enhanced setup
   - iPhone 16e: marker + motion/audio
   - iPad Air: marker + motion/audio, large-screen scan UX

4. **Explicitly reject GPS-first indoor design**
   - document why in the spec so it does not re-enter via vague “high precision” language

5. **Define fallback behavior clearly**
   - if marker tracking fails, child can still tap a large “I found it” confirmation
   - if motion cues are noisy, spoken prompts remain sufficient

---

## Proposed gameplay architecture

### Baseline loop

1. Parent places physical markers/stations in the room.
2. Device guides setup by asking parent to scan each station once.
3. Child gets first clue.
4. Child finds the station and scans / confirms it.
5. Device reveals the count or challenge for that station.
6. Child completes embodied count task.
7. Device guides to next station.
8. CPA handoff back to on-screen math.

### Enhanced LiDAR loop

1. Parent places station markers.
2. Device scans room and stabilizes virtual overlays near markers.
3. Child follows richer visual/audio guidance.
4. Marker scan still confirms arrival.
5. AR effects add delight, not core correctness.

This keeps the system robust: markers handle identity, LiDAR improves feel.

---

## Recommended next spec move

Write a new Room Quest spec that treats the feature as:

**“marker-guided embodied scavenger math with hardware-tier enhancements”**

not:
- manual parent-only room setup, and not
- GPS/altitude indoor positioning.

---

## Sources

- Apple iPhone 15 Pro technical specs: https://support.apple.com/en-us/111829
- Apple iPhone 16e specs / support pages: https://support.apple.com/en-us/122208 and Apple iPhone 16e specs pages
- Apple iPad Air specs: https://www.apple.com/ipad-air/specs/
- Apple Nearby Interaction documentation: https://developer.apple.com/documentation/nearbyinteraction
- Apple ARKit documentation: https://developer.apple.com/documentation/arkit
- Apple Core Motion altitude docs: https://developer.apple.com/documentation/coremotion/cmaltitudedata
