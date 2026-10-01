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
- Play/Pause repeats the current instructions or question in every game. In Angle Arcade, Select fires, advances to the next target after a hit, or retries the same aim after a miss.
- Feedback and Memory Gallery results are spoken. Leaving a screen or putting the app in the background stops narration.
- Custom narration yields to VoiceOver, which uses the existing accessibility labels.

Angle Arcade:

- The first target offers a guided winning shot. Later targets, including the first target when it returns, start with a small miss that needs an adjustment.
- Left/right changes the angle; up/down changes the power. The dotted arc previews the shot. After a miss, a direction press opens aiming immediately.
- The ball travels along the arc and stops at a hit or on the ground. Feedback distinguishes a short shot from one above or below the target.
- Play/Pause repeats guidance. Menu returns to all games; reentering starts a fresh guided round.

Before device handoff, check each game with the Siri Remote: initial prompt, rapid focus movement, answer feedback, next round, repeat prompt, Menu return, and VoiceOver enabled. Confirm that Memory picture prompts do not speak the answer before selection.
