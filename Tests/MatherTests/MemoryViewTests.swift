import Foundation
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

    @Test func issue352ImageAssetPlansTrackPilotImportsAndRemainingBacklog() {
        let vehicleIds = MemoryDeck.vehicles.map(\.id)
        let planetIds = MemoryDeck.planets.map(\.id)
        let vehiclePlan = MemoryDeck.vehicleImageAssetPlan
        let planetPlan = MemoryDeck.planetImageAssetPlan
        let plannedAssets = (vehiclePlan + planetPlan).map(\.assetName)
        let importedPlans = (vehiclePlan + planetPlan).filter { plan in
            if case .readyForAssetImport = plan.status { return true }
            return false
        }
        let importedAssetNames = Set(importedPlans.map(\.assetName))

        #expect(vehiclePlan.map(\.cardId) == vehicleIds)
        #expect(planetPlan.map(\.cardId) == planetIds)
        #expect(Set(plannedAssets).count == plannedAssets.count)
        #expect(plannedAssets.allSatisfy { $0.hasPrefix("MemoryVehicle") || $0.hasPrefix("MemoryPlanet") })
        #expect((vehiclePlan + planetPlan).allSatisfy { !$0.searchPrompt.isEmpty && !$0.styleNotes.isEmpty })
        #expect(importedAssetNames == ["MemoryPlanetEarth", "MemoryVehicleBike"])
        #expect((vehiclePlan + planetPlan).allSatisfy { plan in
            if importedAssetNames.contains(plan.assetName) {
                if case .readyForAssetImport = plan.status { return true }
                return false
            }
            if case .needsVettedSource = plan.status { return true }
            return false
        })
        #expect(MemoryDeck.vehicles.first { $0.id == "bike" }?.imageAssetName == "MemoryVehicleBike")
        #expect(MemoryDeck.planets.first { $0.id == "planet-earth" }?.imageAssetName == "MemoryPlanetEarth")
        #expect(MemoryDeck.vehicles.filter { $0.id != "bike" }.allSatisfy { $0.imageAssetName == nil })
        #expect(MemoryDeck.planets.filter { $0.id != "planet-earth" }.allSatisfy { $0.imageAssetName == nil })
    }

    @Test func issue352ImportedAssetsHaveReuseSafeProvenance() {
        let importedAssetNames = Set(
            (MemoryDeck.vehicles + MemoryDeck.planets)
                .compactMap(\.imageAssetName)
                .filter { $0.hasPrefix("MemoryVehicle") || $0.hasPrefix("MemoryPlanet") }
        )
        let provenanceByAsset = Dictionary(uniqueKeysWithValues: MemoryDeck.imageAssetProvenance.map { ($0.assetName, $0) })

        #expect(importedAssetNames == ["MemoryPlanetEarth", "MemoryVehicleBike"])
        #expect(provenanceByAsset["MemoryPlanetEarth"]?.cardId == "planet-earth")
        #expect(provenanceByAsset["MemoryVehicleBike"]?.cardId == "bike")
        #expect(MemoryDeck.imageAssetProvenance.allSatisfy { !$0.creator.isEmpty && !$0.creditLine.isEmpty && !$0.license.isEmpty })
        #expect(MemoryDeck.imageAssetProvenance.allSatisfy { $0.licenseAllowsReuse })
        #expect(MemoryDeck.imageAssetProvenance.allSatisfy { $0.noThirdPartyRestrictionFound })
        #expect(MemoryDeck.imageAssetProvenance.allSatisfy { $0.noLogoOrEndorsementRisk })
        #expect(MemoryDeck.imageAssetProvenance.allSatisfy { $0.noPeopleOrPrivacyRisk })
        #expect(MemoryDeck.imageAssetProvenance.allSatisfy { $0.childCardLegibilityChecked })
        #expect(provenanceByAsset["MemoryPlanetEarth"]?.derivativeSha256 == "77c3e4b4d267e283d2bb5efbaf2a45d8412ebee55bc15957ef1ad2514a635466")
        #expect(provenanceByAsset["MemoryVehicleBike"]?.derivativeSha256 == "e4bdd509af598bdc0b9407c85ee27987460808846b01dd28972a8c6ecbc4e276")
    }

    @Test func issue379FishDeckUsesVettedImageAssets() {
        let fishIds = MemoryDeck.fishes.map(\.id)
        let plan = MemoryDeck.fishImageAssetPlan
        let plannedAssets = plan.map(\.assetName)
        let fishAssets = MemoryDeck.fishes.compactMap(\.imageAssetName)
        let importedAssetNames = Set(plan.compactMap { plan in
            if case .readyForAssetImport = plan.status { return plan.assetName }
            return nil
        })

        #expect(plan.map(\.cardId) == fishIds)
        #expect(Set(plannedAssets).count == plannedAssets.count)
        #expect(plannedAssets.allSatisfy { $0.hasPrefix("MemoryFish") })
        #expect(plan.allSatisfy { !$0.searchPrompt.isEmpty && !$0.styleNotes.isEmpty })
        #expect(importedAssetNames == Set(plannedAssets))
        #expect(fishAssets == plannedAssets)
        #expect(MemoryDeck.fishes.allSatisfy { $0.imageAssetName != nil })
    }

    @Test func issue379FishAssetsHaveReuseSafeProvenanceAndCatalogs() {
        let fishAssets = Set(MemoryDeck.fishes.compactMap(\.imageAssetName))
        let provenanceByAsset = Dictionary(uniqueKeysWithValues: MemoryDeck.imageAssetProvenance.map { ($0.assetName, $0) })
        let expectedHashes = [
            "MemoryFishClownfish": "994003f9911cd64dae9b0b788918a64ca4bf0a9ca8c2889ecb9dfca6903d9c6b",
            "MemoryFishGoldfish": "03e5d0f461f714cff979eba3c154b3f1012f8880c88fca509cdabeb74ddc4dde",
            "MemoryFishBetta": "32da3532b489e9c7d20394cec5b99897c2011cc2a92809ced0b249d74e1aa200",
            "MemoryFishAngelfish": "8da0cff35ded5222747f099b3ca785719c9700c17514aa2f69fd3ff5b5b904c6",
            "MemoryFishCatfish": "e2d712233b9fd1d4f5fa5d3c167329d19784fb72784ce062ee8231cc7e19a1fe",
            "MemoryFishSwordtail": "decdde0bb9874d8d7b5f3c07c544f342dd339c69c42f135eee8f134a1ea18a19",
            "MemoryFishTuna": "d9716931aba86201236c724311c5b8fae07b6dca705ca059cd9c7247b33b67a3",
            "MemoryFishSeahorse": "90a58259c3a44be96017c86b1d4a165fc507ba24d9baf2c53b9dad23c1ff50a0"
        ]
        let sourceFile = URL(fileURLWithPath: #filePath)
        let repoRoot = sourceFile.deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
        let assetsRoot = repoRoot.appendingPathComponent("App/Assets.xcassets")

        #expect(fishAssets == Set(expectedHashes.keys))
        for assetName in fishAssets {
            let provenance = provenanceByAsset[assetName]
            let imageset = assetsRoot.appendingPathComponent("\(assetName).imageset")
            let image = imageset.appendingPathComponent("\(assetName).png")
            let contents = imageset.appendingPathComponent("Contents.json")

            #expect(provenance?.cardId.hasPrefix("fish-") == true)
            #expect(provenance?.sourceName == "Project-owned deterministic drawing")
            #expect(provenance?.licenseAllowsReuse == true)
            #expect(provenance?.noThirdPartyRestrictionFound == true)
            #expect(provenance?.noLogoOrEndorsementRisk == true)
            #expect(provenance?.noPeopleOrPrivacyRisk == true)
            #expect(provenance?.childCardLegibilityChecked == true)
            #expect(provenance?.derivativeSha256 == expectedHashes[assetName])
            #expect(FileManager.default.fileExists(atPath: image.path))
            #expect(FileManager.default.fileExists(atPath: contents.path))
        }
    }

    @Test func deckSelectionExposesVehiclesDeck() {
        #expect(MemoryView.DeckSelection.allCases.contains(.vehicles))
        #expect(MemoryView.DeckSelection.vehicles.menuLabel == "Vehicles")
        #expect(MemoryView.DeckSelection.vehicles.animals.map(\.id) == MemoryDeck.vehicles.map(\.id))
    }

    @Test func newDeckSelectionsExposeRequestedCategories() {
        #expect(MemoryView.DeckSelection.allCases.contains(.planets))
        #expect(MemoryView.DeckSelection.allCases.contains(.fishes))
        #expect(MemoryView.DeckSelection.allCases.contains(.countries))
        #expect(MemoryView.DeckSelection.allCases.contains(.indiaStates))
        #expect(MemoryView.DeckSelection.planets.animals.map(\.id) == MemoryDeck.planets.map(\.id))
        #expect(MemoryView.DeckSelection.fishes.animals.map(\.id) == MemoryDeck.fishes.map(\.id))
        #expect(MemoryView.DeckSelection.countries.animals.map(\.id) == MemoryDeck.countries.map(\.id))
        #expect(MemoryView.DeckSelection.indiaStates.animals.map(\.id) == MemoryDeck.indiaStates.map(\.id))
    }

    @Test func requestedDecksProvideEnoughDistinctPairs() {
        for deck in [MemoryDeck.planets, MemoryDeck.fishes, MemoryDeck.countries, MemoryDeck.indiaStates] {
            #expect(deck.count >= MemoryDifficulty.hard.pairCount)
            #expect(Set(deck.map(\.id)).count == deck.count)
        }
    }

    @Test func capitalDecksMatchPromptSideToCapitalLabel() {
        let country = MemoryDeck.countries.first { $0.canonicalName == "India" }
        let state = MemoryDeck.indiaStates.first { $0.canonicalName == "Kerala" }

        #expect(country?.name == "New Delhi")
        #expect(state?.name == "Thiruvananthapuram")
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

        func shortDescription(for animal: MemoryAnimal, prompt: MemoryCardAIPrompt) async throws -> String? {
            response
        }
    }

    @Test func allMemoryCardsExposeStructuredMetadata() {
        let allAnimals = MemoryDeck.domesticAnimals + MemoryDeck.birds + MemoryDeck.vehicles + MemoryDeck.planets + MemoryDeck.fishes + MemoryDeck.countries + MemoryDeck.indiaStates

        #expect(MemoryDeck.allAnimalsById.count == allAnimals.count)
        #expect(allAnimals.allSatisfy { !$0.metadata.category.isEmpty })
        #expect(allAnimals.allSatisfy { !$0.detailCards.isEmpty })
        #expect(MemoryDeck.domesticAnimals.allSatisfy { $0.metadata.deck == .domesticAnimals })
        #expect(MemoryDeck.birds.allSatisfy { $0.metadata.deck == .birds })
        #expect(MemoryDeck.vehicles.allSatisfy { $0.metadata.deck == .vehicles })
        #expect(MemoryDeck.planets.allSatisfy { $0.metadata.deck == .planets })
        #expect(MemoryDeck.fishes.allSatisfy { $0.metadata.deck == .fishes })
        #expect(MemoryDeck.countries.allSatisfy { $0.metadata.deck == .countries })
        #expect(MemoryDeck.indiaStates.allSatisfy { $0.metadata.deck == .indiaStates })
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

    @Test func appleIntelligencePromptStaysChildSafeAndFactBound() {
        let prompt = MemoryCardAIPrompt.childSafePrompt(for: MemoryDeck.planets.first { $0.id == "planet-earth" }!)

        #expect(prompt.systemInstruction.localizedCaseInsensitiveContains("child age 5 to 8"))
        #expect(prompt.systemInstruction.localizedCaseInsensitiveContains("two short sentences"))
        #expect(prompt.systemInstruction.localizedCaseInsensitiveContains("Do not ask questions"))
        #expect(prompt.userPrompt.contains("Earth"))
        #expect(prompt.userPrompt.contains("Order: 3rd from the Sun"))
        #expect(prompt.userPrompt.contains("Fun Fact: It has one moon"))
    }

    @MainActor @Test func generatedDescriptionsAreSanitizedBeforeUse() async {
        let service = MemoryCardDescribeService(
            appleIntelligenceEnabled: { true },
            aiAdapter: StubAIAdapter(
                isAvailable: true,
                response: "  Earth is our home planet.  It has blue oceans and white clouds. Extra sentence should not be read.  "
            )
        )

        let description = await service.describe(MemoryDeck.planets.first { $0.id == "planet-earth" }!)

        #expect(description.source == .appleIntelligence)
        #expect(description.shortDescription == "Earth is our home planet. It has blue oceans and white clouds.")
    }

    @MainActor @Test func unsafeGeneratedDescriptionsFallBackToCuratedCopy() async {
        let service = MemoryCardDescribeService(
            appleIntelligenceEnabled: { true },
            aiAdapter: StubAIAdapter(isAvailable: true, response: "As an AI language model, click here to learn about rockets.")
        )

        let description = await service.describe(MemoryDeck.vehicles.first { $0.id == "rocket" }!)

        #expect(description.source == .curatedFallback)
        #expect(description.shortDescription.localizedCaseInsensitiveContains("vehicle"))
        #expect(description.shortDescription.localizedCaseInsensitiveContains("space"))
    }

}
