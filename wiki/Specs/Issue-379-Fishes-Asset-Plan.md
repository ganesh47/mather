# Issue 379 - Fishes Image Asset Plan

This records the project-owned import used to upgrade the `fishes` Memory Match deck to image-backed cards. The imported fish assets are deterministic drawings created in-repo; no web images, screenshots, or third-party source material were used.

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

## Source rules

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

## Imported provenance

All eight assets were generated on 2026-04-27 by OpenAI Codex for `ganesh47/mather` issue #379. Each image is a project-owned deterministic 512x512 transparent PNG created with Pillow vector drawing commands. There is no third-party source material, no logo or endorsement risk, no people/privacy risk, and each image was checked for child-card legibility.

| Card ID | Asset | SHA-256 |
| --- | --- | --- |
| `fish-clownfish` | `MemoryFishClownfish` | `994003f9911cd64dae9b0b788918a64ca4bf0a9ca8c2889ecb9dfca6903d9c6b` |
| `fish-goldfish` | `MemoryFishGoldfish` | `03e5d0f461f714cff979eba3c154b3f1012f8880c88fca509cdabeb74ddc4dde` |
| `fish-betta` | `MemoryFishBetta` | `32da3532b489e9c7d20394cec5b99897c2011cc2a92809ced0b249d74e1aa200` |
| `fish-angelfish` | `MemoryFishAngelfish` | `8da0cff35ded5222747f099b3ca785719c9700c17514aa2f69fd3ff5b5b904c6` |
| `fish-catfish` | `MemoryFishCatfish` | `e2d712233b9fd1d4f5fa5d3c167329d19784fb72784ce062ee8231cc7e19a1fe` |
| `fish-swordtail` | `MemoryFishSwordtail` | `decdde0bb9874d8d7b5f3c07c544f342dd339c69c42f135eee8f134a1ea18a19` |
| `fish-tuna` | `MemoryFishTuna` | `d9716931aba86201236c724311c5b8fae07b6dca705ca059cd9c7247b33b67a3` |
| `fish-seahorse` | `MemoryFishSeahorse` | `90a58259c3a44be96017c86b1d4a165fc507ba24d9baf2c53b9dad23c1ff50a0` |

## Current status

- Fishes: 8/8 cards use image-backed `MemoryFish...` assets.
- The imported images are project-owned generated drawings with provenance recorded here and in `MemoryDeck.imageAssetProvenance`.
