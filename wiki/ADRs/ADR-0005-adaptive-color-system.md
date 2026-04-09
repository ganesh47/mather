# ADR-0005: Adaptive Color System — Light/Dark Mode via Asset Catalogue Semantic Tokens

**Date:** 2026-04-09
**Status:** Accepted
**Context:** TestFlight build 19 feedback (issue #136 enrichment) noted that the app never adapts to system dark mode. v0.1.11 locked the app to light mode (`UIUserInterfaceStyle = Light` in `Info.plist`) as a short-term fix for low-contrast text issues (#128, #129, #130). This ADR decides the long-term approach.

---

## Context

### Current state

`MatherTheme` (`Shared/MatherTheme.swift`) defines eight hardcoded `Color(red:green:blue:)` values:

| Token | Light value | Role |
|---|---|---|
| `background` | Pale cream `#F7F2E3` | App/screen background |
| `card` | White `#FFFFFF` | CardSurface fill |
| `ink` | Near-black `#242931` | Primary text |
| `cardSubtitle` | `ink` at 65% | Secondary text on white card |
| `accent` | Vivid emerald `#17B571` | Primary action, success |
| `warm` | Vivid amber `#FF9E12` | Counters row 1, warm states |
| `danger` | Red `#E13B33` | Destructive actions |
| `softBlue` | Sky blue `#38ABFB` | Info, secondary buttons |
| `coral` | Coral `#FA6154` | Celebration |

A second palette (`VS1Palette` in `VS1SharedUI.swift`) duplicates some of these with different values for VS1-specific UI.

`CardSurface` uses `MatherTheme.card` (pure white) as its background. All colours are single-appearance — no dark variants exist anywhere. The app is currently force-locked to light mode to prevent system dark mode from inverting the warm cream palette in unexpected ways.

### Why dark mode matters

The target device is an iPad shared across a family. Parents often use devices in dark mode at night. A force-light app looks jarring in that context, and the tester explicitly asked for system theme syncing.

---

## Options Evaluated

### Option A — Third-party design system library

Evaluated: Orbit (Kiwi.com), DSKit, Orange OUDS, Microsoft Fluent UI, Material Design SwiftUI.

**Rejected.** Reasons:
- **Orbit** is archived (July 2025) — no ongoing iOS compatibility maintenance.
- **DSKit / OUDS / Fluent** impose their own visual component language. Mather's warm cream + vivid emerald + amber palette is carefully tuned for a 5-year-old's perceptual needs; overriding it with a corporate design system's defaults would require re-customising every token anyway, gaining nothing.
- **Material Design** aesthetics are demonstrably wrong for this age group (cool greys, dense information hierarchy, corporate affordances).
- Adding a Swift Package dependency for color tokens alone adds maintenance overhead and version-lock risk for a personal app with no team. The maintenance burden is not justified.

**ColorTokensKit-Swift** (LCH-based token system) is interesting but adopts its own naming conventions and requires building new components on top. For an app where the components already exist, it adds friction rather than removing it.

### Option B — `@Environment(\.colorScheme)` inline in views

Each view checks `colorScheme` and returns different `Color` values conditionally. Works without infrastructure but leads to duplicated logic across 14+ views and makes the palette impossible to audit in one place.

**Rejected.** Violates the single-responsibility principle already established by `MatherTheme` as the canonical color source.

### Option C — Asset catalogue named color sets (chosen)

Define each `MatherTheme` color as a named color set in `App/Assets.xcassets` with **Any** (light) and **Dark** appearance variants. Replace `Color(red:green:blue:)` calls in `MatherTheme` with `Color("MatherBackground")` etc. SwiftUI's color pipeline resolves the correct variant automatically based on `@Environment(\.colorScheme)`.

**Chosen.** Reasons:
- Zero new dependencies.
- Single source of truth: palette lives in the asset catalogue; `MatherTheme` becomes a thin alias layer.
- Dark variants are editable without code changes — Xcode's color picker makes it trivial to iterate visually.
- Xcode 15+ generates `ColorResource` static properties; `Color(.matherBackground)` is type-safe.
- Removing `UIUserInterfaceStyle = Light` from `Info.plist` is all that's needed to re-enable system adaptation once the catalogue variants exist.
- Fully compatible with Swift 6 strict concurrency (no async color loading, no `@Observable` overhead).

---

## Decision

**Use the iOS asset catalogue with semantic named color sets.**

### Token naming convention

All tokens are prefixed `Mather` to avoid collision with system names:

| Asset name | Light value | Dark value | Semantic role |
|---|---|---|---|
| `MatherBackground` | `#F7F2E3` (cream) | `#1A1814` (warm near-black) | Screen/app background |
| `MatherCard` | `#FFFFFF` | `#2A2620` (warm dark grey) | CardSurface fill |
| `MatherInk` | `#242931` | `#F0EBE0` (warm off-white) | Primary text |
| `MatherCardSubtitle` | `ink` 65% | `ink` 70% (lighter for dark bg) | Secondary text on card |
| `MatherAccent` | `#17B571` (emerald) | `#1FD080` (slightly lighter) | Primary action, success |
| `MatherWarm` | `#FF9E12` (amber) | `#FFB340` (slightly lighter) | Counters row 1, warm states |
| `MatherDanger` | `#E13B33` | `#FF5C54` (slightly lighter) | Destructive actions |
| `MatherSoftBlue` | `#38ABFB` | `#52B8FF` (slightly lighter) | Info, secondary buttons |
| `MatherCoral` | `#FA6154` | `#FF7A6F` (slightly lighter) | Celebration |

Dark background rationale: a **warm near-black** (`#1A1814`) rather than a cool system grey preserves the app's identity and prevents the palette from feeling cold and clinical. The vivid accent colours (emerald, amber, blue) are slightly lightened for dark backgrounds to maintain the same perceived luminance and contrast ratio against the darker surface.

`VS1Palette` is a second independent palette used in some VS1 layout containers. It should be consolidated into `MatherTheme` during this migration — the duplication is a historical artefact, not intentional.

### Code changes

**`Shared/MatherTheme.swift`** — replace literals with asset references:
```swift
enum MatherTheme {
    static let background   = Color("MatherBackground")
    static let card         = Color("MatherCard")
    static let ink          = Color("MatherInk")
    static let cardSubtitle = Color("MatherCardSubtitle")
    static let accent       = Color("MatherAccent")
    static let warm         = Color("MatherWarm")
    static let danger       = Color("MatherDanger")
    static let softBlue     = Color("MatherSoftBlue")
    static let coral        = Color("MatherCoral")
}
```

**`App/Info.plist`** — remove:
```xml
<key>UIUserInterfaceStyle</key>
<string>Light</string>
```

**`Features/VerticalSlice1/VS1SharedUI.swift`** — remove `VS1Palette` entirely; update all callsites to use the equivalent `MatherTheme` token.

**`App/Assets.xcassets`** — add one `.colorset` per token with `Any` and `Dark` appearance variants.

### Shadow adaptation

`CardSurface` uses `.shadow(color: .black.opacity(0.06), ...)`. On dark backgrounds, black shadows have near-zero visual effect. Add a `MatherCardShadow` token:
- Light: `#000000` at 6% opacity
- Dark: `#000000` at 20% opacity (stronger contrast needed against a dark card surface)

### What does NOT change

- `SliceTheme` protocol and `ClassicTheme` / `VehicleTheme` — these provide *copy and counter identity*, not palette colours. They are unaffected.
- `CounterView`, `ConcreteBuildView`, `TransferCheckView` — counter fill colours come from `MatherTheme.warm` / `MatherTheme.accent` which will auto-adapt via the new tokens.
- The in-session vehicle theme picker — `selectedThemeId` in `FeatureFlagService` is orthogonal.

---

## Consequences

- The app follows system dark/light mode automatically after `UIUserInterfaceStyle = Light` is removed.
- The warm identity of the app is preserved in dark mode via warm near-black backgrounds rather than cool system greys.
- Vivid accent colours retain sufficient contrast against both background tones — WCAG AA targets can be verified per-token with Xcode's built-in contrast checker.
- `VS1Palette` duplication is eliminated, reducing the palette surface to a single place.
- No new Swift Package dependencies.
- Iterating the dark palette is a Xcode asset catalogue edit — no code change, no PR needed for colour tweaks.
- Unit tests that compare `Color` values directly may need updating (though the current test suite does not do this — the `cardSubtitleIsDefinedAndNonTransparent` test compiles the token only, so it is unaffected).

---

## Implementation sequence

This is a visual change spanning all views — it should be done as a single PR to avoid a half-migrated state visible in CI screenshots.

1. Add all 10 `.colorset` files to `App/Assets.xcassets` (light + dark variants)
2. Update `MatherTheme.swift` to use `Color("...")` references
3. Remove `VS1Palette` from `VS1SharedUI.swift`; update callsites
4. Update `CardSurface` shadow to use `MatherCardShadow`
5. Remove `UIUserInterfaceStyle = Light` from `Info.plist`
6. Run CI — screenshot artifacts will show both appearances (light is default simulator)
7. Manual on-device check with system dark mode ON

Estimated scope: ~6 files changed, no logic changes.
