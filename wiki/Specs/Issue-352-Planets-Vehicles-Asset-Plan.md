# Issue 352 — Planets + Vehicles Image Asset Plan

This is the safe pre-import plan for upgrading the `planets` and `vehicles` Memory Match decks to image-backed cards. It intentionally does **not** import images yet; every asset still needs a vetted source, license/reuse check, and provenance note before it can be referenced by `MemoryAnimal.picture`.

## Asset naming

- Vehicles: `MemoryVehicle<Car|Bus|Train|Plane|Boat|Bike|Truck|Tractor|Helicopter|Rocket|Scooter|Taxi>`
- Planets: `MemoryPlanet<Mercury|Venus|Earth|Mars|Jupiter|Saturn|Uranus|Neptune>`

The same planned names are captured in `MemoryDeck.vehicleImageAssetPlan` and `MemoryDeck.planetImageAssetPlan` so tests can guard coverage before asset import.

## Source rules before import

1. Prefer public-domain or explicitly reusable educational sources.
   - Planets: NASA/JPL/USGS public-domain imagery is the preferred first pass, with exact source URLs recorded per asset.
   - Vehicles: use public-domain, CC0, project-owned, or generated-and-approved assets only; avoid trademark-heavy/logo-forward photos.
2. Record provenance next to the imported images before switching deck cards from `.emoji`/`.text` to `.asset`.
3. Normalize to a square crop with the subject centered and recognizable at small card sizes.
4. Avoid visible license plates, people as the main subject, brand logos, or misleading fantasy planet art.

## Import checklist

For each planned asset:

- source URL / creator / license recorded
- reuse is compatible with the app/repo
- square crop exported and checked at Memory card size
- image added under `App/Assets.xcassets/<assetName>.imageset`
- matching card switched to `.asset(assetName)`
- tests updated from plan coverage to actual asset reference coverage

## Current status

- Vehicles: 12/12 cards have planned asset names and sourcing prompts.
- Planets: 8/8 cards have planned asset names and sourcing prompts.
- No unvetted images were imported in this slice.
