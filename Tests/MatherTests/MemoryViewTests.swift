import Testing
@testable import Mather

@Suite("MemoryView")
struct MemoryViewTests {

    @Test func birdDeckUsesExtractedSheetAssetPool() {
        let ids = MemoryDeck.birds.map(\.id)
        let assets = MemoryDeck.birds.compactMap(\.imageAssetName)
        #expect(MemoryDeck.birds.count == 36)
        #expect(ids.first == "bird-a01")
        #expect(ids.last == "bird-b18")
        #expect(Set(ids).count == ids.count)
        #expect(Set(assets).count == assets.count)
    }

    @Test func birdDeckStillSupportsHardModePairCount() {
        #expect(MemoryDeck.birds.count >= MemoryDifficulty.hard.pairCount)
    }

    @Test func vehiclesDeckProvidesEnoughDistinctPairs() {
        let ids = MemoryDeck.vehicles.map(\.id)
        let emojis = MemoryDeck.vehicles.compactMap(\.emoji)
        #expect(MemoryDeck.vehicles.count >= MemoryDifficulty.hard.pairCount)
        #expect(Set(ids).count == ids.count)
        #expect(Set(emojis).count == emojis.count)
    }

    @Test func deckSelectionExposesVehiclesDeck() {
        #expect(MemoryView.DeckSelection.allCases.contains(.vehicles))
        #expect(MemoryView.DeckSelection.vehicles.menuLabel == "Vehicles")
        #expect(MemoryView.DeckSelection.vehicles.animals.map(\.id) == MemoryDeck.vehicles.map(\.id))
    }
}
