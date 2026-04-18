import Foundation
import Testing
import SwiftData
@testable import Mather

@MainActor
struct SumSprintGeneratorTests {

    // MARK: - Helpers

    private func makeStore() throws -> FactRecordStore {
        let schema = Schema([StoredFactRecord.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: config)
        return FactRecordStore(modelContext: ModelContext(container))
    }

    // MARK: - Fact pool

    @Test
    func factPoolContainsOnly11To20Sums() {
        let facts = SumSprintGenerator.allFacts
        for fact in facts {
            #expect(fact.sum >= 11)
            #expect(fact.sum <= 20)
            #expect(fact.addendA >= 1)
            #expect(fact.addendB >= 1)
            #expect(fact.addendA <= fact.addendB)
        }
    }

    @Test
    func factPoolHasNoDuplicates() {
        let keys = SumSprintGenerator.allFacts.map(\.factKey)
        let unique = Set(keys)
        #expect(keys.count == unique.count)
    }

    @Test
    func stableIDIsConsistentAcrossCalls() {
        let id1 = SumSprintGenerator.stableID(a: 3, b: 8)
        let id2 = SumSprintGenerator.stableID(a: 3, b: 8)
        #expect(id1 == id2)
    }

    @Test
    func stableIDDiffersForDifferentFacts() {
        let id1 = SumSprintGenerator.stableID(a: 3, b: 8)
        let id2 = SumSprintGenerator.stableID(a: 4, b: 7)
        #expect(id1 != id2)
    }

    // MARK: - Session selection

    @Test
    func generateSessionReturns10FactsWhenNoRecords() throws {
        let store = try makeStore()
        let facts = SumSprintGenerator.generateSession(allRecords: store.fetchAll())
        #expect(facts.count == 10)
    }

    @Test
    func generateSessionReturnsSumsIn11To20() throws {
        let store = try makeStore()
        let facts = SumSprintGenerator.generateSession(allRecords: store.fetchAll())
        for fact in facts {
            #expect(fact.sum >= 11)
            #expect(fact.sum <= 20)
        }
    }

    @Test
    func generateSessionRespectsBox1IntervalOf2() throws {
        let store = try makeStore()
        // Seed all 45 facts in box1 with sessionsSinceLastSeen = 1 (not yet eligible)
        for fact in SumSprintGenerator.allFacts {
            store.upsert(factKey: fact.factKey) { record in
                record.boxRawValue = LeitnerBox.box1.rawValue
                record.sessionsSinceLastSeen = 1
            }
        }
        let facts = SumSprintGenerator.generateSession(allRecords: store.fetchAll())
        // All box1 with sinceLastSeen=1 are ineligible — generator backfills from them
        // but they should come from the ineligible pool (no pure-eligible box1 facts)
        #expect(facts.count == 10)
        // Verify none have sinceLastSeen >= 2 (they're all == 1)
        let records = store.fetchAll()
        let recordByKey = Dictionary(uniqueKeysWithValues: records.map { ($0.factKey, $0) })
        for fact in facts {
            let record = recordByKey[fact.factKey]
            // They are ineligible (sinceLastSeen == 1 for box1) but selected as backfill
            let sinceLastSeen = record?.sessionsSinceLastSeen ?? 0
            #expect(sinceLastSeen < 2)
        }
    }

    @Test
    func generateSessionIncludesBox1WhenIntervalMet() throws {
        let store = try makeStore()
        // Seed exactly 10 facts in box1 with sessionsSinceLastSeen = 2 (eligible)
        let eligibleFacts = Array(SumSprintGenerator.allFacts.prefix(10))
        for fact in eligibleFacts {
            store.upsert(factKey: fact.factKey) { record in
                record.boxRawValue = LeitnerBox.box1.rawValue
                record.sessionsSinceLastSeen = 2
            }
        }
        // Seed remaining facts in box2 with sinceLastSeen = 1 (ineligible)
        for fact in SumSprintGenerator.allFacts.dropFirst(10) {
            store.upsert(factKey: fact.factKey) { record in
                record.boxRawValue = LeitnerBox.box2.rawValue
                record.sessionsSinceLastSeen = 1
            }
        }
        let selectedKeys = Set(SumSprintGenerator.generateSession(allRecords: store.fetchAll()).map(\.factKey))
        let eligibleKeys = Set(eligibleFacts.map(\.factKey))
        // All selected should be from the eligible box1 facts
        #expect(selectedKeys == eligibleKeys)
    }

    @Test
    func generateSessionRespectsBox2IntervalOf5() throws {
        let store = try makeStore()
        // All facts in box2, sinceLastSeen = 4 (not yet eligible)
        for fact in SumSprintGenerator.allFacts {
            store.upsert(factKey: fact.factKey) { record in
                record.boxRawValue = LeitnerBox.box2.rawValue
                record.sessionsSinceLastSeen = 4
            }
        }
        let facts = SumSprintGenerator.generateSession(allRecords: store.fetchAll())
        // All are ineligible — backfilled from ineligible pool
        #expect(facts.count == 10)
    }

    @Test
    func generateSessionBackfillsWhenEligiblePoolSmall() throws {
        let store = try makeStore()
        // Only 5 facts in box0 (always eligible), rest in box2 with sinceLastSeen = 1
        let box0Facts = Array(SumSprintGenerator.allFacts.prefix(5))
        for fact in box0Facts {
            store.upsert(factKey: fact.factKey) { record in
                record.boxRawValue = LeitnerBox.box0.rawValue
            }
        }
        for fact in SumSprintGenerator.allFacts.dropFirst(5) {
            store.upsert(factKey: fact.factKey) { record in
                record.boxRawValue = LeitnerBox.box2.rawValue
                record.sessionsSinceLastSeen = 1
            }
        }
        let facts = SumSprintGenerator.generateSession(allRecords: store.fetchAll())
        // Should still return 10 (5 eligible + 5 backfilled)
        #expect(facts.count == 10)
    }

    @Test
    func generateSessionAvoidsAdjacentDuplicateSumsWhenPossible() {
        let facts = SumSprintGenerator.generateSession(allRecords: [])

        for index in 1..<facts.count {
            #expect(facts[index].sum != facts[index - 1].sum)
        }
    }
}
