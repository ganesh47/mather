import Foundation
import Testing
@testable import Mather

@MainActor
struct TransferIntentTests {
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
    func transferPromptReferencesTheExactEquationToRebuild() async throws {
        let engine = makeEngine()
        engine.startSession()

        guard let problem = engine.currentProblem else { return }
        try await advanceToTransfer(engine, problem: problem)

        #expect(engine.feedbackMessage.contains("\(problem.decompositionA)"))
        #expect(engine.feedbackMessage.contains("\(problem.decompositionB)"))
        #expect(engine.feedbackMessage.contains("left"))
        #expect(engine.feedbackMessage.contains("right"))
    }

    @Test
    func transferEquationCopyMakesEquationAssociationExplicit() {
        let copy = TransferEquationCopy(problem: SliceProblem(target: 9, decompositionA: 4, decompositionB: 5))

        #expect(copy.recap == "Rebuild your equation: 4 + 5 = 9")
        #expect(copy.instruction == "Tap counters to make 4 on the left and 5 on the right.")
    }


    @Test
    func transferCounterTapAddsOrRemovesThroughTappedBubble() {
        #expect(TransferCounterTap(index: 0, currentCount: 0).nextCount == 1)
        #expect(TransferCounterTap(index: 3, currentCount: 1).delta == 3)
        #expect(TransferCounterTap(index: 2, currentCount: 5).nextCount == 2)
        #expect(TransferCounterTap(index: 2, currentCount: 5).delta == -3)
    }

    @Test
    func transferSideAdjustmentClampsEachSideIndependently() {
        let engine = makeEngine()
        engine.startSession()
        guard let problem = engine.currentProblem else { return }

        engine.adjustTransfer(by: problem.target + 5, side: .left)
        engine.adjustTransfer(by: -3, side: .left)
        engine.adjustTransfer(by: problem.target + 2, side: .right)

        #expect(engine.transferLeftCount == max(problem.target - 3, 0))
        #expect(engine.transferRightCount == problem.target)

        engine.adjustTransfer(by: -(problem.target + 10), side: .right)
        #expect(engine.transferRightCount == 0)
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
        flags.testModeEnabled = true
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
}
