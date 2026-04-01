# Mather — Agent Context

> Universal context file for all AI coding agents (Claude, Codex, Gemini, Cursor, Copilot, Windsurf, Devin, etc.).
> Tool-specific additions live in: `CLAUDE.md`, `GEMINI.md`, `.github/copilot-instructions.md`,
> `.cursor/rules/`, `.windsurf/rules/`

## Project

**Mather** — iPadOS SwiftUI math learning app for a 5-year-old.
- Repo: `ganesh47/mather`
- Distribution: **personal/family only** — sideloaded via Xcode USB/WiFi. No App Store.
- Docs: wiki at `wiki/` (Research, Specs, ADRs) → auto-synced to GitHub wiki on push to main
- Issue #1: research complete. Issue #10: VS1 spec. VS1 ("Make & Break to 10") is the active milestone.

## Stack

| Layer | Choice |
|---|---|
| Language | Swift 6 (strict concurrency) |
| UI | SwiftUI, `@Observable` (no TCA, no Combine) |
| Min target | iOS/iPadOS 18.0 |
| Project gen | XcodeGen (`project.yml`) — **never edit `.xcodeproj` by hand** |
| Persistence | SwiftData (`SessionHistoryStore`) |
| Telemetry | JSONL event log written to app Documents (`TelemetryWriter`) |
| Tests | Swift Testing framework (`#expect`, `@Test`) |
| CI | GitHub Actions `macos-15`, Xcode (latest), iPhone simulator |

## Source Layout

```
App/            MatherApp, RootView, AppModel, Assets, Info.plist
Domain/         SliceModels, SliceStateMachine, VerticalSliceEngine, ProblemGenerator
Features/
  VerticalSlice1/   ConcreteBuildView, SplitView, EquationResolveView,
                    TransferCheckView, SliceSessionView, SessionConfig/SummaryViews
  ParentSummary/    ParentSummaryView, SettingsView
Persistence/    SessionHistoryStore (SwiftData), TelemetryWriter (JSONL)
Services/       SpeechService (AVFoundation)
Shared/         FeatureFlags (@Observable + UserDefaults), MatherTheme
Tests/
  MatherTests/      Unit tests (Swift Testing)
  MatherUITests/    UI/screenshot tests (XCTest + XCUIApplication)
wiki/           Research/, Specs/, ADRs/ — synced to GitHub wiki
```

## Trunk-Based Development

- `main` = trunk, always releasable
- Branches: `<type>/<short-slug>`, max 2 days old, then merge or drop
- PRs: squash-merge, CI must pass, 1 review
- Feature flags in `FeatureFlagService` gate incomplete work; `verticalSlice1Enabled` gates VS1
- No release branches; tags mark releases

## Key Conventions

**XcodeGen**: All project changes go in `project.yml`. Run `xcodegen generate` after editing.

**Swift 6 / strict concurrency**:
- All `@Observable` classes and SwiftUI views run on `@MainActor`
- `VerticalSliceEngine` is `@MainActor final class`
- No `async/await` bridging hacks; use `Task { @MainActor in }` for any off-thread work

**SwiftUI / `@Observable`**:
- Pass `appModel` as `@Bindable var appModel: AppModel` into views
- Views are pure; all mutation goes through `VerticalSliceEngine` methods
- No `@State` in views for domain state — only for local transient UI state

**CPA pedagogy** (Concrete→Pictorial→Abstract):
- `SliceStage` encodes the learning phase; `SliceStateMachine` governs valid transitions
- New activities must follow: concrete drag/tap → pictorial representation → abstract symbols → transfer

**Touch targets**: minimum 80×80 pt. `VS1PrimaryButton` sets `minHeight: 72`; respect this.

**No reading difficulty**: All instructions delivered by `SpeechService`. No required text in child-facing flow.

## Tests

```bash
xcodegen generate
xcodebuild test \
  -project Mather.xcodeproj -scheme Mather \
  -destination 'platform=iOS Simulator,name=iPhone 16,OS=latest' \
  CODE_SIGNING_ALLOWED=NO
```

Current suite: `ProblemGeneratorTests`, `SliceStateMachineTests`, `VerticalSliceEngineTests` — 4 tests, all passing.

## Research & Spec Process

1. Open **Research Task** issue → document in `wiki/Research/<Topic>.md`
2. Write spec in `wiki/Specs/<Feature>.md` → open **Feature Spec** issue
3. Significant architecture decisions → `wiki/ADRs/ADR-<NNNN>-<slug>.md`
4. Push `wiki/` changes to main → GitHub wiki auto-syncs via `wiki-sync.yml`

## Agent Collaboration Rules

- Read this file before making changes
- Do not edit `.xcodeproj` — edit `project.yml` then regenerate
- Do not revert unrelated user edits
- Prefer targeted, small changes over large refactors
- Propose architecture changes as ADRs before implementing them
- Keep branches short-lived; flag if a task will exceed 2 days
