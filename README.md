# Mather

Mather is an Apple-platform learning playground for kids ages **2–12**.

- **App information:** https://ganesh47.github.io/mather/
- **Privacy:** https://ganesh47.github.io/mather/privacy.html

The product is moving from a flat set of math mini-games into a **capability-based Explorer Lab**: kids choose what they want to grow — numbers, geometry, physics, geography/world knowledge, and future chemistry/electronics — then choose how they want to play: learn, explore, review, challenge, or timed.

The core design principle is simple: **make real concepts feel like play**. Mather uses touch, motion, audio, haptics, room movement, cards, and device sensors to turn abstract learning into concrete experiences.

## Product direction

Mather is built around:

- **Capability lanes** instead of isolated game tiles
  - Numbers Lab
  - Geometry Lab
  - Physics Lab
  - Geography Lab
  - Discovery Cards / recall substrate
  - future Chemistry Lab
  - future Electronics Lab
- **Staged gameplay** inspired by Make & Break
  - concrete action
  - pictorial model
  - abstract naming
  - embedded recall
  - choice/card quiz
  - transfer challenge
  - mastery tracking
- **Child agency**
  - kids can choose what to play and how intense it should be
  - calm, explore, challenge, and timed modes should coexist
- **Fast, loved mechanics**
  - Bond Blast-style pairing is a reusable pattern
  - Mix-Match-style recall is embedded across capability lanes
- **Sensor-rich play**
  - use the available iPhone/iPad sensors when they make learning more fun
  - keep fallback paths honest when sensors are missing, noisy, or permission-gated
- **Smart Play**
  - Apple Intelligence / Foundation Models / Siri can personalize hints, stories, voice prompts, and review
  - deterministic gameplay remains the source of truth
  - AI is fallback-first, parent-aware, and privacy-conscious

See the current umbrella tracker: [Spec: Reorganize Explorer Lab into capability-based staged learning lanes](https://github.com/ganesh47/mather/issues/797).

## Current implemented and researched areas

Current Explorer Lab/gameplay work includes:

- **Explorer Lab shell** — capability-lane navigation for Numbers, Geometry, Physics, Geography/World, and future science lanes

- **Make & Break** — concept-first number composition and staged learning
- **Bond Blast** — fast pairing mechanic loved by kids; should be generalized
- **Sum Sprint** — spaced-repetition fluency and recall
- **Room Quest** — embodied room-scale play with marker/sensor-aware direction and optional camera/location-assisted place matching
- **Symmetry Fold** — geometry through fold/tilt interaction
- **Rectangle Factory** — arrays, factors, and early number theory
- **Angle Cannon / Gravity Artist** — physics prediction and motion intuition
- **Two-Finger Protractor / Compass Walk** — embodied angles, direction, and measurement
- **Memory / Mix-Match** — moving from standalone play into embedded recall cards
- **Sound / sensor experiments** — optional motion, sound, haptics, and device-capability-aware fallbacks
- **Reusable five-stage gameplay threads** — countries, fruits, and water cycle now share the same Flashcards → Easy Memory → Flip Memory → Bond Blast → Multiple Choice flow, with direct Explorer Lab entries, score/time summaries, and persisted spaced-repetition progress

Useful specs and research live under `wiki/`, especially:

- `wiki/Research/Math-App-Vision.md`
- `wiki/Research/Memory-Multi-Mix-Match.md`
- `wiki/Research/Sum-Sprint-Spaced-Repetition.md`
- `wiki/Research/Physics-Geometry-Sensor-Gameplay.md`
- `wiki/Research/Room-Quest-Sensor-Capabilities-and-Design-Direction.md`
- `wiki/Specs/Make-Break-Number-Story-Thread.md`
- `wiki/Specs/Physics-Geometry-UX-Design.md`
- `wiki/Specs/Room-Quest-Sensor-Driven.md`

## Working model

When orienting on the product, use this order:

1. repo reality: code, tests, wiki specs, ADRs
2. live GitHub issue / PR / CI state
3. workspace product memory, if available
4. current conversation instructions

Operational expectations:

- GitHub is the main progress surface for repo-backed work.
- Incomplete implementation should move quickly toward branch, PR, and CI.
- Product claims should stay evidence-backed: code, tests, specs, issues, or observed child feedback.
- Keep useful research, but convert it into implementation-ready slices.

## Development

Open the project in Xcode:

```bash
open Mather.xcodeproj
```

Useful validation commands vary by environment, but the usual gates are:

```bash
xcodebuild test -project Mather.xcodeproj -scheme Mather -destination 'platform=iOS Simulator,name=iPad (A16)'
```

CI and workflow work should preserve the security posture documented in `.github/workflows/` and active PRs/issues.

## GitHub Pages

The public app information and privacy pages live under `docs/` and are intended to be served by GitHub Pages at:

- https://ganesh47.github.io/mather/
- https://ganesh47.github.io/mather/privacy.html

Keep these pages in sync whenever privacy-sensitive features change, especially sensors, storage, Smart Play, TestFlight diagnostics, or parent controls.

## Release readiness notes

- Recent build 104 crash-hardening work tightened delayed callback/lifecycle handling in Bond Blast and Angle Cannon/Targets flows.
- Issue #912 Slice H polish routes country cards, fruit cards, and water cycle through the reusable gameplay-thread surface.
- The legacy water-cycle lab route remains intentionally available for explicit legacy/UI-test launches, while Explorer Lab and direct water-cycle launches delegate to `GameplayThreadView`.
- Release screenshots should cover `-uiTest.startRoute waterCycle`, country cards, and fruit cards on compact phone and iPad layouts once CI/simulator infrastructure is available.

## Current near-term gaps

- Continue expanding the capability-lane Explorer Lab shell.
- Extract reusable Bond Blast-style pairing and Mix-Match recall components.
- Embed recall cards inside capability lanes instead of keeping Memory Match as a primary standalone play mode.
- Add play-mode choice: Learn, Explore, Challenge, Timed, Review.
- Add a `SensorCapabilityService` so gameplay can use available device sensors with honest fallbacks.
- Continue hardening Make & Break / VS1 quality while the larger Explorer Lab architecture evolves.
