import Testing
@testable import Mather

@Suite("MemoryVariety")
struct MemoryVarietyTests {

    @Test func memoryDecksCoverExpandedCategoryPools() {
        #expect(MemoryDeck.domesticAnimals.count >= 18)
        #expect(MemoryDeck.birds.count == 36)
        #expect(MemoryDeck.planets.count >= 8)
        #expect(MemoryDeck.fishes.count >= 8)
        #expect(MemoryDeck.countries.count >= 8)
        #expect(MemoryDeck.countryFlags.count >= 8)
        #expect(MemoryDeck.indiaStates.count >= 8)
        #expect(MemoryDeck.waterCycle.count >= 8)
        #expect(MemoryDeck.numberBondsTo10.count == 10)
    }

    @MainActor @Test func preferredRoundAnimalsAvoidsRecentHistoryWhenFreshPoolIsLargeEnough() {
        let deck = MemoryDeck.domesticAnimals
        let recent = Array(deck.prefix(6).map(\.id))

        let round = MemoryView.preferredRoundAnimals(from: deck, pairCount: 4, recentPairHistory: recent)

        #expect(round.count == 4)
        #expect(Set(round.map(\.id)).count == 4)
        #expect(round.allSatisfy { !recent.contains($0.id) })
    }

    @MainActor @Test func preferredRoundAnimalsPicksUniqueBirdIdentities() {
        let round = MemoryView.preferredRoundAnimals(from: MemoryDeck.birds, pairCount: 6, recentPairHistory: [])

        #expect(round.count == 6)
        #expect(Set(round.map(\.id)).count == 6)
    }

    @MainActor @Test func buildCardsCreatesExactPictureAndLabelPairs() {
        let round = Array(MemoryDeck.numberBondsTo10.prefix(4))
        let cards = MemoryView.buildCards(for: round)

        #expect(cards.count == 8)
        for animal in round {
            let matching = cards.filter { $0.pairId == animal.id }
            #expect(matching.count == 2)
            #expect(matching.contains { if case .picture = $0.content { return true } else { return false } })
            #expect(matching.contains { if case .label = $0.content { return true } else { return false } })
        }
    }


    @Test func birdCardsExposeRichFactSets() {
        #expect(MemoryDeck.birds.allSatisfy { $0.detailCards.count >= 6 })
        #expect(MemoryDeck.birds.allSatisfy { Set($0.detailCards.map(\.title)).isSuperset(of: ["Name", "Home", "Lifespan", "Weight", "Size", "Colors"]) })
    }

    @MainActor @Test func learningDetailsRespectRevealRulesAcrossDecks() {
        let bird = MemoryDeck.birds[0]
        let domestic = MemoryDeck.domesticAnimals[0]
        let matchedBirdCard = MemoryCard(pairId: bird.id, content: .picture(bird), isMatched: true)
        let unmatchedBirdCard = MemoryCard(pairId: bird.id, content: .picture(bird), isMatched: false)
        let revealedDomesticCard = MemoryCard(pairId: domestic.id, content: .picture(domestic), isSelected: true)

        #expect(MemoryView.canOpenLearningDetails(for: matchedBirdCard, deckSelection: .birds, difficulty: .medium, showRoundComplete: true))
        #expect(!MemoryView.canOpenLearningDetails(for: unmatchedBirdCard, deckSelection: .birds, difficulty: .hard, showRoundComplete: true))
        #expect(MemoryView.canOpenLearningDetails(for: revealedDomesticCard, deckSelection: .domestic, difficulty: .hard, showRoundComplete: false))
        #expect(MemoryView.canOpenLearningDetails(for: matchedBirdCard, deckSelection: .birds, difficulty: .medium, showRoundComplete: false))
    }

    @MainActor @Test func updatedRecentPairHistoryKeepsRecentWindowBounded() {
        let previous = ["a", "b", "c", "d", "e", "f", "g", "h"]
        let round = Array(MemoryDeck.vehicles.prefix(4))

        let updated = MemoryView.updatedRecentPairHistory(previous: previous, newRoundAnimals: round, pairCount: 4)

        #expect(updated.count == 8)
        #expect(updated.suffix(4).elementsEqual(round.map(\.id)))
    }
}
