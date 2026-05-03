import Foundation

struct GameplayRepetitionKey: Hashable, Equatable, Codable, Comparable {
    let entityID: String
    let propertyTypeID: String?
    let propertyValueID: String?

    init(entityID: String, propertyTypeID: String? = nil, propertyValueID: String? = nil) {
        self.entityID = entityID
        self.propertyTypeID = propertyTypeID
        self.propertyValueID = propertyValueID
    }

    static func < (lhs: GameplayRepetitionKey, rhs: GameplayRepetitionKey) -> Bool {
        [lhs.entityID, lhs.propertyTypeID ?? "", lhs.propertyValueID ?? ""] < [rhs.entityID, rhs.propertyTypeID ?? "", rhs.propertyValueID ?? ""]
    }
}

enum GameplayConfidenceBand: String, CaseIterable, Equatable, Codable {
    case new
    case learning
    case steady
    case reviewNeeded
    case mastered
}

struct GameplayExposureEvent: Identifiable, Equatable, Codable {
    let id: UUID
    let key: GameplayRepetitionKey
    let stageKind: GameplayStageKind
    let sessionID: UUID
    let seenAt: Date
    let wasCorrect: Bool?
    let attempts: Int
    let usedHint: Bool
    let responseTimeSeconds: TimeInterval?

    init(
        id: UUID = UUID(),
        key: GameplayRepetitionKey,
        stageKind: GameplayStageKind,
        sessionID: UUID,
        seenAt: Date,
        wasCorrect: Bool? = nil,
        attempts: Int = 0,
        usedHint: Bool = false,
        responseTimeSeconds: TimeInterval? = nil
    ) {
        self.id = id
        self.key = key
        self.stageKind = stageKind
        self.sessionID = sessionID
        self.seenAt = seenAt
        self.wasCorrect = wasCorrect
        self.attempts = attempts
        self.usedHint = usedHint
        self.responseTimeSeconds = responseTimeSeconds
    }
}

struct GameplayRepetitionState: Identifiable, Equatable, Codable {
    var id: GameplayRepetitionKey { key }
    let key: GameplayRepetitionKey
    var lastStageKind: GameplayStageKind?
    var lastSessionID: UUID?
    var exposureCount: Int
    var correctCount: Int
    var incorrectCount: Int
    var lastSeenAt: Date?
    var nextDueAt: Date
    var confidenceBand: GameplayConfidenceBand

    init(
        key: GameplayRepetitionKey,
        lastStageKind: GameplayStageKind? = nil,
        lastSessionID: UUID? = nil,
        exposureCount: Int = 0,
        correctCount: Int = 0,
        incorrectCount: Int = 0,
        lastSeenAt: Date? = nil,
        nextDueAt: Date = .distantPast,
        confidenceBand: GameplayConfidenceBand = .new
    ) {
        self.key = key
        self.lastStageKind = lastStageKind
        self.lastSessionID = lastSessionID
        self.exposureCount = exposureCount
        self.correctCount = correctCount
        self.incorrectCount = incorrectCount
        self.lastSeenAt = lastSeenAt
        self.nextDueAt = nextDueAt
        self.confidenceBand = confidenceBand
    }

    var accuracy: Double {
        guard exposureCount > 0 else { return 0 }
        return Double(correctCount) / Double(exposureCount)
    }

    var isWeak: Bool { confidenceBand == .reviewNeeded || confidenceBand == .learning || incorrectCount > correctCount }
    var isMastered: Bool { confidenceBand == .mastered }
}

protocol GameplayRepetitionStoring {
    func states(for keys: [GameplayRepetitionKey]) -> [GameplayRepetitionKey: GameplayRepetitionState]
    mutating func apply(_ events: [GameplayExposureEvent], at now: Date)
}

struct InMemoryGameplayRepetitionStore: GameplayRepetitionStoring {
    private(set) var statesByKey: [GameplayRepetitionKey: GameplayRepetitionState]

    init(states: [GameplayRepetitionState] = []) {
        self.statesByKey = Dictionary(uniqueKeysWithValues: states.map { ($0.key, $0) })
    }

    func states(for keys: [GameplayRepetitionKey]) -> [GameplayRepetitionKey: GameplayRepetitionState] {
        Dictionary(uniqueKeysWithValues: keys.map { key in
            (key, statesByKey[key] ?? GameplayRepetitionState(key: key))
        })
    }

    mutating func apply(_ events: [GameplayExposureEvent], at now: Date) {
        let scheduler = SpacedRepetitionScheduler()
        for event in events {
            let previous = statesByKey[event.key] ?? GameplayRepetitionState(key: event.key)
            statesByKey[event.key] = scheduler.updatedState(from: previous, with: event, at: now)
        }
    }
}
