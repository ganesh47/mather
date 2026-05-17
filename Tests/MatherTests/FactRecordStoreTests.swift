import Testing
import SwiftData
@testable import Mather

@MainActor
struct FactRecordStoreTests {
    private func makeContext() throws -> ModelContext {
        let schema = Schema([StoredFactRecord.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: config)
        return ModelContext(container)
    }

    @Test
    func factRecordsAreScopedToActiveProfile() throws {
        let context = try makeContext()
        var activeProfileId = "profile-a"
        let store = FactRecordStore(modelContext: context, activeProfileIdProvider: { activeProfileId })

        store.upsert(factKey: "5+6") { record in
            record.boxRawValue = LeitnerBox.box2.rawValue
            record.sessionsSinceLastSeen = 4
        }

        activeProfileId = "profile-b"
        store.upsert(factKey: "5+6") { record in
            record.boxRawValue = LeitnerBox.box0.rawValue
            record.sessionsSinceLastSeen = 0
        }

        #expect(store.fetchAll().map(\.profileId) == ["profile-b"])
        #expect(store.record(forKey: "5+6")?.boxRawValue == LeitnerBox.box0.rawValue)

        activeProfileId = "profile-a"
        #expect(store.fetchAll().map(\.profileId) == ["profile-a"])
        #expect(store.record(forKey: "5+6")?.boxRawValue == LeitnerBox.box2.rawValue)
    }

    @Test
    func sessionCountIncrementDoesNotTouchOtherProfiles() throws {
        let context = try makeContext()
        var activeProfileId = "profile-a"
        let store = FactRecordStore(modelContext: context, activeProfileIdProvider: { activeProfileId })

        store.upsert(factKey: "5+6") { record in
            record.sessionsSinceLastSeen = 1
        }

        activeProfileId = "profile-b"
        store.upsert(factKey: "5+6") { record in
            record.sessionsSinceLastSeen = 7
        }

        activeProfileId = "profile-a"
        store.incrementSessionCounts(excludingKeys: [])

        #expect(store.record(forKey: "5+6")?.sessionsSinceLastSeen == 2)

        activeProfileId = "profile-b"
        #expect(store.record(forKey: "5+6")?.sessionsSinceLastSeen == 7)
    }
}
