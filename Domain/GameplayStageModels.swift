import Foundation

enum GameplayStageKind: String, Codable, CaseIterable, Equatable, Hashable {
    case flashcards
    case easyMemory
    case flipMemory
    case bondBlast
    case multipleChoice
}

struct GameplayCategory: Identifiable, Codable, Equatable, Hashable {
    let id: String
    let title: String
    let subtitle: String
}

struct GameplayPropertyType: Identifiable, Codable, Equatable, Hashable {
    let id: String
    let displayName: String
    let prompt: String
}

struct GameplayProperty: Identifiable, Codable, Equatable, Hashable {
    let id: String
    let typeID: String
    let value: String
    let explanation: String
    let visualKey: String?
    let visualAssetName: String?

    init(
        id: String,
        typeID: String,
        value: String,
        explanation: String = "",
        visualKey: String? = nil,
        visualAssetName: String? = nil
    ) {
        self.id = id
        self.typeID = typeID
        self.value = value
        self.explanation = explanation
        self.visualKey = visualKey
        self.visualAssetName = visualAssetName
    }
}

struct GameplayEntity: Identifiable, Codable, Equatable, Hashable {
    let id: String
    let name: String
    let summary: String
    let visualKey: String?
    let visualAssetName: String?
    let properties: [GameplayProperty]

    init(
        id: String,
        name: String,
        summary: String = "",
        visualKey: String? = nil,
        visualAssetName: String? = nil,
        properties: [GameplayProperty]
    ) {
        self.id = id
        self.name = name
        self.summary = summary
        self.visualKey = visualKey
        self.visualAssetName = visualAssetName
        self.properties = properties
    }
}

struct GameplayStageDefinition: Identifiable, Codable, Equatable, Hashable {
    let id: String
    let kind: GameplayStageKind
    let title: String
    let prompt: String
    let propertyTypeIDs: [String]
    let maximumItemCount: Int

    /// Pairing/card stages may review several items in one stage while only
    /// showing a child-sized turn at a time. This keeps Lab/Gameplay stages
    /// aligned with the Numbers Bond Blast tap-to-select rhythm without forcing
    /// a long scrolling board.
    var recommendedTurnItemCount: Int {
        switch kind {
        case .flashcards:
            return 1
        case .easyMemory, .flipMemory:
            return min(maximumItemCount, 2)
        case .bondBlast:
            return min(maximumItemCount, 3)
        case .multipleChoice:
            return 1
        }
    }

    init(
        id: String,
        kind: GameplayStageKind,
        title: String,
        prompt: String,
        propertyTypeIDs: [String] = [],
        maximumItemCount: Int = 6
    ) {
        self.id = id
        self.kind = kind
        self.title = title
        self.prompt = prompt
        self.propertyTypeIDs = propertyTypeIDs
        self.maximumItemCount = max(1, maximumItemCount)
    }
}

struct GameplayProgressionPolicy: Codable, Equatable, Hashable {
    let minimumAccuracyToAdvance: Double
    let retryMissedItemsFirst: Bool

    init(minimumAccuracyToAdvance: Double = 0.7, retryMissedItemsFirst: Bool = true) {
        self.minimumAccuracyToAdvance = min(max(minimumAccuracyToAdvance, 0), 1)
        self.retryMissedItemsFirst = retryMissedItemsFirst
    }
}

struct GameplayThreadDefinition: Identifiable, Codable, Equatable {
    let id: String
    let title: String
    let category: GameplayCategory
    let propertyTypes: [GameplayPropertyType]
    let entities: [GameplayEntity]
    let stages: [GameplayStageDefinition]
    let progressionPolicy: GameplayProgressionPolicy

    var propertyTypesByID: [String: GameplayPropertyType] {
        Dictionary(uniqueKeysWithValues: propertyTypes.map { ($0.id, $0) })
    }

    init(
        id: String,
        title: String,
        category: GameplayCategory,
        propertyTypes: [GameplayPropertyType],
        entities: [GameplayEntity],
        stages: [GameplayStageDefinition] = GameplayThreadDefinition.defaultStages,
        progressionPolicy: GameplayProgressionPolicy = GameplayProgressionPolicy()
    ) {
        self.id = id
        self.title = title
        self.category = category
        self.propertyTypes = propertyTypes
        self.entities = entities
        self.stages = stages
        self.progressionPolicy = progressionPolicy
    }

    static let defaultStages: [GameplayStageDefinition] = [
        GameplayStageDefinition(id: "flashcards", kind: .flashcards, title: "Look + Learn", prompt: "Meet each card.", maximumItemCount: 6),
        GameplayStageDefinition(id: "easy-memory", kind: .easyMemory, title: "Easy Memory", prompt: "Match with the cards still visible.", maximumItemCount: 6),
        GameplayStageDefinition(id: "flip-memory", kind: .flipMemory, title: "Flip Memory", prompt: "Remember where the matches are.", maximumItemCount: 6),
        GameplayStageDefinition(id: "bond-blast", kind: .bondBlast, title: "Bond Blast", prompt: "Connect names, pictures, and facts.", maximumItemCount: 6),
        GameplayStageDefinition(id: "multiple-choice", kind: .multipleChoice, title: "Quiz", prompt: "Pick the best answer.")
    ]
}

struct GameplayRoundItem: Identifiable, Codable, Equatable, Hashable {
    let id: String
    let entityID: String
    let propertyID: String?
    let propertyTypeID: String?
}

struct GameplayRoundDefinition: Identifiable, Codable, Equatable, Hashable {
    let id: String
    let stageID: String
    let kind: GameplayStageKind
    let items: [GameplayRoundItem]
    let seed: UInt64
}

struct GameplayStageResult: Identifiable, Codable, Equatable, Hashable {
    let id: String
    let stageID: String
    let correctCount: Int
    let mistakeCount: Int
    let hintsUsed: Int
    let durationSeconds: TimeInterval
    let completedAt: Date

    var attemptedCount: Int { correctCount + mistakeCount }
    var accuracy: Double {
        guard attemptedCount > 0 else { return 0 }
        return Double(correctCount) / Double(attemptedCount)
    }

    var scorePoints: Int {
        max(0, correctCount * 10 - mistakeCount * 4 - hintsUsed * 2)
    }

    var averageSecondsPerAttempt: TimeInterval {
        guard attemptedCount > 0 else { return durationSeconds }
        return durationSeconds / Double(attemptedCount)
    }
}

struct GameplayScoreSummary: Codable, Equatable, Hashable {
    let correctCount: Int
    let mistakeCount: Int
    let hintsUsed: Int
    let durationSeconds: TimeInterval
    let stars: Int

    var attemptedCount: Int { correctCount + mistakeCount }
    var accuracy: Double {
        guard attemptedCount > 0 else { return 0 }
        return Double(correctCount) / Double(attemptedCount)
    }

    var scorePoints: Int {
        max(0, correctCount * 10 - mistakeCount * 4 - hintsUsed * 2)
    }

    var averageSecondsPerAttempt: TimeInterval {
        guard attemptedCount > 0 else { return durationSeconds }
        return durationSeconds / Double(attemptedCount)
    }

    var formattedAccuracy: String {
        "\(Int((accuracy * 100).rounded()))%"
    }

    var formattedDuration: String {
        let seconds = max(0, Int(durationSeconds.rounded()))
        let minutes = seconds / 60
        let remainingSeconds = seconds % 60
        return minutes > 0 ? "\(minutes)m \(remainingSeconds)s" : "\(remainingSeconds)s"
    }

    static func summarize(_ results: [GameplayStageResult]) -> GameplayScoreSummary {
        let correct = results.reduce(0) { $0 + $1.correctCount }
        let mistakes = results.reduce(0) { $0 + $1.mistakeCount }
        let hints = results.reduce(0) { $0 + $1.hintsUsed }
        let duration = results.reduce(0) { $0 + $1.durationSeconds }
        let attempts = max(correct + mistakes, 1)
        let accuracy = Double(correct) / Double(attempts)
        let baseStars: Int
        if accuracy >= 0.9 { baseStars = 3 }
        else if accuracy >= 0.7 { baseStars = 2 }
        else if accuracy >= 0.45 { baseStars = 1 }
        else { baseStars = 0 }
        let hintPenalty = hints >= 4 ? 1 : 0
        return GameplayScoreSummary(
            correctCount: correct,
            mistakeCount: mistakes,
            hintsUsed: hints,
            durationSeconds: duration,
            stars: max(0, baseStars - hintPenalty)
        )
    }
}
