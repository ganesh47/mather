import Foundation
import SwiftData

enum SliceStage: String, Codable, CaseIterable, Identifiable {
    case concrete
    case pictorial
    case abstract
    case transfer
    case bondMatch
    case done

    var id: String { rawValue }

    var title: String {
        switch self {
        case .concrete:  "Make it"
        case .pictorial: "Break it"
        case .abstract:  "Write it"
        case .transfer:  "Show it again"
        case .bondMatch: "Bond Blast!"
        case .done:      "Done"
        }
    }
}

enum SliceEventType: String, Codable {
    case sessionStart = "session_start"
    case problemPresented = "problem_presented"
    case interaction
    case hintUsed = "hint_used"
    case stageTransition = "stage_transition"
    case problemCompleted = "problem_completed"
    case sessionEnd = "session_end"
    case roomQuestStarted = "room_quest_started"
    case roomQuestSetupComplete = "room_quest_setup_complete"
    case roomQuestSpotVisited = "room_quest_spot_visited"
    case roomQuestPhaseComplete = "room_quest_phase_complete"
    case roomQuestAbandoned = "room_quest_abandoned"
    case roomQuestCompleted = "room_quest_completed"
}

struct SliceConfig: Codable, Equatable {
    var maxProblems: Int = 6
    var minTarget: Int = 6
    var maxTarget: Int = 10
    var showTransfer: Bool = true
    var audioEnabled: Bool = true
    var deterministicMode: Bool = true

    var targetRange: ClosedRange<Int> { minTarget...maxTarget }
}

struct SliceProblem: Identifiable, Codable, Equatable {
    let id: UUID
    let target: Int
    let decompositionA: Int
    let decompositionB: Int
    let skillTag: String
    let difficultyTier: Int

    init(
        id: UUID = UUID(),
        target: Int,
        decompositionA: Int,
        decompositionB: Int,
        skillTag: String = "make_and_break_to_10",
        difficultyTier: Int = 1
    ) {
        self.id = id
        self.target = target
        self.decompositionA = decompositionA
        self.decompositionB = decompositionB
        self.skillTag = skillTag
        self.difficultyTier = difficultyTier
    }
}

struct ProblemState: Codable, Equatable {
    var stage: SliceStage = .concrete
    var attempts: Int = 0
    var isCorrect: Bool = false
    var timeSpentMs: Int = 0
}

struct SliceEvent: Identifiable, Codable, Equatable {
    let id: UUID
    let type: SliceEventType
    let timestamp: Date
    let payload: [String: String]

    init(
        id: UUID = UUID(),
        type: SliceEventType,
        timestamp: Date = .now,
        payload: [String: String] = [:]
    ) {
        self.id = id
        self.type = type
        self.timestamp = timestamp
        self.payload = payload
    }
}

struct ProblemSession: Codable, Equatable {
    let problemId: UUID
    let givenAt: Date
    var events: [SliceEvent]
    var firstTryCorrect: Bool
    var attemptCount: Int
    var retryCount: Int
    var transferCorrect: Bool
}

struct SliceSession: Codable, Equatable {
    var sessionId: UUID
    var startedAt: Date
    var endedAt: Date?
    var problems: [ProblemSession]
    var schemaVersion: Int
}

struct ParentDigest: Codable, Equatable {
    var objectiveTitle: String
    var firstAttemptAccuracy: Double
    var medianLatencyMs: Int
    var problemsCompleted: Int
    var transferCorrectCount: Int
    var nextTargetHint: String
}

struct SessionSummaryDraft: Equatable {
    var sessionId: String
    var startedAt: Date
    var endedAt: Date
    var objectiveTitle: String
    var problemsCompleted: Int
    var firstAttemptAccuracy: Double
    var transferCorrectCount: Int
    var medianLatencyMs: Int
    var nextTargetHint: String
    var exportFileName: String
}

// MARK: - Bond Blast models

/// One complement pair in the Bond Blast finale stage.
/// `left + right == target` for all pairs in a `BondMatchState`.
struct ComplementPair: Identifiable, Equatable {
    let id: UUID
    let left: Int
    let right: Int
    var isMatched: Bool

    init(left: Int, right: Int, isMatched: Bool = false) {
        self.id = UUID()
        self.left = left
        self.right = right
        self.isMatched = isMatched
    }
}

/// State for the Bond Blast finale stage — held by `VerticalSliceEngine`.
struct BondMatchState: Equatable {
    let target: Int
    /// Canonical pair list ordered by ascending left value.
    var pairs: [ComplementPair]

    var matchCount: Int { pairs.filter(\.isMatched).count }
    var isComplete: Bool { pairs.allSatisfy(\.isMatched) }

    /// Generate all unique complement pairs (a, b) where a ≤ b and a + b == target.
    /// Excludes (0, target) — zero is not a meaningful addend in this context.
    static func makePairs(for target: Int) -> [ComplementPair] {
        guard target >= 2 else { return [] }
        return (1...(target - 1))
            .filter { $0 <= target - $0 }
            .map { a in ComplementPair(left: a, right: target - a) }
    }
}

// MARK: - Room Quest models

enum RoomQuestStationRole: String, Codable, Equatable {
    case redRocket
    case blueBubble

    var title: String {
        switch self {
        case .redRocket: "Red Rocket"
        case .blueBubble: "Blue Bubble"
        }
    }

    var colorName: String {
        switch self {
        case .redRocket: "red"
        case .blueBubble: "blue"
        }
    }

    var icon: String {
        switch self {
        case .redRocket: "🚀"
        case .blueBubble: "🫧"
        }
    }

    var scanPrompt: String {
        switch self {
        case .redRocket: "Find and scan the Red Rocket marker."
        case .blueBubble: "Find and scan the Blue Bubble marker."
        }
    }

    var fallbackButtonTitle: String {
        switch self {
        case .redRocket: "I found Red Rocket"
        case .blueBubble: "I found Blue Bubble"
        }
    }
}

struct RoomQuestStation: Equatable, Codable, Identifiable {
    let id: RoomQuestStationRole
    let role: RoomQuestStationRole
    let quantity: Int
    var isRegistered: Bool = false
}

@Model
final class StoredSessionSummary {
    @Attribute(.unique) var sessionId: String
    var startedAt: Date
    var endedAt: Date
    var objectiveTitle: String
    var problemsCompleted: Int
    var firstAttemptAccuracy: Double
    var transferCorrectCount: Int
    var medianLatencyMs: Int
    var nextTargetHint: String
    var exportFileName: String

    init(from draft: SessionSummaryDraft) {
        sessionId = draft.sessionId
        startedAt = draft.startedAt
        endedAt = draft.endedAt
        objectiveTitle = draft.objectiveTitle
        problemsCompleted = draft.problemsCompleted
        firstAttemptAccuracy = draft.firstAttemptAccuracy
        transferCorrectCount = draft.transferCorrectCount
        medianLatencyMs = draft.medianLatencyMs
        nextTargetHint = draft.nextTargetHint
        exportFileName = draft.exportFileName
    }
}
