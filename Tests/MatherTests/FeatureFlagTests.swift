import Foundation
import Testing
@testable import Mather

struct FeatureFlagTests {

    @Test func selectedThemeIdDefaultsToClassic() {
        let flags = FeatureFlagService(defaults: UserDefaults(suiteName: #function)!)
        #expect(flags.selectedThemeId == "classic")
    }

    @Test func selectedThemeIdPersistsAcrossInstances() {
        let defaults = UserDefaults(suiteName: #function)!
        let flags1 = FeatureFlagService(defaults: defaults)
        flags1.selectedThemeId = "vehicle"

        let flags2 = FeatureFlagService(defaults: defaults)
        #expect(flags2.selectedThemeId == "vehicle")
    }

    @Test func selectedThemeIdCanBeResetToClassic() {
        let defaults = UserDefaults(suiteName: #function)!
        let flags = FeatureFlagService(defaults: defaults)
        flags.selectedThemeId = "vehicle"
        flags.selectedThemeId = "classic"
        #expect(flags.selectedThemeId == "classic")
    }

    @Test func otherFlagsUnaffectedByThemeIdChange() {
        let flags = FeatureFlagService(defaults: UserDefaults(suiteName: #function)!)
        flags.selectedThemeId = "vehicle"
        // Defaults should still be what FeatureFlagService registers
        #expect(flags.testModeEnabled == true)
        #expect(flags.audioEnabled == true)
        #expect(flags.hapticsEnabled == true)
    }

    @Test func makeBreakLoopV2DefaultsFalse() {
        let flags = FeatureFlagService(defaults: UserDefaults(suiteName: #function)!)
        #expect(flags.makeBreakLoopV2Enabled == false)
    }

    @Test func makeBreakLoopV2PersistsAcrossInstances() {
        let defaults = UserDefaults(suiteName: #function)!
        let flags1 = FeatureFlagService(defaults: defaults)
        flags1.makeBreakLoopV2Enabled = true

        let flags2 = FeatureFlagService(defaults: defaults)
        #expect(flags2.makeBreakLoopV2Enabled)
    }
}
