import Foundation

/// Converts observed photo practice into the existing profile-owned ledger.
/// A reviewed photo bank is never a fresh transfer probe, and adult help stays unknown.
@MainActor
enum AnimalExplorerEvidenceRecorder {
    static let activityID = "tv-animal-explorer"

    static func attempt(for event: AnimalExplorerLearningEvent, profileID: String) -> ItemAttempt? {
        guard event.kind != .completed, !profileID.isEmpty, validEnvelope(event),
              let card = event.cardID, !card.isEmpty,
              let species = event.speciesID, !species.isEmpty,
              let variant = event.itemVariantID, !variant.isEmpty else { return nil }
        let stage: String
        let outcome: ItemAttemptOutcome
        let support = event.appHintUsed || event.wasExploredBeforeAnswer || event.kind == .help
        switch event.kind {
        case .exposure:
            stage = "photo-browse"
            outcome = .exposure
        case .help, .answer:
            guard let round = event.roundIndex, (0..<6).contains(round) else { return nil }
            stage = "name-quiz-\(round)"
            if event.kind == .help { outcome = .help }
            else {
                guard let correct = event.correct, let response = event.responseID, !response.isEmpty else { return nil }
                outcome = correct ? (support ? .supportedCorrect : .independentCorrect) : .incorrect
            }
        case .completed: return nil
        }
        return ItemAttempt(id: event.id, activityID: activityID, conceptID: "animal-recognition",
            entityID: species, propertyID: "common-name", stageID: stage, outcome: outcome,
            response: event.responseID, occurredAt: event.occurredAt, profileID: profileID,
            sessionID: event.sessionID, contentVersion: event.contentVersion,
            itemVariantID: variant, appHintUsed: support, isFreshProbe: false, adultHelp: .unknown)
    }

    @discardableResult
    static func record(_ event: AnimalExplorerLearningEvent, context: TVLearningContext, ledger: TVLearningStore) -> Bool {
        guard context.profileID == ledger.context.profileID, ledger.storageMessage == nil, validEnvelope(event) else { return false }
        let previous = ledger.attempts(for: context.profileID).filter {
            $0.activityID == activityID && $0.sessionID == event.sessionID
        }
        if event.kind != .completed {
            guard let incoming = attempt(for: event, profileID: context.profileID) else { return false }
            if event.kind == .answer, previous.contains(where: {
                $0.stageID == incoming.stageID && isAnswer($0) && $0.id != incoming.id
            }) { return false }
            return ledger.record(incoming)
        }
        guard let count = event.completedRoundCount, (1...6).contains(count),
              let correctCount = event.correctCount, (0...count).contains(correctCount) else { return false }
        let answers = previous.filter(isAnswer)
        let expectedStages = Set((0..<count).map { "name-quiz-\($0)" })
        guard answers.count == count, Set(answers.map(\.stageID)) == expectedStages,
              answers.filter({ $0.outcome != .incorrect }).count == correctCount else { return false }
        return ledger.save(ActivityResult(id: event.sessionID, activityID: activityID, title: "Animal photo name quiz",
            startedAt: event.startedAt, endedAt: event.occurredAt, attempts: previous,
            completedStageIDs: ["name-quiz"], profileID: context.profileID, contentVersion: event.contentVersion))
    }

    private static func isAnswer(_ attempt: ItemAttempt) -> Bool {
        [.independentCorrect, .supportedCorrect, .incorrect].contains(attempt.outcome)
    }

    private static func validEnvelope(_ event: AnimalExplorerLearningEvent) -> Bool {
        !event.sessionID.isEmpty && event.contentVersion > 0 &&
        event.startedAt.timeIntervalSince1970.isFinite && event.occurredAt.timeIntervalSince1970.isFinite &&
        event.occurredAt >= event.startedAt
    }
}
