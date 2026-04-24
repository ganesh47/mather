import Foundation
import Observation
import SwiftData

@MainActor
@Observable
final class KidProfileStore {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func fetchAll() -> [StoredKidProfile] {
        let descriptor = FetchDescriptor<StoredKidProfile>(
            sortBy: [SortDescriptor(\.createdAt)]
        )
        return (try? modelContext.fetch(descriptor)) ?? []
    }

    @discardableResult
    func insert(name: String, emoji: String) -> StoredKidProfile {
        let profile = StoredKidProfile(name: name, emoji: emoji)
        modelContext.insert(profile)
        try? modelContext.save()
        return profile
    }

    func delete(_ profile: StoredKidProfile) {
        modelContext.delete(profile)
        try? modelContext.save()
    }

    func profile(withId id: UUID) -> StoredKidProfile? {
        var descriptor = FetchDescriptor<StoredKidProfile>(
            predicate: #Predicate { $0.id == id }
        )
        descriptor.fetchLimit = 1
        return try? modelContext.fetch(descriptor).first
    }
}
