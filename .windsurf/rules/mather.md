---
trigger: always_on
---

# Mather — Windsurf Context

See `AGENTS.md` for full project context.

## Critical Rules

**Never edit `.xcodeproj` directly** — edit `project.yml`, then run `xcodegen generate`.

**Swift 6 strict concurrency** — all `@Observable` classes must be `@MainActor`. No `DispatchQueue`, no Combine.

**Architecture** — `VerticalSliceEngine` owns all state. Views are pure. `SliceStateMachine` owns transitions.

**Touch targets** — minimum 80×80 pt for any child-facing interactive element.

**XcodeGen** — after any `project.yml` change, regenerate before building:
```bash
xcodegen generate
```

## Quick Reference

| File | Purpose |
|---|---|
| `project.yml` | XcodeGen source of truth for project structure |
| `Domain/VerticalSliceEngine.swift` | Central state engine |
| `Domain/SliceModels.swift` | All core types |
| `Domain/SliceStateMachine.swift` | Stage transition logic |
| `Shared/FeatureFlags.swift` | Feature flag service |
| `Shared/MatherTheme.swift` | App-wide theme tokens |
| `Features/VerticalSlice1/VS1SharedUI.swift` | VS1 design system components |

## Tests
- Unit: Swift Testing (`@Test`, `#expect`) in `Tests/MatherTests/`
- UI: XCTest + `XCUIApplication` in `Tests/MatherUITests/`
- Run: `xcodebuild test -project Mather.xcodeproj -scheme Mather -destination 'platform=iOS Simulator,name=iPhone 16,OS=latest' CODE_SIGNING_ALLOWED=NO`
