# iPhone Sensor + Physics Learning Research (Mather)

## Executive summary
Mather is already a Swift 6 + SwiftUI kids math game with working motion, microphone, camera, and location services (`MotionService`, `SoundDetectionService`, `RoomQuestLiveScanner`, `LocationService`). That makes it a strong base for a **“physics with numbers”** direction without re-platforming.

For iPhone support, design 3 capability tiers:

- **Base tier (iPhone 16e + iPhone 15 Pro):** accelerometer/gyro, pedometer, barometer, GPS/compass, camera, microphone.
- **Enhanced tier (15 Pro class):** LiDAR/depth + richer camera pipeline for AR measurement and confidence overlays.
- **Optional tier (future):** BLE/USB-C education sensors and microcontroller kits (never required for v1).

Product direction: give kids simple, safe, confidence-scored movement challenges with **relative progress** and **rough speed/effort bands**, not lab-grade claims.

---

## Current repo assessment (static inspection)

### App type, stack, architecture
- **Type:** SwiftUI iOS/iPadOS educational game app with multiple mini-game routes.
- **Language:** Swift 6 (`project.yml` sets `SWIFT_VERSION: 6.0`).
- **UI/State:** SwiftUI + `@Observable` models/services.
- **Architecture:** Central `AppModel` DI container + route engines (`VerticalSliceEngine`, `RoomQuestEngine`, `SumSprintEngine`).
- **Build system:** XcodeGen (`project.yml`) generating `Mather.xcodeproj`.
- **Persistence:** SwiftData stores for sessions/telemetry/profiles.
- **Current permissions in `App/Info.plist`:**
  - `NSMicrophoneUsageDescription`
  - `NSCameraUsageDescription`
  - `NSLocationWhenInUseUsageDescription`
  - **Missing for pedometer/history:** `NSMotionUsageDescription`.

### Existing sensor-related modules (already in repo)
- `Services/MotionService.swift`
  - Uses `CMMotionManager`, tilt (pitch/roll), shake detection, relative yaw.
- `Services/SoundDetectionService.swift`
  - Uses `AVAudioEngine` for clap-like RMS spike detection.
- `Services/LocationService.swift`
  - Uses `CLLocationManager`, when-in-use auth, live updates.
- `Services/RoomQuestLiveScanner.swift`
  - Uses `AVCaptureSession`, camera/photo + QR scanning, plus location-coupled verification.

### Existing game shell where physics modules can plug in
- Game hub: `Features/Lab/LabView.swift` (already “Explorer Lab”).
- Route enum: `Domain/VerticalSliceEngine.swift` (`AppRoute` includes lab mini-games).
- Existing physics-adjacent mini-games already present:
  - `Features/GravityArtist/GravityArtistView.swift`
  - `Features/AngleCannon/AngleCannonView.swift`
  - `Features/SymmetryFold/SymmetryFoldView.swift`
  - `Features/TwoFingerProtractor/TwoFingerProtractorView.swift`
  - `CompassAnglesView` route exists (file present in repo).

### Where to add movement-learning system
Recommended insertion points:
1. **Services layer (`Services/`)**
   - Add capability detection + multi-sensor capture.
2. **Domain layer (`Domain/`)**
   - Add metric calculators, capability matrix, mini-game protocol/engine.
3. **Persistence layer (`Persistence/`)**
   - Add motion session/game session stores (SwiftData models).
4. **Features/Lab and new Features/Physics/**
   - Add new child-facing movement mini-games and parent summaries.
5. **App/Info.plist + project.yml**
   - Add motion permission string and any future privacy keys.

---

## Device + sensor catalogue (iPhone 16e vs iPhone 15 Pro)

> Sources prioritized: Apple Support tech specs + Apple Developer docs. Reliability ratings below are for energetic kid play in home/school environments.

| Capability | 16e | 15 Pro | Primary iOS API | Permission | Physics-learning use | Reliability for kids | Privacy/safety concerns | Fallback |
|---|---:|---:|---|---|---|---|---|---|
| Accelerometer | ✅ | ✅ | Core Motion `CMMotionManager` | None (live motion); motion permission needed for pedometer/activity APIs | Start/stop bursts, jump impulse, shake intensity bands | Medium (pocket/hand noise) | Don’t incentivize risky movement with phone in hand | Timer-only challenge + tap rhythm |
| Gyroscope | ✅ | ✅ | Core Motion `CMMotionManager` | None (live gyro) | Rotation/spin, tilt-control, angular stability | Medium | Dizziness/spinning risk | Use on-screen drag rotation mode |
| Barometer / relative altitude | ✅ | ✅ | Core Motion `CMAltimeter` | Typically no prompt for live altitude stream | Stair/incline gain, “height climbed” approximation | Medium-low (indoor pressure drift) | Avoid precise altitude claims | Stair count proxy via steps/time |
| GPS location | ✅ | ✅ | Core Location `CLLocationManager` | `NSLocationWhenInUseUsageDescription` | Outdoor speed band, distance band, route-free treasure hunts | Medium outdoors / low indoors | Child-location sensitivity; minimize retention | Indoor mode with no GPS, pedometer-only |
| Compass / magnetometer | ✅ (digital compass listed) | ✅ | Core Location heading APIs (`startUpdatingHeading`) + Core Motion magnetometer | No separate prompt; location authorization typically needed for true heading context | Heading-angle matching (“turn to 90°”) | Medium-low around metal/interference | Confusing results indoors | Relative yaw from gyro only |
| Pedometer / cadence / floors | ✅ | ✅ | `CMPedometer` | `NSMotionUsageDescription` required | Step counts, cadence rhythm, improvement tracking | High for simple step count | Child activity profiling | Session-local + parent controls |
| Camera (RGB) | ✅ 2‑in‑1 system | ✅ Pro camera system | AVFoundation (`AVCaptureSession`, `AVCapturePhotoOutput`) | `NSCameraUsageDescription` | Object distance proxy (vision), scan markers, AR overlays | Medium (lighting dependent) | Camera in home/private spaces | No-camera mode / on-screen simulation |
| LiDAR depth | ❌ | ✅ | ARKit (`sceneDepth`, `supportsFrameSemantics`) + AVFoundation LiDAR depth camera APIs | Camera permission | Accurate near-field distance/size labs | High when feature available | Extra camera capture concerns | Use non-LiDAR AR estimate / known-size object mode |
| Ambient light | Hardware exists (dual ambient sensors) but no public direct lux API | Hardware exists but no stable public lux API | N/A public; indirect via camera exposure only | Camera if inferred via camera | Light/shadow concept only via camera-based estimate | Low | Avoid hidden sensing assumptions | Manual “bright/dim” child input |
| Proximity sensor | ✅ | ✅ | `UIDevice.proximityState` (`isProximityMonitoringEnabled`) | None | Pocket detect / “device secured” safety checks | Medium | False triggers with cases | Explicit parent “secured mode” toggle |
| Microphone | ✅ | ✅ | AVAudioEngine / AVAudioSession permission | `NSMicrophoneUsageDescription` | Sound energy, clap timing, rhythm | Medium | Recordings must stay local; avoid speech capture | Tap-based rhythm mode |
| Face ID / TrueDepth | ✅ | ✅ | LocalAuthentication (`LAContext`) for parent gate; ARFaceTracking for advanced AR if needed | Face ID auth prompt via OS flow | Parent gate before settings/data exports | High for auth | Never use for child scoring/identity | Passcode/parent math gate |
| Action Button | ✅ (tech specs list) | ✅ | No direct “action button press” API for 3rd-party apps | N/A | Optional shortcut launcher into game | High if configured externally | UX confusion if expected in-app | In-app quick start button |
| USB‑C external accessories | ✅ (USB 2 speed) | ✅ (USB 3 up to 10Gb/s) | ExternalAccessory, CoreBluetooth, USB accessory SDKs | Depends on accessory/BLE/camera/mic/location | Optional sensor kits, external IMUs | Medium (cables/disconnects) | Physical safety with cables for kids | BLE wireless-first; accessory-free default |
| UWB / Nearby Interaction | Not clearly listed in 16e tech spec (treat as unknown/off by default) | ✅ Ultra Wideband availability noted on 15 Pro specs | NearbyInteraction framework | Nearby Interaction entitlement/capability; BLE link often needed | Direction/distance to paired tags in future | Medium (setup-heavy) | Tracking concerns | Keep out of v1; use BLE RSSI if needed |
| ARKit baseline | ✅ (A9+ class support expected) | ✅ | ARKit `ARConfiguration.isSupported` | Camera permission | Plane-based AR teaching overlays | Medium | Camera use + motion discomfort | 2D overlays |
| ARKit scene depth / reconstruction | Likely ❌ (no LiDAR) | ✅ | `supportsFrameSemantics(.sceneDepth)`, `supportsSceneReconstruction` | Camera permission | Measurement lab + confidence visualization | High on supported devices | Overclaim risk | Simplified measurement bands |
| Simulator support | Limited | Limited | N/A | N/A | UI flow only | Low for sensor validation | False confidence if tested only in simulator | Mandatory real-device QA matrix |

### Notes and clarifications
- **iPhone 16e** official tech spec lists sensors: Face ID, barometer, high dynamic range gyro, high-g accelerometer, proximity, dual ambient light sensors.
- **iPhone 15 Pro** official tech spec includes **LiDAR scanner** and lists UWB availability (region dependent).
- Ambient light is not exposed as a stable public “lux sensor API”; treat as non-guaranteed.

---

## External kits and accessory catalogue (optional/future)

> v1 must not depend on these. Use only for opt-in “home science pack” later.

| Kit | Sensors | Connection | iOS compatibility | SDK/API likely | Kid safety | Consumer app fit | Recommendation |
|---|---|---|---|---|---|---|---|
| Vernier Go Direct family | acceleration, sound, temp, light, etc. (model dependent) | BLE + USB | Strong (Vernier iOS support/apps) | Mostly vendor app workflow; custom integration depends on protocol availability | Small parts, school handling needed | Good for guided parent mode | **Later (Phase 6 pilot)** |
| PASCO Wireless Sensors | motion, weather, force, temp, etc. | BLE | Strong via SPARKvue ecosystem | Vendor ecosystem first; custom app integration may be limited | School-lab hardware considerations | Better for education partnerships than consumer v1 | **Later / partnership path** |
| MbientLab MetaMotion (R/S/C series) | IMU + environmental variants | BLE | iOS API support advertised | iOS SDK available historically | Wearable straps/choking/supervision considerations | Strong for R&D spike, less mainstream retail | **Phase 1 spike only** |
| Arduino Nano 33 BLE Sense (dev kit) | IMU, mic, temp/humidity/pressure, light, proximity | BLE / USB | CoreBluetooth possible | Custom protocol engineering required | DIY hardware risks, not child-ready | Developer tooling, not child consumer out-of-box | **Research/prototyping only** |
| BBC micro:bit | accel, magnetometer, temp (basic), buttons | BLE / USB | iOS app ecosystem exists | Custom BLE profile integration possible | Battery packs/wires supervision needed | Good educational add-on, not required | **Optional future classroom mode** |
| Nordic Thingy:52 | 9-axis motion + env sensors | BLE | iOS app/libs available | BLE SDK path exists | Dev-kit enclosure not toy-certified | Good internal prototyping | **Avoid for consumer v1; R&D only** |

Decision rule:
- **v1:** internal phone sensors only.
- **Later:** accessories only behind parent opt-in + explicit hardware setup wizard.

---

## Capability tiers

### Tier A — Base (16e + 15 Pro)
- Core Motion (accel/gyro), pedometer, barometer, core camera, mic, optional location.
- All core gameplay and progression works here.
- Child-facing claims use words like “about,” “band,” “try again,” “improved.”

### Tier B — Enhanced (15 Pro)
- LiDAR/scene depth driven distance and object-size mini-games.
- Rich confidence overlays (green/yellow/red confidence bands).
- Optional pro camera quality boosts for detection robustness.

### Tier C — Optional future
- BLE/USB-C external sensors for parent-supervised “science lab mode”.
- Never gating progression or core learning.

---

## Sensor-driven mini-game concepts (10)

### 1) Speed Sprint
- Physics: speed = distance/time (banded).
- Age: 6–9.
- Sensors: pedometer + optional GPS outdoors.
- Calculation: step cadence + stride estimate; if outdoor GPS quality good, blend for coarse speed band.
- Base 16e: yes.
- Enhanced 15 Pro: camera-based AR lane overlays optional.
- Fallback: timer + steps only.
- UI: rocket speedometer with turtle/rabbit/cheetah bands.
- Scoring: consistency + personal best delta.
- Safety: pocket/armband mode only.
- Complexity: M.

### 2) Start Burst
- Physics: acceleration burst.
- Age: 6–9.
- Sensors: accelerometer.
- Calculation: high-pass filtered acceleration peak over 2 s window.
- Base: yes.
- Enhanced: pro motion smoothing profile on 15 Pro.
- Fallback: tap burst challenge.
- UI: “launch meter.”
- Scoring: best of 3 with confidence.
- Safety: no jumping with phone in hand.
- Complexity: S-M.

### 3) Stop Challenge
- Physics: deceleration / control.
- Age: 6–9.
- Sensors: accelerometer + pedometer.
- Calculation: detect motion onset then stable stop interval.
- Base: yes.
- Enhanced: AR finish-line visualization.
- Fallback: rhythm stop using taps.
- UI: traffic-light stop game.
- Scoring: closest to target stop window.
- Safety: clear space check.
- Complexity: M.

### 4) Jump Lab
- Physics: impulse / airtime proxy.
- Age: 7–10.
- Sensors: accelerometer + barometer (optional).
- Calculation: peak vertical acceleration + brief unload period; barometer for trend only.
- Base: yes.
- Enhanced: slow-mo camera replay overlay.
- Fallback: squat-count challenge.
- UI: trampoline graph.
- Scoring: smooth jump quality, not max force.
- Safety: soft floor, adult supervision.
- Complexity: M.

### 5) Rhythm Runner
- Physics: periodic motion, frequency.
- Age: 5–8.
- Sensors: pedometer cadence + mic clap optional.
- Calculation: cadence variance vs target bpm bands.
- Base: yes.
- Enhanced: spatial audio cues.
- Fallback: tap-to-beat mode.
- UI: drum lane + cartoon footsteps.
- Scoring: streak-based rhythm match.
- Safety: indoor low-speed mode default.
- Complexity: S-M.

### 6) Stair/Incline Explorer
- Physics: elevation gain, potential energy concept (qualitative).
- Age: 7–10.
- Sensors: CMAltimeter + pedometer.
- Calculation: relative altitude trend + floors ascended (if available).
- Base: yes.
- Enhanced: LiDAR staircase detection aid (15 Pro exploratory).
- Fallback: step-count hill simulation.
- UI: mountain climb with flags.
- Scoring: steady climb challenge.
- Safety: handrail reminder, no running stairs.
- Complexity: M.

### 7) Spin & Rotation Studio
- Physics: angular velocity, rotation count.
- Age: 6–9.
- Sensors: gyro.
- Calculation: integrate yaw rate with drift correction windows.
- Base: yes.
- Enhanced: AR compass ring.
- Fallback: on-screen rotate knob.
- UI: “satellite spin” dial.
- Scoring: hit target angles (90/180/360).
- Safety: anti-dizziness cooldown prompts.
- Complexity: M.

### 8) Sound Lab
- Physics: amplitude/energy (not decibels claim).
- Age: 5–8.
- Sensors: microphone.
- Calculation: RMS envelope and clap timing.
- Base: yes.
- Enhanced: better noise suppression presets.
- Fallback: button-tap loud/quiet simulation.
- UI: blob grows with sound energy.
- Scoring: match loud/soft pattern.
- Safety: “no yelling close to phone”.
- Complexity: S.

### 9) AR Distance/Object Lab
- Physics: distance estimation + comparison.
- Age: 7–10.
- Sensors: camera + ARKit world tracking.
- Calculation: raycast distance with confidence bands.
- Base: yes (non-LiDAR AR estimate).
- Enhanced: better stability with LiDAR on 15 Pro.
- Fallback: known-object-size estimate cards.
- UI: tape-measure beam.
- Scoring: closest estimate wins.
- Safety: indoor boundary reminders.
- Complexity: M-L.

### 10) LiDAR Measurement Lab (15 Pro enhanced only)
- Physics: depth mapping, object height/volume approximation.
- Age: 8–11.
- Sensors: LiDAR scene depth + RGB.
- Calculation: scene depth sampling + confidence map + smoothing.
- Base 16e: unavailable.
- Enhanced 15 Pro: full experience.
- Fallback: redirect to AR Distance/Object Lab.
- UI: “scan and reveal” depth heatmap.
- Scoring: complete measurement missions.
- Safety: no scanning faces/people for scoring.
- Complexity: L.

---

## Practical sensor-fusion strategy

### Principles
- Prioritize **robustness + kid safety** over precision.
- Publish **confidence levels** with each metric (high/medium/low).
- Use cross-checks before showing “result badges.”

### Fusion pipeline
1. **Capability detect at launch** (and refresh when needed).
2. **Per-game sensor profile** requests only required streams.
3. **Time alignment** into a common timeline (e.g., 20–50 Hz normalized samples).
4. **Quality gates** (signal variance, dropout rate, permission state).
5. **Metric calculators** output:
   - value band
   - confidence score
   - explanatory string for child/parent.
6. **Telemetry + history** store derived metrics, not raw high-frequency traces by default.

### Suggested confidence model
- **High:** two independent indicators align (e.g., pedometer + accel cadence).
- **Medium:** single reliable sensor with clean signal.
- **Low:** sparse/noisy data or partial permission.

### Avoid overclaiming
Use language templates:
- “about 3.2 m/s (medium confidence)”
- “faster than your last 3 tries”
- “great consistency today”

---

## Implementation architecture mapped to this repo

### New services/models to add

1. **`Services/SensorCapabilityService.swift`**
   - Detect: motion, pedometer, altimeter, heading, location auth, camera auth, microphone auth, ARKit/LiDAR support.
   - API: `currentProfile() -> DeviceProfile`.

2. **`Services/PermissionManager.swift`**
   - Centralize staged permission prompts.
   - Reuse existing patterns from `LocationService` and camera/mic flows.

3. **`Services/MotionSessionRecorder.swift`**
   - Start/stop sessions with requested sensors.
   - Expose sampled stream + quality flags.

4. **`Domain/PhysicsMetricCalculator.swift`**
   - Pure calculators for speed bands, acceleration peaks, cadence consistency, incline trends, rotation counts.

5. **`Domain/DeviceProfile.swift`**
   - Device capability snapshot (`hasLiDAR`, `supportsSceneDepth`, `hasBarometer`, etc).

6. **`Domain/GameCapabilityMatrix.swift`**
   - Map each mini-game to required/optional capabilities.
   - Drives tier unlocks and fallback selection.

7. **`Domain/GameSession.swift`**
   - Session summary model with confidence and safety flags.

8. **`Domain/SafetyGuardrails.swift`**
   - Runtime checks: movement mode, cooldowns, stop conditions.

9. **`Domain/MiniGameEngine.swift`**
   - Protocol + coordinator for game lifecycle.

### Persistence integration
- Add new SwiftData models in `Persistence/`:
  - `StoredGameSession`
  - `StoredPhysicsMetricSummary`
- Extend `MatherApp` model container registration.
- Keep data local-first, short retention defaults.

### UI integration points
- `Features/Lab/LabView.swift`: add new tiles + tier badges.
- Add `Features/Physics/` for new mini-game screens.
- `Features/ParentSummary/ParentSummaryView.swift`: add movement trend cards.
- `Features/ParentSummary/SettingsView.swift`: add sensor/privacy controls and indoor/outdoor mode.

### Existing code reuse opportunities
- `MotionService` as base for orientation stream.
- `SoundDetectionService` for Sound Lab v1.
- `RoomQuest` safety and camera flow patterns for permission UX.
- `TelemetryWriter` event logging shape for new game events.

---

## Roadmap (phased)

### Phase 0 — catalogue + assessment
- Deliver this research doc + backlog.
- Confirm target APIs and privacy model.

### Phase 1 — real-device sensor spike (16e + 15 Pro)
- Build internal diagnostic screen in `Features/Lab` gated by parent mode.
- Validate sampling rates, drift, and confidence rules on both devices.

### Phase 2 — first playable base-tier game
- Implement **Speed Sprint Lite** (timer + pedometer + accelerometer).
- Add `NSMotionUsageDescription` and motion permission flow.

### Phase 3 — session history + graphs + kid feedback
- Persist `GameSession` and show parent trend charts.
- Add confidence and “improvement vs self” language.

### Phase 4 — broaden base tier
- Add gyro, barometer, microphone, and camera mini-games from list.

### Phase 5 — 15 Pro enhanced AR/LiDAR
- Ship LiDAR Measurement Lab behind capability gate.
- Fallback to non-LiDAR AR mode on 16e.

### Phase 6 — external kit exploration
- Pilot one BLE education kit with parent opt-in flow.
- Validate support burden before productizing.

---

## Safety + privacy guardrails

- No design that encourages sprinting while holding phone.
- Default to **pocket/armband mode** for movement games.
- Parent gate before enabling outdoor/location modes.
- Local-first storage; cloud sync optional and off by default.
- Don’t retain raw location trails unless explicitly enabled by parent.
- Child data minimization; no biometric profiling.
- Permission minimization: ask only at feature entry.
- Explicit Indoor/Outdoor mode toggles with different sensor mixes.

---

## Backlog seed (summary)
Detailed GitHub-ready backlog is in `docs/physics-learning-backlog.md`.

---

## Open questions
1. Is iPhone-only support now a product requirement, or must iPad remain first-class simultaneously?
2. What age segmentation should gate game difficulty and safety prompts?
3. Should any outdoor/location mini-game be opt-in per session or permanently disabled by default?
4. What retention period is acceptable for child movement summaries?
5. Is there a parent PIN/Face ID gate requirement before changing safety settings?
6. Should LiDAR enhanced content be purely optional or part of premium progression?

---

## Sources

### Apple official device specs
- iPhone 16e Tech Specs: https://support.apple.com/en-us/122208
- iPhone 15 Pro Tech Specs: https://support.apple.com/en-la/111829

### Apple developer docs (APIs/permissions)
- `CMMotionManager`: https://developer.apple.com/documentation/coremotion/cmmotionmanager
- `CMAltimeter`: https://developer.apple.com/documentation/coremotion/cmaltimeter
- `CMPedometer`: https://developer.apple.com/documentation/coremotion/cmpedometer
- `NSMotionUsageDescription`: https://developer.apple.com/documentation/bundleresources/information-property-list/nsmotionusagedescription
- `CLLocationManager` + when-in-use auth: https://developer.apple.com/documentation/corelocation/cllocationmanager
- `requestWhenInUseAuthorization`: https://developer.apple.com/documentation/corelocation/cllocationmanager/requestwheninuseauthorization%28%29
- Heading/compass guidance: https://developer.apple.com/documentation/corelocation/getting-heading-and-course-information
- ARKit device support guidance: https://developer.apple.com/documentation/arkit/verifying-device-support-and-user-permission
- AR `isSupported`: https://developer.apple.com/documentation/arkit/arconfiguration/issupported
- AR scene depth: https://developer.apple.com/documentation/arkit/arconfiguration/framesemantics-swift.struct/scenedepth
- AR scene reconstruction support check: https://developer.apple.com/documentation/arkit/arworldtrackingconfiguration/scenereconstruction
- LiDAR depth capture (AVFoundation): https://developer.apple.com/documentation/avfoundation/capturing-depth-using-the-lidar-camera
- Camera permission API: https://developer.apple.com/documentation/avfoundation/avcapturedevice/authorizationstatus%28for%3A%29
- Proximity (`UIDevice`): https://developer.apple.com/documentation/uikit/uidevice
- Nearby Interaction (UWB): https://developer.apple.com/documentation/nearbyinteraction

### External kit references (non-v1 optional)
- Vernier Go Direct overview: https://www.vernier.com/products/go-direct
- Vernier iOS usage page: https://www.vernier.com/til/get-started/go-direct/ios
- PASCO SPARKvue help center: https://help.pasco.com/sparkvue/
- MbientLab MetaMotion sensors: https://mbientlab.com/metamotions/
- Arduino Nano 33 BLE Sense hardware page: https://docs.arduino.cc/hardware/nano-33-ble-sense
- micro:bit iOS BLE guide: https://microbit.org/get-started/user-guide/ble-ios/
- Nordic Thingy:52 app/product page: https://www.nordicsemi.com/Products/Development-tools/Nordic-Thingy-52-App
