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
            for asset in candidate.assets {
                try Task.checkCancellation()
                let assetURL = url.deletingLastPathComponent().appendingPathComponent(asset.file)
                let image = try await download(assetURL, session: session, limit: asset.byteCount)
                try Self.validateArtwork(image, asset: asset)
                try image.write(to: directory.appendingPathComponent(asset.file), options: .atomic)
            }
            try data.write(to: directory.appendingPathComponent("pack.json"), options: .atomic)
            try Task.checkCancellation()
            guard canActivate() else { throw CancellationError() }
            // Commit only after every asset and the manifest have been written.
            try Data(directory.lastPathComponent.utf8).write(to: root.appendingPathComponent("active"), options: .atomic)
            let previousDirectory = activeDirectory
            pack = candidate
            activeDirectory = directory
            staging = nil
            lastRefreshError = nil
            if let previousDirectory { try? FileManager.default.removeItem(at: previousDirectory) }
        } catch {
            if let staging { try? FileManager.default.removeItem(at: staging) }
            lastRefreshError = String(describing: error)
        }
    }

    private func restore() {
        do {
            let id = try String(contentsOf: root.appendingPathComponent("active"), encoding: .utf8)
            guard UUID(uuidString: id) != nil else { return }
            let directory = root.appendingPathComponent(id, isDirectory: true)
            let data = try Data(contentsOf: directory.appendingPathComponent("pack.json"))
            guard data.count <= 5_000_000 else { return }
            let candidate = try JSONDecoder().decode(MemoryGalleryContentPack.self, from: data)
            try candidate.validate()
            for asset in candidate.assets {
                let file = directory.appendingPathComponent(asset.file)
                let size = try file.resourceValues(forKeys: [.fileSizeKey]).fileSize
                guard size == asset.byteCount else { throw StoreError.invalidDownload }
                try Self.validateArtwork(Data(contentsOf: file), asset: asset)
            }
            pack = candidate
            activeDirectory = directory
        } catch {
            // Missing, purged, or invalid cache always falls back to bundled content.
        }
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
