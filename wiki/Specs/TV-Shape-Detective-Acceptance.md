# TV Shape Detective investigations and Angle Arcade focus

## Slice contract

Base: `c475327111b4eb72850ef9cc311c1d99fe7d3bea`, plus coordinator evidence contract `08b08a286e2426e3099277073e234b657b79ec7e`.

Owned implementation: `Domain/ShapeDetectiveTVSession.swift`, `Persistence/ShapeDetectiveTVSessionStore.swift`, `AppTV/ShapeDetectiveTVView.swift`, and world-card focus styling in `AppTV/AngleArcadeTVView.swift`. Compare Camp content and Angle Arcade's three worlds/nine missions are retained.

The TV target needs `Domain/ActivityLearningEvidence.swift`, `Domain/ShapeDetectiveTVSession.swift`, and `Persistence/ShapeDetectiveTVSessionStore.swift`. Target includes and generated project are integration-owned.

`ShapeDetectiveTVView(profileID:familyMode:onAttempt:onResult:onExit:)` accepts the coordinator's frozen profile context and shared evidence callbacks. `onExit` is optional for previews, and must be injected by the TV root for **All done** and the paused session's **All games** action to return from the embedded game to the launcher. Menu uses the existing root exit action. Root/profile/ledger changes belong to integration.

## Acceptance behavior

- Six property investigations followed by one changed-geometry rectangle check, then a calm finite finish. No automatic endless loop or punitive streak reset.
- Actual polygon vertices define the artwork and are checked in domain tests. Narrow/scalene triangles, turned and smaller squares, tall rectangles, and non-square rhombi are included.
- Square clues require **both** four equal sides and four square corners. Success explains that a square is also a rectangle. A rectangle clue specifying two longer and two shorter sides uniquely selects the non-square rectangle; it does not claim all rectangles need unequal nearby sides.
- The square investigation includes a non-square rhombus distractor. The rhombus has equal side lengths and zero right-angle corners; a rotated square still has four right-angle corners.
- Choice labels are neutral A–D. Accessibility descriptions speak the edge/corner information visible in the drawing; they do not announce a canonical shape name. Select chooses, swipes move focus, Play/Pause repeats the current clue without marking support, Hint provides property guidance, and Menu safely quits.
- Wrong answers keep choices enabled and provide a property hint instead of revealing the answer. A second hint traces edges/corners. Correct selections move focus to Next; repeated selects after success cannot duplicate result events.
- Checkpoints are keyed by frozen profile ID and activity. Clue identity, session ID, help level, misses, selections, completed items, UUID event IDs, timestamps, and completion remain intact across quit, background, and relaunch. Background/disappear cancel pending focus and narration work.
- Parent-controlled `ShapeDetectiveTVSessionStore.clear()` removes only this profile’s checkpoint and used-probe history. Other profiles and shared ledger records are untouched by this slice.
- Future-version, unreadable, wrong-type, or inconsistent saved data pauses gameplay. Original checkpoint bytes and probe history are preserved; no exposure, attempt replay, result, or gameplay write is allowed. Unknown/duplicate probe IDs are rejected, and unreadable history is never treated as unused probes. The child sees a calm parent-help notice and can return to All games. Only an explicit parent reset clears that frozen profile scope; reopen the game afterward to create a new session.
- Local persistence happens before event callbacks. Resuming replays saved UUID event IDs; the shared ledger must deduplicate them. Resuming a helped/missed item never upgrades its eventual success to unaided.
- Final check starts without app hints and changes rotation and aspect ratio. Twelve reviewed variants are reserved per profile on first exposure. A variant already exposed in an earlier session is excluded; after pool exhaustion the check is explicitly a revisit and `isFreshProbe` is false. Hint use or a miss still marks a fresh probe's eventual answer as supported.
- Results distinguish correct without observed app hints/retry from correct with app support. All adult help remains `.unknown`; family exploration is labelled. No mastery or verified absence of adult help is inferred.
- Optional room-object conversation asks about the flat face of a book/box. It is skippable, persists as a displayed prompt, and creates no verified transfer/answer evidence.
- Shape and Angle world cards control both foreground and background: dark labels on focused pale cards; white labels on unfocused dark cards. Focus is also shown with a border. Reduce Motion suppresses custom card scaling/animation; the existing Angle flight branch uses its reduced path.

## Verification

`ShapeDetectiveTVSessionTests` covers finite completion and duplicate input, open retries, checkpoint/event replay, help classification, fresh probe identity/geometry, exhausted pool honesty, optional conversation evidence, profile/corruption boundaries, and drawn geometry invariants. Storage preservation cases include a future schema, malformed bytes/types, unknown/duplicate probe history, missing exposed-probe history, invalid variants/counters, support downgrades, corruption during play, and recovery after explicit scoped reset.

`ShapeDetectiveUITests` covers a wrong answer followed by all seven correct investigations, focus progression, neutral accessible descriptions, finite ending, room prompt, Menu/reentry/relaunch/background, replay narration, the injected Reduce Motion branch, and a blocked checkpoint that remains paused after Menu/reentry. `AngleArcadeUITests` retains all nine missions, replay/progress/help/lifecycle regression checks and adds screenshots of Garden, Builder and Moon focused with reduced card motion.

Dedicated devices: TV 26.5 `701442C5-5AFD-4B9F-8ED0-61AF702B8939`; iOS 26.5 unit device `BA2428A3-079F-4409-86F2-DC4AF46222BF`. Derived data and results live separately under `/tmp/mather-enrichment-20261002/shape-angle-*` and `shape-unit-*`.

Simulator screenshots must be inspected for all three Angle focus states and representative shape retry, rotated square/rhombus, probe, and finale states. Validation status and exported screenshot paths are included in the slice handoff.

## Verified local results (2026-10-02)

- **18 domain/persistence tests passed**, including byte preservation, malformed history and explicit reset recovery: `/tmp/mather-enrichment-20261002/shape-storage-final-unit.xcresult`.
- **4 Shape remote UI tests passed**, including the paused/reentry flow: `/tmp/mather-enrichment-20261002/shape-storage-ui-verified.xcresult`.
- **5 Angle remote UI tests passed**, including all nine missions and all three focused world cards: `/tmp/mather-enrichment-20261002/angle-ui-verified.xcresult`.
- Representative screenshots were exported and inspected: retry, square beside non-square rhombus, rhombus, changed-geometry rectangle probe, finite ending, optional room prompt, Reduce Motion hint, restored checkpoint, and paused saved-data notice; plus Garden/Builder/Moon focus states. Evidence manifest: `/Users/ganesh/Documents/Codex/2026-10-02/task-5/evidence/manifest.json`.
- Focused Garden title pixels sampled from the screenshot are RGB `(18,34,54)` on a pale RGB `(245,249,251)` background, approximately **15.1:1 contrast**. The simulator's intermittent network toast is an OS overlay; the shape session works offline.
- `git diff --check` passed. Project include/generated-project changes used for validation are excluded from the slice commit.

## Limits

Simulator UI checks verify remote button semantics and exposed accessibility labels/values. They do not verify Siri Remote touchpad feel, couch-distance readability on a physical TV, actual VoiceOver audio behavior, or the device's system Reduce Motion setting. The Reduce Motion UI tests use test-only launch arguments scoped to the corresponding UI-test mode; real-device testing is still needed. All done and shared-ledger/profile integration require the coordinator's root injection and final integration checks. This slice does not merge or release; the coordinator owns PR integration and TestFlight.
