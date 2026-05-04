import CoreGraphics
import Foundation

struct GameplayStageNavigationState: Equatable {
    var activeStageIndex: Int
    var stageResults: [GameplayStageResult]
    var startedAt: Date
    var currentStageStartedAt: Date

    init(activeStageIndex: Int = 0, stageResults: [GameplayStageResult] = [], startedAt: Date = Date(), currentStageStartedAt: Date = Date()) {
        self.activeStageIndex = max(0, activeStageIndex)
        self.stageResults = stageResults
        self.startedAt = startedAt
        self.currentStageStartedAt = currentStageStartedAt
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
    }

    mutating func retryCurrentStage(now: Date = Date()) {
        currentStageStartedAt = now
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
    let shuffledRights: [GameplayDisplayItem]
    var selectedLeftID: String?
    var matchedPairIDs: Set<String> = []
    var mismatchCount = 0
    var hintCount = 0

    init(thread: GameplayThreadDefinition, round: GameplayRoundDefinition, mode: GameplayStageKind) {
        self.pairs = GameplayStageContentBuilder.matchPairs(thread: thread, round: round)
        self.mode = mode
        self.shuffledRights = GameplayStageContentBuilder.sortedRights(pairs, seed: round.seed)
    }

    var correctCount: Int { matchedPairIDs.count }
    var isComplete: Bool { !pairs.isEmpty && matchedPairIDs.count == pairs.count }

    func accessibilityLabel(for item: GameplayDisplayItem, side: GameplayMatchSide) -> String {
        let role = side == .left ? "prompt" : "answer"
        if side == .right && shouldConcealRight(item) {
            return "hidden \(role) card"
        }
        return "\(role): \(item.title), \(item.subtitle)"
    }

    func shouldConcealRight(_ item: GameplayDisplayItem) -> Bool {
        mode == .flipMemory && !matchedPairIDs.contains(pairID(forRight: item))
    }

    private func pairID(forRight item: GameplayDisplayItem) -> String {
        pairs.first(where: { $0.right.id == item.id })?.id ?? item.id
    }

    mutating func selectLeft(pairID: String) {
        guard !matchedPairIDs.contains(pairID) else { return }
        selectedLeftID = pairID
    }

    mutating func chooseRight(_ right: GameplayDisplayItem) -> Bool {
        guard let selectedLeftID, let pair = pairs.first(where: { $0.id == selectedLeftID }) else { return false }
        let correct = pair.right.id == right.id
        if correct {
            matchedPairIDs.insert(pair.id)
            self.selectedLeftID = nil
        } else {
            mismatchCount += 1
        }
        return correct
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
                visualAssetName: entity.visualAssetName
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
                visualAssetName: entity.visualAssetName
            )
            let right = GameplayDisplayItem(
                id: "\(item.id)-right",
                entityID: entity.id,
                title: property?.value ?? entity.name,
                subtitle: property.map { propertyTypeTitle($0.typeID, in: thread) } ?? "Name",
                visualKey: property?.visualKey,
                visualAssetName: property?.visualAssetName
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
