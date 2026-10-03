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
        guard store.lastRefreshError == nil, store.catalog.contentVersion == IOSLearningCatalog.bundled.contentVersion else {
            throw Failure.check("Download or deferred activation failed: \(store.lastRefreshError ?? "unexpected activation")")
        }
        store.activatePending()
        guard store.catalog.contentVersion >= IOSLearningCatalog.bundled.contentVersion,
              store.catalog.decks.count == 11, store.catalog.threads.count == 7 else {
            throw Failure.check("Fresh bundled or newer external iOS catalog was not retained")
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

        if CommandLine.arguments.count > 2 {
            let input = URL(fileURLWithPath: CommandLine.arguments[2])
            let exported = try JSONDecoder().decode(IOSLearningCatalog.self, from: Data(contentsOf: input))
            try exported.validate()
            guard exported.contentVersion == IOSLearningCatalog.bundled.contentVersion,
                  !exported.assets.isEmpty else { throw Failure.check("Export must match the bundle and supply PNGs") }
            // A synthetic higher version exercises downloading/activation; it
            // never changes the published catalog or its actual version.
            let upgrade = IOSLearningCatalog(schemaVersion: exported.schemaVersion,
                contentVersion: exported.contentVersion + 1, decks: exported.decks,
                threads: exported.threads, assets: exported.assets)
            let manifest = try JSONEncoder().encode(upgrade)
            let localRoot = root.appendingPathComponent("local-upgrade")
            let local = IOSLearningContentStore(root: localRoot, fetch: { url, _ in
                url.pathExtension == "png"
                    ? try Data(contentsOf: input.deletingLastPathComponent().appendingPathComponent(url.lastPathComponent)) : manifest
            })
            await local.refresh(from: URL(string: "https://example.com/ios/catalog.json")!, canActivate: { false })
            guard local.catalog == .bundled, local.lastRefreshError == nil else {
                throw Failure.check("Export download/deferred activation failed")
            }
            local.activatePending()
            guard local.catalog == upgrade else { throw Failure.check("Export did not activate") }
            for asset in upgrade.assets {
                guard let url = local.assetURL(named: asset.id) else { throw Failure.check("Export artwork missing") }
                try IOSLearningContentStore.validateArtwork(Data(contentsOf: url), asset: asset)
            }
            let offline = IOSLearningContentStore(root: localRoot, fetch: { _, _ in throw URLError(.notConnectedToInternet) })
            guard offline.catalog == upgrade else { throw Failure.check("Export offline restoration failed") }
            await offline.refresh(from: feed)
            guard offline.catalog == upgrade, offline.lastRefreshError != nil else {
                throw Failure.check("Offline refresh lost exported content")
            }
            print("PASS: local iOS v\(exported.contentVersion), \(exported.assets.count) PNGs; complete deferred upgrade and offline restore")
        }
    }
}
