import Foundation

enum SwiftDataStoreRecovery {
    static let storeFileName = "Mather.sqlite"
    static let quarantineDirectoryName = "MatherSwiftDataStoreQuarantine"

    static func defaultStoreURL(fileManager: FileManager = .default) -> URL {
        let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
        return (appSupport ?? URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true))
            .appendingPathComponent(storeFileName, isDirectory: false)
    }

    static func relatedStoreURLs(for storeURL: URL) -> [URL] {
        [
            storeURL,
            URL(fileURLWithPath: storeURL.path + "-shm"),
            URL(fileURLWithPath: storeURL.path + "-wal")
        ]
    }

    static func quarantineStore(
        at storeURL: URL,
        fileManager: FileManager = .default,
        date: Date = Date()
    ) {
        let quarantineRoot = storeURL.deletingLastPathComponent()
            .appendingPathComponent(quarantineDirectoryName, isDirectory: true)
        let quarantineDirectory = quarantineRoot
            .appendingPathComponent(timestamp(for: date), isDirectory: true)

        do {
            try fileManager.createDirectory(
                at: quarantineDirectory,
                withIntermediateDirectories: true
            )
        } catch {
            return
        }

        for url in relatedStoreURLs(for: storeURL) where fileManager.fileExists(atPath: url.path) {
            let destination = quarantineDirectory.appendingPathComponent(url.lastPathComponent)
            try? fileManager.moveItem(at: url, to: destination)
        }
    }

    private static func timestamp(for date: Date) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter.string(from: date)
            .replacingOccurrences(of: ":", with: "-")
    }
}
