# TestFlight feedback triage: #349, #368-#372

Date: 2026-04-27

Builds covered: TestFlight build 53 (#349) and build 54 (#368-#372)

Scope: cluster feedback into durable implementation / validation lanes without making risky code changes.

## Executive read

The feedback cluster splits into four themes:

1. **Make & Break graduation / de-gating** — #349 and #369 are duplicate product signals asking to remove the parent-visible `Make & Break loop v2` rollout setting and make the reopened loop built in.
2. **Compass Angles device-direction bug** — #368 is a distinct sensor-sign / success-display validation bug. It should stay as its own narrow fix lane.
3. **Memory category visual assets** — #370 and #372 ask for picture/name matching in Fishes and Planets. Planets is covered by the active #352 asset lane; Fishes needs a sibling follow-up unless the #352 scope is deliberately expanded.
4. **Memory Learn interactive conversation** — #371 is a feature request for a child-safe conversational Jupiter / card guide. It is adjacent to #353, but larger than the current one-shot learn-more/read-aloud path and should be scoped separately or explicitly added to #353 after the deterministic learn-more baseline is stable.

## Issue-by-issue disposition

| Feedback | Theme | Current lane | Disposition | Rationale / closure rule |
| --- | --- | --- | --- | --- |
| #349 | Make & Break graduation | #351 + #222 | **Covered / duplicate signal; do not close yet** | Same ask as #369, already linked to #351. Close only when a real graduation/de-gating decision lands, or if #351 records a no-go with explicit rationale. |
| #369 | Make & Break graduation | #351 + #222 | **Duplicate of #349 / #351; candidate to close after comment** | Build-54 repeat of #349's request. It adds evidence that the visible V2 toggle feels like product debt, but it does not require a separate implementation lane. |
| #368 | Compass Angles direction | #354 validation can observe; likely new narrow bug lane | **Needs focused fix/validation issue or keep #368 as the fix lane** | Tester reports right/left inversion. Repo has `MotionService.relativeYaw` contract (`positive = right`) but no real-device sign regression. Also screenshot may show success text next to a non-target degree. |
| #370 | Memory Fishes visual assets | No exact existing lane | **Needs narrow follow-up** | Mechanics already support picture/name matching, but fish cards are text-prompt visuals. #352 covers Planets + Vehicles only, so Fishes should get a sibling asset/provenance lane unless #352 is intentionally broadened. |
| #371 | Memory Learn conversation | #353 adjacent | **Needs scoped follow-up or explicit #353 expansion** | Existing #353 is Apple-Intelligence learn-more/read-aloud/fallback, with non-goal of unrestricted chat. Interactive Jupiter conversation needs child-safe turn-taking, availability gating, fallback, and parental/safety constraints. |
| #372 | Memory Planets visual assets | #352 | **Covered by #352; do not close until assets imported** | PRs #375/#376 landed planning and source-candidate artifacts, but no images are imported and cards are not switched to `.asset(...)` yet. Close when #352's asset-import slice makes Planets picture/name-backed. |

## Theme clusters and lane mapping

### A. Make & Break graduation / de-gating (#349, #369)

**Feedback:** remove the Make & Break V2 setting / keep it always on.

**Current truth:**
- #351 is the right coordination lane tying #349 to #222.
- #222 is now closed as the historic/runtime closeout lane, but final product posture still depends on the current validation / release recommendation rather than the old issue state alone.
- The code path intentionally kept `makeBreakLoopV2Enabled` visible/default-off while validation was pending.

**Recommendation:**
- Treat #369 as a duplicate of #349 and #351.
- Do not close #349 solely because #351 exists; close it from the actual de-gating/default-on PR or from a documented no-go decision.
- If closing #369 now, leave a comment that it is a duplicate signal folded into #349/#351 and that no separate code path is needed.

### B. Compass Angles physical direction correctness (#368)

**Feedback:** tester has to turn left when the app asks right; readings may need inversion.

**Current truth:**
- `CompassAnglesView` treats positive target degrees as right turns.
- `MotionService.relativeYaw` is documented as positive = turned right, but the live CoreMotion sign convention is not device-validated in tests.
- #354's UI-review lane can catch screenshots/layout, but it will not prove physical yaw sign without device/simulator-injected motion evidence.

**Recommendation:**
- Keep #368 open as the narrow bug lane, or open a dedicated `fix(compass): validate and correct yaw sign` issue if the TestFlight issue should remain raw feedback only.
- Minimum fix criteria:
  - device log confirming right/left sign from the app's supported holding/orientation posture,
  - normalization or inversion at `MotionService` or Compass boundary,
  - regression coverage for the chosen sign convention,
  - decision on whether success-state display should lock to target to avoid `12°` beside `You turned 90°!`.

### C. Memory visual category assets (#370, #372)

**Feedback:** Fishes and Planets should compare real pictures with names.

**Current truth:**
- The Memory model already supports picture/name pairing.
- Birds use asset-backed cards.
- Planets/fishes still use `.text(...)` picture representations.
- #352 covers Planets + Vehicles asset planning and source candidates; PRs #375/#376 advanced planning only, not image import.

**Recommendation:**
- #372 is covered by #352 and should remain open until actual planet assets are imported and wired.
- #370 is not covered by #352 as currently written; create a sibling Fishes asset/provenance issue, or explicitly expand #352 to Planets + Vehicles + Fishes.
- Add tests that visual educational decks cannot regress to text-only picture cards once each deck is graduated.

### D. Memory Learn interactive conversation (#371)

**Feedback:** from Jupiter Learn, start an interactive Jupiter conversation using Apple Intelligence / interactive speak.

**Current truth:**
- #353 covers Apple-Intelligence learn-more/fallback work, but explicitly avoids an unrestricted chat experience.
- `SpeechService` supports deterministic read-aloud; it does not support speech recognition, turn-taking, conversational state, or child-safety moderation.

**Recommendation:**
- Keep #371 open as product discovery input unless #353 is expanded with explicit conversational acceptance criteria.
- Prefer a new follow-up after #353's deterministic baseline: `feat(memory): child-safe Ask About This Card conversation`.
- Gate it behind availability/parent/safety constraints and keep one-shot Read Aloud as fallback.

## Close / duplicate candidates

Safe-to-close now **only after a comment**, if maintainers want to reduce duplicate noise:

- **#369** → duplicate evidence for #349/#351. Suggested closure comment: folded into #349 and #351; closure waits on Make & Break graduation/de-gating outcome, not a separate build-54 issue.

Not safe to close yet:

- **#349** — still represents the original product signal; close from concrete de-gating/no-go outcome.
- **#368** — unique physical-direction bug.
- **#370** — fish asset gap lacks an exact lane.
- **#371** — conversational feature request is broader than current #353 acceptance criteria.
- **#372** — covered by #352, but only planning/provenance has landed; image import/wiring remains.

## Suggested next narrow issues

1. `fix(compass): validate and correct Compass Angles yaw direction` — if #368 should not itself be the implementation lane.
2. `feat(memory): add image-backed Fishes deck with provenance` — sibling to #352 for fish visuals.
3. `feat(memory): child-safe Ask About This Card conversation` — dependent on #353 deterministic learn-more baseline and #352/#fish visual grounding.

## Lightweight validation performed

- Compared raw TestFlight feedback issues #349 and #368-#372 plus enrichment comments.
- Checked current `main` after PR #376 merge.
- Inspected current lane issues #222, #351, #352, #353, #354, #355, and PR #376.
- Confirmed this artifact is documentation-only; no app code or workflow behavior changed.
