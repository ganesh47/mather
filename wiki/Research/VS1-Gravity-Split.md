# Research: VS1 Gravity Split — Tilt-Powered Balance Stage

**Issue**: (to be opened — see §8)
**Status**: Completed
**Date**: 2026-04-15

---

## Overview

This document researches and designs "Gravity Split" — a sensor-powered replacement
for the Transfer stage in VS1. The child physically tilts the device; simulated gravity
slides counters between two pans of a balance scale until the split matches the target
decomposition. A satisfying haptic "balance lock" fires when the equation is satisfied.

The hypothesis: the Transfer stage's +/− stepper buttons are the weakest sensory moment
in the CPA flow. The wiki for `TransferCheckView` explicitly flagged it for future
enhancement toward direct physical manipulation. This research answers whether a
tilt-driven balance mechanic is age-appropriate, pedagogically sound, and technically
feasible within the existing sensor infrastructure.

---

## 1. Pedagogy — Balance Scales and Part-Part-Whole Decomposition

### 1.1 Balance Scales Are an Established Manipulative for K-2

The balance/pan scale is one of the most widely researched physical manipulatives for
early number and equality instruction. Research from NSF-funded classroom studies of
Kindergarten through Grade 2 found:

> "The affordances of balance scales identified from observations of Kindergarten through
> second-grade students had largely to do with helping students (begin to) build
> appropriate conceptions of the equal sign and equations in a way that may have been
> more difficult to do had the only tools available been a written equation and a pencil."
> *(NSF PAR #10201368)*

This is directly relevant: a core misconception in ages 5–7 is that the equal sign means
"put the answer here" (an operational reading) rather than "both sides are the same
amount" (a relational reading). Physical balance scales — where the child can *see and feel*
two sides becoming equal — are the recommended intervention for this misconception. Mather
already displays live equations (ConcreteBuildView, EquationResolveView); Gravity Split
would make the child *cause* the balance, grounding the abstract `A + B = target` in
a kinesthetic act.

Developmental timeline from curriculum research (NAEYC, Kindergarten Cafe):
- **Age 5 (Kindergarten entry)**: children can compose and decompose numbers to 5–6 using
  concrete objects; pan balance work is appropriate and recommended.
- **Age 6 (K–1 transition)**: children extend to 10; "how many ways can you make 6?"
  activities are grade-level expectations.
- **Age 7 (Grade 1)**: decomposition to 20; balance metaphor strengthens the understanding
  of commutativity and compensation.

The target child (currently age 5) is at the lower end of balance-scale readiness.
The key design implication: the balance must show **discrete, countable** objects (circles,
counters) on each pan — NOT abstract colour fills or liquid — so that the child can
subitize and verify "yes, there are 3 here and 3 there."

### 1.2 Does Physically *Causing* a Split Improve Learning Transfer?

Goldin-Meadow (2009), cited in `VS1-Sensor-Finale.md`, established that children who
gesture while explaining maths problems are 50% more likely to transfer learning to new
problems. The critical mechanism is **embodied encoding**: the body creates an additional
memory trace alongside the symbolic one.

Gravity Split extends this to the Transfer stage: instead of using +/− buttons (visual
and fine-motor only), the child tilts the whole device. The tilt is a whole-arm,
postural-level action — larger in motor scope than a button tap, matching the
"bodily engagement creates stronger encoding" principle.

However, one critical finding from embodied cognition literature must be acknowledged
(see §1.3 risk below).

### 1.3 Key Risk: Continuous vs. Discrete Gesture Congruency

A systematic review of embodied learning on tablets (Abrahamson et al., PMC 5321706, 2017)
found a specific effect:

> "Students who did arithmetic with a tapping gesture performed better than those who did
> it with a sliding gesture... discrete math tasks benefit from discrete gestures like
> tapping, while continuous tasks (estimation, proportion) benefit from sliding motions."

Tilt is a *continuous* input. Counting and decomposition (the math in Transfer) are
*discrete* tasks. This is a direct tension: we are proposing a continuous sensor for a
discrete math problem.

**Mitigation design**: Gravity Split must make the experience feel discrete at the
mathematical level even while the input is continuous. The design resolves this with:

1. **Discrete snap-to-integer**: counters snap to whole number positions only. The tilt
   drives a smooth animation, but the mathematical state only changes in integer steps.
   The child never sees "2.7 counters" — only 2 or 3.
2. **Per-integer haptic ticks**: each time a counter crosses from one integer to the next,
   a distinct haptic fires (see §5). The *body* experiences discrete events even though
   the *hand* is making a continuous gesture.
3. **Tap fallback is always available**: tapping either pan nudges the count by ±1,
   exactly like Transfer's buttons. Children who struggle with tilt use tapping; children
   who love the physical sensation use tilt. Both lead to the same math.

This design makes the tilt a *modality of exploration* and the taps a *modality of
precision* — matching the two uses to their respective gesture types as the research
recommends.

---

## 2. Motor Suitability for Deliberate Tilt (Ages 5–7)

### 2.1 Postural Stability at Age 5

Research on postural control development (PMC 5816079; ScienceDirect postural dynamics
in 3– and 5-year-olds) shows:

- **Age 5** is a transitional period: children can maintain stable sitting/standing posture
  during simple tasks, but introducing a concurrent manipulation task (like tilting a
  device while tracking a screen) adds postural demand.
- "Seven-year-olds seem to go through a period of differentiated singularity in postural
  control" — meaning 5-year-olds have *less* postural stability under dual-task conditions
  than 7-year-olds.
- Postural control and eye-hand coordination are "functionally linked" and co-develop
  together.

**Implication**: a 5-year-old can tilt a device, but asking for precise angle maintenance
over 10–30 seconds may produce frustration. The design must make small tilts effective
(i.e., the full 0–target range maps to ±45° of tilt, not ±90°).

### 2.2 Bilateral Arm Coordination

Holding a tablet with two hands while tilting it left-right is a bilateral coordination
task. Research on bilateral coordination in 5-year-olds (PMC 4131166 on postural control
and manual dexterity) confirms that age-5 children can perform symmetric bilateral holds
with objects of tablet size (they carry books, trays, etc.). The tilt gesture (tilting a
flat tablet in the frontal plane) is essentially the same motor pattern as tilting a tray.

**Motor suitability verdict**: ✅ Age-appropriate with the caveat that the mapping
must require **no more than ±45° tilt** from neutral for full counter distribution.
A 45° tilt is a comfortable, easily achievable range that does not demand held precision —
the child just tilts toward the side they want more counters on.

### 2.3 Tilt Angle to Count Mapping

Using the available `tiltRoll` from `MotionService` (range: −π to +π radians):

```
maxTiltRad  = π/4  (45°, comfortable maximum)
clampedRoll = clamp(tiltRoll, -maxTiltRad, maxTiltRad)
normalised  = clampedRoll / maxTiltRad          // range: -1.0 to +1.0
leftFraction = 0.5 - normalised * 0.5           // neutral=0.5, right-tilt=0.0, left-tilt=1.0
leftCount   = round(target * leftFraction)      // snaps to 0, 1, 2, ... target
rightCount  = target - leftCount
```

Dead zone: if `|tiltRoll| < 0.07 rad` (~4°), freeze at current count. This prevents
jitter at neutral without requiring the child to hold perfectly level.

**Example for target = 6**:
| Tilt (right side down) | leftCount | rightCount |
|---|---|---|
| 45° right | 0 | 6 |
| 22.5° right | 1–2 | 4–5 |
| Neutral (~0°) | 3 | 3 |
| 22.5° left | 4–5 | 1–2 |
| 45° left | 6 | 0 |

---

## 3. Sensor Feasibility

### 3.1 CMMotionManager — No Changes Required

`MotionService.swift` already provides:
- `tiltRoll: Double` at 30 Hz — exactly the axis needed for left/right balance tilt
- `shakeDetected: Bool` — can serve as "reset to neutral" (all counters to one side)
- No permissions required
- `applyMotionValues(pitch:roll:accelerationMagnitude:)` test hook already exists

**Usage**: The new `GravitySplitView` receives `tiltRoll` from the parent
(`SliceSessionView`) identically to how `BondMatchView` receives `tiltPitch` and
`tiltRoll`. No changes to `MotionService` are needed.

### 3.2 CHHapticEngine — Four New Patterns (§5 for specifications)

Existing patterns all belong to Bond Blast's card-matching metaphor. Four new
Gravity Split patterns are needed, all distinct in texture and timing:

| Pattern | Purpose | New? |
|---|---|---|
| `counterSlide` | Continuous thin rumble while tilting and counters are moving | ✅ New |
| `counterSettle` | Single clean tick as each counter snaps to an integer value | ✅ New |
| `balanceLock` | Bilateral simultaneous pulse when split matches decomposition | ✅ New |
| `tiltNeutral` | Micro-bump as device passes through level position | ✅ New |

All existing Bond Blast patterns (`cardPickup`, `cardNearSnap`, `cardSnapCorrect`,
`cardSnapMismatch`, `bondMatchComplete`) are untouched.

### 3.3 Feature Flag

New flag: `vs1GravitySplitEnabled: Bool`, default `false`.
Follows the same pattern as `vs1BondMatchEnabled`.
When `false`, the classic `TransferCheckView` (stepper buttons) is shown — zero regression.

---

## 4. Visual Design Recommendation

### 4.1 Selected Metaphor: Two-Pan Balance with Counter Circles

**Selected**: A horizontal balance beam with two rounded pans (left = amber/warm,
right = accent/emerald), each containing circular `CounterView` objects that slide
under simulated gravity.

**Rationale**:
- Maintains visual continuity with `ConcreteBuildView` and `TransferCheckView` (same
  counter circles, same warm/accent color coding)
- Explicitly represents the balance/equality concept established in research (§1.1)
- Discrete circles make subitizing and counting unambiguous

**Rejected alternatives**:
- *Water/liquid fills*: abstract, obscures discrete counting, contradicts CPA concrete principle
- *Rolling balls*: too dynamic/chaotic; child loses track of exact quantities
- *Abstract bar fills*: no countable objects; would require conservation reasoning not yet developed at age 5

### 4.2 Layout Structure

```
┌─────────────────────────────────────┐
│  Show it          [♪] [↩] [⌂]      │
│ ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ │
│                                     │
│  [3]  +  [3]  =  6                  │  ← live equation, color-coded
│                                     │
│      ╱           ╲                  │
│    ╱               ╲                │  ← balance beam, tilts with device
│  ┌─────────┐   ┌─────────┐         │
│  │ ● ● ●  │   │ ● ● ●  │         │  ← counters (amber left, green right)
│  └─────────┘   └─────────┘         │
│                                     │
│  Tap pan to nudge ±1               │  ← audio prompt, no text required
│                                     │
│  ┌────────────────────────────┐    │
│  │     Balance it!            │    │  ← primary CTA (enabled when locked)
│  └────────────────────────────┘    │
└─────────────────────────────────────┘
```

Key layout rules:
- Balance beam angle tracks `tiltRoll` visually (rotated line/shape)
- Counters "pour" to the lower pan when tilted; snap to integer positions
- CTA button "Balance it!" is always visible; enabled only when `isLocked == true`
  (left = decompositionA, right = decompositionB)
- Tapping either pan triggers onAdjust(±1, side) — the tap fallback

### 4.3 Live Equation Display

Same as `ConcreteBuildView`: live equation `leftCount + rightCount = target` with
amber/accent color-coded numerals, using `.contentTransition(.numericText())` for
animated digit changes. The child sees the equation update with each counter movement,
continuously reinforcing the abstract representation of the physical action.

**Design choice: live update vs. lock-then-reveal**

- Live update chosen: consistent with ConcreteBuildView and Write it; shows the CPA
  connection in real time (physical tilt → abstract equation update simultaneously).
- Risk: child may focus on numbers instead of the balance. Mitigated by making the
  equation small/secondary and the balance visual prominent.

---

## 5. Haptic Arc — New Patterns

All new patterns are distinct from Bond Blast's card-matching feel
(pickup/magnetic-ramp/click-echo/dull-hmm/four-rising-taps).

### 5.1 `counterSlide` — Continuous motion texture

```
CHHapticEvent(.hapticContinuous)
  intensity: 0.18, sharpness: 0.72   ← thin, buzzy (distinct from nearSnap's 0.2/0.4)
  duration: while tilt active and count changing
```
**Feel**: gravel or sand shifting — physically matches the sensation of loose objects
sliding. Plays only while the integer count is actively changing; stops immediately when
the count stabilises. Very low intensity to avoid fatigue over a session.

UIKit fallback: none (too subtle; skip if CHHapticEngine unavailable).

### 5.2 `counterSettle` — Per-integer snap tick

```
CHHapticEvent(.hapticTransient)
  intensity: 0.45, sharpness: 0.85   ← bright, clean (like placing a coin)
  relativeTime: 0
```
**Feel**: a single definitive click — the counter has landed. Fires once per integer
boundary crossed (e.g. if tilt moves count from 2→5, fires 3 times with 30ms spacing).
Provides the discrete experience that counteracts the continuous-gesture problem (§1.3).

UIKit fallback: `UIImpactFeedbackGenerator(style: .rigid).impactOccurred()`

### 5.3 `balanceLock` — Bilateral celebration

```
// Two simultaneous pulses representing left + right pans settling
CHHapticEvent(.hapticTransient) at t=0.00: intensity 0.70, sharpness 0.75
CHHapticEvent(.hapticTransient) at t=0.00: intensity 0.70, sharpness 0.55  // slight texture diff
CHHapticEvent(.hapticTransient) at t=0.14: intensity 0.40, sharpness 0.60  // echo
CHHapticEvent(.hapticContinuous) at t=0.28: intensity 0.45, sharpness 0.40, duration 0.25s  // settle hum
```
**Feel**: two things arriving simultaneously and coming to rest — the physical sensation
of a balance scale equalising. Meaningfully distinct from `bondMatchComplete`
(which builds sequentially and surges; this is simultaneous and settles).

UIKit fallback: `UINotificationFeedbackGenerator().notificationOccurred(.success)`

### 5.4 `tiltNeutral` — Midpoint marker

```
CHHapticEvent(.hapticTransient)
  intensity: 0.15, sharpness: 0.50
  fires when |tiltRoll| transitions through < 0.05 rad (from either side)
```
**Feel**: an almost imperceptible bump — like feeling a detent click when crossing
level on a physical balance. Helps the child find the midpoint (equal split) without
looking at the numbers. Very subtle; should not be noticed consciously.

UIKit fallback: none (too subtle).

---

## 6. Stage Placement Recommendation

### 6.1 Option Analysis

| Option | Description | Pros | Cons |
|---|---|---|---|
| **A** | Replace `.transfer` | Eliminates weakest UX moment; same concept | No fallback; regression risk |
| **B** | New stage between `.abstract` and `.transfer` | Both modalities for same decomposition | Adds session length; attention budget risk |
| **C** ✅ | Feature-flagged `.transfer` replacement | Zero regression; A/B testing possible; safe rollout | Slightly more implementation complexity |

**Recommendation: Option C**

With `vs1GravitySplitEnabled = false` (default), the app uses `TransferCheckView`
unchanged. With `vs1GravitySplitEnabled = true`, `GravitySplitView` replaces it.
The `SliceStateMachine` passes `showGravitySplit` alongside the existing `showTransfer`.

This mirrors exactly how `vs1BondMatchEnabled` gates Bond Blast. The family tests
Gravity Split, confirms it works better than the steppers, and at a later point we can
make it the default or remove the old path.

### 6.2 Revised Stage Sequence (with flag on)

```
concrete → pictorial → abstract → gravitySplit → bondMatch → done
```

(Transfer is suppressed when `vs1GravitySplitEnabled = true`; Bond Blast still fires on
the last problem as before.)

---

## 7. Integration Summary

### Domain Changes

| File | Change |
|---|---|
| `Domain/SliceModels.swift` | Add `case gravitySplit` to `SliceStage` enum |
| `Domain/SliceStateMachine.swift` | Add `showGravitySplit: Bool` parameter to `nextStage()`; when true, `.abstract → .gravitySplit` instead of `.abstract → .transfer` |
| `Domain/VerticalSliceEngine.swift` | Add `gravitySplitState: GravitySplitState?`; initialise on stage transition; respond to `adjustGravitySplit(side:delta:)` and `lockGravitySplit()` |

### New Model

```swift
struct GravitySplitState {
    let target: Int
    let decompositionA: Int  // expected left count
    let decompositionB: Int  // expected right count
    var leftCount: Int
    var rightCount: Int
    var isLocked: Bool        // true when leftCount==A and rightCount==B
}
```

### Services

| Service | Change |
|---|---|
| `MotionService` | No changes — `tiltRoll` already available |
| `HapticsService` | Add `counterSlide(enabled:)`, `counterSettle(enabled:)`, `balanceLock(enabled:)`, `tiltNeutral(enabled:)` |

### Feature Flag

| File | Change |
|---|---|
| `Shared/FeatureFlags.swift` | Add `vs1GravitySplitEnabled: Bool`, key `"feature.vs1GravitySplitEnabled"`, default `false` |

### New View

`Features/VerticalSlice1/GravitySplitView.swift` — receives `state: GravitySplitState`,
`tiltRoll: Double`, `shakeDetected: Bool` (reset). Follows the same prop-passing pattern
as `BondMatchView`.

---

## 8. Open Questions for Prototype Validation

These questions cannot be answered by research alone and require a working prototype:

1. **Tilt sensitivity**: does ±45° feel natural for the full range, or does it need to be
   tighter (±30°) or wider (±60°)?
2. **Dead zone size**: is 4° dead zone at neutral enough to prevent jitter, or does it
   feel "sticky" and unresponsive?
3. **Counter settle rate**: should all counters snap instantly when the tilt stabilises,
   or should they settle one-by-one with 30ms gaps (more physical, but slower)?
4. **Shake-to-reset direction**: should shake reset to one extreme (all left, like pouring
   into a bucket) or to neutral (equal split)? Neutral makes more mathematical sense but
   "pouring" might be more physically satisfying.
5. **Attention span**: does the tilt mechanic extend time on Transfer stage beyond the
   ~30–60 seconds typical for the stepper version? Monitor session telemetry.

---

## 9. Risks and Mitigations

| Risk | Likelihood | Mitigation |
|---|---|---|
| 5-year-old finds tilt imprecise/frustrating | Medium | Tap fallback always available; dead zone prevents jitter; ±45° range is generous |
| Continuous gesture/discrete task mismatch (§1.3) | Medium | Discrete snap + per-integer haptic tick makes experience feel discrete |
| Session attention budget exceeded | Low | Gravity Split replaces Transfer (no net addition); Bond Blast unchanged |
| Motion sickness from balance animation | Low | Balance beam tilt is slow (tied to device tilt, not rapid animation); no scrolling or parallax |
| Shake-reset triggers accidentally during normal handling | Low | 2.5g threshold already validated in Bond Blast; same threshold here |
| `vs1GravitySplitEnabled` left on in prod prematurely | Low | Default false; Settings toggle visibility gated by same flag |

---

## 10. References

- NSF PAR #10201368: *The role of balance scales in supporting productive thinking about equality*. (Kindergarten–Grade 2 classroom study, NSF-funded). Retrieved from par.nsf.gov.
- Abrahamson, D., et al. (2017). Support of mathematical thinking through embodied cognition: Nondigital and digital approaches. *Psychonomic Bulletin & Review*. PMC5321706.
- Goldin-Meadow, S. (2009). How gesture promotes learning throughout childhood. *Child Development Perspectives*, 3(2), 106–111. *(Cited in VS1-Sensor-Finale.md)*
- NAEYC (2022). Playing Around with Number Composition. *Teaching Young Children*, Spring 2022. naeyc.org.
- Kindergarten Cafe (2024). Decomposing Numbers in Kindergarten. kindergartencafe.org.
- PMC 5816079: Development of postural control and maturation of sensory systems in children of different ages. (Cross-sectional study, 5–7 year cohort.)
- PMC 4131166: The relationship between a child's postural stability and manual dexterity.
- Common Sense Media / Motion Math Zoom app review. commonsensemedia.org.
- Funexpected Math (2024). Introduction to Equations with Balancing Scales. funexpectedapps.com.
- Apple Developer Documentation: [Core Motion](https://developer.apple.com/documentation/coremotion), [Core Haptics](https://developer.apple.com/documentation/corehaptics).
- All prior Mather research: `wiki/Research/Math-App-Vision.md`, `wiki/Research/VS1-Sensor-Finale.md`, `wiki/ADRs/ADR-0006-sensor-finale-stage.md`.
