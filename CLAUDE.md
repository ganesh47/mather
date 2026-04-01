# Mather — Claude Code Context

> See `AGENTS.md` for the full shared project context (stack, layout, conventions, workflow).
> This file adds Claude-specific guidance only.

@AGENTS.md

## Claude-Specific Behaviour

### Tools
- Use `Read`, `Edit`, `Write`, `Glob`, `Grep` for file operations — not Bash equivalents
- Use `Bash` only for: `git`, `xcodegen generate`, `gh`, build/test commands
- Use the `Agent` tool (Explore subagent) for broad codebase searches needing multiple passes

### Project Changes That Require XcodeGen Regeneration
Any edit to `project.yml` must be followed by:
```bash
xcodegen generate
```
Then commit both `project.yml` and the regenerated `.xcodeproj`.

### Memory
Persistent memory lives at `~/.claude/projects/-home-ganesh-projects-mather/memory/`.
Key memories: `product_vision.md`, `project_setup.md`, `user_context.md`.
Update memory when significant decisions are made or product direction changes.

### Distribution
Personal/family only — Xcode → iPad via USB or WiFi.
No App Store, no parental gate, no StoreKit, no COPPA compliance needed (ADR-0002).

### Pedagogy Constraint
Any new activity or game mechanic must align with the CPA framework and research in
`wiki/Research/Math-App-Vision.md`. Check the research before speccing a new feature.

### CI Notes
- CoreData "Failed to stat" errors in test output are benign (SwiftData lazy init in simulator)
- `Executed 0 tests` + individual test lines = normal Swift Testing / XCTest bridge dual output
- CI captures `TestResults.xcresult` and uploads screenshot artifacts — check Actions tab

### Code Style
- Swift 6, strict concurrency — every `@Observable` class is `@MainActor`
- No storyboards, no UIKit unless bridging required
- Tests use Swift Testing (`#expect`, `@Test`); UI tests use XCTest + `XCUIApplication`
