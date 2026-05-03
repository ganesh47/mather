import CoreGraphics
import Foundation
import Testing
@testable import Mather

struct GameplayStageViewModelsTests {
    @Test
    func navigationCompletesOneActiveStageAtATime() {
        let thread = GameplaySampleThreads.countries
        let start = Date(timeIntervalSince1970: 100)
        let finish = Date(timeIntervalSince1970: 125)
        var state = GameplayStageNavigationState(startedAt: start, currentStageStartedAt: start)

        #expect(state.activeStage(in: thread)?.kind == .flashcards)
        #expect(state.progressFraction(for: thread) == 0.2)

        state.completeCurrentStage(thread: thread, correctCount: 4, mistakeCount: 1, hintsUsed: 0, now: finish)

        #expect(state.activeStage(in: thread)?.kind == .easyMemory)
        #expect(state.stageResults.count == 1)
        #expect(state.stageResults.first?.durationSeconds == 25)
        #expect(state.canGoBack)
    }

    @Test
    func contentBuilderCreatesPropertyPairsForRoundItems() {
        let thread = GameplaySampleThreads.countries
        let stage = thread.stages.first { $0.kind == .easyMemory }!
        let round = SpacedRepetitionScheduler.makeRound(thread: thread, stage: stage, seed: 912)

        let pairs = GameplayStageContentBuilder.matchPairs(thread: thread, round: round)

        #expect(!pairs.isEmpty)
        #expect(pairs.allSatisfy { $0.left.entityID == $0.right.entityID })
        #expect(pairs.allSatisfy { $0.right.subtitle == "Capital" })
    }

    @Test
    func multipleChoiceQuestionsIncludeAnswerAndDistractors() {
        let thread = GameplaySampleThreads.countries
        let stage = thread.stages.first { $0.kind == .multipleChoice }!
        let round = SpacedRepetitionScheduler.makeRound(thread: thread, stage: stage, seed: 5)

        let questions = GameplayStageContentBuilder.multipleChoiceQuestions(thread: thread, round: round, choicesPerQuestion: 4)

        #expect(questions.count == min(stage.maximumItemCount, thread.entities.count))
        #expect(questions.allSatisfy { question in question.choices.contains(question.answer) })
        #expect(questions.allSatisfy { question in question.choices.count >= 2 })
    }

    @Test
    func renderSupportKeepsCompactPhoneCardsLargeEnough() {
        #expect(GameplayStageRenderSupport.usesCompactStageLayout(width: 390, height: 720))
        #expect(GameplayStageRenderSupport.cardMinimumWidth(availableWidth: 390, compact: true) >= 132)
        #expect(GameplayStageRenderSupport.cardMinimumWidth(availableWidth: 820, compact: false) == 180)
    }
}
