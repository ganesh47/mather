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

        let openMatchAttempt = state.recordOpenMatchChoice(id: "sun-heat")
        #expect(openMatchAttempt == MixMatchRecallAttempt(choiceID: "sun-heat", isCorrect: true))
        #expect(state.isRecallCardRevealed)
        #expect(state.openMatchFeedback == .correct(choiceID: "sun-heat"))

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
        #expect(state.activeLessonPrimaryActionTitle == "Start picture match")

        state.completeCurrentLessonStage()
        #expect(state.lessonThread.activeStage.kind == .invertedRecall)
        #expect(state.activeLessonPrimaryActionTitle == "Pick the matching name")

        _ = state.recordOpenMatchChoice(id: "sun-heat")
        #expect(state.activeLessonPrimaryActionTitle == "Loading next picture")

        for _ in 0..<4 { state.advanceLessonCard() }
        _ = state.recordOpenMatchChoice(id: state.currentLessonCard.id)
        #expect(state.activeLessonPrimaryActionTitle == "Opening ask card")

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
    @Test func mixMatchFinaleIgnoresIncorrectAttemptsAndAdvancesOnCurrentCorrectMatch() {
        var state = WaterCycleLabState()
        for _ in 0..<5 { state.advance() }
        state.completeCurrentLessonStage()
        state.completeCurrentLessonStage()
        state.completeCurrentLessonStage()

        #expect(state.lessonThread.activeStage.kind == .mixMatchFinale)
        #expect(state.currentMixMatchCard.answer.id == "sun-heat")

        state.recordMixMatchAttempt(MixMatchRecallAttempt(choiceID: "evaporation", isCorrect: false))
        #expect(state.currentMixMatchCard.answer.id == "sun-heat")
        #expect(state.mixMatchCorrectCardIDs.isEmpty)
        #expect(state.mixMatchProgressLabel == "Match 0 of 5")
        #expect(state.lessonThread.isComplete == false)

        state.recordMixMatchAttempt(MixMatchRecallAttempt(choiceID: "evaporation", isCorrect: true))
        #expect(state.currentMixMatchCard.answer.id == "sun-heat")
        #expect(state.mixMatchCorrectCardIDs.isEmpty)

        state.recordMixMatchAttempt(MixMatchRecallAttempt(choiceID: "sun-heat", isCorrect: true))
        #expect(state.mixMatchCorrectCardIDs == Set(["sun-heat"]))
        #expect(state.currentMixMatchCard.answer.id == "evaporation")
        #expect(state.mixMatchProgressLabel == "Match 1 of 5")
    }

    @Test func completedLessonThreadExposesDeterministicInterestingFacts() {
        var state = WaterCycleLabState()
        for _ in 0..<5 { state.advance() }
        state.completeCurrentLessonStage()
        state.completeCurrentLessonStage()
        state.completeCurrentLessonStage()

        #expect(state.completionInterestingFacts.isEmpty)

        for card in WaterCycleLessonThread.mixMatchCards {
            state.recordMixMatchAttempt(MixMatchRecallAttempt(choiceID: card.answer.id, isCorrect: true))
        }

        let facts = state.completionInterestingFacts
        #expect(facts.count == 3)
        #expect(facts.map(\.id) == [
            "rainiest-places",
            "same-water-travels",
            "cloud-tiny-drops"
        ])
        #expect(facts[0].body.contains("Mawsynram"))
        #expect(facts[0].body.contains("Cherrapunji"))
        #expect(facts.allSatisfy { !$0.title.isEmpty && !$0.body.isEmpty })
        #expect(state.activeLessonPrimaryActionTitle == "Try the cycle again")
    }



    @Test func waterCycleLessonReportsScoredQuizCycle() {
        var state = WaterCycleLabState()
        for _ in 0..<5 { state.advance() }

        #expect(state.lessonScore == 0)
        #expect(state.lessonScoreMax == 10)
        #expect(state.lessonScoreLabel == "Score 0 / 10")
        #expect(state.lessonRewardLabel == "Earn stars in picture quiz and Mix-Match")

        state.completeCurrentLessonStage()
        for index in WaterCycleLessonThread.cards.indices {
            let cardID = state.currentLessonCard.id
            _ = state.recordOpenMatchChoice(id: cardID)
            if index < WaterCycleLessonThread.cards.count - 1 {
                state.advanceLessonCard()
            }
        }

        #expect(state.lessonScore == 5)
        #expect(state.lessonScoreLabel == "Score 5 / 10")
        #expect(state.lessonRewardLabel == "5 quiz stars earned")

        state.completeCurrentLessonStage()
        state.completeCurrentLessonStage()
        for card in WaterCycleLessonThread.mixMatchCards {
            state.recordMixMatchAttempt(MixMatchRecallAttempt(choiceID: card.answer.id, isCorrect: true))
        }

        #expect(state.lessonThread.isComplete)
        #expect(state.lessonScore == 10)
        #expect(state.lessonScoreLabel == "Score 10 / 10")
        #expect(state.lessonRewardLabel == "Quiz cycle complete: 10 stars earned")
    }

    @Test func openPictureNameMatchRecordsDeterministicFeedback() {
        var state = WaterCycleLabState()
        for _ in 0..<5 { state.advance() }
        state.completeCurrentLessonStage()

        #expect(state.lessonThread.activeStage.title == "Picture Match")
        #expect(state.isRecallCardRevealed == false)

        let wrong = state.recordOpenMatchChoice(id: "evaporation")
        #expect(wrong == MixMatchRecallAttempt(choiceID: "evaporation", isCorrect: false))
        #expect(state.openMatchFeedback == .incorrect(choiceID: "evaporation"))
        #expect(state.isRecallCardRevealed == false)
        #expect(state.openMatchedCardIDs.isEmpty)

        let correct = state.recordOpenMatchChoice(id: "sun-heat")
        #expect(correct == MixMatchRecallAttempt(choiceID: "sun-heat", isCorrect: true))
        #expect(state.openMatchFeedback == .correct(choiceID: "sun-heat"))
        #expect(state.isRecallCardRevealed)
        #expect(state.openMatchedCardIDs == Set(["sun-heat"]))

        state.advanceAfterCorrectOpenMatch()
        #expect(state.currentLessonCard.id == "evaporation")
        #expect(state.openMatchFeedback == nil)
        #expect(state.isRecallCardRevealed == false)
        #expect(state.openMatchedCardIDs == Set(["sun-heat"]))
    }
    @Test func openPictureNameMatchAutoAdvanceMovesToNextCardOrAskStage() {
        var state = WaterCycleLabState()
        for _ in 0..<5 { state.advance() }
        state.completeCurrentLessonStage()

        _ = state.recordOpenMatchChoice(id: state.currentLessonCard.id)
        state.advanceAfterCorrectOpenMatch()
        #expect(state.lessonThread.activeStage.kind == .invertedRecall)
        #expect(state.currentLessonCard.id == "evaporation")

        while !state.isOnLastLessonCard {
            _ = state.recordOpenMatchChoice(id: state.currentLessonCard.id)
            state.advanceAfterCorrectOpenMatch()
        }
        _ = state.recordOpenMatchChoice(id: state.currentLessonCard.id)
        state.advanceAfterCorrectOpenMatch()
        #expect(state.lessonThread.activeStage.kind == .contextualAsk)
        #expect(state.currentLessonCard.id == "sun-heat")
    }

}
