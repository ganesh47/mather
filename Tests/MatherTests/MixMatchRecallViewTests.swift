import Testing
@testable import Mather

struct MixMatchRecallViewTests {
    @Test
    func evaluatorMarksCorrectAndIncorrectChoices() {
        let evaluator = MixMatchRecallChoiceEvaluator(correctChoiceIDs: ["ten"])

        #expect(evaluator.attempt(choiceID: "ten") == MixMatchRecallAttempt(choiceID: "ten", isCorrect: true))
        #expect(evaluator.attempt(choiceID: "nine") == MixMatchRecallAttempt(choiceID: "nine", isCorrect: false))
    }

    @Test
    func feedbackStateMarksCorrectAndIncorrectAttempts() {
        var feedback = MixMatchRecallFeedbackState()
        #expect(feedback.hasActiveFeedback == false)

        feedback.markAttempt(MixMatchRecallAttempt(choiceID: "ten", isCorrect: true))
        #expect(feedback.selectedChoiceID == "ten")
        #expect(feedback.matchedChoiceID == "ten")
        #expect(feedback.incorrectChoiceID == nil)
        #expect(feedback.isResolving)

        feedback.clear()
        #expect(feedback.hasActiveFeedback == false)

        feedback.markAttempt(MixMatchRecallAttempt(choiceID: "nine", isCorrect: false))
        #expect(feedback.selectedChoiceID == "nine")
        #expect(feedback.matchedChoiceID == nil)
        #expect(feedback.incorrectChoiceID == "nine")
        #expect(feedback.isResolving)
    }

    @Test
    func learningCardAdapterCreatesPromptAndChoiceCards() {
        let correct = CardAnswer(id: "triangle", speechText: "triangle", displayText: "Triangle")
        let card = LearningCard(
            laneID: .geometry,
            conceptID: "shape",
            stage: .pictorial,
            ageBand: .ages4To12,
            prompt: CardPrompt(id: "three-sides", speechText: "Which shape has three sides?", displayText: "Three sides"),
            answer: correct,
            choices: [
                CardChoice(answer: correct, isCorrect: true),
                CardChoice(answer: CardAnswer(id: "circle", speechText: "circle", displayText: "Circle"))
            ]
        )

        #expect(card.mixMatchPromptCard.display == .text("Three sides"))
        #expect(card.mixMatchPromptCard.accessibilityLabel == "Which shape has three sides?")
        #expect(card.mixMatchChoices.map(\.id) == ["triangle", "circle"])
        #expect(card.mixMatchChoices.map(\.isCorrect) == [true, false])
        #expect(card.mixMatchChoices.first?.card.display == .choice("Triangle"))
        #expect(card.mixMatchChoices.last?.card.accessibilityLabel == "circle")
    }

    @Test
    @MainActor
    func memoryAdapterPreservesCardStateAndAccessibleLabels() throws {
        let animal = try #require(MemoryDeck.countryFlags.first)
        var pictureCard = MemoryCard(pairId: animal.id, content: .picture(animal))
        pictureCard.isSelected = true
        let model = MemoryView.learningCardModel(for: pictureCard, difficulty: .hard, isIncorrect: true)

        #expect(model.display == .asset("MemoryFlagIndia"))
        #expect(model.accessibilityLabel == "Flag of India, selected")
        #expect(model.accessibilityHint == "Tap to choose this card.")
        #expect(model.isFaceDown == false)
        #expect(model.isSelected == true)
        #expect(model.isIncorrect == true)

        let hiddenLabelCard = MemoryCard(pairId: animal.id, content: .label(animal))
        let hiddenModel = MemoryView.learningCardModel(for: hiddenLabelCard, difficulty: .hard, isIncorrect: false)

        #expect(hiddenModel.display == .text("India"))
        #expect(hiddenModel.accessibilityLabel == "Face down memory card")
        #expect(hiddenModel.accessibilityHint == "Tap to turn this card over.")
        #expect(hiddenModel.isFaceDown == true)
    }
}
