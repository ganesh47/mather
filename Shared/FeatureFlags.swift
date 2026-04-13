import Foundation
import Observation

@Observable
final class FeatureFlagService {
    private enum Keys {
        static let verticalSlice1Enabled = "feature.verticalSlice1Enabled"
        static let testModeEnabled = "feature.testModeEnabled"
        static let audioEnabled = "feature.audioEnabled"
        static let hapticsEnabled = "feature.hapticsEnabled"
        static let selectedThemeId = "feature.selectedThemeId"
        static let vs1BondMatchEnabled = "feature.vs1BondMatchEnabled"
        static let motionControlsEnabled = "feature.motionControlsEnabled"
        static let soundReactionEnabled = "feature.soundReactionEnabled"
        static let roomQuestEnabled = "feature.roomQuestEnabled"
        static let roomQuestSafetyAcknowledged = "feature.roomQuestSafetyAcknowledged"
        static let roomQuestMarkerSetupEnabled = "feature.roomQuestMarkerSetupEnabled"
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
            Keys.motionControlsEnabled: true,
            Keys.soundReactionEnabled: false,
            Keys.roomQuestEnabled: false,
            Keys.roomQuestSafetyAcknowledged: false,
            Keys.roomQuestMarkerSetupEnabled: true,
        ])
        verticalSlice1Enabled = defaults.bool(forKey: Keys.verticalSlice1Enabled)
        testModeEnabled = defaults.bool(forKey: Keys.testModeEnabled)
        audioEnabled = defaults.bool(forKey: Keys.audioEnabled)
        hapticsEnabled = defaults.bool(forKey: Keys.hapticsEnabled)
        selectedThemeId = defaults.string(forKey: Keys.selectedThemeId) ?? "classic"
        vs1BondMatchEnabled = defaults.bool(forKey: Keys.vs1BondMatchEnabled)
        motionControlsEnabled = defaults.bool(forKey: Keys.motionControlsEnabled)
        soundReactionEnabled = defaults.bool(forKey: Keys.soundReactionEnabled)
        roomQuestEnabled = defaults.bool(forKey: Keys.roomQuestEnabled)
        roomQuestSafetyAcknowledged = defaults.bool(forKey: Keys.roomQuestSafetyAcknowledged)
        roomQuestMarkerSetupEnabled = defaults.bool(forKey: Keys.roomQuestMarkerSetupEnabled)
    }
}
