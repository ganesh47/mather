# tvOS Memory picture-pairs presentation

Scope: Busy Builders, Rescue Crew and Space Trip picture-pairs presentation. The shared `MemoryPairingEngine` retains matching rules, actual pair counts, hint behavior and its 350ms match / 800ms miss validation intervals. This change does not add mastery, speed or independent-learning claims.

## Pictures and stable layout

- Default: three visible pairs in three columns and two complete rows. Four visible pairs use four columns and two rows. Hide and seek preserves up to six pairs, with four columns and up to three rows; Rescue Crew uses its actual five-pair pool in five columns and two complete rows.
- The grid fills the available safe area. Each picture uses full aspect fit with 12pt inset, with no cropping or image distortion. Existing 512×512 bundled artwork is not described as high resolution.
- Each round retains its original card slots. Collection replaces the two matched buttons with quiet, noninteractive placeholders; remaining cards do not move or change identity. Collected pairs appear as one thumbnail per actual picture identity in the status tray.
- Focus uses a clear outline and a restrained 1.018 scale. Reduce Motion removes focus scale, collection transition and final badge motion.

## Feedback and completion

An accepted matching selection receives a check and green border during engine validation. After validation, a further 300ms presentation interval gives the pair time to be seen, then both buttons are collected. Input is guarded through validation and collection. Reduced Motion collects immediately after engine validation. A miss keeps cards visible for the existing engine interval, then clears selected state; no pair is awarded.

After the final collection, a small completion badge settles within 900ms and the screen remains still. Completion shows the actual pair total, collected pictures, adventure celebration and optional physical activity. Play again, Adventure options and Choose another adventure remain available. Replay deals new identities and resets actual counts and collection.

## Options, lifecycle and narration

Adventure options cancels unresolved feedback while retaining the same round, confirmed pairs and fixed slots. Resume restores those cards. Choosing a new pair count explicitly deals a new round. Menu exits to the gallery. Scene inactivity cancels delayed presentation/focus work and unresolved engine callbacks; confirmed matches are reconciled into collection before foreground restoration. Tokens protect against callbacks from an older round.

Only accepted selections speak picture names; ignored input produces no extra speech. Hidden cards expose position labels until selected or hinted. Outcome announcements support VoiceOver without simultaneous app narration. Play/Pause repeats the current instruction. A transient Audio on/off option defaults on and mutes app narration through the shared controller; VoiceOver announcements remain available. Hint and exploration retain grounded card content.

## Optional gentle timer

The default is untimed. The option enables a 120-second `TVFriendlyChallengeClock`, displayed by the shared `TVFriendlyTimerView`. Independent pause reasons cover background, options, hints (until the engine's actual hint IDs clear), and feedback including collection. A new/replay round starts a fresh clock. Explicitly changing the timer option configures the pace aid without changing cards or counts. Options Resume preserves remaining time.

Expiry freezes the clock without altering cards or score. More time adds 60 seconds to that same round; Keep matching turns the clock off on that same round. No race, failure, speed reward or timer-derived learning claim is shown. Completion and exit stop the clock. Test-only short timing is gated behind `-memory-pairs-ui-test`.

## Native acceptance evidence required

`MemoryPairsTVUITests` covers:

1. Large default six-card board, three-column balance, collection 6→4→2→0, stable remaining centers, repeated Select, bounded finish and replay reset.
2. Miss behavior, repeated input, options Resume identity preservation, and foreground reconciliation during pair success.
3. Gentle timer expiry, More time and Untimed recovery with identical cards and counts.
4. Reduce Motion four-pair layout, six-pair hidden mode, temporary hint visibility, and Menu exit.
5. Muted narration option state, accepted pairing and options Resume.
6. Rescue Crew and Space Trip large full-picture screenshots; Rescue requested-six mode uses ten hidden cards / five actual pairs in two balanced rows, with last-card focus and hint access.

The existing `MemoryGalleryContentUITests.testAdventureStartsWithThreeVisiblePairsAndOffersHint` checks collection instead of retained matched buttons. Coordinator native builds, test runs and post-change screenshot inspection remain required before declaring the presentation verified. VoiceOver audio and focus behavior also require a manual accessibility pass.
