import Foundation

/// A frozen observation from the TV photo explorer. The profile-owned coordinator
/// records and deduplicates these events; neither timing nor UI animation earns credit.
struct AnimalExplorerLearningEvent: Equatable {
    enum Kind: Equatable { case exposure, help, answer, completed }

    let id: UUID
    let kind: Kind
    let sessionID: String
    let startedAt: Date
    let occurredAt: Date
    let contentVersion: Int
    let cardID: String?
    let speciesID: String?
    let itemVariantID: String?
    let roundIndex: Int?
    let responseID: String?
    let correct: Bool?
    let appHintUsed: Bool
    let wasExploredBeforeAnswer: Bool
    let completedRoundCount: Int?
    let correctCount: Int?

    init(
        id: UUID = UUID(),
        kind: Kind,
        sessionID: String,
        startedAt: Date,
        occurredAt: Date = Date(),
        contentVersion: Int,
        cardID: String? = nil,
        speciesID: String? = nil,
        itemVariantID: String? = nil,
        roundIndex: Int? = nil,
        responseID: String? = nil,
        correct: Bool? = nil,
        appHintUsed: Bool = false,
        wasExploredBeforeAnswer: Bool = false,
        completedRoundCount: Int? = nil,
        correctCount: Int? = nil
    ) {
        self.id = id
        self.kind = kind
        self.sessionID = sessionID
        self.startedAt = startedAt
        self.occurredAt = occurredAt
        self.contentVersion = contentVersion
        self.cardID = cardID
        self.speciesID = speciesID
        self.itemVariantID = itemVariantID
        self.roundIndex = roundIndex
        self.responseID = responseID
        self.correct = correct
        self.appHintUsed = appHintUsed
        self.wasExploredBeforeAnswer = wasExploredBeforeAnswer
        self.completedRoundCount = completedRoundCount
        self.correctCount = correctCount
    }
}
