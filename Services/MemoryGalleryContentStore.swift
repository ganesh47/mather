import CryptoKit
import Foundation
import ImageIO
import Observation

@MainActor
@Observable
final class MemoryGalleryContentStore {
    private(set) var pack = MemoryGalleryContentPack.bundled
    private(set) var lastRefreshError: String?
    private var activeDirectory: URL?
    private var refreshing = false
    private var pending: (pack: MemoryGalleryContentPack, directory: URL)?
    private let root: URL
    private let fetch: (@MainActor (URL, Int) async throws -> Data)?

    init(root: URL? = nil, fetch: (@MainActor (URL, Int) async throws -> Data)? = nil) {
        self.fetch = fetch
        self.root = root ?? FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("MemoryGalleryContent", isDirectory: true)
        restore()
    }

    func cards(for category: MemoryGalleryTVCategory) -> [MemoryAnimal] {
        pack.cards(for: category)
    }

    func assetURL(named id: String) -> URL? {
        guard let asset = pack.assets.first(where: { $0.id == id }), let activeDirectory else { return nil }
        return activeDirectory.appendingPathComponent(asset.file)
    }

    func refresh(from url: URL, canActivate: @MainActor () -> Bool = { true }) async {
        guard !refreshing else { return }
        refreshing = true
        defer { refreshing = false }
        var staging: URL?
        do {
            if canActivate() { activatePending() }
            guard url.scheme == "https", let host = url.host, url.user == nil, url.password == nil else {
                throw StoreError.invalidDownload
            }
            let delegate = GalleryDownloadDelegate(host: host)
            let configuration = URLSessionConfiguration.ephemeral
            configuration.timeoutIntervalForRequest = 30
            configuration.timeoutIntervalForResource = 120
            let session = URLSession(configuration: configuration, delegate: delegate, delegateQueue: nil)
            defer { session.invalidateAndCancel() }
            let data = try await download(url, session: session, limit: 5_000_000)
            let candidate = try JSONDecoder().decode(MemoryGalleryContentPack.self, from: data)
            try candidate.validate()
            guard candidate.contentVersion > pack.contentVersion else {
                lastRefreshError = nil
                return
            }
            try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
            let directory = root.appendingPathComponent(UUID().uuidString, isDirectory: true)
            staging = directory
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            try await downloadArtwork(candidate.assets, from: url, session: session, into: directory)
            try data.write(to: directory.appendingPathComponent("pack.json"), options: .atomic)
            try Task.checkCancellation()
            if canActivate() {
                try activate(candidate, from: directory)
            } else {
                try Data(directory.lastPathComponent.utf8).write(to: root.appendingPathComponent("pending"), options: .atomic)
                let previous = pending?.directory
                pending = (candidate, directory)
                if let previous { try? FileManager.default.removeItem(at: previous) }
            }
            staging = nil
            lastRefreshError = nil
        } catch {
            if let staging { try? FileManager.default.removeItem(at: staging) }
            lastRefreshError = String(describing: error)
        }
    }

    /// Call only at a session boundary, so card and image snapshots stay stable.
    func activatePending() {
        guard let pending else { return }
        do {
            try activate(pending.pack, from: pending.directory)
            self.pending = nil
            try? FileManager.default.removeItem(at: root.appendingPathComponent("pending"))
        } catch { lastRefreshError = String(describing: error) }
    }

    private func activate(_ candidate: MemoryGalleryContentPack, from directory: URL) throws {
        // Commit only after every asset and the manifest have been written.
        try Data(directory.lastPathComponent.utf8).write(to: root.appendingPathComponent("active"), options: .atomic)
        let previousDirectory = activeDirectory
        pack = candidate
        activeDirectory = directory
        if let previousDirectory, previousDirectory != directory { try? FileManager.default.removeItem(at: previousDirectory) }
        if let pending, pending.directory != directory { try? FileManager.default.removeItem(at: pending.directory) }
        pending = nil
        try? FileManager.default.removeItem(at: root.appendingPathComponent("pending"))
    }

    private func downloadArtwork(_ assets: [MemoryGalleryContentPack.Asset], from url: URL,
                                 session: URLSession, into directory: URL) async throws {
        // Bound concurrency and memory while avoiding 82 serial HTTPS handshakes.
        try await withThrowingTaskGroup(of: (String, Data).self) { group in
            var nextIndex = 0
            while nextIndex < min(6, assets.count) {
                let asset = assets[nextIndex]
                group.addTask { try await self.fetchArtwork(asset, from: url, session: session) }
                nextIndex += 1
            }
            for try await (file, data) in group {
                try Task.checkCancellation()
                try data.write(to: directory.appendingPathComponent(file), options: .atomic)
                if nextIndex < assets.count {
                    let asset = assets[nextIndex]
                    group.addTask { try await self.fetchArtwork(asset, from: url, session: session) }
                    nextIndex += 1
                }
            }
        }
    }

    private func fetchArtwork(_ asset: MemoryGalleryContentPack.Asset, from url: URL,
                              session: URLSession) async throws -> (String, Data) {
        let assetURL = url.deletingLastPathComponent().appendingPathComponent(asset.file)
        let data = try await download(assetURL, session: session, limit: asset.byteCount)
        try Self.validateArtwork(data, asset: asset)
        return (asset.file, data)
    }

    private func restore() {
        do {
            let cached = try readStoredPack(pointer: "active")
            // A newer app bundle must not restore older artwork from a previous feed.
            if cached.pack.contentVersion >= MemoryGalleryContentPack.bundled.contentVersion {
                pack = cached.pack
                activeDirectory = cached.directory
            }
        } catch {
            // Missing, purged, or invalid cache always falls back to bundled content.
        }
        if let cached = try? readStoredPack(pointer: "pending"), cached.pack.contentVersion > pack.contentVersion {
            pending = cached
            activatePending()
        }
    }

    private func readStoredPack(pointer: String) throws -> (pack: MemoryGalleryContentPack, directory: URL) {
        let id = try String(contentsOf: root.appendingPathComponent(pointer), encoding: .utf8)
        guard UUID(uuidString: id) != nil else { throw StoreError.invalidDownload }
        let directory = root.appendingPathComponent(id, isDirectory: true)
        let data = try Data(contentsOf: directory.appendingPathComponent("pack.json"))
        guard data.count <= 5_000_000 else { throw StoreError.invalidDownload }
        let candidate = try JSONDecoder().decode(MemoryGalleryContentPack.self, from: data)
        try candidate.validate()
        for asset in candidate.assets {
            let file = directory.appendingPathComponent(asset.file)
            let size = try file.resourceValues(forKeys: [.fileSizeKey]).fileSize
            guard size == asset.byteCount else { throw StoreError.invalidDownload }
            try Self.validateArtwork(Data(contentsOf: file), asset: asset)
        }
        return (candidate, directory)
    }

    private func download(_ url: URL, session: URLSession, limit: Int) async throws -> Data {
        if let fetch {
            let data = try await fetch(url, limit)
            guard data.count <= limit else { throw StoreError.invalidDownload }
            return data
        }
        let (bytes, response) = try await session.bytes(from: url)
        guard let response = response as? HTTPURLResponse, response.statusCode == 200,
              response.url?.scheme == "https", response.url?.host == url.host,
              response.expectedContentLength <= Int64(limit) else { throw StoreError.invalidDownload }
        var data = Data()
        for try await byte in bytes {
            guard data.count < limit else { throw StoreError.invalidDownload }
            data.append(byte)
        }
        return data
    }

    static func validateArtwork(_ data: Data, asset: MemoryGalleryContentPack.Asset) throws {
        guard data.count == asset.byteCount,
              SHA256.hash(data: data).map({ String(format: "%02x", $0) }).joined() == asset.sha256,
              data.starts(with: [137, 80, 78, 71, 13, 10, 26, 10]),
              let source = CGImageSourceCreateWithData(data as CFData, nil),
              let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any],
              let width = properties[kCGImagePropertyPixelWidth] as? Int,
              let height = properties[kCGImagePropertyPixelHeight] as? Int,
              (1...4096).contains(width), (1...4096).contains(height),
              CGImageSourceCreateImageAtIndex(source, 0, nil) != nil else { throw StoreError.invalidDownload }
    }

    enum StoreError: Error { case invalidDownload }
}

/// Reject cross-host or HTTP redirects before the request is sent.
private final class GalleryDownloadDelegate: NSObject, URLSessionTaskDelegate {
    private let host: String
    init(host: String) { self.host = host }

    func urlSession(_ session: URLSession, task: URLSessionTask,
                    willPerformHTTPRedirection response: HTTPURLResponse,
                    newRequest request: URLRequest,
                    completionHandler: @escaping (URLRequest?) -> Void) {
        let url = request.url
        completionHandler(url?.scheme == "https" && url?.host == host && url?.user == nil && url?.password == nil ? request : nil)
    }
}
