import Testing
@testable import Mather

@Suite("Array Prelude Models")
struct ArrayPreludeModelsTests {
    @Test func arrayFactUsesCanonicalKeyButKeepsTeachingOrientation() {
        let fact = ArrayFact(rows: 3, columns: 2)

        #expect(fact.product == 6)
        #expect(fact.canonicalKey == "2x3")
        #expect(fact.rowColumnPhrase == "3 rows of 2")
        #expect(fact.spokenPrompt == "Pack 6 boxes as 3 rows of 2.")
        #expect(fact.equationText == "3 x 2 = 6")
    }

    @Test func difficultiesMatchRequestedCardProgression() {
        #expect(ArrayPreludeDifficulty.easy.pairCount == 3)
        #expect(ArrayPreludeDifficulty.standard.pairCount == 4)
        #expect(ArrayPreludeDifficulty.flip.pairCount == 4)
        #expect(ArrayPreludeDifficulty.easy.showsEquation == false)
        #expect(ArrayPreludeDifficulty.standard.showsEquation == true)
        #expect(ArrayPreludeDifficulty.flip.startsFaceDown == true)
        #expect(ArrayPreludeDifficulty.flip.menuLabel == "Flip mode")
    }

    @Test func generatedRoundsAvoidOneByNAndDuplicateCanonicalFacts() {
        for difficulty in ArrayPreludeDifficulty.allCases {
            let round = ArrayPreludeRound.make(difficulty: difficulty, seed: 2)
            let keys = round.steps.map { $0.fact.canonicalKey }

            #expect(round.steps.count == difficulty.pairCount)
            #expect(Set(keys).count == keys.count)
            #expect(round.steps.allSatisfy { $0.fact.rows > 1 && $0.fact.columns > 1 })
        }
    }

    @Test func choicesContainAnswerAndStayDistinct() {
        let round = ArrayPreludeRound.make(difficulty: .standard, seed: 0)

        for step in round.steps {
            #expect(step.totalChoices.contains(step.fact.product))
            #expect(Set(step.totalChoices).count == step.totalChoices.count)
            #expect(step.totalChoices.count == 3)
        }
    }

    @Test func handoffTargetUsesLastPracticedProduct() {
        let round = ArrayPreludeRound.make(difficulty: .easy, seed: 0)

        #expect(ArrayPreludeRound.handoffTarget(after: round) == round.steps.last!.fact.product)
    }
}
