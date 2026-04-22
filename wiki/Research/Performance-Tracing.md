# Research: Performance Tracing

**Issue**: ganesh47/mather#251
**Status**: Completed
**Date**: 2026-04-22

---

## Goal

Define a practical baseline for profiling Mather's runtime cost before expanding further into motion, sound, and camera-heavy gameplay.

## Recommendation summary

Use a split approach:

1. **Instruments for truth** during manual profiling on device and simulator
2. **Lightweight in-app spans** for repeatable timing breadcrumbs in debug and test builds
3. **Selective XCTest metrics** in CI for regressions on launch, core loops, and memory churn
4. **A debug-only overlay** for FPS, memory, and recent sensor activity while tuning interaction-heavy screens

This keeps production code lean while still giving the team enough visibility to catch performance drift.

## 1. Instruments profiles that matter most

### Time Profiler
Use first for:
- hot paths in `VerticalSliceEngine`, `SumSprintEngine`, and session transitions
- repeated SwiftUI layout / body recomputation spikes
- sensor callback cost in `MotionService`, `SoundDetectionService`, and `RoomQuestLiveScanner`

### Allocations + Leaks
Use to verify:
- session reset actually releases temporary state
- repeated route transitions do not accumulate view models or telemetry buffers
- SwiftData / persistence writes do not retain large transient payloads

### Energy Log
Use on real iPad hardware when validating:
- continuous motion updates vs. start/stop per screen
- microphone / camera related flows
- speech + haptics overlap during rapid success feedback

### Core Animation
Use when:
- animations stutter on compact layouts
- Bond Blast or Room Quest overlays feel visually heavy
- screenshots / UI review runs start failing due to timing-sensitive layout shifts

## 2. In-app telemetry hooks worth adding

Keep hooks debug-friendly and intentionally small.

Recommended spans:
- session start -> first interactive frame
- stage transition start -> stage interactive
- Sum Sprint answer tap -> correctness feedback shown
- Bond Blast final match -> next problem visible
- Room Quest scan trigger -> scan result resolved

Implementation guidance:
- keep using `TelemetryWriter` as the narrow logging surface
- add timestamped span helpers instead of broad analytics plumbing
- gate verbose timing logs behind debug or test flags
- store duration in milliseconds and include stage / route identifiers

Example lightweight fields:
- `span_name`
- `started_at`
- `duration_ms`
- `route`
- `stage`
- `target`
- `device_class`

## 3. Sensor overhead baseline

For `CMMotionManager`, prefer **start on screen entry, stop on screen exit**.

Reasoning:
- continuous background motion updates waste energy when the child is reading or on non-sensor screens
- Mather's current interactions are stage-scoped, not globally motion-driven
- explicit lifecycle control makes regressions easier to profile in Instruments

Baseline comparison to capture during profiling:
- idle home screen with motion updates off
- Gravity Split with motion updates on for 60s
- same flow with continuous updates forced across the full session

Decision target:
- keep continuous updates only if profiling shows negligible battery/CPU cost and materially smoother interaction, otherwise scope them per active view

## 4. Memory budget targets for iPadOS 18

Use conservative soft targets for alpha:
- **steady-state app memory target**: under 200 MB on supported iPads
- **short-lived peak during heavy sensor / camera flows**: under 300 MB
- **post-session-reset recovery**: return close to pre-session baseline instead of ratcheting upward over repeated sessions

Why conservative targets help:
- they leave room for future audio, motion, and camera features
- they reduce screenshot / UI-test flake from memory pressure
- they fit the app's current educational scope, which should not need game-engine-scale memory use

## 5. CI integration

Recommended CI layer:

### XCTest metrics
Add targeted performance tests for:
- cold launch to home
- start VS1 session
- complete one deterministic loop transition
- repeated session reset memory footprint

Useful metrics:
- `XCTClockMetric`
- `XCTMemoryMetric`
- `XCTCPUMetric` where noise is acceptable

### Policy
- keep performance assertions broad at first to avoid flaky CI
- compare medians over multiple iterations rather than single hard cutoffs
- run heavier profiling on a scheduled lane, not every PR

## 6. Debug stats overlay

Add a debug-only overlay with:
- approximate FPS
- current memory footprint in MB
- active route / stage
- whether motion, sound, or camera services are currently running
- latest recorded span duration

Constraints:
- debug builds only
- hidden behind a flag or gesture
- must never appear in production or screenshot-review runs

## 7. Suggested rollout order

1. Add minimal span helpers in `TelemetryWriter`
2. Add one or two XCTest metric tests around launch and deterministic VS1 flow
3. Add debug overlay for local tuning
4. Run device profiling sessions on VS1, Bond Blast, Gravity Split, and Room Quest flows
5. Set concrete guardrails only after baseline numbers are collected

## Decision

Mather should adopt a **hybrid profiling strategy**: Instruments for deep truth, debug-only in-app spans for repeatability, and lightweight XCTest metrics for regression detection. Sensor services should default to **screen-scoped activation** rather than continuous whole-app operation until profiling proves otherwise.
