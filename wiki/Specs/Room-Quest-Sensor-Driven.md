# Spec: Room Quest — Sensor-Driven Scavenger Mode

**Status**: Draft
**Date**: 2026-04-11
**Supersedes direction in**: `Room-Quest-Future-Vertical-Slice.md`
**Research base**:
- `wiki/Research/Room-Scale-Embodied-Math-Gameplay.md`
- `wiki/Research/Room-Quest-Sensor-Capabilities-and-Design-Direction.md`

---

## Overview

Room Quest should be redesigned as a **sensor-driven scavenger mode** that uses the best available device capabilities without pretending to have exact indoor positioning when it does not.

This means:
- **not GPS-first indoor gameplay**
- **not altitude-only room localization**
- **not a purely manual card-only baseline**
- **yes to marker-guided stations with camera recognition and motion/audio assistance**
- **yes to LiDAR-enhanced setup/anchoring on devices that actually support it**

---

## Product framing

Room Quest is a **device-guided embodied scavenger math mode**.

The child should feel:
- the device is guiding me to the next station
- I found the station and unlocked the next clue
- my movement matters

The parent should feel:
- setup is simple and trustworthy
- the device is using visible, understandable signals
- the game still works even if advanced sensors are unavailable

---

## Design principles

1. **Station identity must be explicit**.
2. **High-precision hardware enhances, but does not redefine, the loop**.
3. **No fake exactness**.
4. **The app guides; the child still plays physically**.
5. **Graceful degradation is a core requirement**.
6. **Fallbacks are part of the primary design**.

---

## Hardware tiers

### Tier A: LiDAR-enhanced
**Devices**: iPhone 15 Pro-class hardware

Capabilities used:
- camera marker detection
- ARKit plane/image anchoring
- LiDAR-enhanced scene understanding
- motion / heading
- audio / haptics

### Tier B: camera + motion baseline
**Devices**: iPhone 16e, iPad Air, and any non-LiDAR supported device

Capabilities used:
- camera marker detection
- motion / heading
- audio / haptics
- optional ARKit image detection without LiDAR-specific assumptions

### Explicit non-goals
- GPS-first room positioning
- UWB-dependent station finding
- altitude-defined station identity

---

## Core interaction model

### Setup
1. Parent chooses Room Quest.
2. App asks parent to place physical station markers in safe locations.
3. Parent scans each station once with the device.
4. App confirms station registration and associates each with a role.
5. App shows a compact ready-to-hunt summary.

### Play loop
1. App gives the child a clue or mission.
2. Child moves through the room with the device-guided flow.
3. On arrival, child scans or confirms the station.
4. App unlocks a count, collection, or grouping challenge.
5. Child completes embodied math action.
6. App guides to the next station.
7. Session returns to on-screen CPA representation and abstraction.

---

## MVP gameplay loops

### Loop A: Find and Count
- simplest embodied baseline
- validates the station-guided hunt feel

### Loop B: Find and Gather
- stronger CPA continuity
- maps physical grouping to part-part-whole thinking

### Loop C: Find and Unlock
- stronger scavenger fantasy
- unlocks the next clue or mini-challenge through station discovery

---

## Product rule

Sensors must act as **enhancement layers**, not gates to understanding.

The child must be able to complete the core experience without LiDAR, GPS, UWB, or fragile vision-only assumptions.
