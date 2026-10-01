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

Spoken guidance:

- Instructions and new-round prompts play automatically.
- Pausing on a focused game, answer, or action reads its label. Rapid swipes cancel pending labels; instructions and feedback finish before a choice is read.
- Play/Pause repeats the current instructions or question in every game. In Angle Arcade, Select fires or advances/retries the shot.
- Feedback and Memory Gallery results are spoken. Leaving a screen or putting the app in the background stops narration.
- Custom narration yields to VoiceOver, which uses the existing accessibility labels.

Before device handoff, check each game with the Siri Remote: initial prompt, rapid focus movement, answer feedback, next round, repeat prompt, Menu return, and VoiceOver enabled. Confirm that Memory picture prompts do not speak the answer before selection.
