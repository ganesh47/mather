# Parent manual mission continuation and Room Quest proof

## Scope and behavior

“Continue an idea” works entirely offline on iOS and tvOS. A parent prepares a reviewed build-5 or build-10 mission, shows/copies the code on one device, enters it using the native TV or handheld keyboard on another, reviews the safe prompt, and approves a local recipient. A code has six groups of six symbols. iOS offers selectable text and an explicit parent ShareLink; the app never sends anything automatically.

This continues a mission idea, not an exact session, synchronized mastery or native Handoff. The code contains no learner name/ID, attempts, history, observation, answer, timestamps or assistance claims. CRC-16 catches transcription errors but does not authenticate a sender or encrypt the code. A shorter server lookup code would require infrastructure; this 36-symbol self-contained payload avoids it. Parents should review codes from known devices themselves.

The companion asks a grown-up to provide large safe blocks/toys at a clear reachable table. The child makes two groups, counts the whole and moves groups closer to explore conservation. Narration is repeatable and honors the audio setting; VoiceOver avoids overlapping narration. A parent can reveal the pictorial/symbolic example after object play and report alone, with help or not yet. App performance is not measured. Parent reports remain local, separate from ItemAttempt/ActivityResult; absent reporting and not-yet assistance are unknown. No camera, child voice, uploads, accounts or new entitlements are involved.

## Exact integration hooks

```swift
@MainActor
LearningCompanionView(
    profileID: selectedLocalLearnerID,
    displayName: selectedLocalLearnerName,
    store: companionStore,             // optional; default .init()
    audioEnabled: parentAudioEnabled,  // optional; default true
    onClose: closeCompanion            // optional; default nil uses environment dismiss
)
```

Open from parent-controlled iOS Parent Summary / TV Family Guide **after** local learner selection. Keep old unknown device history family/device scoped. Share one store instance with local reset controls when practical. This slice changes no app entry points, AppModel, TV root, project/release files or shared evidence beyond the coordinator's explicit prerequisite commit.

`LearningHandoffStore` is `@MainActor @Observable` and accepts `init(defaults: UserDefaults = .standard)`. It provides:

- `assignment(profileID:) -> LearningHandoffAssignment?`
- `preview(code:) throws -> LearningHandoffPayload`, with no consuming/mapping side effects
- `createMission(profileID:target:parentApproved:replacingReceiptID: UUID? = nil) throws -> LearningHandoffAssignment`
- `approveImport(code:recipientProfileID:parentApproved:replacingReceiptID: UUID? = nil) throws -> LearningHandoffAssignment`
- `exportCode(profileID:parentApproved:) throws -> String`
- `recordObservation(profileID:receiptID:outcome:parentApproved:at: Date = .now) throws -> ParentRoomQuestObservation`
- `observations(profileID:) -> [ParentRoomQuestObservation]`
- `observation(profileID:receiptID:) -> ParentRoomQuestObservation?`
- `unlink(profileID:) throws`: removes current assignment, preserves local reports and anonymous retired receipts
- `reset(profileID:) throws`: removes this learner's assignments/reports, preserves anonymous replay receipts
- `resetAll()`: nonthrowing deletion of all companion data, including receipts; old codes can then be entered again
- `storageError: LearningHandoffError?`: fail-closed corrupt/future local storage status, recover using explicit resetAll

Wire `try companionStore.reset(profileID:)` into learner deletion/reset and `companionStore.resetAll()` into full app data reset. Handle partial-reset errors; damaged storage requires all-companion deletion because partial contents cannot be trusted. The key is `mather.learning-companion.v1`; no other app persistence is touched.

One code receipt may be consumed once device-wide, including codes prepared locally. It cannot later be remapped to another learner. Assignment and parent observation event IDs are stable strings derived from receipt UUID with distinct event prefixes. Parent reports are immutable per receipt; retries add nothing. A replacement carries the receipt ID captured at review, and a stale approval fails. Open store instances refresh before writing, so an old screen cannot restore deleted data or overwrite another learner's assignment. The 256-receipt limit refuses new codes rather than silently dropping replay protection. Local devices resolve competing missions through explicit parent replacement, with no cross-device reconciliation.

## File inclusion

iOS uses existing directory includes. Coordinator must add these three paths to `MatherTV` sources in project.yml and regenerate the project:

```yaml
- path: Domain/LearningHandoff.swift
- path: Services/LearningHandoffStore.swift
- path: Features/LearningCompanion/LearningCompanionView.swift
```

`SpeechService.swift` is already included on TV. Domain/store have no shared-evidence or platform dependencies. The 14 Swift Testing cases in `Tests/MatherTests/LearningHandoffTests.swift` enter the existing iOS unit test target automatically. `Tests/CompanionProofUITests` and `scripts/CompanionProofApp.swift` belong only to the temporary synthetic UI harness, not release targets.

## Validation and reproduction

All test data is synthetic. The standalone domain suite exercises an independently generated binary fixture, safe quantities, future schema/unsupported mission rejection with valid checksums, malformed input, canonical padding, explicit mapping/approval, relaunch replay, stale replacement, separate store instances, reported observation dedupe, deletion and bounded receipt retention.

```bash
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer bash scripts/test_learning_handoff.sh
bash scripts/prepare_learning_companion_qa.sh /tmp/mather-enrichment-20261002/companion-qa
```

The harness uses real source with synthetic-only entry points and separate bundle IDs. Build/test schemes `CompanionIOS` and `CompanionTV` with `-parallel-testing-enabled NO`, dedicated derived data, and your reserved simulator IDs. Do not use another worker's simulator. This worker's reservations were iOS `1D279B90-C30B-487B-8845-7F1DA6CC19AD` (iPhone 17e / iOS 26.5) and TV `399D0BC3-5266-46A2-B0E8-E6E4A2E0C590` (1080p / tvOS 26.5).

Validated: 14 domain cases, real-source iOS and tvOS builds, 2 compact-phone UI cases, 2 TV UI cases including actual code typing through native keyboard, receipt import/approval/re-export, remote focus and horizontal bounds. The final phone deletion-confirmation regression passed. Screenshots were exported and visually inspected. An attempted TV native deletion-dialog automation could not reliably target its nested duplicate accessibility wrappers; this exact dialog interaction remains for coordinator validation, while TV navigation to the data controls and domain unlink/reset hooks are tested. The optional Done/onClose hook is compile checked on both platforms. Full integrated app regression/release validation remains with the integration coordinator.

Local proof bundles/logs (not committed): `/tmp/mather-enrichment-20261002/continuity-domain-tests.log`, `continuity-ios-ui.xcresult` (2 phone cases), `continuity-ios-deletion-retry.xcresult` (final phone deletion check), `continuity-tv-ui-verified.xcresult` (2 TV cases including actual keyboard import/re-export), `continuity-ios-screens/`, `continuity-tv-verified-screens/` under the same parent. The failed TV native-dialog attempt is preserved in `continuity-tv-deletion-pass.xcresult`; it is not claimed as a passing result. No merge or release is performed by this slice.
