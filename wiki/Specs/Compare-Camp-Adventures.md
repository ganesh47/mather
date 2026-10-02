# Compare Camp adventures

Implemented scope: tvOS Compare Camp, personal/family distribution. Date: 2026-10-02.

## Experience

Choose one of 24 camps in six regions, then a trail and a quantity range. The six trails are Camp Adventure, Find More, Find Fewer, Make a Match, How Many Extra, and Number Signs. Little Steps uses 0-5; Growing Explorer uses 0-10; Big Adventure uses 0-20. This creates 432 camp/trail/size combinations without locking content behind performance.

The eight-stop adventure starts with two manipulable matching tasks, then picture comparisons for more/fewer, two symbolic comparisons, and transfer into another region. Difference and Number Signs practice also begin with manipulable matching. Every trail has a finite end, a celebration, replay with a changed seed, and a choice of another camp.

Focused trails retain their practice question while the representation progresses: early count/pair taps or building, pictured groups, explicit numerals and relation signs, then a new subject for transfer. Pictured evidence stays available as support during number discovery.

## Content inventory

| Region | Camps |
| --- | --- |
| Green Trail | Apple Orchard, Flower Garden, Leaf Trail, Sheep Meadow |
| Ocean Cove | Clownfish Reef, Goldfish Pond, Seahorse Bay, Angelfish Lagoon |
| Bird Grove | Macaw Canopy, Peafowl Garden, Flamingo Lake, Puffin Cliffs |
| Star Camp | Earth Workshop, Mars Workshop, Jupiter Workshop, Saturn Workshop |
| On the Move | Car Camp, Train Station, Boat Harbor, Airplane Field |
| Builder Valley | Excavator Hill, Bulldozer Trail, Dump Truck Quarry, Mixer Yard |

Planet objects are explicitly called models, avoiding an implication that there are many real Earths. Each displayed token is one consistent object tile. Scenery and guide illustrations are outside the counting evidence.

## Learning and interaction

- Quantity determines every correct relation and difference; truth is never entered separately from the counts.
- The generator includes empty groups and equal groups, rotates relation directions, avoids consecutive repeated pairs, and uses deterministic seeds for reproducible checks.
- Incorrect answers leave the question open. Counting, alignment and hints remain available; there is no next-stop action until solved.
- Build actions add or remove exactly one left-side item, bounded by the selected range. A check succeeds only when both groups match.
- Optional counting highlights one object per Select and stops at the actual quantity. Alignment makes matching and unmatched items visible.
- Spoken prompts and focused labels support pre-readers. Play/Pause repeats guidance for the current state, including a solved explanation. Narration stops on departure and yields to VoiceOver through the existing controller.
- No timer, punitive streak, or child-facing accuracy percentage. Reduce Motion disables optional visual transitions.

## Progress

The device-local passport records completed sessions once by UUID. It stores the camp, trail, quantity range, generator seed, completion date and support/first-attempt counts. The child sees exploration stickers rather than a mastery claim. An interrupted trail is not recorded. Passport data is versioned and checked when decoded.

Architecture: [ADR-0009](../ADRs/ADR-0009-compare-camp-adventures.md).

## Generated deliverables

- Eleven project-bound ImageGen assets: landscape, fox guide, badge, apple, flower, leaf, sheep, macaw, peafowl, flamingo, puffin.
- Six-page printable family kit: spoken-by-adult guide, eight mission cards, comparison mat, 40 token cards, and a 24-space passport.
- `output/compare-camp/content-manifest.json` provides the content inventory and generated asset hashes.
- `scripts/export_compare_camp_manifest.py` regenerates that inventory from the curated catalog.
- `scripts/generate_compare_camp_playkit.py` regenerates the printable companion from bundled app artwork.

## Validation

Domain checks cover content uniqueness, asset availability, quantity bounds, answer correctness, relation coverage, distractors, deterministic replay, retry/guarded progression, counting/build limits, finite completion and progress integrity. Persistence checks cover reload, duplicate recording and corrupt data recovery. tvOS UI checks cover directional focus, all region shelves, trail selection, build/count/help interactions, symbol/transfer stages, finish/replay/passport and Menu/PlayPause.

Native verification on 2026-10-02 passed 20 focused unit tests in four suites and all three Compare Camp remote UI tests. The challenge sweep checks 10,368 generated rounds across every camp, activity and range. Result bundles are saved locally in `.artifacts/CompareCampUnitAssetsFinal.xcresult` and `.artifacts/CompareCampVerified.xcresult`. A focused adventure rerun also passed after the final celebration inset and passport grammar fixes (`.artifacts/CompareCampFinalCelebration.xcresult`). The checked-in [audit](../Research/Compare-Camp-Overhaul-Audit.md) contains accepted before/after screenshots and their findings. The six-page printable was rendered and inspected page by page.

Simulator screenshots support layout and remote-flow verification. Couch-distance readability, Siri Remote hardware feel, narration intelligibility and VoiceOver behavior still merit a family device check; simulator evidence does not establish full accessibility compliance.
