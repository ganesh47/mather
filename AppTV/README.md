# MatherTV

`MatherTV` is the TV-native Mather game library. Keep this target focused on focus/select navigation, couch-distance type, and small shared-play surfaces instead of direct iPad ports.

Current games:

- Memory Gallery — picture and name matching
- Angle Arcade — predict and launch with angles
- Sum Sprint Party — calm addition practice
- Compare Camp — count and compare two groups
- Shape Detective — solve geometry clues

Generation and build checks:

```sh
xcodegen generate
xcodebuild -scheme MatherTV -destination 'platform=tvOS Simulator,name=Apple TV' build
```

The target intentionally shares small domain models while keeping its screens and remote interactions specific to tvOS.
