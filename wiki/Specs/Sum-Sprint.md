# Spec: Sum Memory (working title: Sum Sprint)

**Issue**: [#218](https://github.com/ganesh47/mather/issues/218)
**Status**: implementation-driving draft
**Author**: @grclaw
**Date**: 2026-04-17

## Overview

Sum Memory is Mather's implementation-driving spec for the playful fact-fluency lane previously researched under the working name Sum Sprint.

It is a feature-flagged fluency activity that appears after the child has shown
conceptual readiness in VS1. It delivers short, playful retrieval sessions using streak-based
motivation, fading pictorial support, and a lightweight spaced-repetition scheduler.

The first implementation target is **addition within 10**. Later expansions may extend to
within 20 and then within 100 with explicit place-value scaffolding.

If the shipped child-facing label remains **Sum Sprint**, the mechanics below still apply. "Sum Memory" is the current product-facing framing for this spec.

## User Stories

- As a child who already understands number bonds, I want quick playful recall rounds so that I build fluency without feeling tested.
- As a parent, I want Sum Sprint to unlock only when my child is ready so that fluency practice reinforces understanding instead of replacing it.
- As a product system, I want struggling facts to resurface more often so that practice time focuses on the right items.

## Acceptance Criteria

- [ ] Sum Sprint is gated behind `FeatureFlags.sumSprintEnabled` and is off by default.
- [ ] The activity is only surfaced to the child when readiness criteria are met, unless a parent explicitly overrides it.
- [ ] A session presents 8 to 10 prompts and then exits cleanly with a simple progress recap.
- [ ] No visible countdown timer appears anywhere in the child flow.
- [ ] The child sees streak and personal-best style motivation, not failure-forward scoring.
- [ ] Facts are selected by a lightweight adaptive scheduler that resurfaces weaker facts sooner.
- [ ] Pictorial support fades gradually after repeated independent success.
- [ ] v1 supports addition facts within 10 only.
- [ ] Parent-facing settings and summaries describe Sum Sprint as fluency practice, not first-teaching.

## Design

### SwiftUI Views

- `SumSprintEntryView`
  - parent-visible description / readiness entry point
- `SumSprintSessionView`
  - owns one sprint session loop and prompt progression
- `SumSprintPromptView`
  - renders the current fact with support stage
- `SumSprintAnswerRow`
  - large-tap answer chips or equivalent low-reading input
- `SumSprintRecapView`
  - streak recap and positive exit

### Data Model

Suggested types:

- `FactKey`
  - `lhs: Int`
  - `rhs: Int`
  - `operation: ArithmeticOperation`
  - `scope: SumSprintScope`

- `FactMastery`
  - `factKey: FactKey`
  - `supportStage: SupportStage`
  - `proficiencyBand: ProficiencyBand`
  - `consecutiveIndependentCorrect: Int`
  - `lastSeenAt: Date?`
  - `recentLatencyBand: ResponseLatencyBand`

- `SumSprintSessionState`
  - `currentPrompt`
  - `remainingPrompts`
  - `currentStreak`
  - `bestStreak`
  - `sessionResults`

- `SumSprintSessionSummary`
  - `presentedFacts`
  - `independentCorrectCount`
  - `supportedRescueCount`
  - `peakStreak`

### Navigation

- Entry should live behind a parent-approved route, not the default child home flow until the feature is validated.
- Child starts a sprint from a clear activity tile once available.
- Session exits automatically after the capped prompt count.
- Parent summary may later surface aggregate readiness / fluency notes.

### State Management

- Session state should live in a dedicated engine or reducer-like coordinator, not directly inside the view tree.
- Fact mastery persistence should be profile-scoped.
- Selection logic should be deterministic enough for tests while still adaptive in production.

## Readiness Gate

Default gate before child-facing availability:
- at least 5 completed VS1 sessions
- at least 80% first-attempt accuracy across recent core decomposition prompts
- no severe instability signal in recent sessions

Parent override may bypass the gate from settings.

## Scheduler Rules

- Facts in `new` or `supported` bands should repeat soon, potentially within the same session.
- Facts in `emerging` band should return after short session gaps.
- Facts in `solid` band should resurface periodically for retention checks.
- Incorrect or heavily hesitated responses should demote one band.
- Repeated independent success should promote one band.

## Support Fade Rules

Support stages:
- `full`
- `brief`
- `abstractFirst`

Promotion:
- move from `full` to `brief` after 5 independent correct results with acceptable latency
- move from `brief` to `abstractFirst` after another 5 mostly fast independent correct results

Demotion:
- two misses or repeated heavy hesitation drops one support stage

## Feature Flag

Flag name: `FeatureFlags.sumSprintEnabled`

## Out of Scope

- subtraction in v1
- sums within 20 or 100 in v1
- leaderboard or competitive social mechanics
- visible countdown timers
- typed numeric input
- teacher-facing dashboards
- full multi-skill adaptive platform logic

## Open Questions

- [ ] Which answer input pattern feels best on iPad for 5-year-olds?
- [ ] Should Bond Blast performance contribute to readiness gating?
- [ ] Do we need separate mastery by commuted pair (`3+4` vs `4+3`) or shared fact families?
- [ ] Where should parent-facing fluency progress appear first: Settings, Parent Summary, or both?

## References

- Related research: `wiki/Research/Sum-Sprint-Spaced-Repetition.md`
- Related research: `wiki/Research/Math-App-Vision.md`
- Related open issue history: `ganesh47/mather#179` (research) -> `ganesh47/mather#218` (implementation spec)
