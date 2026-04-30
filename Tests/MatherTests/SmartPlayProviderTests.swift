import Testing
@testable import Mather

@Suite("SmartPlayProvider")
struct SmartPlayProviderTests {
    @MainActor
    @Test func curatedFallbackReturnsDeterministicHint() async {
        let provider = CuratedSmartPlayProvider()
        let request = SmartPlayHintRequest(
            context: SmartPlayRequestContext(
                laneID: "make-break-10",
                stageID: "concrete",
                learningGoal: "Make and break to 10"
            ),
            currentProblem: "Split 10 into two groups",
            attemptCount: 0,
            availableTools: ["counters"]
        )

        let first = await provider.hint(for: request)
        let second = await provider.hint(for: request)

        #expect(first == second)
        #expect(first.source == .curatedFallback)
        #expect(first.spokenText == "Try moving one counter, then count each group.")
    }

    @MainActor
    @Test func curatedFallbackReturnsDeterministicStory() async {
        let provider = CuratedSmartPlayProvider()
        let request = SmartPlayStoryRequest(
            context: SmartPlayRequestContext(laneID: "vs1", stageID: "story"),
            theme: "vehicles",
            targetNumber: 10
        )

        let response = await provider.story(for: request)

        #expect(response.source == .curatedFallback)
        #expect(response.spokenText == "The builders are sharing 10 blocks between two trucks. Move the blocks until both trucks match your plan.")
    }

    @MainActor
    @Test func curatedFallbackReturnsDeterministicReviewPrompt() async {
        let provider = CuratedSmartPlayProvider()
        let request = SmartPlayReviewPromptRequest(
            context: SmartPlayRequestContext(laneID: "make-break-10", stageID: "review"),
            completedActivities: ["concrete", "pictorial", "abstract"],
            successCount: 3,
            retryCount: 1
        )

        let response = await provider.reviewPrompt(for: request)

        #expect(response.source == .curatedFallback)
        #expect(response.spokenText == "Show how you made the number two ways. Tell which parts stayed the same.")
    }

    @MainActor
    @Test func unknownContextUsesGenericSafeFallbacks() async {
        let provider = CuratedSmartPlayProvider()
        let context = SmartPlayRequestContext(laneID: "future-lane", stageID: "unknown")

        let hint = await provider.hint(for: SmartPlayHintRequest(context: context, attemptCount: 4))
        let story = await provider.story(for: SmartPlayStoryRequest(context: context, theme: ""))
        let review = await provider.reviewPrompt(for: SmartPlayReviewPromptRequest(context: context))

        #expect(hint == SmartPlayHintResponse(
            spokenText: "Try one small move, then check what changed.",
            source: .curatedFallback
        ))
        #expect(story == SmartPlayStoryResponse(
            spokenText: "This math challenge needs careful looking. Try a move, then check your answer.",
            source: .curatedFallback
        ))
        #expect(review == SmartPlayReviewPromptResponse(
            spokenText: "Show one thing you tried. Tell what changed when you tried it.",
            source: .curatedFallback
        ))
    }
}
