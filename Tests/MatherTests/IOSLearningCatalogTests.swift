import Foundation
import CoreGraphics
import CryptoKit
import ImageIO
import Testing
@testable import Mather

@Suite("Versioned iOS learning catalog")
struct IOSLearningCatalogTests {
    @Test func bundledCatalogIsCompleteAndRoundTrips() throws {
        let catalog = IOSLearningCatalog.bundled
        try catalog.validate()
        #expect(catalog.decks.count == 11)
        #expect(catalog.threads.count == 7)
        #expect(try JSONDecoder().decode(IOSLearningCatalog.self, from: JSONEncoder().encode(catalog)) == catalog)
        // The separate TV feed still enforces its original four-deck contract.
        try MemoryGalleryContentPack.bundled.validate()
        #expect(throws: (any Error).self) {
            try MemoryGalleryContentPack(schemaVersion: 1, contentVersion: 2, decks: catalog.decks, assets: []).validate()
        }
    }

    @Test func rejectsMissingTopicsUnknownArtworkAndUnsupportedSchema() throws {
        let catalog = IOSLearningCatalog.bundled
        #expect(throws: (any Error).self) {
            try IOSLearningCatalog(schemaVersion: 9, contentVersion: 2, decks: catalog.decks, threads: catalog.threads, assets: []).validate()
        }
        #expect(throws: (any Error).self) {
            try IOSLearningCatalog(schemaVersion: 1, contentVersion: 2, decks: catalog.decks, threads: Array(catalog.threads.dropLast()), assets: []).validate()
        }
        let source = catalog.threads[0]
        let entity = GameplayEntity(id: "new-entity", name: "New", visualAssetName: "unverified-artwork",
            properties: [GameplayProperty(id: "new-property", typeID: source.propertyTypes[0].id, value: "New")])
        let thread = GameplayThreadDefinition(id: source.id, title: source.title, category: source.category,
            propertyTypes: source.propertyTypes, entities: source.entities + [entity], stages: source.stages)
        #expect(throws: (any Error).self) {
            try IOSLearningCatalog(schemaVersion: 1, contentVersion: 2, decks: catalog.decks, threads: [thread] + catalog.threads.dropFirst(), assets: []).validate()
        }
    }

    @Test func previousReleaseBundledBirdArtworkRemainsAValidSchemaOneReference() throws {
        let bundled = IOSLearningCatalog.bundled
        let source = try #require(bundled.threads.first { $0.id == "world-birds" })
        let bird = try #require(source.entities.first)
        let legacyBird = GameplayEntity(id: bird.id, name: bird.name, summary: bird.summary,
            visualAssetName: "MemoryBirdA01", properties: bird.properties)
        let legacyThread = GameplayThreadDefinition(id: source.id, title: source.title, category: source.category,
            propertyTypes: source.propertyTypes, entities: [legacyBird] + source.entities.dropFirst(), stages: source.stages)
        let legacy = IOSLearningCatalog(schemaVersion: 1, contentVersion: 2, decks: bundled.decks,
            threads: bundled.threads.map { $0.id == source.id ? legacyThread : $0 }, assets: [])
        try legacy.validate()
    }

    @Test @MainActor func activeSessionDefersUpdateAndVerifiedCacheWorksOffline() async throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: root) }
        let bundled = IOSLearningCatalog.bundled
        let update = IOSLearningCatalog(schemaVersion: 1, contentVersion: bundled.contentVersion + 1, decks: bundled.decks, threads: bundled.threads, assets: [])
        let manifest = try JSONEncoder().encode(update)
        let store = IOSLearningContentStore(root: root, fetch: { _, _ in manifest })
        let sessionSnapshot = store.catalog
        await store.refresh(from: URL(string: "https://example.com/ios/catalog.json")!, canActivate: { false })
        #expect(store.catalog.contentVersion == bundled.contentVersion)
        #expect(sessionSnapshot == bundled)
        store.activatePending()
        #expect(store.catalog == update)
        #expect(sessionSnapshot.contentVersion == bundled.contentVersion)
        let offline = IOSLearningContentStore(root: root, fetch: { _, _ in throw URLError(.notConnectedToInternet) })
        #expect(offline.catalog == update)
        await offline.refresh(from: URL(string: "https://example.com/ios/catalog.json")!)
        #expect(offline.catalog == update)
        #expect(offline.lastRefreshError != nil)
    }

    @Test @MainActor func invalidManifestAndIncompleteAssetsNeverReplaceContent() async throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: root) }
        let bundled = IOSLearningCatalog.bundled
        var response = Data("{bad-json}".utf8)
        let store = IOSLearningContentStore(root: root, fetch: { url, _ in
            if url.pathExtension == "png" { throw URLError(.cannotFindHost) }
            return response
        })
        let url = URL(string: "https://example.com/ios/catalog.json")!
        await store.refresh(from: url)
        #expect(store.catalog == bundled)
        let asset = MemoryGalleryContentPack.Asset(id: "new-image", file: "new-image.png", byteCount: 20, sha256: String(repeating: "a", count: 64))
        response = try JSONEncoder().encode(IOSLearningCatalog(schemaVersion: 1, contentVersion: bundled.contentVersion + 1,
            decks: bundled.decks, threads: bundled.threads, assets: [asset]))
        await store.refresh(from: url)
        #expect(store.catalog == bundled)
        #expect(store.lastRefreshError != nil)
        #expect(!FileManager.default.fileExists(atPath: root.appendingPathComponent("active").path))
        await store.refresh(from: URL(string: "http://example.com/ios/catalog.json")!)
        #expect(store.catalog == bundled)
    }

    @Test @MainActor func delayedOlderResponseCannotReplaceNewerPendingCatalog() async throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: root) }
        let bundled = IOSLearningCatalog.bundled
        var version = bundled.contentVersion + 2
        let store = IOSLearningContentStore(root: root, fetch: { _, _ in
            try JSONEncoder().encode(IOSLearningCatalog(schemaVersion: 1, contentVersion: version,
                decks: bundled.decks, threads: bundled.threads, assets: []))
        })
        let url = URL(string: "https://example.com/ios/catalog.json")!
        await store.refresh(from: url, canActivate: { false })
        version = bundled.contentVersion + 1
        await store.refresh(from: url, canActivate: { false })
        #expect(store.catalog.contentVersion == bundled.contentVersion)
        store.activatePending()
        #expect(store.catalog.contentVersion == bundled.contentVersion + 2)
    }

    @Test @MainActor func replacingCatalogKeepsPausedSessionArtworkAvailable() async throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: root) }
        let context = try #require(CGContext(data: nil, width: 1, height: 1, bitsPerComponent: 8,
            bytesPerRow: 4, space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue))
        let image = try #require(context.makeImage())
        let png = NSMutableData()
        let destination = try #require(CGImageDestinationCreateWithData(png, "public.png" as CFString, 1, nil))
        CGImageDestinationAddImage(destination, image, nil)
        #expect(CGImageDestinationFinalize(destination))
        let artwork = png as Data
        let asset = MemoryGalleryContentPack.Asset(id: "paused-image", file: "paused-image.png", byteCount: artwork.count,
            sha256: SHA256.hash(data: artwork).map { String(format: "%02x", $0) }.joined())
        let bundled = IOSLearningCatalog.bundled
        var version = bundled.contentVersion + 1
        let store = IOSLearningContentStore(root: root, fetch: { url, _ in
            if url.pathExtension == "png" { return artwork }
            return try JSONEncoder().encode(IOSLearningCatalog(schemaVersion: 1, contentVersion: version,
                decks: bundled.decks, threads: bundled.threads, assets: version == bundled.contentVersion + 1 ? [asset] : []))
        })
        let url = URL(string: "https://example.com/ios/catalog.json")!
        await store.refresh(from: url)
        let pausedImage = try #require(store.assetURL(named: asset.id))
        version = bundled.contentVersion + 2
        await store.refresh(from: url)
        #expect(store.catalog.contentVersion == bundled.contentVersion + 2)
        #expect(store.assetURL(named: asset.id) == nil)
        try IOSLearningContentStore.validateArtwork(Data(contentsOf: pausedImage), asset: asset)
        let restored = IOSLearningContentStore(root: root)
        #expect(restored.catalog.contentVersion == bundled.contentVersion + 2)
        #expect(FileManager.default.fileExists(atPath: pausedImage.path))
    }

    @Test @MainActor func previousReleaseCatalogDoesNotOverrideNewBundledMemory() throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: root) }
        let directory = root.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let bundled = IOSLearningCatalog.bundled
        let older = IOSLearningCatalog(schemaVersion: 1, contentVersion: 2,
            decks: bundled.decks, threads: bundled.threads, assets: [])
        let encoded = try JSONEncoder().encode(older)
        try encoded.write(to: directory.appendingPathComponent("pack.json"))
        try Data(directory.lastPathComponent.utf8).write(to: root.appendingPathComponent("active"))
        try Data(directory.lastPathComponent.utf8).write(to: root.appendingPathComponent("pending"))
        let restored = IOSLearningContentStore(root: root)
        #expect(restored.catalog == bundled)
        #expect(restored.assetURLs.isEmpty)
        #expect(try Data(contentsOf: directory.appendingPathComponent("pack.json")) == encoded)
        #expect(restored.catalog.cards(for: .birds).contains { $0.imageAssetName == "MemoryBirdCleanA02" })
    }
}
