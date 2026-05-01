import Testing
@testable import Mather

struct LessonPlayThreadTests {
    @Test func advancesDeterministicStagesAndReportsProgress() {
        var thread = LessonPlayThread(
            id: "sample-thread",
            title: "Sample",
            stages: [
                LessonPlayStage(id: "look", kind: .lookLearnFlashcards, title: "Look", prompt: "Look."),
                LessonPlayStage(id: "picture-name", kind: .pictureNameMatch, title: "Picture-Name", prompt: "Match."),
                LessonPlayStage(id: "ask", kind: .contextualAsk, title: "Ask", prompt: "Ask."),
                LessonPlayStage(id: "match", kind: .mixMatchFinale, title: "Match", prompt: "Match.")
            ],
            cards: [
                LessonPlayCard(id: "card-1", title: "Card", prompt: "Prompt", answer: "Answer", detail: "Detail", assetName: nil)
            ]
        )

        #expect(thread.activeStage.kind == .lookLearnFlashcards)
        #expect(thread.progressLabel == "Level 1 of 4")
        #expect(thread.progress == 0)

        thread.completeActiveStage()
        #expect(thread.activeStage.kind == .pictureNameMatch)
        #expect(thread.progressLabel == "Level 2 of 4")
        #expect(thread.progress == 0.25)

        thread.completeActiveStage()
        thread.completeActiveStage()
        thread.completeActiveStage()
        #expect(thread.activeStage.kind == .mixMatchFinale)
        #expect(thread.isComplete)
        #expect(thread.progress == 1)

        thread.resetProgress()
        #expect(thread.activeStage.kind == .lookLearnFlashcards)
        #expect(!thread.isComplete)
        #expect(thread.progress == 0)
    }

    @Test func safeAskOnlyAnswersSuggestedCardScopedTurns() {
        var session = LessonSafeAskSession(
            cardID: "evaporation",
            suggestedTurns: [
                LessonSafeAskTurn(
                    id: "evaporation-what",
                    question: "What is evaporation?",
                    answer: "Evaporation is water vapor going up."
                )
            ]
        )

        #expect(LessonSafeAskSession.allowsMicrophoneInput == false)
        #expect(LessonSafeAskSession.allowsFreeformTextInput == false)

        let answer = session.respond(to: .suggestedTurn(id: "evaporation-what"))
        #expect(answer.kind == .answer)
        #expect(answer.spokenText.contains("water vapor"))
        #expect(session.selectedTurnIDs == ["evaporation-what"])

        let missing = session.respond(to: .suggestedTurn(id: "off-card"))
        #expect(missing.kind == .refusal)
        #expect(missing.spokenText.contains("only talk about this card"))

        let unsupported = session.respond(to: .unsupportedTopic)
        #expect(unsupported.kind == .refusal)
    }
}
