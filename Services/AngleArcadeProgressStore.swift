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
    private let defaults: UserDefaults
    let scope: String
    private var key: String { "mather.angle-arcade.progress.v1.\(scope)" }

    init(defaults: UserDefaults = .standard, scope: String = "tv") {
        self.defaults = defaults
        self.scope = scope
    }

    func load() -> AngleArcadeProgress {
        guard let data = defaults.data(forKey: key),
              let value = try? JSONDecoder().decode(AngleArcadeProgress.self, from: data),
              value.schemaVersion == 1 else { return AngleArcadeProgress() }
        return validated(value)
    }

    func save(_ progress: AngleArcadeProgress) {
        guard progress.schemaVersion == 1, let data = try? JSONEncoder().encode(validated(progress)) else { return }
        defaults.set(data, forKey: key)
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
