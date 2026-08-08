import Foundation

enum MemoryAskConversationSource: Equatable {
    case appleIntelligenceSuggested
    case deterministicFallback
}

enum MemoryAskInputMode: Equatable {
    case suggestedTurnSelection
}

struct MemoryAskSuggestedTurn: Identifiable, Equatable {
    let id: String
    let question: String
    let answer: String
}

struct MemoryAskResponse: Equatable {
    enum Kind: Equatable {
        case answer
        case refusal
    }

    let kind: Kind
    let spokenText: String
}

enum MemoryAskTurnRequest: Equatable {
    case suggestedTurn(id: String)
    case unsupportedTopic
}

struct MemoryAskConversationSession: Equatable {
    let cardId: String
    let source: MemoryAskConversationSource
    let suggestedTurns: [MemoryAskSuggestedTurn]
    private(set) var selectedTurnIDs: [String] = []

    mutating func respond(to request: MemoryAskTurnRequest) -> MemoryAskResponse {
        switch request {
        case let .suggestedTurn(id):
            guard let turn = suggestedTurns.first(where: { $0.id == id }) else {
                return Self.offScopeResponse
            }
            selectedTurnIDs.append(id)
            return MemoryAskResponse(kind: .answer, spokenText: turn.answer)
        case .unsupportedTopic:
            return Self.offScopeResponse
        }
    }

    private static var offScopeResponse: MemoryAskResponse {
        MemoryAskResponse(
            kind: .refusal,
            spokenText: "I can only talk about this card. Pick one of the card questions."
        )
    }
}

@MainActor
protocol MemoryAskConversationTurnProvider {
    var isAvailable: Bool { get }
    func suggestedTurns(for animal: MemoryAnimal) async throws -> [MemoryAskSuggestedTurn]
}

private struct NullMemoryAskConversationTurnProvider: MemoryAskConversationTurnProvider {
    var isAvailable: Bool { false }
    func suggestedTurns(for animal: MemoryAnimal) async throws -> [MemoryAskSuggestedTurn] { [] }
}

@MainActor
final class MemoryAskConversationPolicy {
    static let allowsMicrophoneInput = false
    static let allowsFreeformTextInput = false
    static let supportedInputModes: [MemoryAskInputMode] = [.suggestedTurnSelection]

    private let provider: any MemoryAskConversationTurnProvider

    init(provider: (any MemoryAskConversationTurnProvider)? = nil) {
        self.provider = provider ?? NullMemoryAskConversationTurnProvider()
    }

    func startSession(for animal: MemoryAnimal) async -> MemoryAskConversationSession {
        if provider.isAvailable,
           let generatedTurns = try? await provider.suggestedTurns(for: animal) {
            let safeTurns = sanitize(generatedTurns, for: animal)
            if !safeTurns.isEmpty {
                return MemoryAskConversationSession(
                    cardId: animal.id,
                    source: .appleIntelligenceSuggested,
                    suggestedTurns: safeTurns
                )
            }
        }

        return MemoryAskConversationSession(
            cardId: animal.id,
            source: .deterministicFallback,
            suggestedTurns: Self.fallbackTurns(for: animal)
        )
    }

    private func sanitize(_ turns: [MemoryAskSuggestedTurn], for animal: MemoryAnimal) -> [MemoryAskSuggestedTurn] {
        let cardText: [String] = [
            animal.canonicalName,
            animal.name,
            animal.metadata.category,
            animal.metadata.kind
        ] + animal.detailCards.flatMap { [$0.title, $0.value] }
        let genericWords: Set<String> = [
            "about", "and", "are", "because", "but", "can", "card", "current", "for", "from",
            "has", "have", "how", "into", "its", "not", "one", "our", "question", "that", "the",
            "their", "them", "this", "turn", "tell", "was", "what", "when", "where", "who", "why", "with"
        ]
        let cardWords = Set(Self.words(in: cardText.joined(separator: " ")).filter { word in
            word.count > 2 && !genericWords.contains(word)
        })

        var seenIDs = Set<String>()
        var sanitizedTurns: [MemoryAskSuggestedTurn] = []
        for turn in turns {
            let cleanQuestion = Self.clean(turn.question)
            let cleanAnswer = Self.clean(turn.answer)
            guard !turn.id.isEmpty,
                  seenIDs.insert(turn.id).inserted,
                  !cleanQuestion.isEmpty,
                  !cleanAnswer.isEmpty,
                  cleanQuestion.count <= 90,
                  cleanAnswer.count <= 220 else { continue }

            let turnWords = Set(Self.words(in: cleanQuestion + " " + cleanAnswer))
            guard !cardWords.isDisjoint(with: turnWords) else { continue }

            sanitizedTurns.append(MemoryAskSuggestedTurn(id: turn.id, question: cleanQuestion, answer: cleanAnswer))
            if sanitizedTurns.count == 3 { break }
        }
        return sanitizedTurns
    }

    private static func fallbackTurns(for animal: MemoryAnimal) -> [MemoryAskSuggestedTurn] {
        if animal.metadata.deck == .vehicles {
            return vehicleTurns(for: animal)
        }

        var turns: [MemoryAskSuggestedTurn] = []
        let name = animal.canonicalName
        let metadata = animal.metadata

        if metadata.deck == .planets,
           let order = animal.detailCards.first(where: { $0.title == "Order" })?.value,
           let type = animal.detailCards.first(where: { $0.title == "Type" })?.value {
            turns.append(MemoryAskSuggestedTurn(
                id: "planet-place",
                question: "Where is \(name)?",
                answer: "\(name) is the \(order.lowercased()) planet. It is a \(type.lowercased())."
            ))
        } else if let home = metadata.habitat {
            turns.append(MemoryAskSuggestedTurn(
                id: "home",
                question: "Where does \(name) belong?",
                answer: "\(name) belongs in \(home.lowercased())."
            ))
        }

        if let size = metadata.size {
            turns.append(MemoryAskSuggestedTurn(
                id: "size",
                question: "How big is \(name)?",
                answer: "\(name) can be about \(size.lowercased())."
            ))
        }

        if metadata.deck == .planets,
           let funFact = animal.detailCards.first(where: { $0.title == "Fun Fact" })?.value {
            turns.append(MemoryAskSuggestedTurn(
                id: "fun-fact",
                question: "What is special about \(name)?",
                answer: "\(name) is special because \(funFact.lowercased())."
            ))
        }

        if let colors = metadata.colors {
            turns.append(MemoryAskSuggestedTurn(
                id: "colors",
                question: "What colors can I see?",
                answer: "Look for \(colors.lowercased()) on \(name)."
            ))
        }

        if metadata.deck != .planets, let movement = metadata.movement {
            turns.append(MemoryAskSuggestedTurn(
                id: "movement",
                question: "How does \(name) move?",
                answer: "\(name) \(movement.lowercased())."
            ))
        }

        if turns.count < 3 {
            for turn in detailCardTurns(for: animal) where !turns.contains(where: { $0.id == turn.id }) {
                turns.append(turn)
                if turns.count == 3 { break }
            }
        }

        return Array(turns.prefix(3))
    }

    private static func vehicleTurns(for animal: MemoryAnimal) -> [MemoryAskSuggestedTurn] {
        let name = animal.canonicalName
        var turns: [MemoryAskSuggestedTurn] = []
        let technicalWords = ["part", "engine", "motor", "gear", "brake", "control", "attachment", "tool", "power"]
        let technicalFacts = animal.detailCards.filter { card in
            let title = card.title.lowercased()
            return technicalWords.contains { title.contains($0) }
        }

        if !technicalFacts.isEmpty {
            let workingFacts = technicalFacts + animal.detailCards.filter { card in
                card.title.localizedCaseInsensitiveContains("how it works")
                    && !technicalFacts.contains(card)
            }
            let answer = workingFacts.prefix(2)
                .map { "\($0.title): \($0.value)." }
                .joined(separator: " ")
            turns.append(MemoryAskSuggestedTurn(
                id: "vehicle-parts",
                question: "Which parts help \(name) work?",
                answer: answer
            ))
        }

        if let use = animal.metadata.use {
            turns.append(MemoryAskSuggestedTurn(
                id: "vehicle-job",
                question: "What job does \(name) do?",
                answer: "\(name) \(use.lowercased())."
            ))
        }

        if let movement = animal.metadata.movement {
            turns.append(MemoryAskSuggestedTurn(
                id: "vehicle-movement",
                question: "How does \(name) move?",
                answer: "\(name) \(movement.lowercased())."
            ))
        }

        for turn in detailCardTurns(for: animal) where !turns.contains(where: { $0.id == turn.id }) {
            turns.append(turn)
            if turns.count == 3 { break }
        }

        return Array(turns.prefix(3))
    }

    private static func detailCardTurns(for animal: MemoryAnimal) -> [MemoryAskSuggestedTurn] {
        let name = animal.canonicalName
        let skippedTitles = Set(["name"])
        return animal.detailCards.compactMap { card in
            let title = clean(card.title)
            let value = clean(card.value)
            guard !title.isEmpty,
                  !value.isEmpty,
                  !skippedTitles.contains(title.lowercased()) else { return nil }
            let id = "fact-\(words(in: title).joined(separator: "-"))"
            guard id != "fact-" else { return nil }
            return MemoryAskSuggestedTurn(
                id: id,
                question: "What does \(title.lowercased()) tell us about \(name)?",
                answer: "\(title): \(value)."
            )
        }
    }

    private static func clean(_ text: String) -> String {
        text
            .replacingOccurrences(of: "\n", with: " ")
            .replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static func words(in text: String) -> [String] {
        text.lowercased()
            .split { !$0.isLetter && !$0.isNumber }
            .map(String.init)
    }
}
