# Research: Sum Sprint — Spaced-Repetition Fluency Practice

**Issue**: [ganesh47/mather#179](https://github.com/ganesh47/mather/issues/179)
**Status**: Completed
**Date**: 2026-04-17

---

## Overview

This document researches and frames **Sum Sprint**, a new Mather activity focused on
fluency after conceptual mastery. The product job is to extend the child beyond VS1's
"Make & Break to 10" loop into repeated, low-pressure retrieval across sums to 10,
20, and eventually 100, without collapsing into worksheet-style drill.

The core recommendation is:
- use a **streak + personal-best** motivation layer, not a visible countdown timer
- use a **lightweight expanding-interval scheduler** instead of a heavy SM-2-style model
- keep **pictorial support visible first**, then fade it only after repeated successful recall
- gate access behind **evidence of conceptual readiness** from VS1 telemetry
- introduce **two-digit scope only with explicit tens-and-ones visuals**

In short: Sum Sprint should feel like a confident, playful retrieval lane, not a test.

---

## 1. Product framing

### 1.1 Why Mather needs a fluency lane

Mather's current active slice is strongest at **conceptual number sense**:
- concrete manipulation
- pictorial decomposition
- early abstraction
- embodied reinforcement through Bond Blast and Gravity Split

That is the right foundation. But the current product still leaves a gap between:
- "the child understands part-part-whole and can solve with support"
- and
- "the child can retrieve familiar sums quickly enough for larger-number work"

For Indian 5-year-olds, this gap matters more than it would in a lower-ceiling curriculum.
Many children entering LKG/UKG already count fluently and are exposed to early addition
expectations that move past sums to 10. Sum Sprint should become the **fluency bridge**,
not a replacement for conceptual play.

### 1.2 Role in the product system

| Activity | Primary role | Number scope |
|---|---|---|
| VS1 Make & Break | conceptual composition/decomposition | to 10 |
| Bond Blast | embodied retrieval of known bonds | to 10 |
| Gravity Split | embodied transfer / decomposition control | to 10 |
| **Sum Sprint** | **fluency + spaced retrieval** | **10 → 20 → 100** |
| Room Quest | room-scale embodied play | to 10 initially |

Sum Sprint belongs **after** conceptual understanding is established. It should never be
presented as the first exposure to a fact family.

---

## 2. Curriculum context

### 2.1 Indian foundational-stage fit

NCERT Grade 1 and NEP 2020 foundational-stage framing both support:
- play-based, activity-driven early numeracy
- strong emphasis on foundational literacy and numeracy by the end of Grade 3
- early addition/subtraction through concrete and pictorial support
- progression from numbers within 10 toward 20, then place-value-grounded work within 100

This makes Sum Sprint directionally aligned with the curriculum, provided it:
1. stays **joyful and activity-based**
2. does **not** lead with naked symbolic drill
3. respects the concrete-to-pictorial-to-abstract transition for two-digit work

### 2.2 Scope recommendation

Recommended curriculum ladder:
1. **Sprint 10**: facts within 10, with heavy pictorial support initially
2. **Sprint 20**: facts within 20, including make-10 and near-10 strategies
3. **Sprint 100**: only after tens-and-ones scaffolding is introduced

This sequence keeps the product honest: fluency scales only after representation scales.

---

## 3. Research synthesis: retrieval practice for ages 5–7

### 3.1 Retrieval is useful, but pure flashcard pressure is the wrong import

The existing `Math-App-Vision.md` synthesis already supports several important truths:
- conceptual-first, fluency-second is the right sequence
- spaced repetition helps young children when retrieval remains scaffolded
- expanding intervals outperform flat repetition
- for younger learners, **restudy + retrieval** is often better than pure retrieval pressure

That means Sum Sprint should not be a strict "show fact, demand immediate answer, move on"
engine. It needs a mixed loop:
- retrieve
- if needed, briefly re-show support
- then return the fact later on a widened or shortened interval based on performance

### 3.2 Recommended scheduler shape

Three realistic options:

| Option | Upside | Risk |
|---|---|---|
| 3-box Leitner | simple, explainable, easy to implement | too coarse if item difficulty varies widely |
| Simplified SM-2 | flexible intervals | overfit for early-childhood, more state complexity than needed |
| Custom expanding intervals | tuned to short sessions and child-safe re-exposure | needs explicit product choices |

### 3.3 Recommendation

Use a **custom child-safe expanding schedule** that behaves like a simplified Leitner system,
but is stored as a few explicit fields rather than a full flashcard algorithm.

Per fact, track:
- `lastSeenAt`
- `proficiencyBand` (`new`, `supported`, `emerging`, `solid`)
- `consecutiveIndependentCorrect`
- `lastResponseLatencyBand` (`slow`, `ok`, `fast`)

Suggested revisit policy:
- `new`: same session or next session
- `supported`: next session
- `emerging`: 2 to 3 sessions later
- `solid`: 5+ sessions later, with periodic resurfacing

Demotion rule:
- wrong answer or heavy hesitation drops one band, not all the way to `new`

Why this is better than raw Leitner:
- easier to explain in product terms
- easier to feature-flag and debug
- better aligned with 5 to 7 minute capped sessions
- avoids pseudo-scientific precision the product cannot yet validate

---

## 4. Timer safety and motivation design

### 4.1 Visible countdowns are too risky for this age band

The strongest product signal from both early-childhood guidance and the current Mather
vision is clear: avoid **pressure-forward timers** for 5-year-olds.

Visible countdown risks:
- converts recall into performance pressure
- punishes slower but conceptually secure children
- amplifies math-anxiety risk for first-grade-adjacent learners
- makes the activity feel test-like instead of game-like

### 4.2 What to use instead

Recommended motivation stack:
1. **Current streak**: "3 in a row"
2. **Personal best**: "Best streak: 6"
3. **Session cap**: 8 to 10 prompts total
4. **Celebration on growth**, not on speed alone

Optional hidden use of response speed:
- use latency internally to decide whether to fade support
- do **not** expose reaction time numerically to the child in v1

### 4.3 UX verdict

**Use streaks, not timers.**

This keeps the loop exciting while preserving child dignity. The child is trying to
"keep the rocket going" or "keep the sparkle train moving," not racing a clock.

---

## 5. Pictorial fade protocol

### 5.1 Why fade matters

A fade system solves a real pedagogical problem:
- if the pictorial aid never fades, the child may stay dependent on counting every time
- if it fades too early, the app mistakes familiarity for fluency and causes frustration

### 5.2 Recommended fade stages

For each fact family or fact cluster, use three support stages:

1. **Full support**
   - dots / ten-frame / grouped objects visible immediately
2. **Brief support**
   - visual appears briefly, then soft-fades after ~1 second
3. **Abstract-first**
   - equation shown first, with a help reveal if the child hesitates

### 5.3 Advancement rule

Advance from one support stage to the next only after **5 independent successful retrievals**
across multiple sessions, with no more than one visibly supported rescue in the set.

Suggested operational rule:
- move to `brief support` after 5 correct with `ok` or `fast` latency
- move to `abstract-first` after another 5 correct with mostly `fast` latency
- drop back one support stage after 2 misses or repeated long hesitations

This matches the product's existing bias from `Math-App-Vision.md`: adapt after 5 stable
wins, not 3.

---

## 6. Scope gating and readiness

### 6.1 Sum Sprint should not unlock by default

Unlocking Sum Sprint too early would violate the product's conceptual-first thesis.
The child should first demonstrate they can work meaningfully in VS1.

### 6.2 Recommended gate

Gate Sum Sprint behind all of the following:
- at least **5 completed VS1 sessions**
- at least **80% first-attempt accuracy** across recent VS1 decomposition prompts
- no sign that the child is still relying on repeated parent rescue for core sums to 10

Parent-facing wording should be positive, for example:
> "Ready for quick number sprints"

This keeps the gate framed as earned readiness, not exclusion.

### 6.3 Optional soft-launch rule

Allow parents to manually enable Sum Sprint early from Settings, but mark it as:
- "best after Make & Break confidence"

That preserves family-first flexibility.

---

## 7. Two-digit scope and place-value scaffolding

### 7.1 Why sums within 100 are different

Once Sum Sprint moves beyond 20, the child needs representation that makes tens and ones
legible at a glance. Reusing single-dot patterns will collapse under visual load.

### 7.2 Recommended minimal representation

For two-digit sums, use:
- **tens sticks** or rods for groups of ten
- **single counters** for ones
- maximum on-screen decomposition small enough to parse instantly

Example:
- 34 shown as 3 tens sticks + 4 ones
- 28 shown as 2 tens sticks + 8 ones

The child should never need to count 34 individual dots.

### 7.3 Product recommendation

Do **not** ship within-100 scope in the first implementation slice.

Ship in phases:
1. v1: within 10
2. v2: within 20
3. v3: within 100 with explicit place-value visuals and separate validation

---

## 8. Design direction

### 8.1 Core session loop

A Sum Sprint session should look like this:
1. child enters a playful themed sprint lane
2. app presents one fact prompt
3. child answers through large-tap input
4. app celebrates, rescues, or lightly re-supports
5. scheduler queues the next fact based on confidence
6. session ends after 8 to 10 prompts with a simple streak recap

### 8.2 Input pattern

Recommended answer UI for v1:
- 3-option or 4-option large answer chips for very young children, or
- tap-the-total from a compact answer row

Avoid in v1:
- keyboard entry
- drag digits into place
- multi-step typed construction

The retrieval target is math fluency, not text entry or symbol assembly.

### 8.3 Theme fit

Because Mather already values game-feel, Sum Sprint should use a light metaphor such as:
- rocket boost
- sparkle run
- train streak
- animal trail

The theme should:
- reinforce momentum
- not imply danger or failure
- not require a countdown clock to feel energetic

---

## 9. Data model recommendation

Minimum new persistence required per child profile:

- `FactKey`
  - operands
  - operation
  - scope bucket
- `FactMastery`
  - support stage
  - proficiency band
  - consecutive independent correct
  - last seen timestamp
  - recent hesitation / latency band
- `SumSprintSessionSummary`
  - presented facts
  - streak peak
  - supported rescues
  - independent correct count

This is enough for v1 research-to-spec work without committing to a full adaptive-learning
platform.

---

## 10. Recommendation

Build Sum Sprint as a **feature-flagged fluency lane** with these firm constraints:
- conceptual-first unlock gate
- no visible countdown timers
- streak-based motivation
- child-safe expanding retrieval intervals
- pictorial-to-abstract fade only after repeated success
- within-10 first, within-20 second, within-100 later

This direction is highly aligned with Mather's product thesis and gives the roadmap a
credible next layer above VS1 without abandoning the current CPA-centered identity.

---

## 11. Open questions for validation

- What answer input pattern is fastest without feeling quiz-like: chips, number line taps, or picker wheels?
- Is the right unlock threshold 80% first-attempt accuracy over 5 sessions, or should it be stricter?
- Should Bond Blast mastery count toward Sum Sprint readiness, or only VS1 core prompts?
- Does v1 need addition only, or should subtraction facts within 10 launch together?
- What session-level telemetry best distinguishes healthy thinking time from struggling hesitation?

---

## 12. Next steps

- Write implementation-facing spec: `wiki/Specs/Sum-Sprint.md`
- Add a feature flag proposal for `sumSprintEnabled`
- Decide v1 answer input pattern
- Define persistence model once implementation starts
- Validate the readiness gate against real child-session telemetry
