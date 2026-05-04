import CoreGraphics
import Foundation
import Testing
@testable import Mather

struct GameplayStageViewModelTests {
    @Test
    func fiveStageSampleThreadCanNavigateThroughAllStages() {
        let thread = GameplaySampleThreads.countries
        let start = Date(timeIntervalSince1970: 10)
        var navigation = GameplayStageNavigationState(startedAt: start, currentStageStartedAt: start)

        for index in thread.stages.indices {
            #expect(navigation.activeStage(in: thread)?.id == thread.stages[index].id)
            navigation.completeCurrentStage(
                thread: thread,
                correctCount: 2,
                mistakeCount: index == 2 ? 1 : 0,
                now: start.addingTimeInterval(Double(index + 1) * 5)
            )
        }

        #expect(navigation.isComplete(for: thread))
        #expect(navigation.stageResults.count == 5)
        #expect(navigation.summary().correctCount == 10)
        #expect(navigation.summary().mistakeCount == 1)
    }

    @Test
    func retryReopensCompletedCurrentStageWithFreshAttemptToken() {
        let thread = GameplaySampleThreads.countries
        let start = Date(timeIntervalSince1970: 20)
        var navigation = GameplayStageNavigationState(startedAt: start, currentStageStartedAt: start)

        for index in thread.stages.indices {
            navigation.completeCurrentStage(
                thread: thread,
                correctCount: 2,
                mistakeCount: 0,
                now: start.addingTimeInterval(Double(index + 1) * 5)
            )
        }

        #expect(navigation.isComplete(for: thread))
        let previousToken = navigation.stageAttemptToken

        navigation.retryCurrentStage(in: thread, now: start.addingTimeInterval(100))

        #expect(!navigation.isComplete(for: thread))
        #expect(navigation.activeStage(in: thread)?.id == thread.stages.last?.id)
        #expect(!navigation.stageResults.contains { $0.stageID == thread.stages.last?.id })
        #expect(navigation.stageAttemptToken == previousToken + 1)
    }

    @Test
    func backFromCompletedSummaryReopensPreviousStage() {
        let thread = GameplaySampleThreads.countries
        let start = Date(timeIntervalSince1970: 30)
        var navigation = GameplayStageNavigationState(startedAt: start, currentStageStartedAt: start)

        for index in thread.stages.indices {
            navigation.completeCurrentStage(
                thread: thread,
                correctCount: 2,
                mistakeCount: 0,
                now: start.addingTimeInterval(Double(index + 1) * 5)
            )
        }

        #expect(navigation.isComplete(for: thread))

        navigation.goBack(in: thread, now: start.addingTimeInterval(100))

        #expect(!navigation.isComplete(for: thread))
        #expect(navigation.activeStage(in: thread)?.id == thread.stages[thread.stages.count - 2].id)
        #expect(!navigation.stageResults.contains { $0.stageID == thread.stages[thread.stages.count - 2].id })
    }

    @Test
    func flashcardListenAgainAccessibilityNamesActiveCardAndTracksExposure() {
        let thread = GameplaySampleThreads.countries
        let stage = thread.stages[0]
        let round = SpacedRepetitionScheduler.makeRound(thread: thread, stage: stage, seed: 1)
        var viewModel = GameplayFlashcardStageViewModel(thread: thread, round: round)

        let activeTitle = viewModel.activeCard?.title ?? ""
        #expect(!activeTitle.isEmpty)
        #expect(viewModel.listenAgainAccessibilityLabel == "Listen again to \(activeTitle)")
        viewModel.markExposure()
        viewModel.markExposure()
        #expect(viewModel.exposureCount == 2)
    }

    @Test
    func matchViewModelProducesAccessibleLabelsAndCountsMistakes() {
        let thread = GameplaySampleThreads.countries
        let stage = thread.stages.first { $0.kind == .easyMemory }!
        let round = SpacedRepetitionScheduler.makeRound(thread: thread, stage: stage, seed: 2)
        var viewModel = GameplayMatchStageViewModel(thread: thread, round: round, mode: .easyMemory)
        let firstPair = viewModel.pairs[0]
        let wrongRight = viewModel.pairs.first { $0.id != firstPair.id }!.right

        #expect(viewModel.accessibilityLabel(for: firstPair.left, side: .left).contains("prompt: \(firstPair.left.title)"))
        viewModel.selectLeft(pairID: firstPair.id)
        let wrongResult = viewModel.chooseRight(wrongRight)
        #expect(!wrongResult)
        #expect(viewModel.mismatchCount == 1)
        let correctResult = viewModel.chooseRight(firstPair.right)
        #expect(correctResult)
        #expect(viewModel.correctCount == 1)
    }

    @Test
    func flipMemoryConcealsUnmatchedAnswerCardsUntilMatched() {
        let thread = CountryGameplayThread.thread
        let stage = thread.stages.first { $0.kind == .flipMemory }!
        let round = SpacedRepetitionScheduler.makeRound(thread: thread, stage: stage, seed: 923)
        var viewModel = GameplayMatchStageViewModel(thread: thread, round: round, mode: .flipMemory)
        let firstPair = viewModel.pairs[0]

        #expect(viewModel.shouldConcealRight(firstPair.right))
        #expect(viewModel.accessibilityLabel(for: firstPair.right, side: .right) == "hidden answer card")

        viewModel.selectLeft(pairID: firstPair.id)
        let didMatch = viewModel.chooseRight(firstPair.right)
        #expect(didMatch)

        #expect(!viewModel.shouldConcealRight(firstPair.right))
        #expect(viewModel.accessibilityLabel(for: firstPair.right, side: .right).contains(firstPair.right.title))
    }

    @Test
    func multipleChoiceQuestionsKeepVisibleAnswerAndDeterministicChoices() {
        let thread = GameplaySampleThreads.countries
        let stage = thread.stages.first { $0.kind == .multipleChoice }!
        let round = SpacedRepetitionScheduler.makeRound(thread: thread, stage: stage, seed: 3)
        var viewModel = GameplayMultipleChoiceStageViewModel(thread: thread, round: round)
        let firstQuestion = viewModel.activeQuestion!

        #expect(firstQuestion.choices.contains(firstQuestion.answer))
        #expect(firstQuestion.prompt.hasPrefix("Which one matches "))
        let quizResult = viewModel.choose(firstQuestion.answer)
        #expect(quizResult)
        #expect(viewModel.correctCount == 1)
        #expect(viewModel.progressText == "2 of 4")
    }

    @Test
    func compactStageLayoutKeepsLargeTapTargets() {
        #expect(GameplayStageRenderSupport.usesCompactStageLayout(width: 393, height: 700))
        #expect(GameplayStageRenderSupport.cardMinimumWidth(availableWidth: 393, compact: true) >= 132)
        #expect(GameplayStageRenderSupport.touchTargetSize(compact: true) >= 54)
        #expect(GameplayStageRenderSupport.maximumContentWidth(compact: false) == 920)
    }
}
