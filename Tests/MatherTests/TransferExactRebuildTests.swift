import Foundation
import Testing
@testable import Mather

@MainActor
struct TransferExactRebuildTests {
    @Test
    func transferRequiresExactDisplayedDecomposition() async throws {
        let engine = makeEngine()

        engine.startSession()
        guard let problem = engine.currentProblem else { return }

        try await advanceToTransfer(engine, problem: problem)

        engine.adjustTransfer(by: problem.decompositionA, side: .left)
        engine.adjustTransfer(by: problem.decompositionB, side: .right)
        engine.submitCurrentStage()
        try await Task.sleep(for: .milliseconds(200))

        #expect(engine.currentStage != .transfer)
        #expect(engine.feedbackMessage.contains("new direction"))
    }

    @Test
    func transferRejectsCorrectTotalWithWrongSplit() async throws {
        let engine = makeEngine()

        engine.startSession()
        guard let problem = engine.currentProblem else { return }

        try await advanceToTransfer(engine, problem: problem)

        let wrongLeft = min(problem.target, problem.decompositionA + 1)
        let wrongRight = problem.target - wrongLeft
        #expect(wrongLeft + wrongRight == problem.target)
        #expect(wrongLeft != problem.decompositionA || wrongRight != problem.decompositionB)

        engine.adjustTransfer(by: wrongLeft, side: .left)
        engine.adjustTransfer(by: wrongRight, side: .right)
        engine.submitCurrentStage()

        #expect(engine.currentStage == .transfer)
        #expect(engine.feedbackMessage.contains("left") || engine.feedbackMessage.contains("right"))
    }

    @Test
    func transferRejectsSwappedDecomposition() async throws {
        let engine = makeEngine()

        engine.startSession()
        guard let problem = engine.currentProblem else { return }
        #expect(problem.decompositionA != problem.decompositionB)

        try await advanceToTransfer(engine, problem: problem)

        engine.adjustTransfer(by: problem.decompositionB, side: .left)
        engine.adjustTransfer(by: problem.decompositionA, side: .right)
        engine.submitCurrentStage()

        #expect(engine.currentStage == .transfer)
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
