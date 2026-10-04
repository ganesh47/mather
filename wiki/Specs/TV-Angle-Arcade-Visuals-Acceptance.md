# TV Angle Arcade world presentation

## Scope and baseline

Base: `840b1107f2e40a2137a456935f0e53db136e7bc7`. This slice owns `AppTV/AngleArcadeTVScene.swift`, the mission scene call in `AppTV/AngleArcadeTVView.swift`, and dedicated visual UI checks. The shared iPad renderer, campaign, engine, progress, scoring, remote handling, narration, world focus style, and all nine authored missions remain unchanged.

The coordinator's fresh native baseline passed two cases. Its Garden fence image at `/tmp/mather-tv-fun-20261003/baseline-screenshots/0E5CC864-4E5E-4BB5-9A05-E8CC417650DE.png` showed a small vehicle, a faint wedge/fence, and a largely empty scene. It was inspected before implementation.

`AngleArcadeTVScene(engine:flightProgress:reduceMotion:)` is a read-only renderer. Existing `AppTV/**/*.swift` target inclusion picks it up when the coordinator regenerates the project. It creates no task, timer, engine mutation, sound, focus target, or completion callback.

## Picture contract

- Launch coordinates use the shared scene's exact fixed-bounds transform: `scale = min(width * 0.84 / bounds.width, height * 0.70 / bounds.height)`; `origin.x = (width - bounds.width * scale) / 2 - bounds.minX * scale`; `origin.y = height * 0.85 + bounds.minY * scale`. World point `(x, y)` maps to `(origin.x + x * scale, origin.y - y * scale)`.
- Obstacles retain their exact model rectangles. Texture and outline remain inside the rectangle; labels identify the fence/rock without enlarging its collision silhouette. Target circles and projectile radii use their authored values multiplied by the same scale.
- The angle wedge retains its existing radius and exact angle. A larger cart and articulated barrel rotate about that same launch origin. Recoil moves only the decorative tube; the wedge, origin, sampled path, target, and obstacle remain fixed.
- Current, preview, prior-attempt, and Earth comparison paths use engine samples only. Guided/full and later/partial preview rules stay unchanged. A flying trail uses recent points from the visible sampled path; decorative floor dust does not imply a second trajectory.
- Builder retains the existing hinge `(width * 0.46, height * 0.62)` and radius `min(width * 0.23, height * 0.31)`. Both square arms and its four vertices rotate together, retaining the square corner. The gate turns around its fixed hinge, with a fixed ground ray and dotted target.
- Static clouds/hills/plants, a workshop grid/shelves, and a Moon sky/planet/craters sit behind the mathematical picture. Earth launch uses a daylight palette; lower-gravity Moon missions use the night palette. Scenery is procedural and uses system symbols, with no downloaded assets.
- Contact marks anchor to the final engine path point. Success rays/green path require `phase == .result && success`; misses receive a neutral dotted contact ring and never reveal degrees. Existing degree discovery and scene accessibility identifiers/labels/values are preserved.
- Reduce Motion suppresses recoil, flying trail, and floor dust. The existing TV reduced flight branch supplies a static full sampled shot and completes it once. Static aim, contact, degree discovery, and engine feedback remain available without movement.

## Native acceptance checks

`AngleArcadeTVVisualsUITests` adds:

1. Garden missions 1–2, then the fence mission at its initial aim: inspect cart, exact wedge, thin fence and target; submit a blocked shot and verify no completion or degree reward; correct angle/power and inspect the success contact and degree discovery. A remote power command after success must leave completion and aim unchanged.
2. Builder rigid square before/after turning, then the quarter-turn gate from 0° to 90°: inspect dotted/current shapes and the square corner; verify exact accessibility aim and post-success direction/turn degree labels.
3. Reduced Motion Earth/Moon comparison: inspect the retained actual Earth trace and Moon scene; submit a too-high shot with no reward; reduce power and verify the static success picture and unchanged completion after an ignored remote command.

Keep `AngleArcadeUITests` as the full nine-mission, replay, persistence, help, repeated input, flight cancellation/foreground, world-focus readability, and Reduced Motion regression gate. Existing campaign/engine/model tests remain the physics and single-completion gates.

The coordinator owns the single heavy Mac slot, project regeneration, builds, simulators and native test execution. Screenshot review must check all three worlds, Garden blocked/corrected contact, Builder rigid corners/quarter turn, Moon comparison and Reduced Motion. Visual checks must confirm that added decoration is subordinate, traces remain readable, and thin obstacle/target silhouettes match the actual contact point.

## Validation status and limits

Source review and `git diff --check` are worker checks. No worker build, compiler, simulator, or UI test process is permitted. Native test and screenshot results are pending coordinator execution; this document does not claim they passed.

The UI checks cover exposed remote button/accessibility behavior. Physical Siri Remote held gestures, couch-distance readability, VoiceOver audio, and the actual system Reduce Motion setting require coordinator/device review. The test-only reduced-motion launch argument is scoped to the existing Angle Arcade UI test mode.
