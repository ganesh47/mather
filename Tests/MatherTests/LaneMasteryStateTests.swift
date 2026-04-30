import Testing
@testable import Mather

struct LaneMasteryStateTests {
    @Test
    func laneStateTracksModesCardsAndConceptConfidence() {
        var state = LaneMasteryState(
            laneID: .numbers,
            availableModes: [.learn, .challenge, .timed, .review],
            conceptConfidence: ["number-bond": .introduced, "array": .introduced]
        )

        #expect(state.progressLabel == "0 / 4 modes")
        #expect(state.masteryPercentLabel == "13% ready")
        #expect(state.nextRecommendedMode == .learn)

        state.markCompleted(.learn)
        state.markReviewedCard(id: "numbers-number-bond-five-and-five")
        state.setConfidence(.mastered, for: "number-bond")

        #expect(state.completedModeCount == 1)
        #expect(state.reviewedCardIDs == ["numbers-number-bond-five-and-five"])
        #expect(state.conceptConfidence["number-bond"] == .mastered)
        #expect(state.nextRecommendedMode == .challenge)
        #expect(state.masteryPercentLabel == "44% ready")
    }

    @Test
    func unsupportedModeDoesNotAffectProgress() {
        var state = LaneMasteryState(laneID: .physics, availableModes: [.explore, .challenge])

        state.markCompleted(.timed)

        #expect(state.completedModes.isEmpty)
        #expect(state.progressLabel == "0 / 2 modes")
    }

    @Test
    func emptyExplorerProfileSeedsEveryCapabilityLane() throws {
        let profile = ExplorerLabMasteryProfile.emptyExplorerProfile()

        #expect(profile.lanes.keys.count == CapabilityLaneID.allCases.count)
        let numbers = try #require(profile[.numbers])
        #expect(numbers.availableModes == [.learn, .challenge, .timed, .review])
        #expect(numbers.conceptConfidence["number-bond"] == .introduced)
    }
}
