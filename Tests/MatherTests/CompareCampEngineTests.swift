import Foundation
import Testing
@testable import Mather

@MainActor
@Suite("Compare Camp learning state")
struct CompareCampEngineTests {
    @Test func invalidActionsCannotStartAdvanceOrSolveARound() throws {
        let engine = CompareCampEngine()
        #expect(engine.phase == .choosingCamp)
        #expect(!engine.select(answerID: "left"))
        #expect(!engine.checkBuild())
        engine.advance()
        #expect(engine.round == nil)
        engine.start(category: .first, activity: .more, difficulty: .small)
        let round = try #require(engine.round)
        #expect(!engine.select(answerID: "invented"))
        #expect(engine.selectedAnswerID == nil)
        engine.advance()
        #expect(engine.round == round)
        #expect(engine.completedRoundCount == 0)
    }

    @Test func anIncorrectAnswerKeepsTheTaskOpenAndCorrectionCountsOnlyOnce() throws {
        let engine = CompareCampEngine()
        engine.start(category: .first, activity: .more, difficulty: .small)
        let round = try #require(engine.round)
        let incorrect = try #require(round.choices.first { $0.id != round.correctAnswerID })
        #expect(!engine.select(answerID: incorrect.id))
        #expect(engine.lastAnswerWasCorrect == false)
        #expect(!engine.hasSolvedRound)
        #expect(engine.completedRoundCount == 0)
        #expect(!engine.hintShown)
        #expect(!engine.isArranged)
        #expect(!engine.feedbackText.contains(round.explanation))
        engine.advance()
        #expect(engine.roundIndex == 0)
        #expect(engine.select(answerID: round.correctAnswerID))
        #expect(engine.hasSolvedRound)
        #expect(engine.completedRoundCount == 1)
        #expect(engine.firstTryCount == 0)
        #expect(engine.helpedRoundCount == 1)
        #expect(!engine.select(answerID: round.correctAnswerID))
        #expect(engine.completedRoundCount == 1)
        #expect(engine.currentPrompt.contains(round.explanation))
        engine.advance()
        #expect(engine.roundIndex == 1)
        #expect(engine.selectedAnswerID == nil)
    }

    @Test func childrenCanBuildABalanceWithSafeBoundsAndRetryChecks() throws {
        let engine = CompareCampEngine()
        engine.start(category: .first, activity: .makeEqual, difficulty: .small)
        let round = try #require(engine.round)
        #expect(round.leftCount != round.rightCount)
        #expect(!engine.checkBuild())
        #expect(engine.completedRoundCount == 0)
        engine.advance()
        #expect(engine.roundIndex == 0)
        let before = engine.currentLeftCount
        engine.adjustLeft(by: Int.max)
        engine.adjustLeft(by: Int.min)
        #expect(engine.currentLeftCount == before)
        for _ in 0..<30 { engine.adjustLeft(by: -1) }
        #expect(engine.currentLeftCount == 0)
        #expect(!engine.canRemove)
        for _ in 0..<30 { engine.adjustLeft(by: 1) }
        #expect(engine.currentLeftCount == 5)
        #expect(!engine.canAdd)
        while engine.currentLeftCount != round.rightCount {
            engine.adjustLeft(by: engine.currentLeftCount < round.rightCount ? 1 : -1)
        }
        #expect(engine.checkBuild())
        #expect(engine.hasSolvedRound)
        #expect(!engine.canAdd && !engine.canRemove)
        #expect(engine.completedRoundCount == 1)
        #expect(engine.currentPrompt.contains("Both groups have \(round.category.quantityText(round.rightCount))"))
        #expect(!engine.checkBuild())
        #expect(engine.completedRoundCount == 1)
    }

    @Test func countingPairsAndHintsDoNotMutateQuantityOrGiveUnaskedAnswers() throws {
        let engine = CompareCampEngine()
        engine.start(category: .first, activity: .more, difficulty: .growing)
        let round = try #require(engine.round)
        for expected in 1...max(1, round.leftCount) where expected <= round.leftCount {
            #expect(engine.countNext(side: .left) == expected)
        }
        #expect(engine.countNext(side: .left) == nil)
        #expect(engine.revealedLeftCount == round.leftCount)
        #expect(engine.countedLeft == round.leftCount)
        engine.arrange()
        #expect(engine.isArranged)
        #expect(!engine.hintShown)
        #expect(engine.currentLeftCount == round.leftCount)
        #expect(engine.pairedCount == min(round.leftCount, round.rightCount))
        #expect(engine.unmatchedLeft + engine.unmatchedRight == round.difference)
        engine.showHint()
        #expect(engine.hintShown)
        #expect(!engine.hasSolvedRound)
        #expect(engine.completedRoundCount == 0)
        #expect(!engine.currentPrompt.contains(round.explanation))
        #expect(engine.select(answerID: round.correctAnswerID))
        #expect(engine.firstTryCount == 1)
        #expect(engine.helpedRoundCount == 1)
        #expect(engine.countNext(side: .right) == nil)
        engine.advance()
        #expect(!engine.hintShown && !engine.isArranged)
        #expect(engine.countedLeft == 0 && engine.countedRight == 0)
    }

    @Test func changingABuildResetsOnlyItsLeftTally() throws {
        let engine = CompareCampEngine()
        engine.start(category: .first, activity: .makeEqual, difficulty: .small)
        let round = try #require(engine.round)
        _ = engine.countNext(side: .left)
        _ = engine.countNext(side: .right)
        let rightTally = engine.countedRight
        engine.adjustLeft(by: engine.canAdd ? 1 : -1)
        #expect(engine.countedLeft == 0)
        #expect(engine.countedRight == rightTally)
        #expect(engine.round?.rightCount == round.rightCount)
    }

    @Test func completionIsFiniteSavedOnceAndReplayPreservesChoicesWithNewTasks() throws {
        let engine = CompareCampEngine()
        engine.start(category: .first, activity: .adventure, difficulty: .small, seed: .max)
        let firstRound = try #require(engine.round)
        for index in 0..<engine.roundGoal {
            #expect(engine.roundIndex == index)
            try solve(engine)
            engine.advance()
        }
        #expect(engine.phase == .completed)
        #expect(engine.completedRoundCount == 8)
        let result = try #require(engine.completion)
        #expect(result.categoryID == CompareCampCategory.first.id)
        #expect(result.activity == .adventure && result.difficulty == .small)
        #expect(result.seed == .max)
        #expect(result.roundsCompleted == 8 && result.firstTryCount == 8 && result.helpedRoundCount == 0)
        engine.advance()
        #expect(engine.completion == result)
        engine.replay()
        #expect(engine.phase == .playing)
        #expect(engine.seed == 0)
        #expect(engine.round != firstRound)
        #expect(engine.completion == nil)
        #expect(engine.completedRoundCount == 0)
        #expect(engine.activity == .adventure && engine.difficulty == .small)
        engine.chooseAnotherCamp()
        #expect(engine.phase == .choosingCamp)
        #expect(engine.round == nil && engine.completion == nil)
        #expect(engine.completedRoundCount == 0)
    }

    private func solve(_ engine: CompareCampEngine) throws {
        let round = try #require(engine.round)
        if round.activity == .makeEqual {
            while engine.currentLeftCount != round.rightCount {
                engine.adjustLeft(by: engine.currentLeftCount < round.rightCount ? 1 : -1)
            }
            #expect(engine.checkBuild())
        } else {
            #expect(engine.select(answerID: round.correctAnswerID))
        }
    }
}
