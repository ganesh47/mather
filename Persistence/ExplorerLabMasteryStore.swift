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
        storage.removeObject(forKey: storageKey)
    }
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
