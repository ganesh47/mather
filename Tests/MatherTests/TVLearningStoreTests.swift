import Foundation
import Testing
@testable import Mather

@MainActor
struct TVLearningStoreTests {
    private func defaults() -> UserDefaults {
        UserDefaults(suiteName: "TVLearningStoreTests.\(UUID().uuidString)")!
    }
    private func attempt(profileID: String, outcome: ItemAttemptOutcome = .independentCorrect, id: UUID = UUID()) -> ItemAttempt {
        ItemAttempt(id: id, activityID: "tv-sum-sprint", conceptID: "addition", entityID: "2+3", stageID: "probe", outcome: outcome,
            profileID: profileID, sessionID: "session", contentVersion: 1, itemVariantID: "parts-2-3", appHintUsed: false, isFreshProbe: true, adultHelp: .unknown)
    }

    @Test func familyIsSeparateAndDuplicatesAreIdempotent() {
        let storage = defaults()
        let store = TVLearningStore(defaults: storage)
        let familyEvent = attempt(profileID: TVLearningContext.familyID)
        #expect(store.record(familyEvent))
        #expect(store.record(familyEvent))
        #expect(store.attempts(for: TVLearningContext.familyID).count == 1)
        #expect(store.addLearner(name: "Learner A"))
        let learnerID = store.context.profileID
        #expect(!store.record(familyEvent))
        #expect(store.record(attempt(profileID: learnerID)))
        let reopened = TVLearningStore(defaults: storage)
        #expect(reopened.context.profileID == learnerID)
        #expect(reopened.attempts(for: learnerID).count == 1)
        #expect(reopened.attempts(for: TVLearningContext.familyID).count == 1)
    }

    @Test func resumedSupportCannotBecomeIndependent() {
        let storage = defaults()
        let store = TVLearningStore(defaults: storage)
        #expect(store.record(attempt(profileID: TVLearningContext.familyID, outcome: .help)))
        let reopened = TVLearningStore(defaults: storage)
        #expect(reopened.record(attempt(profileID: TVLearningContext.familyID)))
        #expect(reopened.attempts(for: TVLearningContext.familyID).last?.outcome == .supportedCorrect)
    }

    @Test func resultsRejectMixedChildrenAndDoNotDoubleCount() {
        let store = TVLearningStore(defaults: defaults())
        let event = attempt(profileID: TVLearningContext.familyID)
        let result = ActivityResult(id: "session", activityID: event.activityID, title: "Sum Sprint", startedAt: Date(), attempts: [event], completedStageIDs: ["probe"], profileID: event.profileID, contentVersion: 1)
        #expect(store.save(result))
        #expect(store.save(result))
        #expect(store.results(for: TVLearningContext.familyID).count == 1)
        #expect(store.attempts(for: TVLearningContext.familyID).count == 1)
        #expect(store.addLearner(name: "Learner B"))
        #expect(!store.save(result))
        #expect(store.results(for: store.context.profileID).isEmpty)
    }

    @Test func futureOrCorruptArchiveIsPreserved() {
        let storage = defaults()
        let data = Data("{\"schemaVersion\":2}".utf8)
        storage.set(data, forKey: "tv.learningLedger.v1")
        let store = TVLearningStore(defaults: storage)
        #expect(store.storageMessage != nil)
        #expect(!store.addLearner(name: "A"))
        #expect(storage.data(forKey: "tv.learningLedger.v1") == data)
    }

    @Test func selectedResetKeepsOtherLearnersAndFamily() {
        let storage = defaults()
        let store = TVLearningStore(defaults: storage)
        #expect(store.record(attempt(profileID: TVLearningContext.familyID)))
        #expect(store.addLearner(name: "A"))
        let selected = store.context.profileID
        #expect(store.record(attempt(profileID: selected)))
        #expect(store.clearLearning(profileID: selected))
        #expect(store.attempts(for: selected).isEmpty)
        #expect(store.learners.count == 1)
        #expect(store.attempts(for: TVLearningContext.familyID).count == 1)
        store.resetAll()
        #expect(store.learners.isEmpty)
        #expect(store.attempts(for: TVLearningContext.familyID).isEmpty)
        #expect(storage.data(forKey: "tv.learningLedger.v1") == nil)
    }

    @Test func oldEvidenceDecodesAndContextSurvives() throws {
        let event = attempt(profileID: TVLearningContext.familyID)
        let data = try JSONEncoder().encode(event)
        var json = try #require(JSONSerialization.jsonObject(with: data) as? [String: Any])
        for key in ["itemVariantID", "appHintUsed", "isFreshProbe", "adultHelp"] { json.removeValue(forKey: key) }
        let old = try JSONDecoder().decode(ItemAttempt.self, from: JSONSerialization.data(withJSONObject: json))
        #expect(old.isFreshProbe == nil)
        #expect(old.withContext(profileID: "learner").adultHelp == nil)
        #expect(event.withOutcome(.supportedCorrect).itemVariantID == event.itemVariantID)
    }

    @Test func differentFrozenProbeDoesNotInheritPracticeHelpButLegacySupportSurvives() {
        let help = ItemAttempt(activityID: "shapes", conceptID: "corners", entityID: "rectangle", stageID: "check", outcome: .help,
            profileID: "learner", sessionID: "session", contentVersion: 1, itemVariantID: "practice")
        let probe = ItemAttempt(activityID: "shapes", conceptID: "corners", entityID: "rectangle", stageID: "check", outcome: .independentCorrect,
            profileID: "learner", sessionID: "session", contentVersion: 1, itemVariantID: "fresh-turned-rectangle", appHintUsed: false, isFreshProbe: true)
        #expect(ActivityEvidenceNormalizer.normalized([probe], after: [help]).first?.outcome == .independentCorrect)
        let legacyHelp = ItemAttempt(activityID: "shapes", conceptID: "corners", entityID: "rectangle", stageID: "check", outcome: .help,
            profileID: "learner", sessionID: "session", contentVersion: 1)
        #expect(ActivityEvidenceNormalizer.normalized([probe], after: [legacyHelp]).first?.outcome == .supportedCorrect)
        let legacyCorrect = ItemAttempt(activityID: "shapes", conceptID: "corners", entityID: "rectangle", stageID: "check", outcome: .independentCorrect,
            profileID: "learner", sessionID: "session", contentVersion: 1)
        #expect(ActivityEvidenceNormalizer.normalized([legacyCorrect], after: [help]).first?.outcome == .supportedCorrect)
    }
}
