import Foundation
import Testing
@testable import Mather

private final class ObservationDefaults: ExplorerLabMasteryKeyValueStore {
    var values: [String: Data] = [:]
    func data(forKey key: String) -> Data? { values[key] }
    func set(_ value: Data?, forKey key: String) { values[key] = value }
    func removeObject(forKey key: String) { values.removeValue(forKey: key) }
}

@MainActor
struct ParentOffscreenObservationTests {
    @Test func nonDataUserDefaultsValueIsPreservedUntilExplicitAllReset() throws {
        let suite = "parent-observation-test-\(UUID().uuidString)", key = "parentOffscreenObservations.v1"
        let defaults = try #require(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        defaults.set("unsupported future storage", forKey: key)
        let store = ParentOffscreenObservationStore(storage: defaults)
        #expect(store.storageIssue == .unreadableHistory)
        #expect(store.record(profileID: "a", questID: .numbers, outcome: .notYet) == nil)
        #expect(!store.clearSelectedProfile(profileID: "a"))
        #expect(defaults.string(forKey: key) == "unsupported future storage")
        store.clearAllProfiles()
        #expect(defaults.object(forKey: key) == nil && store.storageIssue == nil)
    }
    @Test func reportsPersistConceptDateAndParentHelpSeparatelyForEachChild() throws {
        let defaults = ObservationDefaults(), store = ParentOffscreenObservationStore(storage: ObservationDefaults())
        #expect(store.record(profileID: "", questID: .numbers, outcome: .notYet) == nil)
        let original = ParentOffscreenObservationStore(storage: defaults)
        let when = Date(timeIntervalSince1970: 100)
        let report = try #require(original.record(profileID: "a", questID: .waterCycle, outcome: .usedIdeaWithAdultHelp, now: when))
        original.record(profileID: "b", questID: .numbers, outcome: .usedIdeaAlone)
        let restored = ParentOffscreenObservationStore(storage: defaults)
        #expect(restored.observations(profileID: "a") == [report])
        #expect(report.prompt == LearningQuestID.waterCycle.offscreenPrompt)
        #expect(report.occurredAt == when)
        #expect(report.outcome == .usedIdeaWithAdultHelp)
        restored.clearSelectedProfile(profileID: "a")
        #expect(restored.observations(profileID: "a").isEmpty)
        #expect(restored.observations(profileID: "b").count == 1)
        restored.clearAllProfiles()
        #expect(restored.observations(profileID: "b").isEmpty)
    }
    @Test func boundedHistoryPreservesOtherChildAndNewestReport() throws {
        let store = ParentOffscreenObservationStore(storage: ObservationDefaults())
        store.record(profileID: "b", questID: .shapes, outcome: .notYet)
        for index in 0..<35 {
            store.record(profileID: "a", questID: .numbers, outcome: .usedIdeaAlone, now: Date(timeIntervalSince1970: Double(index)))
        }
        #expect(store.observations(profileID: "a").count == 30)
        #expect(store.observations(profileID: "a").first?.occurredAt == Date(timeIntervalSince1970: 34))
        #expect(store.observations(profileID: "b").count == 1)
    }
    @Test func corruptAndFutureHistoryRejectWritesWithoutErasingOtherChildren() throws {
        let key = "parentOffscreenObservations.v1"
        let valid = ParentOffscreenObservation(id: UUID(), profileID: "other-child", questID: .shapes,
            occurredAt: Date(timeIntervalSince1970: 100), outcome: .notYet, prompt: "Keep this report")
        let encoded = try JSONEncoder().encode([valid])
        var future = try #require(JSONSerialization.jsonObject(with: encoded) as? [[String: Any]])
        future[0]["futureEvidence"] = "preserve me"
        let futureBytes = try JSONSerialization.data(withJSONObject: future)
        for bytes in [Data("broken JSON".utf8), Data("{\"schemaVersion\":2,\"observations\":[]}".utf8), futureBytes] {
            let defaults = ObservationDefaults(); defaults.set(bytes, forKey: key)
            let store = ParentOffscreenObservationStore(storage: defaults)
            #expect(store.storageIssue == .unreadableHistory)
            #expect(store.record(profileID: "a", questID: .numbers, outcome: .usedIdeaAlone) == nil)
            #expect(!store.clearSelectedProfile(profileID: "a"))
            #expect(defaults.data(forKey: key) == bytes)
            #expect(store.storageIssue?.message.contains("preserved") == true)
            store.clearAllProfiles()
            #expect(defaults.data(forKey: key) == nil)
            #expect(store.record(profileID: "a", questID: .numbers, outcome: .notYet) != nil)
        }
        let defaults = ObservationDefaults(); defaults.set(encoded, forKey: key)
        let store = ParentOffscreenObservationStore(storage: defaults)
        #expect(store.storageIssue == nil)
        #expect(store.record(profileID: "a", questID: .numbers, outcome: .usedIdeaAlone) != nil)
        #expect(store.observations(profileID: "other-child") == [valid])
    }

}
