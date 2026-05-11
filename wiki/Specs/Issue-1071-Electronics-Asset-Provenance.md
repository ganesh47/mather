# Issue 1071 Electronics Asset Provenance

Circuit Spark uses first-party vector artwork so electronics gameplay cards do not depend on emoji rendering.

## Asset set

The checked-in asset catalog images are SVG sources stored in `App/Assets.xcassets/*Electronics*.imageset` with vector preservation enabled:

- `ElectronicsBattery` — pretend screen battery
- `ElectronicsBulb` — light bulb
- `ElectronicsWire` — curved wire path
- `ElectronicsSwitch` — open/close switch
- `ElectronicsOpenCircuit` — loop with a gap
- `ElectronicsClosedCircuit` — complete loop with lit bulb
- `ElectronicsSafeCircuit` — safe pretend screen circuit
- `ElectronicsOutletSafety` — outlet with do-not-touch safety mark

## Reproducible source prompt

Use this prompt to regenerate matching vector-style source art if the set needs to be refreshed:

> Create a consistent set of kid-friendly flat vector SVG illustrations for an iOS learning app called Mather. Use a rounded 256×256 viewBox, pale blue/white background, thick navy rounded outlines, soft fills, and no text. Keep the concepts elementary and safe: pretend battery, bulb, wire, switch, open circuit with a gap, closed circuit with lit bulb, safe pretend screen circuit with a check, and outlet safety with a clear do-not-touch mark. Avoid photorealism, brand marks, scary danger language, sparks, shocks, flames, or real-world wiring instructions.

## Implementation notes

- The SVGs are hand-authored first-party assets based on the prompt above; no third-party source art is included.
- `GameplayThreadCatalog.electronics` maps every electronics entity and property to `visualAssetName` so SwiftUI `Image(assetName)` renders the illustration before any fallback text.
- Emoji `visualKey` values were removed from the electronics gameplay cards; VoiceOver labels remain derived from card titles and subtitles.
