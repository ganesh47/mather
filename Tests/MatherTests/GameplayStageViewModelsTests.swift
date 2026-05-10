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
    func retryCurrentStageRebuildsAttemptAndClearsCompletedResult() {
        let thread = GameplaySampleThreads.countries
        let start = Date(timeIntervalSince1970: 200)
        var state = GameplayStageNavigationState(startedAt: start, currentStageStartedAt: start)

        state.completeCurrentStage(thread: thread, correctCount: 3, mistakeCount: 0, now: start.addingTimeInterval(10))
        #expect(state.activeStageIndex == 1)
        let attemptBeforeRetry = state.stageAttemptID

        state.retryCurrentStage(in: thread, now: start.addingTimeInterval(12))

        #expect(state.activeStageIndex == 1)
        #expect(state.stageResults.map(\.stageID) == [thread.stages[0].id])
        #expect(state.currentStageStartedAt == start.addingTimeInterval(12))
        #expect(state.stageAttemptID != attemptBeforeRetry)
    }

    @Test
    func retryAfterThreadCompleteReturnsToLastStage() {
        let thread = GameplayThreadDefinition(
            id: "short-thread",
            title: "Short Thread",
            category: GameplayCategory(id: "test", title: "Test", subtitle: ""),
            propertyTypes: [],
            entities: [],
            stages: [
                GameplayStageDefinition(id: "look", kind: .flashcards, title: "Look", prompt: "Look"),
                GameplayStageDefinition(id: "quiz", kind: .multipleChoice, title: "Quiz", prompt: "Quiz")
            ]
        )
        let start = Date(timeIntervalSince1970: 300)
        var state = GameplayStageNavigationState(startedAt: start, currentStageStartedAt: start)
        state.completeCurrentStage(thread: thread, correctCount: 1, mistakeCount: 0, now: start.addingTimeInterval(5))
        state.completeCurrentStage(thread: thread, correctCount: 1, mistakeCount: 0, now: start.addingTimeInterval(10))
        #expect(state.isComplete(for: thread))

        state.retryCurrentStage(in: thread, now: start.addingTimeInterval(11))

        #expect(!state.isComplete(for: thread))
        #expect(state.activeStage(in: thread)?.id == "quiz")
        #expect(state.stageResults.map(\.stageID) == ["look"])
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
    func flipMemoryHiddenRightCardRevealsWhenTappedFirst() {
        let thread = GameplaySampleThreads.countries
        let stage = thread.stages.first { $0.kind == .flipMemory }!
        let round = SpacedRepetitionScheduler.makeRound(thread: thread, stage: stage, seed: 77)
        var viewModel = GameplayMatchStageViewModel(thread: thread, round: round, mode: .flipMemory, turnItemCount: 2)
        let firstRight = viewModel.shuffledRights[0]

        #expect(viewModel.shouldConcealRight(firstRight))
        let correct = viewModel.chooseRight(firstRight)

        #expect(!correct)
        #expect(!viewModel.shouldConcealRight(firstRight))
        #expect(viewModel.inspectedItemID == firstRight.id)
        #expect(viewModel.mismatchCount == 0)
    }

    @Test
    func matchTurnsAvoidDuplicateEntitiesWherePossible() {
        let thread = GameplaySampleThreads.countries
        let stage = thread.stages.first { $0.kind == .bondBlast }!
        let round = SpacedRepetitionScheduler.makeRound(thread: thread, stage: stage, seed: 18)
        let viewModel = GameplayMatchStageViewModel(thread: thread, round: round, mode: .bondBlast, turnItemCount: 3)

        #expect(viewModel.activePairs.count <= 3)
        #expect(Set(viewModel.activePairs.map { $0.left.entityID }).count == viewModel.activePairs.count)
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

struct GameplayThreadCatalogRegressionTests {
    @Test
    func allDirectGameplayEntriesUseFiveStageReusableThread() {
        let directEntries: [GameplayThreadID] = [.countries, .fruits, .waterCycle, .worldAnimals, .worldBirds]

        for id in directEntries {
            let thread = GameplayThreadCatalog.thread(for: id)
            #expect(thread.stages.map(\.kind) == [.flashcards, .easyMemory, .flipMemory, .bondBlast, .multipleChoice])
            #expect(!thread.entities.isEmpty)
        }
    }
}
