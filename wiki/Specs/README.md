# Feature Specs

Specifications for features in Mather. Each spec is linked to a GitHub issue labelled `spec`.

## Status Legend

| Label | Meaning |
|---|---|
| `spec:draft` | Being written, not ready for review |
| `spec:review` | Ready for team review |
| `spec:approved` | Approved — ready for implementation issues |
| `spec:implemented` | All implementation issues closed |

## Index

| Feature | Issue | Status |
|---|---|---|
| [VS1-Make-and-Break-to-10](VS1-Make-and-Break-to-10.md) | #10 | implemented |
| [VS1-Complement-Match-Finale](VS1-Complement-Match-Finale.md) | [#137](https://github.com/ganesh47/mather/issues/137) | draft |
| [Sum-Sprint](Sum-Sprint.md) | [#179](https://github.com/ganesh47/mather/issues/179) | draft |
| [Room-Quest-Reference-Capture](Room-Quest-Reference-Capture.md) | [#182](https://github.com/ganesh47/mather/issues/182) | draft |
| [Memory-Ask-About-This-Card](Memory-Ask-About-This-Card.md) | [#380](https://github.com/ganesh47/mather/issues/380) | draft |
| [Sum-Sprint](Sum-Sprint.md) | [#179](https://github.com/ganesh47/mather/issues/179) | draft |

---

## Spec Template

```
# Spec: <Feature Name>

**Issue**: #<n>
**Status**: draft | review | approved | implemented
**Author**: @<handle>
**Date**: YYYY-MM-DD

## Overview
One paragraph: what this feature does and why it exists.

## User Stories
- As a <user>, I want to <action> so that <outcome>

## Acceptance Criteria
- [ ] ...

## Design

### SwiftUI Views
List the views involved and their responsibilities.

### Data Model
Key types, their properties, relationships.

### Navigation
How the user reaches this feature; how they exit.

### State Management
Where state lives, how it flows.

## Feature Flag
Flag name: `FeatureFlags.<flagName>` (or "Not required")

## Out of Scope
Explicitly list what this spec does NOT cover.

## Open Questions
- [ ] ...

## References
- Related research: [[Research/<Topic>]]
- Related ADRs: [[ADRs/ADR-<n>]]
```
