import Foundation
import SwiftData

enum SliceStage: String, Codable, CaseIterable, Identifiable {
    case concrete
    case pictorial
    case abstract
    case transfer
    case done

    var id: String { rawValue }

    var title: String {
        switch self {
        case .concrete: "Make it"
        case .pictorial: "Break it"
        case .abstract: "Write it"
        case .transfer: "Show it again"
        case .done: "Done"
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
