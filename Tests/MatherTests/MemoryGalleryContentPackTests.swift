import Foundation
import CryptoKit
import Testing
@testable import Mather

@Suite("Downloadable Memory Gallery content")
struct MemoryGalleryContentPackTests {
    @Test func bundledContentRoundTripsThroughPortableJSON() throws {
        let pack = MemoryGalleryContentPack.bundled
        try pack.validate()
        let data = try JSONEncoder().encode(pack)
        #expect(try JSONDecoder().decode(MemoryGalleryContentPack.self, from: data) == pack)
        let picture = try JSONSerialization.jsonObject(with: JSONEncoder().encode(MemoryPicture.asset("new-image"))) as? [String: String]
        #expect(picture == ["kind": "asset", "value": "new-image"])
    }

    @Test func rejectsUnsupportedSchemaIncompleteDecksAndDuplicateCards() throws {
        let baseline = MemoryGalleryContentPack.bundled
        #expect(throws: (any Error).self) {
            try MemoryGalleryContentPack(schemaVersion: 99, contentVersion: 2, decks: baseline.decks, assets: []).validate()
        }
        #expect(throws: (any Error).self) {
            try MemoryGalleryContentPack(schemaVersion: 1, contentVersion: 2, decks: Array(baseline.decks.dropLast()), assets: []).validate()
        }
        var decks = baseline.decks
        let first = decks[0]
        decks[0] = .init(kind: first.kind, cards: first.cards + [first.cards[0]])
        #expect(throws: (any Error).self) {
            try MemoryGalleryContentPack(schemaVersion: 1, contentVersion: 2, decks: decks, assets: []).validate()
        }
    }

    @Test func rejectsPathTraversalAndOversizedArtwork() throws {
        for asset in [
            MemoryGalleryContentPack.Asset(id: "new", file: "../new.png", byteCount: 10, sha256: String(repeating: "a", count: 64)),
            .init(id: "new", file: "new.png", byteCount: 10_000_001, sha256: String(repeating: "a", count: 64))
        ] {
            #expect(throws: (any Error).self) {
                try MemoryGalleryContentPack(schemaVersion: 1, contentVersion: 2, decks: MemoryGalleryContentPack.bundled.decks, assets: [asset]).validate()
            }
        }
    }

    @Test func sessionUsesDownloadedCardsAndRetainsThemForReplay() {
        let deck = Array(MemoryDeck.domesticAnimals.suffix(4))
        var game = MemoryGalleryTVGame()
        game.start(category: .animals, deck: deck)
        for _ in 0..<6 {
            let round = game.round!
            #expect(deck.contains(round.promptCard))
            game.select(answerID: round.correctAnswerID)
            game.advance()
        }
        #expect(game.phase == .completed)
        game.replay()
        #expect(game.sessionDeck == deck)
        #expect(game.round?.promptCard == deck[0])
    }

    @Test @MainActor func corruptCacheAndInvalidFeedKeepBundledContent() async throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: root) }
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        try Data("../unsafe".utf8).write(to: root.appendingPathComponent("active"))
        let store = MemoryGalleryContentStore(root: root)
        #expect(store.pack == .bundled)
        await store.refresh(from: URL(string: "http://example.com/pack.json")!)
        #expect(store.pack == .bundled)
        #expect(store.lastRefreshError != nil)
    }

    @Test @MainActor func updateCommitsRestoresAndFailedUpdateKeepsLastPack() async throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: root) }
        let baseline = MemoryGalleryContentPack.bundled
        let replacement = MemoryGalleryContentPack(schemaVersion: 1, contentVersion: 2, decks: baseline.decks, assets: [])
        var response = try JSONEncoder().encode(replacement)
        let store = MemoryGalleryContentStore(root: root, fetch: { _, _ in response })
        let url = URL(string: "https://example.com/pack.json")!
        await store.refresh(from: url)
        #expect(store.pack == replacement)
        #expect(MemoryGalleryContentStore(root: root).pack == replacement)
        response = Data("invalid JSON".utf8)
        await store.refresh(from: url)
        #expect(store.lastRefreshError != nil)
        #expect(store.pack == replacement)
        #expect(MemoryGalleryContentStore(root: root).pack == replacement)
    }

    @Test @MainActor func incompleteArtworkAndActiveSessionPreventActivation() async throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: root) }
        let baseline = MemoryGalleryContentPack.bundled
        let missing = MemoryGalleryContentPack.Asset(id: "new", file: "new.png", byteCount: 10, sha256: String(repeating: "a", count: 64))
        var response = try JSONEncoder().encode(MemoryGalleryContentPack(schemaVersion: 1, contentVersion: 2, decks: baseline.decks, assets: [missing]))
        let store = MemoryGalleryContentStore(root: root, fetch: { url, _ in
            if url.pathExtension == "png" { throw MemoryGalleryContentStore.StoreError.invalidDownload }
            return response
        })
        let url = URL(string: "https://example.com/pack.json")!
        await store.refresh(from: url)
        #expect(store.pack == baseline)
        #expect(!FileManager.default.fileExists(atPath: root.appendingPathComponent("active").path))
        response = try JSONEncoder().encode(MemoryGalleryContentPack(schemaVersion: 1, contentVersion: 2, decks: baseline.decks, assets: []))
        await store.refresh(from: url, canActivate: { false })
        #expect(store.pack == baseline)
        #expect(!FileManager.default.fileExists(atPath: root.appendingPathComponent("active").path))
        #expect(FileManager.default.fileExists(atPath: root.appendingPathComponent("pending").path))
        store.activatePending()
        #expect(store.pack.contentVersion == 2)
        #expect(!FileManager.default.fileExists(atPath: root.appendingPathComponent("pending").path))
    }

    @Test @MainActor func stagedUpdateSurvivesRelaunchWithoutReplacingAnActiveSession() async throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: root) }
        let replacement = MemoryGalleryContentPack(schemaVersion: 1, contentVersion: 2, decks: MemoryGalleryContentPack.bundled.decks, assets: [])
        let data = try JSONEncoder().encode(replacement)
        let store = MemoryGalleryContentStore(root: root, fetch: { _, _ in data })
        await store.refresh(from: URL(string: "https://example.com/pack.json")!, canActivate: { false })
        #expect(store.pack == .bundled)
        #expect(MemoryGalleryContentStore(root: root).pack == replacement)
    }

    @Test @MainActor func artworkIsVerifiedCachedAndCorruptionFallsBack() async throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: root) }
        let repo = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
        let image = try Data(contentsOf: repo.appendingPathComponent("App/Assets.xcassets/MemoryFlagIndia.imageset/MemoryFlagIndia.png"))
        let asset = MemoryGalleryContentPack.Asset(id: "MemoryFlagIndia", file: "MemoryFlagIndia.png", byteCount: image.count,
            sha256: SHA256.hash(data: image).map { String(format: "%02x", $0) }.joined())
        let replacement = MemoryGalleryContentPack(schemaVersion: 1, contentVersion: 2, decks: MemoryGalleryContentPack.bundled.decks, assets: [asset])
        let manifest = try JSONEncoder().encode(replacement)
        let store = MemoryGalleryContentStore(root: root, fetch: { url, _ in url.pathExtension == "png" ? image : manifest })
        await store.refresh(from: URL(string: "https://example.com/pack.json")!)
        #expect(store.pack == replacement)
        let file = try #require(store.assetURL(named: asset.id))
        #expect(try Data(contentsOf: file) == image)
        #expect(MemoryGalleryContentStore(root: root).pack == replacement)
        try Data("corrupt".utf8).write(to: file)
        #expect(MemoryGalleryContentStore(root: root).pack == .bundled)
    }
}
