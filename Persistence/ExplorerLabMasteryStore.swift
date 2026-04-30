import Foundation

protocol ExplorerLabMasteryKeyValueStore: AnyObject {
    func data(forKey defaultName: String) -> Data?
    func set(_ value: Data?, forKey defaultName: String)
    func removeObject(forKey defaultName: String)
}

extension UserDefaults: ExplorerLabMasteryKeyValueStore {
    func set(_ value: Data?, forKey defaultName: String) {
        if let value {
            set(value as Any, forKey: defaultName)
        } else {
            removeObject(forKey: defaultName)
        }
    }
}

final class ExplorerLabMasteryStore {
    static let defaultStorageKey = "explorerLabMasteryProfile.v1"

    private let storage: ExplorerLabMasteryKeyValueStore
    private let storageKey: String
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    init(
        storage: ExplorerLabMasteryKeyValueStore = UserDefaults.standard,
        storageKey: String = ExplorerLabMasteryStore.defaultStorageKey,
        encoder: JSONEncoder = JSONEncoder(),
        decoder: JSONDecoder = JSONDecoder()
    ) {
        self.storage = storage
        self.storageKey = storageKey
        self.encoder = encoder
        self.decoder = decoder
    }

    func load() -> ExplorerLabMasteryProfile {
        guard let data = storage.data(forKey: storageKey),
              let profile = try? decoder.decode(ExplorerLabMasteryProfile.self, from: data)
        else {
            return .emptyExplorerProfile()
        }

        return profile.withSeededExplorerLanes()
    }

    func save(_ profile: ExplorerLabMasteryProfile) throws {
        let data = try encoder.encode(profile.withSeededExplorerLanes())
        storage.set(data, forKey: storageKey)
    }

    func reset() {
        storage.removeObject(forKey: storageKey)
    }
}

extension ExplorerLabMasteryProfile {
    func withSeededExplorerLanes() -> ExplorerLabMasteryProfile {
        var profile = self
        for descriptor in CapabilityLaneRegistry.all {
            _ = profile.ensureLane(descriptor)
        }
        return profile
    }
}
