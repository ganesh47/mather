import Foundation
import Testing
@testable import Mather

@MainActor
struct TransferIntentTests {
    private func waitFor(_ description: String, timeoutNanoseconds: UInt64 = 2_000_000_000, condition: @escaping @MainActor () -> Bool) async {
        let deadline = DispatchTime.now().uptimeNanoseconds + timeoutNanoseconds
        while DispatchTime.now().uptimeNanoseconds < deadline {
            if condition() { return }
            await Task.yield()
            try? await Task.sleep(nanoseconds: 20_000_000)
        }
        Issue.record("Timed out waiting for \(description)")
    }

    @Test
    func transferPromptReferencesShowingTheSameEquationAgain() async throws {
        let engine = makeEngine()
        engine.startSession()

        guard let problem = engine.currentProblem else { return }
        try await advanceToTransfer(engine, problem: problem)

        #expect(engine.feedbackMessage.localizedCaseInsensitiveContains("same two"))
        #expect(!engine.feedbackMessage.contains("\(problem.decompositionA)"))
        #expect(!engine.feedbackMessage.contains("\(problem.decompositionB)"))
        #expect(engine.feedbackMessage.localizedCaseInsensitiveContains("counters"))
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
