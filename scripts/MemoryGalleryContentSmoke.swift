import Foundation

/// Run against the public feed using the same loader shipped in Mather TV.
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
        guard store.pack.contentVersion > MemoryGalleryContentPack.bundled.contentVersion,
              store.lastRefreshError == nil, !store.pack.assets.isEmpty else {
            throw Failure.check("Public pack did not activate: \(store.lastRefreshError ?? "no newer content")")
        }
        try store.pack.validate()
        for asset in store.pack.assets {
            guard let file = store.assetURL(named: asset.id) else { throw Failure.check("Missing cached artwork") }
            try MemoryGalleryContentStore.validateArtwork(Data(contentsOf: file), asset: asset)
        }
        for category in MemoryGalleryTVCategory.allCases {
            let cards = store.cards(for: category)
            var game = MemoryGalleryTVGame()
            game.start(category: category, deck: cards)
            for _ in 0..<game.roundGoal {
                guard let round = game.round, cards.contains(round.promptCard),
                      round.answerChoices.count == 4, !round.learningFacts.isEmpty else {
                    throw Failure.check("Downloaded deck cannot generate a playable round")
                }
                guard game.select(answerID: round.correctAnswerID) else { throw Failure.check("Answer rejected") }
                game.advance()
            }
            guard game.phase == .completed, game.correctCount == game.roundGoal else {
                throw Failure.check("Session did not complete")
            }
            print("\(category.title): \(cards.count) downloaded cards, \(game.roundGoal) rounds completed")
        }
        // A new store restores from disk; a network failure must preserve it.
        let restored = MemoryGalleryContentStore(root: root, fetch: { _, _ in throw URLError(.notConnectedToInternet) })
        guard restored.pack == store.pack else { throw Failure.check("Offline cache restore failed") }
        await restored.refresh(from: feed)
        guard restored.pack == store.pack, restored.lastRefreshError != nil else {
            throw Failure.check("Offline refresh discarded cached content")
        }
        print("PASS: production HTTPS loader activated content v\(store.pack.contentVersion), verified \(store.pack.assets.count) PNGs, played all categories, and retained the offline cache")
    }
}
