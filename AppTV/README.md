# MatherTV

`MatherTV` is the TV-native Mather game library. Keep this target focused on focus/select navigation, couch-distance type, and small shared-play surfaces instead of direct iPad ports.

Current games:

- Memory Gallery — picture and name matching
- Angle Arcade — predict and launch with angles
- Sum Sprint Party — calm addition practice
- Compare Camp — 24 themed camps with building, counting, comparison and number signs
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

Compare Camp:

- Six regions contain four camps each: plants/sheep, ocean creatures, birds, planet models, travel, and builders. The artwork identifies one object per token tile.
- Choose Camp Adventure or one of five focused trails, then groups up to 5, 10 or 20. Every trail contains eight stops and a natural finish.
- Adventure progresses from adding/removing items to match, through pictured more/fewer comparisons, to number signs and transfer into a new region.
- Count left/right advances one highlighted object per Select. Pair up shows matching link markers and extra plus markers. Guide me speaks a scaffold. Incorrect checks and choices remain open for another try.
- From answer controls, Left reaches help; Down from Check Match or the final answer reaches the counting row. Up from help returns to the answer controls. Down from any group-size choice reaches Start Exploring.
- Play/Pause repeats the current task, chosen options, scaffold or solved explanation. Menu returns to all games. Reentry starts at the camp chooser.
- Completed trails earn a device-local passport sticker. Replay and later completed-camp visits vary the groups. Exploration is celebrated without a timer or accuracy score.
- The printable companion is `output/pdf/compare-camp-family-play-kit.pdf`; its builder and the content manifest exporter live in `scripts/`.
