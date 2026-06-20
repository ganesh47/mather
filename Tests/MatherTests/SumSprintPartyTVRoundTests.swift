import Testing
@testable import Mather

struct SumSprintPartyTVRoundTests {
    @Test
    func factPoolCoversSumSprintTotalsWithoutDuplicateFacts() {
        let facts = SumSprintPartyTVRound.factPool
        let ids = facts.map(\.id)

        #expect(Set(facts.map(\.sum)) == Set(11...20))
        #expect(ids.count == Set(ids).count)
        #expect(facts.allSatisfy { $0.addendA <= $0.addendB })
    }

    @Test
    func answerChoicesIncludeCorrectAnswerAndThreeUniqueDistractors() {
        let fact = SumSprintPartyTVFact(addendA: 6, addendB: 7)
        let choices = SumSprintPartyTVRound.answerChoices(for: fact)

        #expect(choices.count == 4)
        #expect(Set(choices).count == 4)
        #expect(choices.contains(13))
        #expect(choices.allSatisfy { (11...20).contains($0) })
    }

    @Test
    func distractorGenerationIsDeterministic() {
        let fact = SumSprintPartyTVFact(addendA: 6, addendB: 7)

        #expect(SumSprintPartyTVRound.answerChoices(for: fact) == [12, 15, 13, 14])
        #expect(SumSprintPartyTVRound.answerChoices(for: fact) == [12, 15, 13, 14])
    }

    @Test
    func edgeSumsStillReceiveFourChoices() {
        let lowFact = SumSprintPartyTVFact(addendA: 1, addendB: 10)
        let highFact = SumSprintPartyTVFact(addendA: 10, addendB: 10)

        #expect(SumSprintPartyTVRound.answerChoices(for: lowFact) == [11, 12, 13, 14])
        #expect(SumSprintPartyTVRound.answerChoices(for: highFact) == [20, 19, 18, 17])
    }

    @Test
    func partyRoundHasNoPressureTimerByDefault() {
        let round = SumSprintPartyTVRound.make(index: 0)

        #expect(round.usesTimer == false)
        #expect(round.answerChoices.count == 4)
    }

    @Test
    func roundIndexWrapsDeterministically() {
        let first = SumSprintPartyTVRound.make(index: 0)
        let wrapped = SumSprintPartyTVRound.make(index: SumSprintPartyTVRound.factPool.count)
        let negative = SumSprintPartyTVRound.make(index: -SumSprintPartyTVRound.factPool.count)

        #expect(first == wrapped)
        #expect(first == negative)
    }
}
