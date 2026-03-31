# ADR-0001: Record Architecture Decisions

**Date**: 2026-03-31
**Status**: Accepted
**Deciders**: @ganesh47

## Context

We need a way to capture why significant technical decisions were made, not just what was decided. Without this, future contributors (or future us) have no context for why the codebase looks the way it does, leading to re-litigation of settled decisions or silent erosion of architectural intent.

## Decision

Use lightweight Architecture Decision Records (ADRs) stored in `wiki/ADRs/` in the repository. Each ADR is a markdown file named `ADR-<NNNN>-<short-title>.md`. ADRs are immutable once accepted — if a decision is reversed, a new ADR supersedes the old one rather than editing it.

## Rationale

- ADRs are versioned alongside the code in git
- They're short enough to actually write and read
- The supersede pattern preserves the history of why we changed our minds

## Alternatives Considered

- **Confluence / Notion**: not co-located with code; requires separate login
- **PR description only**: lost in PR history, not discoverable
- **No documentation**: leads to mystery architecture

## Consequences

- Positive: decisions are discoverable and contextualised
- Positive: onboarding is faster
- Negative: requires discipline to write an ADR when making significant decisions
- Neutral: minor overhead per architectural decision
