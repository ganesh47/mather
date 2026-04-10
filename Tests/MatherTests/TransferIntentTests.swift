import Foundation
import Testing
@testable import Mather

@MainActor
struct TransferIntentTests {
    @Test
    func transferPromptReferencesShowingTheSameEquationAgain() async throws {
        let engine = makeEngine()
        engine.startSession()

        guard let problem = engine.currentProblem else { return }
        try await advanceToTransfer(engine, problem: problem)

        #expect(engine.feedbackMessage.contains("same equation"))
        #expect(!engine.feedbackMessage.contains("\(problem.decompositionA)"))
        #expect(!engine.feedbackMessage.contains("\(problem.decompositionB)"))
        #expect(engine.feedbackMessage.localizedCaseInsensitiveContains("memory"))
    }

    @Test
    func transferSuccessMessageReferencesMatchingTheSameEquation() async throws {
        let engine = makeEngine()
        engine.startSession()

        guard let problem = engine.currentProblem else { return }
        try await advanceToTransfer(engine, problem: problem)

        engine.adjustTransfer(by: problem.decompositionA, side: .left)
        engine.adjustTransfer(by: problem.decompositionB, side: .right)
        engine.submitCurrentStage()

        #expect(engine.feedbackMessage.contains("same equation"))
    }

    private func makeEngine() -> VerticalSliceEngine {
        let flags = FeatureFlagService(defaults: UserDefaults(suiteName: #function)!)
        flags.verticalSlice1Enabled = true
        flags.testModeEnabled = true
        return VerticalSliceEngine(
            featureFlags: flags,
            telemetryWriter: TelemetryWriter(),
            speechService: SpeechService(),
            celebrationDuration: 0,
            saveSummary: { _ in }
        )
    }

    private func advanceToTransfer(_ engine: VerticalSliceEngine, problem: SliceProblem) async throws {
        engine.adjustConcrete(by: problem.target)
        engine.submitCurrentStage()
        try await Task.sleep(for: .milliseconds(200))

        engine.submitCurrentStage()
        try await Task.sleep(for: .milliseconds(200))

        engine.equationLeftInput = String(problem.decompositionA)
        engine.equationRightInput = String(problem.decompositionB)
        engine.submitCurrentStage()
        try await Task.sleep(for: .milliseconds(200))

        #expect(engine.currentStage == .transfer)
    }
}
