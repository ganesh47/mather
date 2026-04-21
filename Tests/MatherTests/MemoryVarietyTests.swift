import Testing
@testable import Mather

@Suite("MemoryVariety")
struct MemoryVarietyTests {

    @Test func domesticAndBirdDecksHaveExpandedPools() {
        #expect(MemoryDeck.domesticAnimals.count >= 18)
        #expect(MemoryDeck.birds.count >= 18)
    }

    @Test func preferredRoundAnimalsAvoidsRecentHistoryWhenFreshPoolIsLargeEnough() {
        let deck = MemoryDeck.domesticAnimals
        let recent = Array(deck.prefix(6).map(\.id))

        let round = MemoryView.preferredRoundAnimals(from: deck, pairCount: 4, recentPairHistory: recent)

        #expect(round.count == 4)
        #expect(Set(round.map(\.id)).count == 4)
        #expect(round.allSatisfy { !recent.contains($0.id) })
    }

    @Test func preferredRoundAnimalsFallsBackToDeckWhenRecentHistoryCoversMostOptions() {
        let deck = Array(MemoryDeck.birds.prefix(6))
        let recent = deck.map(\.id)

        let round = MemoryView.preferredRoundAnimals(from: deck, pairCount: 4, recentPairHistory: recent)

        #expect(round.count == 4)
        #expect(Set(round.map(\.id)).count == 4)
    }

    @Test func updatedRecentPairHistoryKeepsRecentWindowBounded() {
        let previous = ["a", "b", "c", "d", "e", "f", "g", "h"]
        let round = Array(MemoryDeck.vehicles.prefix(4))

        let updated = MemoryView.updatedRecentPairHistory(previous: previous, newRoundAnimals: round, pairCount: 4)

        #expect(updated.count == 8)
        #expect(updated.suffix(4).elementsEqual(round.map(\.id)))
    }
}
