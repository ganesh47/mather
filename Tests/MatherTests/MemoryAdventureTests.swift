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
        #expect(MemoryAdventure.wildAnimals.cards.count == 8)
        #expect(MemoryAdventure.wildAnimals.galleryCategory == .animals)
        #expect(MemoryAdventure.wildAnimals.deckKind == .domesticAnimals)
    }

    @Test @MainActor func wildAnimalsSupportMatchingAndAnimalQuizRounds() {
        let cards = MemoryAdventure.wildAnimals.cards
        let engine = MemoryPairingEngine()
        engine.deal(animals: cards, mode: .pictures, faceDown: true)
        #expect(engine.totalPairs == 8)
        #expect(engine.cards.count == 16)
        var game = MemoryGalleryTVGame()
        game.start(category: MemoryAdventure.wildAnimals.galleryCategory, deck: cards, roundLimit: 6)
        for _ in 0..<6 {
            guard let round = game.round else { Issue.record("Missing animal quiz round"); return }
            #expect(round.category == .animals)
            #expect(cards.contains(round.promptCard))
            #expect(round.answerChoices.allSatisfy { cards.contains($0) })
            #expect(round.learningFacts.contains { $0.title == "Look closely" })
            let accepted = game.select(answerID: round.correctAnswerID)
            #expect(accepted)
            game.advance()
        }
        #expect(game.phase == .completed)
        #expect(game.correctCount == 6)
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
