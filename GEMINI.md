# Mather — Gemini Context

> See `AGENTS.md` for the full shared project context.
> This file adds Gemini-specific guidance.

@AGENTS.md

## Gemini-Specific Notes

### Project Generation
This project uses XcodeGen. After editing `project.yml`, regenerate with:
```bash
xcodegen generate
```
Never edit `Mather.xcodeproj/project.pbxproj` directly.

### Swift 6 Concurrency
The codebase targets Swift 6 strict concurrency. When suggesting code:
- All `@Observable` classes must be `@MainActor`
- Use `Task { @MainActor in }` for async bridging
- `sendable` conformance is required across actor boundaries

### Test Framework
Tests use **Swift Testing** (not XCTest):
- `import Testing`
- `@Test func name() { #expect(...) }`
- `@Suite` for grouping
- Do not suggest `XCTestCase` subclasses for unit tests; use `struct` with `@Test`

### Key Files to Orient From
- `AGENTS.md` — full context
- `project.yml` — source of truth for Xcode project structure
- `Domain/VerticalSliceEngine.swift` — central state machine / engine
- `Domain/SliceModels.swift` — all core data types
- `Shared/FeatureFlags.swift` — feature flag service
- `wiki/Research/Math-App-Vision.md` — product vision and pedagogy
