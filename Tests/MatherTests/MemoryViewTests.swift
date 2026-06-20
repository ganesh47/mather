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
        let assets = MemoryDeck.vehicles.compactMap(\.imageAssetName)
        #expect(MemoryDeck.vehicles.count >= MemoryDifficulty.hard.pairCount)
        #expect(Set(ids).count == ids.count)
        #expect(assets.count == MemoryDeck.vehicles.count)
        #expect(Set(assets).count == assets.count)
    }

    @Test func issue352ImageAssetPlansTrackFullDeckImports() {
        let vehicleIds = MemoryDeck.vehicles.map(\.id)
        let planetIds = MemoryDeck.planets.map(\.id)
        let vehiclePlan = MemoryDeck.vehicleImageAssetPlan
        let planetPlan = MemoryDeck.planetImageAssetPlan
        let plannedAssets = (vehiclePlan + planetPlan).map(\.assetName)
        let importedAssetNames = Set((vehiclePlan + planetPlan).compactMap { plan in
            if case .readyForAssetImport = plan.status { return plan.assetName }
            return nil
        })
        let vehicleAssets = MemoryDeck.vehicles.compactMap(\.imageAssetName)
        let planetAssets = MemoryDeck.planets.compactMap(\.imageAssetName)

        #expect(vehiclePlan.map(\.cardId) == vehicleIds)
        #expect(planetPlan.map(\.cardId) == planetIds)
        #expect(Set(plannedAssets).count == plannedAssets.count)
        #expect(plannedAssets.allSatisfy { $0.hasPrefix("MemoryVehicle") || $0.hasPrefix("MemoryPlanet") })
        #expect((vehiclePlan + planetPlan).allSatisfy { !$0.searchPrompt.isEmpty && !$0.styleNotes.isEmpty })
        #expect(importedAssetNames == Set(plannedAssets))
        #expect(vehicleAssets == vehiclePlan.map(\.assetName))
        #expect(planetAssets == planetPlan.map(\.assetName))
        #expect(MemoryDeck.vehicles.allSatisfy { $0.imageAssetName != nil })
        #expect(MemoryDeck.planets.allSatisfy { $0.imageAssetName != nil })
    }

    @Test func issue352ImportedAssetsHaveReuseSafeProvenanceAndCatalogs() {
        let expectedHashes = [
            "MemoryPlanetMercury": "9308f539c70807709f96c98d6d70f6e931cb7095f2dd9049fa1f47be83032081",
            "MemoryPlanetVenus": "3f94177e135f7dff55b73f6091141bc6aba555e5717ceadb6b012667cf6cb6e4",
            "MemoryPlanetEarth": "77c3e4b4d267e283d2bb5efbaf2a45d8412ebee55bc15957ef1ad2514a635466",
            "MemoryPlanetMars": "8975ed07bbbe2fc471c9373d63fab8f85a0e8d3e115ea160ee73bc00724d0d6e",
            "MemoryPlanetJupiter": "0197f506bd7e414c337e9ba3543a4cf4cad5f99855e353cba8a7aca9c799da40",
            "MemoryPlanetSaturn": "798d945d730902e9d8cd438a121bc10f09a96f341fdabeec183ff64b493f3439",
            "MemoryPlanetUranus": "88e2d9c7cf3859fe88ab02a41aeb642f048760940164f84f37ed888f46d748fd",
            "MemoryPlanetNeptune": "ffc0a56865f63c42190a01825e29711596415e4aeecdf4c0d236a0d38ec12a03",
            "MemoryVehicleCar": "322156d48b0625d864b17fcd5c85d480b3938cb350ece977692ae5c34910a2a5",
            "MemoryVehicleBus": "850e2541f2eee679c5f02c4037588125b69ed049ace670fd1790498e934cb639",
            "MemoryVehicleTrain": "3eb0d1f9ec3327ea786822796d0a4cd05721512fac86a6e6e8cf443bf5ca4d60",
            "MemoryVehiclePlane": "64109fdb182213310e6951783540fb419969b250185ac47f12085270ee07dd2f",
            "MemoryVehicleBoat": "6249a276351fd91a2f81b78371c78349a5802c6de242721a8391f290ef9b5924",
            "MemoryVehicleBike": "e4bdd509af598bdc0b9407c85ee27987460808846b01dd28972a8c6ecbc4e276",
            "MemoryVehicleTruck": "daca358c96d2a4e5ecfd6a502631213a83f6628ee790e1330ce80d794af7af51",
            "MemoryVehicleTractor": "fa46188e68866c975e751d30d4dcfbef7f5946f2fb5f7a535008f594283394fe",
            "MemoryVehicleHelicopter": "b968b491b968e0aeb371c405f303adf3f301ffc71059f904e8630ecb7f4aced2",
            "MemoryVehicleRocket": "329909c4b26c533933e422a2062bf5f563b32fd687c34ee19d8c842495b23dea",
            "MemoryVehicleScooter": "a73d39d0d34154e2040d6fe9a5d7884901696a0385a8d94b949bf6c9b0bb4492",
            "MemoryVehicleTaxi": "3da398ace4c4d435b5ce3833d1407e296947e598c1ec88653d7848e8f63ea628"
        ]
        let importedAssetNames = Set(
            (MemoryDeck.vehicles + MemoryDeck.planets)
                .compactMap(\.imageAssetName)
                .filter { $0.hasPrefix("MemoryVehicle") || $0.hasPrefix("MemoryPlanet") }
        )
        let provenanceByAsset = Dictionary(uniqueKeysWithValues: MemoryDeck.imageAssetProvenance.map { ($0.assetName, $0) })
        let sourceFile = URL(fileURLWithPath: #filePath)
        let repoRoot = sourceFile.deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
        let assetsRoot = repoRoot.appendingPathComponent("App/Assets.xcassets")

        #expect(importedAssetNames == Set(expectedHashes.keys))
        for assetName in importedAssetNames {
            let provenance = provenanceByAsset[assetName]
            let imageset = assetsRoot.appendingPathComponent("\(assetName).imageset")
            let image = imageset.appendingPathComponent("\(assetName).png")
            let contents = imageset.appendingPathComponent("Contents.json")

            #expect(provenance?.sourceName == "Project-owned deterministic drawing")
            #expect(provenance?.creator.isEmpty == false)
            #expect(provenance?.creditLine == "Project-owned artwork created for Mather issue #352")
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

    @MainActor
    @Test func directFruitAndCountryEntriesBypassChooserAndUseStagedDifficulties() {
        #expect(MemoryView.shouldHideChooser(for: .fruits))
        #expect(MemoryView.shouldHideChooser(for: .countries))
        #expect(!MemoryView.shouldHideChooser(for: nil))
        #expect(!MemoryView.shouldHideChooser(for: .domesticAnimals))
        #expect(!MemoryView.shouldHideChooser(for: .countryFlags))

        #expect(MemoryView.DeckSelection(kind: .fruits).animals.map(\.id) == MemoryDeck.fruits.map(\.id))
        #expect(MemoryView.DeckSelection(kind: .countries).animals.map(\.id) == MemoryDeck.countries.map(\.id))
        #expect(MemoryView.initialDifficulty(for: .fruits) == .easy)
        #expect(MemoryView.initialDifficulty(for: .countries) == .easy)
        #expect(MemoryView.directStageDifficulties == [.easy, .medium, .hard])
    }

    @MainActor
    @Test func directStagedEntriesAdvanceEasyMediumThenStayFaceDown() {
        #expect(MemoryView.stageNumber(for: .easy) == 1)
        #expect(MemoryView.stageNumber(for: .medium) == 2)
        #expect(MemoryView.stageNumber(for: .hard) == 3)
        #expect(MemoryView.nextDirectStageDifficulty(after: .easy) == .medium)
        #expect(MemoryView.nextDirectStageDifficulty(after: .medium) == .hard)
        #expect(MemoryView.nextDirectStageDifficulty(after: .hard) == .hard)
        #expect(MemoryDifficulty.hard.faceDown)
    }

    @Test func newDeckSelectionsExposeRequestedCategories() {
        #expect(MemoryView.DeckSelection.allCases.contains(.planets))
        #expect(MemoryView.DeckSelection.allCases.contains(.fishes))
        #expect(MemoryView.DeckSelection.allCases.contains(.countries))
        #expect(MemoryView.DeckSelection.allCases.contains(.countryFlags))
        #expect(MemoryView.DeckSelection.allCases.contains(.indiaStates))
        #expect(MemoryView.DeckSelection.allCases.contains(.waterCycle))
        #expect(MemoryView.DeckSelection.allCases.contains(.fruits))
        #expect(MemoryView.DeckSelection.planets.animals.map(\.id) == MemoryDeck.planets.map(\.id))
        #expect(MemoryView.DeckSelection.fishes.animals.map(\.id) == MemoryDeck.fishes.map(\.id))
        #expect(MemoryView.DeckSelection.countries.animals.map(\.id) == MemoryDeck.countries.map(\.id))
        #expect(MemoryView.DeckSelection.countryFlags.animals.map(\.id) == MemoryDeck.countryFlags.map(\.id))
        #expect(MemoryView.DeckSelection.indiaStates.animals.map(\.id) == MemoryDeck.indiaStates.map(\.id))
        #expect(MemoryView.DeckSelection.waterCycle.animals.map(\.id) == MemoryDeck.waterCycle.map(\.id))
        #expect(MemoryView.DeckSelection.fruits.animals.map(\.id) == MemoryDeck.fruits.map(\.id))
    }

    @Test func requestedDecksProvideEnoughDistinctPairs() {
        for deck in [MemoryDeck.planets, MemoryDeck.fishes, MemoryDeck.countries, MemoryDeck.countryFlags, MemoryDeck.indiaStates, MemoryDeck.waterCycle] {
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

    @Test func countryFlagsDeckIsSeparateFlagToCountryMatchDeck() {
        let expectedCountries = ["India", "Japan", "France", "Egypt", "Brazil", "Australia", "Canada", "Kenya"]
        let ids = MemoryDeck.countryFlags.map(\.id)
        let assets = MemoryDeck.countryFlags.compactMap(\.imageAssetName)

        #expect(MemoryView.DeckSelection.countryFlags.menuLabel == "Countries & Flags")
        #expect(MemoryView.DeckSelection.countryFlags.label == "🏳️ Countries & Flags")
        #expect(MemoryDeck.countryFlags.map(\.canonicalName) == expectedCountries)
        #expect(MemoryDeck.countryFlags.map(\.name) == expectedCountries)
        #expect(Set(ids).count == ids.count)
        #expect(ids.allSatisfy { $0.hasPrefix("country-flag-") })
        #expect(Set(assets).count == MemoryDeck.countryFlags.count)
        #expect(assets.allSatisfy { $0.hasPrefix("MemoryFlag") })
        #expect(MemoryDeck.countryFlags.allSatisfy { $0.metadata.deck == .countryFlags })
        #expect(MemoryDeck.countryFlags.allSatisfy { $0.metadata.category == "country flag" })
        #expect(MemoryDeck.countryFlags.allSatisfy { animal in
            animal.detailCards.contains { $0.title == "Flag" && $0.value == "Flag of \(animal.canonicalName)" }
        })

        let indiaCapital = MemoryDeck.countries.first { $0.canonicalName == "India" }
        let indiaFlag = MemoryDeck.countryFlags.first { $0.canonicalName == "India" }
        #expect(indiaCapital?.id == "country-india")
        #expect(indiaCapital?.name == "New Delhi")
        #expect(indiaFlag?.id == "country-flag-india")
        #expect(indiaFlag?.name == "India")
    }

    @MainActor
    @Test func countryFlagsBuildFlagPictureAndCountryLabelCards() {
        let india = MemoryDeck.countryFlags.first { $0.canonicalName == "India" }!
        let cards = MemoryView.buildCards(for: [india])
        let picture = cards.first { card in
            if case .picture = card.content { return true }
            return false
        }!
        let label = cards.first { card in
            if case .label = card.content { return true }
            return false
        }!

        #expect(picture.pairId == "country-flag-india")
        #expect(label.pairId == "country-flag-india")
        #expect(MemoryView.accessibilityLabel(for: picture) == "Flag of India")
        #expect(MemoryView.accessibilityLabel(for: label) == "India")
        if case let .picture(animal) = picture.content {
            #expect(animal.imageAssetName == "MemoryFlagIndia")
        } else {
            Issue.record("Expected picture card")
        }
        if case let .label(animal) = label.content {
            #expect(animal.name == "India")
        } else {
            Issue.record("Expected label card")
        }
    }

    @MainActor
    @Test func memoryCardModelsKeepPictureAndNameFacesPure() {
        let cow = MemoryDeck.domesticAnimals[0]
        let flag = MemoryDeck.countryFlags.first { $0.canonicalName == "India" }!

        let cowPicture = MemoryView.learningCardModel(
            for: MemoryCard(pairId: cow.id, content: .picture(cow)),
            difficulty: .easy,
            isIncorrect: false
        )
        let cowLabel = MemoryView.learningCardModel(
            for: MemoryCard(pairId: cow.id, content: .label(cow)),
            difficulty: .easy,
            isIncorrect: false
        )
        let flagPicture = MemoryView.learningCardModel(
            for: MemoryCard(pairId: flag.id, content: .picture(flag)),
            difficulty: .easy,
            isIncorrect: false
        )
        let flagLabel = MemoryView.learningCardModel(
            for: MemoryCard(pairId: flag.id, content: .label(flag)),
            difficulty: .easy,
            isIncorrect: false
        )

        #expect(cowPicture.display == .emoji("🐄"))
        #expect(cowLabel.display == .text("Cow"))
        #expect(flagPicture.display == .asset("MemoryFlagIndia"))
        #expect(flagLabel.display == .text("India"))
    }

    @MainActor
    @Test func faceDownMemoryCardsDoNotExposeHiddenAnswerToAccessibility() {
        let bird = MemoryDeck.birds[0]
        let hidden = MemoryCard(pairId: bird.id, content: .picture(bird))
        let hiddenLabel = MemoryCard(pairId: bird.id, content: .label(bird))
        let selected = MemoryCard(pairId: bird.id, content: .picture(bird), isSelected: true)

        #expect(MemoryView.accessibilityLabel(for: hidden, difficulty: .hard) == "Face down memory card")
        #expect(MemoryView.accessibilityHint(for: hidden, difficulty: .hard) == "Tap to turn this card over.")
        #expect(MemoryView.accessibilityLabel(for: hiddenLabel, difficulty: .hard) == "Face down memory card")
        #expect(MemoryView.accessibilityHint(for: hiddenLabel, difficulty: .hard) == "Tap to turn this card over.")
        #expect(MemoryView.accessibilityLabel(for: selected, difficulty: .hard).contains(bird.canonicalName))
        #expect(MemoryView.accessibilityLabel(for: selected, difficulty: .hard).contains("selected"))
    }

    @Test func countryFlagAssetsHaveProvenanceAndCatalogs() {
        let expectedHashes = [
            "MemoryFlagIndia": "532012f66641b8e0ddd64628305810178bd97bb35e13086c00ee2ba597ae45f2",
            "MemoryFlagJapan": "b2d751e8a2b4a7987c5268b5edb12b45a5cdda7dd9977d027311aba9401b39ef",
            "MemoryFlagFrance": "c9912731f78d48a59bcad43a2e0014ac83ef7887277b8a4ad8728803a3c74ff4",
            "MemoryFlagEgypt": "f307582ff40e2c27ebf25e244fa34330b671f30cf44df07e75fc122f3402ddd8",
            "MemoryFlagBrazil": "ac1235d39036fd5ed000a10dd0e49d939eda8db1632c831d8453be301aa6c272",
            "MemoryFlagAustralia": "07e169c5a54af9027fbafe0348e4505b09112cd077d1e3fbcf37a206be37c119",
            "MemoryFlagCanada": "b3712b0ba8bb6c0bb9d40878b9ba8af8dfcd42f5fc35823472d4324ef580132c",
            "MemoryFlagKenya": "174a01c7a8f65e7b4e7fc976edb1f239617042113a82335fa7ff7455ea1657e9"
        ]
        let flagAssets = Set(MemoryDeck.countryFlags.compactMap(\.imageAssetName))
        let provenanceByAsset = Dictionary(uniqueKeysWithValues: MemoryDeck.imageAssetProvenance.map { ($0.assetName, $0) })
        let sourceFile = URL(fileURLWithPath: #filePath)
        let repoRoot = sourceFile.deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
        let assetsRoot = repoRoot.appendingPathComponent("App/Assets.xcassets")

        #expect(flagAssets == Set(expectedHashes.keys))
        for assetName in flagAssets {
            let provenance = provenanceByAsset[assetName]
            let imageset = assetsRoot.appendingPathComponent("\(assetName).imageset")
            let image = imageset.appendingPathComponent("\(assetName).png")
            let contents = imageset.appendingPathComponent("Contents.json")

            #expect(provenance?.sourceName == "Project-owned deterministic educational flag drawing")
            #expect(provenance?.creditLine == "Project-owned artwork created for Mather issue #744")
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

    @Test func waterCycleDeckUsesVettedImageAssets() {
        let expectedNames = ["Evaporation", "Condensation", "Precipitation", "Collection", "Sun Heat", "Vapor", "Cloud", "Pond"]
        let ids = MemoryDeck.waterCycle.map(\.id)
        let assets = MemoryDeck.waterCycle.compactMap(\.imageAssetName)
        let plan = MemoryDeck.waterCycleImageAssetPlan
        let importedAssetNames = Set(plan.compactMap { plan in
            if case .readyForAssetImport = plan.status { return plan.assetName }
            return nil
        })

        #expect(MemoryView.DeckSelection.waterCycle.menuLabel == "Water Cycle")
        #expect(MemoryView.DeckSelection.waterCycle.label == "💧 Water Cycle")
        #expect(MemoryDeck.waterCycle.map(\.name) == expectedNames)
        #expect(Set(ids).count == ids.count)
        #expect(ids.allSatisfy { $0.hasPrefix("water-cycle-") })
        #expect(Set(assets).count == MemoryDeck.waterCycle.count)
        #expect(assets.allSatisfy { $0.hasPrefix("MemoryWaterCycle") })
        #expect(plan.map(\.cardId) == ids)
        #expect(plan.map(\.assetName) == assets)
        #expect(importedAssetNames == Set(assets))
        #expect(MemoryDeck.waterCycle.allSatisfy { $0.metadata.deck == .waterCycle })
        #expect(MemoryDeck.fruits.allSatisfy { $0.metadata.deck == .fruits })
        #expect(MemoryDeck.fruits.first?.detailCards.map(\.title).contains("Taste") == true)
        #expect(MemoryDeck.fruits.first?.detailCards.map(\.title).contains("Usually Found") == true)
        #expect(MemoryDeck.waterCycle.allSatisfy { $0.metadata.category == "water cycle concept" })
        #expect(MemoryDeck.waterCycle.allSatisfy { animal in
            Set(animal.detailCards.map(\.title)).isSuperset(of: ["Concept", "Action", "Where", "Everyday Words", "Cycle Step"])
        })
    }

    @MainActor
    @Test func waterCycleBuildsPictureAndConceptLabelCards() {
        let evaporation = MemoryDeck.waterCycle.first { $0.id == "water-cycle-evaporation" }!
        let cards = MemoryView.buildCards(for: [evaporation])
        let picture = cards.first { card in
            if case .picture = card.content { return true }
            return false
        }!
        let label = cards.first { card in
            if case .label = card.content { return true }
            return false
        }!

        #expect(picture.pairId == "water-cycle-evaporation")
        #expect(label.pairId == "water-cycle-evaporation")
        #expect(MemoryView.accessibilityLabel(for: picture) == "Evaporation")
        #expect(MemoryView.accessibilityLabel(for: label) == "Evaporation")
        if case let .picture(animal) = picture.content {
            #expect(animal.imageAssetName == "MemoryWaterCycleEvaporation")
        } else {
            Issue.record("Expected picture card")
        }
    }

    @Test func waterCycleAssetsHaveProvenanceAndCatalogs() {
        let expectedHashes = [
            "MemoryWaterCycleEvaporation": "5f7571966da3b6242143f3a44e73c41ee81f1085849a32f9a067b6124a996569",
            "MemoryWaterCycleCondensation": "9698adba516d56e3f4b9f30465630b4af094a03a6f111fde71622b02df2e7fe2",
            "MemoryWaterCyclePrecipitation": "5cd079edf33046af063ad95cdc34d75d1783c2af5561b6478d4cbf39fb0b5dc1",
            "MemoryWaterCycleCollection": "cc5e445e06d97f817e01bfc1977621fd68259f0620b43c1fc57fba3c5e612a31",
            "MemoryWaterCycleSunHeat": "78eda4860d8e9a467e59cd74fb857aa01745adbdfab504b1acc4049c15743621",
            "MemoryWaterCycleVapor": "b18c6b62a49da2c32206fe750468626675067ee7aac36fbbb1a8186ef04e6a2b",
            "MemoryWaterCycleCloud": "9b4ec5f6b72b03b0e0ec9e730164de97b9e532043c07b16f62937a71499518c9",
            "MemoryWaterCyclePond": "97829a63dda1473845eadb5c54b3701d5eca265f73044920de36f00bc941acce"
        ]
        let waterCycleAssets = Set(MemoryDeck.waterCycle.compactMap(\.imageAssetName))
        let provenanceByAsset = Dictionary(uniqueKeysWithValues: MemoryDeck.imageAssetProvenance.map { ($0.assetName, $0) })
        let sourceFile = URL(fileURLWithPath: #filePath)
        let repoRoot = sourceFile.deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
        let assetsRoot = repoRoot.appendingPathComponent("App/Assets.xcassets")

        #expect(waterCycleAssets == Set(expectedHashes.keys))
        for assetName in waterCycleAssets {
            let provenance = provenanceByAsset[assetName]
            let imageset = assetsRoot.appendingPathComponent("\(assetName).imageset")
            let image = imageset.appendingPathComponent("\(assetName).png")
            let contents = imageset.appendingPathComponent("Contents.json")

            #expect(provenance?.sourceName == "Codex CLI image generation water cycle prompt family")
            #expect(provenance?.creditLine == "Project-owned artwork created for Mather issue #771")
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

    @MainActor
    @Test func learningContentAndEligibilityFollowVisibleDeckRules() {
        let bird = MemoryDeck.birds[0]
        let vehicle = MemoryDeck.vehicles[0]
        let planet = MemoryDeck.planets[0]
        let hiddenHardBirdCard = MemoryCard(pairId: bird.id, content: .picture(bird))
        let revealedHardBirdCard = MemoryCard(pairId: bird.id, content: .picture(bird), isSelected: true)
        let hiddenHardPlanetCard = MemoryCard(pairId: planet.id, content: .picture(planet))
        let revealedHardPlanetCard = MemoryCard(pairId: planet.id, content: .picture(planet), isSelected: true)
        let matchedVehicleCard = MemoryCard(pairId: vehicle.id, content: .label(vehicle), isMatched: true)

        #expect(MemoryView.supportsLearningDetails(for: .birds))
        #expect(MemoryView.supportsLearningDetails(for: .domestic))
        #expect(MemoryView.supportsLearningDetails(for: .vehicles))
        #expect(MemoryView.supportsLearningDetails(for: .planets))
        #expect(!MemoryView.canOpenLearningDetails(for: hiddenHardBirdCard, deckSelection: .birds, difficulty: .hard, showRoundComplete: false))
        #expect(MemoryView.canOpenLearningDetails(for: revealedHardBirdCard, deckSelection: .birds, difficulty: .hard, showRoundComplete: false))
        #expect(!MemoryView.canOpenLearningDetails(for: hiddenHardPlanetCard, deckSelection: .planets, difficulty: .hard, showRoundComplete: false))
        #expect(MemoryView.canOpenLearningDetails(for: revealedHardPlanetCard, deckSelection: .planets, difficulty: .hard, showRoundComplete: false))
        #expect(MemoryView.canOpenLearningDetails(for: matchedVehicleCard, deckSelection: .vehicles, difficulty: .hard, showRoundComplete: true))
        #expect(MemoryView.learnMoreHintText(for: .vehicles) == "Double-tap a card to learn more")
        #expect(MemoryView.roundCompleteMessage(for: .planets, roundsPlayed: 1) == "Double-tap a card to learn more, or start the next round.")
        #expect(!MemoryView.roundCompleteMessage(for: .vehicles, roundsPlayed: 1).localizedCaseInsensitiveContains("bird"))
        #expect(MemoryView.learnAboutActionName(for: planet) == "Learn about Mercury")

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
        #expect(learningContent.readAloudText.contains("Source: Apple Intelligence + Vehicle Guide."))

        let planetDescription = MemoryCardDescription(
            title: planet.canonicalName,
            shortDescription: "Mercury is a planet near the Sun.",
            factChips: [MemoryFactChip(title: "Order", value: "1st from the Sun")],
            source: .curatedFallback
        )
        let planetContent = MemoryView.learningContent(for: planet, deckSelection: .planets, description: planetDescription)
        #expect(planetContent.sourceBadge == "Planet Guide")
        #expect(planetContent.readAloudText.contains("Source: Planet Guide."))

        let flagDescription = MemoryCardDescription(
            title: "India",
            shortDescription: "This card shows the flag of India.",
            factChips: [MemoryFactChip(title: "Flag", value: "Flag of India")],
            source: .curatedFallback
        )
        let flagContent = MemoryView.learningContent(for: MemoryDeck.countryFlags[0], deckSelection: .countryFlags, description: flagDescription)
        #expect(flagContent.sourceBadge == "Flag Guide")
        #expect(flagContent.readAloudText.contains("Source: Flag Guide."))

        let waterCycleDescription = MemoryCardDescription(
            title: "Evaporation",
            shortDescription: "Evaporation is warm water going up.",
            factChips: [MemoryFactChip(title: "Action", value: "warm water goes up")],
            source: .curatedFallback
        )
        let waterCycleContent = MemoryView.learningContent(for: MemoryDeck.waterCycle[0], deckSelection: .waterCycle, description: waterCycleDescription)
        #expect(waterCycleContent.sourceBadge == "Water Cycle Guide")
        #expect(waterCycleContent.readAloudText.contains("Source: Water Cycle Guide."))

        let fruitDescription = MemoryCardDescription(
            title: "Mango",
            shortDescription: "Mango is a sweet fruit with shape, color, smell, and country clues.",
            factChips: [MemoryFactChip(title: "Taste", value: "very sweet and juicy")],
            source: .curatedFallback
        )
        let fruitContent = MemoryView.learningContent(for: MemoryDeck.fruits[2], deckSelection: .fruits, description: fruitDescription)
        #expect(fruitContent.sourceBadge == "Fruit Guide")
        #expect(fruitContent.readAloudText.contains("Source: Fruit Guide."))
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
        let allAnimals = MemoryDeck.allDeckAnimals

        #expect(MemoryDeck.allAnimalsById.count == allAnimals.count)
        #expect(allAnimals.allSatisfy { !$0.metadata.category.isEmpty })
        #expect(allAnimals.allSatisfy { !$0.detailCards.isEmpty })
        #expect(MemoryDeck.domesticAnimals.allSatisfy { $0.metadata.deck == .domesticAnimals })
        #expect(MemoryDeck.birds.allSatisfy { $0.metadata.deck == .birds })
        #expect(MemoryDeck.vehicles.allSatisfy { $0.metadata.deck == .vehicles })
        #expect(MemoryDeck.planets.allSatisfy { $0.metadata.deck == .planets })
        #expect(MemoryDeck.fishes.allSatisfy { $0.metadata.deck == .fishes })
        #expect(MemoryDeck.countries.allSatisfy { $0.metadata.deck == .countries })
        #expect(MemoryDeck.countryFlags.allSatisfy { $0.metadata.deck == .countryFlags })
        #expect(MemoryDeck.indiaStates.allSatisfy { $0.metadata.deck == .indiaStates })
        #expect(MemoryDeck.waterCycle.allSatisfy { $0.metadata.deck == .waterCycle })
        #expect(MemoryDeck.fruits.allSatisfy { $0.metadata.deck == .fruits })
        #expect(MemoryDeck.fruits.first?.detailCards.map(\.title).contains("Taste") == true)
        #expect(MemoryDeck.fruits.first?.detailCards.map(\.title).contains("Usually Found") == true)
    }

    @MainActor @Test func fallbackDescriptionUsesCuratedFlagMetadata() async {
        let service = MemoryCardDescribeService(
            appleIntelligenceEnabled: { false },
            aiAdapter: StubAIAdapter(isAvailable: false, response: nil)
        )

        let description = await service.describe(MemoryDeck.countryFlags[0])

        #expect(description.title == "India")
        #expect(description.source == .curatedFallback)
        #expect(description.shortDescription.localizedCaseInsensitiveContains("flag of india"))
        #expect(description.shortDescription.localizedCaseInsensitiveContains("country in asia"))
        #expect(Array(description.factChips.map(\.title).prefix(4)) == ["Country", "Flag", "ISO Code", "Capital"])
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

    @MainActor @Test func fallbackDescriptionUsesCuratedWaterCycleMetadata() async {
        let service = MemoryCardDescribeService(
            appleIntelligenceEnabled: { false },
            aiAdapter: StubAIAdapter(isAvailable: false, response: nil)
        )

        let description = await service.describe(MemoryDeck.waterCycle.first { $0.id == "water-cycle-evaporation" }!)

        #expect(description.title == "Evaporation")
        #expect(description.source == .curatedFallback)
        #expect(description.shortDescription.localizedCaseInsensitiveContains("water cycle"))
        #expect(description.shortDescription.localizedCaseInsensitiveContains("warm water goes up"))
        #expect(description.shortDescription.localizedCaseInsensitiveContains("sun warms water into vapor"))
        #expect(Array(description.factChips.map(\.title).prefix(4)) == ["Concept", "Action", "Where", "Everyday Words"])
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
        #expect(prompt.systemInstruction.localizedCaseInsensitiveContains("220 total characters"))
        #expect(prompt.systemInstruction.localizedCaseInsensitiveContains("Do not ask questions"))
        #expect(prompt.systemInstruction.localizedCaseInsensitiveContains("roleplay"))
        #expect(prompt.systemInstruction.localizedCaseInsensitiveContains("markdown"))
        #expect(prompt.systemInstruction.localizedCaseInsensitiveContains("emoji"))
        #expect(prompt.userPrompt.localizedCaseInsensitiveContains("Only use these known facts"))
        #expect(prompt.userPrompt.contains("Earth"))
        #expect(prompt.userPrompt.contains("Order: 3rd from the Sun"))
        #expect(prompt.userPrompt.contains("Fun Fact: It has one moon"))
    }

    @MainActor @Test func appleIntelligenceDisabledFallsBackEvenWhenAdapterCanRespond() async {
        let service = MemoryCardDescribeService(
            appleIntelligenceEnabled: { false },
            aiAdapter: StubAIAdapter(isAvailable: true, response: "A rocket zooms high and can reach space.")
        )

        let description = await service.describe(MemoryDeck.vehicles.first { $0.id == "rocket" }!)

        #expect(description.source == .curatedFallback)
        #expect(description.shortDescription.localizedCaseInsensitiveContains("vehicle"))
        #expect(description.shortDescription.localizedCaseInsensitiveContains("space"))
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
        let unsafeResponses = [
            "As an AI language model, click here to learn about rockets.",
            "What is a rocket? A rocket can fly high.",
            "- A rocket blasts toward space.",
            "A rocket blasts toward space. 🚀",
            "Pretend you are a rocket blasting into space."
        ]

        for response in unsafeResponses {
            let service = MemoryCardDescribeService(
                appleIntelligenceEnabled: { true },
                aiAdapter: StubAIAdapter(isAvailable: true, response: response)
            )

            let description = await service.describe(MemoryDeck.vehicles.first { $0.id == "rocket" }!)

            #expect(description.source == .curatedFallback)
            #expect(description.shortDescription.localizedCaseInsensitiveContains("vehicle"))
            #expect(description.shortDescription.localizedCaseInsensitiveContains("space"))
        }
    }

    @MainActor @Test func overlongGeneratedDescriptionsFallBackToCuratedCopy() async {
        let service = MemoryCardDescribeService(
            appleIntelligenceEnabled: { true },
            aiAdapter: StubAIAdapter(
                isAvailable: true,
                response: "Earth is a rocky planet with blue oceans, green land, white clouds, one moon, a day and night cycle, many habitats, and people living on it around the world."
            )
        )

        let description = await service.describe(MemoryDeck.planets.first { $0.id == "planet-earth" }!)

        #expect(description.source == .curatedFallback)
        #expect(description.shortDescription.localizedCaseInsensitiveContains("planet"))
        #expect(description.shortDescription.localizedCaseInsensitiveContains("solar system"))
    }

}
