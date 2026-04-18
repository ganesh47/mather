# Research: Physics, Geometry & Sensor-Based Gameplay — Ages 4–10 Expansion

**Status**: Draft
**Date**: 2026-04-18
**See also**: `wiki/Specs/Physics-Geometry-UX-Design.md` — complete UX design for all 7 mechanics + Gravity Split fix

---

## Summary

Mather currently addresses the number sense / part-part-whole curriculum band for ages 5–7
(VS1 Make & Break to 10, Bond Blast, Gravity Split, Room Quest, Sum Sprint). This document
commissions and delivers the research basis for a physics + geometry expansion that:

- Extends Mather's age ceiling from 7 to **10**
- Introduces **physics intuition**, **geometry**, and **early number theory** through
  sensor-grounded, CPA-coherent gameplay
- Addresses the **timer mechanic tension**: the user has requested puzzle-play with a timer,
  but existing research (§2 below) forbids pressure timers for ages 5–7. The research resolves
  this with an age-gated timer policy.

All hard constraints from `Math-App-Vision.md` carry forward unchanged for ages 4–7.
The new material addresses ages 8–10 where those constraints can be selectively relaxed.

---

## 1. Concept-to-Age Developmental Map

### 1.1 Physics Concepts by Age

**Key narrative: the naive-physics learning loop**

McCloskey (1983) documented that children (and adults) hold systematically wrong "intuitive
physics" theories — e.g., that objects fall straight down when released from a moving hand,
rather than following a parabolic arc. Siegler and Stern (1998) showed that the most effective
learning intervention is not instruction but *prediction-then-observation*: the child states what
will happen, watches what actually happens, and resolves the discrepancy. This is the CPA loop
applied to physics. A simulation that lets the child predict first and then sees the outcome
live is more powerful than a tutorial that tells them the correct answer.

Mather can use this pattern across all physics mechanics: **C = physical prediction gesture**
(tilt, launch, lift), **P = simulated outcome drawn in real time**, **A = physics variable
label appears after the concept is discovered**.

| Age band | Concept | Research basis | Prerequisite | CPA note |
|---|---|---|---|---|
| 4–5 | Gravity as direction (things fall down) | Baillargeon (1987): intuitive gravity present from 3–4 months of age; governs object-drop expectations reliably by age 4 | None | C = drop gesture or tilt; abstract label not introduced |
| 4–5 | Balance / heavy vs. light | NSF-funded balance beam studies (Siegler, 1976): children begin reasoning about weight on one side of a scale by age 5; already embodied in GravitySplit | Counting to target | GravitySplit is the existing implementation |
| 6–7 | Trajectory / arc of a thrown object | McCloskey (1983): most children and adults predict incorrect straight-down paths; Siegler (1998): prediction gap drives discovery | Subitizing to 10 | C = device-tilt aim; P = arc drawn; A = angle label deferred to §1.2 |
| 6–7 | Floating and sinking (density intuition) | Archimedes' principle is *discoverable* at age 6 through exploration without formulas (NAEYC, 2002); Piaget caution: full conservation of volume not until ~age 7 | Conservation of number | C = lift/lower device to control depth; P = buoyancy arrow overlay; A = density value shown |
| 6–7 | Speed comparison (relative, not absolute) | Relative speed (faster/slower) is pre-formal and reliable by age 5; absolute speed (m/s) is not accessible until late elementary (CCSS grade 6) | Comparison (more/less) | A = velocity label deferred; "faster" comparison is the abstract step |
| 8–10 | Force and motion — pushes and pulls change speed and direction | NGSS grades 3–5 introduce force formally; visual preparation at grade 2–3 supported by research (National Research Council, 2012) | Multiplication intuition | C = pinch/push gesture sets force magnitude; P = arrow overlay shows direction + magnitude; A = force equation after discovery |
| 8–10 | Simple machines — lever and inclined plane as force multipliers | Connects physics to multiplication / factor intuition; visualizable without formulas; Linn & Hsi (2000): hands-on lever work age 8+ | Factor pairs (§1.3) | C = drag fulcrum position; P = animated effort/load arrows; A = mechanical advantage ratio |
| 8–10 | Projectile arcs and angle | Requires angle concept from §1.2 as prerequisite; connects geometry to physics; satisfying payoff for angle curriculum | Angle measurement | C = tilt + pinch for angle + power; P = dashed predicted arc + solid actual arc; A = angle + velocity labels |

**Design principle from the research**: For every physics concept, introduce the prediction gap
*before* the correct model. Never tell the child what will happen. Let them set up the scenario,
state their prediction (or simply act on their intuition), and then observe. The discrepancy is
the engine of learning.

---

### 1.2 Geometry Concepts by Age

**Key finding: topological precedes Euclidean (Piaget & Inhelder, 1956)**

Children's earliest spatial understanding is *topological* — inside vs. outside, connected vs.
disconnected, closed vs. open. Euclidean properties (angles, distances, parallelism) come later.
This has a direct design implication: shape-sorting activities (topology) are CPA-ready at age
4–5, while angle measurement (Euclidean) requires concrete groundwork first and should not be
introduced symbolically before age 7–8 at the earliest.

| Age band | Concept | Research basis | Prerequisite |
|---|---|---|---|
| 4–5 | Shape identification: circle, square, triangle, rectangle | CCSS K.G; Clements & Sarama (2014) shape trajectory Level 1: visual prototype matching | None |
| 4–5 | Sorting by shape, size, and inside/outside | Clements & Sarama Level 1–2 trajectories; topological relations (enclosed/not) are reliably used by age 4 | None |
| 5–6 | Bilateral symmetry — fold-line matching | Roth (2016): bilateral symmetry recognition is robust from infancy; fold-line action is the concrete Piagetian act for symmetry | Shape recognition |
| 6–7 | Shape composition: two shapes make a new shape | CCSS 1.G; DragonBox Geometry uses exactly this as its core mechanic; Clements (2004): composing/decomposing shapes is foundational for fractions and area | Shape sorting |
| 6–7 | Angles as turns — full, half, quarter turns before degrees | CCSS 2.G introduces angle preparation; Logo/Turtle geometry research (Clements, 2003): children as young as 6 develop robust angle intuition through turtle-turn play | Shape composition |
| 7–8 | Angle measurement in degrees | CCSS 4.MD.5 introduces angle measurement formally; but visual degree preparation at grade 2–3 is supported by Mitchelmore & White (2000) | Angles as turns |
| 7–8 | Perimeter as a counting/adding task | CCSS 3.MD.8; Nunes et al. (2009): perimeter is easier than area because it reduces to addition | Addition to 20 |
| 8–10 | Area as multiplicative structure — rows × columns | CCSS 3.MD.7; Nunes et al. (2009): area is the *hardest* geometry concept for ages 8–10 because it requires understanding two-dimensional quantity, not just length; connects directly to factor pairs (§1.3) | Multiplication |
| 8–10 | Coordinate grids | CCSS 5.G.1 formally; Logo turtle path introduces spatial coordinates at age 7 (Clements, 2003) | Skip-counting |
| 8–10 | Reflections, rotations, translations | CCSS 8.G formal; but physical introduction at grade 3–4 with rotating/flipping physical shapes is supported (Sarama & Clements, 2009) | Angle measurement |

**Practical consequence for Mather**: Do not jump to protractors or coordinate grids for a
7-year-old. The Symmetry Fold mechanic (§6.4) is age-appropriate at 5–7 because it uses
the fold gesture (concrete topological act). The Two-Finger Protractor (§6.2) is appropriate
at 7–9 only after angles-as-turns have been established.

---

### 1.3 Number Theory by Age

This section extends the factor/prime coverage in `wiki/Research/Math-App-Vision.md §3`.

| Age band | Concept | Approach | Prerequisite |
|---|---|---|---|
| 5–6 | Odd/even (Montessori pairing: can every object find a partner?) | Concrete pairing; "lonely" leftover = odd | Counting to 20 |
| 6–7 | Figurate numbers — triangular, square dot arrays | Visual building; "how many dots if I add another row?" | Addition |
| 7–8 | Factor pairs via rectangle building | "How many different rectangles can 12 dots make?" → 1×12, 2×6, 3×4; discovery that prime numbers give only *one* rectangle | Multiplication intuition |
| 7–8 | Multiples via skip-counting patterns | Number line illumination: every 3rd step lights up → multiples of 3 | Skip-counting |
| 8–9 | Prime vs. composite — single rectangle = prime | Array approach from Math-App-Vision; natural payoff of rectangle factory | Factor pairs |
| 8–10 | Divisibility rules: 2, 5, 10 | Pattern discovery from last digit observation; "all evens end in 0, 2, 4, 6, or 8" | Multiples |
| 9–10 | Factor trees as splitting animations | Splitting tree game: "break 12 until every branch is prime"; 12 → 2×6 → 2×2×3 | Primes; factor pairs |

---

## 2. Timer Mechanics and Math Anxiety

This section addresses the central tension: the product request includes timer-based puzzle
play, but `Math-App-Vision.md §4.1` explicitly forbids pressure timers for ages 5–7. The
following synthesis resolves the tension with an age-gated policy grounded in empirical research.

### 2.1 The Research Evidence

**Math anxiety in young children**

Ramirez et al. (2013, *Child Development*) demonstrated that math anxiety is present and
measurable in first and second grade (ages 6–8), not just in older students. Critically, they
showed that math-anxious children with high working memory capacity are *more* harmed by
anxiety than those with lower capacity — anxiety depletes precisely the cognitive resource
most needed for mathematical reasoning. Time pressure in an evaluation context is one of the
primary triggers.

Gunderson et al. (2018) mapped the developmental trajectory of math anxiety: it appears as
early as grade 1 and peaks in grades 2–4 (ages 7–10). This is exactly the age band that a
timer-based expansion would target. The research does not support the assumption that timers
become safe "once the child is older" — they can introduce anxiety at any point where the
task is not yet at mastery.

**Timed conditions and cognitive load**

Ashcraft & Kirk (2001) showed that timed math conditions produce a measurable increase in
working memory disruption in math-anxious individuals, independent of mathematical ability.
Hembree's meta-analysis (1990) found that anxiety is highest under the combination of
*evaluation* and *time pressure* — either factor alone is less harmful than the combination.

**The case against timed fluency practice**

Boaler (2014, "Fluency Without Fear", YouCubed, Stanford) synthesised the above research into
a direct argument against timed tests in mathematics education. The paper is widely cited by
curriculum designers and has influenced several state education standards. Boaler's position:
timed conditions do not improve fluency; they cause math anxiety which then impairs the
fluency they are meant to develop. For a math learning app, this is a serious indictment of
"race the clock" mechanics.

**Counter-evidence: timers can support strategy selection in specific conditions**

Siegler (1988) observed that time constraints promote efficient strategy selection in older
children (approximately grade 3+) *when the task is within established mastery range*. The
critical condition: the child must already know how to solve the problem; the timer tests
retrieval speed, not first-learning. When this condition is violated — as it is during initial
concept acquisition — timers produce anxiety without learning benefit.

### 2.2 Age-Gated Timer Policy

Based on the above synthesis, Mather's timer policy extends as follows:

| Age | Timer type | Permitted | Condition |
|---|---|---|---|
| 4–7 | Any countdown timer | **No** | Unconditionally forbidden. Existing `Math-App-Vision.md §4.1` policy unchanged. |
| 4–7 | Ambient rhythm / pulsing animation | **No** | Even subtle time pressure is harmful during initial concept acquisition. |
| 8–9 | Self-started personal best counter | **Yes** | Only on fact families that the child has demonstrated mastery of (≥3 consecutive correct). Prominent "skip" or "no timer" option always visible. |
| 8–9 | Growing completion bar | **Yes** | Progress framing (how much done) not deadline framing (how much time left). No urgency signal. |
| 8–9 | Forced countdown | **No** | Anxiety risk is still present; Gunderson et al. show anxiety peaks ages 7–10. |
| 10 | Self-paced countdown (optional) | **Conditional** | Opt-in only via parent settings. Only on mastered fact families. Must be paired with immediate "turn off timer" affordance. |
| All | Countdown + negative feedback ("time's up!" buzzer) | **FORBIDDEN** | The combination of time pressure and negative evaluation feedback is the highest-anxiety pattern documented in Hembree (1990). |

**Timer design gradient** (least anxious → most anxious):

1. **No timer** — always safe at all ages; the default for all Mather activities
2. **Personal best counter** — not a timer; measures improvement over the child's previous performance; entirely positive framing; safe from age 8+ on mastered content
3. **Ambient visual rhythm** — a gentle pulse or breathing animation that establishes a pleasant pace without countdown; no loss-framing; safe as a background element age 8+
4. **Growing completion bar** — shows how much has been completed (not how much time remains); progress-framing; safe age 8+ on mastered content
5. **Self-started countdown** — child initiates the timer themselves; task is at mastery level; age 8+ only; "skip" always visible
6. **Forced countdown** — **FORBIDDEN** for Mather at all ages

**Implementation note**: Any timer mechanic must be behind both the feature flag system and
an age-profile gate (see §7 open question on age-profile UX). The flag must default to `false`.

---

## 3. iOS Sensor Feasibility Matrix

Mather already uses CMMotionManager (tilt + shake), CHHapticEngine, SwiftUI sensoryFeedback,
AVAudioEngine RMS (clap detection), and AVFoundation camera + image detection (Room Quest).

The following sensors have not yet been leveraged:

| Sensor | Framework | Permission | Mechanic potential | Age fit | Motor demand | Recommendation |
|---|---|---|---|---|---|---|
| **Barometer** | `CoreMotion.CMAltimeter` | None | Altitude delta (±0.3–0.5m resolution) maps to a "depth" axis. Child lifts the device → object rises in the simulation; lowers it → object sinks. Float Lab mechanic (§6.3). | 6–8 | Lift/lower device — gross motor, safe from age 4 | **Include** — no permission; honest signal at qualitative scale; validate altitude delta stability before speccing |
| **Multi-touch simultaneous tracking** | `UIKit UITouch` / SwiftUI `simultaneousGesture` | None | Two fingers placed on screen → device computes angle between them. Two-Finger Protractor mechanic (§6.2). | 7–9 | Two-finger placement — achievable by age 6+ | **Include** — no new API needed; angle computed via `atan2` between touch positions |
| **Magnetometer (raw field)** | `CMDeviceMotion.magneticField` via `CMMotionManager` | **None** (accessed through `CMMotionManager.startDeviceMotionUpdates(using: .xMagneticNorthZVertical)`) | Device heading relative to magnetic north. Compass Angles mechanic (§6.7): rotate device to point cardinal directions; compass rose overlay shows swept angle. | 7–9 | Device rotation — same as GravitySplit tilt | **Conditional** — raw magnetometer via CoreMotion requires no permission; design must not imply GPS or location; validate heading stability in indoor environments (magnetic interference from furniture/appliances is common) |
| **LiDAR depth sensor** | `ARKit / RealityKit ARWorldTrackingConfiguration` | None | Room-scale distance and angle measurement using real environment. "Measure your room" geometry activity. Surface normal provides ground-plane physics anchor. | 8–10 | Normal device use | **Conditional** — iPad Pro and iPhone 15 Pro+ only; **no LiDAR on iPad Air (M1/M2/M3) or iPhone 16e**; must degrade gracefully on non-LiDAR hardware; model on Room Quest tiered approach (ADR-0006); defer until hardware share justifies spec work |
| **TrueDepth / Face tracking** | `ARKit ARFaceTrackingConfiguration` | **Camera** (orange indicator dot) | Emotion-aware difficulty pacing; gaze-direction attention detection; face symmetry mirror game (child's face reflected). | 6–10 | None beyond holding device | **Defer** — camera permission introduces significant UX friction and parental concern; privacy risk for children's face data; emotion detection is algorithmically fragile and culturally biased; the symmetry face mirror game is achievable without face tracking using the front camera mirror mode |
| **Front camera (non-face)** | `AVFoundation` + `Vision VNDetectRectanglesRequest` | **Camera** | Shape detection from real-world objects: scan a book for rectangle, a clock for circle, a slice of pizza for triangle. | 6–10 | Normal device use | **Defer** — camera permission UX friction; Room Quest already owns the camera permission mental model; avoid asking for camera permission twice for unrelated use cases; revisit after Room Quest UX is fully stabilised |
| **GPS / CoreLocation** | `CoreLocation` | **Location (when in use)** | Outdoor measurement activities; distance math; compass navigation with true north. | All | Normal device use | **Exclude** — location permission is the most parental-concern-raising permission on iOS; GPS is too coarse for any in-room mechanic (±5m); outdoor-only use case is outside Mather's indoor-activity design constraint |

**Summary verdicts**:
- **Include immediately**: Barometer (Float Lab), Multi-touch (Two-Finger Protractor)
- **Include conditionally**: Magnetometer (Compass Angles — validate indoor stability), LiDAR (room-scale geometry — defer until hardware share justifies)
- **Defer**: TrueDepth face tracking, front camera shape detection
- **Exclude**: GPS

---

## 4. Competitive Analysis

### 4.1 DragonBox Geometry (Kahoot!, ages 4+)

**What it does**: Angles are introduced as tangram-like puzzle pieces. The child manipulates
wedge shapes to fill outlines. There is no protractor, no degree label, no explicit instruction.
The angle concept is *discovered* through repeated shape-fitting. Degree labels appear only
after the concept is established through play — a textbook CPA implementation.

**What Mather learns**: The symbol (degree, protractor) must be withheld until the concrete
geometry of the angle is already intuitive. DragonBox Geometry is the clearest existing
example of CPA done right for a Euclidean geometry concept. The Two-Finger Protractor mechanic
(§6.2) should follow the same principle: no degree label on first use, revealed only after
consistent correct angle placement.

**What Mather avoids**: DragonBox Geometry has no sensor input beyond touch. Mather's sensor
advantage (tilt, magnetometer) lets the body become the angle, not just the finger.

### 4.2 Angry Birds (Rovio, ages 6+)

**What it does**: Projectile physics is the core mechanic. The child develops arc intuition
through repeated slingshot experiments — not through instruction. Every failed shot is an
experiment; the physics feedback loop is immediate and consequence-free.

**What Mather learns**: (1) The prediction-gap loop: each shot is a hypothesis. (2) Failure
is funny and instructive, not punishing. (3) Physics intuition can be deeply engaging without
any explicit physics teaching. (4) The "aim angle × power = trajectory" relationship can be
intuited before it is formalised.

**What Mather avoids**: Angry Birds has no curriculum progression — it is pure entertainment.
Mather pairs the same arc-intuition mechanic with an explicit CPA ladder that introduces angle
measurement after the intuition is established.

### 4.3 Monument Valley (ustwo, ages 8+)

**What it does**: Spatial reasoning through impossible geometry puzzles — Escher-style optical
illusions where spatial manipulation is the mechanic. No arithmetic, no labels. Intrinsically
motivating through spatial discovery alone.

**What Mather learns**: Spatial reasoning is a first-class mathematical activity, not a
prerequisite for "real" math. Spatial challenge alone, without arithmetic, can be a complete
and deeply satisfying learning experience. Mather should resist the temptation to attach
arithmetic to every spatial mechanic — sometimes the spatial concept *is* the learning objective.

**What Mather avoids**: Monument Valley has no pedagogical scaffolding. Mather adds the CPA
layer without losing the spatial delight.

### 4.4 Osmo Tangram (Tangible Play, ages 5–12)

**What it does**: Physical tangram tiles placed in front of a camera are recognised and
matched to on-screen outlines. The hybrid physical/digital interface is compelling — the
child is manipulating real objects.

**What Mather learns**: Shape composition (two triangles → square) is deeply satisfying as
a mechanic and is CPA-coherent. The tangram composition challenge is fully achievable on-screen
without physical tiles, using drag-and-snap touch gestures.

**What Mather avoids**: Camera permission + physical accessory dependency. The same conceptual
value is achievable through touch-based shape composition (§6.5 Rectangle Factory, shape
composition variant) without requiring an accessory or camera permission.

### 4.5 Toca Boca Physics Toys (Toca Boca, ages 3–8)

**What it does**: Open-ended sandbox physics — water, sand, cutting, dropping. No learning
objective. The delight is pure physical exploration.

**What Mather learns**: Open-ended physical exploration is intrinsically motivating and
emotionally safe. Sandbox play with physics creates the affective conditions for mathematical
discovery. Mather's Float Lab (§6.3) is a constrained version of exactly this: lift/lower to
control buoyancy, but with a number attached.

**What Mather avoids**: Pure sandbox with no mathematical structure produces play but not
learning. Mather adds a mathematical question ("which object sinks? why?") to the sandbox
pattern without destroying the exploratory feeling.

---

## 5. CPA Mapping for New Concept Domains

Every new mechanic must follow the Concrete → Pictorial → Abstract sequence independently for
each concept. No mechanic should introduce the abstract symbol before the concrete and pictorial
phases are established.

| Domain | Concrete | Pictorial | Abstract |
|---|---|---|---|
| **Angles** | Device tilt to aim; two-finger spread to set angle; physical body turn (quarter/half/full) | Coloured arc drawn between the two directions; rotation animation sweeping from start to end; wedge shape filling the angle | Degree numeral fades in; "°" symbol; protractor overlay appears after correct placements |
| **Symmetry** | Rotate iPad to physically "fold" the canvas (bilateral fold gesture — like folding paper); mirror image snaps together | Mirror line drawn as dashed axis; reflection animation plays; both halves shown as identical coloured regions | Transformation label: "reflection"; axis coordinates shown; eventually: coordinate rule (x, y) → (-x, y) |
| **Gravity + force** | Tilt device to steer a falling object (direct body-to-physics connection, extends GravitySplit); pinch to increase force | Force-arrow overlay shows direction and length proportional to magnitude; predicted trajectory (dashed) shown before action; simulation plays after | "Force", "N" (newton) labels appear post-discovery; slider for force variable after several sessions; F=ma shown only at age 10+ |
| **Projectile arcs** | Tilt for direction, pinch for power; launch is a tap | Dashed predicted arc drawn before launch; solid actual arc drawn during flight; landing point highlighted | Angle + velocity values shown at summary screen; arc equation deferred until formal algebra |
| **Factor pairs** | Drag dot tiles onto grid to form rectangles; must use all dots | Dot array shown inside completed rectangle; dimensions highlighted (e.g., "3 rows × 4 columns") | "3 × 4 = 12" equation label appears on rectangle completion; prime numbers get a "lonely rectangle" label |
| **Density / buoyancy** | Lift/lower device to control submersion depth (barometer); objects of same size but different visual weight | Buoyancy force arrow scales with submersion depth; water level line rises and falls | Density value shown as number; "heavier → sinks faster" comparison; Archimedes label deferred until age 9+ |

---

## 6. Game Mechanic Proposals

Each proposal specifies: concept, age band, sensors, timer design, CPA mapping, intrinsic fun
rationale, and architectural fit with the existing Mather codebase.

---

### 6.1 Angle Cannon

**Concept**: Angle measurement as aim direction

**Age**: 7–9

**Sensors**: CMMotionManager tilt (existing, via `MotionService`)

**Timer**: None on first encounter. Personal best streak counter (opt-in, age 8+) on mastered
angle families. Never a countdown.

**CPA**:
- Concrete: tilt device to aim the cannon; tap to fire
- Pictorial: dashed trajectory arc drawn before firing; solid arc after; target hit or missed shown
- Abstract: degree readout appears in summary after fire; "You aimed at 45°" shown post-shot

**Fun**: Prediction + result suspense ("did I aim right?"); satisfying arc animation; natural
difficulty progression (wider target → smaller target → specific degree matching)

**Architecture**: New `AngleCannonView`. Extends `MotionService.startTiltUpdates()` already
used by `GravitySplitView`. New feature flag `angleCannonEnabled` (default `false`). New
`AppRoute.angleCannon` case in `VerticalSliceEngine`. No new permissions.

**Prototype priority**: **Highest** — extends existing sensor infrastructure, no new permissions,
strongest CPA mapping, clearest fun rationale.

---

### 6.2 Two-Finger Protractor

**Concept**: Angle measurement with the body as the instrument

**Age**: 7–9

**Sensors**: Simultaneous multi-touch (`UITouch` tracking; no new API)

**Timer**: Personal best streak counter, opt-in, age 8+ only on mastered angle targets.

**CPA**:
- Concrete: place two fingers on screen; they define the angle's rays
- Pictorial: arc drawn between the two fingers in real time as they move; wedge fills the angle
- Abstract: degree numeral fades in between fingers; "°" symbol appears after correct placement

**Fun**: "I am the protractor" — embodied angle measurement; haptic snap at common angles
(30°, 45°, 60°, 90°, 120°, 180°); satisfying completion click at target angle

**Architecture**: New `TwoFingerProtractorView`. Angle computed via
`atan2(touch2.y - touch1.y, touch2.x - touch1.x)`. `CHHapticEngine` snap pattern at target
angle ±3°. New feature flag `twoFingerProtractorEnabled`.

---

### 6.3 Float Lab

**Concept**: Density and buoyancy intuition

**Age**: 6–8

**Sensors**: `CMAltimeter` (barometer); altitude delta maps to submersion depth

**Timer**: None

**CPA**:
- Concrete: lift device → object rises in water; lower device → object sinks; hold level → object floats
- Pictorial: buoyancy force arrow shown; water level line; object partially submerged illustration
- Abstract: density number label shown for each object variant; "heavier than water" comparison text

**Fun**: Direct body-to-physics connection (lift your body, the object rises); surprise when a
hollow "heavy-looking" box floats; compare two objects to discover which sinks faster

**Architecture**: New `CMAltimeter.startRelativeAltitudeUpdates` wrapper in `MotionService`.
Altitude delta (±0.3–0.5m resolution) mapped to submersion percentage (0–100%). Validate
altitude delta stability across iPad models before speccing. New feature flag `floatLabEnabled`.

**Risk**: Indoor barometric pressure fluctuations (HVAC, doors opening) can produce noise.
Design the mapping to use relative delta from session start, not absolute altitude.

---

### 6.4 Symmetry Fold

**Concept**: Bilateral symmetry and reflection

**Age**: 5–7

**Sensors**: CMMotionManager device rotation (existing, via `MotionService`)

**Timer**: None

**CPA**:
- Concrete: rotate iPad left-to-right (like folding a sheet of paper in half) to "fold" the canvas
- Pictorial: dashed mirror line appears at fold axis; left half animates onto right half; colours blend on match
- Abstract: "Reflection" label appears; axis line shown; eventually: "the fold line is the mirror" text

**Fun**: Physical folding gesture is deeply intuitive; haptic snap when both halves align
precisely; stars or sparkles animate on perfect symmetry; wide appeal across gender lines
(paper-folding is universal play)

**Architecture**: Device rotation angle read from `CMDeviceMotion.attitude.roll`.
`FoldThreshold` constant (≈80° roll) triggers mirror animation. Extends existing
`CMMotionManager` usage in `MotionService`. New feature flag `symmetryFoldEnabled`.

---

### 6.5 Rectangle Factory

**Concept**: Factor pairs as multiplicative structure of area

**Age**: 7–9

**Sensors**: Tap + drag (no new sensor); CMMotionManager shake-to-reset (existing)

**Timer**: Growing completion bar (personal best — how many distinct rectangles found) at
age 8+. Never a countdown.

**CPA**:
- Concrete: drag dot tiles onto a grid to form a rectangle; must use *all* N dots
- Pictorial: dot array shown inside completed rectangle; row/column lines highlighted;
  dimensions annotated ("3 rows × 4 columns")
- Abstract: "3 × 4 = 12" equation label appears on rectangle completion; prime numbers show
  a "1 × N is the only rectangle" label — the prime discovery moment

**Fun**: Puzzle satisfaction ("how many different rectangles can I build with 12 dots?");
prime surprise ("7 dots can only make one rectangle — that's what prime means"); natural
escalating difficulty (increase N toward 100)

**Architecture**: Grid drag mechanic similar to `ConcreteBuildView`. Leitner-style fact
tracking for factor pairs — evaluate whether to reuse `StoredFactRecord` schema or introduce
a separate `StoredFactorPair` `@Model` (see §7 open question). New feature flag
`rectangleFactoryEnabled`.

---

### 6.6 Gravity Artist

**Concept**: Projectile arc as physics prediction experiment

**Age**: 8–10

**Sensors**: CMMotionManager tilt for aim angle; pinch gesture for launch power

**Timer**: None on first encounter. Self-started personal best on mastered arc families, age 8+.

**CPA**:
- Concrete: tilt device to set aim direction; pinch to set power; tap to fire
- Pictorial: dashed predicted arc drawn before firing; solid actual arc during flight; landing
  point shown; prediction-vs-reality overlay after each shot
- Abstract: angle + velocity values shown in post-shot summary; arc equation ("parabolic")
  deferred until formal algebra readiness

**Fun**: "Did I predict correctly?" suspense; every wrong shot is an experiment; arc animation
is inherently satisfying; chains of shots build a picture ("Gravity Artist" — child paints with
arcs); increasing challenge through smaller target windows

**Architecture**: New physics simulation using SwiftUI `TimelineView` + `Canvas` for arc
drawing, or `SpriteKit` scene embedded in SwiftUI. `CMMotionManager` tilt for aim angle;
`UIPinchGestureRecognizer` for power. `CHHapticEngine` launch pattern. New feature flag
`gravityArtistEnabled`.

---

### 6.7 Compass Angles

**Concept**: Angle as a turn; cardinal directions as concrete angle instances

**Age**: 7–9

**Sensors**: `CMDeviceMotion.magneticField` via `CMMotionManager` — raw magnetometer,
no permission required

**Timer**: None

**CPA**:
- Concrete: rotate device to point toward North, East, South, West — the body embodies the angle
- Pictorial: compass rose overlay with arc swept from starting direction to target direction;
  coloured wedge fills the swept angle
- Abstract: degree numeral appears (N=0°, E=90°, S=180°, W=270°); eventually: arbitrary angles
  between cardinals

**Fun**: Real-world grounding ("I turned to face East, that's 90°"); haptic click at cardinal
positions; challenge escalates to intermediate angles (NE = 45°, SE = 135°)

**Architecture**: `CMMotionManager.startDeviceMotionUpdates(using: .xMagneticNorthZVertical)`
for heading. New `CompassService` wrapper. Validate indoor heading stability (magnetic
interference from iPad covers, metal furniture) — may need a calibration step. New feature
flag `compassAnglesEnabled`.

**Risk**: Indoor magnetometer readings can be unstable near metal objects or electronics.
The mechanic must be robust to heading drift — design with a ±10° tolerance band at target
angles.

---

## 7. Open Questions

The following questions must be answered before any of the above mechanics move to spec and
implementation:

**7.1 Prototype priority**

Angle Cannon (§6.1) is the recommended first prototype: it extends the existing `MotionService`
tilt infrastructure with no new permissions, targets the age 7–9 band where the angle concept
is developmentally appropriate, and has the cleanest CPA mapping. Symmetry Fold (§6.4) is the
recommended second prototype: it extends the same MotionService, targets the younger 5–7 band
(more overlap with the current user), and requires no new sensor validation.

**7.2 LiDAR hardware reach**

iPad Air (M1/M2/M3) has no LiDAR sensor. iPhone 16e has no LiDAR. LiDAR mechanics (room-scale
distance and angle measurement) should be deferred until the LiDAR-equipped hardware share
in the Mather user base justifies the development investment. Monitor Apple's product line
evolution.

**7.3 Age-profile UX**

The timer policy (§2.2) and several age-gated mechanic unlocks depend on knowing whether the
current session is for a child of age 5 or age 9. Mather currently has no age-profile concept.
Options:

- A. **Parent-set age profile in Settings** — simplest; parent enters child's age once; stored
  in `FeatureFlags` or a new `ChildProfile` model. Recommended.
- B. **Difficulty-tier inference from performance** — no parent input required; engine infers
  appropriate age band from correctness rate and response latency. More complex; can mis-infer.
- C. **Activity-level age gating** — each activity specifies its own minimum age; parent
  enables/disables in Settings. Avoids a global age profile.

This needs an ADR before any age-gated mechanic is specced.

**7.4 Barometer signal stability**

`CMAltimeter` altitude delta has ~0.3–0.5m resolution on current iPad hardware. This is
sufficient for qualitative float/sink (the object clearly rises or falls). However, HVAC
systems, door/window openings, and elevator motion produce barometric pressure changes
that could be interpreted as device movement. Float Lab must be validated for stability
before spec: run a 5-minute idle test and measure altitude delta variance in a typical
indoor environment.

**7.5 Magnetometer indoor stability**

`CMDeviceMotion.magneticField` heading can drift significantly indoors due to interference
from metal objects, electronics, and building infrastructure. Compass Angles (§6.7) requires
heading accuracy within ±10° to be usable. Validate with a simple test: record heading
while rotating device in a typical living room/classroom environment. If variance exceeds
±15°, the mechanic is not viable without a calibration step.

**7.6 Rectangle Factory schema**

Sum Sprint's `StoredFactRecord` `@Model` stores fact fluency (addend pairs). Rectangle Factory
needs to store factor pair mastery (factor × factor = product). Evaluate: does the same schema
serve both use cases, or does factor-pair tracking warrant a separate `StoredFactorPair` `@Model`
with different fields (e.g., `factorA`, `factorB`, `product`, `rectanglesFound`)? The
decision affects the `ModelContainer` schema and migration strategy.

---

## 8. References

**Developmental Psychology**

- Baillargeon, R. (1987). Object permanence in 3.5- and 4.5-month-old infants. *Developmental Psychology*, 23(5), 655–664.
- Piaget, J. & Inhelder, B. (1956). *The Child's Conception of Space*. Routledge.
- McCloskey, M. (1983). Intuitive physics. *Scientific American*, 248(4), 122–130.
- Siegler, R. S. (1976). Three aspects of cognitive development. *Cognitive Psychology*, 8(4), 481–520.
- Siegler, R. S. (1988). Strategy choice procedures and the development of multiplication skill. *Journal of Experimental Psychology: General*, 117(3), 258–275.
- Siegler, R. S. & Stern, E. (1998). Conscious and unconscious strategy discoveries: A microgenetic analysis. *Journal of Experimental Psychology: General*, 127(4), 377–397.

**Math Anxiety and Timers**

- Ramirez, G., Gunderson, E. A., Levine, S. C., & Beilock, S. L. (2013). Math anxiety, working memory, and math achievement in early elementary school. *Child Development*, 84(5), 1476–1490.
- Ashcraft, M. H. & Kirk, E. P. (2001). The relationships among working memory, math anxiety, and performance. *Journal of Experimental Psychology: General*, 130(2), 224–237.
- Hembree, R. (1990). The nature, effects, and relief of mathematics anxiety. *Journal for Research in Mathematics Education*, 21(1), 33–46.
- Gunderson, E. A., Park, D., Maloney, E. A., Beilock, S. L., & Levine, S. C. (2018). Reciprocal relations among motivational frameworks, math anxiety, and math achievement in early elementary school. *Journal of Cognition and Development*, 19(1), 21–46.
- Boaler, J. (2014). *Fluency Without Fear: Research Evidence on the Best Ways to Learn Math Facts*. YouCubed, Stanford University.
- NCTM (2014). *Procedural Fluency in Mathematics: A Position of the National Council of Teachers of Mathematics*. NCTM.

**Geometry and Spatial Reasoning**

- Clements, D. H. & Sarama, J. (2003). Young children and technology: What does the research say? *Young Children*, 58(6), 34–40.
- Clements, D. H. (2004). Geometric and spatial thinking in early childhood education. In *Engaging Young Children in Mathematics* (pp. 267–297). Lawrence Erlbaum.
- Clements, D. H. & Sarama, J. (2014). *Learning and Teaching Early Math: The Learning Trajectories Approach* (2nd ed.). Routledge.
- Mitchelmore, M. C. & White, P. (2000). Development of angle concepts by progressive abstraction and generalisation. *Educational Studies in Mathematics*, 41(3), 209–238.
- Nunes, T., Bryant, P., & Watson, A. (2009). *Key Understandings in Mathematics Learning*. Nuffield Foundation.
- Roth, W.-M. (2016). Astonishment: A post-constructivist investigation into mathematics as passion. *Educational Studies in Mathematics*, 88, 185–204.
- Sarama, J. & Clements, D. H. (2009). *Early Childhood Mathematics Education Research: Learning Trajectories for Young Children*. Routledge.

**Curriculum Standards**

- Common Core State Standards for Mathematics (CCSS-M): K.G (shapes), 1.G (shape composition), 3.MD.7 (area), 3.MD.8 (perimeter), 4.MD.5 (angles), 5.G.1 (coordinates), 8.G (transformations).
- Next Generation Science Standards (NGSS) Grades 3–5: Forces and Interactions (PS2.A, PS2.B).
- National Research Council (2012). *A Framework for K–12 Science Education*. National Academies Press.
- Linn, M. C. & Hsi, S. (2000). *Computers, Teachers, Peers: Science Learning Partners*. Lawrence Erlbaum.

---

*This document is the research basis for a future spec and implementation. No Swift code changes are implied by this document. The first implementation candidate is Angle Cannon (§6.1) — see open questions §7.1 and §7.3 before opening a spec issue.*
