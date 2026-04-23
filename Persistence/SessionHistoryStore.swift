import Foundation
import Observation
import SwiftData

@MainActor
@Observable
final class SessionHistoryStore {
    private let modelContext: ModelContext
    private let activeProfileIdProvider: () -> String

    init(modelContext: ModelContext, activeProfileIdProvider: @escaping () -> String) {
        self.modelContext = modelContext
        self.activeProfileIdProvider = activeProfileIdProvider
    }

    convenience init(modelContext: ModelContext) {
        self.init(modelContext: modelContext, activeProfileIdProvider: { KidProfileStore.defaultProfileId })
    }

    func save(_ draft: SessionSummaryDraft) {
        modelContext.insert(StoredSessionSummary(from: draft, profileId: activeProfileIdProvider()))
        try? modelContext.save()
    }

    func summariesForActiveProfile() -> [StoredSessionSummary] {
        let profileId = activeProfileIdProvider()
        let descriptor = FetchDescriptor<StoredSessionSummary>(
            predicate: #Predicate { $0.profileId == profileId },
            sortBy: [SortDescriptor(\StoredSessionSummary.startedAt, order: .reverse)]
        )
        return (try? modelContext.fetch(descriptor)) ?? []
    }

    func allSummaries() -> [StoredSessionSummary] {
        let descriptor = FetchDescriptor<StoredSessionSummary>(sortBy: [SortDescriptor(\StoredSessionSummary.startedAt, order: .reverse)])
        return (try? modelContext.fetch(descriptor)) ?? []
    }

    func clearAll() {
        let profileId = activeProfileIdProvider()
        let descriptor = FetchDescriptor<StoredSessionSummary>(
            predicate: #Predicate { $0.profileId == profileId }
        )
        guard let sessions = try? modelContext.fetch(descriptor) else { return }
        for session in sessions {
            modelContext.delete(session)
        }
        try? modelContext.save()
    }

    func clearAllProfiles() {
        let descriptor = FetchDescriptor<StoredSessionSummary>()
        guard let sessions = try? modelContext.fetch(descriptor) else { return }
        for session in sessions {
            modelContext.delete(session)
        }
        try? modelContext.save()
    }
}
