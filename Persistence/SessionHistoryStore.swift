import Foundation
import Observation
import SwiftData

@MainActor
@Observable
final class SessionHistoryStore {
    private let modelContext: ModelContext
    var activeProfileId: UUID?

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func save(_ draft: SessionSummaryDraft) {
        var stamped = draft
        stamped.profileId = activeProfileId
        modelContext.insert(StoredSessionSummary(from: stamped))
        try? modelContext.save()
    }

    func clearAll() {
        let descriptor = FetchDescriptor<StoredSessionSummary>()
        guard let sessions = try? modelContext.fetch(descriptor) else { return }
        for session in sessions {
            modelContext.delete(session)
        }
        try? modelContext.save()
    }
}
