import Testing
@testable import Mather

struct WaterCycleLabTests {
    @Test func inquiryLoopNamesWaterCycleStagesInOrder() {
        var state = WaterCycleLabState()
        #expect(state.stage == .wonder)
        #expect(state.prompt.contains("warm sun"))

        state.advance()
        #expect(state.stage == .evaporation)
        #expect(state.prompt.contains("evaporation"))

        state.advance()
        #expect(state.stage == .condensation)
        #expect(state.vaporDrops == 3)
        #expect(state.pondDrops == 2)
        #expect(state.prompt.contains("condensation"))

        state.advance()
        #expect(state.stage == .precipitation)
        #expect(state.cloudDrops == 3)
        #expect(state.vaporDrops == 0)
        #expect(state.prompt.contains("precipitation"))

        state.advance()
        #expect(state.stage == .collection)
        #expect(state.rainDrops == 3)
        #expect(state.cloudDrops == 0)

        state.advance()
        #expect(state.stage == .complete)
        #expect(state.cyclesCompleted == 1)
        #expect(state.pondDrops == 4)
        #expect(state.rainDrops == 0)
    }

    @Test func resetKeepsCompletedCycleCountForSessionScore() {
        var state = WaterCycleLabState()
        for _ in 0..<5 { state.advance() }
        #expect(state.stage == .complete)
        #expect(state.cyclesCompleted == 1)

        state.reset()
        #expect(state.stage == .wonder)
        #expect(state.cyclesCompleted == 1)
        #expect(state.vaporDrops == 0)
        #expect(state.cloudDrops == 0)
        #expect(state.rainDrops == 0)
        #expect(state.pondDrops == 4)
    }

    @Test func completeStageStartsAnotherInquiryCycle() {
        var state = WaterCycleLabState()
        for _ in 0..<5 { state.advance() }
        state.advance()

        #expect(state.stage == .wonder)
        #expect(state.cyclesCompleted == 1)
        #expect(state.progress == 0.0)
    }
}
