import Foundation
import Observation
import SwiftData

@MainActor
@Observable
final class GameSessionStore {
    private let modelContext: ModelContext
    private let activeProfileIdProvider: () -> String

    init(modelContext: ModelContext, activeProfileIdProvider: @escaping () -> String) {
        self.modelContext = modelContext
        self.activeProfileIdProvider = activeProfileIdProvider
    }

    func save(
        gameName: String,
        startedAt: Date,
        scoreValue: Int,
        scoreLabel: String,
        detail: String? = nil
    ) {
        let session = StoredGameSession(
            profileId: activeProfileIdProvider(),
            gameName: gameName,
            startedAt: startedAt,
            durationSeconds: Date().timeIntervalSince(startedAt),
            scoreValue: scoreValue,
            scoreLabel: scoreLabel,
            detail: detail
        )
        modelContext.insert(session)
        try? modelContext.save()
    }

    func sessions(forGame gameName: String) -> [StoredGameSession] {
        let profileId = activeProfileIdProvider()
        let descriptor = FetchDescriptor<StoredGameSession>(
            predicate: #Predicate { $0.profileId == profileId && $0.gameName == gameName },
            sortBy: [SortDescriptor(\StoredGameSession.startedAt, order: .reverse)]
        )
        return (try? modelContext.fetch(descriptor)) ?? []
    }

    func allSessions() -> [StoredGameSession] {
        let profileId = activeProfileIdProvider()
        let descriptor = FetchDescriptor<StoredGameSession>(
            predicate: #Predicate { $0.profileId == profileId },
            sortBy: [SortDescriptor(\StoredGameSession.startedAt, order: .reverse)]
        )
        return (try? modelContext.fetch(descriptor)) ?? []
    }

    func clearAll() {
        let profileId = activeProfileIdProvider()
        let descriptor = FetchDescriptor<StoredGameSession>(
            predicate: #Predicate { $0.profileId == profileId }
        )
        guard let sessions = try? modelContext.fetch(descriptor) else { return }
        sessions.forEach { modelContext.delete($0) }
        try? modelContext.save()
    }
}
