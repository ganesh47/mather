# ADR-0018: World Quest offline geography and remote navigation

- Status: Accepted for implementation
- Date: 2026-10-18

## Context

World Quest teaches country location from a shown and spoken name, first on tvOS. Existing country silhouettes are illustrative, not suitable for geographic answer truth. The family chose country focus, starter plus full-world coverage, 20 seconds per country, and India-viewpoint boundaries.

## Decision

Bundle a reproducibly generated, pinned Natural Earth 1:10m India-viewpoint map. Maintain an explicit 195-entry roster (193 UN members, Palestine, and Vatican City for the Holy See). Geographic features outside the roster remain background context. Preserve polygon holes, islands, and antimeridian cuts. Simplify shared edges together and project to Equal Earth. Tiny countries receive distinct location markers, never enlarged borders.

Use a shared deterministic catalog/session engine with an injected monotonic clock and seeded random generator. Views own only focus, viewport, narration, and animation. Directional navigation follows geographic anchors, with a reachability check for every pack. Country IDs determine answers. Names of focused countries are revealed in Explore, but not while answering a quiz, including VoiceOver. Timers pause during prompt speech and app interruptions; returning to the foreground requires explicit resume.

The math CPA sequence is adapted deliberately: concrete remote exploration of named locations, pictorial recognition on an unlabeled map, name-to-location recall, and transfer from regional practice to whole-world questions. Do not force math SliceStage transitions into this geography game.

Completed sessions and passport stamps use versioned local UserDefaults, following Compare Camp. No unfinished-session resume, downloads, accounts, or cross-device sync. worldQuestEnabled allows rollback through the standard feature.worldQuestEnabled preference/launch argument. It defaults on for the requested family TestFlight pilot; physical-device acceptance remains part of that pilot.

## Consequences

Map provenance and boundary viewpoint are visible in parent information. The chosen viewpoint is a convention, not a claim of universal agreement. Geometry is a general-purpose educational map, not survey data. Geometry generation uses pinned Python dependencies; gameplay has no third-party runtime dependency or network requirement. Shared models compile into iOS for unit tests, while only tvOS exposes the new game.
