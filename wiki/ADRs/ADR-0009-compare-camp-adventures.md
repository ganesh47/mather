# ADR-0009: Compare Camp adventures and local exploration passport

- Status: Accepted for implementation
- Date: 2026-10-02

## Context

Compare Camp on tvOS contains six fixed lantern comparisons. The view owns both question truth and session mutation. Incorrect answers immediately end the question, and replay has no meaningful variety or natural stopping point. The requested overhaul needs many content choices without multiplying bespoke screens.

## Decision

Use a shared, deterministic `CompareCampRound` generator and a `@MainActor @Observable` `CompareCampEngine`. Quantities determine answer truth. A curated catalog provides 24 camps in six regions; activities and quantity ranges compose with these camps. Keep the TV interface and remote navigation in `AppTV`.

An adventure has eight stops: manipulate groups, compare pictures, compare symbols, then transfer to another context. Focused trails practice the same concepts. Incorrect responses leave a question open; counting and one-to-one alignment supply optional support. Build controls are bounded and use the engine rather than view-owned domain state.

Save completed sessions in a versioned, local UserDefaults passport. The passport records exploration and support use, rather than claiming mastery or resetting a child's streak after a mistake. Record each completion UUID once. Keep asset provenance and printable family activities alongside the implementation.

## Consequences

- Content and answer validity can be tested independently of tvOS focus behavior.
- New camps can reuse the activity loop and narration contract.
- Exact-count groups use isolated, consistently sized objects; decorative art stays separate.
- The passport is device-local and stores completed sessions only; it does not resume an unfinished question or synchronize between devices.
- Simulator UI tests must separately verify focus, retries, narration controls, finite completion, and reentry.
