# ADR-0006: Sensor-Powered Finale Stage for VS1 ("Bond Blast")

**Status**: Accepted
**Date**: 2026-04-10
**Deciders**: ganesh47

---

## Context

VS1's CPA loop ends at the Transfer stage (TransferCheckView), which is pedagogically complete but not celebratory. Issue #137 calls for a complement-match finale where children pair numbers that sum to the session target. This ADR records the architectural decisions for making that finale interactive using iPhone hardware sensors.

Target devices: iPhone 15 Pro, iPhone 16e (iOS 18).

---

## Decisions

### 1. Adopt CMMotionManager for tilt drift and shake-to-shuffle

**Decision**: Use `CMMotionManager.startDeviceMotionUpdates(to:withHandler:)` at 30 Hz, delivering to `.main` queue. Extract `attitude.pitch` / `attitude.roll` for tilt drift, and `userAcceleration` magnitude > 2.5g for shake detection.

**Rationale**:
- Zero permissions required (no NSUsageDescription needed)
- Works identically on iPhone 15 Pro and iPhone 16e (no platform gap)
- Tilt drift (max ±6pt on card positions) gives the card layout an "alive" quality without impeding tap accuracy
- Shake-to-shuffle is a playful reset mechanism that teaches the child agency over the game

**Swift 6 concurrency**: `MotionService` is `@MainActor @Observable`. The `CMMotionManager` handler runs on `.main` queue; `MainActor.assumeIsolated { }` makes this explicit and safe under strict concurrency checking. The manager stored as `nonisolated(unsafe)` avoids Sendable crossing issues since it is only ever accessed from `@MainActor` methods.

**Consequences**: Battery impact at 30 Hz is minimal; Apple's documentation cites typical consumption under 1 mA. The service starts only when `BondMatchView` appears and stops on disappear.

---

### 2. Upgrade HapticsService to CHHapticEngine with UIKit fallback

**Decision**: Replace `UIImpactFeedbackGenerator` calls in `HapticsService` with `CHHapticEngine` patterns for five events: card pickup, near-snap magnetic pull, correct snap, mismatch wobble, and Bond Blast celebration rhythm. Keep `UIImpactFeedbackGenerator` as fallback when `CHHapticEngine` fails to start (simulator, older hardware).

**Rationale**:
- `UIImpactFeedbackGenerator` has three preset weights (light/medium/heavy) and one notification type; this is insufficient differentiation for the five distinct Bond Blast moments
- `CHHapticEngine` allows continuous ramp patterns (the "magnetic pull" effect as a card approaches a snap target), which are impossible with UIKit feedback generators
- The UIKit fallback ensures existing tests and CI (simulator) continue to pass without changes
- Existing method signatures (`stageSuccess`, `success`, `failure`) are preserved — callers are unaffected

**Consequence**: `HapticsService.init()` now starts `CHHapticEngine` eagerly. Engine startup is fast (<10ms) and non-blocking on device. On simulator, the engine fails to start silently and the UIKit fallback activates.

---

### 3. Optional clap detection via AVAudioEngine RMS (default off)

**Decision**: Implement `SoundDetectionService` using `AVAudioEngine` + `AVAudioInputNode` tap with RMS spike detection. Gate behind `featureFlags.soundReactionEnabled` (default: **false**). Require `NSMicrophoneUsageDescription` in Info.plist.

**Why RMS spike, not SoundAnalysis framework**:
- `SoundAnalysis` uses a ~35 MB Core ML model with 200–500ms classification latency — too slow for a real-time "clap now!" moment
- A single-window RMS spike (rise from <0.05 to >0.3 in one ~46ms buffer) captures the transient signature of a clap accurately enough for a celebration trigger
- No model download, no framework size increase

**Why default off**:
- `NSMicrophoneUsageDescription` triggers a system permission dialog on first use
- In a family setting, the parent should consciously opt in to microphone use
- The feature works perfectly without clap detection; it is a bonus delight layer

**Privacy guarantee**: The audio tap reads raw float samples to compute RMS only. No audio data is stored, buffered beyond one window, or transmitted. The service stops immediately when `BondMatchView` disappears.

---

### 4. Exclude ARKit, camera, GPS, AirPods motion, and SoundAnalysis

**Decision**: Explicitly not adopted.

| Sensor | Reason excluded |
|---|---|
| ARKit / LiDAR | LiDAR unavailable on iPhone 16e; motion sickness risk for ages 5–7 |
| Camera (AVCaptureDevice) | Privacy concern for children; orange indicator dot; no pedagogical benefit |
| CoreLocation / magnetometer | Permission overhead; no geographic concept in VS1 |
| CMHeadphoneMotionManager | Requires AirPods; no toddler AirPods in this family's setup |
| SoundAnalysis | Model size + latency; replaced by simpler RMS approach |

---

### 5. Stage fires on last problem only

**Decision**: `.bondMatch` stage is injected by `VerticalSliceEngine` only when `currentProblemIndex + 1 >= problems.count` AND `featureFlags.vs1BondMatchEnabled`. `SliceStateMachine.nextStage` receives `showBondMatch: Bool` and routes `transfer → bondMatch → done` (or `abstract → bondMatch → done` when `showTransfer: false`).

**Rationale**:
- Firing Bond Blast after every problem would add 2–3 min to a 4-problem session, violating the 10–12 min attention window for age 5 (Math-App-Vision.md §1.5)
- One session-closing celebration is more ceremonially meaningful than repeated finales
- `SliceStateMachine` changes are additive (new default parameter `showBondMatch = false`); all existing tests pass without modification

---

### 6. Tap-to-select + tap-to-match as primary interaction

**Decision**: Bond Blast uses a two-tap model: tap a left card to select it (glow ring), tap the matching right card to complete the pair. This is the primary interaction. Tilt drift and shake are ambient enhancements.

**Rationale**:
- Fine-motor drag to an exact pixel target is developmentally inappropriate for age 5 (Math-App-Vision.md §7 — 80×80pt targets, 20–32pt spacing)
- Two taps on large (88×88pt) targets are well within the gross-pinch motor ability of a 5-year-old
- The tap model degrades gracefully in simulator (no motion) and with audio/haptics disabled (CI)

---

## Consequences

**Positive**:
- Bond Blast is entirely additive — existing CPA stages, tests, and feature flags are unchanged
- No new runtime permissions required for the default experience (motion + haptics)
- Works identically on iPhone 15 Pro and 16e

**Negative / Trade-offs**:
- `CHHapticEngine` patterns require on-device testing; simulator falls back to UIKit (lower fidelity in dev)
- `SoundDetectionService` adds `NSMicrophoneUsageDescription` to Info.plist even when the feature is off — any App Store submission (not applicable per ADR-0002) would require justification

**Not decided here**:
- Future: Bond Blast for every problem (revisit if attention-span data from pilot sessions supports it)
- Future: AirPods head-nod as yes/no response mechanism (requires device availability data)
- Future: Pencil input for abstracting the equation (ADR-0001 process applies)
