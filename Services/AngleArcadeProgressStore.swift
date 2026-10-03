import Foundation

struct AngleArcadeCompletion: Codable, Equatable {
    var assisted: Bool = false
    var independent: Bool = false
}

struct AngleArcadeProgress: Codable, Equatable {
    var schemaVersion = 1
    var completions: [String: AngleArcadeCompletion] = [:]
    var attemptCounts: [String: Int] = [:]
    var helpCounts: [String: Int] = [:]
    var lastLevelID: String?

    func hasCompleted(_ id: String) -> Bool { completions[id] != nil }
    func completion(for id: String) -> AngleArcadeCompletion? { completions[id] }
    func completedCount(in world: AngleArcadeWorld) -> Int {
        AngleArcadeCampaign.levels(in: world).filter { hasCompleted($0.id) }.count
    }
    var nextSuggestedLevelID: String {
        AngleArcadeCampaign.levels.first { !hasCompleted($0.id) }?.id ?? AngleArcadeCampaign.levels[0].id
    }
}

@MainActor
final class AngleArcadeProgressStore {
    enum StorageState: Equatable { case missing, loaded, unsupported }

    private let defaults: UserDefaults
    let scope: String
    private(set) var storageState: StorageState = .missing
    private var key: String { "mather.angle-arcade.progress.v1.\(scope)" }

    var storageIssueMessage: String? {
        storageState == .unsupported
            ? "Angle progress cannot be read by this version. It has been kept unchanged. Ask a parent to restore it or choose to clear Angle progress."
            : nil
    }

    init(defaults: UserDefaults = .standard, scope: String = "tv") {
        self.defaults = defaults
        self.scope = scope
    }

    func load() -> AngleArcadeProgress? {
        guard let object = defaults.object(forKey: key) else {
            storageState = .missing
            return AngleArcadeProgress()
        }
        guard let data = object as? Data,
              hasOnlyKnownFields(data),
              let value = try? JSONDecoder().decode(AngleArcadeProgress.self, from: data),
              value.schemaVersion == 1,
              validated(value) == value else {
            storageState = .unsupported
            return nil
        }
        storageState = .loaded
        return value
    }

    @discardableResult
    func save(_ progress: AngleArcadeProgress) -> Bool {
        // Re-read before every write, including from an already running engine.
        // A different store instance may have restored a newer payload meanwhile.
        guard load() != nil, progress.schemaVersion == 1,
              let data = try? JSONEncoder().encode(validated(progress)) else { return false }
        defaults.set(data, forKey: key)
        storageState = .loaded
        return true
    }

    /// Call only from an explicit parent-confirmed reset. No other scope is cleared.
    func clear() {
        defaults.removeObject(forKey: key)
        storageState = .missing
    }

    private func hasOnlyKnownFields(_ data: Data) -> Bool {
        guard let object = try? JSONSerialization.jsonObject(with: data),
              let root = object as? [String: Any],
              Set(root.keys).isSubset(of: ["schemaVersion", "completions", "attemptCounts", "helpCounts", "lastLevelID"]),
              let completions = root["completions"] as? [String: Any] else { return false }
        for object in completions.values {
            guard let completion = object as? [String: Any],
                  Set(completion.keys).isSubset(of: ["assisted", "independent"]) else { return false }
        }
        return true
    }

    private func validated(_ value: AngleArcadeProgress) -> AngleArcadeProgress {
        let ids = Set(AngleArcadeCampaign.levels.map(\.id))
        var result = value
        result.completions = value.completions.filter { ids.contains($0.key) && ($0.value.assisted || $0.value.independent) }
        result.attemptCounts = value.attemptCounts.filter { ids.contains($0.key) && $0.value >= 0 }
        result.helpCounts = value.helpCounts.filter { ids.contains($0.key) && $0.value >= 0 }
        if let last = result.lastLevelID, !ids.contains(last) { result.lastLevelID = nil }
        return result
    }
}
