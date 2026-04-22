import Testing
@testable import Mather

@Suite("MemoryView")
struct MemoryViewTests {

    @Test func tropicalBirdDeckExposesApprovedFortyCardPool() {
        let ids = MemoryDeck.birds.map(\.id)
        #expect(MemoryDeck.birds.count == 40)
        #expect(ids.first == "bird-01")
        #expect(ids.last == "bird-40")
        #expect(Set(ids).count == ids.count)
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
