# Research Spec: Mather on Apple TV and tvOS

**Status**: Draft
**Date**: 2026-06-20
**Lane task**: `mather-e3a9140775`

---

## Executive summary

Mather should not start by porting the full iPad app to tvOS. The best Apple TV version is a
living-room companion that turns Mather's strongest shared-play ideas into big-screen,
remote-friendly experiences.

The first tvOS candidate should be:

**Mather TV Lab**: a focused Apple TV app with 4 living-room modes:

1. **Memory Gallery** - big-screen picture/name/fact matching from existing Memory decks.
2. **Sum Sprint Party** - low-pressure shared recall using focusable answer tiles and streaks.
3. **Angle Arcade** - Angle Cannon / Gravity Artist style prediction games with the Siri Remote or game controller.
4. **Room Quest TV** - Apple TV as the shared mission board, with iPhone/iPad as the camera or motion companion when needed.

This direction uses what Apple TV is good at: big readable visuals, couch play, shared family
attention, remote/game-controller input, speaker audio, and optional iPhone continuity. It avoids
what Apple TV is weak at: fine touch manipulation, dense worksheets, and sensor-first solo play.

---

## Product thesis

Apple TV can make Mather feel more like family game night than solo tablet practice.

The iPad app is strongest when a child manipulates, moves, predicts, matches, and hears feedback.
On Apple TV, the same thesis becomes:

- parent and child can play together from the couch
- large visuals make animals, planets, vehicles, angles, and number bonds feel theatrical
- the remote or controller turns math choices into simple physical actions
- an iPhone/iPad can optionally supply camera, motion, or keyboard-like input
- the TV can become the "stage", while handheld devices become "controllers" or "scanners"

The product should be designed as a new surface with shared code, not a stretched iPad layout.

---

## Apple TV platform constraints and opportunities

### Input model

Apple TV interaction is focus-first. People navigate focused elements with a remote or game
controller, and the highlighted item receives the next input. This means Mather TV screens need
large focusable targets, predictable directional movement, and minimal text entry.

Design implications:

- Every child-facing action should be expressible as up/down/left/right/select/play-pause.
- Avoid drag-and-drop as a required primitive.
- Replace dense touch grids with shelves, rows, rails, answer lanes, and large tiles.
- Make the focused tile visually "lift" and respond with sound.
- Use SwiftUI focus APIs and focus sections deliberately for non-grid layouts.

### Remote and controller model

Apple documents the Siri Remote as the primary Apple TV input, with game controllers also supported.
The older Game Controller Programming Guide notes that the Siri Remote can behave as a micro
gamepad and that Apple TV can connect up to four game controllers plus one Siri Remote. The current
Game Controller framework also covers third-party gamepads and remotes.

Design implications:

- Single-player MVP must work with Siri Remote only.
- Multi-player or "party" mode can support up to 2-4 controllers, but must not require them.
- Treat Play/Pause as "pause / parent help / repeat prompt" rather than a gameplay action.
- For angle/arc games, prefer D-pad/focus aiming first; remote motion can be optional only after
  hardware validation.

### Living-room scale

Apple's tvOS page frames Apple TV as a living-room platform for entertainment, connection, rich
games, 4K/HDR visuals, immersive audio, SwiftUI, UIKit, AVKit, Metal, and Continuity Camera.

Design implications:

- Make every scene legible at 8-10 feet.
- Use fewer, larger visual objects.
- Use ambient music, spoken prompts, and distinct audio rewards.
- Use the TV for shared presentation and an iPhone/iPad for camera or motion only when it creates
  a genuinely better loop.

### Continuity Camera and iPhone companion paths

Current Apple documentation and WWDC material describe Continuity Camera support for tvOS, including
using iPhone/iPad camera and microphone in Apple TV apps. This is a good long-term path for
Room Quest or "show the object to the TV" play, but it should not be the MVP baseline because it
adds setup friction and hardware constraints.

Design implications:

- MVP should not require Continuity Camera.
- Room Quest TV can start as "TV mission board + iPhone/iPad scanner" using the existing iOS app.
- A later tvOS-native Continuity Camera slice can be researched separately.

---

## Fit analysis: current Mather parts

### 1. Memory / Mix-Match - best first tvOS candidate

**Why it fits Apple TV**

Memory is visually rich, already has decks, and does not require fine manipulation. Apple TV can
make cards large, vivid, and shared. The existing decks also have facts for animals, birds,
vehicles, planets, fishes, countries, and India states.

**tvOS concept: Memory Gallery**

- Rows of large cards by category.
- Select a picture card, then choose the matching name/fact tile.
- "Learn more" opens a big-screen fact panel with 2-3 focusable fact chips.
- Party mode: each player/controller claims a color and takes turns.
- Younger mode: all cards face up, no timer.
- Older mode: face-down concentration with streak and personal-best, not countdown pressure.

**What to reuse**

- `Features/Memory/MemoryView.swift` content model and deck data.
- Existing Memory research and age gating.
- Existing audio/descriptive service patterns.

**What must change**

- Extract deck/content types out of the SwiftUI iOS view file into shared domain/content files.
- Build a tvOS-specific focus layout.
- Replace tap/drag assumptions with focus/select.
- Add TV-safe asset sizing and verify all card art looks good at 4K/1080p.

**Verdict**

Highest value, lowest risk. This should be the first prototype.

---

### 2. Sum Sprint - strong second candidate if made party-like

**Why it fits Apple TV**

Sum Sprint can become a quick family recall game with large answer tiles. It should not feel like
a worksheet on the TV. It should feel like "pick the glowing number before the rocket loses
sparkle", with no harsh countdown.

**tvOS concept: Sum Sprint Party**

- TV shows a big visual fact: dots, ten-frame, or equation depending on support level.
- Four large answer tiles appear in a directional focus layout.
- Child chooses with remote or controller.
- Streaks and personal bests provide energy.
- In party mode, one player answers, or players buzz in with controller buttons.

**What to reuse**

- `SumSprintEngine`, fact scheduling ideas, summary state, pictorial fade policy.
- `FlashCardView` visual language as a reference, not as the literal TV UI.

**What must change**

- No numpad-first input for tvOS MVP.
- Multiple-choice answer generation needs deterministic distractors.
- Focus-first button layout needs large stable dimensions.
- Parent settings should keep countdowns off by default.

**Verdict**

Good second slice. It becomes fun on TV when treated as a family game show, not solo data entry.

---

### 3. Angle Cannon / Gravity Artist - best "real game" opportunity

**Why it fits Apple TV**

Projectile prediction is naturally theatrical on a large screen. The TV gives enough space for
large arcs, targets, misses, replays, and celebration. The remote/controller can aim simply.

**tvOS concept: Angle Arcade**

- D-pad left/right changes angle in visible increments.
- D-pad up/down changes power.
- Select fires.
- Dotted predicted arc appears before firing.
- Solid actual arc plays after firing.
- On hit, the degree label appears as discovery.
- Optional controller mode uses analog stick for angle/power.

**What to reuse**

- `GravityArtistPhysics` pure helpers.
- `AngleCannonView` and `GravityArtistView` concepts.
- Existing prediction-then-observation research.

**What must change**

- Remove touch-first affordances and child-held-device tilt as baseline.
- Use explicit focused controls and gamepad events.
- Tune difficulty for couch distance and large target motion.
- Add a tvOS game loop with pause, restart, and replay.

**Verdict**

Best flagship fun mode after Memory. It could sell the Apple TV idea instantly.

---

### 4. Compass Angles / Two-Finger Protractor - mixed fit

**Compass Angles**

Compass-style turns can work on Apple TV only if input is controller/remote-based, not actual
device rotation. On TV, this becomes "turn the ship/compass rose to north-east" with D-pad or
analog stick. It is educationally valid, but less magical than on iPad.

**Two-Finger Protractor**

The current two-finger mechanic is touch-native and should not be ported directly. It could become
a TV "angle builder" where the remote moves one ray around a pivot, but that is a derivative
experience, not a priority.

**Verdict**

Compass can be folded into Angle Arcade. Two-Finger Protractor should stay iPad-first for now.

---

### 5. Room Quest - strong companion mode, weak pure-tvOS mode

**Why it can fit Apple TV**

Room Quest is already about embodied family-room play. Apple TV can be the mission control screen:
large clue, station map, progress, narration, celebration, and parent-visible setup status.

**Why it cannot be pure tvOS MVP**

Apple TV alone does not give the same handheld camera/motion affordance. Continuity Camera is
promising but adds setup. Existing Room Quest is built around iOS/iPad camera and motion services.

**tvOS concept: Room Quest TV**

- Apple TV shows the mission board and speaks clues.
- iPhone/iPad app scans station markers and sends progress.
- TV celebrates station discoveries and shows the next clue.
- Optional later Continuity Camera mode lets Apple TV use an iPhone as the camera directly.

**What to reuse**

- Room Quest station model, setup concepts, marker-first/honest-sensor research.
- Existing station store and scanner concepts.

**What must change**

- Add cross-device/session coordination if TV and iPhone run separate apps.
- Define a local-network or SharePlay/Multipeer/CloudKit handoff approach after technical spike.
- Keep fallback path: TV-only demo mode with manual confirmation.

**Verdict**

High-value long-term. Do not make it the first tvOS implementation unless companion-device
plumbing becomes the explicit project goal.

---

### 6. Rectangle Factory / Symmetry Fold - keep as later or iPad-first

Rectangle Factory can become a big-screen factor/array puzzle, but it is likely less magical than
Memory, Sum Sprint, or Angle Arcade. Symmetry Fold is touch/tilt-native and loses much of its
embodied value on TV unless redesigned as a focus-driven mirror puzzle.

**Verdict**

Good later content, not MVP.

---

### 7. VS1 Make & Break / Gravity Split / Bond Blast - partial reuse only

The full VS1 loop is touch-manipulation heavy and belongs on iPad. However, two parts are useful:

- Bond Blast-style fast pairing can become a TV answer-matching mechanic.
- Gravity Split can become a TV "balance the pans" game using left/right controls.

**Verdict**

Do not port the full VS1 session. Extract the reusable pairing/balance concepts into TV-native
mini-games after the first tvOS content shell exists.

---

## Recommended MVP

### MVP name

**Mather TV Lab**

### MVP modes

1. **Memory Gallery**
   - Categories: animals, birds, vehicles, planets.
   - Loops: picture-to-name, picture-to-fact, face-up match.
   - Input: Siri Remote focus/select.

2. **Angle Arcade**
   - Start with one game: Gravity Artist TV or Angle Cannon TV.
   - Input: left/right angle, up/down power, select fire.
   - Output: big arc, replay, hit/miss learning feedback.

3. **Sum Sprint Party**
   - Multiple-choice answer tiles only.
   - Pictorial support visible first.
   - Streak/personal best, no countdown.

### MVP non-goals

- No full iPad UI port.
- No required Continuity Camera.
- No freeform text entry.
- No App Store assumptions; preserve personal/family distribution unless strategy changes.
- No timer-pressure modes for young profiles.
- No Room Quest companion networking in the first slice unless chosen as a separate spike.

---

## Technical architecture recommendation

### Add a tvOS target, not a separate repo

Mather already uses SwiftUI, Swift 6, XcodeGen, and a shared domain/service structure. Add a
second application target in `project.yml`:

- `Mather` remains iOS/iPadOS.
- `MatherTV` becomes tvOS.
- Shared code moves into platform-neutral groups/modules over time.

### Extract shared content and game logic

First extraction candidates:

- Memory deck/content models from `Features/Memory/MemoryView.swift`
- Gravity/angle pure physics helpers from `Features/GravityArtist/GravityArtistView.swift`
- Sum Sprint fact/problem generation from current engine files
- Shared theme tokens that are not touch-size-specific

### Keep platform-specific views separate

Use shared domain/content logic, but build tvOS-specific SwiftUI screens:

- `FeaturesTV/MemoryGallery/MemoryGalleryTVView.swift`
- `FeaturesTV/AngleArcade/AngleArcadeTVView.swift`
- `FeaturesTV/SumSprintParty/SumSprintPartyTVView.swift`
- `AppTV/MatherTVApp.swift`

Avoid a single view full of `#if os(tvOS)` branches except for tiny modifiers.

### Input abstraction

Introduce a small input intent layer for games:

- `moveLeft`
- `moveRight`
- `moveUp`
- `moveDown`
- `select`
- `pause`
- `repeatPrompt`

iOS touch, tvOS focus, Siri Remote, keyboard, and game controller can all map into the same
intent vocabulary where useful.

### Persistence

Do not share child progress blindly across platforms in the first prototype. Start with local
tvOS session summaries or no persistence. Later, evaluate CloudKit/App Group/parent export only
after the TV gameplay proves useful.

---

## Design rules for tvOS Mather

1. **Eight-foot legibility**
   - Big type, big art, fewer objects.
   - No dense parent-summary dashboards in child play.

2. **Focus is the cursor**
   - Every visible action must have a predictable focus path.
   - Use focus sections for non-adjacent controls.

3. **Remote-first, controller-better**
   - Siri Remote must play every MVP mode.
   - Controllers can add multiplayer and analog precision later.

4. **No worksheet TV**
   - The TV should never show a page of problems.
   - Every prompt should be a game state.

5. **Shared delight**
   - Build for "look at that!" moments: big animal reveal, rocket streak, arc replay, family turn.

6. **Companion only when it earns its cost**
   - iPhone/iPad handoff is powerful but should not be required for the first fun prototype.

---

## Research-backed ranking

| Rank | Candidate | Fun on TV | Learning value | Engineering risk | Recommendation |
| --- | --- | ---: | ---: | ---: | --- |
| 1 | Memory Gallery | High | High | Low-Med | Prototype first |
| 2 | Angle Arcade | Very high | High | Medium | Prototype second |
| 3 | Sum Sprint Party | Medium-High | High | Medium | Prototype third |
| 4 | Room Quest TV companion | Very high | High | High | Spike after MVP |
| 5 | Compass Angles TV | Medium | Medium | Medium | Fold into Angle Arcade |
| 6 | Rectangle Factory TV | Medium | High | Medium | Later |
| 7 | Symmetry Fold TV | Medium | Medium | Medium-High | Later redesign |
| 8 | Full VS1 port | Low-Med | High | High | Do not port directly |

---

## Proposed issue breakdown

### Issue A: tvOS feasibility spike

Goal:
- Add a minimal `MatherTV` target via XcodeGen.
- Launch a tvOS SwiftUI shell with one focusable menu.
- Validate build on `studio` with Xcode.

Acceptance:
- `xcodegen generate` succeeds.
- tvOS target builds.
- One root view runs in Apple TV simulator.
- No existing iOS target regression.

### Issue B: Extract Memory content model

Goal:
- Move Memory deck/content types out of `MemoryView.swift`.
- Keep iOS Memory behavior unchanged.
- Add unit tests for deck counts and duplicate identifiers/names where relevant.

Acceptance:
- Existing iOS Memory compiles.
- Shared content is platform-neutral.
- Tests cover deck availability for tvOS.

### Issue C: Memory Gallery TV prototype

Goal:
- Build the first playable tvOS mode.

Acceptance:
- Category shelf.
- Picture/name matching round.
- Focus/select interaction.
- Spoken prompt or accessible label.
- No timer.

### Issue D: Angle Arcade TV prototype

Goal:
- Reuse `GravityArtistPhysics` or equivalent pure helpers in a tvOS game.

Acceptance:
- D-pad angle/power control.
- Fire/replay loop.
- Prediction arc and actual arc.
- Difficulty with at least 3 target positions.

### Issue E: Sum Sprint Party TV prototype

Goal:
- Build a multiple-choice shared recall mode.

Acceptance:
- Fact prompt with pictorial support.
- Four answer tiles.
- Streak/personal-best only.
- Deterministic distractor generation tests.

### Issue F: Room Quest TV companion research spike

Goal:
- Choose a viable cross-device communication/continuity path.

Acceptance:
- Compare at least MultipeerConnectivity, CloudKit/shared store, local network, and tvOS
  Continuity Camera.
- Produce recommendation and minimal proof plan.

---

## Validation plan

### Product validation

- Put Memory Gallery on TV for one child session.
- Measure whether the child can play with only remote/select after a parent starts the round.
- Watch whether the TV creates shared attention or just turns into passive viewing.
- Compare engagement against iPad Memory for 5 minutes each.

### Technical validation

- Build on `studio` using current Xcode.
- Run Apple TV simulator smoke test.
- Verify focus traversal with Siri Remote simulator controls.
- Add screenshot/UI tests only after focus shell stabilizes.

### Design validation

- Test at couch distance.
- Check 1080p and 4K layout.
- Confirm text is not required for child comprehension.
- Confirm focus states are obvious without reading.

---

## Open questions

1. Should Mather TV be a separate app identity or an additional target under the same product family?
2. Is the first goal a family-only Apple TV build or eventual App Store-style compatibility?
3. Should Room Quest TV wait for Continuity Camera, or start with iPhone/iPad companion messages?
4. Which decks are safest for TV first: domestic animals/birds, or planets/vehicles with more visual drama?
5. Should game controller multiplayer be a v1 design constraint or a later enhancement?

---

## Sources

### Mather sources

- `README.md`
- `AGENTS.md`
- `wiki/Research/Math-App-Vision.md`
- `wiki/Research/Memory-Multi-Mix-Match.md`
- `wiki/Research/Sum-Sprint-Spaced-Repetition.md`
- `wiki/Research/Physics-Geometry-Sensor-Gameplay.md`
- `wiki/Research/Room-Quest-Sensor-Capabilities-and-Design-Direction.md`
- `wiki/Specs/Physics-Geometry-UX-Design.md`
- `wiki/Specs/Room-Quest-Sensor-Driven.md`
- `Features/Memory/MemoryView.swift`
- `Features/SumSprint/`
- `Features/AngleCannon/AngleCannonView.swift`
- `Features/GravityArtist/GravityArtistView.swift`
- `Features/RoomQuest/`
- `project.yml`

### Apple sources checked on 2026-06-20

- Apple Developer: tvOS overview - https://developer.apple.com/tvos/
- Apple Human Interface Guidelines: Designing for tvOS - https://developer.apple.com/design/human-interface-guidelines/designing-for-tvos
- Apple Human Interface Guidelines: Remotes - https://developer.apple.com/design/human-interface-guidelines/remotes
- Apple Developer: Support directional remotes in your tvOS app - https://developer.apple.com/news/?id=33cpm46r
- Apple Developer: Game Controller framework - https://developer.apple.com/documentation/gamecontroller/
- Apple Developer Archive: Controlling Input on tvOS - https://developer.apple.com/library/archive/documentation/ServicesDiscovery/Conceptual/GameControllerPG/ControllingInputontvOS/ControllingInputontvOS.html
- Apple Developer: The SwiftUI cookbook for focus - https://developer.apple.com/videos/play/wwdc2023/10162/
- Apple Developer: Direct and reflect focus in SwiftUI - https://developer.apple.com/videos/play/wwdc2021/10023/
- Apple Developer: Supporting Continuity Camera in your tvOS app - https://developer.apple.com/documentation/AVKit/supporting-continuity-camera-in-your-tvos-app
- Apple Developer: Discover Continuity Camera for tvOS - https://developer.apple.com/videos/play/wwdc2023/10256/
- Apple Developer: tvOS 26 Release Notes - https://developer.apple.com/documentation/tvos-release-notes/tvos-26-release-notes
