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

struct GameplayExposureRecord: Codable, Equatable, Hashable {
    let key: GameplayExposureKey
    var correctCount: Int
    var mistakeCount: Int
    var lastSeenAt: Date?
    var dueAt: Date
    var confidenceBand: GameplayConfidenceBand

    init(
        key: GameplayExposureKey,
        correctCount: Int = 0,
        mistakeCount: Int = 0,
        lastSeenAt: Date? = nil,
        dueAt: Date = .distantPast,
        confidenceBand: GameplayConfidenceBand = .new
    ) {
        self.key = key
        self.correctCount = correctCount
        self.mistakeCount = mistakeCount
        self.lastSeenAt = lastSeenAt
        self.dueAt = dueAt
        self.confidenceBand = confidenceBand
    }

    var attemptCount: Int { correctCount + mistakeCount }
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
    let wasCorrect: Bool
    let occurredAt: Date
}
