import CryptoKit
import Foundation
import Testing
import UIKit
@testable import Mather

@Suite("Offline animal photo catalog")
struct AnimalExplorerCatalogTests {
    @Test func reviewedBankHasDistinctSpeciesPicturesAndClearProvenance() throws {
        let entries = AnimalExplorerCatalog.photoEntries
        #expect(entries.count == 31)
        #expect(Set(entries.map(\.id)).count == entries.count)
        #expect(Set(entries.map(\.speciesID)).count == entries.count)
        #expect(Set(entries.compactMap { $0.card.imageAssetName }).count == entries.count)
        let collectionIDs = Set(AnimalExplorerCatalog.collections.map(\.id))
        for entry in entries {
            let asset = try #require(entry.card.imageAssetName)
            #expect(UIImage(named: asset) != nil, "Offline asset must resolve: \(asset)")
            #expect(entry.collectionIDs.contains("all-animals"))
            #expect(Set(entry.collectionIDs).isSubset(of: collectionIDs))
            let attribution = try #require(entry.photoAttribution)
            #expect(!attribution.creditLine.isEmpty)
            #expect(attribution.sourceURL.hasPrefix("https://commons.wikimedia.org/wiki/File:"))
            #expect(attribution.licenseURL.hasPrefix("https://creativecommons.org/"))
            #expect(attribution.downloadedSHA256.count == 64)
            #expect(attribution.derivativeSHA256.count == 64)
            #expect(attribution.derivativeWidth > 0 && attribution.derivativeHeight > 0)
            #expect(max(attribution.derivativeWidth, attribution.derivativeHeight) <= 1600)
            #expect(!entry.neutralPhotoDescription.localizedCaseInsensitiveContains(entry.card.name))
            #expect(entry.card.metadata.habitat == nil)
        }
    }

    @Test func cardSnapshotsDoNotAcquireAnotherVariantsAttribution() throws {
        let original = try #require(AnimalExplorerCatalog.photoEntries.first)
        #expect(AnimalExplorerCatalog.entries(for: [original.card]) == [original])
        let changed = MemoryAnimal(
            id: original.card.id, name: original.card.name, picture: .text("Changed source picture"),
            metadata: original.card.metadata
        )
        let unknown = MemoryDeck.domesticAnimals[0]
        let supplied = AnimalExplorerCatalog.entries(for: [changed, unknown])
        #expect(supplied.map(\.card) == [changed, unknown])
        #expect(supplied.allSatisfy { $0.photoAttribution == nil && $0.photoCredit == nil })
        #expect(supplied.allSatisfy { $0.collectionIDs == ["all-animals"] })
        #expect(supplied.allSatisfy { $0.hint == nil })
    }

    @Test func collectionAndCaptionCautionsAreExplicit() throws {
        let sheep = try #require(AnimalExplorerCatalog.photoEntries.first { $0.speciesID == "sheep" })
        #expect(sheep.collectionIDs == ["all-animals", "farm-animals"])
        #expect(sheep.card.name == "Sheep")
        let camel = try #require(AnimalExplorerCatalog.photoEntries.first { $0.speciesID == "dromedary-camel" })
        #expect(!camel.neutralPhotoDescription.localizedCaseInsensitiveContains("hump"))
        #expect(camel.hint?.localizedCaseInsensitiveContains("hump") == false)
        #expect(!AnimalExplorerCatalog.photoEntries.contains { $0.speciesID == "olive-ridley-turtle" })
        let india = try #require(AnimalExplorerCatalog.collections.first { $0.id == "india-wildlife" })
        #expect(india.spokenDescription.contains("Some photographs were taken in other places or in zoos"))
        for id in ["blackbuck", "indian-peafowl"] {
            let credit = try #require(AnimalExplorerCatalog.photoEntries.first { $0.speciesID == id }?.photoAttribution)
            #expect(credit.creditLine == "N. A. Naseer / www.nilgirimarten.com / naseerart@gmail.com")
            #expect(credit.licenseURL == "https://creativecommons.org/licenses/by-sa/2.5/in/")
            #expect(credit.grantNote.contains("2013082110009341"))
        }
    }

    @Test func shippedBytesAndCompiledAttributionsMatchTheIndependentLedger() throws {
        struct Ledger: Decodable {
            struct Entry: Decodable {
                let cardID: String
                let derivativePath: String
                let derivativeSHA256: String
                let downloadedSHA256: String
                let originalSHA256: String?
                let downloadedSourceKind: String
                let derivativeDimensions: [Int]
                let downloadedDimensions: [Int]
                let licenseURL: String
                let sourcePageSHA256: String
                let sourceRevisionID: String?
            }
            let included: [Entry]
        }
        let repository = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
        let data = try Data(contentsOf: repository.appendingPathComponent("wiki/Research/Animal-Photo-Provenance.json"))
        let ledger = try JSONDecoder().decode(Ledger.self, from: data)
        #expect(ledger.included.count == AnimalExplorerCatalog.photoEntries.count)
        for entry in ledger.included {
            let compiled = try #require(AnimalExplorerCatalog.photoEntries.first { $0.id == entry.cardID }?.photoAttribution)
            let bytes = try Data(contentsOf: repository.appendingPathComponent(entry.derivativePath))
            let digest = SHA256.hash(data: bytes).map { String(format: "%02x", $0) }.joined()
            #expect(digest == entry.derivativeSHA256)
            #expect(compiled.derivativeSHA256 == digest)
            #expect(compiled.downloadedSHA256 == entry.downloadedSHA256)
            #expect(compiled.originalSHA256 == entry.originalSHA256)
            #expect(compiled.licenseURL == entry.licenseURL)
            #expect(entry.sourcePageSHA256.count == 64)
            #expect(entry.sourceRevisionID != nil)
            #expect(max(entry.derivativeDimensions[0], entry.derivativeDimensions[1]) <= max(entry.downloadedDimensions[0], entry.downloadedDimensions[1]))
            if entry.downloadedSourceKind == "commons-1280px-thumbnail" {
                #expect(entry.originalSHA256 == nil)
            }
        }
    }

    @Test func observationIdentityAndSupportAreFrozenWithoutScoringSideEffects() {
        let id = UUID()
        let began = Date(timeIntervalSince1970: 10)
        let occurred = Date(timeIntervalSince1970: 12)
        let event = AnimalExplorerLearningEvent(
            id: id, kind: .answer, sessionID: "frozen-session", startedAt: began,
            occurredAt: occurred, contentVersion: AnimalExplorerCatalog.contentVersion,
            cardID: "animal-photo-bengal-tiger", speciesID: "bengal-tiger",
            itemVariantID: "AnimalPhotoBengalTiger", roundIndex: 2, responseID: "bengal-tiger",
            correct: true, appHintUsed: true, wasExploredBeforeAnswer: true
        )
        #expect(event.id == id && event.startedAt == began && event.occurredAt == occurred)
        #expect(event.sessionID == "frozen-session" && event.roundIndex == 2)
        #expect(event.itemVariantID == "AnimalPhotoBengalTiger")
        #expect(event.appHintUsed && event.wasExploredBeforeAnswer)
        #expect(event.completedRoundCount == nil && event.correctCount == nil)
    }
}
