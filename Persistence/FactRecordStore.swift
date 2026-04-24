import Foundation
import Observation
import SwiftData

@MainActor
@Observable
final class FactRecordStore {
    private let modelContext: ModelContext
    var activeProfileId: UUID?

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - Fetch

    func fetchAll() -> [StoredFactRecord] {
        let descriptor = FetchDescriptor<StoredFactRecord>()
        let all = (try? modelContext.fetch(descriptor)) ?? []
        guard let profileId = activeProfileId else {
            return all.filter { $0.profileId == nil }
        }
        return all.filter { $0.profileId == profileId }
    }

    func record(forKey rawKey: String) -> StoredFactRecord? {
        let key = storedKey(rawKey)
        var descriptor = FetchDescriptor<StoredFactRecord>(
            predicate: #Predicate { $0.factKey == key }
        )
        descriptor.fetchLimit = 1
        return try? modelContext.fetch(descriptor).first
    }

    // MARK: - Upsert

    func upsert(factKey rawKey: String, update: (StoredFactRecord) -> Void) {
        if let existing = record(forKey: rawKey) {
            update(existing)
        } else {
            let parts = rawKey.split(separator: "+").compactMap { Int($0) }
            guard parts.count == 2 else { return }
            let new = StoredFactRecord(
                factKey: storedKey(rawKey),
                addendA: parts[0],
                addendB: parts[1],
                profileId: activeProfileId
            )
            update(new)
            modelContext.insert(new)
        }
        try? modelContext.save()
    }

    // MARK: - Session bookkeeping

    func incrementSessionCounts(excludingKeys seenRawKeys: Set<String>) {
        let seenStoredKeys = Set(seenRawKeys.map { storedKey($0) })
        let all = fetchAll()
        for record in all where !seenStoredKeys.contains(record.factKey) {
            record.sessionsSinceLastSeen += 1
        }
        try? modelContext.save()
    }

    // MARK: - Private

    private func storedKey(_ rawKey: String) -> String {
        guard let profileId = activeProfileId else { return rawKey }
        return "\(profileId.uuidString):\(rawKey)"
    }
}
