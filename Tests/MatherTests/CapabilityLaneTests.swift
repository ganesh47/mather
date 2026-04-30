import XCTest
@testable import Mather

final class CapabilityLaneTests: XCTestCase {
    func testAllCapabilityLaneIDsHaveDisplayMetadata() throws {
        XCTAssertEqual(
            CapabilityLaneID.allCases,
            [.numbers, .geometry, .physics, .mapWorld, .discoveryCards, .chemistry, .electronics]
        )

        let registry = CapabilityLaneRegistry.explorerLab
        XCTAssertEqual(registry.descriptors.map(\.id), CapabilityLaneID.allCases)

        for laneID in CapabilityLaneID.allCases {
            let descriptor = try XCTUnwrap(registry.descriptor(for: laneID))
            XCTAssertFalse(descriptor.title.isEmpty)
            XCTAssertFalse(descriptor.shortTitle.isEmpty)
            XCTAssertFalse(descriptor.symbolName.isEmpty)
            XCTAssertFalse(descriptor.promise.isEmpty)
            XCTAssertFalse(descriptor.ageBandLabel.isEmpty)
            XCTAssertFalse(descriptor.defaultModes.isEmpty)
            XCTAssertFalse(descriptor.stages.isEmpty)
            XCTAssertFalse(descriptor.featuredConcepts.isEmpty)
        }
    }

    func testSharedModeAndStageCasesAreComplete() {
        XCTAssertEqual(PlayMode.allCases, [.learn, .explore, .challenge, .timed, .review])
        XCTAssertEqual(
            LaneStage.allCases,
            [.concrete, .pictorial, .abstract, .recall, .quiz, .transfer, .summary]
        )
    }

    func testConceptIdSupportsLaneSpecificStrings() {
        let numberBond: ConceptId = .laneSpecific(.numbers, "number-bond")
        let customElectronicsConcept = ConceptId(rawValue: "electronics.resistor-color")

        XCTAssertEqual(numberBond.rawValue, "numbers.number-bond")
        XCTAssertEqual(customElectronicsConcept.rawValue, "electronics.resistor-color")
    }

    func testFutureLanesArePresentInMetadataRegistry() throws {
        let registry = CapabilityLaneRegistry.explorerLab
        let chemistry = try XCTUnwrap(registry.descriptor(for: .chemistry))
        let electronics = try XCTUnwrap(registry.descriptor(for: .electronics))

        XCTAssertEqual(chemistry.ageBand, .future)
        XCTAssertEqual(electronics.ageBand, .future)
        XCTAssertFalse(chemistry.isAvailable)
        XCTAssertFalse(electronics.isAvailable)
    }
}
