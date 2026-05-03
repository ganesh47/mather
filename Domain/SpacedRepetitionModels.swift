import Foundation

struct GameplayExposureKey: Codable, Equatable, Hashable {
    let entityID: String
    let propertyID: String?
    let stageID: String

    init(entityID: String, propertyID: String? = nil, stageID: String) {
        self.entityID = entityID
        self.propertyID = propertyID
        self.stageID = stageID
    }
}

enum GameplayConfidenceBand: String, Codable, Equatable, Hashable, CaseIterable {
    case new
    case learning
    case steady
    case reviewNeeded
}

enum GameplayExposureOutcome: String, Codable, Equatable, Hashable, CaseIterable {
    case correct
    case supportedCorrect
    case incorrect

    var cardReviewResult: CardReviewResult {
        switch self {
        case .correct: return .correct
        case .supportedCorrect: return .supportedCorrect
        case .incorrect: return .incorrect
        }
    }
}

struct GameplayExposureRecord: Codable, Equatable, Hashable {
    let key: GameplayExposureKey
    var correctCount: Int
    var supportedCorrectCount: Int
    var mistakeCount: Int
    var lastSeenAt: Date?
    var lastOutcome: GameplayExposureOutcome?
    var dueAt: Date
    var confidenceBand: GameplayConfidenceBand

    init(
        key: GameplayExposureKey,
        correctCount: Int = 0,
        supportedCorrectCount: Int = 0,
        mistakeCount: Int = 0,
        lastSeenAt: Date? = nil,
        lastOutcome: GameplayExposureOutcome? = nil,
        dueAt: Date = .distantPast,
        confidenceBand: GameplayConfidenceBand = .new
    ) {
        self.key = key
        self.correctCount = correctCount
        self.supportedCorrectCount = supportedCorrectCount
        self.mistakeCount = mistakeCount
        self.lastSeenAt = lastSeenAt
        self.lastOutcome = lastOutcome
        self.dueAt = dueAt
        self.confidenceBand = confidenceBand
    }

    var attemptCount: Int { correctCount + supportedCorrectCount + mistakeCount }

    var independentCorrectCount: Int { correctCount }

    var totalSuccessfulCount: Int { correctCount + supportedCorrectCount }
}

struct SpacedRepetitionSelectionPolicy: Codable, Equatable, Hashable {
    let maximumItemCount: Int
    let dueItemRatio: Double
    let reviewNeededPriority: Int
    let newItemPriority: Int
    let steadyPriority: Int

    init(
        maximumItemCount: Int = 6,
        dueItemRatio: Double = 0.7,
        reviewNeededPriority: Int = 0,
        newItemPriority: Int = 1,
        steadyPriority: Int = 3
    ) {
        self.maximumItemCount = max(1, maximumItemCount)
        self.dueItemRatio = min(max(dueItemRatio, 0), 1)
        self.reviewNeededPriority = reviewNeededPriority
        self.newItemPriority = newItemPriority
        self.steadyPriority = steadyPriority
    }
}

struct SpacedRepetitionUpdate: Codable, Equatable, Hashable {
    let key: GameplayExposureKey
    let outcome: GameplayExposureOutcome
    let occurredAt: Date

    var wasCorrect: Bool { outcome != .incorrect }

    init(key: GameplayExposureKey, outcome: GameplayExposureOutcome, occurredAt: Date) {
        self.key = key
        self.outcome = outcome
        self.occurredAt = occurredAt
    }

    init(key: GameplayExposureKey, wasCorrect: Bool, occurredAt: Date) {
        self.init(key: key, outcome: wasCorrect ? .correct : .incorrect, occurredAt: occurredAt)
    }
}
