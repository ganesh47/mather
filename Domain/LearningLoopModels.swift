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


enum SoundLoudnessZone: String, CaseIterable, Equatable {
    case quiet
    case normal
    case loud
    case tooLoud

    var label: String {
        switch self {
        case .quiet: return "Quiet"
        case .normal: return "Normal talking"
        case .loud: return "Loud"
        case .tooLoud: return "Too loud"
        }
    }

    var estimatedRangeLabel: String {
        switch self {
        case .quiet: return "about 30–40 dB"
        case .normal: return "about 55–65 dB"
        case .loud: return "about 70–85 dB"
        case .tooLoud: return "90 dB or more"
        }
    }

    var safetyCopy: String {
        switch self {
        case .quiet:
            return "Soft sounds are gentle for ears."
        case .normal:
            return "Talking voice is a safe middle zone."
        case .loud:
            return "Loud places can feel tiring — take breaks."
        case .tooLoud:
            return "Move away, lower the volume, or protect your ears."
        }
    }
}

enum SoundVolumeContent {
    static let safetyNote = "Use listening clues only — no screaming. Protect your ears. A live microphone meter comes later and is not used in this activity."

    static let cards: [LearningConceptCard] = [
        LearningConceptCard(id: "quiet", title: "Quiet", explanation: "Quiet sounds are soft and gentle, like a whisper or leaves.", visualKey: "🍃", audioPrompt: "Quiet sounds are soft and gentle."),
        LearningConceptCard(id: "conversation", title: "Conversation", explanation: "A talking voice sits in the middle loudness zone.", visualKey: "💬", audioPrompt: "Conversation is a middle loudness zone."),
        LearningConceptCard(id: "traffic", title: "Traffic", explanation: "Busy traffic is loud and can turn into noise pollution.", visualKey: "🚗", audioPrompt: "Traffic can be loud and unwanted."),
        LearningConceptCard(id: "siren", title: "Siren", explanation: "Sirens warn us, but they are very loud. Move away and protect ears.", visualKey: "🚨", audioPrompt: "Sirens are very loud warning sounds."),
        LearningConceptCard(id: "headphones", title: "Headphones", explanation: "Keep headphones low, take breaks, and never play a volume that hurts.", visualKey: "🎧", audioPrompt: "Headphones should stay low and safe."),
        LearningConceptCard(id: "pleasant", title: "Pleasant Sound", explanation: "Pleasant sounds feel nice and safe, like birds or soft music.", visualKey: "🐦", audioPrompt: "Pleasant sounds feel nice and safe."),
        LearningConceptCard(id: "unpleasant", title: "Noisy Sound", explanation: "Noisy sounds feel harsh, distracting, or unwanted.", visualKey: "📣", audioPrompt: "Noisy sounds are unwanted or harsh."),
        LearningConceptCard(id: "protect-ears", title: "Protect Ears", explanation: "Lower volume, move away, cover ears, or ask a grown-up for help.", visualKey: "👂", audioPrompt: "Protect ears when sound is too loud."),
    ]

    static let quizQuestions: [ConceptQuizQuestion] = [
        ConceptQuizQuestion(
            id: "quiet-example",
            prompt: "Which sound belongs in the quiet zone?",
            choices: ["Whisper", "Siren", "Busy traffic"],
            correctChoice: "Whisper",
            feedback: "Yes — a whisper is soft and gentle."
        ),
        ConceptQuizQuestion(
            id: "safe-headphones",
            prompt: "What is the safest headphone choice?",
            choices: ["Turn it up until it hurts", "Keep volume low and take breaks", "Try to be louder than traffic"],
            correctChoice: "Keep volume low and take breaks",
            feedback: "Right — low volume and breaks help protect hearing."
        ),
        ConceptQuizQuestion(
            id: "noise-pollution",
            prompt: "What does noise pollution mean?",
            choices: ["Too much unwanted sound", "Only music you like", "A silent room"],
            correctChoice: "Too much unwanted sound",
            feedback: "Yes — noise pollution is unwanted sound around us."
        ),
        ConceptQuizQuestion(
            id: "too-loud-action",
            prompt: "What should you do if a sound hurts your ears?",
            choices: ["Move away or protect ears", "Make a louder sound", "Stand closer"],
            correctChoice: "Move away or protect ears",
            feedback: "Correct — move away, lower volume, or protect ears."
        ),
    ]

    static let matchPairs: [ConceptMatchPair] = [
        ConceptMatchPair(id: "whisper-quiet", left: "Whisper", right: "Quiet", feedback: "A whisper belongs in the quiet zone.", leftVisualKey: "🤫", rightVisualKey: "🍃"),
        ConceptMatchPair(id: "talk-normal", left: "Friend talking", right: "Conversation", feedback: "Talking voice is a middle loudness clue.", leftVisualKey: "🗣️", rightVisualKey: "💬"),
        ConceptMatchPair(id: "traffic-loud", left: "Busy road", right: "Traffic noise", feedback: "Busy roads can be loud and distracting.", leftVisualKey: "🚗", rightVisualKey: "📣"),
        ConceptMatchPair(id: "siren-too-loud", left: "Siren", right: "Protect ears", feedback: "Sirens are useful warnings, but they are too loud up close.", leftVisualKey: "🚨", rightVisualKey: "👂"),
        ConceptMatchPair(id: "birds-pleasant", left: "Birds", right: "Pleasant sound", feedback: "Birds can be a pleasant, gentle sound.", leftVisualKey: "🐦", rightVisualKey: "😊"),
        ConceptMatchPair(id: "headphones-safe", left: "Headphones", right: "Keep volume low", feedback: "Low volume and breaks are safer for headphones.", leftVisualKey: "🎧", rightVisualKey: "🔉"),
    ]

    static let estimatedZones: [SoundLoudnessZone] = [.quiet, .normal, .loud, .tooLoud]

    static func zone(forEstimatedDecibels decibels: Double) -> SoundLoudnessZone {
        switch decibels {
        case ..<50: return .quiet
        case ..<70: return .normal
        case ..<90: return .loud
        default: return .tooLoud
        }
    }
}

struct ShapeGeometryLevel: Identifiable, Equatable {
    let id: String
    let title: String
    let subtitle: String
    let cardIDs: [String]

    func cards(from deck: [LearningConceptCard]) -> [LearningConceptCard] {
        cardIDs.compactMap { id in deck.first { $0.id == id } }
    }

    func quizQuestions(from questions: [ConceptQuizQuestion]) -> [ConceptQuizQuestion] {
        questions.filter { cardIDs.contains($0.id.replacingOccurrences(of: "shape-quiz-", with: "")) }
    }

    func matchPairs(from pairs: [ConceptMatchPair]) -> [ConceptMatchPair] {
        pairs.filter { cardIDs.contains($0.id.replacingOccurrences(of: "shape-match-", with: "")) }
    }
}

enum ShapeGeometryContent {
    static let cards: [LearningConceptCard] = [
        LearningConceptCard(id: "circle", title: "Circle", explanation: "A circle is round. It has no corners and no straight sides.", visualKey: "⚪", audioPrompt: "Circle is round with no corners."),
        LearningConceptCard(id: "triangle", title: "Triangle", explanation: "A triangle has 3 straight sides and 3 corners.", visualKey: "🔺", audioPrompt: "Triangle has three sides."),
        LearningConceptCard(id: "square", title: "Square", explanation: "A square has 4 equal sides and 4 square corners.", visualKey: "◼️", audioPrompt: "Square has four equal sides."),
        LearningConceptCard(id: "rectangle", title: "Rectangle", explanation: "A rectangle has 4 straight sides and 4 square corners. Opposite sides match.", visualKey: "▭", audioPrompt: "Rectangle has four square corners."),
        LearningConceptCard(id: "oval", title: "Oval", explanation: "An oval is round and stretched like an egg. It has no corners.", visualKey: "🥚", audioPrompt: "Oval is a stretched circle shape."),
        LearningConceptCard(id: "diamond", title: "Diamond", explanation: "A diamond has 4 sides and stands on a point.", visualKey: "💎", audioPrompt: "Diamond stands on a point."),
        LearningConceptCard(id: "star", title: "Star", explanation: "A star has points that stick out around the shape.", visualKey: "⭐", audioPrompt: "Star has points."),
        LearningConceptCard(id: "heart", title: "Heart", explanation: "A heart has two rounded bumps and a point at the bottom.", visualKey: "❤️", audioPrompt: "Heart has two bumps and a point."),
    ]

    static let levels: [ShapeGeometryLevel] = [
        ShapeGeometryLevel(
            id: "basic-shapes",
            title: "Level 1: Shape starters",
            subtitle: "Circle, triangle, square, and rectangle",
            cardIDs: ["circle", "triangle", "square", "rectangle"]
        ),
        ShapeGeometryLevel(
            id: "expanded-shapes",
            title: "Level 2: More shapes",
            subtitle: "Oval, diamond, star, and heart",
            cardIDs: ["oval", "diamond", "star", "heart"]
        ),
    ]

    static let quizQuestions: [ConceptQuizQuestion] = [
        ConceptQuizQuestion(id: "shape-quiz-circle", prompt: "Which shape is round with no corners?", choices: ["Circle", "Triangle", "Rectangle"], correctChoice: "Circle", feedback: "Yes — a circle is round with no corners."),
        ConceptQuizQuestion(id: "shape-quiz-triangle", prompt: "Which shape has 3 straight sides?", choices: ["Square", "Triangle", "Oval"], correctChoice: "Triangle", feedback: "Triangle means 3 sides and 3 corners."),
        ConceptQuizQuestion(id: "shape-quiz-square", prompt: "Which shape has 4 equal sides?", choices: ["Square", "Heart", "Oval"], correctChoice: "Square", feedback: "A square has four equal sides."),
        ConceptQuizQuestion(id: "shape-quiz-rectangle", prompt: "Which shape has 4 square corners and opposite sides that match?", choices: ["Circle", "Rectangle", "Star"], correctChoice: "Rectangle", feedback: "A rectangle has four square corners."),
        ConceptQuizQuestion(id: "shape-quiz-oval", prompt: "Which shape is stretched and round like an egg?", choices: ["Oval", "Diamond", "Triangle"], correctChoice: "Oval", feedback: "An oval is a stretched round shape."),
        ConceptQuizQuestion(id: "shape-quiz-diamond", prompt: "Which shape stands on a point?", choices: ["Heart", "Diamond", "Circle"], correctChoice: "Diamond", feedback: "A diamond has four sides and a point at top and bottom."),
        ConceptQuizQuestion(id: "shape-quiz-star", prompt: "Which shape has points sticking out?", choices: ["Star", "Oval", "Rectangle"], correctChoice: "Star", feedback: "A star has points around it."),
        ConceptQuizQuestion(id: "shape-quiz-heart", prompt: "Which shape has two rounded bumps and one bottom point?", choices: ["Triangle", "Heart", "Square"], correctChoice: "Heart", feedback: "A heart has two rounded bumps and a bottom point."),
    ]

    static let matchPairs: [ConceptMatchPair] = cards.map { card in
        ConceptMatchPair(
            id: "shape-match-\(card.id)",
            left: card.title,
            right: card.title,
            feedback: "Locked: \(card.title) matches its name.",
            leftVisualKey: card.visualKey,
            rightVisualKey: nil
        )
    }

    static func level(withID id: String) -> ShapeGeometryLevel? {
        levels.first { $0.id == id }
    }
}
