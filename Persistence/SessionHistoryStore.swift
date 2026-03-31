import Foundation
import Observation
import SwiftData

@MainActor
@Observable
final class SessionHistoryStore {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func save(_ draft: SessionSummaryDraft) {
        modelContext.insert(StoredSessionSummary(from: draft))
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
