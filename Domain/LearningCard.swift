import Foundation

struct LearningCard: Identifiable, Codable, Hashable {
    let id: String
    let laneID: CapabilityLaneID
    let conceptID: ConceptId
    let stage: LaneStage
    let ageBand: AgeBand
    let prompt: CardPrompt
    let answer: CardAnswer
    let choices: [CardChoice]
    var progress: CardProgress

    init(
        id: String? = nil,
        laneID: CapabilityLaneID,
        conceptID: ConceptId,
        stage: LaneStage,
        ageBand: AgeBand,
        prompt: CardPrompt,
        answer: CardAnswer,
        choices: [CardChoice],
        progress: CardProgress = CardProgress()
    ) {
        self.id = id ?? Self.makeID(
            laneID: laneID,
            conceptID: conceptID,
            stage: stage,
            ageBand: ageBand,
            promptID: prompt.id
        )
        self.laneID = laneID
        self.conceptID = conceptID
        self.stage = stage
        self.ageBand = ageBand
        self.prompt = prompt
        self.answer = answer
        self.choices = choices
        self.progress = progress
    }

    var correctChoices: [CardChoice] {
        choices.filter(\.isCorrect)
    }

    var hasSingleCorrectChoice: Bool {
        correctChoices.count == 1
    }

    static func makeID(
        laneID: CapabilityLaneID,
        conceptID: ConceptId,
        stage: LaneStage,
        ageBand: AgeBand,
        promptID: String
    ) -> String {
        [
            laneID.rawValue,
            conceptID.rawValue,
            stage.rawValue,
            ageBand.rawValue,
            promptID,
        ].joined(separator: ".")
    }
}

struct CardPrompt: Identifiable, Codable, Hashable {
    let id: String
    let speechText: String
    let displayText: String?
    let assetName: String?

    init(
        id: String,
        speechText: String,
        displayText: String? = nil,
        assetName: String? = nil
    ) {
        self.id = id
        self.speechText = speechText
        self.displayText = displayText
        self.assetName = assetName
    }
}

struct CardAnswer: Identifiable, Codable, Hashable {
    let id: String
    let speechText: String
    let displayText: String?
    let normalizedValue: String

    init(
        id: String,
        speechText: String,
        displayText: String? = nil,
        normalizedValue: String? = nil
    ) {
        self.id = id
        self.speechText = speechText
        self.displayText = displayText
        self.normalizedValue = normalizedValue ?? id
    }
}

struct CardChoice: Identifiable, Codable, Hashable {
    let id: String
    let answer: CardAnswer
    let isCorrect: Bool

    init(id: String? = nil, answer: CardAnswer, isCorrect: Bool = false) {
        self.id = id ?? answer.id
        self.answer = answer
        self.isCorrect = isCorrect
    }
}

struct CardProgress: Codable, Hashable {
    var timesSeen: Int
    var correctCount: Int
    var incorrectCount: Int
    var currentCorrectStreak: Int
    var lastReviewedAt: Date?
    var lastReviewResult: CardReviewResult?

    init(
        timesSeen: Int = 0,
        correctCount: Int = 0,
        incorrectCount: Int = 0,
        currentCorrectStreak: Int = 0,
        lastReviewedAt: Date? = nil,
        lastReviewResult: CardReviewResult? = nil
    ) {
        self.timesSeen = timesSeen
        self.correctCount = correctCount
        self.incorrectCount = incorrectCount
        self.currentCorrectStreak = currentCorrectStreak
        self.lastReviewedAt = lastReviewedAt
        self.lastReviewResult = lastReviewResult
    }

    var totalAttempts: Int {
        correctCount + incorrectCount
    }

    var accuracy: Double {
        guard totalAttempts > 0 else { return 0 }
        return Double(correctCount) / Double(totalAttempts)
    }
}

enum CardReviewResult: String, Codable, Hashable {
    case correct
    case supportedCorrect
    case incorrect
}

protocol StarterLearningCardProviding {
    func starterCards(for laneID: CapabilityLaneID?) -> [LearningCard]
}

extension StarterLearningCardProviding {
    func starterCards() -> [LearningCard] {
        starterCards(for: nil)
    }
}

struct DeterministicStarterLearningCardProvider: StarterLearningCardProviding {
    private let cards: [LearningCard]

    init(cards: [LearningCard] = Self.defaultCards) {
        self.cards = cards
    }

    func starterCards(for laneID: CapabilityLaneID? = nil) -> [LearningCard] {
        guard let laneID else { return cards }
        return cards.filter { $0.laneID == laneID }
    }
}

extension DeterministicStarterLearningCardProvider {
    static let defaultCards: [LearningCard] = [
        LearningCard.makeChoiceCard(
            laneID: .numbers,
            conceptID: "number-bond",
            stage: .abstract,
            ageBand: .ages4To12,
            promptID: "six-plus-four",
            prompt: "What does six plus four make?",
            answer: "10",
            distractors: ["9", "11"]
        ),
        LearningCard.makeChoiceCard(
            laneID: .geometry,
            conceptID: "shape",
            stage: .pictorial,
            ageBand: .ages4To12,
            promptID: "three-sides",
            prompt: "Which shape has three sides?",
            answer: "triangle",
            distractors: ["square", "circle"]
        ),
        LearningCard.makeChoiceCard(
            laneID: .physics,
            conceptID: "gravity",
            stage: .concrete,
            ageBand: .ages2To12,
            promptID: "drop-ball",
            prompt: "What happens when you drop a ball?",
            answer: "falls down",
            distractors: ["floats up", "stays still"]
        ),
        LearningCard.makeChoiceCard(
            laneID: .mapWorld,
            conceptID: "compass",
            stage: .abstract,
            ageBand: .ages4To12,
            promptID: "letter-n",
            prompt: "On a compass, what does N mean?",
            answer: "north",
            distractors: ["east", "west"]
        ),
        LearningCard.makeChoiceCard(
            laneID: .discoveryCards,
            conceptID: "category",
            stage: .review,
            ageBand: .ages2To12,
            promptID: "apple-category",
            prompt: "What kind of thing is an apple?",
            answer: "fruit",
            distractors: ["vehicle", "planet"]
        ),
        LearningCard.makeChoiceCard(
            laneID: .chemistry,
            conceptID: "state",
            stage: .pictorial,
            ageBand: .future,
            promptID: "ice-state",
            prompt: "What state is ice?",
            answer: "solid",
            distractors: ["liquid", "gas"]
        ),
        LearningCard.makeChoiceCard(
            laneID: .electronics,
            conceptID: "component",
            stage: .pictorial,
            ageBand: .future,
            promptID: "battery-job",
            prompt: "What does a battery give a circuit?",
            answer: "power",
            distractors: ["sound", "water"]
        ),
    ]
}

fileprivate extension LearningCard {
    static func makeChoiceCard(
        laneID: CapabilityLaneID,
        conceptID: ConceptId,
        stage: LaneStage,
        ageBand: AgeBand,
        promptID: String,
        prompt: String,
        answer: String,
        distractors: [String]
    ) -> LearningCard {
        let correctAnswer = CardAnswer(
            id: answer.normalizedLearningCardToken,
            speechText: answer,
            displayText: answer,
            normalizedValue: answer.lowercased()
        )
        let distractorChoices = distractors.map {
            CardChoice(
                answer: CardAnswer(
                    id: $0.normalizedLearningCardToken,
                    speechText: $0,
                    displayText: $0,
                    normalizedValue: $0.lowercased()
                )
            )
        }

        return LearningCard(
            laneID: laneID,
            conceptID: conceptID,
            stage: stage,
            ageBand: ageBand,
            prompt: CardPrompt(id: promptID, speechText: prompt, displayText: prompt),
            answer: correctAnswer,
            choices: [CardChoice(answer: correctAnswer, isCorrect: true)] + distractorChoices
        )
    }
}

fileprivate extension String {
    var normalizedLearningCardToken: String {
        lowercased()
            .replacingOccurrences(of: " ", with: "-")
            .replacingOccurrences(of: "°", with: "deg")
    }
}
