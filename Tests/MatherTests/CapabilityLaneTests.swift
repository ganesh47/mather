import Testing
@testable import Mather

struct CapabilityLaneTests {
    @Test
    func registryContainsEveryExplorerLaneInDisplayOrder() {
        #expect(CapabilityLaneRegistry.all.map(\.id) == [
            .numbers,
            .geometry,
            .physics,
            .mapWorld,
            .discoveryCards,
            .chemistry,
            .electronics,
        ])
    }

    @Test
    func everyLaneHasCompleteDisplayMetadata() {
        #expect(CapabilityLaneRegistry.all.count == CapabilityLaneID.allCases.count)

        for descriptor in CapabilityLaneRegistry.all {
            #expect(!descriptor.title.isEmpty)
            #expect(!descriptor.emoji.isEmpty)
            #expect(!descriptor.promise.isEmpty)
            #expect(!descriptor.ageBandHint.isEmpty)
            #expect(!descriptor.stages.isEmpty)
            #expect(!descriptor.supportedPlayModes.isEmpty)
            #expect(!descriptor.starterConcepts.isEmpty)
        }
    }

    @Test
    func registryCoversAllPlayModes() {
        let supportedModes = Set(CapabilityLaneRegistry.all.flatMap(\.supportedPlayModes))

        #expect(supportedModes == Set(PlayMode.allCases))
    }

    @Test
    func laneIdentifiersExposeExpectedTitles() {
        #expect(CapabilityLaneID.numbers.title == "Numbers Lab")
        #expect(CapabilityLaneID.geometry.title == "Geometry Lab")
        #expect(CapabilityLaneID.physics.title == "Physics Lab")
        #expect(CapabilityLaneID.mapWorld.title == "Geography Lab")
        #expect(CapabilityLaneID.discoveryCards.title == "Discovery Cards")
        #expect(CapabilityLaneID.chemistry.title == "Chemistry Lab")
        #expect(CapabilityLaneID.electronics.title == "Electronics Lab")
    }
}

