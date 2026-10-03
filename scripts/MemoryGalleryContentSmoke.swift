import Foundation

/// Exercise the production HTTPS feed plus the exported local artwork through the shipped loader.
@main
struct MemoryGalleryContentSmoke {
    enum Failure: Error { case check(String) }

    @MainActor
    static func main() async throws {
        let feed = URL(string: "https://raw.githubusercontent.com/ganesh47/mather-content/main/memory-gallery/pack.json")!
        let root = FileManager.default.temporaryDirectory.appendingPathComponent("mather-content-smoke-\(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(at: root) }
        let store = MemoryGalleryContentStore(root: root)
        await store.refresh(from: feed)
        guard store.lastRefreshError == nil else {
            throw Failure.check("Public feed failed validation: \(store.lastRefreshError!)")
        }
        try store.pack.validate()
        if store.pack.contentVersion > MemoryGalleryContentPack.bundled.contentVersion {
            guard !store.pack.assets.isEmpty else { throw Failure.check("New public feed has no artwork") }
            try verifyAssets(store)
            print("Public newer feed activated v\(store.pack.contentVersion), verified \(store.pack.assets.count) PNGs")
        } else {
            guard store.pack == .bundled else { throw Failure.check("Old public feed replaced bundled content") }
            print("PASS: valid public older/equal feed retained fresh bundled v\(store.pack.contentVersion)")
        }
        try playAllCategories(store)
        let restored = MemoryGalleryContentStore(root: root, fetch: { _, _ in throw URLError(.notConnectedToInternet) })
        guard restored.pack == store.pack else { throw Failure.check("Offline cache restore failed") }
        await restored.refresh(from: feed)
        guard restored.pack == store.pack, restored.lastRefreshError != nil else {
            throw Failure.check("Offline refresh discarded content")
        }

        let repo = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent()
        let input = CommandLine.arguments.count > 1 ? URL(fileURLWithPath: CommandLine.arguments[1])
            : repo.appendingPathComponent("Content/MemoryGallery/pack.json")
        let exported = try JSONDecoder().decode(MemoryGalleryContentPack.self, from: Data(contentsOf: input))
        try exported.validate()
        guard exported.contentVersion == MemoryGalleryContentPack.bundled.contentVersion,
              !exported.assets.isEmpty else { throw Failure.check("Local export must match bundled version and include artwork") }
        // Increment only the in-memory test version so refresh exercises its complete upgrade path.
        let upgrade = MemoryGalleryContentPack(schemaVersion: exported.schemaVersion,
            contentVersion: exported.contentVersion + 1, decks: exported.decks, assets: exported.assets)
        let manifest = try JSONEncoder().encode(upgrade)
        let localRoot = FileManager.default.temporaryDirectory.appendingPathComponent("mather-local-content-smoke-\(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(at: localRoot) }
        let localStore = MemoryGalleryContentStore(root: localRoot, fetch: { url, _ in
            if url.pathExtension == "json" { return manifest }
            let external = input.deletingLastPathComponent().appendingPathComponent(url.lastPathComponent)
            let file = FileManager.default.fileExists(atPath: external.path) ? external
                : repo.appendingPathComponent("App/Assets.xcassets/\(url.deletingPathExtension().lastPathComponent).imageset/\(url.lastPathComponent)")
            return try Data(contentsOf: file)
        })
        await localStore.refresh(from: URL(string: "https://local-smoke.example/pack.json")!)
        guard localStore.pack == upgrade, localStore.lastRefreshError == nil else {
            throw Failure.check("Local artwork upgrade failed: \(localStore.lastRefreshError ?? "no activation")")
        }
        try verifyAssets(localStore)
        try playAllCategories(localStore)
        let offline = MemoryGalleryContentStore(root: localRoot, fetch: { _, _ in throw URLError(.notConnectedToInternet) })
        guard offline.pack == upgrade else { throw Failure.check("Valid newer local cache failed offline restore") }
        print("PASS: local export v\(exported.contentVersion) verified \(exported.assets.count) PNGs and all categories; injected test upgrade v\(upgrade.contentVersion) retained offline")
    }

    @MainActor
    private static func verifyAssets(_ store: MemoryGalleryContentStore) throws {
        for asset in store.pack.assets {
            guard let file = store.assetURL(named: asset.id) else { throw Failure.check("Missing cached artwork") }
            try MemoryGalleryContentStore.validateArtwork(Data(contentsOf: file), asset: asset)
        }
    }

    @MainActor
    private static func playAllCategories(_ store: MemoryGalleryContentStore) throws {
        for category in MemoryGalleryTVCategory.allCases {
            let cards = store.cards(for: category)
            var game = MemoryGalleryTVGame()
            game.start(category: category, deck: cards)
            for _ in 0..<game.roundGoal {
                guard let round = game.round, cards.contains(round.promptCard),
                      round.answerChoices.count == 4, !round.learningFacts.isEmpty else {
                    throw Failure.check("Deck cannot generate a playable round")
                }
                guard game.select(answerID: round.correctAnswerID) else { throw Failure.check("Answer rejected") }
                game.advance()
            }
            guard game.phase == .completed, game.correctCount == game.roundGoal else {
                throw Failure.check("Session did not complete")
            }
        }
    }
}
