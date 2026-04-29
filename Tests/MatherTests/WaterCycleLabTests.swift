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

    @Test func sceneMetricsFitCompactPhoneWidth() {
        let metrics = WaterCycleSceneMetrics(availableWidth: 288)

        #expect(abs(metrics.scale - 0.72) < 0.001)
        #expect(metrics.sunHaloSize < 100)
        #expect(metrics.cloudCapsuleWidth < 124)
        #expect(metrics.columnWidth <= 116)
        #expect(metrics.horizontalInset >= 21)

        let topRowMinimum = metrics.sunHaloSize + metrics.cloudCapsuleWidth + metrics.horizontalInset * 2
        #expect(topRowMinimum < metrics.availableWidth)

        let middleRowMinimum = metrics.columnWidth * 2 + metrics.horizontalInset * 2
        #expect(middleRowMinimum < metrics.availableWidth)
    }
}
