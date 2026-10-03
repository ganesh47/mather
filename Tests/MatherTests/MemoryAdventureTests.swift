import Testing
@testable import Mather

@Suite("Memory adventures")
struct MemoryAdventureTests {
    @Test func curatedCardsResolveToDistinctBundledPictures() {
        for adventure in MemoryAdventure.allCases {
            #expect(adventure.cards.map(\.id) == adventure.cardIDs)
            #expect(Set(adventure.cardIDs).count == adventure.cardIDs.count)
            #expect(adventure.cards.allSatisfy { $0.imageAssetName != nil })
            #expect(adventure.cards.allSatisfy { $0.metadata.deck == adventure.deckKind })
            #expect(!adventure.introduction.isEmpty)
            #expect(!adventure.celebration.isEmpty)
            #expect(!adventure.tryIt.isEmpty)
        }
        #expect(MemoryAdventure.busyBuilders.cards.count == 6)
        #expect(MemoryAdventure.rescueCrew.cards.count == 5)
        #expect(MemoryAdventure.spaceTrip.cards.count == 8)
    }

    @Test func adventureUsesFrozenCatalogCardsRatherThanReplacingTheirFacts() throws {
        let source = try #require(MemoryAdventure.busyBuilders.cards.first)
        let corrected = MemoryAnimal(id: source.id, name: source.name,
            canonicalName: source.canonicalName, picture: .text("Reviewed catalog picture"),
            metadata: source.metadata, learningArtwork: source.learningArtwork)
        let snapshot = [corrected] + MemoryAdventure.busyBuilders.cards.dropFirst()
        #expect(MemoryAdventure.busyBuilders.cards(from: snapshot).first == corrected)
        #expect(MemoryAdventure.busyBuilders.cards(from: snapshot).map(\.id) == MemoryAdventure.busyBuilders.cardIDs)
    }
}
