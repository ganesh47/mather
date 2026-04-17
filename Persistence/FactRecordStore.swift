import Foundation
import Observation
import SwiftData

@MainActor
@Observable
final class FactRecordStore {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - Fetch

    func fetchAll() -> [StoredFactRecord] {
        let descriptor = FetchDescriptor<StoredFactRecord>()
        return (try? modelContext.fetch(descriptor)) ?? []
    }

    func record(forKey key: String) -> StoredFactRecord? {
        var descriptor = FetchDescriptor<StoredFactRecord>(
            predicate: #Predicate { $0.factKey == key }
        )
        descriptor.fetchLimit = 1
        return try? modelContext.fetch(descriptor).first
    }

    // MARK: - Upsert

    /// Updates an existing record or creates one if it doesn't exist.
    func upsert(factKey: String, update: (StoredFactRecord) -> Void) {
        if let existing = record(forKey: factKey) {
            update(existing)
        } else {
            let parts = factKey.split(separator: "+").compactMap { Int($0) }
            guard parts.count == 2 else { return }
            let new = StoredFactRecord(factKey: factKey, addendA: parts[0], addendB: parts[1])
            update(new)
            modelContext.insert(new)
        }
        try? modelContext.save()
    }

    // MARK: - Session bookkeeping

    /// Called at the end of each session.
    /// Increments sessionsSinceLastSeen for all records that were NOT seen this session.
    func incrementSessionCounts(excludingKeys seenKeys: Set<String>) {
        let all = fetchAll()
        for record in all where !seenKeys.contains(record.factKey) {
            record.sessionsSinceLastSeen += 1
        }
        try? modelContext.save()
    }
}
