import Foundation
import Observation

/// A visit is one retrieval session. Previewing and replaying an accepted answer
/// do not create new attempts or new independent sessions.
@MainActor
@Observable
final class LaneRecallReviewEngine {
    private let activeProfileID: () -> String
    private(set) var profileID = ""
    private(set) var laneID: CapabilityLaneID = .numbers
    private(set) var sessionID = ""
    private(set) var startedAt = Date()
    private(set) var selectedChoices: [String: String] = [:]
    private(set) var completedCards: Set<String> = []
    private(set) var supportedCards: Set<String> = []
    private(set) var feedback: [String: String] = [:]
    private(set) var attempts: [ItemAttempt] = []
    var onAttempt: (ItemAttempt, String) -> Void = { _, _ in }
    var onSpeak: (String) -> Void = { _ in }
    var onResult: (ActivityResult) -> Void = { _ in }

    init(activeProfileID: @escaping () -> String) { self.activeProfileID = activeProfileID }
    func beginVisit(_ lane: CapabilityLaneID) {
        profileID = activeProfileID(); laneID = lane; sessionID = UUID().uuidString; startedAt = Date()
        selectedChoices = [:]; completedCards = []; supportedCards = []; feedback = [:]; attempts = []
    }
    func speakPrompt(_ card: LearningCard) { guard valid(card) else { return }; onSpeak(card.prompt.speechText) }
    func select(_ choiceID: String, card: LearningCard) {
        guard valid(card), !completedCards.contains(card.id), let choice = card.choices.first(where: { $0.id == choiceID }) else { return }
        selectedChoices[card.id] = choiceID; onSpeak(choice.answer.speechText)
    }
    func help(_ card: LearningCard) {
        guard valid(card), !completedCards.contains(card.id) else { return }
        supportedCards.insert(card.id)
        let clue = "Let's look together. \(card.prompt.speechText) Look for \(card.answer.speechText). Compare the choices, then try it."
        feedback[card.id] = clue
        record(card, outcome: .help, response: clue)
        onSpeak(clue)
    }
    @discardableResult
    func submit(_ card: LearningCard) -> ItemAttempt? {
        guard valid(card), !completedCards.contains(card.id), let selected = selectedChoices[card.id], let choice = card.choices.first(where: { $0.id == selected }) else { return nil }
        let outcome: ItemAttemptOutcome = choice.isCorrect ? (supportedCards.contains(card.id) ? .supportedCorrect : .independentCorrect) : .incorrect
        if choice.isCorrect { completedCards.insert(card.id) } else { supportedCards.insert(card.id) }
        let explanation = choice.isCorrect ? "You found it! \(card.answer.speechText)" : "Listen to the clue and compare the choices. You can try another idea."
        feedback[card.id] = explanation; onSpeak(explanation)
        return record(card, outcome: outcome, response: choice.id)
    }
    func finishVisit(title: String) {
        guard profileID == activeProfileID(), !attempts.isEmpty else { return }
        onResult(ActivityResult(id: sessionID, activityID: "lane-review-\(laneID.rawValue)", title: title, startedAt: startedAt, attempts: attempts, completedStageIDs: completedCards.isEmpty ? [] : ["review"], profileID: profileID, contentVersion: 1))
    }
    private func valid(_ card: LearningCard) -> Bool { profileID == activeProfileID() && card.laneID == laneID && !sessionID.isEmpty }
    @discardableResult
    private func record(_ card: LearningCard, outcome: ItemAttemptOutcome, response: String) -> ItemAttempt {
        let attempt = ItemAttempt(activityID: "lane-review-\(laneID.rawValue)", conceptID: card.conceptID.rawValue, entityID: card.id, stageID: "review", outcome: outcome, response: response, profileID: profileID, sessionID: sessionID, contentVersion: 1)
        attempts.append(attempt); onAttempt(attempt, sessionID); return attempt
    }
}
