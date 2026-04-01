# GitHub Copilot Instructions — Mather

See `AGENTS.md` for full project context. Key points for inline completions:

## Language & Framework
- Swift 6, strict concurrency. Every `@Observable` class is `@MainActor`.
- SwiftUI only — no UIKit, no storyboards.
- iOS/iPadOS 18.0 minimum. Use `@Observable` (not `ObservableObject`/`@Published`).
- Swift Testing for unit tests (`import Testing`, `#expect`, `@Test`).

## Architecture Rules
- Views are pure — no domain mutation inside view bodies.
- All state lives in `VerticalSliceEngine`; views receive it via `@Bindable var appModel: AppModel`.
- `SliceStateMachine` governs stage transitions — never transition stages from a view directly.
- Feature flags come from `FeatureFlagService` injected via `AppModel`.

## Naming
- Views: `<Context>View` (e.g., `ConcreteBuildView`)
- Engine methods: imperative verbs (`startSession()`, `submitCurrentStage()`, `adjustConcrete(by:)`)
- Shared UI components: `VS1<Name>` prefix for VS1-scoped, `Mather<Name>` for app-wide

## Touch Targets
Minimum 80×80 pt for any interactive element in the child-facing UI.
Use `VS1PrimaryButton` (minHeight: 72) and `VS1Card` from `Features/VerticalSlice1/VS1SharedUI.swift`.

## XcodeGen
Do not suggest edits to `.xcodeproj`. Suggest `project.yml` edits instead.

## What NOT to suggest
- Combine, `@Published`, `ObservableObject` — project uses `@Observable`
- `UIKit` imports unless explicitly required for bridging
- `DispatchQueue` — use Swift concurrency (`async/await`, `Task`)
- Hardcoded strings in child-facing UI — they must go through `SpeechService`
