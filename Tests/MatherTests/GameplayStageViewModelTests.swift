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

struct GameplayStageParityRegressionTests {
    @Test
    func memoryStagesChunkPairsIntoSmallTurns() {
        let thread = GameplaySampleThreads.countries
        let stage = thread.stages.first { $0.kind == .easyMemory }!
        let round = SpacedRepetitionScheduler.makeRound(thread: thread, stage: stage, seed: 44)
        var viewModel = GameplayMatchStageViewModel(
            thread: thread,
            round: round,
            mode: .easyMemory,
            turnItemCount: stage.recommendedTurnItemCount
        )

        #expect(viewModel.pairs.count == 4)
        #expect(viewModel.activePairs.count == 2)
        #expect(viewModel.turnCount == 2)
        #expect(viewModel.turnProgressText == "Turn 1/2")

        for pair in viewModel.activePairs {
            viewModel.selectLeft(pairID: pair.id)
            let matched = viewModel.chooseRight(pair.right)
            #expect(matched)
        }

        #expect(viewModel.canAdvanceTurn)
        viewModel.advanceTurn()
        #expect(viewModel.activeTurnIndex == 1)
        #expect(viewModel.activePairs.count == 2)
        #expect(viewModel.turnProgressText == "Turn 2/2")
    }

    @Test
    func rightCardTapWithoutSelectedPromptOpensDetailsWithoutMistake() {
        let thread = GameplaySampleThreads.countries
        let stage = thread.stages.first { $0.kind == .easyMemory }!
        let round = SpacedRepetitionScheduler.makeRound(thread: thread, stage: stage, seed: 45)
        var viewModel = GameplayMatchStageViewModel(thread: thread, round: round, mode: .easyMemory, turnItemCount: 2)
        let right = viewModel.shuffledRights[0]

        let matched = viewModel.chooseRight(right)

        #expect(!matched)
        #expect(viewModel.mismatchCount == 0)
        #expect(viewModel.inspectedItem == right)
    }

    @Test
    func bondBlastUsesNumbersStyleTapSelectThenMatchAcrossReadinessTurns() {
        let thread = GameplaySampleThreads.countries
        let stage = thread.stages.first { $0.kind == .bondBlast }!
        let round = SpacedRepetitionScheduler.makeRound(thread: thread, stage: stage, seed: 46)
        var viewModel = GameplayMatchStageViewModel(
            thread: thread,
            round: round,
            mode: .bondBlast,
            turnItemCount: stage.recommendedTurnItemCount
        )
        let pair = viewModel.activePairs[0]

        #expect(viewModel.activePairs.count <= 3)
        viewModel.selectLeft(pairID: pair.id)
        #expect(viewModel.selectedLeftID == pair.id)
        #expect(viewModel.inspectedItem == pair.left)
        let matched = viewModel.chooseRight(pair.right)
        #expect(matched)
        #expect(viewModel.correctCount == 1)
        #expect(viewModel.lastMatchedPairID == pair.id)
        #expect(
            viewModel.turnGuidanceText == "Nice match! Pick another prompt card."
                || viewModel.turnGuidanceText == "This turn is done. Move to the next mini-round when ready."
        )
    }

    @Test
    func matchTurnGuidanceExplainsFinishAndRecentSuccessState() {
        let thread = GameplaySampleThreads.countries
        let stage = thread.stages.first { $0.kind == .easyMemory }!
        let round = SpacedRepetitionScheduler.makeRound(thread: thread, stage: stage, seed: 48)
        var viewModel = GameplayMatchStageViewModel(thread: thread, round: round, mode: .easyMemory, turnItemCount: 2)
        let firstPair = viewModel.activePairs[0]

        #expect(viewModel.turnGuidanceText == "Pick a prompt card first, then tap its matching answer.")
        #expect(viewModel.finishRequirementText == "4 matches left to finish")

        viewModel.selectLeft(pairID: firstPair.id)
        #expect(viewModel.turnGuidanceText == "Now tap the matching answer card.")

        let firstMatched = viewModel.chooseRight(firstPair.right)
        #expect(firstMatched)
        #expect(viewModel.lastMatchedPairID == firstPair.id)
        #expect(viewModel.finishRequirementText == "3 matches left to finish")

        for pair in viewModel.activePairs where !viewModel.matchedPairIDs.contains(pair.id) {
            viewModel.selectLeft(pairID: pair.id)
            let matched = viewModel.chooseRight(pair.right)
            #expect(matched)
        }

        #expect(viewModel.canAdvanceTurn)
        #expect(viewModel.turnGuidanceText == "This turn is done. Move to the next mini-round when ready.")
        viewModel.advanceTurn()
        #expect(viewModel.lastMatchedPairID == nil)
    }


    @Test
    func reusableBondBlastRightTargetsRevealLikeNumbersBondBlastSlots() {
        #expect(!ReusableBondBlastBoard.shouldRevealRightCard(selectedPairID: nil, pairID: "bond-1", isMatched: false))
        #expect(ReusableBondBlastBoard.shouldRevealRightCard(selectedPairID: "bond-2", pairID: "bond-1", isMatched: false))
        #expect(ReusableBondBlastBoard.shouldRevealRightCard(selectedPairID: nil, pairID: "bond-1", isMatched: true))
    }

    @Test
    func waterBondBlastAcceptsArbitraryGameplayMatchPairDataInFocusedTurns() {
        let thread = GameplayThreadCatalog.waterCycle
        let stage = thread.stages.first { $0.kind == .bondBlast }!
        let round = SpacedRepetitionScheduler.makeRound(thread: thread, stage: stage, seed: 47)
        var viewModel = GameplayMatchStageViewModel(
            thread: thread,
            round: round,
            mode: .bondBlast,
            turnItemCount: stage.recommendedTurnItemCount
        )
        let active = viewModel.activePairs

        #expect(!active.isEmpty)
        #expect(active.count <= 3)
        let activePairsHaveDisplayText = active.allSatisfy { pair in
            !pair.left.title.isEmpty && !pair.right.title.isEmpty
        }
        #expect(activePairsHaveDisplayText)

        let pair = active[0]
        viewModel.selectLeft(pairID: pair.id)
        let matched = viewModel.chooseRight(pair.right)
        #expect(matched)
        #expect(viewModel.correctCount == 1)
    }

    @Test
    func stageDefinitionsKeepSingleCardAndPairTurnsChildSized() {
        let flashcard = GameplayStageDefinition(id: "learn", kind: .flashcards, title: "Learn", prompt: "Look", maximumItemCount: 8)
        let memory = GameplayStageDefinition(id: "remember", kind: .easyMemory, title: "Remember", prompt: "Match", maximumItemCount: 8)
        let blast = GameplayStageDefinition(id: "blast", kind: .bondBlast, title: "Bond Blast", prompt: "Match", maximumItemCount: 10)

        #expect(flashcard.recommendedTurnItemCount == 1)
        #expect(memory.recommendedTurnItemCount == 2)
        #expect(blast.recommendedTurnItemCount == 3)
    }
}
