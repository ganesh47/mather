# VS1 Theme Framework

**Status:** Implemented (PRs #102–#110)
**Milestone:** VS1 Theme Framework (#2)

---

## Overview

The VS1 theme framework lets a parent select a visual and vocabulary theme for a session before it starts. The first content pack is **Vehicles** — generated local vehicle assets with SF Symbol fallback and vehicle/worksite vocabulary replace the default abstract circles and neutral prompts.

Themes are a purely additive layer. The CPA learning loop, stage rules, equation logic, and scoring are completely unchanged.

---

## Protocol

`SliceTheme` is defined in `Domain/SliceTheme.swift`:

```swift
protocol SliceTheme {
    var counterKind: CounterKind { get }
    var celebrationEmoji: String { get }

    func concretePrompt(target: Int) -> String
    func pictorialPrompt(target: Int) -> String
    func abstractPrompt() -> String
    func transferPrompt(decompositionA: Int, decompositionB: Int) -> String
    func stageSuccessPhrase(for stage: SliceStage, target: Int) -> String
    func sessionIntroPhrase() -> String
    func sessionEndPhrase() -> String
    func sessionStartFeedback() -> String
}
```

`CounterKind` controls rendering:

```swift
enum CounterKind: Equatable {
    case circle                                      // filled/empty circle (ClassicTheme)
    case vehicle(symbolName: String, assetName: String?) // local asset with SF Symbol fallback
}
```

---

## Session lifecycle

1. **SessionConfigView** — parent taps a theme card → sets `featureFlags.selectedThemeId`
2. **startSession()** — engine reads `selectedThemeId`, resolves `ClassicTheme` or `VehicleTheme`, stores as `activeTheme`
3. **During session** — `activeTheme` is frozen (never changes mid-session)
4. **Views** — `ConcreteBuildView`, `SplitView`, `TransferCheckView` all receive `theme: any SliceTheme` and pass it to `CounterView`
5. **Speech** — `promptForCurrentStage()`, `successMessage()`, `startSession()`, `endSession()` all delegate to `activeTheme`

---

## Available themes

| ID | Struct | Counter | Emoji | Intro phrase |
|---|---|---|---|---|
| `classic` | `ClassicTheme` | Circle | ⭐️ | "Let's make and break numbers to ten." |
| `vehicle` | `VehicleTheme` | Generated vehicle asset with SF Symbol fallback | 🚗 / per-vehicle | Per-problem vehicle/worksite intro |

---

## Vehicle asset pool and randomization

Vehicle sessions use `VehicleSpec.pool` one spec per problem, preserving a stable noun/image/prompt within that problem. In test mode the pool order is deterministic for screenshot and unit-test stability. In normal play the pool is shuffled per session and avoids starting with the default car, so build-58-style sessions do not always open on repeated car counters.

Issue #750 added local generated 512×512 transparent PNG counter assets for car, pickup truck, bulldozer, dump truck, cement mixer, and mining haul truck. Provenance is recorded in `wiki/Specs/Issue-750-VS1-Vehicle-Counter-Provenance.yml`; assets without a local PNG continue to use their SF Symbol fallback.

## CounterView

`Features/VerticalSlice1/CounterView.swift` — renders a single ten-frame cell.

```swift
CounterView(
    index: Int,           // 0-based position in the grid
    filled: Bool,         // whether this counter is active
    theme: any SliceTheme,
    overrideColor: Color? = nil  // bucket colour for SplitView / TransferView
)
```

For the two-tone ten-frame: index 0–4 → warm amber, index 5–9 → vivid accent.
`overrideColor` is used by SplitView and TransferCheckView where each bucket has its own palette colour.

---

## Subitising preservation

Replacing circles with generated vehicle assets or SF Symbols preserves all subitising benefits. Subitising depends on **spatial arrangement**, not object shape (Clements, 2002). The 2×5 ten-frame grid structure is invariant across themes. A child still instantly reads "a full top row of 5 plus 2 in the bottom row = 7" regardless of the counter shape.

---

## Adding a new theme

1. Create `Domain/MyTheme.swift` conforming to `SliceTheme`
2. Register its ID in `startSession()` in `VerticalSliceEngine.swift`
3. Add a card to `themeOptions` in `SessionConfigView.swift`
4. Add vocabulary tests in `ThemeTests.swift`

No changes to `CounterKind`, `SliceStateMachine`, or any engine logic are required for a theme that uses an existing vehicle asset/SF Symbol counter path.

To add a new counter shape, extend `CounterKind` and handle the new case in `CounterView.counterShape`.
