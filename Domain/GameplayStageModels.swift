import Foundation

struct GameplayThreadDefinition: Identifiable, Equatable, Codable {
    let id: String
    let title: String
    let subtitle: String
    let category: GameplayCategory
    let entities: [GameplayEntity]
    let propertyTypes: [GameplayPropertyType]
    let stages: [GameplayStageDefinition]
    let progressionPolicy: GameplayProgressionPolicy

    init(
        id: String,
        title: String,
        subtitle: String = "",
        category: GameplayCategory,
        entities: [GameplayEntity],
        propertyTypes: [GameplayPropertyType],
        stages: [GameplayStageDefinition] = GameplayStageKind.allCases.map { GameplayStageDefinition(kind: $0) },
        progressionPolicy: GameplayProgressionPolicy = .standard
    ) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.category = category
        self.entities = entities
        self.propertyTypes = propertyTypes.sorted { $0.learningPriority < $1.learningPriority }
        self.stages = stages
        self.progressionPolicy = progressionPolicy
    }

    func propertyType(for id: String) -> GameplayPropertyType? { propertyTypes.first { $0.id == id } }
    func entity(for id: String) -> GameplayEntity? { entities.first { $0.id == id } }
}

enum GameplayCategory: String, CaseIterable, Equatable, Codable {
    case flashcards
    case countries
    case fruits
    case waterCycle
    case shapes
    case sounds
    case custom
}

struct GameplayEntity: Identifiable, Equatable, Codable {
    let id: String
    let name: String
    let visual: GameplayVisual
    let audioCue: GameplayAudioCue?
    let explanation: String
    let properties: [GameplayProperty]

    init(
        id: String,
        name: String,
        visual: GameplayVisual,
        audioCue: GameplayAudioCue? = nil,
        explanation: String,
        properties: [GameplayProperty] = []
    ) {
        self.id = id
        self.name = name
        self.visual = visual
        self.audioCue = audioCue
        self.explanation = explanation
        self.properties = properties
    }

    func properties(ofType typeID: String) -> [GameplayProperty] { properties.filter { $0.typeID == typeID } }
}

enum GameplayVisual: Equatable, Codable, Hashable {
    case emoji(String)
    case asset(String)
    case systemImage(String)
    case text(String)
}

struct GameplayAudioCue: Equatable, Codable, Hashable {
    let text: String
    let assetName: String?

    init(text: String, assetName: String? = nil) {
        self.text = text
        self.assetName = assetName
    }
}

struct GameplayPropertyType: Identifiable, Equatable, Codable, Hashable {
    let id: String
    let title: String
    let icon: String?
    let learningPriority: Int

    init(id: String, title: String, icon: String? = nil, learningPriority: Int = 0) {
        self.id = id
        self.title = title
        self.icon = icon
        self.learningPriority = learningPriority
    }
}

struct GameplayProperty: Identifiable, Equatable, Codable, Hashable {
    let id: String
    let typeID: String
    let value: String
    let visual: GameplayVisual?
    let audioCue: GameplayAudioCue?
    let explanation: String?

    init(
        id: String,
        typeID: String,
        value: String,
        visual: GameplayVisual? = nil,
        audioCue: GameplayAudioCue? = nil,
        explanation: String? = nil
    ) {
        self.id = id
        self.typeID = typeID
        self.value = value
        self.visual = visual
        self.audioCue = audioCue
        self.explanation = explanation
    }
}

enum GameplayStageKind: String, CaseIterable, Equatable, Codable, Hashable {
    case flashcards
    case easyMemory
    case flipMemory
    case bondBlast
    case multipleChoice

    var title: String {
        switch self {
        case .flashcards: return "Flashcards"
        case .easyMemory: return "Easy Memory"
        case .flipMemory: return "Flip Memory"
        case .bondBlast: return "Bond Blast"
        case .multipleChoice: return "Quiz"
        }
    }
}

struct GameplayStageDefinition: Identifiable, Equatable, Codable {
    let id: String
    let kind: GameplayStageKind
    let title: String
    let pairCount: Int
    let focusedPropertyTypeIDs: [String]
    let allowsHints: Bool

    init(
        id: String? = nil,
        kind: GameplayStageKind,
        title: String? = nil,
        pairCount: Int = 4,
        focusedPropertyTypeIDs: [String] = [],
        allowsHints: Bool = true
    ) {
        self.id = id ?? kind.rawValue
        self.kind = kind
        self.title = title ?? kind.title
        self.pairCount = pairCount
        self.focusedPropertyTypeIDs = focusedPropertyTypeIDs
        self.allowsHints = allowsHints
    }
}

struct GameplayRoundDefinition: Identifiable, Equatable, Codable {
    let id: UUID
    let stageKind: GameplayStageKind
    let entityIDs: [String]
    let propertyTypeIDs: [String]
    let seed: UInt64?

    init(id: UUID = UUID(), stageKind: GameplayStageKind, entityIDs: [String], propertyTypeIDs: [String] = [], seed: UInt64? = nil) {
        self.id = id
        self.stageKind = stageKind
        self.entityIDs = entityIDs
        self.propertyTypeIDs = propertyTypeIDs
        self.seed = seed
    }
}

struct GameplayProgressionPolicy: Equatable, Codable {
    let requiredStageOrder: [GameplayStageKind]
    let minimumAccuracyToAdvance: Double
    let reviewWeakItemsBetweenStages: Bool
    let newItemRatio: Double
    let steadyReviewRatio: Double

    static let standard = GameplayProgressionPolicy(
        requiredStageOrder: GameplayStageKind.allCases,
        minimumAccuracyToAdvance: 0.7,
        reviewWeakItemsBetweenStages: true,
        newItemRatio: 0.25,
        steadyReviewRatio: 0.15
    )
}

struct GameplayStageScore: Identifiable, Equatable, Codable {
    let id: UUID
    let sessionID: UUID
    let stageKind: GameplayStageKind
    let startedAt: Date
    var endedAt: Date?
    var correctCount: Int
    var incorrectCount: Int
    var attempts: Int
    var hintsUsed: Int
    var currentStreak: Int
    var bestStreak: Int
    var firstTryCorrectCount: Int

    init(id: UUID = UUID(), sessionID: UUID, stageKind: GameplayStageKind, startedAt: Date) {
        self.id = id
        self.sessionID = sessionID
        self.stageKind = stageKind
        self.startedAt = startedAt
        self.endedAt = nil
        self.correctCount = 0
        self.incorrectCount = 0
        self.attempts = 0
        self.hintsUsed = 0
        self.currentStreak = 0
        self.bestStreak = 0
        self.firstTryCorrectCount = 0
    }

    var elapsedSeconds: TimeInterval { (endedAt ?? startedAt).timeIntervalSince(startedAt) }

    var accuracy: Double {
        let total = correctCount + incorrectCount
        guard total > 0 else { return 0 }
        return Double(correctCount) / Double(total)
    }

    var points: Int {
        let firstTryPoints = firstTryCorrectCount * 10
        let supportedCorrectPoints = max(0, correctCount - firstTryCorrectCount) * 6
        let streakBonus = bestStreak * 2
        let hintPenalty = hintsUsed * 2
        return max(0, firstTryPoints + supportedCorrectPoints + streakBonus - hintPenalty)
    }

    mutating func recordAnswer(correct: Bool, firstTry: Bool, usedHint: Bool = false) {
        attempts += 1
        if usedHint { hintsUsed += 1 }

        if correct {
            correctCount += 1
            if firstTry { firstTryCorrectCount += 1 }
            currentStreak += 1
            bestStreak = max(bestStreak, currentStreak)
        } else {
            incorrectCount += 1
            currentStreak = 0
        }
    }

    mutating func finish(at endedAt: Date) { self.endedAt = endedAt }
}

struct GameplaySessionScore: Identifiable, Equatable, Codable {
    let id: UUID
    let threadID: String
    let startedAt: Date
    var endedAt: Date?
    var stageScores: [GameplayStageScore]

    init(id: UUID = UUID(), threadID: String, startedAt: Date, endedAt: Date? = nil, stageScores: [GameplayStageScore] = []) {
        self.id = id
        self.threadID = threadID
        self.startedAt = startedAt
        self.endedAt = endedAt
        self.stageScores = stageScores
    }

    var totalCorrect: Int { stageScores.reduce(0) { $0 + $1.correctCount } }
    var totalIncorrect: Int { stageScores.reduce(0) { $0 + $1.incorrectCount } }
    var totalAttempts: Int { stageScores.reduce(0) { $0 + $1.attempts } }
    var hintsUsed: Int { stageScores.reduce(0) { $0 + $1.hintsUsed } }
    var totalPoints: Int { stageScores.reduce(0) { $0 + $1.points } }
    var totalElapsedSeconds: TimeInterval { stageScores.reduce(0) { $0 + $1.elapsedSeconds } }

    var accuracy: Double {
        let total = totalCorrect + totalIncorrect
        guard total > 0 else { return 0 }
        return Double(totalCorrect) / Double(total)
    }

    var starRating: Int {
        switch accuracy {
        case 0.9...: return 3
        case 0.7..<0.9: return 2
        case 0.45..<0.7: return 1
        default: return 0
        }
    }
}
