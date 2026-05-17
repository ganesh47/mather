import Foundation
import SwiftData

enum SliceStage: String, Codable, CaseIterable, Identifiable {
    case storyAnchor
    case concrete
    case pictorial
    case abstract
    case transfer
    case gravitySplit
    case sumSprint
    case bondMatch
    case done

    var id: String { rawValue }

    var title: String {
        switch self {
        case .storyAnchor: "Story"
        case .concrete:     "Make it"
        case .pictorial:    "Bond Blast!"
        case .abstract:     "Write it"
        case .transfer:     "Show it"
        case .gravitySplit: "Gravity Split"
        case .sumSprint:    "Sum Sprint"
        case .bondMatch:    "Bond Blast!"
        case .done:         "Done"
        }
    }
}

enum SliceRouteMode: Equatable {
    case legacy(showTransfer: Bool, showGravitySplit: Bool, showBondMatch: Bool)
    case makeBreakLoopV2
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
    case routeQuestStarted = "route_quest_started"
    case routeQuestNodeStarted = "route_quest_node_started"
    case routeQuestTurnCompleted = "route_quest_turn_completed"
    case routeQuestStepCompleted = "route_quest_step_completed"
    case routeQuestStationConfirmed = "route_quest_station_confirmed"
    case routeQuestFallbackUsed = "route_quest_fallback_used"
    case routeQuestCompleted = "route_quest_completed"
    case routeQuestAbandoned = "route_quest_abandoned"
    case roomQuestReferenceCaptureStarted = "room_quest_reference_capture_started"
    case roomQuestReferenceCaptureCompleted = "room_quest_reference_capture_completed"
    case sumSprintStarted = "sum_sprint_started"
    case sumSprintCardShown = "sum_sprint_card_shown"
    case sumSprintCardAnswered = "sum_sprint_card_answered"
    case sumSprintCompleted = "sum_sprint_completed"
}

enum ParentTargetCap {
    static let minimum = 10
    static let maximum = 1_000
    static let step = 10
    static let quickPicks = [10, 20, 50, 100, 1_000]

    static func normalize(_ value: Int) -> Int {
        let clamped = min(max(value, minimum), maximum)
        return (clamped / step) * step
    }

    static func displayLabel(for value: Int) -> String {
        "Up to \(normalize(value))"
    }
}

struct SliceConfig: Codable, Equatable {
    private static let allowedTargets = 1...1_000

    var maxProblems: Int = 6
    var minTarget: Int = allowedTargets.lowerBound {
        didSet { minTarget = Self.clampTarget(minTarget) }
    }
    var maxTarget: Int = 20 {
        didSet { maxTarget = Self.clampTarget(maxTarget) }
    }
    var showTransfer: Bool = true
    var audioEnabled: Bool = true
    var deterministicMode: Bool = true

    init(
        maxProblems: Int = 6,
        minTarget: Int = allowedTargets.lowerBound,
        maxTarget: Int = 20,
        showTransfer: Bool = true,
        audioEnabled: Bool = true,
        deterministicMode: Bool = true
    ) {
        self.maxProblems = maxProblems
        self.minTarget = Self.clampTarget(minTarget)
        self.maxTarget = Self.clampTarget(maxTarget)
        self.showTransfer = showTransfer
        self.audioEnabled = audioEnabled
        self.deterministicMode = deterministicMode
    }

    var parentTargetCap: Int {
        get { ParentTargetCap.normalize(maxTarget) }
        set { maxTarget = ParentTargetCap.normalize(newValue) }
    }

    var targetRange: ClosedRange<Int> {
        let lower = Self.clampTarget(minTarget)
        let upper = Self.clampTarget(maxTarget)
        return min(lower, upper)...max(lower, upper)
    }

    private static func clampTarget(_ value: Int) -> Int {
        min(max(value, allowedTargets.lowerBound), allowedTargets.upperBound)
    }
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

enum KidProfilePersistence {
    static let defaultProfileId = "default-profile"
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
final class StoredKidProfile {
    @Attribute(.unique) var id: String
    var name: String
    var emoji: String
    var createdAt: Date

    init(id: String = UUID().uuidString, name: String, emoji: String, createdAt: Date = .now) {
        self.id = id
        self.name = name
        self.emoji = emoji
        self.createdAt = createdAt
    }
}

@Model
final class StoredTelemetryEvent {
    var sessionId: String
    var profileId: String = KidProfilePersistence.defaultProfileId
    var typeRawValue: String
    var timestamp: Date
    var encodedEvent: String

    init(sessionId: String, profileId: String, event: SliceEvent, encodedEvent: String) {
        self.sessionId = sessionId
        self.profileId = profileId
        self.typeRawValue = event.type.rawValue
        self.timestamp = event.timestamp
        self.encodedEvent = encodedEvent
    }
}

// MARK: - Gravity Split models

/// State for the Gravity Split balance stage — held by `VerticalSliceEngine`.
///
/// The child tilts the device; counters slide under simulated gravity between two pans.
/// `isLocked` becomes true when the split matches the problem's decomposition exactly.
struct GravitySplitState: Equatable {
    static let individualTokenLimit = 20

    let target: Int
    let decompositionA: Int   // expected left-pan count
    let decompositionB: Int   // expected right-pan count
    var leftCount: Int        // current left-pan count (starts at 0)
    var rightCount: Int       // current right-pan count (starts at 0)

    var isLocked: Bool {
        leftCount == decompositionA && rightCount == decompositionB
    }

    var usesGroupedRepresentation: Bool {
        target > Self.individualTokenLimit
    }

    var groupedStepValues: [Int] {
        GroupedNumberRepresentation(target).suggestedSteps
    }

    func remainingCapacity(for side: TransferSide) -> Int {
        switch side {
        case .left:
            max(0, decompositionA - leftCount)
        case .right:
            max(0, decompositionB - rightCount)
        }
    }

    func currentCount(for side: TransferSide) -> Int {
        switch side {
        case .left:
            leftCount
        case .right:
            rightCount
        }
    }

    init(problem: SliceProblem) {
        target         = problem.target
        decompositionA = problem.decompositionA
        decompositionB = problem.decompositionB
        leftCount      = 0
        rightCount     = 0
    }

    mutating func adjustLeft(by delta: Int) {
        leftCount = min(max(leftCount + delta, 0), decompositionA)
    }

    mutating func adjustRight(by delta: Int) {
        rightCount = min(max(rightCount + delta, 0), decompositionB)
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
    static let highTargetPairLimit = 10

    var matchCount: Int { pairs.filter(\.isMatched).count }
    var isComplete: Bool { pairs.allSatisfy(\.isMatched) }

    /// Generate all unique complement pairs (a, b) where a ≤ b and a + b == target.
    /// Excludes (0, target) — zero is not a meaningful addend in this context.
    /// For targets above 20, returns a small deterministic sample of exact pairs
    /// so Bond Blast never creates hundreds of cards.
    static func makePairs(for target: Int) -> [ComplementPair] {
        guard target >= 2 else { return [] }
        if target <= 20 {
            return allPairLeftValues(for: target)
                .map { a in ComplementPair(left: a, right: target - a) }
        }

        let midpoint = target / 2
        let candidateLeftValues = [
            1,
            2,
            5,
            10,
            max(1, target / 10),
            max(1, target / 4),
            max(1, target / 3),
            max(1, midpoint - 10),
            max(1, midpoint - 1),
            midpoint
        ]

        return Array(Set(candidateLeftValues))
            .filter { $0 <= target - $0 }
            .sorted()
            .prefix(highTargetPairLimit)
            .map { a in ComplementPair(left: a, right: target - a) }
    }

    private static func allPairLeftValues(for target: Int) -> [Int] {
        (1...(target - 1)).filter { $0 <= target - $0 }
    }
}



// MARK: - Embedded Sum Sprint models

enum SumSprintBurstCardContent: Equatable {
    case prompt(String)
    case sum(Int)
    case decoratedSum(value: Int, marker: String)

    var displayText: String {
        switch self {
        case .prompt(let value):
            return value
        case .sum(let value):
            return String(value)
        case .decoratedSum(let value, let marker):
            return "\(value) \(marker)"
        }
    }

    var promptTotal: Int? {
        guard case .prompt(let value) = self else { return nil }
        let addends = value
            .split(separator: "+")
            .compactMap { Int(String($0).trimmingCharacters(in: .whitespacesAndNewlines)) }
        guard addends.count == 2 else { return nil }
        return addends.reduce(0, +)
    }

    var sumValue: Int? {
        switch self {
        case .sum(let value), .decoratedSum(let value, _):
            return value
        case .prompt:
            return nil
        }
    }
}

struct SumSprintBurstCard: Identifiable, Equatable {
    let id: UUID
    let pairId: UUID
    let content: SumSprintBurstCardContent
    var isMatched: Bool = false
    var isSelected: Bool = false
}

struct SumSprintBurstState: Equatable {
    let target: Int
    var cards: [SumSprintBurstCard]
    var selectedCardID: UUID? = nil

    var totalPairs: Int {
        Set(cards.map(\.pairId)).count
    }

    var matchedPairs: Int {
        cards.filter(\.isMatched).count / 2
    }

    var isComplete: Bool {
        cards.allSatisfy(\.isMatched) && totalPairs > 0
    }

    var progressLabel: String {
        "\(matchedPairs) / \(totalPairs)"
    }

    static func cardsFormValidMatch(_ lhs: SumSprintBurstCard, _ rhs: SumSprintBurstCard) -> Bool {
        if let promptTotal = lhs.content.promptTotal, let sumValue = rhs.content.sumValue {
            return promptTotal == sumValue
        }
        if let promptTotal = rhs.content.promptTotal, let sumValue = lhs.content.sumValue {
            return promptTotal == sumValue
        }
        return false
    }

    static func make(for problem: SliceProblem) -> SumSprintBurstState {
        let facts = makeFacts(for: problem)
        let duplicateTotals = Set(
            Dictionary(grouping: facts.map { $0.0 + $0.1 }, by: { $0 })
                .filter { $0.value.count > 1 }
                .map(\.key)
        )
        let markers = ["●", "▲", "★", "◆", "■"]

        let cards = facts.enumerated().flatMap { index, fact -> [SumSprintBurstCard] in
            let pairId = UUID()
            let prompt = "\(fact.0) + \(fact.1)"
            let sum = fact.0 + fact.1
            let sumContent: SumSprintBurstCardContent = duplicateTotals.contains(sum)
                ? .decoratedSum(value: sum, marker: markers[index % markers.count])
                : .sum(sum)
            return [
                SumSprintBurstCard(id: UUID(), pairId: pairId, content: .prompt(prompt)),
                SumSprintBurstCard(id: UUID(), pairId: pairId, content: sumContent)
            ]
        }
        return SumSprintBurstState(target: problem.target, cards: cards.shuffled())
    }

    private static func makeFacts(for problem: SliceProblem) -> [(Int, Int)] {
        let target = problem.target
        let first = (problem.decompositionA, problem.decompositionB)
        let second = (max(1, target - 1), min(1, target))
        let thirdLeft = max(1, target / 2)
        let third = (thirdLeft, max(1, target - thirdLeft))

        var facts: [(Int, Int)] = [first]
        if target >= 4 {
            facts.append(second)
        }
        if target >= 8 {
            facts.append(third)
        }

        var deduped: [(Int, Int)] = []
        for pair in facts {
            if !deduped.contains(where: { $0.0 == pair.0 && $0.1 == pair.1 }) {
                deduped.append(pair)
            }
        }
        return deduped
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
    var referenceImageJPEGData: Data? = nil
    var referenceLatitude: Double? = nil
    var referenceLongitude: Double? = nil
    var referenceGPSAccuracy: Double? = nil

    var isReadyForRoomQuest: Bool {
        isRegistered && referenceCaptureState != .notCaptured
    }
}

enum RoomQuestStationVerificationMethod: String, Codable, Equatable {
    case cameraVerified
    case manualConfirmed

    var badgeTitle: String {
        switch self {
        case .cameraVerified: "Marker scanned"
        case .manualConfirmed: "Fallback used"
        }
    }
}

enum RoomQuestReferenceCaptureState: String, Equatable, Codable {
    case notCaptured
    case captured
    case manualFallback

    var badgeTitle: String {
        switch self {
        case .notCaptured: "Place check not saved"
        case .captured: "Place photo saved"
        case .manualFallback: "Same-place fallback saved"
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
    let referenceImageJPEGData: Data?
    let referenceLatitude: Double?
    let referenceLongitude: Double?
    let referenceGPSAccuracy: Double?
    let capturedAt: Date
    let note: String
    let captureState: RoomQuestReferenceCaptureState

    init(
        role: RoomQuestStationRole,
        markerPayload: String?,
        referenceImageJPEGData: Data?,
        referenceLatitude: Double? = nil,
        referenceLongitude: Double? = nil,
        referenceGPSAccuracy: Double? = nil,
        capturedAt: Date,
        note: String,
        captureState: RoomQuestReferenceCaptureState
    ) {
        self.role = role
        self.markerPayload = markerPayload
        self.referenceImageJPEGData = referenceImageJPEGData
        self.referenceLatitude = referenceLatitude
        self.referenceLongitude = referenceLongitude
        self.referenceGPSAccuracy = referenceGPSAccuracy
        self.capturedAt = capturedAt
        self.note = note
        self.captureState = captureState
    }
}

@Model
final class StoredRoomQuestStationReference {
    var roleRawValue: String
    var markerPayload: String?
    var referenceImageJPEGData: Data?
    var referenceLatitude: Double?
    var referenceLongitude: Double?
    var referenceGPSAccuracy: Double?
    var capturedAt: Date
    var note: String
    var captureStateRawValue: String

    init(role: RoomQuestStationRole, markerPayload: String?, referenceImageJPEGData: Data?,
         referenceLatitude: Double?, referenceLongitude: Double?, referenceGPSAccuracy: Double?,
         capturedAt: Date, note: String, captureState: RoomQuestReferenceCaptureState) {
        self.roleRawValue = role.rawValue
        self.markerPayload = markerPayload
        self.referenceImageJPEGData = referenceImageJPEGData
        self.referenceLatitude = referenceLatitude
        self.referenceLongitude = referenceLongitude
        self.referenceGPSAccuracy = referenceGPSAccuracy
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
    var factKey: String  // "\(addendA)+\(addendB)"
    var profileId: String = KidProfilePersistence.defaultProfileId
    var addendA: Int
    var addendB: Int
    var boxRawValue: Int
    var sessionsSinceLastSeen: Int
    var correctStreak: Int
    var lastSeenAt: Date?

    init(profileId: String = KidProfilePersistence.defaultProfileId, factKey: String, addendA: Int, addendB: Int) {
        self.factKey = factKey
        self.profileId = profileId
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
    var profileId: String = KidProfilePersistence.defaultProfileId

    init(from draft: SessionSummaryDraft, profileId: String = KidProfilePersistence.defaultProfileId) {
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
        self.profileId = profileId
    }
}

// MARK: - StoredGameSession

@Model
final class StoredGameSession {
    @Attribute(.unique) var id: String
    var profileId: String
    var gameName: String
    var startedAt: Date
    var durationSeconds: Double
    var scoreValue: Int
    var scoreLabel: String
    var detail: String?

    init(
        id: String = UUID().uuidString,
        profileId: String,
        gameName: String,
        startedAt: Date,
        durationSeconds: Double,
        scoreValue: Int,
        scoreLabel: String,
        detail: String? = nil
    ) {
        self.id = id
        self.profileId = profileId
        self.gameName = gameName
        self.startedAt = startedAt
        self.durationSeconds = durationSeconds
        self.scoreValue = scoreValue
        self.scoreLabel = scoreLabel
        self.detail = detail
    }
}

// MARK: - StoredGameplayProgressRecord

@Model
final class StoredGameplayProgressRecord {
    @Attribute(.unique) var uniqueKey: String
    var profileId: String
    var threadId: String
    var entityId: String
    var propertyId: String?
    var propertyTypeId: String?
    var propertyValue: String?
    var relationId: String?
    var stageId: String
    var exposureCount: Int
    var correctCount: Int
    var incorrectCount: Int
    var supportedCorrectCount: Int
    var hintCount: Int
    var firstSeenAt: Date
    var lastSeenAt: Date?
    var nextDueAt: Date
    var confidenceBandRawValue: String
    var lastOutcomeRawValue: String?
    var lastStageId: String?
    var lastResultMetadata: String?

    init(
        uniqueKey: String,
        profileId: String,
        threadId: String,
        entityId: String,
        propertyId: String? = nil,
        propertyTypeId: String? = nil,
        propertyValue: String? = nil,
        relationId: String? = nil,
        stageId: String,
        exposureCount: Int = 0,
        correctCount: Int = 0,
        incorrectCount: Int = 0,
        supportedCorrectCount: Int = 0,
        hintCount: Int = 0,
        firstSeenAt: Date = .now,
        lastSeenAt: Date? = nil,
        nextDueAt: Date = .distantPast,
        confidenceBandRawValue: String = GameplayConfidenceBand.new.rawValue,
        lastOutcomeRawValue: String? = nil,
        lastStageId: String? = nil,
        lastResultMetadata: String? = nil
    ) {
        self.uniqueKey = uniqueKey
        self.profileId = profileId
        self.threadId = threadId
        self.entityId = entityId
        self.propertyId = propertyId
        self.propertyTypeId = propertyTypeId
        self.propertyValue = propertyValue
        self.relationId = relationId
        self.stageId = stageId
        self.exposureCount = exposureCount
        self.correctCount = correctCount
        self.incorrectCount = incorrectCount
        self.supportedCorrectCount = supportedCorrectCount
        self.hintCount = hintCount
        self.firstSeenAt = firstSeenAt
        self.lastSeenAt = lastSeenAt
        self.nextDueAt = nextDueAt
        self.confidenceBandRawValue = confidenceBandRawValue
        self.lastOutcomeRawValue = lastOutcomeRawValue
        self.lastStageId = lastStageId
        self.lastResultMetadata = lastResultMetadata
    }
}

// MARK: - StoredGameplayThreadSession

@Model
final class StoredGameplayThreadSession {
    @Attribute(.unique) var id: String
    var profileId: String
    var threadId: String
    var startedAt: Date
    var endedAt: Date
    var durationSeconds: Double
    var completedStageIdsData: Data?
    var totalScore: Int
    var stars: Int
    var stageSummaryData: Data?

    init(
        id: String = UUID().uuidString,
        profileId: String,
        threadId: String,
        startedAt: Date,
        endedAt: Date,
        durationSeconds: Double,
        completedStageIdsData: Data? = nil,
        totalScore: Int,
        stars: Int,
        stageSummaryData: Data? = nil
    ) {
        self.id = id
        self.profileId = profileId
        self.threadId = threadId
        self.startedAt = startedAt
        self.endedAt = endedAt
        self.durationSeconds = durationSeconds
        self.completedStageIdsData = completedStageIdsData
        self.totalScore = totalScore
        self.stars = stars
        self.stageSummaryData = stageSummaryData
    }
}
