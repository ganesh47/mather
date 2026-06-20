# Research: Room Quest TV Companion and Continuity Camera Path

**Issue**: [ganesh47/mather#1182](https://github.com/ganesh47/mather/issues/1182)
**Status**: Draft
**Date**: 2026-06-20
**Apple TV wave**: `artifacts/mather-appletv-implementation-wave-2026-06-20.md`
**Related research/specs**:
- `wiki/Research/Apple-TV-tvOS-Mather-Opportunities.md`
- `wiki/Specs/Room-Quest-Sensor-Driven.md`
- `wiki/Research/Room-Quest-Reference-Capture-and-Recheck.md`
- `wiki/Research/Room-Quest-Camera-Flow-UX-Review.md`

---

## Executive summary

Room Quest TV should start as a **companion display**, not as a new camera owner.

The minimum proof path is:

1. Keep the iPhone/iPad Room Quest scanner and engine as the source of truth.
2. Add a tvOS mission-board surface that joins a nearby Room Quest session.
3. Use `MultipeerConnectivity` for a same-room proof channel between the handheld and Apple TV.
4. Exchange only small session events: setup state, current station, scan outcome, fallback outcome, clue, and celebration trigger.
5. Preserve every existing iPhone/iPad scanner fallback when the TV is absent, unavailable, or disconnected.

Continuity Camera is a promising later path, but it should not be the first proof. It moves camera
capture into the tvOS app, introduces Apple TV pairing/setup friction, creates a second scanner
implementation path, and risks disrupting the current iPhone/iPad baseline before the companion
product loop has been validated.

---

## Product stance

Room Quest already has the right baseline shape:

- iPhone/iPad owns setup, camera marker scans, optional reference capture, and fallback behavior.
- Parents can understand what is being sensed.
- The feature degrades when camera confidence is weak.

The Apple TV extension should make that loop feel better in the room:

- TV shows the mission board, clue, station map, large progress, and celebrations.
- Handheld device remains the scanner/controller that moves with the child or parent.
- If the TV session fails, the handheld experience continues without data loss.

This keeps Apple TV additive. It does not turn a scanner feature into a dependency on a second
screen.

---

## Current Room Quest baseline to preserve

The existing implementation and specs already establish these constraints:

- Baseline station confirmation is camera marker scanning on iPhone/iPad, with manual fallback.
- Reference capture and same-place recheck are follow-on enhancements, not exact indoor
  localization.
- Room Quest must stay honest about camera confidence and avoid pretending that GPS or a single
  frame proves indoor position.
- Safety and parent control are part of the feature, not polish.

Non-negotiable for TV companion work:

- No change to iPhone/iPad session completion semantics.
- No new permission required for baseline handheld Room Quest unless the parent explicitly enables
  TV companion mode.
- No requirement that a family owns or uses Apple TV to play Room Quest.
- No Continuity Camera dependency in the first companion proof.
- No remote/cloud dependency for in-room play completion.

---

## Option comparison

| Path | Best use | Fit for first proof | Permission/setup cost | Main risk | Recommendation |
|---|---|---:|---|---|---|
| `MultipeerConnectivity` | Nearby same-room event sync between handheld and Apple TV | High | Local network / Bonjour disclosure on relevant OS versions; in-app pairing UX | Discovery and reconnection edge cases | Use for minimum proof |
| Local network with Network framework / Bonjour | Custom same-room transport with explicit protocol control | Medium | Local network usage copy, Bonjour service declarations, custom TLS/pairing work | More plumbing than product proof needs | Consider after MC proof if reliability demands it |
| CloudKit/shared store | Durable cross-device state, account-backed history, family sharing | Low for live play | iCloud account, CloudKit entitlements, share/invitation/account states | Latency and account setup make it poor for live scanning | Defer to progress/history, not live session |
| SharePlay / GroupActivities | Remote co-play over FaceTime/Messages/AirDrop contexts | Low | SharePlay activation/session UX; platform/social context | Not naturally a same-room TV-and-scanner pairing mechanism | Defer; maybe remote family mode |
| Continuity Camera for tvOS | tvOS app captures iPhone/iPad camera/mic input | Medium long-term, low first-proof | Camera/mic privacy, continuity device availability, Apple TV pairing, setup education | Duplicates scanner path and shifts camera ownership away from handheld baseline | Research separately after companion proof |

---

## Path details

### 1. MultipeerConnectivity

Apple's Multipeer Connectivity framework is designed for nearby device discovery and communication.
That matches the first Room Quest TV proof: two devices in the same room exchanging small, timely
events.

Recommended proof:

- Apple TV advertises or browses for a `mather-roomquest` service.
- iPhone/iPad starts a Room Quest session and offers "Show on Apple TV".
- Parent confirms a short code or QR/pairing phrase so the child does not accidentally join the
  wrong TV.
- Handheld sends event snapshots to TV:
  - session created
  - setup station ready count
  - current clue/station
  - scan attempt started
  - scan success/failure/fallback
  - session paused/resumed/ended
  - celebration cue
- TV never decides whether a scan is valid. It renders the state it receives.

Permissions and declarations:

- Add local network purpose copy only to the app surface that enables TV companion.
- Declare Bonjour service types if discovery uses Bonjour-backed browsing/advertising.
- Explain the permission in parent-facing language: "Find your Apple TV for Room Quest companion
  mode." Do not mention abstract networking.

Fallbacks:

- If permission is denied, show "Play on this device" and keep the current Room Quest flow.
- If the TV drops mid-session, handheld remains authoritative and continues.
- If two TVs are found, require explicit pairing code confirmation.
- If no peer is found within a short timeout, keep the session local.

Validation:

- Unit-test event encoding/decoding and session reducer behavior without live networking.
- Add an integration stub that feeds TV state from recorded handheld events.
- On-device validation later: iPhone/iPad plus Apple TV simulator/device pairing, permission
  denial, peer drop, reconnect, and wrong-code rejection.

### 2. Local network with Network framework / Bonjour

A custom Network framework path can replace or supersede MultipeerConnectivity if the proof reveals
MC reliability or UX limits. It gives tighter control over protocol shape, transport, pairing, and
reconnect behavior.

It is not the best first proof because it makes the transport the project instead of the product
question. Room Quest TV first needs to answer whether the TV mission-board loop improves the
experience.

Use this path only when one of these becomes true:

- MC discovery is unreliable in the household/test environment.
- The app needs stricter transport security semantics than MC gives for the proof.
- The event stream grows beyond simple state snapshots.
- The team needs deterministic reconnect and version negotiation.

Fallback requirements are the same as MC: no TV, denied local network access, or dropped peer must
not block handheld Room Quest.

### 3. CloudKit/shared store

CloudKit is a good fit for durable account-backed data, not a first live companion loop.

Good future uses:

- Persist Room Quest session summaries across devices.
- Let Apple TV show a recent family gallery or recap.
- Share parent-approved deck/progress data between iPhone, iPad, and TV.

Poor first-proof uses:

- Live scan confirmation.
- Station-by-station mission board updates.
- Setup pairing between a TV and handheld in the same room.

Risks:

- Requires iCloud account availability and CloudKit entitlements.
- Sharing flows add invitation, participant, permission, and account-edge states.
- Network latency and offline states complicate a child-facing live room session.

Recommendation: keep CloudKit out of the live Room Quest TV proof. Revisit it for durable progress
and multi-device family history after the TV companion loop is validated.

### 4. SharePlay / GroupActivities

SharePlay is built for shared activities across FaceTime, Messages, AirDrop, and related group
activity contexts. It can be compelling if Mather later supports remote family play.

It is not the first same-room companion mechanism because:

- Room Quest TV needs local Apple TV plus nearby scanner pairing, not a social call/session model.
- SharePlay activation adds a concept parents do not need for in-room play.
- It does not solve camera ownership or scanner fallback.

Possible future use:

- Grandparent joins remotely and watches a simplified Room Quest mission board.
- Two households play a non-camera Memory Gallery or Sum Sprint Party session together.
- A remote coach/parent sees progress after explicit family opt-in.

Recommendation: defer until Mather has a proven TV surface and a clear remote co-play use case.

### 5. Continuity Camera for tvOS

Apple's tvOS platform now supports connecting an iPhone or iPad as a continuity camera/microphone
device for Apple TV apps. That makes a direct tvOS Room Quest scanner technically plausible.

It is still the wrong first proof for Room Quest TV.

Why:

- It changes the ownership model: tvOS would become the camera/scanner owner.
- The existing iPhone/iPad scanner already owns Room Quest station scan, reference capture, and
  fallback semantics.
- A second scanner path would need separate permission, availability, failure, and validation work.
- Families must understand the Apple TV continuity-device pairing flow before the game starts.
- The child may still need a handheld device near the station; at that point the existing app is a
  simpler camera owner.

Where Continuity Camera could become valuable:

- A stationary TV-led setup where the parent points an iPhone camera at a play mat or table.
- A "show the object to the TV" mode where the child brings objects back to the living-room stage.
- A later same-place/reference experiment if tvOS camera frames can reuse the same confidence-stack
  logic as iOS.

Gate before implementation:

- Confirm tvOS target entitlement/plist needs.
- Validate continuity camera availability across the oldest Apple TV target Mather intends to
  support.
- Confirm whether AVFoundation/Vision scanner code can be shared or must diverge on tvOS.
- Test setup friction with a real Apple TV plus iPhone/iPad, not only simulator docs.
- Preserve handheld Room Quest as the fallback and source of truth until the tvOS scanner proves
  better in family testing.

---

## Recommended minimum proof path

### Phase 0: Contract-only spike

Create a platform-neutral companion event contract:

```swift
enum RoomQuestCompanionEvent: Codable, Equatable {
    case sessionStarted(targetNumber: Int, stationCount: Int)
    case setupProgress(readyStations: Int, totalStations: Int)
    case clueChanged(stationID: String, prompt: String)
    case scanStateChanged(stationID: String, state: ScanState)
    case fallbackUsed(stationID: String)
    case celebration(stationID: String)
    case paused
    case resumed
    case completed(summary: Summary)
}
```

Acceptance:

- Existing iPhone/iPad Room Quest can emit the events without changing its state machine.
- A fake TV renderer can replay an event fixture into expected mission-board state.
- No network, CloudKit, SharePlay, or Continuity Camera code is required yet.

### Phase 1: Multipeer local proof

Add an opt-in TV companion session:

- tvOS app shows a Room Quest companion landing state.
- iPhone/iPad Room Quest setup shows "Show on Apple TV" only when the feature flag is enabled.
- Pair using a short code or QR-style challenge.
- Send event snapshots over MC.
- TV renders mission board and celebrations.
- Handheld remains fully playable if TV disconnects.

Acceptance:

- Denying local network permission does not block Room Quest on handheld.
- Killing the TV app mid-session does not lose handheld progress.
- Reconnecting sends a full state snapshot before live events resume.
- TV never records camera frames, station reference images, child media, or location.
- UI copy makes the permission and fallback understandable to parents.

### Phase 2: Transport hardening or Network framework replacement

Only after Phase 1 proves the product loop:

- Add event schema versioning.
- Add explicit reconnect and stale-session handling.
- Decide whether MC is sufficient or whether custom Network framework transport is warranted.
- Add route-level analytics for opt-in, pairing success, peer drop, reconnect, and local-only
  fallback.

### Phase 3: Continuity Camera validation spike

Treat this as a separate research spike, not a continuation of the MC proof:

- Build a tiny tvOS-only camera capture sample.
- Try marker detection against existing Room Quest marker payloads.
- Compare setup time and reliability against the handheld scanner baseline.
- Decide whether it is a distinct mode or a dead end.

Acceptance:

- Demonstrates real device availability and permission flow.
- Documents camera/microphone plist keys and user-facing prompts.
- Shows whether existing scanner logic can be reused.
- Keeps baseline Room Quest unchanged.

---

## Permissions and privacy

| Feature | Likely permission / entitlement surface | Product copy principle | Data policy |
|---|---|---|---|
| MC / Bonjour discovery | Local network usage string and Bonjour service declaration when applicable | "Find your Apple TV for Room Quest companion mode" | Peer identifiers and session events only |
| Custom local network | Same local network disclosure plus custom pairing/security | Same as MC, with clearer troubleshooting | Session events only |
| CloudKit | iCloud/CloudKit entitlements and account states | "Sync family progress across your devices" | Summaries/progress only; no child media by default |
| SharePlay | GroupActivities activation/session flow | "Play together in a shared call" | Shared activity state only |
| Continuity Camera | Camera/microphone privacy strings and continuity-device setup | "Use an iPhone/iPad camera with Apple TV" | No captured media persisted unless parent explicitly approves reference capture |

Privacy defaults:

- Do not send camera frames to TV in the MC proof.
- Do not persist companion event logs beyond debug/test fixtures unless telemetry is explicitly
  designed.
- Do not introduce child identity, account, or location sharing for TV companion.
- Make the local network prompt parent-initiated, not a surprise on first launch.

---

## Device availability and fallback matrix

| Situation | Expected behavior |
|---|---|
| No Apple TV app installed | Handheld Room Quest runs exactly as today |
| Apple TV unavailable/offline | Hide or time out TV pairing; continue local handheld play |
| Local network permission denied | Explain companion unavailable; continue handheld play |
| Multiple Apple TVs/peers found | Require visible pairing code confirmation |
| Peer drops during setup | Keep setup on handheld; allow retry pairing |
| Peer drops during play | Handheld continues; TV can rejoin from full state snapshot |
| iCloud unavailable | No impact on MC proof |
| SharePlay unavailable | No impact on MC proof |
| Continuity Camera unavailable | No impact until a separate Continuity Camera mode exists |
| Camera permission denied on handheld | Existing Room Quest fallback behavior applies |

---

## Validation plan

Documentation/research validation for this slice:

- Confirm this document covers all issue #1182 comparison points.
- Link the PR to issue #1182.
- No Xcode-native validation is required because this is a docs/research artifact.

Implementation validation for the next proof:

- Unit tests:
  - companion event encoding/decoding
  - mission-board reducer from event fixtures
  - reconnect full-state snapshot behavior
  - unknown future event handling
- UI tests:
  - feature flag off keeps Room Quest unchanged
  - permission-denied path keeps handheld playable
  - TV-disconnected path keeps primary action reachable
- Device tests:
  - one iPhone/iPad + Apple TV simulator/device pairing
  - local network denial and recovery via Settings
  - wrong pairing code
  - peer drop/rejoin
  - existing Room Quest scanner success/failure/manual fallback unchanged

---

## Next implementation steps

1. Open a follow-up implementation issue for `RoomQuestCompanionEvent` and fake TV event replay.
2. Add a feature flag such as `roomQuestTVCompanionEnabled`, default `false`.
3. Extract only presentation-safe Room Quest state into a companion snapshot model.
4. Build a tvOS mission-board screen that consumes fixture events without networking.
5. Add MC pairing behind the feature flag.
6. Validate local-network denial and disconnect fallbacks before adding polish.
7. Decide whether MC is sufficient or a Network framework transport is needed.
8. Open a separate Continuity Camera validation issue only after the TV companion proof is useful.

---

## Acceptance coverage for issue #1182

- **Compare MultipeerConnectivity, local network, CloudKit/shared store, SharePlay, and Continuity
  Camera**: covered in the option comparison and path detail sections.
- **Recommend minimum proof path**: recommend contract-only spike followed by MC same-room TV
  companion proof.
- **Preserve iPad/iPhone scanner baseline**: handheld remains the scanner and source of truth;
  TV receives events only.
- **Permissions**: local network, Bonjour, iCloud, SharePlay, camera/mic surfaces documented.
- **Device availability**: fallback matrix covers unavailable Apple TV, local network denial,
  CloudKit/SharePlay irrelevance, and Continuity Camera unavailability.
- **Fallbacks**: handheld local Room Quest continues in every companion failure mode.
- **Validation**: doc validation plus next implementation test/device plan included.
- **Next steps**: concrete issue-ready implementation sequence included.

---

## Source links

- Apple Developer: [Multipeer Connectivity](https://developer.apple.com/documentation/multipeerconnectivity)
- Apple Developer: [TN3179: Understanding local network privacy](https://developer.apple.com/documentation/technotes/tn3179-understanding-local-network-privacy)
- Apple Developer: [Building a custom peer-to-peer protocol](https://developer.apple.com/documentation/Network/building-a-custom-peer-to-peer-protocol)
- Apple Developer: [Sharing CloudKit data with other iCloud users](https://developer.apple.com/documentation/CloudKit/sharing-cloudkit-data-with-other-icloud-users)
- Apple Developer: [Group Activities](https://developer.apple.com/documentation/GroupActivities)
- Apple Developer: [Supporting Continuity Camera in your tvOS app](https://developer.apple.com/documentation/AVKit/supporting-continuity-camera-in-your-tvos-app)
- Apple Developer: [Build for tvOS](https://developer.apple.com/tvos/)
