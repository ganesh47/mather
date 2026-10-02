# ADR-0010: Child-scoped learning evidence and short iOS quests

Status: Accepted — implementation of the user-approved iOS enrichment plan.

## Context

The iOS audit found that flashcard exposure was recorded as independent success,
stage totals were attributed to arbitrary items, lab progress crossed profiles,
and guided paths did not consistently return or finish. The first rollout targets
ages 5–7, learning through play, and Numbers, Shapes, Water Cycle, and Circuit Spark.

## Decision

Record actual item attempts separately from exposure and completion. Preserve
response, concept/property identity, assistance, session, and content version.
Derive presentation totals from attempts, and require actual tasks for transfer.
Use recent independent evidence for review confidence; historical errors must not
permanently prevent recovery. Help must provide a scaffold without reward penalties.

Resolve the selected child before loading guided progress. Carry launch context
and return destination through activities. Persist in-stage checkpoints by child;
keep legacy aggregate scores as historical activity without inventing evidence.
Do not assign legacy global lane confidence to individual children.

Build short concrete→pictorial→abstract→transfer quests for the four pilots.
Use narrated instructions, large touch targets, recoverable mistakes, and a clear
finish. Direct games remain available; sensor concepts receive touch alternatives.

The public content repository gains a separate versioned iOS catalog. Keep the
TV schema-1 feed compatible. Validate before caching, activate between sessions,
and keep bundled/last-valid offline fallback. Never execute downloaded code.

## Consequences and validation

The existing SwiftUI/@Observable, SwiftData, SpeechService, and JSONL architecture
is retained. Migration is conservative: legacy history remains readable and new
independent confidence begins unknown. Focused tests cover real attribution,
profile isolation, exact resume, guided routing, fair answers, bounded games, and
content fallback. Simulator checks are supplemented by family device validation;
learning outcomes are not claimed from completion counts.

Implementation is split into focused changes; any branch approaching two days
must be reviewed and split rather than held as a release branch.
