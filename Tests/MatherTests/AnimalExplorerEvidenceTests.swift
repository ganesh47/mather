import Foundation
import Testing
@testable import Mather

@MainActor
struct AnimalExplorerEvidenceTests {
    private let began = Date(timeIntervalSince1970: 100)

    private func event(kind: AnimalExplorerLearningEvent.Kind = .answer, id: UUID = UUID(), round: Int = 0,
                       hint: Bool = false, explored: Bool = false, correct: Bool = true) -> AnimalExplorerLearningEvent {
        AnimalExplorerLearningEvent(id: id, kind: kind, sessionID: "synthetic-session", startedAt: began,
            occurredAt: began.addingTimeInterval(1), contentVersion: 1, cardID: "animal-photo-tiger",
            speciesID: "panthera-tigris", itemVariantID: "AnimalPhotoBengalTiger", roundIndex: round,
            responseID: "animal-photo-tiger", correct: correct, appHintUsed: hint, wasExploredBeforeAnswer: explored)
    }

    @Test func correctPracticeHasUnknownAdultHelpAndNoFreshProbeClaim() throws {
        let attempt = try #require(AnimalExplorerEvidenceRecorder.attempt(for: event(), profileID: "child"))
        #expect(attempt.outcome == .independentCorrect)
        #expect(attempt.adultHelp == .unknown && attempt.isFreshProbe == false)
        #expect(attempt.sessionID == "synthetic-session" && attempt.itemVariantID == "AnimalPhotoBengalTiger")
    }

    @Test func priorNameExplorationAndHintAreSupportedAnswers() throws {
        for item in [event(hint: true), event(explored: true)] {
            let attempt = try #require(AnimalExplorerEvidenceRecorder.attempt(for: item, profileID: "child"))
            #expect(attempt.outcome == .supportedCorrect && attempt.appHintUsed == true)
        }
        #expect(AnimalExplorerEvidenceRecorder.attempt(for: event(kind: .exposure), profileID: "child")?.outcome == .exposure)
        #expect(AnimalExplorerEvidenceRecorder.attempt(for: event(kind: .help), profileID: "child")?.outcome == .help)
        #expect(AnimalExplorerEvidenceRecorder.attempt(for: event(correct: false), profileID: "child")?.outcome == .incorrect)
    }

    @Test func malformedEventsAreRejected() {
        #expect(AnimalExplorerEvidenceRecorder.attempt(for: event(round: 6), profileID: "child") == nil)
        #expect(AnimalExplorerEvidenceRecorder.attempt(for: event(), profileID: "") == nil)
        let missing = AnimalExplorerLearningEvent(kind: .answer, sessionID: "s", startedAt: began,
            occurredAt: began, contentVersion: 1)
        #expect(AnimalExplorerEvidenceRecorder.attempt(for: missing, profileID: "child") == nil)
    }

    @Test func repeatedInputAndIncompleteFinaleCannotCreateExtraCredit() throws {
        let defaults = try #require(UserDefaults(suiteName: UUID().uuidString))
        let ledger = TVLearningStore(defaults: defaults, key: "synthetic-ledger")
        defer { defaults.removeObject(forKey: "synthetic-ledger") }
        let context = ledger.context
        let first = event()
        #expect(AnimalExplorerEvidenceRecorder.record(first, context: context, ledger: ledger))
        #expect(AnimalExplorerEvidenceRecorder.record(first, context: context, ledger: ledger))
        #expect(!AnimalExplorerEvidenceRecorder.record(event(), context: context, ledger: ledger))
        #expect(ledger.attempts(for: context.profileID).count == 1)
        let incomplete = AnimalExplorerLearningEvent(kind: .completed, sessionID: "synthetic-session", startedAt: began,
            occurredAt: began.addingTimeInterval(2), contentVersion: 1, completedRoundCount: 6, correctCount: 6)
        #expect(!AnimalExplorerEvidenceRecorder.record(incomplete, context: context, ledger: ledger))
        #expect(ledger.results(for: context.profileID).isEmpty)
    }

    @Test func completedQuizUsesActualLedgerAnswersAndIsDeduplicated() throws {
        let defaults = try #require(UserDefaults(suiteName: UUID().uuidString))
        let ledger = TVLearningStore(defaults: defaults, key: "synthetic-ledger")
        defer { defaults.removeObject(forKey: "synthetic-ledger") }
        let context = ledger.context
        for round in 0..<6 {
            #expect(AnimalExplorerEvidenceRecorder.record(event(round: round, hint: round == 1, correct: round != 2), context: context, ledger: ledger))
        }
        let complete = AnimalExplorerLearningEvent(kind: .completed, sessionID: "synthetic-session", startedAt: began,
            occurredAt: began.addingTimeInterval(2), contentVersion: 1, completedRoundCount: 6, correctCount: 5)
        #expect(AnimalExplorerEvidenceRecorder.record(complete, context: context, ledger: ledger))
        #expect(AnimalExplorerEvidenceRecorder.record(complete, context: context, ledger: ledger))
        #expect(ledger.results(for: context.profileID).count == 1)
        #expect(ledger.attempts(for: context.profileID).filter { $0.outcome == .supportedCorrect }.count == 1)
    }

    @Test func staleProfileCallbackAndUnsupportedStoragePreserveData() throws {
        let defaults = try #require(UserDefaults(suiteName: UUID().uuidString))
        let ledger = TVLearningStore(defaults: defaults, key: "synthetic-ledger")
        defer { defaults.removeObject(forKey: "synthetic-ledger") }
        let family = ledger.context
        #expect(ledger.addLearner(name: "Synthetic child"))
        #expect(!AnimalExplorerEvidenceRecorder.record(event(), context: family, ledger: ledger))
        let raw = Data("future-or-corrupt".utf8)
        defaults.set(raw, forKey: "synthetic-ledger")
        #expect(!AnimalExplorerEvidenceRecorder.record(event(), context: ledger.context, ledger: ledger))
        #expect(defaults.data(forKey: "synthetic-ledger") == raw)
    }

    @Test func priorHintNormalizesLaterAnswerEvenIfUIHintFlagIsMissing() throws {
        let defaults = try #require(UserDefaults(suiteName: UUID().uuidString))
        let ledger = TVLearningStore(defaults: defaults, key: "synthetic-ledger")
        defer { defaults.removeObject(forKey: "synthetic-ledger") }
        let context = ledger.context
        #expect(AnimalExplorerEvidenceRecorder.record(event(kind: .help), context: context, ledger: ledger))
        #expect(AnimalExplorerEvidenceRecorder.record(event(hint: false), context: context, ledger: ledger))
        #expect(ledger.attempts(for: context.profileID).last?.outcome == .supportedCorrect)
    }
}
