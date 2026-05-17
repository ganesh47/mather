import Foundation
import Testing
@testable import Mather

struct SwiftDataStoreRecoveryTests {
    @Test
    func quarantineOnlyMovesConfiguredStoreFiles() throws {
        let tempRoot = FileManager.default.temporaryDirectory
            .appendingPathComponent("MatherStoreRecoveryTests-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: tempRoot, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempRoot) }

        let storeURL = tempRoot.appendingPathComponent("Mather.sqlite")
        let unrelatedSQLiteURL = tempRoot.appendingPathComponent("Other.sqlite")
        let unrelatedWALURL = tempRoot.appendingPathComponent("Other.sqlite-wal")

        for url in [
            storeURL,
            URL(fileURLWithPath: storeURL.path + "-shm"),
            URL(fileURLWithPath: storeURL.path + "-wal"),
            unrelatedSQLiteURL,
            unrelatedWALURL
        ] {
            try Data(url.lastPathComponent.utf8).write(to: url)
        }

        SwiftDataStoreRecovery.quarantineStore(
            at: storeURL,
            date: Date(timeIntervalSince1970: 1_771_200_000)
        )

        #expect(!FileManager.default.fileExists(atPath: storeURL.path))
        #expect(!FileManager.default.fileExists(atPath: storeURL.path + "-shm"))
        #expect(!FileManager.default.fileExists(atPath: storeURL.path + "-wal"))
        #expect(FileManager.default.fileExists(atPath: unrelatedSQLiteURL.path))
        #expect(FileManager.default.fileExists(atPath: unrelatedWALURL.path))

        let quarantineRoot = tempRoot.appendingPathComponent(SwiftDataStoreRecovery.quarantineDirectoryName)
        let quarantinedFiles = try FileManager.default
            .subpathsOfDirectory(atPath: quarantineRoot.path)
            .filter { !$0.hasSuffix("/") }

        #expect(quarantinedFiles.contains { $0.hasSuffix("Mather.sqlite") })
        #expect(quarantinedFiles.contains { $0.hasSuffix("Mather.sqlite-shm") })
        #expect(quarantinedFiles.contains { $0.hasSuffix("Mather.sqlite-wal") })
        #expect(!quarantinedFiles.contains { $0.hasSuffix("Other.sqlite") })
    }
}
