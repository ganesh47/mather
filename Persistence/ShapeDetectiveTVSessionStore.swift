import Foundation

enum ShapeDetectiveStorageIssue: String, Equatable {
    case unsupportedCheckpoint, corruptCheckpoint, corruptProbeHistory, inconsistentProbeHistory
}

enum ShapeDetectiveStorageState: Equatable {
    case empty
    case ready(ShapeDetectiveCheckpoint)
    case blocked(ShapeDetectiveStorageIssue)
}

/// A slice-owned checkpoint. Unsupported bytes are preserved until parent reset.
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

    /// An unreadable history is conservatively treated as all probes used, never
    /// as an empty history. Gameplay also blocks while its storage is unreadable.
    var usedProbeIDs: Set<String> { validatedProbeIDs ?? Set(ShapeDetectiveCatalog.probes.map(\.id)) }

    private var validatedProbeIDs: Set<String>? {
        guard let object = defaults.object(forKey: probeKey) else { return [] }
        guard let values = object as? [String], Set(values).count == values.count,
              values.allSatisfy({ ShapeDetectiveCatalog.probe(id: $0) != nil }) else { return nil }
        return Set(values)
    }

    func loadState() -> ShapeDetectiveStorageState {
        guard let history = validatedProbeIDs else { return .blocked(.corruptProbeHistory) }
        guard let object = defaults.object(forKey: key) else { return .empty }
        guard let data = object as? Data else { return .blocked(.corruptCheckpoint) }
        if let header = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let version = header["version"] as? Int, version != ShapeDetectiveCatalog.version {
            return .blocked(.unsupportedCheckpoint)
        }
        guard let value = try? JSONDecoder().decode(ShapeDetectiveCheckpoint.self, from: data),
              value.isValid(for: profileID) else { return .blocked(.corruptCheckpoint) }
        guard hasConsistentProbeHistory(value, history: history) else {
            return .blocked(.inconsistentProbeHistory)
        }
        return .ready(value)
    }

    @discardableResult
    func reserveProbe(_ id: String) -> Bool {
        guard ShapeDetectiveCatalog.probe(id: id) != nil, let history = validatedProbeIDs,
              !isBlocked else { return false }
        defaults.set(Array(history.union([id])).sorted(), forKey: probeKey)
        return true
    }

    /// The only operation allowed to remove unsupported/corrupt data. The root
    /// calls this from an explicit parent-controlled reset for this frozen scope.
    func clear() {
        defaults.removeObject(forKey: key)
        defaults.removeObject(forKey: probeKey)
    }

    func load() -> ShapeDetectiveCheckpoint? {
        if case .ready(let value) = loadState() { return value }
        return nil
    }

    private var isBlocked: Bool {
        if case .blocked = loadState() { return true }
        return false
    }

    private func hasConsistentProbeHistory(_ value: ShapeDetectiveCheckpoint, history: Set<String>) -> Bool {
        let exposed = value.attempts.contains { $0.itemVariantID == value.probeID && $0.outcome == .exposure }
        return (!(exposed || !value.probeIsFresh) || history.contains(value.probeID)) &&
            !(value.probeIsFresh && value.index < 6 && history.contains(value.probeID))
    }

    @discardableResult
    func save(_ checkpoint: ShapeDetectiveCheckpoint) -> Bool {
        guard !isBlocked, checkpoint.isValid(for: profileID), let history = validatedProbeIDs,
              hasConsistentProbeHistory(checkpoint, history: history),
              let data = try? JSONEncoder().encode(checkpoint) else { return false }
        defaults.set(data, forKey: key)
        return true
    }
}
