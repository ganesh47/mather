import Foundation
import SwiftData
import Testing
@testable import Mather

@MainActor
struct QuestPriorEvidenceReaderTests {
    private func container() throws -> ModelContainer {
        try ModelContainer(for: StoredGameplayProgressRecord.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
    }
    private func record(profile: String = "selected", thread: String = LearningQuestID.numbers.activityID) -> StoredGameplayProgressRecord {
        StoredGameplayProgressRecord(uniqueKey: UUID().uuidString, profileId: profile, threadId: thread,
            entityId: "number-bond.challenge", stageId: "challenge", exposureCount: 1, correctCount: 1)
    }

    @Test func readsOnlySelectedQuestHistoryAndPreservesOriginalAttemptMetadata() throws {
        let database = try container()
        let context = database.mainContext
        let own = record()
        let old = ItemAttempt(activityID: own.threadId, conceptID: "number-bond", entityID: own.entityId,
            stageID: own.stageId, outcome: .independentCorrect, profileID: "selected", sessionID: "old", contentVersion: 1)
        let bytes = try JSONEncoder().encode([old])
        own.itemAttemptsData = bytes
        context.insert(own)
        let other = record(profile: "other")
        other.itemAttemptsData = Data("unreadable other child's history".utf8)
        context.insert(other)
        let unrelated = record(thread: "memory-match")
        unrelated.itemAttemptsData = Data("unrelated history".utf8)
        context.insert(unrelated)
        try context.save()
        let input = try #require(QuestPriorEvidenceReader.attempts(profileID: "selected", context: context))
        #expect(input.contains(old))
        #expect(input.allSatisfy { $0.profileID == "selected" })
        #expect(own.itemAttemptsData == bytes)
        #expect(old.itemVariantID == nil && old.isFreshProbe == nil)
    }

    @Test func unreadableSelectedQuestHistoryIsUnknownAndPreserved() throws {
        let database = try container()
        let context = database.mainContext
        let own = record()
        let bytes = Data("unreadable quest history".utf8)
        own.itemAttemptsData = bytes
        context.insert(own)
        try context.save()
        #expect(QuestPriorEvidenceReader.attempts(profileID: "selected", context: context) == nil)
        #expect(own.itemAttemptsData == bytes)
    }

    @Test func legacyAggregateCanPreventFreshnessWithoutCreditingAnAnswer() throws {
        let database = try container()
        let context = database.mainContext
        let own = record()
        context.insert(own)
        try context.save()
        let input = try #require(QuestPriorEvidenceReader.attempts(profileID: "selected", context: context))
        #expect(!input.isEmpty)
        #expect(input.allSatisfy { $0.outcome == .exposure })
        #expect(own.itemAttemptsData == nil && own.correctCount == 1)
    }
}
