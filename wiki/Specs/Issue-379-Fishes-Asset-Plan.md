# Issue 379 - Fishes Image Asset Plan

This is the safe pre-import plan for upgrading the `fishes` Memory Match deck to image-backed cards. It intentionally does **not** import images yet; every fish image still needs a vetted source, license/reuse check, and provenance note before the deck can reference `.asset(...)`.

## Asset naming

Fish assets should use `MemoryFish<Name>`:

- `MemoryFishClownfish`
- `MemoryFishGoldfish`
- `MemoryFishBetta`
- `MemoryFishAngelfish`
- `MemoryFishCatfish`
- `MemoryFishSwordtail`
- `MemoryFishTuna`
- `MemoryFishSeahorse`

The same planned names are captured in `MemoryDeck.fishImageAssetPlan` so tests can guard coverage before asset import.

## Source rules before import

1. Use public-domain, CC0, project-owned, or generated-and-approved assets only.
2. Record provenance next to imported images before switching cards from `.text(...)` to `.asset(...)`.
3. Prefer uncluttered side/profile views where each fish's recognition cue is visible at card size.
4. Avoid watermarks, aquarium labels, visible people, fishing/deck scenes, brand marks, and images where the animal is tiny or ambiguous.

## Import checklist

For each planned asset:

- source URL / creator / license recorded
- reuse is compatible with the app/repo
- square crop exported and checked at Memory card size
- image added under `App/Assets.xcassets/<assetName>.imageset`
- matching card switched to `.asset(assetName)`
- tests updated from plan coverage to actual asset reference coverage

## Current status

- Fishes: 8/8 cards have planned asset names and sourcing prompts.
- No unvetted images were imported in this slice.
