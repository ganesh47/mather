import Foundation
import Testing
@testable import Mather

@MainActor
struct TransferExactRebuildTests {
    private func waitFor(_ description: String, timeoutNanoseconds: UInt64 = 2_000_000_000, condition: @escaping @MainActor () -> Bool) async {
        let deadline = DispatchTime.now().uptimeNanoseconds + timeoutNanoseconds
        while DispatchTime.now().uptimeNanoseconds < deadline {
            if await MainActor.run(body: condition) { return }
            await Task.yield()
            try? await Task.sleep(nanoseconds: 20_000_000)
        }
        Issue.record("Timed out waiting for \(description)")
    }

    @Test
    func transferRequiresExactDisplayedDecomposition() async throws {
        let engine = makeEngine()

        engine.startSession()
        guard let problem = engine.currentProblem else { return }

        try await advanceToTransfer(engine, problem: problem)

        engine.adjustTransfer(by: problem.decompositionA, side: .left)
        engine.adjustTransfer(by: problem.decompositionB, side: .right)
        engine.submitCurrentStage()
        await waitFor("advance past transfer after exact rebuild") { engine.currentStage != .transfer }

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
        flags.testModeEnabled = true
        flags.audioEnabled = false
        flags.hapticsEnabled = false
        flags.makeBreakLoopV2Enabled = false
        flags.vs1GravitySplitEnabled = false
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
        await waitFor("pictorial stage after concrete") { engine.currentStage == .pictorial }
        await waitFor("bond match state in pictorial") { engine.bondMatchState != nil }

        for pair in engine.bondMatchState?.pairs ?? [] {
            engine.matchPair(id: pair.id)
        }
        await waitFor("abstract stage after Bond Blast") { engine.currentStage == .abstract }

        engine.equationLeftInput = String(problem.decompositionA)
        engine.equationRightInput = String(problem.decompositionB)
        engine.submitCurrentStage()
        await waitFor("transfer stage after abstract") { engine.currentStage == .transfer }

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
        await waitFor("pictorial stage after concrete") { engine.currentStage == .pictorial }
        await waitFor("bond match state in pictorial") { engine.bondMatchState != nil }
        for pair in engine.bondMatchState?.pairs ?? [] {
            engine.matchPair(id: pair.id)
        }
        await waitFor("abstract stage after Bond Blast") { engine.currentStage == .abstract }
        engine.equationLeftInput = String(currentProblem.decompositionA)
        engine.equationRightInput = String(currentProblem.decompositionB)
        engine.submitCurrentStage()
        await waitFor("transfer stage after abstract") { engine.currentStage == .transfer }
        engine.adjustTransfer(by: currentProblem.decompositionA, side: .left)
        engine.adjustTransfer(by: currentProblem.decompositionB, side: .right)
        engine.submitCurrentStage()
        await waitFor("next problem after transfer") { engine.currentProblem?.id != currentProblem.id }

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
