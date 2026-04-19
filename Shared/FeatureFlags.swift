import Foundation
import Observation

@Observable
final class FeatureFlagService {
    private enum Keys {
        static let verticalSlice1Enabled  = "feature.verticalSlice1Enabled"
        // Place-matching thresholds (tunable from Settings)
        static let placeMatchGPSMatch     = "placeMatch.gpsMatchMetres"
        static let placeMatchGPSClose     = "placeMatch.gpsCloseMetres"
        static let placeMatchGPSCutoff    = "placeMatch.gpsAccuracyCutoff"
        static let placeMatchVisionMatch  = "placeMatch.visionMatchDistance"
        static let placeMatchVisionClose  = "placeMatch.visionCloseDistance"
        static let testModeEnabled = "feature.testModeEnabled"
        static let audioEnabled = "feature.audioEnabled"
        static let hapticsEnabled = "feature.hapticsEnabled"
        static let selectedThemeId = "feature.selectedThemeId"
        static let vs1BondMatchEnabled = "feature.vs1BondMatchEnabled"
        static let vs1GravitySplitEnabled = "feature.vs1GravitySplitEnabled"
        static let makeBreakLoopV2Enabled = "feature.makeBreakLoopV2Enabled"
        static let motionControlsEnabled = "feature.motionControlsEnabled"
        static let soundReactionEnabled = "feature.soundReactionEnabled"
        static let roomQuestEnabled = "feature.roomQuestEnabled"
        static let roomQuestSafetyAcknowledged = "feature.roomQuestSafetyAcknowledged"
        static let roomQuestMarkerSetupEnabled = "feature.roomQuestMarkerSetupEnabled"
        static let roomQuestReferenceCaptureEnabled = "feature.roomQuestReferenceCaptureEnabled"
        static let sumSprintEnabled = "feature.sumSprintEnabled"
        static let symmetryFoldEnabled = "feature.symmetryFoldEnabled"
        static let rectangleFactoryEnabled = "feature.rectangleFactoryEnabled"
        static let angleCannonEnabled = "feature.angleCannonEnabled"
        static let twoFingerProtractorEnabled = "feature.twoFingerProtractorEnabled"
        static let gravityArtistEnabled = "feature.gravityArtistEnabled"
        static let compassAnglesEnabled = "feature.compassAnglesEnabled"
    }

    var verticalSlice1Enabled: Bool {
        didSet { defaults.set(verticalSlice1Enabled, forKey: Keys.verticalSlice1Enabled) }
    }

    var testModeEnabled: Bool {
        didSet { defaults.set(testModeEnabled, forKey: Keys.testModeEnabled) }
    }

    var audioEnabled: Bool {
        didSet { defaults.set(audioEnabled, forKey: Keys.audioEnabled) }
    }

    var hapticsEnabled: Bool {
        didSet { defaults.set(hapticsEnabled, forKey: Keys.hapticsEnabled) }
    }

    /// Identifies the active theme for the next session.
    /// Valid values: `"classic"` (default), `"vehicle"`.
    /// Injected via launch argument `-feature.selectedThemeId classic` in UI tests.
    var selectedThemeId: String {
        didSet { defaults.set(selectedThemeId, forKey: Keys.selectedThemeId) }
    }

    /// Gates the Bond Blast complement-match finale stage at the end of each VS1 session.
    var vs1BondMatchEnabled: Bool {
        didSet { defaults.set(vs1BondMatchEnabled, forKey: Keys.vs1BondMatchEnabled) }
    }

    /// Replaces the Transfer (Show it) stepper stage with the tilt-powered balance activity.
    /// Default false — parent opts in via Settings.
    var vs1GravitySplitEnabled: Bool {
        didSet { defaults.set(vs1GravitySplitEnabled, forKey: Keys.vs1GravitySplitEnabled) }
    }

    /// Enables the issue #222 per-target loop: Make it -> Gravity Split -> Sum Sprint -> Bond Blast.
    var makeBreakLoopV2Enabled: Bool {
        didSet { defaults.set(makeBreakLoopV2Enabled, forKey: Keys.makeBreakLoopV2Enabled) }
    }

    /// Enables CMMotionManager tilt drift and shake-to-shuffle in Bond Blast.
    /// Defaults to true; parent can disable in Settings.
    var motionControlsEnabled: Bool {
        didSet { defaults.set(motionControlsEnabled, forKey: Keys.motionControlsEnabled) }
    }

    /// Enables AVAudioEngine clap detection in Bond Blast.
    /// Defaults to false — requires NSMicrophoneUsageDescription permission.
    var soundReactionEnabled: Bool {
        didSet { defaults.set(soundReactionEnabled, forKey: Keys.soundReactionEnabled) }
    }

    /// Gates the Room Quest companion slice. Default false; parent enables in Settings.
    var roomQuestEnabled: Bool {
        didSet { defaults.set(roomQuestEnabled, forKey: Keys.roomQuestEnabled) }
    }

    /// Persists whether the parent has acknowledged the Room Quest safety checklist.
    /// Shown once before the first Room Quest session.
    var roomQuestSafetyAcknowledged: Bool {
        didSet { defaults.set(roomQuestSafetyAcknowledged, forKey: Keys.roomQuestSafetyAcknowledged) }
    }

    /// Enables real camera-backed marker scanning during Room Quest setup.
    var roomQuestMarkerSetupEnabled: Bool {
        didSet { defaults.set(roomQuestMarkerSetupEnabled, forKey: Keys.roomQuestMarkerSetupEnabled) }
    }

    /// Enables saving a lightweight station reference during camera verification.
    var roomQuestReferenceCaptureEnabled: Bool {
        didSet { defaults.set(roomQuestReferenceCaptureEnabled, forKey: Keys.roomQuestReferenceCaptureEnabled) }
    }

    /// Gates the Sum Sprint fluency activity (sums 11–20). Default false; parent enables in Settings.
    var sumSprintEnabled: Bool {
        didSet { defaults.set(sumSprintEnabled, forKey: Keys.sumSprintEnabled) }
    }

    /// Gates the Symmetry Fold geometry activity (ages 5–7). Default false; parent enables in Settings.
    var symmetryFoldEnabled: Bool {
        didSet { defaults.set(symmetryFoldEnabled, forKey: Keys.symmetryFoldEnabled) }
    }

    /// Gates the Rectangle Factory factor-discovery activity (ages 7–9). Default false; parent enables in Settings.
    var rectangleFactoryEnabled: Bool {
        didSet { defaults.set(rectangleFactoryEnabled, forKey: Keys.rectangleFactoryEnabled) }
    }

    /// Gates the Angle Cannon geometry activity (ages 7–9). Default false; parent enables in Settings.
    var angleCannonEnabled: Bool {
        didSet { defaults.set(angleCannonEnabled, forKey: Keys.angleCannonEnabled) }
    }

    /// Gates the Two-Finger Protractor angle-measurement activity (ages 7–9). Default false; parent enables in Settings.
    var twoFingerProtractorEnabled: Bool {
        didSet { defaults.set(twoFingerProtractorEnabled, forKey: Keys.twoFingerProtractorEnabled) }
    }

    /// Gates the Gravity Artist predict-then-fire projectile activity (ages 8–10). Default false; parent enables in Settings.
    var gravityArtistEnabled: Bool {
        didSet { defaults.set(gravityArtistEnabled, forKey: Keys.gravityArtistEnabled) }
    }

    /// Gates the Compass Angles body-rotation activity (ages 7–9). Default false; parent enables in Settings.
    var compassAnglesEnabled: Bool {
        didSet { defaults.set(compassAnglesEnabled, forKey: Keys.compassAnglesEnabled) }
    }

    // MARK: - Place-matching thresholds

    /// GPS match radius in metres. Default 8 m. Tighter = harder to get false match indoors.
    var placeMatchGPSMatch: Double {
        didSet { defaults.set(placeMatchGPSMatch, forKey: Keys.placeMatchGPSMatch) }
    }
    /// GPS "close" radius in metres. Must be greater than `placeMatchGPSMatch`. Default 20 m.
    var placeMatchGPSClose: Double {
        didSet { defaults.set(placeMatchGPSClose, forKey: Keys.placeMatchGPSClose) }
    }
    /// Discard GPS fixes with horizontal accuracy worse than this (metres). Default 10 m.
    var placeMatchGPSCutoff: Double {
        didSet { defaults.set(placeMatchGPSCutoff, forKey: Keys.placeMatchGPSCutoff) }
    }
    /// VNFeaturePrintObservation match distance. Default 0.25. Lower = stricter.
    var placeMatchVisionMatch: Double {
        didSet { defaults.set(placeMatchVisionMatch, forKey: Keys.placeMatchVisionMatch) }
    }
    /// VNFeaturePrintObservation "close" distance. Default 0.50.
    var placeMatchVisionClose: Double {
        didSet { defaults.set(placeMatchVisionClose, forKey: Keys.placeMatchVisionClose) }
    }

    /// Live snapshot of thresholds — read by `RoomQuestLiveScanner` at scan time.
    var placeMatchThresholds: PlaceMatchThresholds {
        PlaceMatchThresholds(
            gpsMatchMetres:    placeMatchGPSMatch,
            gpsCloseMetres:    placeMatchGPSClose,
            gpsAccuracyCutoff: placeMatchGPSCutoff,
            visionMatchDistance: Float(placeMatchVisionMatch),
            visionCloseDistance: Float(placeMatchVisionClose)
        )
    }

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        // Register fallback defaults so bool(forKey:) returns the correct value
        // for keys that have never been persisted. bool(forKey:) also handles
        // "YES"/"NO"/"1"/"0" string values injected via -key value launch arguments,
        // which object(forKey:) as? Bool does not.
        defaults.register(defaults: [
            Keys.verticalSlice1Enabled: false,
            Keys.testModeEnabled: true,
            Keys.audioEnabled: true,
            Keys.hapticsEnabled: true,
            Keys.selectedThemeId: "classic",
            Keys.vs1BondMatchEnabled: false,
            Keys.vs1GravitySplitEnabled: false,
            Keys.makeBreakLoopV2Enabled: false,
            Keys.motionControlsEnabled: true,
            Keys.soundReactionEnabled: false,
            Keys.roomQuestEnabled: false,
            Keys.roomQuestSafetyAcknowledged: false,
            Keys.roomQuestMarkerSetupEnabled: true,
            Keys.roomQuestReferenceCaptureEnabled: true,
            Keys.sumSprintEnabled: false,
            Keys.symmetryFoldEnabled: false,
            Keys.rectangleFactoryEnabled: false,
            Keys.angleCannonEnabled: false,
            Keys.twoFingerProtractorEnabled: false,
            Keys.gravityArtistEnabled: false,
            Keys.compassAnglesEnabled: false,
            Keys.placeMatchGPSMatch:    PlaceMatchThresholds.default.gpsMatchMetres,
            Keys.placeMatchGPSClose:    PlaceMatchThresholds.default.gpsCloseMetres,
            Keys.placeMatchGPSCutoff:   PlaceMatchThresholds.default.gpsAccuracyCutoff,
            Keys.placeMatchVisionMatch: Double(PlaceMatchThresholds.default.visionMatchDistance),
            Keys.placeMatchVisionClose: Double(PlaceMatchThresholds.default.visionCloseDistance),
        ])
        verticalSlice1Enabled = defaults.bool(forKey: Keys.verticalSlice1Enabled)
        testModeEnabled = defaults.bool(forKey: Keys.testModeEnabled)
        audioEnabled = defaults.bool(forKey: Keys.audioEnabled)
        hapticsEnabled = defaults.bool(forKey: Keys.hapticsEnabled)
        selectedThemeId = defaults.string(forKey: Keys.selectedThemeId) ?? "classic"
        vs1BondMatchEnabled = defaults.bool(forKey: Keys.vs1BondMatchEnabled)
        vs1GravitySplitEnabled = defaults.bool(forKey: Keys.vs1GravitySplitEnabled)
        makeBreakLoopV2Enabled = defaults.bool(forKey: Keys.makeBreakLoopV2Enabled)
        motionControlsEnabled = defaults.bool(forKey: Keys.motionControlsEnabled)
        soundReactionEnabled = defaults.bool(forKey: Keys.soundReactionEnabled)
        roomQuestEnabled = defaults.bool(forKey: Keys.roomQuestEnabled)
        roomQuestSafetyAcknowledged = defaults.bool(forKey: Keys.roomQuestSafetyAcknowledged)
        roomQuestMarkerSetupEnabled = defaults.bool(forKey: Keys.roomQuestMarkerSetupEnabled)
        roomQuestReferenceCaptureEnabled = defaults.bool(forKey: Keys.roomQuestReferenceCaptureEnabled)
        sumSprintEnabled = defaults.bool(forKey: Keys.sumSprintEnabled)
        symmetryFoldEnabled = defaults.bool(forKey: Keys.symmetryFoldEnabled)
        rectangleFactoryEnabled = defaults.bool(forKey: Keys.rectangleFactoryEnabled)
        angleCannonEnabled = defaults.bool(forKey: Keys.angleCannonEnabled)
        twoFingerProtractorEnabled = defaults.bool(forKey: Keys.twoFingerProtractorEnabled)
        gravityArtistEnabled = defaults.bool(forKey: Keys.gravityArtistEnabled)
        compassAnglesEnabled = defaults.bool(forKey: Keys.compassAnglesEnabled)
        placeMatchGPSMatch   = defaults.double(forKey: Keys.placeMatchGPSMatch)
        placeMatchGPSClose   = defaults.double(forKey: Keys.placeMatchGPSClose)
        placeMatchGPSCutoff  = defaults.double(forKey: Keys.placeMatchGPSCutoff)
        placeMatchVisionMatch = defaults.double(forKey: Keys.placeMatchVisionMatch)
        placeMatchVisionClose = defaults.double(forKey: Keys.placeMatchVisionClose)
    }
}
