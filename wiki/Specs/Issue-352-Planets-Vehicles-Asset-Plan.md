# Issue 352 — Planets + Vehicles Image Asset Plan

This records the completed project-owned asset import for upgrading the `planets` and `vehicles` Memory Match decks to image-backed cards. All current Planets and Vehicles cards now reference deterministic in-repo PNG assets, with provenance recorded in `Issue-352-Planets-Vehicles-Provenance.yml` and `MemoryDeck.imageAssetProvenance`.

Source-candidate and provenance checklist artifact: `wiki/Specs/Issue-352-Planets-Vehicles-Source-Candidates.md`.

## Asset naming

- Vehicles: `MemoryVehicle<Car|Bus|Train|Plane|Boat|Bike|Truck|Tractor|Helicopter|Rocket|Scooter|Taxi>`
- Planets: `MemoryPlanet<Mercury|Venus|Earth|Mars|Jupiter|Saturn|Uranus|Neptune>`

The same names are captured in `MemoryDeck.vehicleImageAssetPlan` and `MemoryDeck.planetImageAssetPlan` so tests guard coverage and imported asset status.

## Source rules

1. Use public-domain, CC0, project-owned, or generated-and-approved assets only.
2. Record provenance next to the imported images before switching deck cards from `.emoji`/`.text` to `.asset`.
3. Normalize to a square crop with the subject centered and recognizable at small card sizes.
4. Avoid visible license plates, people as the main subject, brand logos, watermarks, stock-photo marks, or misleading fantasy planet art.
5. This completed import uses project-owned deterministic artwork only; no third-party/web image binaries were imported.

## Import checklist

For each planned asset:

- source URL / creator / license recorded
- reuse is compatible with the app/repo
- square crop exported and checked at Memory card size
- image added under `App/Assets.xcassets/<assetName>.imageset`
- matching card switched to `.asset(assetName)`
- tests updated from plan coverage to actual asset reference coverage

## Current status

- Planets: 8/8 cards use image-backed `MemoryPlanet...` assets.
- Vehicles: 12/12 cards use image-backed `MemoryVehicle...` assets.
- `MemoryDeck.vehicleImageAssetPlan` and `MemoryDeck.planetImageAssetPlan` mark every current card `readyForAssetImport` with project-owned provenance.
- The imported images are project-owned deterministic drawings with provenance recorded in `Issue-352-Planets-Vehicles-Provenance.yml` and in `MemoryDeck.imageAssetProvenance`.
