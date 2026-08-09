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
        case .flags: return "Countries"
        }
    }

    var subtitle: String {
        switch self {
        case .animals: return "Farm favorites"
        case .vehicles: return "Machines and how they work"
        case .planets: return "Solar system"
        case .flags: return "Flags, money & landmarks"
        }
    }

    var prompt: String {
        switch self {
        case .animals: return "Match the picture to the animal name."
        case .vehicles: return "Match the picture to the vehicle or vehicle-part name."
        case .planets: return "Match the planet picture to its name."
        case .flags: return "Match the flag, then discover the country."
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

enum MemoryGalleryTVCountryPromptKind: String, CaseIterable, Equatable {
    case flag
    case monument
    case currency
    case capital
    case officialLanguage

    static func kind(forRoundIndex index: Int) -> Self {
        let sequence: [Self] = [.flag, .monument, .currency, .capital, .officialLanguage]
        let remainder = index % sequence.count
        return sequence[remainder >= 0 ? remainder : remainder + sequence.count]
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

    var countryPromptKind: MemoryGalleryTVCountryPromptKind? {
        guard category == .flags else { return nil }
        return .kind(forRoundIndex: index)
    }

    var promptPicture: MemoryPicture {
        guard let countryPromptKind else { return promptCard.picture }

        switch countryPromptKind {
        case .flag:
            return promptCard.picture
        case .monument:
            return artworkPicture(matching: [], excluding: ["money"])
                ?? factPicture(titled: "Monument")
                ?? promptCard.picture
        case .currency:
            return artworkPicture(matching: ["money", "currency"])
                ?? factPicture(titled: "Currency")
                ?? promptCard.picture
        case .capital:
            return factPicture(titled: "Capital") ?? promptCard.picture
        case .officialLanguage:
            return factPicture(titled: "Language") ?? promptCard.picture
        }
    }

    var promptTitle: String {
        switch category {
        case .flags:
            switch countryPromptKind {
            case .flag: return "Country flag"
            case .monument: return "Famous place"
            case .currency: return "Money clue"
            case .capital: return "Capital city"
            case .officialLanguage: return "Official language"
            case nil: return "Country clue"
            }
        default: return isVehiclePartPrompt ? "Vehicle part" : "Picture"
        }
    }

    var choicePrompt: String {
        switch category {
        case .flags:
            switch countryPromptKind {
            case .flag: return "Which country has this flag?"
            case .monument: return "Which country is home to this place?"
            case .currency: return "Which country uses this money?"
            case .capital: return "Which country has this capital?"
            case .officialLanguage: return "Which country uses this official language?"
            case nil: return "Which country matches this clue?"
            }
        default: return isVehiclePartPrompt ? "Which vehicle part is this?" : "Choose the matching name"
        }
    }

    var learningFacts: [MemoryFactCard] {
        let informativeFacts = promptCard.detailCards.filter {
            $0.title.localizedCaseInsensitiveCompare("Kind") != .orderedSame
                && $0.title.localizedCaseInsensitiveCompare("Name") != .orderedSame
        }
        let availableFacts = informativeFacts.isEmpty ? promptCard.detailCards : informativeFacts
        guard category == .flags else { return Array(availableFacts.prefix(2)) }

        // The country reveal is a tiny post-answer passport. Keep one fact from
        // each child-friendly theme so the expanded deck teaches more than a flag.
        let themes = [
            ["capital"],
            ["language"],
            ["currency", "money"],
            ["monument", "landmark", "known for"]
        ]
        var selectedFacts: [MemoryFactCard] = []
        var selectedIndexes = Set<Int>()

        for themeTerms in themes {
            guard selectedFacts.count < 4 else { break }
            guard let match = availableFacts.enumerated().first(where: { index, fact in
                !selectedIndexes.contains(index)
                    && themeTerms.contains { fact.title.localizedCaseInsensitiveContains($0) }
            }) else { continue }
            selectedFacts.append(match.element)
            selectedIndexes.insert(match.offset)
        }

        for (index, fact) in availableFacts.enumerated() where selectedFacts.count < 4 {
            guard !selectedIndexes.contains(index) else { continue }
            selectedFacts.append(fact)
        }
        return selectedFacts
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
        let forwardChoices = answerChoices(
            from: deck,
            promptIndex: promptIndex,
            countryPromptKind: category == .flags ? .kind(forRoundIndex: normalizedIndex) : nil
        )
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
        guard category == .vehicles || category == .flags else { return roundIndex }

        // Vehicle and country decks are intentionally broad. Spread a six-round
        // TV session across the complete deck so every replay is not limited to
        // the first six familiar cards.
        let spreadIndex = roundIndex * deckCount / MemoryGalleryTVGame.roundsPerGame
        return positiveModulo(spreadIndex, deckCount)
    }

    private static func rotate(_ values: [MemoryAnimal], by offset: Int) -> [MemoryAnimal] {
        guard !values.isEmpty else { return values }
        let split = positiveModulo(offset, values.count)
        return Array(values[split...]) + Array(values[..<split])
    }

    private static func answerChoices(
        from deck: [MemoryAnimal],
        promptIndex: Int,
        countryPromptKind: MemoryGalleryTVCountryPromptKind?
    ) -> [MemoryAnimal] {
        guard let countryPromptKind else {
            return (0..<choiceCount).map { offset in
                deck[positiveModulo(promptIndex + offset, deck.count)]
            }
        }

        var choices = [deck[promptIndex]]
        var usedClues = Set(choices.compactMap { countryClueKey(for: $0, kind: countryPromptKind) })

        for offset in 1..<deck.count where choices.count < choiceCount {
            let candidate = deck[positiveModulo(promptIndex + offset, deck.count)]
            if let clue = countryClueKey(for: candidate, kind: countryPromptKind), usedClues.contains(clue) {
                continue
            }
            choices.append(candidate)
            if let clue = countryClueKey(for: candidate, kind: countryPromptKind) {
                usedClues.insert(clue)
            }
        }

        for offset in 1..<deck.count where choices.count < choiceCount {
            let candidate = deck[positiveModulo(promptIndex + offset, deck.count)]
            guard !choices.contains(where: { $0.id == candidate.id }) else { continue }
            choices.append(candidate)
        }
        return choices
    }

    private static func countryClueKey(
        for card: MemoryAnimal,
        kind: MemoryGalleryTVCountryPromptKind
    ) -> String? {
        let factTitle: String?
        switch kind {
        case .currency: factTitle = "Currency"
        case .capital: factTitle = "Capital"
        case .officialLanguage: factTitle = "Language"
        case .flag, .monument: factTitle = nil
        }
        guard let factTitle else { return nil }
        return card.detailCards.first {
            $0.title.localizedCaseInsensitiveCompare(factTitle) == .orderedSame
        }?.value.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
    }

    private func factPicture(titled title: String) -> MemoryPicture? {
        promptCard.detailCards.first {
            $0.title.localizedCaseInsensitiveCompare(title) == .orderedSame
        }.map { .text($0.value) }
    }

    private func artworkPicture(matching terms: [String], excluding excludedTerms: [String] = []) -> MemoryPicture? {
        promptCard.learningArtwork.first { artwork in
            (terms.isEmpty || terms.contains { artwork.title.localizedCaseInsensitiveContains($0) })
                && !excludedTerms.contains { artwork.title.localizedCaseInsensitiveContains($0) }
        }.map { .asset($0.assetName) }
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
