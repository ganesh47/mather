import Foundation
import Observation

@Observable
final class FeatureFlagService {
    private enum Keys {
        static let verticalSlice1Enabled = "feature.verticalSlice1Enabled"
        static let testModeEnabled = "feature.testModeEnabled"
        static let audioEnabled = "feature.audioEnabled"
        static let hapticsEnabled = "feature.hapticsEnabled"
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

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        verticalSlice1Enabled = defaults.object(forKey: Keys.verticalSlice1Enabled) as? Bool ?? false
        testModeEnabled = defaults.object(forKey: Keys.testModeEnabled) as? Bool ?? true
        audioEnabled = defaults.object(forKey: Keys.audioEnabled) as? Bool ?? true
        hapticsEnabled = defaults.object(forKey: Keys.hapticsEnabled) as? Bool ?? true
    }
}
