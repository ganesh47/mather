# Mather — Project Conventions

## Repository
- **Repo**: ganesh47/mather
- **Wiki**: https://github.com/ganesh47/mather/wiki (research, specs, ADRs)
- **Issues**: GitHub Issues (linked to wiki specs)

## Development Workflow: Trunk-Based Development

- `main` is the trunk — always releasable
- Feature branches are short-lived (< 1 day preferred, max 2 days)
- Branch naming: `<type>/<short-description>` (e.g. `feat/login-view`, `fix/math-parser-crash`)
- PRs must pass CI before merge; squash-merge into main
- Use feature flags (`FeatureFlags.swift`) for incomplete features landing in main
- No long-lived branches. No release branches. Tags mark releases.

## Distribution
- **Personal/family use only** — not publishing to App Store
- Deploy directly to iPad via Xcode (USB or WiFi) using a personal team signing certificate
- No parental gate, no StoreKit, no COPPA/Kids Category requirements
- No App Store review process to worry about

## Tech Stack
- **Platform**: iPadOS (SwiftUI, latest Swift)
- **Minimum iPadOS target**: TBD (see wiki: ADRs)
- **Architecture**: TBD (see wiki: ADRs)
- **Package manager**: Swift Package Manager

## Research & Spec Process
1. Open a GitHub Issue using the **Research Task** template
2. Document findings in the wiki under `Research/<Topic>`
3. Write a feature spec in wiki under `Specs/<Feature>` and link it to the issue
4. Record architecture decisions as ADRs in wiki under `ADRs/`
5. When spec is approved, open implementation issues linked to the spec

## Code Conventions
- SwiftUI views in `Sources/Views/`
- Business logic / models in `Sources/Domain/`
- Services / networking in `Sources/Services/`
- Tests in `Tests/`
- No storyboards, no UIKit unless bridging is required

## CI
- All PRs run: build + test
- Main branch is protected (see branch rules)
