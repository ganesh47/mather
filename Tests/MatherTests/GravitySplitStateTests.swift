import Testing
@testable import Mather

struct GravitySplitStateTests {
    @Test func lowTargetsUseIndividualTokens() {
        let problem = SliceProblem(target: 20, decompositionA: 9, decompositionB: 11)
        let state = GravitySplitState(problem: problem)

        #expect(!state.usesGroupedRepresentation)
        #expect(state.groupedStepValues == [1])
    }

    @Test func highTargetsUseGroupedPlaceValueSteps() {
        let problem = SliceProblem(target: 123, decompositionA: 61, decompositionB: 62)
        let state = GravitySplitState(problem: problem)

        #expect(state.usesGroupedRepresentation)
        #expect(state.groupedStepValues == [100, 10, 1])
    }

    @Test func groupedCapacityTracksEachDestinationSide() {
        let problem = SliceProblem(target: 123, decompositionA: 61, decompositionB: 62)
        var state = GravitySplitState(problem: problem)
        state.adjustLeft(by: 50)
        state.adjustRight(by: 12)

        #expect(state.currentCount(for: .left) == 50)
        #expect(state.currentCount(for: .right) == 12)
        #expect(state.remainingCapacity(for: .left) == 11)
        #expect(state.remainingCapacity(for: .right) == 50)
    }
}
