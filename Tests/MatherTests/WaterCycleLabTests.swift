import Testing
@testable import Mather

struct WaterCycleLabTests {
    @Test func inquiryLoopNamesWaterCycleStagesInOrder() {
        var state = WaterCycleLabState()
        #expect(state.stage == .wonder)
        #expect(state.prompt.contains("warm sun"))

        state.advance()
        #expect(state.stage == .evaporation)
        #expect(state.prompt.contains("evaporation"))

        state.advance()
        #expect(state.stage == .condensation)
        #expect(state.vaporDrops == 3)
        #expect(state.pondDrops == 2)
        #expect(state.prompt.contains("condensation"))

        state.advance()
        #expect(state.stage == .precipitation)
        #expect(state.cloudDrops == 3)
        #expect(state.vaporDrops == 0)
        #expect(state.prompt.contains("precipitation"))

        state.advance()
        #expect(state.stage == .collection)
        #expect(state.rainDrops == 3)
        #expect(state.cloudDrops == 0)

        state.advance()
        #expect(state.stage == .complete)
        #expect(state.cyclesCompleted == 1)
        #expect(state.pondDrops == 4)
        #expect(state.rainDrops == 0)
    }

    @Test func resetKeepsCompletedCycleCountForSessionScore() {
        var state = WaterCycleLabState()
        for _ in 0..<5 { state.advance() }
        #expect(state.stage == .complete)
        #expect(state.cyclesCompleted == 1)

        state.reset()
        #expect(state.stage == .wonder)
        #expect(state.cyclesCompleted == 1)
        #expect(state.vaporDrops == 0)
        #expect(state.cloudDrops == 0)
        #expect(state.rainDrops == 0)
        #expect(state.pondDrops == 4)
    }

    @Test func completeStageStartsAnotherInquiryCycle() {
        var state = WaterCycleLabState()
        for _ in 0..<5 { state.advance() }
        state.advance()

        #expect(state.stage == .wonder)
        #expect(state.cyclesCompleted == 1)
        #expect(state.progress == 0.0)
    }

    @Test func sceneMetricsFitCompactPhoneWidth() {
        let metrics = WaterCycleSceneMetrics(availableWidth: 288)

        #expect(abs(metrics.scale - 0.72) < 0.001)
        #expect(metrics.sunHaloSize < 100)
        #expect(metrics.cloudCapsuleWidth < 124)
        #expect(metrics.columnWidth <= 116)
        #expect(metrics.horizontalInset >= 21)

        let topRowMinimum = metrics.sunHaloSize + metrics.cloudCapsuleWidth + metrics.horizontalInset * 2
        #expect(topRowMinimum < metrics.availableWidth)

        let middleRowMinimum = metrics.columnWidth * 2 + metrics.horizontalInset * 2
        #expect(middleRowMinimum < metrics.availableWidth)
    }
}

extension WaterCycleLabTests {
    @Test func completionUnlocksConceptFlashcardReviewDeck() {
        var state = WaterCycleLabState()
        for _ in 0..<5 { state.advance() }

        #expect(state.stage == .complete)
        #expect(WaterCycleConceptFlashcard.reviewDeck.count >= 5)
        #expect(state.currentFlashcard.concept == "Sun Heat")
        #expect(state.flashcardProgressLabel == "Card 1 of 5")
        #expect(state.isFlashcardAnswerRevealed == false)

        state.revealFlashcardAnswer()
        #expect(state.isFlashcardAnswerRevealed)
        #expect(state.currentFlashcard.answer.contains("sun warms"))

        state.advanceFlashcard()
        #expect(state.currentFlashcard.concept == "Evaporation")
        #expect(state.flashcardProgressLabel == "Card 2 of 5")
        #expect(state.isFlashcardAnswerRevealed == false)
    }

    @Test func flashcardReviewWrapsAndResetsWithInquiryCycle() {
        var state = WaterCycleLabState()
        for _ in 0..<5 { state.advance() }

        for _ in 0..<WaterCycleConceptFlashcard.reviewDeck.count { state.advanceFlashcard() }
        #expect(state.currentFlashcard.concept == "Sun Heat")

        state.revealFlashcardAnswer()
        state.completeCurrentLessonStage()
        #expect(state.lessonThread.activeStage.kind == .invertedRecall)

        state.reset()
        #expect(state.stage == .wonder)
        #expect(state.flashcardIndex == 0)
        #expect(state.isFlashcardAnswerRevealed == false)
        #expect(state.lessonThread.activeStage.kind == .lookLearnFlashcards)
        #expect(state.mixMatchCorrectCardIDs.isEmpty)
    }

    @Test func completedCycleUnlocksStagedLessonThread() {
        var state = WaterCycleLabState()
        for _ in 0..<5 { state.advance() }

        #expect(state.stage == .complete)
        #expect(state.lessonThread.stages.map(\.kind) == [
            .lookLearnFlashcards,
            .invertedRecall,
            .contextualAsk,
            .mixMatchFinale
        ])
        #expect(state.currentLessonCard.title == "Sun Heat")
        #expect(state.currentLessonCard.assetName == "MemoryWaterCycleSunHeat")

        state.completeCurrentLessonStage()
        #expect(state.lessonThread.activeStage.kind == .invertedRecall)
        #expect(state.isRecallCardRevealed == false)

        state.revealRecallCard()
        #expect(state.isRecallCardRevealed)

        state.completeCurrentLessonStage()
        #expect(state.lessonThread.activeStage.kind == .contextualAsk)
        #expect(state.askSession.cardID == "sun-heat")
        #expect(state.askSession.suggestedTurns.count == 2)

        let response = state.selectAskTurn(id: "sun-heat-what")
        #expect(response?.kind == .answer)
        #expect(response?.spokenText.contains("Sun Heat") == true)

        state.completeCurrentLessonStage()
        #expect(state.lessonThread.activeStage.kind == .mixMatchFinale)
        #expect(state.currentMixMatchCard.answer.id == "sun-heat")

        for card in WaterCycleLessonThread.mixMatchCards {
            let attempt = MixMatchRecallAttempt(choiceID: card.answer.id, isCorrect: true)
            state.recordMixMatchAttempt(attempt)
        }

        #expect(state.lessonThread.isComplete)
        #expect(state.mixMatchProgressLabel == "Match 5 of 5")
    }

    @Test func completedLessonThreadExposesStageFocusedPrimaryActions() {
        var state = WaterCycleLabState()
        for _ in 0..<5 { state.advance() }

        #expect(state.stage == .complete)
        #expect(state.activeLessonProgressLabel == "Level 1 of 4 - Card 1 of 5")
        #expect(state.activeLessonPrimaryActionTitle == "Next look card")

        for _ in 0..<4 { state.advanceLessonCard() }
        #expect(state.isOnLastLessonCard)
        #expect(state.activeLessonPrimaryActionTitle == "Start flip recall")

        state.completeCurrentLessonStage()
        #expect(state.lessonThread.activeStage.kind == .invertedRecall)
        #expect(state.activeLessonPrimaryActionTitle == "Flip recall card")

        state.revealRecallCard()
        #expect(state.activeLessonPrimaryActionTitle == "Next recall")

        for _ in 0..<4 { state.advanceLessonCard() }
        state.revealRecallCard()
        #expect(state.activeLessonPrimaryActionTitle == "Ask this card")

        state.completeCurrentLessonStage()
        #expect(state.lessonThread.activeStage.kind == .contextualAsk)
        #expect(state.activeLessonPrimaryActionTitle == "Ask suggested question")

        _ = state.selectAskTurn(id: "sun-heat-what")
        #expect(state.activeLessonPrimaryActionTitle == "Next ask card")

        for _ in 0..<4 {
            state.advanceLessonCard()
            _ = state.selectAskTurn(id: "\(state.currentLessonCard.id)-what")
        }
        #expect(state.activeLessonPrimaryActionTitle == "Start mix-match")

        state.completeCurrentLessonStage()
        #expect(state.lessonThread.activeStage.kind == .mixMatchFinale)
        #expect(state.activeLessonPrimaryActionTitle == "Hear match clue")
    }

    @Test func mixMatchFinalePrimaryActionReflectsCompletionWithoutChangingMastery() {
        var state = WaterCycleLabState()
        for _ in 0..<5 { state.advance() }
        state.completeCurrentLessonStage()
        state.completeCurrentLessonStage()
        state.completeCurrentLessonStage()

        #expect(state.lessonThread.activeStage.kind == .mixMatchFinale)
        #expect(state.activeLessonPrimaryActionTitle == "Hear match clue")

        for card in WaterCycleLessonThread.mixMatchCards {
            state.recordMixMatchAttempt(MixMatchRecallAttempt(choiceID: card.answer.id, isCorrect: true))
        }

        #expect(state.lessonThread.isComplete)
        #expect(state.activeLessonPrimaryActionTitle == "Try the cycle again")
        #expect(state.cyclesCompleted == 1)
    }

    @Test func completedLessonThreadExposesDeterministicInterestingFacts() {
        var state = WaterCycleLabState()
        for _ in 0..<5 { state.advance() }
        state.completeCurrentLessonStage()
        state.completeCurrentLessonStage()
        state.completeCurrentLessonStage()

        for card in WaterCycleLessonThread.mixMatchCards {
            state.recordMixMatchAttempt(MixMatchRecallAttempt(choiceID: card.answer.id, isCorrect: true))
        }

        #expect(state.lessonThread.isComplete)
        #expect(WaterCycleInterestingFact.completionFacts.count >= 4)
        #expect(state.currentInterestingFact.title == "Rainiest place")
        #expect(state.interestingFactProgressLabel == "Fact 1 of 4")
        #expect(state.currentInterestingFact.detail.contains("Mawsynram"))

        state.advanceInterestingFact()
        #expect(state.currentInterestingFact.title == "Driest desert")
        #expect(state.interestingFactProgressLabel == "Fact 2 of 4")
    }

    @Test func interestingFactsIgnoreEarlyAdvanceAndResetWithReplay() {
        var state = WaterCycleLabState()

        state.advanceInterestingFact()
        #expect(state.currentInterestingFact.title == "Rainiest place")

        for _ in 0..<5 { state.advance() }
        state.completeCurrentLessonStage()
        state.completeCurrentLessonStage()
        state.completeCurrentLessonStage()
        state.advanceInterestingFact()
        #expect(state.currentInterestingFact.title == "Rainiest place")

        for card in WaterCycleLessonThread.mixMatchCards {
            state.recordMixMatchAttempt(MixMatchRecallAttempt(choiceID: card.answer.id, isCorrect: true))
        }
        state.advanceInterestingFact()
        #expect(state.currentInterestingFact.title == "Driest desert")

        state.reset()
        #expect(state.stage == .wonder)
        #expect(state.currentInterestingFact.title == "Rainiest place")
        #expect(state.interestingFactProgressLabel == "Fact 1 of 4")
    }
}
