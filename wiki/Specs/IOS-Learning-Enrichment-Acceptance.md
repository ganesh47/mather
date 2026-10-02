# iOS learning enrichment acceptance

This slice extends the existing local quest flow and Parent Summary. New sessions select a bundled, reviewed variant deterministically for the selected child. A saved session retains its full variant, content snapshot, ordinal, probe index, support history and event UUIDs. Legacy checkpoints retain their original task and single Numbers transfer probe.

## Reviewed Numbers bank

Practice keeps a whole of ten and allows free choice of its parts. Remember and Play use the same task identity; Play is rehearsal after the app explains the answer. Each new bank session then presents two changed-whole, changed-context probes using grouped objects rather than the garden frame.

| Variant | Initial practice part | First probe | Answer | Second probe | Answer |
| --- | ---: | --- | ---: | --- | ---: |
| Picnic | 6 | 8 apples, 3 packed | 5 | 7 buttons, 1 packed | 6 |
| Building | 4 | 9 blocks, 4 packed | 5 | 6 shells, 2 packed | 4 |
| Market | 2 | 7 pears, 3 packed | 4 | 9 stones, 6 packed | 3 |

Every answer is whole minus known part; quantities remain in 0...10. Probe IDs are unique across the bank. Choice generation includes the correct answer and distinct valid distractors, including the zero and ten endpoints. Both probes must finish before the Challenge stage completes. A repeated bank item is marked `isFreshProbe == false` for that child. A retry after app feedback remains supported, including after resume.

After Numbers bank correctness passed its initial tests, two frozen variations were added for each other pilot: rotated rectangular door / triangular sign, cold cup / cold bottle condensation, and first / second switch open in a pretend two-switch circuit. Only circuit prediction is a probe; its repair after feedback is supported practice. Older Angles and Symmetry transfer items have no verified freshness metadata.

## Child and parent acceptance checks

- Recognition choices use neutral picture labels and descriptive accessibility labels. Shape, angle and symmetry labels do not name the answer; circuit prediction conceals the bulb state until the child predicts.
- On the reserved compact iPhone simulator, Help and the primary action remain visible and hittable before and after scrolling. Instructions and support continue through the existing speech service.
- Numbers, Shapes, Water and Circuit complete through UI, domain and stored item evidence. Numbers shows two distinct probes and Parent Summary reports `2/2` fresh probes without app hints for an unsupported first session.
- Saving and reopening preserves the selected child's manipulation state, frozen downloaded content, support history and exact first or second probe. Replayed attempts preserve UUIDs for integration-ledger deduplication.
- Parent Summary groups retries by task, shows concept and latest date, includes attempted-task and fresh-probe denominators, and provides a concrete offscreen next step. Correct without an app hint leaves adult help unknown. Older transfer evidence remains history and does not count as fresh.
- Optional parent reports save concept, date, outcome and frozen offscreen prompt locally. They remain separate from app-observed attempts. Selected-child reset preserves other children; history is bounded to 30 reports per child.
- Corrupt JSON, future envelopes and unknown fields block parent-report writes and selected-child deletion while preserving the original bytes. The parent sees an error on failed save; the sheet stays open. Explicit clear-all is the recovery path. Existing array-format reports remain readable, and appending a report preserves another child's history.

Each of the six concepts has a specific household prompt. Circuit prompts use paper drawings and avoid household power. No child recording or external AI service is used.

## Validation evidence

Base: `c475327111b4eb72850ef9cc311c1d99fe7d3bea`, plus the coordinator's compatible optional evidence contract (original `08b08a286e2426e3099277073e234b657b79ec7e`).

The suite uses the exclusively reserved `Mather-Enrichment-Compact` simulator, UUID `C101D092-EBE0-4DE8-B0B2-BC29748D0E22`, separate derived data at `/tmp/mather-enrichment-20261002/ios-learning-derived`, and an ephemeral XcodeGen project outside the source worktree. UI tests run sequentially.

- `/tmp/mather-enrichment-20261002/ios-acceptance-final.xcresult`: 24 domain tests and six offline UI tests passed, covering all four pilots, compact actions, optional parent reporting and exact resume.
- `/tmp/mather-enrichment-20261002/ios-storage-regression.xcresult`: 25 domain tests and two affected UI tests passed, covering storage preservation, second-probe resume and the Parent Summary / Numbers assertions.
- `git diff --check` passed before commit.

The existing network download UI test is not part of the offline acceptance run. Frozen downloaded-content behavior is covered in domain tests; new download delivery still requires integration/network validation. Simulator acceptance establishes application behavior, not a claim about a child's learning or educational mastery.

## Integration contract

Only the slice commit should be cherry-picked; the coordinator already owns the shared contract. No `project.yml`, tracked Xcode project, AppModel, shared evidence schema, release workflow or other slice files are changed here.

AppModel reset hooks are owned by the coordinator:

- `ParentOffscreenObservationStore.clearSelectedProfile(profileID:) -> Bool` returns false when unreadable history was preserved.
- `ParentOffscreenObservationStore.clearAllProfiles()` explicitly removes all parent reports, including unreadable storage.
- Existing `QuestCheckpointStore.reset()` and `clearAllProfiles()` now clear variant rotation and used-probe metadata along with checkpoints.

The coordinator also adds the Parent Summary companion entry point and a confirmed “Delete all parent reports” Settings recovery action when storage is unreadable. PR merge and TestFlight release remain coordinator responsibilities.
