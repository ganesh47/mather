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
}
