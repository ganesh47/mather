import Foundation
import SwiftData
import Testing
@testable import Mather

@MainActor
struct LaneRecallReviewEngineTests {
    private func fixture(profile: QuestReviewProfile) throws -> (LaneRecallReviewEngine, GameplayProgressStore, LearningCard) {
        let schema = Schema([StoredGameplayProgressRecord.self, StoredGameplayThreadSession.self])
        let container = try ModelContainer(for: schema, configurations: ModelConfiguration(schema: schema, isStoredInMemoryOnly: true))
        let store = GameplayProgressStore(modelContext: ModelContext(container), activeProfileIdProvider: { profile.id })
        let engine = LaneRecallReviewEngine(activeProfileID: { profile.id })
        engine.onAttempt = { attempt, session in store.recordAttempts([attempt], sessionID: session) }
        let card = try #require(CapabilityLane.defaultExplorerLanes.first { $0.id == .numbers }?.firstRecallEntry?.card)
        engine.beginVisit(.numbers)
        return (engine, store, card)
    }
    @Test func rapidCorrectSubmitsCreateOneAttemptAndOneSessionWithoutSteadyConfidence() throws {
        let profile = QuestReviewProfile(), (engine, store, card) = try fixture(profile: profile)
        let correct = try #require(card.choices.first { $0.isCorrect })
        engine.select(correct.id, card: card)
        #expect(store.allRecords().isEmpty) // Preview/narration is not a graded response.
        for _ in 0..<3 { engine.submit(card) }
        let record = try #require(store.allRecords().first)
        #expect(engine.attempts.count == 1)
        #expect(record.correctCount == 1)
        #expect(record.confidenceBand == .learning)
        #expect(engine.attempts.allSatisfy { $0.sessionID == engine.sessionID && $0.profileID == profile.id })
        #expect(engine.completedCards.contains(card.id))
    }
    @Test func wrongThenCorrectInOneVisitRecordsSupportedCorrection() throws {
        let profile = QuestReviewProfile(), (engine, store, card) = try fixture(profile: profile)
        let wrong = try #require(card.choices.first { !$0.isCorrect }), correct = try #require(card.choices.first { $0.isCorrect })
        engine.select(wrong.id, card: card); engine.submit(card)
        engine.select(correct.id, card: card); engine.submit(card)
        #expect(engine.attempts.map(\.outcome) == [.incorrect, .supportedCorrect])
        #expect(Set(engine.attempts.compactMap(\.sessionID)).count == 1)
        let record = try #require(store.allRecords().first)
        #expect(record.correctCount == 0)
        #expect(record.supportedCorrectCount == 1)
        #expect(record.incorrectCount == 1)
        #expect(record.confidenceBand != .steady)
    }
    @Test func helpIsSupportedAndStaleChildCannotSubmitOrSaveTheVisit() throws {
        let profile = QuestReviewProfile(), (engine, store, card) = try fixture(profile: profile)
        let correct = try #require(card.choices.first { $0.isCorrect })
        engine.help(card)
        #expect(engine.feedback[card.id]?.contains(card.answer.speechText) == true)
        #expect(engine.selectedChoices[card.id] == nil)
        #expect(engine.attempts.map(\.outcome) == [.help])
        engine.select(correct.id, card: card); engine.submit(card)
        #expect(engine.attempts.map(\.outcome) == [.help, .supportedCorrect])
        engine.beginVisit(.numbers); engine.select(correct.id, card: card)
        profile.id = "child-b"
        #expect(engine.submit(card) == nil)
        engine.help(card)
        #expect(engine.attempts.isEmpty)
        #expect(store.allRecords().isEmpty)
    }
}

@MainActor
private final class QuestReviewProfile { var id = "child-a" }
