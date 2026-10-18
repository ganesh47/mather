import Foundation
import Observation

@MainActor
@Observable
final class WorldQuestProgressStore {
    struct Progress: Codable {
        var schemaVersion = 1
        var countryStamps: Set<String> = []
        var sessions: [WorldQuestSession] = []
        var completedSessionIDs: Set<UUID> = []
    }
    static let storageKey = "mather.worldQuest.progress.v1"
    private(set) var progress: Progress
    @ObservationIgnored private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        if let data = defaults.data(forKey: Self.storageKey),
           let saved = try? JSONDecoder().decode(Progress.self, from: data), saved.schemaVersion == 1 {
            progress = saved
        } else {
            progress = Progress()
        }
    }

    func record(_ session: WorldQuestSession) {
        guard !progress.completedSessionIDs.contains(session.id), !session.answers.isEmpty else { return }
        var updated = progress
        updated.completedSessionIDs.insert(session.id)
        updated.sessions.append(session)
        updated.sessions = Array(updated.sessions.suffix(50))
        updated.countryStamps.formUnion(session.answers.filter { $0.outcome != .revealed }.map(\.countryID))
        guard let data = try? JSONEncoder().encode(updated) else { return }
        defaults.set(data, forKey: Self.storageKey)
        progress = updated
    }
}
