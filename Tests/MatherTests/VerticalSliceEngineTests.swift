import Foundation
import Testing
@testable import Mather

@MainActor
struct VerticalSliceEngineTests {
    @Test
    func sessionAlwaysIncludesTransferStage() {
        let flags = FeatureFlagService(defaults: UserDefaults(suiteName: #function)!)
        flags.verticalSlice1Enabled = true
        flags.testModeEnabled = true

        let engine = VerticalSliceEngine(
            featureFlags: flags,
            telemetryWriter: TelemetryWriter(),
            speechService: SpeechService(),
            saveSummary: { _ in }
        )

        engine.startSession()
        #expect(engine.currentStage == .concrete)

        engine.adjustConcrete(by: engine.currentProblem?.target ?? 0)
        engine.submitCurrentStage()
        #expect(engine.currentStage == .pictorial)

        engine.submitCurrentStage()
        #expect(engine.currentStage == .abstract)
    }
}
