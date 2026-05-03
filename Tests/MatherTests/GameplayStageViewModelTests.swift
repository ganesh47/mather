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
