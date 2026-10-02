import Foundation

@main
struct IOSLearningContentSmoke {
    enum Failure: Error { case check(String) }
    @MainActor static func main() async throws {
        let feed = URL(string: CommandLine.arguments.dropFirst().first
            ?? "https://raw.githubusercontent.com/ganesh47/mather-content/main/ios/catalog.json")!
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: root) }
        let store = IOSLearningContentStore(root: root)
        await store.refresh(from: feed, canActivate: { false })
        guard store.lastRefreshError == nil, store.catalog.contentVersion == 1 else {
            throw Failure.check("Download or deferred activation failed: \(store.lastRefreshError ?? "unexpected activation")")
        }
        store.activatePending()
        guard store.catalog.contentVersion > 1, store.catalog.decks.count == 11, store.catalog.threads.count == 7 else {
            throw Failure.check("External iOS catalog did not activate")
        }
        try store.catalog.validate()
        for asset in store.catalog.assets {
            guard let url = store.assetURL(named: asset.id) else { throw Failure.check("Missing artwork") }
            try IOSLearningContentStore.validateArtwork(Data(contentsOf: url), asset: asset)
        }
        let restored = IOSLearningContentStore(root: root, fetch: { _, _ in throw URLError(.notConnectedToInternet) })
        guard restored.catalog == store.catalog else { throw Failure.check("Offline cache differs") }
        await restored.refresh(from: feed)
        guard restored.catalog == store.catalog, restored.lastRefreshError != nil else { throw Failure.check("Offline fallback failed") }
        print("PASS: external iOS catalog v\(store.catalog.contentVersion), 11 decks, 7 topics, \(store.catalog.assets.count) verified images; deferred activation and offline restore")
    }
}
