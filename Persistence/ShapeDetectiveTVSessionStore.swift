import Foundation

/// A slice-owned checkpoint. The shared ledger receives events through callbacks.
@MainActor
final class ShapeDetectiveTVSessionStore {
    private let defaults: UserDefaults
    let profileID: String
    private var key: String { "mather.shape-detective.v1.\(profileID)" }
    private var probeKey: String { "\(key).used-probes" }

    init(defaults: UserDefaults = .standard, profileID: String = "tv-family") {
        self.defaults = defaults
        self.profileID = profileID
    }

    var usedProbeIDs: Set<String> { Set(defaults.stringArray(forKey: probeKey) ?? []) }

    func reserveProbe(_ id: String) {
        guard ShapeDetectiveCatalog.probe(id: id) != nil else { return }
        defaults.set(Array(usedProbeIDs.union([id])).sorted(), forKey: probeKey)
    }

    /// Called only by the parent-controlled reset action for this frozen scope.
    func clear() {
        defaults.removeObject(forKey: key)
        defaults.removeObject(forKey: probeKey)
    }

    func load() -> ShapeDetectiveCheckpoint? {
        guard let data = defaults.data(forKey: key),
              let value = try? JSONDecoder().decode(ShapeDetectiveCheckpoint.self, from: data),
              value.isValid(for: profileID) else { return nil }
        return value
    }

    func save(_ checkpoint: ShapeDetectiveCheckpoint) {
        guard checkpoint.isValid(for: profileID), let data = try? JSONEncoder().encode(checkpoint) else { return }
        defaults.set(data, forKey: key)
    }
}
