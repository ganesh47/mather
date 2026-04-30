import Testing
@testable import Mather

struct LearningCardTests {
    @Test
    func learningCardIdentityIsDerivedFromStableMetadata() {
        let prompt = CardPrompt(id: "make-ten", speechText: "What makes ten?", displayText: "Make 10")
        let answer = CardAnswer(id: "ten", speechText: "ten", displayText: "10", normalizedValue: "10")
        let card = LearningCard(
            laneID: .numbers,
            conceptID: "number-bond",
            stage: .abstract,
            ageBand: .ages4To12,
            prompt: prompt,
            answer: answer,
            choices: [CardChoice(answer: answer, isCorrect: true)]
        )

        #expect(card.id == "numbers.number-bond.abstract.ages4To12.make-ten")
        #expect(card.id == LearningCard.makeID(
            laneID: .numbers,
            conceptID: "number-bond",
            stage: .abstract,
            ageBand: .ages4To12,
            promptID: "make-ten"
        ))
    }

    @Test
    func learningCardKeepsLaneConceptStageAndAgeMapping() {
        let provider = DeterministicStarterLearningCardProvider()
        let physics = provider.starterCards(for: .physics)

        #expect(physics.count == 1)
        #expect(physics.first?.laneID == .physics)
        #expect(physics.first?.conceptID == "gravity")
        #expect(physics.first?.stage == .concrete)
        #expect(physics.first?.ageBand == .ages2To12)
    }

    @Test
    func choiceCorrectnessIsExplicitAndMatchesAnswer() throws {
        let card = try #require(DeterministicStarterLearningCardProvider().starterCards(for: .numbers).first)

        #expect(card.hasSingleCorrectChoice)
        #expect(card.correctChoices.map(\.answer.id) == [card.answer.id])
        #expect(card.choices.filter(\.isCorrect).count == 1)
        #expect(card.choices.filter { !$0.isCorrect }.allSatisfy { $0.answer.id != card.answer.id })
    }

    @Test
    func cardProgressTracksAttemptsAndAccuracy() {
        let fresh = CardProgress()
        let reviewed = CardProgress(timesSeen: 3, correctCount: 2, incorrectCount: 1, currentCorrectStreak: 2)

        #expect(fresh.totalAttempts == 0)
        #expect(fresh.accuracy == 0)
        #expect(reviewed.totalAttempts == 3)
        #expect(reviewed.accuracy == 2.0 / 3.0)
    }

    @Test
    func deterministicStarterProviderReturnsStableDeckAndLaneFilters() {
        let provider = DeterministicStarterLearningCardProvider()
        let firstPass = provider.starterCards()
        let secondPass = provider.starterCards()

        #expect(firstPass.map(\.id) == secondPass.map(\.id))
        #expect(firstPass.map(\.laneID) == CapabilityLaneID.allCases)
        #expect(Set(firstPass.map(\.id)).count == firstPass.count)

        let discoveryCards = provider.starterCards(for: .discoveryCards)
        #expect(discoveryCards.map(\.id) == ["discoveryCards.category.review.ages2To12.apple-category"])
    }
}
