---
title: Mather Privacy Policy
layout: default
---

# Mather Privacy Policy

_Last updated: 2026-08-08_

Mather is a children’s learning app in active development. This page describes the privacy posture of the current codebase and TestFlight-era app behavior.

## Short version

Mather is designed to be **local-first** and **child-safe**:

- The app does **not** sell personal information.
- The app does **not** show third-party advertising.
- The app does **not** use cross-app tracking.
- Learning progress, profiles, session summaries, and gameplay telemetry are stored on the device in the current implementation.
- Sensor features are used only for gameplay and have fallback paths when unavailable or disabled.

## Information the app may store on device

Mather may save local data so a child can resume play and a parent can review progress:

- child profile nickname/emoji selected in the app;
- gameplay session summaries;
- mastery/progress records;
- spaced-repetition exposure records;
- local telemetry events such as completed stages, attempts, timing summaries, and feature settings used for a session;
- Room Quest reference data if a parent sets up room/place-based play.

This data is stored locally on the device using Apple platform storage such as SwiftData/UserDefaults in the current codebase.

## Sensors and permissions

Some activities can use device capabilities to make learning physical and playful:

- **Motion / Fitness** for tilt, shake, direction, and step-style activities.
- **Microphone** for optional sound-reaction play such as clap detection or a sound meter. Audio is processed locally for simple signal values; raw audio is not stored or transmitted by the current implementation.
- **Camera** for optional Room Quest scanning/reference photos.
- **Location** for optional Room Quest place matching when parents enable that setup.
- **Speech/audio output** for spoken prompts and sound examples.
- **Haptics** for tactile feedback.

When a sensor is unavailable, disabled, or permission-gated, Mather aims to provide an honest fallback instead of marking the child wrong.

## Network and third parties

The current app code is designed around local gameplay and local persistence. The repository uses GitHub, Xcode Cloud, and App Store Connect/TestFlight for development, CI, release, and tester feedback workflows.

On supported devices, Mather may use Apple's on-device Foundation Models framework to rewrite an embedded Memory Match description in simpler child-friendly language. The prompt contains only Mather's bundled card name, curated description, and curated facts. Prompts, model transcripts, and generated descriptions are not sent to Mather servers, included in Mather telemetry, or persisted by Mather. If the model is unavailable or its output does not pass Mather's checks, the app keeps the embedded description.

TestFlight and App Store Connect may collect crash reports, diagnostics, and tester feedback under Apple’s terms and privacy practices. Public GitHub issues intentionally avoid raw crash payloads, tester identity/contact details, exact device identifiers, and signed Apple feedback URLs.

## Children’s privacy

Mather is intended for children and is built with a conservative privacy posture:

- no behavioral advertising;
- no data selling;
- no social features for children;
- no public leaderboards;
- parent-facing controls for saved progress and feature toggles;
- local-first learning records.

Parents can clear saved summaries and telemetry for the active child profile from in-app settings where supported by the current build.

## Changes

This policy may change as Mather evolves. Material privacy changes should be reflected in this page and in app/release notes before broad distribution.

## Contact

For privacy questions or bug reports, open an issue in the repository:

<https://github.com/ganesh47/mather/issues>
