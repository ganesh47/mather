# Physics Learning Backlog (GitHub-ready issue drafts)

## Issue 1 — Add device capability matrix and tiered unlocks
- **Objective:** Introduce runtime capability detection so base-tier features work on iPhone 16e and enhanced features unlock on iPhone 15 Pro.
- **Acceptance Criteria:**
  - `DeviceProfile` model exists with LiDAR/AR depth/motion/location/audio/camera capability flags.
  - `SensorCapabilityService` returns deterministic profile at app launch and can refresh.
  - `GameCapabilityMatrix` maps each mini-game to required/optional capabilities.
  - Lab UI shows lock/fallback state without crashes on unsupported features.
- **Implementation Notes:**
  - Add under `Services/` and `Domain/`.
  - Integrate checks in `Features/Lab/LabView.swift` and route selection path in `Domain/VerticalSliceEngine.swift`.
- **Priority:** P0
- **Phase:** Phase 1

---

## Issue 2 — Add centralized permission manager (camera/mic/location/motion)
- **Objective:** Consolidate permission requests into one service with staged prompts and parent-friendly rationale.
- **Acceptance Criteria:**
  - `PermissionManager` exists and exposes status/request methods.
  - Motion permission path uses `NSMotionUsageDescription` and handles denied state cleanly.
  - Existing camera/mic/location flows routed through manager with no regressions.
- **Implementation Notes:**
  - Reuse current `LocationService`, `RoomQuestLiveScanner`, `SoundDetectionService` behavior.
  - Update `App/Info.plist` to include `NSMotionUsageDescription`.
- **Priority:** P0
- **Phase:** Phase 1

---

## Issue 3 — Build Motion Session Recorder service
- **Objective:** Capture normalized multi-sensor streams per mini-game session.
- **Acceptance Criteria:**
  - `MotionSessionRecorder` can start/stop profiles (accel/gyro/pedometer/barometer/location).
  - Emits timestamped sample frames + quality metrics (dropouts, variance).
  - Works with `@MainActor` safety and does not leak background updates.
- **Implementation Notes:**
  - Add in `Services/`.
  - Keep raw sample retention short or in-memory by default.
- **Priority:** P0
- **Phase:** Phase 1

---

## Issue 4 — Implement Physics Metric Calculator library
- **Objective:** Convert raw samples into child-safe metrics with confidence bands.
- **Acceptance Criteria:**
  - Pure functions for speed band, acceleration burst, stop stability, cadence consistency, incline trend.
  - Every metric includes value + confidence + explanation string.
  - Unit tests added under `Tests/MatherTests` for deterministic sample fixtures.
- **Implementation Notes:**
  - Add `Domain/PhysicsMetricCalculator.swift`.
  - Follow existing pure helper style (e.g., `GravityArtistPhysics`).
- **Priority:** P0
- **Phase:** Phase 2

---

## Issue 5 — Ship first playable base-tier mini-game: Speed Sprint Lite
- **Objective:** Deliver one complete movement mini-game for both 16e and 15 Pro using timer + pedometer + accelerometer.
- **Acceptance Criteria:**
  - New game appears in `LabView` and plays end-to-end.
  - Uses pocket/armband mode gate before start.
  - Shows coarse speed band + confidence, and session summary.
  - No GPS required in default mode.
- **Implementation Notes:**
  - Add under `Features/Physics/SpeedSprintView.swift` + domain state in `Domain/`.
- **Priority:** P0
- **Phase:** Phase 2

---

## Issue 6 — Add GameSession persistence and parent trend cards
- **Objective:** Persist movement-game outcomes and show progress history.
- **Acceptance Criteria:**
  - SwiftData models for game sessions/metric summaries exist.
  - Parent summary includes trend graphs and relative-improvement messaging.
  - Data remains local-first; export optional.
- **Implementation Notes:**
  - Extend `Persistence/` and `MatherApp` container registration.
  - Integrate with `Features/ParentSummary/ParentSummaryView.swift`.
- **Priority:** P1
- **Phase:** Phase 3

---

## Issue 7 — Add safety guardrails framework
- **Objective:** Enforce runtime movement safety constraints across all physics mini-games.
- **Acceptance Criteria:**
  - `SafetyGuardrails` checks: held-vs-pocket mode, cooldowns, indoor/outdoor restrictions, risky behavior interrupt copy.
  - Every movement mini-game calls guardrail checks before scoring.
  - Parent settings include safety defaults and lock options.
- **Implementation Notes:**
  - Domain module + wiring in feature views.
  - Mirror Room Quest safety acknowledgment UX patterns.
- **Priority:** P0
- **Phase:** Phase 2-4

---

## Issue 8 — Add gyro/barometer/microphone mini-game set
- **Objective:** Expand base-tier content to include rotation, incline, and sound-energy games.
- **Acceptance Criteria:**
  - At least 3 new games: Spin & Rotation, Stair/Incline Explorer, Sound Lab.
  - Each game has fallback mode and confidence display.
  - Test coverage added for metric calculations and route transitions.
- **Implementation Notes:**
  - Reuse `MotionService` and `SoundDetectionService`; add barometer support.
- **Priority:** P1
- **Phase:** Phase 4

---

## Issue 9 — Implement AR Distance/Object Lab with non-LiDAR fallback
- **Objective:** Add camera-based AR measurement experience that runs on both target phones.
- **Acceptance Criteria:**
  - AR feature availability checked at runtime.
  - 16e path runs non-LiDAR AR estimation mode.
  - 15 Pro path may use improved depth where available.
- **Implementation Notes:**
  - Create feature in `Features/Physics/ARDistanceLabView.swift`.
  - Use ARKit support checks before session start.
- **Priority:** P1
- **Phase:** Phase 4-5

---

## Issue 10 — Ship iPhone 15 Pro LiDAR Measurement Lab (enhanced tier)
- **Objective:** Deliver Pro-only depth mini-game with safe fallback messaging on unsupported devices.
- **Acceptance Criteria:**
  - LiDAR capability verified via ARKit runtime checks.
  - On 15 Pro: depth measurement gameplay active with confidence overlays.
  - On 16e: route presents fallback game without dead-end UI.
- **Implementation Notes:**
  - Add `Features/Physics/LiDARMeasurementLabView.swift`.
  - Keep claims qualitative and educational, not lab-grade.
- **Priority:** P2
- **Phase:** Phase 5

---

## Issue 11 — Add external accessory exploration mode (optional)
- **Objective:** Evaluate one BLE education sensor integration without affecting core app requirements.
- **Acceptance Criteria:**
  - Feature behind parent/developer flag and disabled by default.
  - Integrates one pilot accessory with connection wizard and disconnect handling.
  - No core gameplay blocked when accessory absent.
- **Implementation Notes:**
  - Suggested pilot: Vernier or MbientLab.
  - Add in a separate module (e.g., `Services/ExternalSensors/`).
- **Priority:** P3
- **Phase:** Phase 6

---

## Issue 12 — Child privacy and data minimization hardening
- **Objective:** Ensure movement-learning features satisfy strict child privacy and retention boundaries.
- **Acceptance Criteria:**
  - Raw location retention defaults to off.
  - Parent-facing privacy settings page added with clear toggles.
  - Telemetry excludes unnecessary PII and biometric-like fields.
- **Implementation Notes:**
  - Update persistence schema and settings UX.
  - Audit `TelemetryWriter` event payloads for minimization.
- **Priority:** P0
- **Phase:** Cross-phase (start Phase 1)
