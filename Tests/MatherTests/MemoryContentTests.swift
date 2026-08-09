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
            #expect(vehicle.detailCards.map(\.title) == ["Vehicle", "Group", "Job", "Key Part", "How It Works", "Safety Fact"])
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
        }
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
