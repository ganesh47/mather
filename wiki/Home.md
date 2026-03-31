# Mather

Research, specifications, and architecture decisions for the Mather iOS app (SwiftUI).

## Navigation

| Section | Purpose |
|---|---|
| [Research](Research) | Technology investigations, trade-off analyses, feasibility studies |
| [Specs](Specs) | Feature specifications linked to GitHub issues |
| [ADRs](ADRs) | Architecture Decision Records — what we decided and why |

## Research Process

1. Open a **Research Task** issue on GitHub
2. Document findings in `wiki/Research/<Topic>.md`
3. Link the wiki page from the issue
4. Conclude with a clear recommendation or decision
5. If the research drives an architecture decision, write an ADR

## Spec Process

1. Research must be complete (or explicitly deferred) before writing a spec
2. Write spec in `wiki/Specs/<Feature>.md` using the spec template
3. Open a **Feature Spec** issue, link to the wiki spec
4. Spec is "approved" when the issue is labelled `spec:approved`
5. Break approved specs into implementation issues

## Trunk-Based Development

- All work merges to `main` frequently (≤2 days in a branch)
- Incomplete features ship behind feature flags
- CI must pass before merge
- Tags mark releases — no release branches

## Quick Links

- [GitHub Issues](https://github.com/ganesh47/mather/issues)
- [Pull Requests](https://github.com/ganesh47/mather/pulls)
- [Actions / CI](https://github.com/ganesh47/mather/actions)
- [Security Policy](https://github.com/ganesh47/mather/security/policy)
