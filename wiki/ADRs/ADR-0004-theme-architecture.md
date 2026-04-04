# ADR-0004: VS1 Theme Architecture

**Date:** 2026-04-04
**Status:** Accepted
**Context:** VS1 Theme Framework (issues #91–#100, PRs #102–#110)

---

## Context

Issue #79 proposed a vehicle-first playful theme to increase engagement for 5-6 year olds. The implementation needed to:

1. Let a parent choose a theme before a session
2. Keep the theme stable for the duration of the session
3. Not change any CPA stage rules, scoring, or engine logic
4. Be testable with arbitrary theme implementations in unit tests

---

## Decision

**Theme as a session-scoped value type, resolved once at `startSession()`.**

`SliceTheme` is a protocol (not a class, not `@Observable`). Conforming types are value structs. `VerticalSliceEngine` holds `private(set) var activeTheme: any SliceTheme`, which is frozen at `startSession()` by reading `featureFlags.selectedThemeId`.

Key properties:

- `activeTheme` never changes between `startSession()` and `endSession()` — the child cannot switch themes mid-session
- The engine init accepts `activeTheme: (any SliceTheme)? = nil` — when non-nil, `startSession()` preserves the injected value and does not override from flags. This lets unit tests inject arbitrary themes (e.g. a `RocketTheme` fixture) without registering them in `FeatureFlagService`
- `SliceTheme` lives in `Domain/` because it is domain logic (vocabulary, counter kind, CPA prompt routing), not a presentation concern

---

## Alternatives considered

### Global `@Observable` theme service
Rejected. A globally observable theme would add SwiftUI observation overhead for a value that never changes during a session. It would also allow mid-session theme changes, which would confuse a child mid-task.

### Theme as a `@State` variable in views
Rejected. Domain vocabulary (speech prompts, success phrases) belongs in the engine, not in views. A view-scoped theme could not be used for `SpeechService` calls.

### Theme embedded in `SessionConfig`
Considered. `SliceConfig` already holds `audioEnabled` and `deterministicMode`. However, the theme is a richer object (a protocol value, not a plain Bool/Int), and would require `SliceConfig` to import domain types it doesn't currently need. Keeping it on the engine is simpler.

---

## Consequences

- All stage prompts, success messages, and session lifecycle strings route through `activeTheme` — hardcoded strings are gone from the engine
- `ClassicTheme` returns the same strings that were hardcoded before — zero regression risk
- Adding a new theme requires: new struct, one `startSession()` line, one UI card — no engine changes
- Telemetry records `theme_id` in both `session_start` and `session_end` JSONL events for future segmentation
- `CounterView` renders either a `Circle` or SF Symbol based on `theme.counterKind`, and is shared across `ConcreteBuildView`, `SplitView`, and `TransferCheckView` — consistent counter identity throughout a session

---

## Pedagogical rationale

See `wiki/Research/Playful-Themes-for-VS1.md` and issue #79 for the full research grounding. Summary:

- Interest-driven learning (Hidi & Renninger): a vehicle theme triggers situational interest in 5-6 year olds, keeping them on-task through the full CPA loop
- Self-Determination Theory: theme picker satisfies autonomy and relatedness needs
- Subitising is structure-dependent, not shape-dependent (Clements, 2002): replacing circles with car icons in the same 2×5 grid preserves all subitising benefits
