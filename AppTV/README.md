# MatherTV

`MatherTV` is the TV-native Mather game library. Keep this target focused on focus/select navigation, couch-distance type, and small shared-play surfaces instead of direct iPad ports.

Current games:

- Memory Gallery — narrated picture quizzes and illustrated picture-pair adventures
- Angle Arcade — predict and launch with angles
- Sum Sprint Party — calm addition practice
- Compare Camp — 24 themed camps with building, counting, comparison and number signs
- Shape Detective — solve geometry clues
- World Quest — explore countries and find them on an accurate offline map

Generation and build checks:

```sh
xcodegen generate
xcodebuild -scheme MatherTV -destination 'platform=tvOS Simulator,name=Apple TV' build
```

The target intentionally shares small domain models while keeping its screens and remote interactions specific to tvOS.

Spoken guidance:

- Instructions and new-round prompts play automatically.
- Pausing on a focused game, answer, or action reads its label. Rapid swipes cancel pending labels; instructions and feedback finish before a choice is read.
- Play/Pause repeats the current instructions or question in every game. In Angle Arcade, Select launches or checks a turn, advances after success, or reopens aiming after a miss. Play/Pause also reveals aiming help.
- Feedback and Memory Gallery results are spoken. Leaving a screen or putting the app in the background stops narration.
- Custom narration yields to VoiceOver, which uses the existing accessibility labels.

Angle Arcade:

- Three open worlds contain nine finite missions: Garden deliveries, Builder corners and quarter turns, and Earth/Moon comparisons.
- World cards show device-local completion and resume the first unfinished mission. A completed world can be replayed.
- Left/right changes angle or turn; up/down changes power in missions that introduce it. Early missions keep the other variable fixed. Select launches or checks a turn.
- The same shared scene and campaign are used on iPad. Fixed camera bounds, a launch wedge and reference ray make angle changes visible. Builder square corners rotate rigidly and retain their right angle; the gate demonstrates a quarter turn.
- Guided missions show the full trajectory. Transfer missions initially show only the start of the path; Play/Pause or two misses reveals more help. Previous attempts remain visible, and the Moon comparison includes the same shot's Earth path.
- Flights animate before scoring. Reduce Motion shows a still trajectory. Backgrounding or leaving cancels a pending flight, and returning restores remote focus.
- Every world finishes with a creation: a flowering garden, clubhouse or rocket. Completion records distinguish assistance from an independent attempt; completion is not a claim of mastery.
- Play/Pause repeats spoken help. Menu returns from a mission or reward to worlds, then from worlds to all games. VoiceOver receives the scene description, adjustable controls and results.

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

Memory Adventures:

- Busy Builders, Rescue Crew, and Space Trip offer picture pairs or the existing narrated quiz.
- Start with three visible pairs, try four, or choose hidden pairs (up to six; Rescue Crew has five). Hints briefly reveal a matching pair.
- Matched cards remain reachable with the remote. Explore speaks a short observation and optional pretend-play activity. Play/Pause repeats the current guidance; Menu returns to the gallery.
- Adventure quizzes choose distinct prompts; Rescue Crew finishes after its five vehicles. Replay changes the order.
- Bundled content v3 protects refreshed artwork from older downloaded packs. Newer packs activate at a gallery boundary.
- The reviewed art manifest and source credits are in `wiki/Specs/Memory-Adventures-Art-Provenance.json`; content decisions and factual sources are in `wiki/Specs/Memory-Adventures-Content.md`.

World Quest:

- Offline geographic exploration, untimed practice, and a 20-second-per-country challenge. Starter has 12 countries; six continent packs and Whole World cover 195 quiz countries.
- The rollout flag `feature.worldQuestEnabled` defaults to true for the family TestFlight pilot. Disable through the MatherTV scheme's launch arguments with `-feature.worldQuestEnabled NO` if rollback is needed. A deterministic QA shuffle is available with `-worldQuest.seed 42`.
- Directional presses move the yellow highlight between country locations. Select checks a location. Up at the northern edge reaches World / Region / Closer zoom, Hint, and Reveal; Down returns to the map. Green marks the answer. Small dots show locations without enlarging country borders.
- Explore reads country names. Practice and Timed show/speak the requested name but conceal candidate names, including from VoiceOver. Play/Pause repeats the prompt and suspends the timer during speech. VoiceOver uses an explicit Start country action after its prompt. Menu returns to All games.
- System interruptions preserve the countdown; returning requires Resume. Each solved/revealed question waits for Select to advance. Completed sessions store a local passport; abandoned games do not.
- Natural Earth v5.1.2, 1:10m India-viewpoint boundaries, Equal Earth projection. The parent Map information screen explains the convention and public-domain source. Rebuild with Python 3.10+, `pip install -r scripts/world_quest_requirements.txt`, then `python scripts/generate_world_quest_map.py`; `--check` verifies reproducibility. `python3 scripts/test_world_quest_content.py` checks bundled content offline.
- World Quest shared unit tests run in both MatherTests and MatherTVTests; remote UI tests run in MatherTVUITests. During physical-device acceptance, review Siri Remote behavior, small-country markers at couch distance, VoiceOver, Reduce Motion, and rendering performance on Apple TV HD.
