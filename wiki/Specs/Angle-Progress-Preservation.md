# Angle progress preservation follow-up

The independent review of base `840b1107` through `419e067` found an inherited data-loss path: unreadable progress loaded as empty and entering a world immediately replaced the retained bytes. Schema-1 extension fields were also discarded. The rendered TV slice passed its bounded source, visual, photo-rights and content review at `419e067`; that verdict explicitly excluded Angle progress preservation.

This follow-up changes only storage handling, engine persistence guards, recovery presentation and the existing confirmed reset hook. The campaign, nine authored missions, physics model and both scene renderers are unchanged.

`AngleArcadeProgressStore.load()` returns known progress for a missing or supported key, and `nil` for unreadable storage. Missing, loaded and unsupported states are distinct. Non-Data values, malformed JSON, unsupported versions, unknown top-level or completion fields, and data that would lose content during validation are preserved. Every save rechecks the persisted value and returns false while it is unsupported. No migration or automatic clear is performed.

The engine pauses before starting or entering a world, recording help, submitting, or completing a flight when storage cannot be read. Paused views hide world controls and completion counts rather than presenting an empty passport as known history. A payload restored while an engine is open is checked before the next write. A rejected completion cannot publish success or add session completion credit.

On iOS, the existing parent-confirmed Settings action for clearing the selected child's learning now calls the explicit scoped Angle clear instead of a normal save. Other children's Angle scopes remain intact. The paused activity provides Listen and Done, plus directions to Settings.

TV Angle progress remains shared device activity with unknown learner ownership. Its paused screen has All games, Listen and a parent action whose confirmation explicitly says it clears only Angle progress for everyone on this TV. Cancel, leaving the activity, or relaunching retain the opaque data. The Family guide's selected-learner and all-learning reset behavior is unchanged; those actions do not claim to clear earlier device activity.

## Focused verification

- Existing campaign, engine, storage and authored-solution checks remain the healthy-progress and physics gate.
- Six data fixtures exercise malformed JSON, future schema, future top-level field, future completion field, invalid stored counter and a non-Data key. Each attempts saves and world/mission entry and checks retained bytes or the original typed value.
- Restore a future payload between aiming/submission and between launch/completion. The engine must pause with no new attempt/completion credit and retain exact bytes.
- Confirm an explicit reset clears only the selected scope and enables play, retaining another scope byte for byte.
- Existing AppModel selected-child reset regression checks the scoped iOS integration.
- A new native TV case checks paused controls/focus, Cancel, relaunch, explicit confirmation and a new zero-completion world. Test data uses only the dedicated UI-test suite. Alert actions use actual remote focus and Select.
- A new native iOS case provides an unreadable value through the test process argument domain, checks the paused Settings guidance and absence of play controls, and uses Done to leave. No persisted real-child fixture is written.

Native and compiler execution for this follow-up is pending a coordinated Mac slot. Earlier runs and 25 inspected 4K captures validate `c1cf4d9`; the credit-only `419e067` and this persistence follow-up have no new native execution claimed here. Physical TV input, manual VoiceOver/audio and animation timing remain unverified.
