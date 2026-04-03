import Foundation
import Testing
@testable import Mather

@MainActor
struct VerticalSliceEngineTests {
    @Test
    func sessionAlwaysIncludesTransferStage() async throws {
        let flags = FeatureFlagService(defaults: UserDefaults(suiteName: #function)!)
        flags.verticalSlice1Enabled = true
        flags.testModeEnabled = true

        let engine = VerticalSliceEngine(
            featureFlags: flags,
            telemetryWriter: TelemetryWriter(),
            speechService: SpeechService(),
            celebrationDuration: 0,
            saveSummary: { _ in }
        )

        engine.startSession()
        #expect(engine.currentStage == .concrete)

        engine.adjustConcrete(by: engine.currentProblem?.target ?? 0)
        engine.submitCurrentStage()
        try await Task.sleep(for: .milliseconds(10))
        #expect(engine.currentStage == .pictorial)

        engine.submitCurrentStage()
        try await Task.sleep(for: .milliseconds(10))
        #expect(engine.currentStage == .abstract)
    }

    @Test
    func hapticsStageSuccessFiredOnConcreteStageClear() {
        let flags = FeatureFlagService(defaults: UserDefaults(suiteName: #function)!)
        flags.testModeEnabled = true
        flags.hapticsEnabled = true
        let haptics = HapticsService()

        let engine = VerticalSliceEngine(
            featureFlags: flags,
            telemetryWriter: TelemetryWriter(),
            speechService: SpeechService(),
            hapticsService: haptics,
            saveSummary: { _ in }
        )

        engine.startSession()
        engine.adjustConcrete(by: engine.currentProblem?.target ?? 0)
        engine.submitCurrentStage()

        // Completing an individual stage (not a full problem) fires stageSuccess, not success
        #expect(haptics.stageSuccessFiredCount == 1)
        #expect(haptics.successFiredCount == 0)
        #expect(haptics.failureFiredCount == 0)
    }

    @Test
    func hapticsSuccessFiredOnProblemComplete() async throws {
        let flags = FeatureFlagService(defaults: UserDefaults(suiteName: #function)!)
        flags.testModeEnabled = true
        flags.hapticsEnabled = true
        let haptics = HapticsService()

        let engine = VerticalSliceEngine(
            featureFlags: flags,
            telemetryWriter: TelemetryWriter(),
            speechService: SpeechService(),
            hapticsService: haptics,
            celebrationDuration: 0,
            saveSummary: { _ in }
        )

        engine.startSession()
        guard let problem = engine.currentProblem else { return }

        // Complete all four CPA stages for one problem — await after each so the
        // stage-advance Task (which runs after celebrationDuration: 0) can fire.
        engine.adjustConcrete(by: problem.target)
        engine.submitCurrentStage()    // concrete → pictorial (stageSuccess)
        try await Task.sleep(for: .milliseconds(10))
        engine.submitCurrentStage()    // pictorial → abstract (stageSuccess)
        try await Task.sleep(for: .milliseconds(10))
        engine.equationLeftInput = String(problem.decompositionA)
        engine.equationRightInput = String(problem.decompositionB)
        engine.submitCurrentStage()    // abstract → transfer (stageSuccess)
        try await Task.sleep(for: .milliseconds(10))
        engine.adjustTransfer(by: problem.target)
        engine.submitCurrentStage()    // transfer → done (success — problem complete)
        try await Task.sleep(for: .milliseconds(10))

        #expect(haptics.successFiredCount == 1)
        #expect(haptics.stageSuccessFiredCount == 3)
        #expect(haptics.failureFiredCount == 0)
    }

    @Test
    func hapticsStageSuccessNotFiredWhenDisabled() {
        let flags = FeatureFlagService(defaults: UserDefaults(suiteName: #function)!)
        flags.testModeEnabled = true
        flags.hapticsEnabled = false
        let haptics = HapticsService()

        let engine = VerticalSliceEngine(
            featureFlags: flags,
            telemetryWriter: TelemetryWriter(),
            speechService: SpeechService(),
            hapticsService: haptics,
            saveSummary: { _ in }
        )

        engine.startSession()
        engine.adjustConcrete(by: engine.currentProblem?.target ?? 0)
        engine.submitCurrentStage()

        #expect(haptics.stageSuccessFiredCount == 0)
        #expect(haptics.successFiredCount == 0)
    }

    @Test
    func hapticsFailureFiredOnWrongAnswer() {
        let flags = FeatureFlagService(defaults: UserDefaults(suiteName: #function)!)
        flags.testModeEnabled = true
        flags.hapticsEnabled = true
        let haptics = HapticsService()

        let engine = VerticalSliceEngine(
            featureFlags: flags,
            telemetryWriter: TelemetryWriter(),
            speechService: SpeechService(),
            hapticsService: haptics,
            saveSummary: { _ in }
        )

        engine.startSession()
        // Leave count at 0 — wrong answer for any target > 0
        engine.submitCurrentStage()

        #expect(haptics.failureFiredCount == 1)
        #expect(haptics.successFiredCount == 0)
    }

    @Test
    func equationAcceptsAlternativeCorrectDecomposition() async throws {
        let flags = FeatureFlagService(defaults: UserDefaults(suiteName: #function)!)
        flags.testModeEnabled = true
        flags.hapticsEnabled = false
        let haptics = HapticsService()

        let engine = VerticalSliceEngine(
            featureFlags: flags,
            telemetryWriter: TelemetryWriter(),
            speechService: SpeechService(),
            hapticsService: haptics,
            celebrationDuration: 0,
            saveSummary: { _ in }
        )

        engine.startSession()
        guard let problem = engine.currentProblem else { return }

        // Advance to abstract stage — await after each submit so the stage-advance Task fires.
        engine.adjustConcrete(by: problem.target)
        engine.submitCurrentStage() // → pictorial
        try await Task.sleep(for: .milliseconds(10))
        engine.submitCurrentStage() // → abstract
        try await Task.sleep(for: .milliseconds(10))

        #expect(engine.currentStage == .abstract)

        // Enter a valid decomposition different from the stored split
        // e.g. if decompositionA=1, decompositionB=5 for target=6, try 3+3
        let altLeft = problem.target / 2
        let altRight = problem.target - altLeft
        engine.equationLeftInput = String(altLeft)
        engine.equationRightInput = String(altRight)
        engine.submitCurrentStage()

        // Should advance past abstract regardless of which valid decomposition was entered
        #expect(engine.currentStage != .abstract)
        #expect(haptics.failureFiredCount == 0)
    }

    @Test
    func hapticsFailureNotFiredWhenDisabled() {
        let flags = FeatureFlagService(defaults: UserDefaults(suiteName: #function)!)
        flags.testModeEnabled = true
        flags.hapticsEnabled = false
        let haptics = HapticsService()

        let engine = VerticalSliceEngine(
            featureFlags: flags,
            telemetryWriter: TelemetryWriter(),
            speechService: SpeechService(),
            hapticsService: haptics,
            saveSummary: { _ in }
        )

        engine.startSession()
        engine.submitCurrentStage()

        #expect(haptics.failureFiredCount == 0)
    }
}
