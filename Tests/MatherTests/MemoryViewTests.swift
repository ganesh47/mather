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

    @Test func birdDeckCarriesFactCardsForLearningPrompts() {
        let sample = MemoryDeck.birds.first
        #expect(sample != nil)
        #expect(sample?.detailCards.count == 6)
        #expect(sample?.detailCards.map(\.title) == ["Name", "Home", "Lifespan", "Weight", "Size", "Colors"])
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

    @MainActor
    @Test func learningContentAndEligibilityFollowVisibleDeckRules() {
        let bird = MemoryDeck.birds[0]
        let vehicle = MemoryDeck.vehicles[0]
        let hiddenHardBirdCard = MemoryCard(pairId: bird.id, content: .picture(bird))
        let revealedHardBirdCard = MemoryCard(pairId: bird.id, content: .picture(bird), isSelected: true)
        let matchedVehicleCard = MemoryCard(pairId: vehicle.id, content: .label(vehicle), isMatched: true)

        #expect(MemoryView.supportsLearningDetails(for: .birds))
        #expect(MemoryView.supportsLearningDetails(for: .domestic))
        #expect(MemoryView.supportsLearningDetails(for: .vehicles))
        #expect(!MemoryView.canOpenLearningDetails(for: hiddenHardBirdCard, deckSelection: .birds, difficulty: .hard, showRoundComplete: false))
        #expect(MemoryView.canOpenLearningDetails(for: revealedHardBirdCard, deckSelection: .birds, difficulty: .hard, showRoundComplete: false))
        #expect(MemoryView.canOpenLearningDetails(for: matchedVehicleCard, deckSelection: .vehicles, difficulty: .hard, showRoundComplete: true))

        let vehicleDescription = MemoryCardDescription(
            title: vehicle.canonicalName,
            shortDescription: "A road vehicle for family trips.",
            factChips: [MemoryFactChip(title: "Use", value: "family trips")],
            source: .appleIntelligence
        )
        let learningContent = MemoryView.learningContent(for: vehicle, deckSelection: .vehicles, description: vehicleDescription)
        #expect(learningContent.title == vehicle.canonicalName)
        #expect(learningContent.sourceBadge == "Apple Intelligence + Vehicle Guide")
        #expect(learningContent.factChips == [MemoryFactCard(title: "Use", value: "family trips")])
        #expect(learningContent.readAloudText.contains(vehicle.canonicalName))
    }
}


@Suite("MemoryCardDescribeService")
struct MemoryCardDescribeServiceTests {
    private struct StubAIAdapter: MemoryCardAIAdapter {
        let isAvailable: Bool
        let response: String?

        func shortDescription(for animal: MemoryAnimal) async throws -> String? {
            response
        }
    }

    @Test func allMemoryCardsExposeStructuredMetadata() {
        let allAnimals = MemoryDeck.domesticAnimals + MemoryDeck.birds + MemoryDeck.vehicles

        #expect(MemoryDeck.allAnimalsById.count == allAnimals.count)
        #expect(allAnimals.allSatisfy { !$0.metadata.category.isEmpty })
        #expect(allAnimals.allSatisfy { !$0.detailCards.isEmpty })
        #expect(MemoryDeck.domesticAnimals.allSatisfy { $0.metadata.deck == .domesticAnimals })
        #expect(MemoryDeck.birds.allSatisfy { $0.metadata.deck == .birds })
        #expect(MemoryDeck.vehicles.allSatisfy { $0.metadata.deck == .vehicles })
    }

    @MainActor @Test func fallbackDescriptionUsesCuratedBirdMetadata() async {
        let service = MemoryCardDescribeService(
            appleIntelligenceEnabled: { false },
            aiAdapter: StubAIAdapter(isAvailable: false, response: nil)
        )

        let description = await service.describe(MemoryDeck.birds[0])

        #expect(description.title == "Macaw")
        #expect(description.source == .curatedFallback)
        #expect(description.shortDescription.contains("bird"))
        #expect(description.shortDescription.localizedCaseInsensitiveContains("south american rainforests"))
        #expect(description.factChips.map(\.title) == ["Home", "Lifespan", "Weight", "Size"])
    }

    @MainActor @Test func servicePrefersAdapterOutputWhenAvailable() async {
        let service = MemoryCardDescribeService(
            appleIntelligenceEnabled: { true },
            aiAdapter: StubAIAdapter(isAvailable: true, response: "A rocket zooms high and can reach space.")
        )

        let description = await service.describe(MemoryDeck.vehicles.first { $0.id == "rocket" }!)

        #expect(description.source == .appleIntelligence)
        #expect(description.shortDescription == "A rocket zooms high and can reach space.")
        #expect(description.factChips.count == 4)
    }
}
