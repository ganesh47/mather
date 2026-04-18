# Spec: Physics & Geometry Mechanics — UX Design

**Issue**: ganesh47/mather#194
**Status**: Draft
**Date**: 2026-04-18
**Depends on**: `wiki/Research/Physics-Geometry-Sensor-Gameplay.md`

---

## Overview

This document specifies the complete UX for the 7 game mechanics proposed in the physics +
geometry research doc, plus a fix for the existing Gravity Split playability flaw. Each design
covers: initial state, gesture model, feedback loop, success condition, CPA stage mapping, a
structured critical review with mitigations, and a difficulty progression plan.

**No Swift code is prescribed here.** Each mechanic will get its own implementation spec issue
once sensor validation (§8) and the paper prototype review checklist (§9) are complete.

---

## Critical Foundation: Universal Tilt Fix

All existing and new tilt-driven mechanics share a common flaw that must be corrected before
any new mechanic ships.

### Root Cause — Absolute Tilt = Accidental Win

`VerticalSliceEngine.adjustGravitySplitByTilt` maps absolute device roll to a counter position:

```
fraction = 0.5 − clamped_roll / (π/4) × 0.5
leftCount = Int((target × fraction).rounded())
```

When the device is held naturally flat (`roll ≈ 0`), `fraction = 0.5`, so `leftCount = target/2`.
For any symmetric decomposition (6=3+3, 8=4+4, 10=5+5), picking up the device already solves the
puzzle on the first tilt sample. The current `lastGravitySplitCount` guard (lines ~333–339 in
`VerticalSliceEngine`) tries to mask this but fails when the child tilts away and returns to flat —
a perfectly normal holding pattern.

The same failure mode will occur in Angle Cannon and Symmetry Fold if the same absolute-tilt
mapping is copied.

### Fix — Three Changes

**A. Neutral-relative tilt**

On first tilt call after stage entry, record `neutralRoll = tiltRoll`. All subsequent calls
compute `deltaTilt = tiltRoll − neutralRoll`, then map `deltaTilt ∈ [−π/4, +π/4]` to the
full `[0…target]` range. The `lastGravitySplitCount` guard is removed entirely.

Effect: wherever the child naturally holds the device becomes the midpoint. The puzzle cannot
be accidentally solved by picking up the iPad.

**B. Non-answer starting position**

`GravitySplitState.init` sets `leftCount = target − 1` (not 0). The beam starts visibly
far-left (almost all weight on the left pan). For symmetric problems this is still obviously
wrong; combined with neutral-relative tilt the child must consciously tilt to reach the answer.

**C. "Hold steady — GO!" transition**

When the stage loads, the pans and counters are visible behind a soft translucent scrim.
A large play affordance (≥88pt) sits in the centre. Speech: "Hold the iPad steady… now TILT
to balance the pans!" On tap, `neutralRoll` is recorded, the scrim dismisses, and tilt updates
begin. No tilt is tracked before the child opts in.

---

## 1. Angle Cannon

**Concept**: Angle measurement embodied as cannon aim. No degree label until discovery.

**Ages**: 7–9

**Sensors**: CMMotionManager tilt (existing `MotionService`). Neutral-relative (see §0).

### 1.1 Screen Layout

Landscape (forced lock). Cannon silhouette at bottom-left, resting on ground, barrel pointing
up-right at the current tilt angle. A single large cartoon target (≥88×88pt) floats in the
upper portion of the screen. A FIRE button (`PrimaryActionButtonStyle`, ≥88pt) is fixed at
the bottom-right — reachable without changing the tilt. No degree number visible.

A dotted amber arc previews the trajectory in real time as the device tilts.

### 1.2 Gesture Model

After a "Ready — Aim!" scrim is dismissed (recording `neutralRoll`):
- Tilt right of neutral → barrel angle increases (higher arc).
- Tilt left of neutral → barrel angle decreases (shallower arc).
- Clamped to 10°–80° from horizontal (never 0° or 90°).
- Snap zones at 15°, 30°, 45°, 60°, 75° — barrel springs gently to each increment with a
  `counterSettle` haptic tick. Child can FEEL the angle steps.

On FIRE tap: the angle freezes at the moment of first touch contact. The tilt state is not
read during the tap gesture itself.

### 1.3 Feedback Loop

| Moment | Visual | Haptic | Speech |
|---|---|---|---|
| Tilt | Dotted arc sweeps in real time | `counterSettle` tick at each snap angle | — |
| Snap zone reached | Arc springs to snap position (0.12s spring) | `counterSettle` | — |
| FIRE tapped | Dotted arc freezes (thinner, lighter amber); ball animates along actual arc (0.6s) | `success` | — |
| Hit | Target explodes into particles; degree label fades in at arc apex | `bondMatchComplete` | "You hit it! You aimed at 45 degrees!" |
| Miss | Ball bounces, settles; both arcs stay visible showing gap | `failure` (soft) | "Almost! Try tilting a little left." |

Miss feedback never shows a degree number — the gap between arcs IS the visual teaching moment.
The child fires again immediately with no penalty.

### 1.4 CPA Mapping

| Stage | What happens |
|---|---|
| Concrete | Physical device tilt is the angle — body IS the cannon barrel |
| Pictorial | Dotted arc (prediction) and solid arc (actual) drawn on screen |
| Abstract | "45°" label fades in ONLY on hit, framed as discovery, not evaluation |

### 1.5 Critical Review

| Risk | Mitigation |
|---|---|
| Device flat at neutral = 45°; targets placed at 45° → accidental win | Neutral-relative tilt means flat = 0° delta. First target is always ≥15° offset from neutral. |
| Large iPad: small roll change = large barrel swing (over-sensitive) | Sensitivity scaled by `UIDevice.current.userInterfaceIdiom`. Snap zones also reduce micro-jitter. |
| Child tilts too far → drops device | Clamp to ±35° from neutral. Visual stop indicator (red arc endpoint) at clamp boundary. |
| FIRE button tap while holding tilt disturbs aim | Angle frozen at first touch contact of FIRE tap, before press animation plays. |
| Degree number feels like evaluation | Degree appears only on hit, phrased as discovery. Never shown on miss. |

### 1.6 Difficulty Progression

- **Level 1**: One large target (88pt), ±15° hit zone, positioned at neutral+15°.
- **Level 2**: Smaller target (66pt), ±10° zone, target position randomised within a range.
- **Level 3**: Multiple targets in colour sequence; snap increments removed (free aim).

---

## 2. Two-Finger Protractor

**Concept**: Child's spread fingers are the protractor rays. Body is the measurement tool.

**Ages**: 7–9

**Sensors**: Simultaneous multi-touch (`UITouch` tracking, no new API).

### 2.1 Screen Layout

Portrait. Upper 60% shows a real-world object with a visible angle — a door (floor-plan view),
open scissors, a slice of pizza, or a clock showing a specific time. A warm amber wedge arc
shows the target angle. Two large pulsing placement guides (≥66pt circles) indicate where to
place fingers: one fixed at the pivot, one draggable.

A ghost wedge (light grey, 20% opacity) shows the exact target angle at all times.

### 2.2 Gesture Model

Child places two fingers simultaneously. The angle is computed as the absolute angle between
the two `UITouch` positions relative to the on-screen pivot:

```
angle = abs(atan2(p2.y − pivot.y, p2.x − pivot.x)
           − atan2(p1.y − pivot.y, p1.x − pivot.x))
```

Snap zone: ±5° of target angle. Both left-open and right-open orientations accepted.
Standard pinch-to-zoom is disabled for this view; the two-finger gesture is consumed entirely
by the angle recogniser.

### 2.3 Feedback Loop

| Moment | Visual | Haptic | Speech |
|---|---|---|---|
| One finger down | Ghost hands animation descends toward second guide | — | "Put another finger down too!" (after 3s) |
| Two fingers down | Coloured wedge fills in real time between fingers | — | — |
| Within ±5° of target | Wedge snaps to target; glows (scale 1.02) | `cardSnapCorrect` | — |
| Exact match | Full sparkle animation; ghost wedge merges with filled wedge | `balanceLock` | "That's right! The door is open 90 degrees!" |
| Degree reveal | "90°" label fades in at arc midpoint | — | — |

### 2.4 CPA Mapping

| Stage | What happens |
|---|---|
| Concrete | Fingers spread to physically embody the angle rays |
| Pictorial | Coloured wedge + arc drawn between fingers in real time |
| Abstract | Degree number fades in at arc midpoint after correct placement |

### 2.5 Critical Review

| Risk | Mitigation |
|---|---|
| Simultaneous two-finger placement hard for age 7 | Large 66pt placement guides with pulsing animation. ±5° snap zone is forgiving. |
| One finger on screen → app appears frozen | Ghost two-finger animation. Speech prompt after 3s. |
| Accidental pinch-to-zoom | Standard pinch disabled for this view entirely. |
| Inverted orientation (mirror image) accepted? | Yes — both left-open and right-open orientations accepted as correct. |
| Angles < 20° too small for reliable finger placement | Minimum target angle: 20°. All puzzles use ≥20° angles. |

### 2.6 Difficulty Progression

- **Level 1**: Real-world context (door, clock); only 45°, 90°, 180° targets.
- **Level 2**: Abstract pivot (two lines, no real-world frame); multiples of 15°.
- **Level 3**: Verbal-only target ("Make a right angle!"); no visual ghost wedge.

---

## 3. Float Lab

**Concept**: Density and buoyancy intuition. Device altitude controls submersion depth.

**Ages**: 6–8

**Sensors**: `CMAltimeter` (barometer). 3-zone discrete model (not continuous). Validate first.

### 3.1 Screen Layout

Portrait. Full-screen animated tank (fish tank or ocean cross-section). Objects rest at the
tank bottom. Three zones delineated by dashed horizontal lines:
- **SURFACE** (top third) — object partially above water line, bobbing
- **FLOAT** (middle third) — object suspended mid-depth
- **SINK** (bottom third) — object rests on tank floor

A zone indicator (glowing border on current zone panel) shows the child's current altitude zone.
A "lift hand" animation pulses as an action hint.

### 3.2 Gesture Model

Altitude is mapped to 3 zones relative to `neutralAltitude` (recorded at session start):
- `altitude > neutralAltitude + 15cm` → SURFACE zone
- `altitude < neutralAltitude − 15cm` → SINK zone
- Otherwise → FLOAT zone

A 2-second rolling average smooths the altitude signal to suppress HVAC/pressure fluctuations.

Each puzzle object has one correct zone:
- Rock → SINK
- Rubber duck → SURFACE
- Cork/log → FLOAT

**Fallback**: If `CMAltimeter` is unavailable on a device, the altitude axis is replaced by a
vertical two-finger drag (slide up = rise, slide down = sink). Same 3-zone model, different input.

### 3.3 Feedback Loop

| Moment | Visual | Haptic | Speech |
|---|---|---|---|
| Altitude changes zone | Object animates to new depth (spring physics, 0.4s) | — | — |
| Object enters correct zone | Bubbles rise from object; zone border glows | `stageSuccess` | "It floats! Good job!" |
| Object in wrong zone for 8s | "Try lifting the iPad!" gentle animation | — | "Try lifting it up!" |
| All objects placed correctly | Full tank celebration; density numbers fade in | `bondMatchComplete` | "The rock has density 3, the duck is less than 1!" |

### 3.4 CPA Mapping

| Stage | What happens |
|---|---|
| Concrete | Lifting the physical device lifts the object — body force = water force |
| Pictorial | Buoyancy arrow overlay shows direction and relative magnitude |
| Abstract | Density numbers revealed after all objects correctly placed |

### 3.5 Critical Review

| Risk | Mitigation |
|---|---|
| HVAC pressure changes trigger spurious zone transitions | 2s rolling average + 3 discrete zones (not continuous) absorb small fluctuations |
| Child sits vs. stands → arm height changes neutral | Neutral recorded at session start. "Recalibrate" button resets neutral without restarting the puzzle. |
| Zone thresholds require uncomfortable arm positions | ±15cm from neutral is achievable by lifting or lowering the forearms naturally while seated. |
| iPad flat on desk → stuck in FLOAT zone | After 8s without altitude change: gentle animation + speech prompt. |
| Barometer absent / unreliable on specific device | Two-finger vertical drag fallback activates automatically. |

### 3.6 Difficulty Progression

- **Level 1**: One object, binary choice (SINK vs. SURFACE).
- **Level 2**: Three objects, three zones. Must sort all.
- **Level 3**: Two visually identical objects with different density numbers — density is a
  property, not just appearance.

---

## 4. Symmetry Fold

**Concept**: Bilateral symmetry — the tilt fold gesture IS the concrete act.

**Ages**: 5–7

**Sensors**: CMMotionManager roll (existing `MotionService`). Neutral-relative. Screen rotation LOCKED.

### 4.1 Screen Layout

Portrait, rotation locked. The screen is split by a dashed vertical centre line. Right half:
a colourful half-image (butterfly, flower, face). Left half: a dotted grey outline of the
mirror image. The dashed centre line pulses gently. A small animated arrow on the right side
shows: "tilt this way →" pointing left.

### 4.2 Gesture Model

After "Ready" scrim dismissed (recording `neutralRoll`):
- Tilt left beyond neutral → right-half image rotates around the Y axis (`rotation3DEffect`)
  simulating a page folding left.
- At 25° left tilt: image has "folded" 90° — fully overlaid on the left half.
- The dotted outline glows progressively brighter as the fold approaches 90° (proximity cue).
- At 90° fold: if the folded image matches the dotted outline → **snap success**.

The perspective transform is applied only to the content layer, not the UI chrome.

### 4.3 Feedback Loop

| Moment | Visual | Haptic | Speech |
|---|---|---|---|
| Tilt left | Right-half image rotates (perspective 3D fold). Left outline brightens. | `counterSlide` subtle rumble | — |
| Tilt right (wrong direction) | Outline pulses red briefly | — | "Tilt the other way!" |
| Near match (fold ≥ 80°) | Outline at full brightness, pulsing | `cardNearSnap` | — |
| Perfect fold | Outline fills with colour; full image revealed; sparkle | `balanceLock` | "You folded it perfectly! Both sides match — it's symmetric!" |
| Fold released (unfold) | Image rotates back to right half; outline returns to dotted grey | — | — |

### 4.4 CPA Mapping

| Stage | What happens |
|---|---|
| Concrete | Physical device tilt acts out the paper-fold gesture |
| Pictorial | 3D fold animation with shadow overlay shows reflection in action |
| Abstract | "Line of symmetry" label fades in on the centre line after success |

### 4.5 Critical Review

| Risk | Mitigation |
|---|---|
| 25° tilt points device toward child's face | Threshold is 25°, not 45°. Moderate tilt only. |
| `rotation3DEffect` distorts UI at high tilt | Transform applied to content layer only; UI chrome (labels, buttons) not transformed. |
| Wrong direction tilt (right instead of left) | Red pulse on outline + directional speech. Not a buzzer — a redirect. |
| iOS auto-rotation at 25° | Screen rotation explicitly locked in this view. |
| Level 1 asymmetric image has subtle variations that are hard to match exactly | Level 1 images are purely symmetric (no colour variation, bold outlines). Level 2 introduces colour. Level 3 has no dotted guide. |

### 4.6 Difficulty Progression

- **Level 1**: Bold geometric shapes; grey outline only (shape match).
- **Level 2**: Animals and faces; coloured outline (colour + shape match).
- **Level 3**: No outline — pure symmetry intuition from the half-image alone.
- **Extension**: Rotational symmetry (tilt in two axes to find axis that is NOT bilateral).

---

## 5. Rectangle Factory

**Concept**: Factor pairs as multiplicative area structure. No "×" symbol until discovery.

**Ages**: 7–9

**Sensors**: Touch drag (no new sensor). Shake-to-reset via existing `MotionService.shakeDetected`.

### 5.1 Screen Layout

Portrait. Upper strip: N dots arranged loosely in a random cluster (target count). Below: a
dot-grid canvas (auto-sized to show at least N dots in a 5-column grid). Overlaid on the canvas:
a resizable rectangle frame (amber 2pt border) with a single corner handle (≥44pt touch target
circle) at the bottom-right corner of the frame. The frame starts at 2×1 (not 1×1, since 1×N
would be immediately trivial).

A large count badge in the frame's interior shows how many dots are currently inside it.

### 5.2 Gesture Model

Drag the corner handle → frame grows/shrinks. The canvas snaps the frame to integer dimensions
automatically (sub-integer drags snap to the nearest integer boundary). The dot count inside
the frame is shown live as a large number badge:

- Badge colour: blue-tint (count < N), amber (count = N), red-tint (count > N).
- A valid rectangle requires: count = N AND the frame dimensions form a complete grid (no
  partial rows — i.e., frame width divides evenly into N with the given height).

On valid rectangle detected: frame snaps with spring animation, `cardSnapCorrect` haptic, row
and column labels fade in ("4 rows × 3 columns"), checkmark appears. The dots rearrange into
a clean array inside the frame.

### 5.3 Feedback Loop

| Moment | Visual | Haptic | Speech |
|---|---|---|---|
| Dragging near valid dimensions | Badge turns amber | `cardNearSnap` subtle | — |
| Valid rectangle snapped | Frame springs to exact size; dot array forms; labels appear | `cardSnapCorrect` | "4 rows and 3 columns! That's a rectangle with all 12 dots!" |
| Rectangle found — another exists | Found rectangle shrinks to thumbnail at bottom | — | "Can you find a different shape?" |
| All rectangles found (composite N) | Factor tree animation unfolds; "N = A × B" appears | `bondMatchComplete` | "You found all the rectangles for 12!" |
| Prime N (only 1×N possible) | Starburst on the only rectangle | `bondMatchComplete` | "7 can only make one rectangle — 7 is a PRIME number!" |
| Shake | Frame resets to 2×1; dots scatter back to random cluster | `failure` (soft) | "Let's try again!" |

### 5.4 CPA Mapping

| Stage | What happens |
|---|---|
| Concrete | Dragging the corner handle builds the rectangle — physical construction |
| Pictorial | Dot array inside frame shows rows × columns structure |
| Abstract | "4 × 3 = 12" equation label appears after rectangle is found |

### 5.5 Critical Review

| Risk | Mitigation |
|---|---|
| "Rectangle" word unknown to child | Use "neat box" in speech. Word "rectangle" avoided in first 3 levels. |
| Single corner handle too small to target | ≥44pt handle with a larger invisible hit area (80pt square). |
| 2×6 vs. 6×2 — same factor pair, different orientation | Accept both as ONE discovered fact. "Can you find a different shape?" only prompts for a genuinely different factor pair. |
| N=1: degenerate, not meaningful | Skip Rectangle Factory for N ≤ 3. |
| N=prime: child finds 1×N but doesn't understand why there's only one | After the first and only valid rectangle, starburst + speech: "That's the only one — 7 is prime!" |
| Large N (24, 36) produces very large grids | Canvas scrollable vertically. Max frame height = 12 rows. |

### 5.6 Difficulty Progression

- **Level 1**: N ∈ {4, 6, 9} — 2–3 valid rectangles, small grids.
- **Level 2**: N ∈ {12, 16, 18} — 4+ rectangles.
- **Level 3**: N ∈ {24, 36} — rich factor structure; factor tree animation unlocked.
- **Prime path**: Primes 5, 7, 11, 13 interspersed — creates the prime discovery moment.

---

## 6. Gravity Artist

**Concept**: Projectile arc as an explicit prediction experiment. The gap between prediction and
reality IS the learning moment (McCloskey 1983 naive-physics loop).

**Ages**: 8–10

**Sensors**: CMMotionManager tilt. Neutral-relative. No pinch-for-power (removed — see §6.5).

### 6.1 Screen Layout

Landscape. Cannon at bottom-left on a platform. A target (bucket / character, ≥88pt) at a
position that varies by level. POWER SELECTOR: three ball icons (small / medium / large) at
bottom-left below the cannon (≥80pt each). Default: medium.

A dotted arc (high-contrast: 2pt amber stroke + 1pt white inner) previews the trajectory at
current tilt and selected power in real time.

**PREDICT button** (`PrimaryActionButtonStyle`, bottom-centre): locks the prediction.
**FIRE button** (appears after PREDICT, same position): fires the ball.

### 6.2 Two-Phase Action Model

**Phase 1 — Predict:**
1. Child tilts to aim. Dotted arc previews trajectory.
2. Child taps PREDICT → dotted arc freezes on screen as their committed prediction.
3. FIRE button replaces PREDICT button.

**Phase 2 — Fire:**
1. Child taps FIRE → solid colored arc traces the actual path (0.8s animation).
2. Both arcs visible simultaneously: dotted (prediction) vs. solid (actual).
3. Hit: celebration + degree label. Miss: both arcs visible showing gap + speech.

**Simplified option (if two-phase feels too complex for age 8)**: Single FIRE button. On tap,
the prediction arc is shown for 0.5s, then the ball travels. This preserves the prediction
moment without a separate tap.

### 6.3 Feedback Loop

| Moment | Visual | Haptic | Speech |
|---|---|---|---|
| Tilt preview | Dotted arc sweeps | — | — |
| PREDICT tapped | Dotted arc freezes; FIRE button appears | `counterSettle` | "Good! Now fire!" |
| FIRE tapped | Solid arc traces actual path over dotted | `success` | — |
| Hit | Target explodes; degree label fades in at arc apex | `bondMatchComplete` | "You hit it! You aimed at 35 degrees!" |
| Miss | Ball bounces; both arcs stay 3s showing gap | — | "So close! See how the real path curved down faster?" |
| Prediction was accurate (arcs nearly overlap) | "Amazing prediction!" overlay | `bondMatchComplete` | "You predicted perfectly!" |

On miss, no degree number is shown. Focus is on the prediction-reality gap, not the angle value.

### 6.4 CPA Mapping

| Stage | What happens |
|---|---|
| Concrete | Device tilt commits a physical intuition; PREDICT tap locks it in |
| Pictorial | Both arcs on screen simultaneously — prediction vs. actual is the visual lesson |
| Abstract | Degree number appears only on hit; parabola formula deferred to age 10+ |

### 6.5 Critical Review

| Risk | Mitigation |
|---|---|
| Two taps (PREDICT + FIRE) too complex | Single-FIRE simplified mode available as fallback (arc shown 0.5s before ball travels) |
| Dotted arc invisible against complex backgrounds | High-contrast arc: 2pt amber stroke + 1pt white inner. Tested against light + dark backgrounds. |
| Child ignores power selector | Power is a PUZZLE CONSTRAINT: "Use the small ball for the near target." Levels designed so aim alone doesn't solve all puzzles. |
| Low-angle shots (< 15°) hit ground instantly → seems broken | Minimum angle: 15°. Ground clips arc naturally; ball bounces once and settles. |
| Replayability — same angle always hits same target | Target position randomised within a range per level. Same tilt doesn't always work. |

### 6.6 Difficulty Progression

- **Level 1**: One fixed target, medium power only. Aim practice.
- **Level 2**: Three targets at different heights; all three power levels required.
- **Level 3**: Moving target (slow oscillation). Must predict WHERE target will be at impact time.

---

## 7. Compass Angles

**Concept**: Angle as a physical turn. Cardinal directions as concrete 90°/45° angle instances.

**Ages**: 7–9

**Sensors**: `CMDeviceMotion.attitude.yaw` (gyroscope-based relative rotation). No magnetometer.
**Screen rotation LOCKED** (landscape fixed).

### 7.1 Critical Sensor Decision

Indoor magnetometers drift up to ±30° near metal furniture, electronics, and iPad Smart Covers
(which contain magnets). Absolute compass heading is therefore unreliable indoors.

**Solution**: Compass Angles uses RELATIVE yaw rotation only:
- At session start, record `referenceAttitude = motionManager.deviceMotion.attitude`.
- All subsequent angle = `currentAttitude.multiply(byInverseOf: referenceAttitude).yaw`.
- This cancels gyro drift and eliminates magnetometer dependence.
- The child's starting direction IS "North" for this session. This is pedagogically valid:
  the concept being taught is ANGLE AS A TURN, not geographic directions.

### 7.2 Screen Layout

Landscape, rotation locked. A large compass rose fills the upper 60% of the screen. The red
needle points to the child's current heading (session-relative). A BLUE DOT on the compass rose
marks the target heading. A dotted arc sweeps from the current needle position toward the target,
showing how far to rotate.

A "turn arrow" animation shows whether to rotate clockwise or counter-clockwise.

### 7.3 Gesture Model

Child rotates device horizontally (like turning a steering wheel on a table). The compass rose
counter-rotates on screen to keep the needle pointing to the current heading. Snap zone at target:
±10° tolerance. Both clockwise and counter-clockwise paths accepted (child may turn "the long
way" — 270° instead of 90° — and that's fine; they still arrive at the target).

### 7.4 Feedback Loop

| Moment | Visual | Haptic | Speech |
|---|---|---|---|
| Rotating | Compass rose turns; dotted arc shortens as target approaches | `counterSettle` at each 15° snap | — |
| Within ±10° of target | Blue dot turns gold, pulses | `cardNearSnap` | — |
| On target | Blue dot fully gold; swept arc highlighted | `balanceLock` | "You found East — that was a 90 degree turn!" |
| Degree reveal | "90°" label fades in at arc | — | — |

### 7.5 CPA Mapping

| Stage | What happens |
|---|---|
| Concrete | Physical body rotation of the device (or the child's body) embodies the angle/turn |
| Pictorial | Compass rose arc swept from start to target heading = the angle drawn |
| Abstract | Degree number fades in at arc after reaching target |

### 7.6 Critical Review

| Risk | Mitigation |
|---|---|
| iOS auto-rotation during horizontal device rotation | Screen rotation locked to landscape. Yaw axis valid regardless. |
| Child walks to face a different direction rather than rotating iPad | This is equivalent and acceptable — they ARE turning by the target angle. |
| Gyro drift over a long session | `CMAttitude.multiply(byInverseOf: referenceAttitude)` cancels accumulated drift continuously. |
| 180° turn requires child to physically rotate uncomfortably | Cap Level 1 at 90° turns only. 180° unlocked at Level 2 ("the full spin!" is celebrated). |
| Too similar to Room Quest | Compass Angles is TABLE-TOP only. No walking required or encouraged. Clearly differentiates. |

### 7.7 Difficulty Progression

- **Level 1**: 90° turns only (right = East, left = West, full turn = back to North).
- **Level 2**: 45° and 135° turns (NE, NW, SE, SW).
- **Level 3**: Any multiple of 15°. Degree targets announced verbally; no text shown.

---

## 8. Sensor Validation Plan

The following tests must pass before Float Lab (§3) and Compass Angles (§7) are specced
for implementation.

### 8.1 Barometer Stability (Float Lab prerequisite)

**Test**: Record `CMAltimeter.startRelativeAltitudeUpdates` for 5 continuous minutes in a
typical indoor environment: room with HVAC running, doors closed. Keep device stationary on a
desk. Log altitude delta every 500ms.

**Pass criteria**:
- < 1 spurious zone transition (crossing ±15cm threshold) per 2 minutes while device is still.
- Altitude signal returns to within ±5cm of baseline after 5 minutes idle.

**Fallback if fails**: Float Lab uses vertical two-finger drag instead of barometer.

### 8.2 Yaw Drift (Compass Angles prerequisite)

**Test**: Start `CMMotionManager.startDeviceMotionUpdates`. Record
`CMAttitude.multiply(byInverseOf: referenceAttitude).yaw` every 100ms for 5 minutes of normal
device handling (picked up, set down, slightly jostled). Target: no intentional rotation.

**Pass criteria**:
- < ±5° accumulated drift over 2 minutes of stationary holding.
- < ±10° over the full 5 minutes.

**Fallback if fails**: Compass Angles uses on-screen rotation (drag a compass needle) instead of
physical device rotation.

---

## 9. Paper Prototype Review Checklist

Before implementing any mechanic, sketch the initial state, gesture, and success state and
verify all items below:

| Check | Question | Must answer "YES" |
|---|---|---|
| First glance | Can the child tell WHAT TO DO in < 3s without reading? | Yes |
| First action | Is the first natural action the child will take the CORRECT first action? | Yes |
| Accidental win | Can the puzzle be solved accidentally at rest / on first touch? | No |
| CPA boundary | Is there a clear Concrete → Pictorial → Abstract stage progression? | Yes |
| Failure teach | Does the failure state teach rather than punish? | Yes |
| Touch targets | Are all interactive elements ≥ 80×80pt? | Yes |
| No reading | Are all instructions deliverable via speech alone? | Yes |
| Timer | Is there no forced countdown for ages < 8? | Yes |

---

## 10. Implementation Priority

| Priority | Mechanic | Reason |
|---|---|---|
| 1 (fix first) | **Gravity Split fix** | Existing stage is unplayable; 3 targeted engine/model changes; no new UI |
| 2 | **Symmetry Fold** | Uses existing MotionService tilt; targets youngest in audience (5–7); no new API |
| 3 | **Angle Cannon** | Extends MotionService tilt; strongest CPA mapping; first new mechanic |
| 4 | **Rectangle Factory** | Touch-only; no sensor; highest curriculum value (factors/primes) |
| 5 | **Two-Finger Protractor** | Multi-touch; no new API; requires age 7+ fine motor |
| 6 | **Gravity Artist** | Physics simulation needed (SpriteKit or Canvas); most complex view |
| 7 | **Compass Angles** | Relative yaw; validate drift test first |
| 8 | **Float Lab** | Barometer; validate stability test first; has sensor fallback |

Each mechanic = its own GitHub issue + `feat/<mechanic>` branch + feature flag (default `false`).
