# Research: Room Quest Reference Capture and Camera-Based Recheck

**Issue**: [ganesh47/mather#182](https://github.com/ganesh47/mather/issues/182)
**Status**: Completed
**Date**: 2026-04-17

---

## Overview

This document defines the next Room Quest slice after the current marker-guided baseline:
**capture a hiding-place reference during setup, then later use the camera to re-check whether
the child has found the same place**.

The product goal is not exact indoor localization. The goal is a more magical and trustworthy
"same place" check that feels camera-real instead of purely manual.

The key design recommendation is:
- keep marker-guided Room Quest as the alpha baseline
- add **reference capture now, camera-based recheck later** as a follow-on slice
- use a **confidence stack** rather than a single yes/no sensing claim
- keep manual fallback available when confidence is weak
- stay explicit that GPS is supporting context at most, not indoor proof

---

## 1. Why this slice exists

The newest TestFlight feedback made the product gap clear:
- Room Quest currently feels too setup-driven
- camera involvement still feels secondary
- the child is not yet experiencing a true hide-and-seek camera recheck loop

The existing Room Quest research and spec already improved the product direction by moving away
from purely manual confirmation toward sensor-driven markers. That is still the correct baseline.
But it does not yet satisfy the stronger user expectation:
1. save what the hiding place looked like
2. come back later
3. let the camera help judge whether this is the same place

That expectation is valid, and it is now the right follow-on product slice.

---

## 2. Product framing

### 2.1 What the feature should feel like

For the parent:
- I can save the real hiding place with the camera
- the app remembers what "correct" looked like
- I still have an escape hatch if camera confidence is weak

For the child:
- I found the spot and the camera recognized it
- I can adjust and try again if I am close
- the game feels like it is truly checking the room, not just trusting a button tap

### 2.2 What the feature must not pretend

The app must not imply:
- exact indoor GPS truth
- full scene understanding on every device
- guaranteed same-place certainty from one blurred frame
- that "Apple Intelligence" provides a turnkey verification API for this use case

The honest framing is:
- **looks like the same hiding spot**
- **close, try moving a little**
- **could not verify yet, use fallback if needed**

---

## 3. Core product decision

### Recommendation

Adopt a **confidence-based same-place verification model**.

Do not model this as binary truth from a single signal.
Instead, combine several weak-to-medium signals into one product-facing judgment.

That gives the best balance of:
- honesty
- delight
- device compatibility
- graceful degradation

---

## 4. Confidence stack

### 4.1 Primary signal: Vision image similarity

Use Vision image feature prints / descriptors to compare:
- the parent-approved reference capture from setup
- the live frame during the find phase

This is the best first-pass signal because it:
- stays on-device
- works without cloud dependency
- can cheaply reject obvious non-matches
- fits the tester's mental model of "compare what the place looked like"

### 4.2 Secondary signal: local feature / geometry checks

After coarse similarity, use stronger checks where practical:
- local feature correspondence
- repeated structural matches in the same region
- simple geometry consistency

Why this matters:
- image similarity alone may over-match similar shelves, walls, or corners
- geometry checks help distinguish the actual location from a visually similar nearby spot

### 4.3 Optional supporting signal: ARKit relocalization / pose consistency

On capable hardware and favorable conditions, ARKit-style pose consistency can help answer:
- is the device seeing the same physical area from a plausible viewpoint?

This should be a supporting signal only, not a baseline requirement.
It will be less reliable in low-texture or low-light home environments.

### 4.4 Supporting signal: marker identity

If a marker is already part of the Room Quest station flow, marker identity should remain a
strong support signal. This helps avoid unnecessary ambiguity.

### 4.5 Supporting signal: temporal / motion freshness

Useful weak support signals:
- was the comparison performed from a live, recently moving camera session?
- did the child approach the target recently instead of replaying a stale frame?

This is not place proof, but it can improve trust in the interaction.

### 4.6 Weak context only: coarse location metadata

Coarse location can be stored only as weak supporting context.
It must never be treated as the primary proof indoors.

---

## 5. User flow recommendation

### Setup flow
1. Parent places or confirms the Room Quest station / hiding spot.
2. App opens the camera and asks for a clear framing of the spot.
3. Parent captures a reference image.
4. App shows a quick approval screen: use this reference or retake.
5. App stores the reference plus supporting metadata.

### Find flow
1. Child reaches a candidate place.
2. App opens live camera recheck.
3. App compares the live view against the saved reference.
4. App returns one of three outcomes:
   - **match**: looks like the same hiding spot
   - **near**: close, adjust the camera slightly
   - **uncertain**: could not confirm, offer retry or fallback
5. If the child or parent cannot get a reliable match, manual confirmation remains available.

---

## 6. UX guidance

### 6.1 Result states

Recommended child-safe states:
- **Found it!**
- **Almost there, move a little**
- **Let's try again**

Avoid:
- harsh wrong-answer language
- technical confidence percentages in the child UI
- claims of exact certainty

### 6.2 Parent copy

Recommended phrasing:
- save a camera reference for this hiding place
- check whether the camera sees the same place later
- if the room is dark or cluttered, you can still confirm manually

### 6.3 Failure handling

The feature should degrade gracefully when:
- lighting changed a lot
- objects moved
- the camera image is blurry
- the room contains many similar-looking surfaces

Fallback is part of the design, not a shame path.

---

## 7. Risks

### Risk 1: visually similar places may false-positive
Mitigation:
- combine coarse similarity with local feature checks and marker identity

### Risk 2: moved furniture / poor lighting may false-negative
Mitigation:
- allow retry guidance and manual fallback

### Risk 3: overclaiming spatial truth
Mitigation:
- confidence-based wording only
- keep GPS and motion as secondary cues

### Risk 4: implementation complexity outruns current alpha scope
Mitigation:
- stage it:
  1. reference capture
  2. simple similarity recheck
  3. richer geometry / AR support later

---

## 8. Phased delivery recommendation

### Phase 1
- parent captures and stores a reference image
- child find flow opens camera and runs coarse similarity only
- match / near / uncertain result bands
- manual fallback preserved

### Phase 2
- add local feature / geometry strengthening
- refine retry guidance and false-positive handling

### Phase 3
- add optional ARKit pose-consistency support on stronger hardware
- validate whether this materially improves home reliability

---

## 9. Recommendation

Proceed with a dedicated follow-on Room Quest slice for **reference capture and camera-based
place recheck**.

This is the cleanest way to:
- respond to the last meaningful TestFlight feedback
- preserve the honesty of the current sensor-driven marker baseline
- add more magic without pretending to solve indoor positioning

The correct product stance is not "we know exactly where you are".
The correct stance is: **we can often tell when this looks like the same hiding place, and we
stay honest when confidence is weak**.
