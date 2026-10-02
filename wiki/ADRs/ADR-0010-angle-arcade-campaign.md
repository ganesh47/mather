# ADR-0010: Share Angle Arcade learning and progress across platform views

Status: Accepted for implementation
Date: 2026-10-02

## Context

The TV activity repeats three ballistic targets and the iPad Angle Cannon maintains a separate aiming loop. The approved upgrade needs nine geometry-first missions on both platforms, with platform-specific accessible inputs and local progress.

## Decision

Use authored, platform-independent mission definitions and pure launch/rotation evaluation. A main-actor observable AngleArcadeEngine owns aim, attempt lifecycle, assistance and progression. SwiftUI views own only focus, motion calibration and flight rendering tasks. A versioned device-local progress store records completion and assistance; iPad keys include the active child profile and TV uses a device scope. Existing Angle Cannon routing/history remain compatible.

Three open worlds contain garden launches, builder corner/quarter-turn puzzles, and Earth/Moon launches. Physics uses fixed gravity and static obstacles, with swept collision and fixed bounds per mission. No wind, random hazards, timers or lives are introduced.

## Consequences

Both views use the same outcomes and hint decisions. Mission solvability and lifecycle can be tested independently of rendering. New sources must be explicitly included in the TV target through project.yml and regenerated with XcodeGen. Local progress does not imply mastery or synchronize between devices.
