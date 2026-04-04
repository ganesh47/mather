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
        ])
        verticalSlice1Enabled = defaults.bool(forKey: Keys.verticalSlice1Enabled)
        testModeEnabled = defaults.bool(forKey: Keys.testModeEnabled)
        audioEnabled = defaults.bool(forKey: Keys.audioEnabled)
        hapticsEnabled = defaults.bool(forKey: Keys.hapticsEnabled)
        selectedThemeId = defaults.string(forKey: Keys.selectedThemeId) ?? "classic"
    }
}
