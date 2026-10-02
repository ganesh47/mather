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
    static let defaultStorageKey = "explorerLabMasteryProfiles.v2"
    static let legacyDeviceStorageKey = "explorerLabMasteryProfile.v1"

    private let storage: ExplorerLabMasteryKeyValueStore
    private let storageKey: String
    private let activeProfileIdProvider: () -> String
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    init(
        storage: ExplorerLabMasteryKeyValueStore = UserDefaults.standard,
        storageKey: String = ExplorerLabMasteryStore.defaultStorageKey,
        activeProfileIdProvider: @escaping () -> String = { KidProfilePersistence.defaultProfileId },
        encoder: JSONEncoder = JSONEncoder(),
        decoder: JSONDecoder = JSONDecoder()
    ) {
        self.storage = storage
        self.storageKey = storageKey
        self.activeProfileIdProvider = activeProfileIdProvider
        self.encoder = encoder
        self.decoder = decoder
    }

    /// Legacy device activity remains readable, but cannot become a child's confidence.
    var legacyDeviceHistory: ExplorerLabMasteryProfile? {
        guard let data = storage.data(forKey: Self.legacyDeviceStorageKey) else { return nil }
        return try? decoder.decode(ExplorerLabMasteryProfile.self, from: data)
    }
    func load() -> ExplorerLabMasteryProfile {
        (loadAll()[activeProfileIdProvider()] ?? .emptyExplorerProfile()).withSeededExplorerLanes()
    }
    func save(_ profile: ExplorerLabMasteryProfile) throws {
        var profiles = loadAll(); profiles[activeProfileIdProvider()] = profile.withSeededExplorerLanes()
        storage.set(try encoder.encode(profiles), forKey: storageKey)
    }
    private func loadAll() -> [String: ExplorerLabMasteryProfile] {
        guard let data = storage.data(forKey: storageKey), let profiles = try? decoder.decode([String: ExplorerLabMasteryProfile].self, from: data) else { return [:] }
        return profiles
    }

    @discardableResult
    func update(_ mutation: (inout ExplorerLabMasteryProfile) -> Void) -> ExplorerLabMasteryProfile {
        var profile = load()
        mutation(&profile)
        profile = profile.withSeededExplorerLanes()
        try? save(profile)
        return profile
    }

    @discardableResult
    func markCompleted(laneID: CapabilityLaneID, mode: PlayMode) -> ExplorerLabMasteryProfile {
        update { profile in
            profile.updateLane(laneID) { lane in
                lane.markCompleted(mode)
            }
        }
    }

    @discardableResult
    func markReviewedCard(laneID: CapabilityLaneID, cardID: String) -> ExplorerLabMasteryProfile {
        update { profile in
            profile.updateLane(laneID) { lane in
                lane.markReviewedCard(id: cardID)
            }
        }
    }

    @discardableResult
    func setConfidence(
        _ confidence: ConceptConfidence,
        for conceptID: ConceptId,
        laneID: CapabilityLaneID
    ) -> ExplorerLabMasteryProfile {
        update { profile in
            profile.updateLane(laneID) { lane in
                lane.setConfidence(confidence, for: conceptID)
            }
        }
    }

    func reset() {
        var profiles = loadAll(); profiles.removeValue(forKey: activeProfileIdProvider())
        if profiles.isEmpty { storage.removeObject(forKey: storageKey) }
        else if let data = try? encoder.encode(profiles) { storage.set(data, forKey: storageKey) }
    }
    func resetAll() { storage.removeObject(forKey: storageKey) }

}

extension ExplorerLabMasteryProfile {
    mutating func updateLane(_ laneID: CapabilityLaneID, _ mutation: (inout LaneMasteryState) -> Void) {
        guard let descriptor = CapabilityLaneRegistry.all.first(where: { $0.id == laneID }) else { return }
        var lane = lanes[laneID] ?? LaneMasteryState(
            laneID: descriptor.id,
            availableModes: descriptor.supportedPlayModes,
            conceptConfidence: Dictionary(uniqueKeysWithValues: descriptor.starterConcepts.map { ($0, .introduced) })
        )
        mutation(&lane)
        lanes[laneID] = lane
    }

    func withSeededExplorerLanes() -> ExplorerLabMasteryProfile {
        var profile = self
        for descriptor in CapabilityLaneRegistry.all {
            _ = profile.ensureLane(descriptor)
        }
        return profile
    }
}
