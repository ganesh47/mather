import CoreGraphics
import Foundation

struct GameplayStageNavigationState: Equatable {
    var activeStageIndex: Int
    var stageResults: [GameplayStageResult]
    var startedAt: Date
    var currentStageStartedAt: Date
    var stageAttemptNonce: Int

    init(
        activeStageIndex: Int = 0,
        stageResults: [GameplayStageResult] = [],
        startedAt: Date = Date(),
        currentStageStartedAt: Date = Date(),
        stageAttemptNonce: Int = 0
    ) {
        self.activeStageIndex = max(0, activeStageIndex)
        self.stageResults = stageResults
        self.startedAt = startedAt
        self.currentStageStartedAt = currentStageStartedAt
        self.stageAttemptNonce = max(0, stageAttemptNonce)
    }

    func activeStage(in thread: GameplayThreadDefinition) -> GameplayStageDefinition? {
        guard thread.stages.indices.contains(activeStageIndex) else { return nil }
        return thread.stages[activeStageIndex]
    }

    func progressFraction(for thread: GameplayThreadDefinition) -> Double {
        guard !thread.stages.isEmpty else { return 1 }
        return Double(min(activeStageIndex + 1, thread.stages.count)) / Double(thread.stages.count)
    }

    var canGoBack: Bool { activeStageIndex > 0 }

    var stageAttemptID: String { "stage-attempt-\(activeStageIndex)-\(stageAttemptNonce)" }

    func isComplete(for thread: GameplayThreadDefinition) -> Bool {
        guard !thread.stages.isEmpty else { return true }
        let completedStageIDs = Set(stageResults.map(\.stageID))
        return thread.stages.allSatisfy { completedStageIDs.contains($0.id) }
    }

    func summary() -> GameplayScoreSummary {
        GameplayScoreSummary.summarize(stageResults)
    }

    mutating func goBack(now: Date = Date()) {
        guard activeStageIndex > 0 else { return }
        activeStageIndex -= 1
        currentStageStartedAt = now
        stageAttemptNonce += 1
    }

    mutating func retryCurrentStage(in thread: GameplayThreadDefinition? = nil, now: Date = Date()) {
        if let thread, isComplete(for: thread) {
            activeStageIndex = max(thread.stages.count - 1, 0)
        }
        if let thread, let stage = activeStage(in: thread) {
            stageResults.removeAll { $0.stageID == stage.id }
        }
        currentStageStartedAt = now
        stageAttemptNonce += 1
    }

    mutating func completeCurrentStage(
        thread: GameplayThreadDefinition,
        correctCount: Int,
        mistakeCount: Int,
        hintsUsed: Int = 0,
        now: Date = Date()
    ) {
        guard let stage = activeStage(in: thread) else { return }
        let result = GameplayStageResult(
            id: "\(stage.id)-\(Int(now.timeIntervalSince1970))",
            stageID: stage.id,
            correctCount: max(0, correctCount),
            mistakeCount: max(0, mistakeCount),
            hintsUsed: max(0, hintsUsed),
            durationSeconds: max(0, now.timeIntervalSince(currentStageStartedAt)),
            completedAt: now
        )
        stageResults.removeAll { $0.stageID == stage.id }
        stageResults.append(result)
        if activeStageIndex < thread.stages.count - 1 {
            activeStageIndex += 1
            currentStageStartedAt = now
            stageAttemptNonce += 1
        }
    }
}

struct GameplayDisplayItem: Identifiable, Equatable, Hashable {
    let id: String
    let entityID: String
    let title: String
    let subtitle: String
    let visualKey: String?
    let visualAssetName: String?
    let visualShapeKey: String?

    var spokenText: String {
        [title, subtitle].filter { !$0.isEmpty }.joined(separator: ". ")
    }
}

struct GameplayMatchPair: Identifiable, Equatable, Hashable {
    let id: String
    let left: GameplayDisplayItem
    let right: GameplayDisplayItem
}

struct GameplayMultipleChoiceQuestion: Identifiable, Equatable, Hashable {
    let id: String
    let prompt: String
    let answer: GameplayDisplayItem
    let choices: [GameplayDisplayItem]

    func isCorrect(_ choice: GameplayDisplayItem) -> Bool {
        choice.entityID == answer.entityID && choice.title == answer.title
    }
}

struct GameplayFlashcardStageViewModel: Equatable {
    let cards: [GameplayDisplayItem]
    var activeIndex: Int = 0
    var exposureCount: Int = 0

    init(thread: GameplayThreadDefinition, round: GameplayRoundDefinition) {
        self.cards = GameplayStageContentBuilder.flashcards(thread: thread, round: round)
    }

    var activeCard: GameplayDisplayItem? {
        guard cards.indices.contains(activeIndex) else { return nil }
        return cards[activeIndex]
    }

    var isLastCard: Bool { activeIndex >= max(cards.count - 1, 0) }

    var progressText: String {
        guard !cards.isEmpty else { return "0 of 0" }
        return "\(activeIndex + 1) of \(cards.count)"
    }

    var listenAgainAccessibilityLabel: String {
        guard let activeCard else { return "Listen again" }
        return "Listen again to \(activeCard.title)"
    }

    mutating func markExposure() {
        exposureCount += 1
    }

    mutating func advance() -> Bool {
        guard !isLastCard else { return true }
        activeIndex += 1
        return false
    }
}

struct GameplayMatchStageViewModel: Equatable {
    let pairs: [GameplayMatchPair]
    let mode: GameplayStageKind
    let turnItemCount: Int
    let seed: UInt64
    var selectedLeftID: String?
    var inspectedItemID: String?
    var revealedRightIDs: Set<String> = []
    var matchedPairIDs: Set<String> = []
    var mismatchCount = 0
    var hintCount = 0
    var activeTurnIndex = 0

    init(thread: GameplayThreadDefinition, round: GameplayRoundDefinition, mode: GameplayStageKind, turnItemCount: Int? = nil) {
        self.pairs = GameplayStageContentBuilder.turnFriendlyOrder(
            GameplayStageContentBuilder.matchPairs(thread: thread, round: round),
            turnItemCount: turnItemCount ?? Self.defaultTurnItemCount(for: mode, itemCount: round.items.count),
            seed: round.seed
        )
        self.mode = mode
        self.turnItemCount = max(1, turnItemCount ?? Self.defaultTurnItemCount(for: mode, itemCount: round.items.count))
        self.seed = round.seed
    }

    var correctCount: Int { matchedPairIDs.count }
    var isComplete: Bool { !pairs.isEmpty && matchedPairIDs.count == pairs.count }
    var turnCount: Int { max(1, Int(ceil(Double(max(pairs.count, 1)) / Double(turnItemCount)))) }
    var turnProgressText: String { "Turn \(min(activeTurnIndex + 1, turnCount))/\(turnCount)" }
    var activePairs: [GameplayMatchPair] {
        let start = activeTurnIndex * turnItemCount
        guard pairs.indices.contains(start) else { return [] }
        let end = min(start + turnItemCount, pairs.count)
        return Array(pairs[start..<end])
    }
    var shuffledRights: [GameplayDisplayItem] {
        GameplayStageContentBuilder.sortedRights(activePairs, seed: seed &+ UInt64(activeTurnIndex * 97))
    }
    var isTurnComplete: Bool {
        !activePairs.isEmpty && activePairs.allSatisfy { matchedPairIDs.contains($0.id) }
    }
    var canAdvanceTurn: Bool { isTurnComplete && !isComplete }
    var inspectedItem: GameplayDisplayItem? {
        guard let inspectedItemID else { return nil }
        return (activePairs.map(\.left) + activePairs.map(\.right)).first { $0.id == inspectedItemID }
    }

    func accessibilityLabel(for item: GameplayDisplayItem, side: GameplayMatchSide) -> String {
        let role = side == .left ? "prompt" : "answer"
        if side == .right && shouldConcealRight(item) {
            return "hidden \(role) card"
        }
        return "\(role): \(item.title), \(item.subtitle)"
    }

    func shouldConcealRight(_ item: GameplayDisplayItem) -> Bool {
        guard mode == .flipMemory else { return false }
        guard !matchedPairIDs.contains(pairID(forRight: item)) else { return false }
        return !revealedRightIDs.contains(item.id) && inspectedItemID != item.id
    }

    func pairID(forRight item: GameplayDisplayItem) -> String {
        pairs.first(where: { $0.right.id == item.id })?.id ?? item.id
    }

    mutating func selectLeft(pairID: String) {
        guard activePairs.contains(where: { $0.id == pairID }), !matchedPairIDs.contains(pairID) else { return }
        selectedLeftID = pairID
        inspectedItemID = activePairs.first(where: { $0.id == pairID })?.left.id
    }

    mutating func inspect(_ item: GameplayDisplayItem) {
        inspectedItemID = inspectedItemID == item.id ? nil : item.id
        if mode == .flipMemory, activePairs.contains(where: { $0.right.id == item.id }) {
            if revealedRightIDs.contains(item.id), inspectedItemID == nil {
                revealedRightIDs.remove(item.id)
            } else {
                revealedRightIDs.insert(item.id)
            }
        }
    }

    mutating func chooseRight(_ right: GameplayDisplayItem) -> Bool {
        revealedRightIDs.insert(right.id)
        guard let selectedLeftID, let pair = activePairs.first(where: { $0.id == selectedLeftID }) else {
            inspect(right)
            return false
        }
        let correct = pair.right.id == right.id
        if correct {
            matchedPairIDs.insert(pair.id)
            self.selectedLeftID = nil
            inspectedItemID = right.id
            revealedRightIDs.insert(right.id)
        } else {
            mismatchCount += 1
            inspectedItemID = right.id
            revealedRightIDs = Set([right.id])
        }
        return correct
    }

    mutating func advanceTurn() {
        guard canAdvanceTurn else { return }
        activeTurnIndex = min(activeTurnIndex + 1, turnCount - 1)
        selectedLeftID = nil
        inspectedItemID = nil
        revealedRightIDs.removeAll()
    }

    private static func defaultTurnItemCount(for mode: GameplayStageKind, itemCount: Int) -> Int {
        switch mode {
        case .easyMemory, .flipMemory:
            return min(max(itemCount, 1), 2)
        case .bondBlast:
            return min(max(itemCount, 1), 3)
        default:
            return max(itemCount, 1)
        }
    }
}

enum GameplayMatchSide {
    case left
    case right
}

struct GameplayMultipleChoiceStageViewModel: Equatable {
    let questions: [GameplayMultipleChoiceQuestion]
    var activeIndex = 0
    var selectedChoiceID: String?
    var correctCount = 0
    var mistakeCount = 0

    init(thread: GameplayThreadDefinition, round: GameplayRoundDefinition) {
        self.questions = GameplayStageContentBuilder.multipleChoiceQuestions(thread: thread, round: round)
    }

    var activeQuestion: GameplayMultipleChoiceQuestion? {
        guard questions.indices.contains(activeIndex) else { return nil }
        return questions[activeIndex]
    }

    var isComplete: Bool { !questions.isEmpty && activeIndex >= questions.count }

    var progressText: String {
        guard !questions.isEmpty else { return "0 of 0" }
        return "\(min(activeIndex + 1, questions.count)) of \(questions.count)"
    }

    mutating func choose(_ choice: GameplayDisplayItem) -> Bool {
        guard let question = activeQuestion else { return false }
        selectedChoiceID = choice.id
        let correct = question.isCorrect(choice)
        if correct { correctCount += 1 } else { mistakeCount += 1 }
        activeIndex += 1
        return correct
    }
}

enum GameplayStageContentBuilder {
    static func flashcards(thread: GameplayThreadDefinition, round: GameplayRoundDefinition) -> [GameplayDisplayItem] {
        round.items.compactMap { item in
            guard let entity = thread.entities.first(where: { $0.id == item.entityID }) else { return nil }
            return GameplayDisplayItem(
                id: "\(item.id)-card",
                entityID: entity.id,
                title: entity.name,
                subtitle: entity.summary,
                visualKey: entity.visualKey,
                visualAssetName: entity.visualAssetName,
                visualShapeKey: entity.visualShapeKey
            )
        }
    }

    static func matchPairs(thread: GameplayThreadDefinition, round: GameplayRoundDefinition) -> [GameplayMatchPair] {
        round.items.compactMap { item in
            guard let entity = thread.entities.first(where: { $0.id == item.entityID }) else { return nil }
            let property = entity.properties.first { $0.id == item.propertyID } ?? entity.properties.first
            let left = GameplayDisplayItem(
                id: "\(item.id)-left",
                entityID: entity.id,
                title: entity.name,
                subtitle: entity.summary,
                visualKey: entity.visualKey,
                visualAssetName: entity.visualAssetName,
                visualShapeKey: entity.visualShapeKey
            )
            let right = GameplayDisplayItem(
                id: "\(item.id)-right",
                entityID: entity.id,
                title: property?.value ?? entity.name,
                subtitle: property.map { propertyTypeTitle($0.typeID, in: thread) } ?? "Name",
                visualKey: property?.visualKey,
                visualAssetName: property?.visualAssetName,
                visualShapeKey: property?.visualShapeKey
            )
            return GameplayMatchPair(id: item.id, left: left, right: right)
        }
    }

    static func multipleChoiceQuestions(thread: GameplayThreadDefinition, round: GameplayRoundDefinition, choicesPerQuestion: Int = 4) -> [GameplayMultipleChoiceQuestion] {
        let pairs = matchPairs(thread: thread, round: round)
        return pairs.map { pair in
            let sameTypeDistractors = pairs
                .filter { $0.id != pair.id && $0.right.subtitle == pair.right.subtitle }
                .map(\.right)
            let fallbackDistractors = pairs
                .filter { $0.id != pair.id }
                .map(\.right)
            let distractors = uniqued(sameTypeDistractors + fallbackDistractors, excluding: pair.right.id)
            let choices = deterministicOrder([pair.right] + Array(distractors.prefix(max(0, choicesPerQuestion - 1))), seed: stableSeed(pair.id))
            return GameplayMultipleChoiceQuestion(
                id: "quiz-\(pair.id)",
                prompt: "Which one matches \(pair.left.title)?",
                answer: pair.right,
                choices: choices
            )
        }
    }

    static func sortedRights(_ pairs: [GameplayMatchPair], seed: UInt64) -> [GameplayDisplayItem] {
        deterministicOrder(pairs.map(\.right), seed: seed)
    }

    static func turnFriendlyOrder(_ pairs: [GameplayMatchPair], turnItemCount: Int, seed: UInt64) -> [GameplayMatchPair] {
        let size = max(1, turnItemCount)
        var remaining = deterministicOrder(pairs, seed: seed &+ 31)
        var ordered: [GameplayMatchPair] = []
        while !remaining.isEmpty {
            var turn: [GameplayMatchPair] = []
            var usedEntities = Set<String>()
            var nextRemaining: [GameplayMatchPair] = []
            for pair in remaining {
                if turn.count < size && !usedEntities.contains(pair.left.entityID) {
                    turn.append(pair)
                    usedEntities.insert(pair.left.entityID)
                } else {
                    nextRemaining.append(pair)
                }
            }
            while turn.count < size, !nextRemaining.isEmpty {
                turn.append(nextRemaining.removeFirst())
            }
            ordered.append(contentsOf: turn)
            remaining = nextRemaining
        }
        return ordered
    }

    private static func propertyTypeTitle(_ id: String, in thread: GameplayThreadDefinition) -> String {
        thread.propertyTypesByID[id]?.displayName ?? id
    }

    private static func uniqued(_ items: [GameplayDisplayItem], excluding id: String) -> [GameplayDisplayItem] {
        var seen = Set([id])
        var result: [GameplayDisplayItem] = []
        for item in items where !seen.contains(item.id) {
            seen.insert(item.id)
            result.append(item)
        }
        return result
    }

    private static func deterministicOrder<T: Identifiable>(_ items: [T], seed: UInt64) -> [T] where T.ID == String {
        items.sorted { stableSeed($0.id, seed: seed) < stableSeed($1.id, seed: seed) }
    }

    private static func stableSeed(_ id: String, seed: UInt64 = 0) -> UInt64 {
        var hash = 14_695_981_039_346_656_037 ^ seed
        for byte in id.utf8 {
            hash ^= UInt64(byte)
            hash &*= 1_099_511_628_211
        }
        return hash
    }
}

enum GameplayStageRenderSupport {
    static func cardMinimumWidth(availableWidth: CGFloat, compact: Bool) -> CGFloat {
        if compact { return max(132, min(168, (availableWidth - 40) / 2)) }
        return 180
    }

    static func touchTargetSize(compact: Bool) -> CGFloat {
        compact ? 54 : 64
    }

    static func usesCompactStageLayout(width: CGFloat, height: CGFloat) -> Bool {
        width < 430 || height < 760
    }

    static func maximumContentWidth(compact: Bool) -> CGFloat {
        compact ? .infinity : 920
    }
}
