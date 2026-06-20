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
        case .vehicles: return "Things that move"
        case .planets: return "Solar system"
        case .flags: return "Countries"
        }
    }

    var prompt: String {
        switch self {
        case .animals: return "Match the picture to the animal name."
        case .vehicles: return "Match the picture to the vehicle name."
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

    static let choiceCount = 4

    static func make(category: MemoryGalleryTVCategory, index: Int) -> MemoryGalleryTVRound {
        let deck = category.deck
        precondition(deck.count >= choiceCount, "Memory Gallery TV categories need at least \(choiceCount) cards.")

        let normalizedIndex = positiveModulo(index, deck.count)
        let prompt = deck[normalizedIndex]
        let forwardChoices = (0..<choiceCount).map { offset in
            deck[positiveModulo(normalizedIndex + offset, deck.count)]
        }
        let rotatedChoices = rotate(forwardChoices, by: normalizedIndex % choiceCount)

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

    private static func rotate(_ values: [MemoryAnimal], by offset: Int) -> [MemoryAnimal] {
        guard !values.isEmpty else { return values }
        let split = positiveModulo(offset, values.count)
        return Array(values[split...]) + Array(values[..<split])
    }
}
