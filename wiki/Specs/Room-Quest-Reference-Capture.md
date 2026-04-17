# Spec: Room Quest Reference Capture and Camera-Based Place Recheck

**Issue**: [#182](https://github.com/ganesh47/mather/issues/182)
**Status**: draft
**Author**: @grclaw
**Date**: 2026-04-17

## Overview

This feature adds a follow-on Room Quest slice where the parent captures a reference image of
a hiding place during setup, and the child later uses the camera to re-check whether a live view
matches that original place.

This is a confidence-based verification feature, not an exact indoor location system.

## User Stories

- As a parent, I want to save the hiding place with the camera so the app can later recognize the intended spot.
- As a child, I want the camera to help confirm that I found the real place so the scavenger hunt feels magical and fair.
- As the product, I want an honest fallback path when confidence is weak so the experience stays trustworthy.

## Acceptance Criteria

- [ ] Parent setup flow can capture and approve a hiding-place reference image.
- [ ] Reference capture is stored with enough metadata to support later recheck.
- [ ] Child-facing find flow can open the camera and compare the current live view against the saved reference.
- [ ] The result is presented as `match`, `near`, or `uncertain`, not as exact certainty.
- [ ] Manual fallback remains available when confidence is weak or camera conditions are poor.
- [ ] Product copy avoids claiming exact indoor GPS truth.
- [ ] v1 works without LiDAR and does not require network calls.

## Design

### SwiftUI Views

- `RoomQuestReferenceCaptureView`
  - parent setup camera capture + approval / retake
- `RoomQuestReferenceReviewView`
  - confirms saved reference image and station identity
- `RoomQuestPlaceRecheckView`
  - child-facing live camera recheck flow
- `RoomQuestPlaceRecheckResultView`
  - communicates match / near / uncertain outcome

### Data Model

Suggested types:

- `RoomQuestPlaceReference`
  - `stationID`
  - `referenceImageAssetID`
  - `capturedAt`
  - `markerIdentity`
  - `featurePrintPayload`
  - `optionalPoseSummary`
  - `optionalCoarseLocationSummary`

- `RoomQuestPlaceRecheckResult`
  - `confidenceBand`
  - `similarityScore`
  - `usedMarkerSupport`
  - `usedPoseSupport`
  - `needsManualFallback`

- `RoomQuestConfidenceBand`
  - `match`
  - `near`
  - `uncertain`

### Detection Pipeline

v1 pipeline:
1. load stored reference image and precomputed feature print
2. capture live frame samples from camera
3. generate feature print for candidate frame
4. run coarse similarity comparison
5. optionally mix in marker identity / simple support signals
6. map result into `match`, `near`, or `uncertain`

v2 additions:
- stronger local feature / geometry validation
- optional ARKit pose-consistency support on capable devices

### Navigation

- Parent captures references during Room Quest setup after station placement.
- Child reaches the find step and enters place recheck from the Room Quest loop.
- On `match`, the activity unlocks the next scavenger action.
- On `near`, the child is prompted to adjust and retry.
- On `uncertain`, the flow offers retry or manual fallback.

### State Management

- Reference capture should be stored per station.
- Recheck logic should live in a dedicated service / engine, not directly in the view.
- Confidence mapping thresholds should be testable and configurable.

## Feature Flag

Flag name: `FeatureFlags.roomQuestReferenceRecheckEnabled`

## Constraints

- No exact indoor GPS claims.
- No network dependency in v1.
- No assumption that Vision alone can guarantee same-place truth.
- No removal of marker/manual fallback.

## Out of Scope

- fully automatic freeform room mapping
- cloud image matching
- accessory / UWB-based station tracking
- exact indoor coordinates
- replacing the existing marker-guided baseline entirely

## Open Questions

- [ ] Should reference capture be required for every station or only for selected stations?
- [ ] What confidence thresholds produce the best balance of delight vs. false positives in real homes?
- [ ] How many live frames should be sampled before returning `uncertain`?
- [ ] Is v1 better with still-photo capture, live preview matching, or both?

## References

- Related issue: #171
- Related research: `wiki/Research/Room-Quest-Sensor-Capabilities-and-Design-Direction.md`
- Related research: `wiki/Research/Room-Quest-Reference-Capture-and-Recheck.md`
- Related spec: `wiki/Specs/Room-Quest-Sensor-Driven.md`
