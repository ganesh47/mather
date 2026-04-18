import Foundation
import SwiftData

enum SliceStage: String, Codable, CaseIterable, Identifiable {
    case concrete
    case pictorial
    case abstract
    case transfer
    case gravitySplit
    case bondMatch
    case done

    var id: String { rawValue }

    var title: String {
        switch self {
        case .concrete:     "Make it"
        case .pictorial:    "Bond Blast!"
        case .abstract:     "Write it"
        case .transfer:     "Show it"
        case .gravitySplit: "Balance it!"
        case .bondMatch:    "Bond Blast!"
        case .done:         "Done"
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
    case roomQuestReferenceCaptureStarted = "room_quest_reference_capture_started"
    case roomQuestReferenceCaptureCompleted = "room_quest_reference_capture_completed"
    case sumSprintStarted = "sum_sprint_started"
    case sumSprintCardShown = "sum_sprint_card_shown"
    case sumSprintCardAnswered = "sum_sprint_card_answered"
    case sumSprintCompleted = "sum_sprint_completed"
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

// MARK: - Gravity Split models

/// State for the Gravity Split balance stage — held by `VerticalSliceEngine`.
///
/// The child tilts the device; counters slide under simulated gravity between two pans.
/// `isLocked` becomes true when the split matches the problem's decomposition exactly.
struct GravitySplitState: Equatable {
    let target: Int
    let decompositionA: Int   // expected left-pan count
    let decompositionB: Int   // expected right-pan count
    var leftCount: Int        // current left-pan count (starts at 0)
    var rightCount: Int       // always target − leftCount

    var isLocked: Bool {
        leftCount == decompositionA && rightCount == decompositionB
    }

    init(problem: SliceProblem) {
        target         = problem.target
        decompositionA = problem.decompositionA
        decompositionB = problem.decompositionB
        // Start with target−1 on the left pan (far-left imbalance) so the beam
        // is visibly unbalanced and the answer is never the starting position.
        leftCount      = max(0, problem.target - 1)
        rightCount     = 1
    }

    /// Sets `leftCount` to `count` (clamped 0…target) and derives `rightCount`.
    mutating func setLeft(_ count: Int) {
        leftCount  = min(max(count, 0), target)
        rightCount = target - leftCount
    }
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

enum RoomQuestStationRole: String, Codable, Equatable, CaseIterable {
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
    var verificationMethod: RoomQuestStationVerificationMethod? = nil
    var referenceCaptureState: RoomQuestReferenceCaptureState = .notCaptured
    var referenceNote: String? = nil
}

enum RoomQuestStationVerificationMethod: String, Codable, Equatable {
    case cameraVerified
    case manualConfirmed

    var badgeTitle: String {
        switch self {
        case .cameraVerified: "Camera verified"
        case .manualConfirmed: "Confirmed manually"
        }
    }
}

enum RoomQuestReferenceCaptureState: String, Equatable, Codable {
    case notCaptured
    case captured
    case manualFallback

    var badgeTitle: String {
        switch self {
        case .notCaptured: "Reference not saved"
        case .captured: "Reference saved"
        case .manualFallback: "Reference skipped"
        }
    }
}

enum RoomQuestScanState: Equatable {
    case idle
    case scanning(role: RoomQuestStationRole)
    case celebrating(role: RoomQuestStationRole, usedARCelebration: Bool)
    case almost(role: RoomQuestStationRole, message: String)
    case failed(role: RoomQuestStationRole, message: String)
}

struct RoomQuestStationReferenceDraft: Equatable, Codable {
    let role: RoomQuestStationRole
    let markerPayload: String?
    let capturedAt: Date
    let note: String
    let captureState: RoomQuestReferenceCaptureState
}

@Model
final class StoredRoomQuestStationReference {
    var roleRawValue: String
    var markerPayload: String?
    var capturedAt: Date
    var note: String
    var captureStateRawValue: String

    init(role: RoomQuestStationRole, markerPayload: String?, capturedAt: Date, note: String, captureState: RoomQuestReferenceCaptureState) {
        self.roleRawValue = role.rawValue
        self.markerPayload = markerPayload
        self.capturedAt = capturedAt
        self.note = note
        self.captureStateRawValue = captureState.rawValue
    }

    var role: RoomQuestStationRole? {
        RoomQuestStationRole(rawValue: roleRawValue)
    }

    var captureState: RoomQuestReferenceCaptureState? {
        RoomQuestReferenceCaptureState(rawValue: captureStateRawValue)
    }
}

@Model
final class StoredFactRecord {
    @Attribute(.unique) var factKey: String  // "\(addendA)+\(addendB)"
    var addendA: Int
    var addendB: Int
    var boxRawValue: Int
    var sessionsSinceLastSeen: Int
    var correctStreak: Int
    var lastSeenAt: Date?

    init(factKey: String, addendA: Int, addendB: Int) {
        self.factKey = factKey
        self.addendA = addendA
        self.addendB = addendB
        self.boxRawValue = 0
        self.sessionsSinceLastSeen = 0
        self.correctStreak = 0
        self.lastSeenAt = nil
    }
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
