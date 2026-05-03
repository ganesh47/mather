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
        let allPairsMatchEntities = pairs.allSatisfy { pair in
            pair.left.entityID == pair.right.entityID
        }
        let allPairsUseCapitalSubtitle = pairs.allSatisfy { pair in
            pair.right.subtitle == "Capital"
        }
        #expect(allPairsMatchEntities)
        #expect(allPairsUseCapitalSubtitle)
    }

    @Test
    func multipleChoiceQuestionsIncludeAnswerAndDistractors() {
        let thread = GameplaySampleThreads.countries
        let stage = thread.stages.first { $0.kind == .multipleChoice }!
        let round = SpacedRepetitionScheduler.makeRound(thread: thread, stage: stage, seed: 5)

        let questions = GameplayStageContentBuilder.multipleChoiceQuestions(thread: thread, round: round, choicesPerQuestion: 4)

        #expect(questions.count == min(stage.maximumItemCount, thread.entities.count))
        let allQuestionsContainAnswer = questions.allSatisfy { question in
            question.choices.contains(question.answer)
        }
        let allQuestionsHaveDistractors = questions.allSatisfy { question in
            question.choices.count >= 2
        }
        #expect(allQuestionsContainAnswer)
        #expect(allQuestionsHaveDistractors)
    }

    @Test
    func renderSupportKeepsCompactPhoneCardsLargeEnough() {
        #expect(GameplayStageRenderSupport.usesCompactStageLayout(width: 390, height: 720))
        #expect(GameplayStageRenderSupport.cardMinimumWidth(availableWidth: 390, compact: true) >= 132)
        #expect(GameplayStageRenderSupport.cardMinimumWidth(availableWidth: 820, compact: false) == 180)
    }
}
