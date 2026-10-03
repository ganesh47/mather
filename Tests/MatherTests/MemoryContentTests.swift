import Foundation
import Testing
@testable import Mather

@Suite("MemoryContent")
struct MemoryContentTests {
    @Test func sharedDeckCatalogExposesEveryMemoryCategory() {
        #expect(MemoryDeck.availableDeckKinds == MemoryDeckKind.allCases)
        #expect(MemoryDeck.availableDeckKinds.map(\.displayName) == [
            "Animals",
            "Birds",
            "Vehicles",
            "Planets",
            "Fishes",
            "Countries & Capitals",
            "Countries & Flags",
            "Indian States & Capitals",
            "Water Cycle",
            "Fruits",
            "Number Bonds to 10"
        ])

        for kind in MemoryDeck.availableDeckKinds {
            let animals = MemoryDeck.animals(for: kind)
            #expect(!animals.isEmpty)
            #expect(animals.allSatisfy { $0.metadata.deck == kind })
        }
    }

    @Test func sharedDeckCatalogMaintainsStableDeckIds() {
        #expect(MemoryDeck.domesticAnimals.map(\.id).prefix(3) == ["cow", "dog", "cat"])
        #expect(MemoryDeck.birds.map(\.id).prefix(2) == ["bird-a01", "bird-a02"])
        #expect(MemoryDeck.vehicles.map(\.id).prefix(2) == ["car", "bus"])
        #expect(MemoryDeck.planets.map(\.id) == [
            "planet-mercury",
            "planet-venus",
            "planet-earth",
            "planet-mars",
            "planet-jupiter",
            "planet-saturn",
            "planet-uranus",
            "planet-neptune"
        ])
        #expect(MemoryDeck.numberBondsTo10.map(\.id).first == "bond-1-9")
        #expect(MemoryDeck.numberBondsTo10.map(\.id).last == "bond-10-0")
    }

    @Test func vehicleDeckIncludesPartsWorkVehiclesAndEmergencyVehicles() throws {
        let vehiclesById = Dictionary(uniqueKeysWithValues: MemoryDeck.vehicles.map { ($0.id, $0) })

        let requiredParts = [
            "vehicle-part-engine",
            "vehicle-part-transmission",
            "vehicle-part-brakes",
            "vehicle-part-wheel-axle",
            "vehicle-part-steering",
            "vehicle-part-suspension"
        ]
        let requiredAdvancedVehicles = [
            "mobile-crane",
            "crawler-crane",
            "wheel-loader",
            "skid-steer-loader",
            "backhoe-loader",
            "dump-truck",
            "concrete-mixer-truck",
            "garbage-truck",
            "tow-truck",
            "mining-haul-truck",
            "excavator",
            "bulldozer",
            "fire-engine",
            "ambulance",
            "police-car",
            "rescue-helicopter"
        ]

        for id in requiredParts {
            let part = try #require(vehiclesById[id])
            #expect(part.metadata.category == "vehicle part")
            #expect(part.detailCards.map(\.title) == ["Part", "Found In", "Job", "How It Works", "Remember"])
        }

        for id in requiredAdvancedVehicles {
            let vehicle = try #require(vehiclesById[id])
            #expect(vehicle.metadata.deck == .vehicles)
            #expect(vehicle.detailCards.map(\.title) == ["Vehicle", "Group", "Job", "Key Part", "How It Works", "Safety Fact", "Look closely", "Try it"])
            #expect(vehicle.detailCards.allSatisfy { !$0.value.isEmpty })
        }
    }

    @Test func sharedDeckCatalogHasNoDuplicateIdsAcrossCategories() {
        let ids = MemoryDeck.allDeckAnimals.map(\.id)

        #expect(ids.count == Set(ids).count)
        #expect(MemoryDeck.allAnimalsById.count == MemoryDeck.allDeckAnimals.count)
        #expect(MemoryDeck.allAnimalsById["bond-10-0"]?.metadata.deck == .numberBondsTo10)
    }

    @Test func assetBackedCardsReferenceBundledAssetCatalogEntries() {
        let sourceFile = URL(fileURLWithPath: #filePath)
        let repoRoot = sourceFile
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        let assetsRoot = repoRoot.appendingPathComponent("App/Assets.xcassets")
        let assetNames = Set(
            MemoryDeck.allDeckAnimals.compactMap(\.imageAssetName)
                + MemoryDeck.allDeckAnimals.flatMap(\.learningArtwork).map(\.assetName)
        )

        #expect(!assetNames.isEmpty)
        for assetName in assetNames {
            let imageset = assetsRoot.appendingPathComponent("\(assetName).imageset")
            let contents = imageset.appendingPathComponent("Contents.json")

            #expect(FileManager.default.fileExists(atPath: imageset.path), "Missing imageset for \(assetName)")
            #expect(FileManager.default.fileExists(atPath: contents.path), "Missing Contents.json for \(assetName)")
            if let data = try? Data(contentsOf: contents),
               let catalog = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let images = catalog["images"] as? [[String: Any]] {
                let filenames = images.compactMap { $0["filename"] as? String }
                #expect(!filenames.isEmpty, "No image payload for \(assetName)")
                for filename in filenames {
                    #expect(FileManager.default.fileExists(atPath: imageset.appendingPathComponent(filename).path), "Missing image payload for \(assetName)")
                }
            } else {
                Issue.record("Invalid catalog contents for \(assetName)")
            }
        }
    }

    @Test func storybookDecksHaveStandaloneArtAndSpokenDiscoveries() {
        let decks = [MemoryDeck.domesticAnimals, MemoryDeck.birds, MemoryDeck.fruits, MemoryDeck.fishes]
        for deck in decks {
            #expect(deck.allSatisfy { $0.imageAssetName != nil })
            #expect(Set(deck.map(\.name)).count == deck.count, "Visible answer names must be distinct")
            for card in deck {
                #expect((1...12).contains(card.detailCards.count))
                #expect(Set(card.detailCards.map(\.title)).isSuperset(of: ["Look closely", "Try it"]))
            }
        }
        #expect(MemoryDeck.birds.allSatisfy { !($0.imageAssetName ?? "").hasPrefix("MemoryBirdA") && !($0.imageAssetName ?? "").hasPrefix("MemoryBirdB") })
        #expect(MemoryDeck.domesticAnimals.first?.imageAssetName == "MemoryAnimalCow")
        #expect(MemoryDeck.fruits.first?.imageAssetName == "CompareCampApple")
        #expect(MemoryDeck.fishes.allSatisfy { $0.imageAssetName?.hasSuffix("Storybook") == true })
    }

    @Test func similarBirdIllustrationsShareCanonicalIdentity() throws {
        for ids in [["bird-a05", "bird-b01"], ["bird-a03", "bird-b07"], ["bird-a11", "bird-b17"], ["bird-a18", "bird-b13"], ["bird-a15", "bird-b12"]] {
            let left = try #require(MemoryDeck.allAnimalsById[ids[0]])
            let right = try #require(MemoryDeck.allAnimalsById[ids[1]])
            #expect(left.canonicalName == right.canonicalName)
            #expect(left.name != right.name)
        }
        let golden = try #require(MemoryDeck.allAnimalsById["bird-b09"])
        #expect(golden.name == "Storybook Golden Bird")
        #expect(golden.detailCards.contains { $0.title == "Story" && $0.value.contains("make-believe") })
    }

    @Test func publicDomainDonkeyRetainsItsActualAuthorAndLicense() throws {
        let donkey = try #require(MemoryDeck.imageAssetProvenance.first { $0.assetName == "MemoryAnimalDonkey" })
        #expect(donkey.creator == "LadyofHats")
        #expect(donkey.license.hasPrefix("Public domain"))
        #expect(donkey.sourceUrl == "https://commons.wikimedia.org/wiki/File:Donkey_cartoon_04.svg")
        #expect(donkey.originalSha256 == donkey.derivativeSha256)
        #expect(donkey.childCardLegibilityChecked)
    }

    @Test func assetPlansAndProvenancePointAtKnownCardsAndAssets() {
        let knownIds = Set(MemoryDeck.allDeckAnimals.map(\.id))
        let knownAssets = Set(
            MemoryDeck.allDeckAnimals.compactMap(\.imageAssetName)
                + MemoryDeck.allDeckAnimals.flatMap(\.learningArtwork).map(\.assetName)
        )
        let plans = MemoryDeck.vehicleImageAssetPlan
            + MemoryDeck.planetImageAssetPlan
            + MemoryDeck.fishImageAssetPlan
            + MemoryDeck.waterCycleImageAssetPlan

        for plan in plans {
            #expect(knownIds.contains(plan.cardId), "Plan references unknown card \(plan.cardId)")
            #expect(knownAssets.contains(plan.assetName), "Plan references unknown asset \(plan.assetName)")
        }

        for provenance in MemoryDeck.imageAssetProvenance {
            #expect(knownIds.contains(provenance.cardId), "Provenance references unknown card \(provenance.cardId)")
            #expect(knownAssets.contains(provenance.assetName), "Provenance references unknown asset \(provenance.assetName)")
            #expect(provenance.licenseAllowsReuse)
            #expect(provenance.childCardLegibilityChecked)
        }
    }
}
