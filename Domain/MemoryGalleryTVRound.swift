import Foundation

enum MemoryGalleryTVCategory: String, CaseIterable, Identifiable, Equatable {
    case animals
    case vehicles
    case planets
    case flags

    var id: String { rawValue }

    var title: String {
        switch self {
        case .animals: return "Animals"
        case .vehicles: return "Vehicles"
        case .planets: return "Planets"
        case .flags: return "Flags"
        }
    }

    var subtitle: String {
        switch self {
        case .animals: return "Farm favorites"
        case .vehicles: return "Machines and how they work"
        case .planets: return "Solar system"
        case .flags: return "Countries"
        }
    }

    var prompt: String {
        switch self {
        case .animals: return "Match the picture to the animal name."
        case .vehicles: return "Match the picture to the vehicle or vehicle-part name."
        case .planets: return "Match the planet picture to its name."
        case .flags: return "Match the flag to the country name."
        }
    }

    var symbolName: String {
        switch self {
        case .animals: return "pawprint.fill"
        case .vehicles: return "car.fill"
        case .planets: return "sparkles"
        case .flags: return "flag.fill"
        }
    }

    var deckKind: MemoryDeckKind {
        switch self {
        case .animals: return .domesticAnimals
        case .vehicles: return .vehicles
        case .planets: return .planets
        case .flags: return .countryFlags
        }
    }

    var deck: [MemoryAnimal] {
        MemoryDeck.animals(for: deckKind)
    }
}

struct MemoryGalleryTVRound: Equatable {
    let category: MemoryGalleryTVCategory
    let index: Int
    let promptCard: MemoryAnimal
    let answerChoices: [MemoryAnimal]

    var correctAnswerID: String { promptCard.id }

    var isVehiclePartPrompt: Bool {
        promptCard.metadata.deck == .vehicles
            && promptCard.metadata.kind.localizedCaseInsensitiveCompare("vehicle part") == .orderedSame
    }

    var promptTitle: String {
        isVehiclePartPrompt ? "Vehicle part" : "Picture"
    }

    var choicePrompt: String {
        isVehiclePartPrompt ? "Which vehicle part is this?" : "Choose the matching name"
    }

    var learningFacts: [MemoryFactCard] {
        let informativeFacts = promptCard.detailCards.filter {
            $0.title.localizedCaseInsensitiveCompare("Kind") != .orderedSame
                && $0.title.localizedCaseInsensitiveCompare("Name") != .orderedSame
        }
        return Array((informativeFacts.isEmpty ? promptCard.detailCards : informativeFacts).prefix(2))
    }

    static let choiceCount = 4

    static func make(category: MemoryGalleryTVCategory, index: Int) -> MemoryGalleryTVRound {
        let deck = category.deck
        precondition(deck.count >= choiceCount, "Memory Gallery TV categories need at least \(choiceCount) cards.")

        let normalizedIndex = positiveModulo(index, deck.count)
        let promptIndex = promptDeckIndex(
            for: category,
            roundIndex: normalizedIndex,
            deckCount: deck.count
        )
        let prompt = deck[promptIndex]
        let forwardChoices = (0..<choiceCount).map { offset in
            deck[positiveModulo(promptIndex + offset, deck.count)]
        }
        let rotatedChoices = rotate(forwardChoices, by: promptIndex % choiceCount)

        return MemoryGalleryTVRound(
            category: category,
            index: normalizedIndex,
            promptCard: prompt,
            answerChoices: rotatedChoices
        )
    }

    static func isCorrect(selectionID: String?, for round: MemoryGalleryTVRound) -> Bool {
        selectionID == round.correctAnswerID
    }

    private static func positiveModulo(_ value: Int, _ divisor: Int) -> Int {
        let remainder = value % divisor
        return remainder >= 0 ? remainder : remainder + divisor
    }

    private static func promptDeckIndex(
        for category: MemoryGalleryTVCategory,
        roundIndex: Int,
        deckCount: Int
    ) -> Int {
        guard category == .vehicles else { return roundIndex }

        // Vehicle decks are intentionally broad. Spread a six-round TV session
        // across the complete deck so specialist machines and their parts are
        // represented instead of always showing only the first six basics.
        let stride = max(1, (deckCount + MemoryGalleryTVGame.roundsPerGame - 1) / MemoryGalleryTVGame.roundsPerGame)
        return positiveModulo(roundIndex * stride, deckCount)
    }

    private static func rotate(_ values: [MemoryAnimal], by offset: Int) -> [MemoryAnimal] {
        guard !values.isEmpty else { return values }
        let split = positiveModulo(offset, values.count)
        return Array(values[split...]) + Array(values[..<split])
    }
}

struct MemoryGalleryTVGame: Equatable {
    enum Phase: Equatable {
        case choosingCategory
        case playing
        case completed
    }

    static let roundsPerGame = 6

    private(set) var phase: Phase = .choosingCategory
    private(set) var category: MemoryGalleryTVCategory?
    private(set) var roundIndex = 0
    private(set) var completedRoundCount = 0
    private(set) var correctCount = 0
    private(set) var streak = 0
    private(set) var bestStreak = 0
    private(set) var selectedAnswerID: String?
    private(set) var lastAnswerWasCorrect: Bool?

    var round: MemoryGalleryTVRound? {
        guard let category, phase == .playing else { return nil }
        return MemoryGalleryTVRound.make(category: category, index: roundIndex)
    }

    var hasAnsweredCurrentRound: Bool {
        selectedAnswerID != nil
    }

    var progressText: String {
        switch phase {
        case .choosingCategory:
            return "Choose a gallery"
        case .playing:
            let visibleRound = hasAnsweredCurrentRound ? completedRoundCount : completedRoundCount + 1
            return "Picture \(min(visibleRound, Self.roundsPerGame)) of \(Self.roundsPerGame)"
        case .completed:
            return "\(Self.roundsPerGame) pictures complete"
        }
    }

    mutating func start(category: MemoryGalleryTVCategory) {
        self.category = category
        phase = .playing
        roundIndex = 0
        completedRoundCount = 0
        correctCount = 0
        streak = 0
        bestStreak = 0
        selectedAnswerID = nil
        lastAnswerWasCorrect = nil
    }

    @discardableResult
    mutating func select(answerID: String) -> Bool {
        guard
            phase == .playing,
            selectedAnswerID == nil,
            let round
        else {
            return false
        }

        let isCorrect = answerID == round.correctAnswerID
        selectedAnswerID = answerID
        lastAnswerWasCorrect = isCorrect
        completedRoundCount += 1

        if isCorrect {
            correctCount += 1
            streak += 1
            bestStreak = max(bestStreak, streak)
        } else {
            streak = 0
        }

        return isCorrect
    }

    mutating func advance() {
        guard phase == .playing, selectedAnswerID != nil else { return }

        if completedRoundCount >= Self.roundsPerGame {
            phase = .completed
            selectedAnswerID = nil
            lastAnswerWasCorrect = nil
            return
        }

        roundIndex += 1
        selectedAnswerID = nil
        lastAnswerWasCorrect = nil
    }

    mutating func replay() {
        guard let category else {
            chooseAnotherCategory()
            return
        }
        start(category: category)
    }

    mutating func chooseAnotherCategory() {
        self = MemoryGalleryTVGame()
    }
}
