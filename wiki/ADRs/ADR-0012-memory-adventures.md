# ADR-0012: Shared Memory adventures and pairing feedback

- Status: Accepted for implementation
- Date: 2026-10-02

## Context

The iOS and tvOS Memory games share a card catalog but own separate interaction state. The requested richer adventures need consistent picture pairing, useful hints, and feedback that cannot mutate a replacement round.

## Decision

Curate three bundled adventures from stable existing card IDs: Busy Builders, Rescue Crew, and Space Trip. Each adventure supplies scene artwork, a spoken introduction, celebration, and a short optional physical observation activity. Existing full decks remain available.

Use a shared `@MainActor @Observable MemoryPairingEngine` for picture pairs or picture-to-name pairs. Views choose and cap the round's animals, render platform-specific controls, and provide speech and haptics. The engine owns selection, matches, timed feedback, and hint state. It deduplicates identities and derives completion from the actual dealt pairs, including smaller adventure pools. It accepts preprocessed country clues without depending on their presentation rules.

Cancel feedback and advance the round identity whenever a round is replaced or abandoned. Delayed feedback checks that identity before applying changes. Hints briefly identify one available pair and never count as a successful match.

## Consequences

- Both platforms can use the same tested interaction rules while preserving touch and remote navigation.
- Bundled images and facts remain available offline; adventure artwork is decorative and does not replace factual card images.
- No persistence schema or downloadable content format changes are required.
- Platform views must respect hidden-card rules and clean up pending feedback on disappearance.
