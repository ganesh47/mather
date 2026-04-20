# Room Quest Camera Flow UX Review

**Date**: 2026-04-18  
**Scope**: `Features/RoomQuest/*`, `Domain/RoomQuestEngine.swift`, `Services/RoomQuestLiveScanner.swift`

## Summary

The current Room Quest flow technically includes camera steps, but the camera does not yet feel like the core of the experience. In setup, the parent is asked to "camera verify" a station, but what is actually being verified is a QR marker, not a hiding place. In hunt/recheck, the child sees language about finding a saved place, but the implementation still mainly checks marker payload equality. That creates a mismatch between product promise and felt experience.

## What is confusing in setup

1. **The setup goal is unclear**  
   The UI mixes three concepts: placing tokens, verifying a marker, and saving a place reference. Parents are told to "camera-verify each one" and later see "reference saved," but there is no explicit capture/review moment that explains what was actually saved.

2. **"Camera verify" sounds stronger than the feature is**  
   The button implies the app understands the physical location. In code, setup scanning only reads a QR payload and then marks the station as camera verified.

3. **Manual fallback is too co-equal with the primary path**  
   "Same-place fallback" appears immediately beside the main action, which makes the primary camera path feel optional and procedural rather than magical.

4. **Ready-state friction**  
   The parent cannot continue until both stations are registered, but the screen does not strongly communicate the two-step checklist per station beyond button states and badges.

## What is confusing in hunt / recheck

1. **Child copy promises place recheck, but the mechanic is still marker check**  
   Copy like "Recheck the saved place" and "Look for the saved place" suggests scene recognition. The scanner still resolves QR payloads.

2. **Fallback bypass is too easy**  
   On the child screen, "I found it" is always available even before any meaningful camera attempt. That weakens the sense that the camera matters.

3. **The recheck outcome language is better than the underlying truth**  
   States like "almost" and "found the saved place" are emotionally right, but they are attached to marker matching, not a place-confidence model.

4. **No visible camera continuity**  
   The scanner is a separate sheet with a QR prompt and short AR celebration. There is no persistent sense that the app is helping the child search the room in real time.

## Why the camera feels not useful

1. **It confirms markers, not places**  
   The most important gap. The experience reads like hide-and-seek, but the camera checks codes.

2. **The useful camera moment is hidden behind implementation detail**  
   Parents never review a captured reference image, and children never see a live comparison against something previously saved.

3. **The fallback path carries the actual progress power**  
   Because manual confirm is always nearby and low-cost, the camera feels decorative.

4. **The AR sparkle is celebratory, not informative**  
   It rewards a scan, but does not help the user understand why the app believed the place was correct.

## Smallest feel-changing UX improvements

1. **Rename setup actions to match reality now**  
   If this release is QR-first, change copy from "camera verify" / "saved place" to "scan station marker" unless a true place reference is being captured.

2. **Add an explicit parent reference step only when reference capture really exists**  
   A tiny review card like "Saved reference for Red Rocket" with thumbnail/retake would make the camera feel purposeful.

3. **Gate fallback slightly harder in hunt**  
   Hide or de-emphasize "I found it" until one scan attempt fails, or relabel it to a parent-only fallback. This alone would make the camera feel more central.

4. **Make progress per station more legible in setup**  
   Add a simple 2-item checklist: marker scanned / fallback used, ready. Reduce ambiguity around why the Ready button is disabled.

5. **Keep child language honest**  
   If the system is matching markers, say marker. If it is matching a saved place, show the saved reference and use confidence wording consistently.

6. **Turn the scanner into guidance, not just a modal checkpoint**  
   Even a lightweight overlay like "Find Red Rocket marker" with clearer success/failure framing would feel more useful than a generic scan sheet.

## Strongest recommendation

For the next iteration, pick one honest story and commit to it in copy and UI:

- **QR-marker story**: fast, reliable, honest, but less magical
- **Saved-place recheck story**: more magical, but requires a real capture/review/recheck loop

Right now the product language is closer to the second story while the implementation is mostly the first. That mismatch is the main UX problem.
