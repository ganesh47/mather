import Foundation

/// Reusable deterministic content for learn → quiz → match loops.
struct LearningConceptCard: Identifiable, Equatable {
    let id: String
    let title: String
    let explanation: String
    let visualKey: String
    let audioPrompt: String

    init(id: String, title: String, explanation: String, visualKey: String, audioPrompt: String? = nil) {
        self.id = id
        self.title = title
        self.explanation = explanation
        self.visualKey = visualKey
        self.audioPrompt = audioPrompt ?? "Learn about \(title)."
    }
}

struct ConceptQuizQuestion: Identifiable, Equatable {
    let id: String
    let prompt: String
    let choices: [String]
    let correctChoice: String
    let feedback: String

    init(id: String, prompt: String, choices: [String], correctChoice: String, feedback: String) {
        self.id = id
        self.prompt = prompt
        self.choices = choices
        self.correctChoice = correctChoice
        self.feedback = feedback
    }

    func isCorrect(_ choice: String) -> Bool {
        choice == correctChoice
    }
}

struct ConceptMatchPair: Identifiable, Equatable {
    let id: String
    let left: String
    let right: String
    let feedback: String
    let leftVisualKey: String?
    let rightVisualKey: String?

    init(
        id: String,
        left: String,
        right: String,
        feedback: String,
        leftVisualKey: String? = nil,
        rightVisualKey: String? = nil
    ) {
        self.id = id
        self.left = left
        self.right = right
        self.feedback = feedback
        self.leftVisualKey = leftVisualKey
        self.rightVisualKey = rightVisualKey
    }
}

enum ConceptMatchAttempt: Equatable {
    case locked(pairId: String, feedback: String)
    case mismatch(feedback: String)
    case alreadyMatched
    case missingSelection
}

struct LearningLoopSummary: Equatable {
    let quizCorrect: Int
    let quizTotal: Int
    let matchedPairs: Int
    let totalPairs: Int

    var starCount: Int {
        guard quizTotal + totalPairs > 0 else { return 0 }
        let earned = quizCorrect + matchedPairs
        let possible = quizTotal + totalPairs
        switch Double(earned) / Double(possible) {
        case 0.85...: return 3
        case 0.55...: return 2
        case 0.01...: return 1
        default: return 0
        }
    }
}

enum LearningLoopScoring {
    static func scoreQuiz(questions: [ConceptQuizQuestion], answersByQuestionId: [String: String]) -> Int {
        questions.reduce(0) { score, question in
            guard let answer = answersByQuestionId[question.id] else { return score }
            return score + (question.isCorrect(answer) ? 1 : 0)
        }
    }

    static func isMatch(left: String, right: String, pairs: [ConceptMatchPair]) -> Bool {
        pairs.contains { $0.left == left && $0.right == right }
    }

    static func matchAttempt(
        selectedPairId: String?,
        targetPairId: String,
        pairs: [ConceptMatchPair],
        matchedPairIds: Set<String>
    ) -> ConceptMatchAttempt {
        guard let selectedPairId else { return .missingSelection }
        guard !matchedPairIds.contains(selectedPairId), !matchedPairIds.contains(targetPairId) else {
            return .alreadyMatched
        }
        guard selectedPairId == targetPairId, let pair = pairs.first(where: { $0.id == targetPairId }) else {
            return .mismatch(feedback: "Not that pair yet — try another match.")
        }
        return .locked(pairId: pair.id, feedback: pair.feedback)
    }

    static func summary(
        questions: [ConceptQuizQuestion],
        answersByQuestionId: [String: String],
        matchedPairIds: Set<String>,
        pairs: [ConceptMatchPair]
    ) -> LearningLoopSummary {
        LearningLoopSummary(
            quizCorrect: scoreQuiz(questions: questions, answersByQuestionId: answersByQuestionId),
            quizTotal: questions.count,
            matchedPairs: matchedPairIds.count,
            totalPairs: pairs.count
        )
    }
}

enum WaterCycleContent {
    static let cards: [LearningConceptCard] = [
        LearningConceptCard(id: "sun", title: "Sun", explanation: "The sun warms water in ponds, lakes, and puddles.", visualKey: "☀️", audioPrompt: "The sun warms the water."),
        LearningConceptCard(id: "pond", title: "Pond", explanation: "A pond holds water on the ground.", visualKey: "🏞️", audioPrompt: "A pond is water on the ground."),
        LearningConceptCard(id: "evaporation", title: "Evaporation", explanation: "Warm water turns into invisible water vapour and rises.", visualKey: "♨️", audioPrompt: "Evaporation means water vapour goes up."),
        LearningConceptCard(id: "water-vapour", title: "Water Vapour", explanation: "Water vapour is tiny water in the air.", visualKey: "💨", audioPrompt: "Water vapour floats in the air."),
        LearningConceptCard(id: "condensation", title: "Condensation", explanation: "Water vapour cools and gathers into tiny drops.", visualKey: "🌫️", audioPrompt: "Condensation makes tiny drops."),
        LearningConceptCard(id: "cloud", title: "Cloud", explanation: "A cloud is made from many tiny water drops.", visualKey: "☁️", audioPrompt: "Clouds hold tiny drops."),
        LearningConceptCard(id: "rain", title: "Rain", explanation: "Drops get heavy and fall back down as rain.", visualKey: "🌧️", audioPrompt: "Rain falls back down."),
    ]

    static let quizQuestions: [ConceptQuizQuestion] = [
        ConceptQuizQuestion(
            id: "sun-warms-water",
            prompt: "What does the sun do to pond water?",
            choices: ["Warms it", "Freezes it", "Hides it"],
            correctChoice: "Warms it",
            feedback: "Yes — warm water can evaporate."
        ),
        ConceptQuizQuestion(
            id: "vapour-rises",
            prompt: "Which word means warm water vapour goes up?",
            choices: ["Rain", "Evaporation", "Pond"],
            correctChoice: "Evaporation",
            feedback: "Evaporation sends water vapour up."
        ),
        ConceptQuizQuestion(
            id: "cloud-rain",
            prompt: "Which card shows water falling down?",
            choices: ["Cloud", "Rain", "Sun"],
            correctChoice: "Rain",
            feedback: "Rain brings water back down."
        ),
    ]

    static let matchPairs: [ConceptMatchPair] = [
        ConceptMatchPair(id: "sun-evaporation", left: "Sun", right: "Evaporation", feedback: "The sun helps water evaporate.", leftVisualKey: "☀️", rightVisualKey: "♨️"),
        ConceptMatchPair(id: "pond-evaporation", left: "Pond", right: "Evaporation", feedback: "Water can rise from the pond.", leftVisualKey: "🏞️", rightVisualKey: "♨️"),
        ConceptMatchPair(id: "cloud-condensation", left: "Cloud", right: "Condensation", feedback: "Condensation helps make clouds.", leftVisualKey: "☁️", rightVisualKey: "🌫️"),
        ConceptMatchPair(id: "cloud-rain", left: "Cloud", right: "Rain", feedback: "Heavy cloud drops fall as rain.", leftVisualKey: "☁️", rightVisualKey: "🌧️"),
        ConceptMatchPair(id: "rain-pond", left: "Rain", right: "Pond", feedback: "Rain fills ponds again.", leftVisualKey: "🌧️", rightVisualKey: "🏞️"),
    ]
}
