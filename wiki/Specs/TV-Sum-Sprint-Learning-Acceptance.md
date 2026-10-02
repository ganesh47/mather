# TV Sum Sprint: number-parts learning slice

## Scope

Replaces endless 11–20 streak play on TV with grown-up-reviewed totals through 5,
10 or 20. Every session contains five practice items and a sixth number-parts
probe. There is no countdown, punishment reset or claim of mastery. The shipped
`tv.sumSprintParty.personalBest` value remains readable and unchanged.

Practice progresses through two concrete counter-tray items, two rows-of-five
items, and an addition sentence with pictured parts. The final item uses a
part-whole diagram with the whole unknown. It has a different fact from all
five practice items and starts without an app hint. Previously exposed
fact/number-parts variants are tracked by frozen profile history; unseen
variants are preferred. Once a small range is exhausted, the same finite
session ends with familiar transfer practice, explicitly `isFreshProbe=false`.
The app does not fabricate fresh evidence on replay.

## Domain and persistence contract

Owned types live in `Domain/SumSprintPartyTVSession.swift`; legacy round APIs
remain compatible in `Domain/SumSprintPartyTVRound.swift`.

View integration:

```swift
SumSprintPartyTVView(
    profileID: frozenProfileID,
    familyMode: familyMode,
    onAttempt: { attempt in /* coordinator ledger */ },
    onResult: { result in /* coordinator ledger */ }
)
```

Integration must include `Domain/SumSprintPartyTVSession.swift` and
`Domain/ActivityLearningEvidence.swift` in the TV target. Project includes are
coordinator-owned; this slice's temporary local includes are excluded from its
commit.

- Activity ID: `tv-sum-sprint`; concept ID: `number-parts`.
- Entity ID: `addition.<a>+<b>`; property ID: `through-5`, `through-10`, or `through-20`.
- Stage IDs: `practice`, `fresh-probe`, and `transfer` for a previously seen final variant.
- `itemVariantID` freezes fact plus representation; `isFreshProbe` describes the item before any retry.
- Exposure, incorrect, help, supported-correct and correct-without-observed-app-help are separate events.
- `appHintUsed` records observed app scaffolding; every event has `adultHelp=.unknown`.
- `.independentCorrect` means no observed app support, not verified absence of adult assistance.
- Family play forces frozen `profileID=tv-family`; child mode uses the injected profile ID.
- Checkpoints are keyed by frozen profile, family/child mode and activity. Fact, choices,
  representation, progress, event UUIDs and session ID are encoded, validated and restored together.
- Each event is saved before callback delivery. Reentry/resume replays the same UUIDs;
  the shared ledger must deduplicate them. Completed results replay with the same session/result ID.
- New sessions archive earlier incomplete or completed checkpoints instead of clearing their evidence.

The engine owns every domain mutation. The view owns transient focus/narration.
No root, profile, shared store, release workflow, or legacy record migration is
part of this slice.

## Acceptance checks

1. Choose Through 5, 10 or 20. Each fact's total and all four unique choices are
   in that range; six unique facts are frozen before play begins.
2. Select an incorrect total. The same item and choices stay available. The
   feedback asks the child to count parts without announcing the correct total.
3. Select Guide me twice. Count-on help starts from the first part. Each Count one
   selection lights exactly one second-part counter and counts one step; counting
   stops at that part's boundary. Helped correctness stays supported.
4. Press Play/Pause before an answer, after a miss, while counting and after a
   correct answer. It repeats the current task/scaffold. Focus reads choices; custom
   narration yields to VoiceOver. No required child instruction depends on reading.
5. Press Menu midway through a helped item, reenter and Resume. Then terminate
   and relaunch. Item, choices, counting progress and helped classification persist.
6. Background and activate the TV app during counting. Counting does not advance;
   answer focus returns, and the same item can be corrected.
7. Finish five practice items. The probe has a fact unused by that session and a
   changed number-parts representation, initially without app support. Helped
   practice does not contaminate this distinct probe; help on the probe does.
8. Finish the sixth item. A calm recap separates answers without app hints from
   counting-assisted answers. Another session is optional. Repeated Select cannot
   skip an unsolved item or duplicate a result.
9. Replay Through 5 enough times to use all six probe variants. They are distinct
   until exhaustion; later familiar transfer practice is not labelled fresh.
10. Switch child/family context. A session never restores another profile's item
    or attributes family assistance to a child. Old personal best remains intact.

## Automated validation

- `SumSprintPartyTVRoundTests`: six legacy compatibility tests.
- `SumSprintPartyTVSessionTests`: thirteen domain/persistence/evidence tests,
  including corrupted checkpoint rejection, exact UUID replay, family/profile
  isolation, partial-session archival and probe exhaustion.
- `SumSprintPartyUITests`: remote finite session and fresh probe, corrected answer
  after Menu/relaunch, and stepwise counting/background/foreground restoration.

Local tests use separate derived data and private simulators, never a parallel
slice's running TV device. Physical Siri Remote and VoiceOver listening remain
part of the coordinator's device handoff checks; simulator tests do not verify
actual spoken audio or report adult help.
