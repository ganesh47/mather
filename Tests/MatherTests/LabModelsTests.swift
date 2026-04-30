import XCTest
@testable import Mather

final class LabModelsTests: XCTestCase {
    func testDefaultExplorerLanesExposeCapabilityShell() throws {
        let lanes = CapabilityLane.defaultExplorerLanes
        let laneIDs = lanes.map(\.id)

        XCTAssertEqual(
            laneIDs,
            [.numbers, .geometry, .physics, .mapWorld, .discoveryCards, .chemistry, .electronics]
        )

        for required in [CapabilityLaneID.numbers, .geometry, .physics, .mapWorld] {
            let lane = try XCTUnwrap(lanes.first { $0.id == required })
            XCTAssertFalse(lane.activities.isEmpty, "\(lane.title) should launch at least one pilot activity")
        }
    }

    func testMemoryMatchIsEmbeddedInDiscoveryCardsInsteadOfTopLevelLane() throws {
        let lanes = CapabilityLane.defaultExplorerLanes
        let discovery = try XCTUnwrap(lanes.first { $0.id == .discoveryCards })

        XCTAssertTrue(discovery.activities.contains { $0.id == .memoryMatch })
        XCTAssertFalse(CapabilityLaneID.allCases.contains { $0.title == "Memory Match" })
    }


    func testCapabilityLanesExposeAgeBandEntryPoints() throws {
        for lane in CapabilityLane.defaultExplorerLanes {
            XCTAssertGreaterThanOrEqual(lane.ageEntries.count, 4, "\(lane.title) should define multiple age entry points")
            XCTAssertFalse(lane.ageEntryPreview.isEmpty)
        }

        let physics = try XCTUnwrap(CapabilityLane.defaultExplorerLanes.first { $0.id == .physics })
        XCTAssertTrue(physics.ageEntries.contains { $0.ageBand == .toddler })
        XCTAssertTrue(physics.ageEntryPreview.contains("Ages 2–3"))
    }

    func testCapabilityLanesExposeChildChoiceModeCards() throws {
        let numbers = try XCTUnwrap(CapabilityLane.defaultExplorerLanes.first { $0.id == .numbers })

        XCTAssertEqual(numbers.modeChoiceCards.map(\.mode), numbers.modes)
        XCTAssertTrue(numbers.modeChoicePreviewLabel.contains("Learn: calm build"))
        XCTAssertTrue(numbers.modeChoiceCards.contains { $0.mode == .timed && $0.policy.usesTimer })
    }

    func testCapabilityLanesIncludeChoiceBasedPlayModes() {
        let modesByLane = Dictionary(
            uniqueKeysWithValues: CapabilityLane.defaultExplorerLanes.map { ($0.id, Set($0.modes)) }
        )

        XCTAssertTrue(modesByLane[.numbers, default: []].contains(.timed))
        XCTAssertTrue(modesByLane[.geometry, default: []].contains(.explore))
        XCTAssertTrue(modesByLane[.physics, default: []].contains(.review))
        XCTAssertTrue(modesByLane[.mapWorld, default: []].contains(.challenge))
        XCTAssertTrue(modesByLane[.discoveryCards, default: []].contains(.review))
    }

    func testLaneRecallReadinessSummariesExposeCardCountsAndConcepts() throws {
        let numbers = try XCTUnwrap(CapabilityLane.defaultExplorerLanes.first { $0.id == .numbers })

        XCTAssertEqual(numbers.starterMixMatchCount, 8)
        XCTAssertEqual(numbers.recallReadinessLabel, "1 recall card + 8 Mix-Match ready")
        XCTAssertEqual(numbers.recallEntries.count, 1)
        XCTAssertTrue(numbers.starterMixMatchConceptPreview.contains("number-bond"))
    }

}

extension LabModelsTests {
    func testEveryCapabilityLaneDefinesAtLeastEightStarterMixMatchCards() throws {
        for lane in CapabilityLane.defaultExplorerLanes {
            XCTAssertGreaterThanOrEqual(
                lane.starterMixMatchCards.count,
                8,
                "\(lane.title) should have at least eight starter Mix-Match cards"
            )
            XCTAssertTrue(lane.starterMixMatchCards.allSatisfy { $0.laneID == lane.id })
        }
    }


    func testStarterMixMatchSamplerCyclesThroughCards() throws {
        let geometry = try XCTUnwrap(CapabilityLane.defaultExplorerLanes.first { $0.id == .geometry })
        var sampler = geometry.starterMixMatchSampler

        XCTAssertEqual(sampler.progressLabel, "1 / 8")
        XCTAssertEqual(sampler.currentCard?.prompt, "3 sides")

        sampler.advance()
        XCTAssertEqual(sampler.progressLabel, "2 / 8")
        XCTAssertEqual(sampler.currentCard?.prompt, "4 equal sides")

        sampler.rewind()
        XCTAssertEqual(sampler.progressLabel, "1 / 8")
    }


    func testCapabilityLaneProgressTracksModesAndRecommendation() throws {
        let numbers = try XCTUnwrap(CapabilityLane.defaultExplorerLanes.first { $0.id == .numbers })
        var progress = numbers.emptyProgress

        XCTAssertEqual(progress.progressLabel, "0 / 4 modes")
        XCTAssertEqual(progress.masteryPercentLabel, "0% ready")
        XCTAssertEqual(progress.progressSummaryLabel, "0 / 4 modes • 0% ready")
        XCTAssertEqual(progress.nextRecommendedMode, .learn)
        XCTAssertEqual(progress.nextRecommendedModeLabel, "Try Learn next")

        progress.markCompleted(.learn)
        progress.markCompleted(.timed)

        XCTAssertEqual(progress.progressLabel, "2 / 4 modes")
        XCTAssertEqual(progress.masteryPercentLabel, "50% ready")
        XCTAssertEqual(progress.progressSummaryLabel, "2 / 4 modes • 50% ready")
        XCTAssertEqual(progress.nextRecommendedMode, .challenge)
        XCTAssertEqual(progress.nextRecommendedModeLabel, "Try Challenge next")
    }

    func testCapabilityLaneProgressTracksReviewedCardsOnlyForItsLane() throws {
        let numbers = try XCTUnwrap(CapabilityLane.defaultExplorerLanes.first { $0.id == .numbers })
        let geometry = try XCTUnwrap(CapabilityLane.defaultExplorerLanes.first { $0.id == .geometry })
        var progress = numbers.emptyProgress

        progress.markReviewed(try XCTUnwrap(numbers.starterMixMatchCards.first))
        progress.markReviewed(try XCTUnwrap(geometry.starterMixMatchCards.first))

        XCTAssertEqual(progress.reviewedCardIDs.count, 1)
    }

    func testCapabilityLaneProgressCanRenderPersistedMasteryState() {
        var masteryState = LaneMasteryState(
            laneID: .numbers,
            availableModes: [.learn, .challenge, .timed, .review]
        )
        masteryState.markCompleted(.learn)
        masteryState.markCompleted(.timed)
        masteryState.markReviewedCard(id: "numbers-number-bond-five-and-five")

        let progress = CapabilityLaneProgress(masteryState: masteryState)

        XCTAssertEqual(progress.progressSummaryLabel, "2 / 4 modes • 50% ready")
        XCTAssertEqual(progress.nextRecommendedModeLabel, "Try Challenge next")
        XCTAssertEqual(progress.reviewedCardIDs, ["numbers-number-bond-five-and-five"])
    }

    func testStarterMixMatchCardsHaveChildReadablePromptsAndMatches() {
        let allCards = CapabilityLane.defaultExplorerLanes.flatMap(\.starterMixMatchCards)

        XCTAssertFalse(allCards.isEmpty)
        XCTAssertTrue(allCards.allSatisfy { !$0.concept.isEmpty })
        XCTAssertTrue(allCards.allSatisfy { !$0.prompt.isEmpty })
        XCTAssertTrue(allCards.allSatisfy { !$0.match.isEmpty })
        XCTAssertEqual(Set(allCards.map(\.id)).count, allCards.count)
    }

    func testActivitySensorNeedsMapToHonestLaneAffordances() {
        XCTAssertEqual(LabActivityID.sumSprint.sensorNeeds, [.noSpecialSensor])
        XCTAssertEqual(LabActivityID.angleCannon.sensorNeeds, [.motion])
        XCTAssertEqual(LabActivityID.gravityArtist.sensorNeeds, [.motion])
        XCTAssertEqual(LabActivityID.compassAngles.sensorNeeds, [.compass])
        XCTAssertEqual(LabActivityID.roomQuest.sensorNeeds, [.cameraMarkerMode, .haptics])
        XCTAssertEqual(LabActivityID.memoryMatch.sensorNeeds, [.noSpecialSensor])
    }

    func testUnavailableSensorAffordancesExposeVisibleFallbackCopy() {
        let affordances = LabActivityID.roomQuest.sensorAffordances(with: .unavailable)

        XCTAssertEqual(
            affordances.map(\.displayLabel),
            [
                "Camera marker mode unavailable: Use tap-to-place stations",
                "Haptics unavailable: Visual feedback stays available",
            ]
        )
        XCTAssertTrue(affordances.allSatisfy { !$0.isAvailable })
    }

    func testAvailableCapabilitiesUseReadyCopyWithoutFallbacks() {
        let capabilities = DeviceSensorCapabilities(
            supportsMotion: true,
            supportsHeading: true,
            supportsCamera: true,
            supportsMicrophone: false,
            supportsHaptics: true,
            supportsBarometer: false,
            supportsLiDAR: false,
            supportsApplePencil: false
        )

        XCTAssertEqual(
            LabActivityID.angleCannon.sensorAffordances(with: capabilities).map(\.displayLabel),
            ["Motion ready"]
        )
        XCTAssertEqual(
            LabActivityID.compassAngles.sensorAffordances(with: capabilities).map(\.displayLabel),
            ["Compass ready"]
        )
        XCTAssertEqual(
            LabActivityID.roomQuest.sensorAffordances(with: capabilities).map(\.displayLabel),
            ["Camera marker mode ready", "Haptics ready"]
        )
        XCTAssertEqual(
            LabActivityID.twoFingerProtractor.sensorAffordances(with: capabilities).map(\.displayLabel),
            ["No special sensor needed"]
        )
    }
}
