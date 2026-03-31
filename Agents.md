# Agents Context

## Project Snapshot
- Repository: ganesh47/mather
- Product: Mather — iPadOS SwiftUI math app
- Target: iPadOS app (Swift, SwiftUI, Swift Package Manager)
- Current docs source: wiki/ (Research, Specs, ADRs)
- App distribution: Personal/family use only (no App Store process)
- CI pipeline: macOS + Xcode 16, scheme Mather, simulator target iPhone 16

## Workflow Defaults (Trunk-Based)
- main is the release branch and should stay releasable
- Keep branches short-lived (prefer < 1 day, max 2 days)
- Branch naming: <type>/<short-description>
- Merge to main with CI passing
- Prefer feature flags for incomplete work
- No release branches; use tags for releases

## Agent Collaboration Model
- Use this file as the first document to sync context before making changes.
- Keep edits targeted and small; focus on one decision/thread at a time.
- Do not propose changes that conflict with existing CLAUDE.md conventions without explicit alignment.
- Prefer existing project templates and wiki process over ad hoc issue/spec formatting.

## Mandatory GitHub Workflow Artifacts
- Use issue templates:
  - Research: .github/ISSUE_TEMPLATE/research_task.yml
  - Feature specs: .github/ISSUE_TEMPLATE/feature_spec.yml
  - Bugs: .github/ISSUE_TEMPLATE/bug_report.yml
- PR template should be followed (.github/pull_request_template.md) and include:
  - trunk-based checklist
  - testing notes
  - optional screenshots for UI work

## GitHub CI and Automation
- .github/workflows/ci.yml
  - runs on push/PR to main
  - resolves package dependencies, runs build-for-testing, runs tests without building
- .github/workflows/wiki-sync.yml
  - syncs wiki/**/*.md to repo wiki on updates
  - wiki README.md flattening rules handled by workflow

## Documentation Conventions
- Specs: wiki/Specs/<Feature>.md and must include issue link + status
- Research: wiki/Research/<Topic>.md
- ADRs: wiki/ADRs/ADR-<NNNN>-<slug>.md using template in wiki/ADRs/README.md
- Process references and indexes in:
  - wiki/Home.md
  - wiki/Specs/README.md
  - wiki/Research/README.md
  - wiki/ADRs/README.md

## Existing Context Notes
- No source tree directories like Sources/, Tests/ are present yet in this checkout.
- Keep architecture and project structure in line with docs until implementations are introduced.
- Existing conventions are explicitly listed in CLAUDE.md.

## Agent Tooling Notes for This Repo
- Use Node-backed JS sessions with js_repl when running JavaScript workflows.
- codex.tool(...) is available for invoking shell/tool calls inside js_repl.
- Avoid process.stdout / process.stderr / process.stdin writes in Node REPL usage.
- Do not revert unrelated user edits; avoid destructive git commands unless explicitly requested.
