import Foundation

enum WaterCycleLessonThread {
    static let thread = LessonPlayThread(
        id: "water-cycle-thread",
        title: "Water Cycle Play Thread",
        stages: [
            LessonPlayStage(
                id: "look-learn",
                kind: .lookLearnFlashcards,
                title: "Look & Learn",
                prompt: "Look at each picture and hear what the water is doing."
            ),
            LessonPlayStage(
                id: "picture-name-match",
                kind: .pictureNameMatch,
                title: "Picture-Name Match",
                prompt: "Match each open picture to its water cycle name."
            ),
            LessonPlayStage(
                id: "safe-ask",
                kind: .contextualAsk,
                title: "Ask This Card",
                prompt: "Pick a card question. Answers stay about this water cycle card."
            ),
            LessonPlayStage(
                id: "mix-match",
                kind: .mixMatchFinale,
                title: "Mix-Match Finale",
                prompt: "Match each picture to the water cycle idea."
            )
        ],
        cards: cards
    )

    static let cards: [LessonPlayCard] = [
        LessonPlayCard(
            id: "sun-heat",
            title: "Sun Heat",
            prompt: "What gives pond water the energy to start moving?",
            answer: "The sun warms the water.",
            detail: "Warm water can change into vapor and rise.",
            assetName: "MemoryWaterCycleSunHeat"
        ),
        LessonPlayCard(
            id: "evaporation",
            title: "Evaporation",
            prompt: "What do we call water going up as tiny vapor?",
            answer: "Evaporation.",
            detail: "The vapor leaves the pond and travels into the air.",
            assetName: "MemoryWaterCycleEvaporation"
        ),
        LessonPlayCard(
            id: "condensation",
            title: "Condensation",
            prompt: "What happens when tiny vapor drops gather together?",
            answer: "They make a cloud.",
            detail: "This gathering step is condensation.",
            assetName: "MemoryWaterCycleCondensation"
        ),
        LessonPlayCard(
            id: "precipitation",
            title: "Precipitation",
            prompt: "What happens when a cloud gets heavy with drops?",
            answer: "Rain falls down.",
            detail: "Rain, snow, sleet, and hail are precipitation.",
            assetName: "MemoryWaterCyclePrecipitation"
        ),
        LessonPlayCard(
            id: "collection",
            title: "Collection",
            prompt: "Where does rainwater wait after it falls?",
            answer: "It gathers in ponds, lakes, rivers, puddles, and the ground.",
            detail: "Then the sun can warm it and the cycle begins again.",
            assetName: "MemoryWaterCycleCollection"
        )
    ]

    static func askTurns(for card: LessonPlayCard) -> [LessonSafeAskTurn] {
        [
            LessonSafeAskTurn(
                id: "\(card.id)-what",
                question: "What is \(card.title)?",
                answer: "\(card.title): \(card.answer) \(card.detail)"
            ),
            LessonSafeAskTurn(
                id: "\(card.id)-look",
                question: "What should I look for?",
                answer: "Look at the picture for \(card.title.lowercased()). \(card.detail)"
            )
        ]
    }

    static func askSession(for card: LessonPlayCard) -> LessonSafeAskSession {
        LessonSafeAskSession(cardID: card.id, suggestedTurns: askTurns(for: card))
    }

    static let mixMatchCards: [LearningCard] = cards.map { card in
        LearningCard(
            id: "water-cycle.\(card.id).mix-match",
            laneID: .physics,
            conceptID: ConceptId(rawValue: "water-cycle-\(card.id)"),
            stage: .review,
            ageBand: .ages4To12,
            prompt: CardPrompt(
                id: card.id,
                speechText: card.prompt,
                displayText: card.title,
                assetName: card.assetName
            ),
            answer: CardAnswer(
                id: card.id,
                speechText: card.title,
                displayText: card.title
            ),
            choices: cards.map { choiceCard in
                CardChoice(
                    answer: CardAnswer(
                        id: choiceCard.id,
                        speechText: choiceCard.title,
                        displayText: choiceCard.title
                    ),
                    isCorrect: choiceCard.id == card.id
                )
            }
        )
    }
}
