# Mather build 78–81 lane wave enrichment — open issues #946–#965

Created: 2026-05-04 18:05 UTC  
Repo: `ganesh47/mather`  
Base inspected: `origin/main` at `de47b6b` (`feat: polish labs games artwork metadata (#956)`)  
Raw issue snapshot: `artifacts/mather-build78-81-wave-20260504/open-issues-full.json`  
Readable issue snapshot: `artifacts/mather-build78-81-wave-20260504/open-issues-readable.md`  
Downloaded screenshots: `artifacts/mather-build78-81-wave-20260504/screenshots/issue-946-1.jpg` … `issue-964-1.jpg`

## 0. Executive read

This queue is mostly one coherent TestFlight theme: **the new cross-domain gameplay-thread/lab experience is useful, but it must inherit the product’s standard stage model, visible recovery controls, visual card treatment, and compact child-friendly pacing.**

The safest immediate implementation slice is the navigation/recovery cluster:

- #947 — Retry does not actually reset the stage; no Home route.
- #948 — Back from completed summary does not return to playable stage.
- #957 — Gameplay thread lacks an obvious Home escape hatch.

Those share a small surface (`GameplayStageNavigationState` + `GameplayThreadView`) and can be fixed without disturbing domain content or stage model decisions.

## 1. Issue inventory and enriched classification

| Issue | Build | Visible / inferred area | Feedback | Cluster | Likely root cause | Acceptance summary |
| --- | --- | --- | --- | --- | --- | --- |
| #965 | n/a | VS1 milestone progress check | VS1 milestone says 35/35 closed, 0 open | Tracking / umbrella | Not a product bug; useful coordinator anchor | Use as tracking comment surface; do not close product bugs through it |
| #964 | 81 | Shape Lab / ShapeGeometry | Shape Lab UX diverges from standard stages/cards | Geometry labs stage unification | `ShapeGeometryLabView` uses local `ShapeGeometryStage`, bespoke picker/progress/card UI, not `GameplayThreadDefinition`/shared cards | Shape Lab either wraps into shared stage model or has explicit adapter using shared stage strip, card components, retry/back/home conventions |
| #963 | 81 | Symmetry Fold / Symmetry Lab | Symmetry Lab does not follow stage pattern | Geometry labs stage unification | `RootView` routes directly to standalone `SymmetryFoldView`; no shared staged thread/session plan | Symmetry Lab shows a multi-stage path: learn/look, memory/recognize, fold play, challenge, score; current fold remains core Play stage |
| #962 | 81 | Angle Cannon / Angle Lab | Angle Cannon should become Angle Lab with lessons/stages | Geometry labs stage unification | `RootView` routes directly to `AngleCannonView`; angle tools are separate, not a staged lab | Angle Lab staged wrapper exists with vocabulary/visual matching, cannon play, protractor practice, score |
| #961 | 81 | Gameplay thread first stage | Need to show all stages, not just first stage | Gameplay stage overview | `GameplayThreadView` only renders current active stage; header says Stage X/Y but no full stage overview/list | Add standard stage strip/overview showing all stages with locked/current/done/replay states |
| #960 | 81 | Country Cards gameplay | Countries repeat in the round | Gameplay round diversification | `SpacedRepetitionScheduler` samples entity-property pairs; same country appears with different facts but left title stays generic country name | One property per country per turn, or visually label property focus when an entity repeats |
| #959 | 81 | Single-card / flashcard display | Card images should be bigger; one card can be large | Shared card visuals | `GameplayDisplayCard` renders `visualKey` text only in small circle; ignores `visualAssetName`; flashcards reuse grid-sized card | Render `Image(visualAssetName)` when present and add hero/single-card visual sizing for flashcards |
| #958 | 81 | Water Cycle thread stage | Stage is buggy/not working in Water Cycle | Shared pairing shell / Water Cycle content | Water Cycle uses shared pairing shell; known defects: hidden right cards do not flip, generic Bond Blast shell, possible repeated step names in 8-item mixed stage | Fix shared pairing mechanics first, then Water Cycle-specific turn sizing/visual cycle diagram if needed |
| #957 | 81 | Gameplay thread controls | No way to navigate Home | Navigation/recovery | `GameplayThreadView` controls are Back/Retry/score only; appModel route home action not exposed | Home/Done control visible in active and summary states; routes through `appModel.engine.showHome()` |
| #955 | 78 | Top-level / Labs menu | Menu options are crowded | IA / compact menu hierarchy | `HomeView` exposes two large feature cards plus secondary actions; `LabView` and lane cards carry dense copy | Top-level uses two primary choices `Labs` and `Games`; secondary parent/settings de-emphasized; compact copy reduced |
| #954 | 78 | Lab lane detail / plan cards | Screen crowded and too detailed | Lab progressive disclosure | `LabLaneDetailView` shows title/subtitle/mastery/length/next/resume + every stage card with parent and timing copy | Default child view shows one recommended action + compact stage strip; parent/timing details behind disclosure |
| #953 | 78 | Labs landing | Missing streams: Physics, Geometry, Chemistry, Geography | Labs breadth visibility | `CapabilityLaneID` and default lanes include streams, but `GuidedLabPath.phaseOne` only has Numbers path, making breadth feel absent | Add first-class guided paths or make lane grid primary; learner-facing `Map & World`/Geography label clear |
| #952 | 78 | Pairing / flip-memory stage | Too much scrolling; use multiple turns and spaced repetition | Gameplay turn chunking | `GameplayPairingStageShell` renders all left/right cards in two `LazyVGrid`s; Country stages allow 8–10 items | Pairing stages paginate into 3–4 pair turns; misses requeue later; no compact-device scrolling through a full grid |
| #951 | 78 | Flip Memory | Tap does not open hidden card | Flip-memory interaction bug | `chooseRight` immediately returns false when no left card is selected; `shouldConcealRight` stays true | Hidden right-card tap previews/reveals in flip mode; matching evaluates only when a left prompt is selected |
| #950 | 78 | Bond Blast stage | Generic stage is not Numbers Bond Blast | Bond Blast consistency | `BondBlastStageView` uses generic pairing shell, while VS1 uses bespoke `BondMatchView` | Shared/domain-adaptable Bond Blast interaction preserves Numbers mental model with non-number content |
| #949 | 78 | Country map-shape cards | Draw country outline instead of textual description | Geography visual assets | `map-shape` property values are text; `visualKey` is `🗺️`; no outline asset rendering | Add map-outline/vector assets; card primary visual is silhouette; text moves to subtitle/accessibility |
| #948 | 78 | Gameplay summary / Back | Back does not go to stage play | Navigation/recovery | `isComplete` remains true because all stage results remain after `goBack`; summary keeps rendering | Back from summary reopens previous playable stage or stage replay mode; regression test exists |
| #947 | 78 | Gameplay summary / controls | Retry does not work; no Home | Navigation/recovery | `retryCurrentStage()` only resets timestamp; child view state/result not reset; no Home action | Retry increments stage instance/seed and removes current result when needed; Home visible; regression test exists |
| #946 | 78 | Main menu | Main menu should have two streams, Labs and Games | IA / compact menu hierarchy | `HomeView` has `Make & Break` and `Explorer Lab` as peer top-level tiles; Labs/Games split exists deeper in `LabView` | Home IA promotes `Labs` and `Games`; Make & Break becomes entry under suitable stream |

## 2. Duplicate / dependency clusters

### A. Navigation and recovery — #947, #948, #957

**Intent:** Gameplay threads must never trap child/parent users in a stage or summary. Back, Retry, and Home should reverse/restart/exit predictably.

**Implementation surface:**

- `Domain/GameplayStageViewModels.swift`
  - `GameplayStageNavigationState.goBack`
  - `GameplayStageNavigationState.retryCurrentStage`
  - `isComplete(for:)`
- `Features/GameplayStages/GameplayThreadView.swift`
  - app-model initializer
  - controls row
  - active stage view identity/seed
- Tests: `Tests/MatherTests/GameplayStageViewModelTests.swift`

**Root cause:** Navigation state tracks completed stage results, but Back/Retry do not alter those results or force a fresh child stage instance. Since `activeStage` is hidden when `isComplete` is true, summary stays visible.

**Acceptance:**

- Active stage and summary both expose a Home/Done route to the app home.
- Retry resets the current playable stage, including child `@State` and round seed/identity.
- Retry from summary reopens the last stage instead of staying on summary.
- Back from complete summary reopens the previous playable stage or explicit replay mode.
- Regression tests cover retry/back state transitions.

### B. Shared gameplay shell quality — #951, #952, #958, #960, #961

**Intent:** Country/Water Cycle/Fruit gameplay threads should feel like stage-based, turn-based children’s activities, not large static grids.

**Root causes:**

- `GameplayThreadView` has no stage overview (#961).
- `GameplayPairingStageShell` lays out all pairs at once (#952).
- Flip memory conceals answer cards but does not support preview reveal (#951).
- Round selection works at entity-property level, so country names repeat without context (#960).
- Water Cycle inherits every shell problem and adds sequential science semantics (#958).

**Acceptance:**

- Stage overview/strip shows the entire thread.
- Pairing stages use compact turns (3–4 pairs) with miss requeue.
- Flip cards reveal on tap before match evaluation.
- Country rounds avoid unlabelled duplicate country prompts in one turn.
- Water Cycle is regression-tested after shell fixes, ideally with a cycle-order visual.

### C. Card visual asset use — #949, #959

**Intent:** Visual concepts should be visual. When a card has art, the art should dominate the card, especially on single-card flashcard screens.

**Root causes:**

- `GameplayDisplayCard` ignores `visualAssetName` and renders `visualKey` text/emoji in a small circular area.
- Country `map-shape` currently has text descriptions instead of outline assets.

**Acceptance:**

- Shared card supports image assets with text/emoji fallback.
- Flashcard/single-card stage uses a hero card variant.
- Country map-shape property has silhouette assets or vector outlines and keeps descriptions for accessibility/subtitle.

### D. Geometry lab stage unification — #962, #963, #964

**Intent:** Angle, Symmetry, and Shape should feel like coherent Labs with lessons/stages, not standalone one-off games.

**Root causes:** standalone views (`AngleCannonView`, `SymmetryFoldView`, `ShapeGeometryLabView`) bypass the shared gameplay/lab stage model.

**Acceptance:**

- Angle Lab: vocabulary/lesson → visual matching → Angle Cannon play → protractor practice → quiz/score.
- Symmetry Lab: learn/look → recognition/memory → fold play → challenge → score.
- Shape Lab: uses shared stage/card chrome or a deliberate adapter with the same controls and stage strip.

**Risk:** bigger product-design slice. Should run after navigation/shared-card primitives unless the user wants a dedicated geometry wave.

### E. Information architecture / compact density — #946, #953, #954, #955

**Intent:** The product hierarchy should be simple at the top and progressively disclose detail.

**Root causes:** Home/Labs screens expose too much explanatory and planning copy at once, while guided paths underrepresent non-number streams.

**Acceptance:**

- Home primary IA is `Labs` and `Games`.
- Parent/settings actions move to secondary chrome.
- Labs clearly show Geometry, Physics, Chemistry, Geography/Map World, Numbers.
- Lab lane detail defaults to one next action + stage strip; parent/timing copy is disclosed.

## 3. Asset / screenshot opportunities

- Keep downloaded screenshots in the workspace artifact bundle while Apple signed URLs remain valid.
- Add/confirm asset inventory for:
  - country map silhouettes (`map-shape`, #949), ideally vector/PDF or SwiftUI shape fallback;
  - flag/country images already referenced through `visualAssetName`;
  - Water Cycle art already referenced by `MemoryWaterCycle*` assets;
  - larger flashcard hero render path (#959).
- Screenshot regression candidates:
  - compact gameplay thread summary with Home/Back/Retry (#947/#948/#957);
  - flip-memory hidden-card preview (#951);
  - pair-turn pagination on compact device (#952);
  - Home menu Labs/Games (#946/#955).

## 4. Suggested first-wave acceptance gates

- Unit tests: navigation state back/retry transitions; flip-card preview; round diversification if implemented.
- Swift/Xcode: Build & Test on macOS runner if available.
- UI smoke: iPhone compact screenshots for Home, gameplay active stage, gameplay summary, Water Cycle flip/pairing.
- GitHub: do not close issues until PR merged and validation evidence is posted.
