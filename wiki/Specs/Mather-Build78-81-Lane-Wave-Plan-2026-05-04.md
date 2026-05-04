# Mather build 78–81 lane wave plan — 2026-05-04

Repo: `ganesh47/mather`  
Issue set: #946–#955, #957–#965  
Enrichment: `artifacts/mather-build78-81-wave-20260504/enrichment.md`

## Coordination principles

- Keep implementation slices dependency-safe and PR-sized.
- Use isolated worktrees under `/mnt/data/openclaw-parallel-workers/mather/build78-81-wave-20260504/`.
- Push branches/PRs early; use GitHub comments/PRs as durable progress surface.
- Do not close issues until fixes merge and validation is credible.
- If Xcode hits the known Swift compiler crash in `SettingsView.swift`, record exact evidence and still push safe branches with Linux/static checks plus Mac blocker notes.

## Wave 1 — safe independent / low product ambiguity

### Slice 1A — Gameplay navigation recovery

Issues: #947, #948, #957  
Branch/worktree: `fix/build78-81-gameplay-nav-retry-home` at `/mnt/data/openclaw-parallel-workers/mather/build78-81-wave-20260504/nav-retry-home`  
Parallelism: can run independently of all other slices.

Scope:

- Add Home/Done escape hatch to `GameplayThreadView` when launched with `AppModel`.
- Make Retry force a fresh active-stage instance and remove current completed result when replaying.
- Make Back from completed summary reopen a playable previous stage instead of rendering summary forever.
- Add navigation-state regression tests.

Validation:

- `GameplayStageViewModelTests` targeted test suite.
- Full Build & Test on macOS if runner is stable.

Status: implementation started.

### Slice 1B — Flip-memory preview bug

Issues: #951; helps #958  
Parallelism: can run with 1A, but validate after 1A if both touch shared gameplay shell.

Scope:

- Add flip/preview state for right-side cards in `.flipMemory` mode.
- Right-card tap with no selected left card reveals/holds preview without mismatch haptic.
- Right-card tap with selected left evaluates match.
- Update accessibility labels and tests.

Validation:

- `GameplayStageViewModelTests.flipMemory...` regression expanded.
- UI smoke on Country/Water Cycle flip-memory.

### Slice 1C — Shared card asset rendering / hero flashcard

Issues: #959; partial prerequisite for #949  
Parallelism: can run independently after code owner decides image sizing defaults.

Scope:

- `GameplayDisplayCard` renders `Image(visualAssetName)` when present.
- Flashcard stage passes a hero/single-card variant so one-card screens use available space.
- Keep emoji/text fallback and accessibility.

Validation:

- Tests assert card model preserves visual asset names.
- Snapshot/screenshot smoke for Water Cycle/Country flashcard.

## Wave 2 — shared shell improvements / needs one validation lane

### Slice 2A — Stage overview strip

Issues: #961; supports geometry unification later.

Scope:

- Add stage strip to `GameplayThreadView` showing all stages and done/current/locked states.
- Decide whether stage taps replay completed stages or are preview-only.
- Ensure compact layout stays readable.

Needs validation lane because it changes chrome on every gameplay thread.

### Slice 2B — Pairing turns and spaced-repetition chunking

Issues: #952; helps #958 and #960.

Scope:

- Present 3–4 pair turns instead of all pairs at once.
- Track per-turn matched/missed; requeue misses later in session.
- Keep progress store updates accurate.

Needs careful validation across Country, Fruit, Water Cycle, Easy Memory, Flip Memory, Bond Blast.

### Slice 2C — Country duplicate diversification

Issue: #960.

Scope:

- Prefer unique `entityID` within a turn.
- If an entity must repeat, annotate property focus on the prompt card.
- Add scheduler/content-builder tests.

Can run after 2B or alongside if merge coordination is tight.

## Wave 3 — product design / larger refactors

### Slice 3A — Bond Blast interaction consistency

Issue: #950.

Scope:

- Extract or adapt Numbers `BondMatchView` mechanics into shared `BondBlastInteraction`.
- Support domain-specific display items.
- Replace generic pairing-shell Bond Blast for gameplay threads.

Needs design/validation: named stage behavior changes across domains.

### Slice 3B — Map-shape country silhouettes

Issue: #949; depends on or benefits from Slice 1C.

Scope:

- Add vector/image silhouette assets or SwiftUI outline renderer.
- Replace textual map-shape primary visual with actual country outline.
- Keep text as subtitle/accessibility.

Needs asset work; likely separate PR.

### Slice 3C — Geometry labs stage unification

Issues: #962, #963, #964.

Scope:

- Angle Lab wrapper: lesson/vocab → visual matching → Angle Cannon → protractor → quiz/score.
- Symmetry Lab wrapper: learn/look → memory/recognition → fold play → challenge → score.
- Shape Lab adapter/shared-stage conversion.

Needs one focused coordinator because these are product-architecture changes, not simple bug fixes.

### Slice 3D — Home/Labs IA and progressive disclosure

Issues: #946, #953, #954, #955.

Scope:

- Promote Home primary choices to Labs/Games.
- Reduce top-level copy density.
- Surface guided/browse streams: Numbers, Geometry, Physics, Chemistry, Geography/Map World.
- Collapse parent/timing details in lab detail cards.

Needs design confirmation only for labels/order; implementation can then split into Home IA and Lab detail sub-PRs.

## Tracking issue usage

Use #965 as the concise coordinator-tracking surface because it is the umbrella-like VS1 progress/check issue in this inventory. The comment should link to:

- this enrichment/plan artifact location,
- the first implementation PR,
- issue clusters and status.

Do not mark #965 as fixing the TestFlight issues unless a dedicated tracking/meta convention is desired.
