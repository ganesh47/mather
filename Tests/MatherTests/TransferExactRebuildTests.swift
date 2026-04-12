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
        #expect(engine.currentSession.problems.last?.transferCorrect == true)
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
        #expect(engine.currentProblemState.isCorrect == false)
    }

    @Test
    func transferRejectsSwappedDecomposition() async throws {
        let engine = makeEngine()

        engine.startSession()
        let problem = try await firstNonSymmetricProblem(in: engine)

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

        for pair in engine.bondMatchState?.pairs ?? [] {
            engine.matchPair(id: pair.id)
        }
        try await Task.sleep(for: .milliseconds(200))

        engine.equationLeftInput = String(problem.decompositionA)
        engine.equationRightInput = String(problem.decompositionB)
        engine.submitCurrentStage()
        try await Task.sleep(for: .milliseconds(200))

        #expect(engine.currentStage == .transfer)
    }

    private func firstNonSymmetricProblem(in engine: VerticalSliceEngine) async throws -> SliceProblem {
        if let currentProblem = engine.currentProblem, currentProblem.decompositionA != currentProblem.decompositionB {
            return currentProblem
        }

        guard let currentProblem = engine.currentProblem else {
            Issue.record("No current problem to advance from.")
            return SliceProblem(target: 0, decompositionA: 0, decompositionB: 0)
        }

        engine.adjustConcrete(by: currentProblem.target)
        engine.submitCurrentStage()
        try await Task.sleep(for: .milliseconds(200))
        for pair in engine.bondMatchState?.pairs ?? [] {
            engine.matchPair(id: pair.id)
        }
        try await Task.sleep(for: .milliseconds(200))
        engine.equationLeftInput = String(currentProblem.decompositionA)
        engine.equationRightInput = String(currentProblem.decompositionB)
        engine.submitCurrentStage()
        try await Task.sleep(for: .milliseconds(200))
        engine.adjustTransfer(by: currentProblem.decompositionA, side: .left)
        engine.adjustTransfer(by: currentProblem.decompositionB, side: .right)
        engine.submitCurrentStage()
        try await Task.sleep(for: .milliseconds(200))

        guard let nextProblem = engine.currentProblem else {
            Issue.record("Failed to advance to a non-symmetric problem.")
            return currentProblem
        }
        guard nextProblem.decompositionA != nextProblem.decompositionB else {
            Issue.record("Expected a non-symmetric follow-up problem.")
            return currentProblem
        }
        return nextProblem
    }
}
