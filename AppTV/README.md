# MatherTV

`MatherTV` is the tvOS feasibility shell for Mather TV Lab. Keep this target TV-native: focus/select navigation, couch-distance type, and small shared-play surfaces instead of a direct iPad port.

Generation and build checks:

```sh
xcodegen generate
xcodebuild -scheme MatherTV -destination 'platform=tvOS Simulator,name=Apple TV' build
```

The shell intentionally avoids `Features/Memory/*` until the shared Memory content extraction lands.
