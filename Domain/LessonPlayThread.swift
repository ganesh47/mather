import Foundation

enum LessonPlayStageKind: String, Codable, CaseIterable, Equatable, Hashable {
    case lookLearnFlashcards
    case pictureNameMatch
    case contextualAsk
    case mixMatchFinale
}

struct LessonPlayCard: Identifiable, Codable, Equatable, Hashable {
    let id: String
    let title: String
    let prompt: String
    let answer: String
    let detail: String
    let assetName: String?
}

struct LessonSafeAskTurn: Identifiable, Codable, Equatable, Hashable {
    let id: String
    let question: String
    let answer: String
}

struct LessonSafeAskResponse: Equatable {
    enum Kind: Equatable {
        case answer
        case refusal
    }

    let kind: Kind
    let spokenText: String
}

enum LessonSafeAskTurnRequest: Equatable {
    case suggestedTurn(id: String)
    case unsupportedTopic
}

struct LessonSafeAskSession: Equatable {
    static let allowsMicrophoneInput = false
    static let allowsFreeformTextInput = false

    let cardID: String
    let suggestedTurns: [LessonSafeAskTurn]
    private(set) var selectedTurnIDs: [String] = []

    mutating func respond(to request: LessonSafeAskTurnRequest) -> LessonSafeAskResponse {
        switch request {
        case .unsupportedTopic:
            return Self.offScopeResponse
        case .suggestedTurn(let id):
            guard let turn = suggestedTurns.first(where: { $0.id == id }) else {
                return Self.offScopeResponse
            }
            selectedTurnIDs.append(id)
            return LessonSafeAskResponse(kind: .answer, spokenText: turn.answer)
        }
    }

    private static var offScopeResponse: LessonSafeAskResponse {
        LessonSafeAskResponse(
            kind: .refusal,
            spokenText: "I can only talk about this card. Pick one of the card questions."
        )
    }
}

struct LessonPlayStage: Identifiable, Codable, Equatable, Hashable {
    let id: String
    let kind: LessonPlayStageKind
    let title: String
    let prompt: String
}

struct LessonPlayThread: Identifiable, Codable, Equatable {
    let id: String
    let title: String
    let stages: [LessonPlayStage]
    let cards: [LessonPlayCard]
    private(set) var activeStageIndex: Int
    private(set) var completedStageIDs: Set<String>

    init(
        id: String,
        title: String,
        stages: [LessonPlayStage],
        cards: [LessonPlayCard],
        activeStageIndex: Int = 0,
        completedStageIDs: Set<String> = []
    ) {
        self.id = id
        self.title = title
        self.stages = stages
        self.cards = cards
        self.activeStageIndex = min(max(activeStageIndex, 0), max(stages.count - 1, 0))
        self.completedStageIDs = completedStageIDs
    }

    var activeStage: LessonPlayStage {
        stages[activeStageIndex]
    }

    var isComplete: Bool {
        completedStageIDs.count == stages.count
    }

    var progressLabel: String {
        "Level \(activeStageIndex + 1) of \(stages.count)"
    }

    var progress: Double {
        guard !stages.isEmpty else { return 1 }
        return Double(completedStageIDs.count) / Double(stages.count)
    }

    mutating func completeActiveStage() {
        completedStageIDs.insert(activeStage.id)
        guard activeStageIndex < stages.count - 1 else { return }
        activeStageIndex += 1
    }

    mutating func resetProgress() {
        activeStageIndex = 0
        completedStageIDs.removeAll()
    }
}
