import Testing
@testable import Mather

struct SmartPlayProviderTests {
    @Test
    func curatedProviderReturnsDeterministicHint() async {
        let provider: any SmartPlayProvider = CuratedSmartPlayProvider()
        let request = SmartPlayRequest.hint(SmartPlayHintRequest(
            context: SmartPlayActivityContext(
                laneID: "numbers",
                activityID: "make-break",
                stageID: "concrete",
                goal: "making 10",
                problemText: "6 and 4"
            ),
            attemptSummary: "moved six counters"
        ))

        let first = await provider.prompt(for: request)
        let second = await provider.prompt(for: request)

        #expect(first == second)
        #expect(first.kind == .hint)
        #expect(first.source == .curatedFallback)
        #expect(first.spokenText == "Try one careful move for 6 and 4. Then check how it helps with making 10.")
    }

    @Test
    func curatedProviderSupportsStoryRequests() async {
        let provider = CuratedSmartPlayProvider()
        let request = SmartPlayRequest.story(SmartPlayStoryRequest(
            context: SmartPlayActivityContext(
                laneID: "geometry",
                activityID: "symmetry-fold",
                goal: "matching two equal halves",
                themeID: "paper garden"
            ),
            storySeed: "butterfly"
        ))

        let prompt = await provider.prompt(for: request)

        #expect(prompt.kind == .story)
        #expect(prompt.source == .curatedFallback)
        #expect(prompt.spokenText == "Here is a paper garden story. We are exploring matching two equal halves with calm, careful choices.")
    }

    @Test
    func curatedProviderSupportsReviewPromptRequests() async {
        let provider = CuratedSmartPlayProvider()
        let request = SmartPlayRequest.reviewPrompt(SmartPlayReviewPromptRequest(
            context: SmartPlayActivityContext(
                laneID: "physics",
                activityID: "gravity-artist",
                goal: "predicting tilt direction"
            ),
            completedSkillSummary: "tilt changed the path"
        ))

        let prompt = await provider.prompt(for: request)

        #expect(prompt.kind == .review)
        #expect(prompt.source == .curatedFallback)
        #expect(prompt.spokenText == "Show that idea one more way: tilt changed the path. Say what stayed the same.")
    }

    @Test
    func curatedProviderCleansRequestTextWithoutChangingPrivacyBoundary() async {
        let provider = CuratedSmartPlayProvider()
        let request = SmartPlayRequest.hint(SmartPlayHintRequest(
            context: SmartPlayActivityContext(
                laneID: "numbers",
                activityID: "bond-blast",
                goal: "finding partners\nfor 10",
                problemText: "  7   and   3  "
            )
        ))

        let prompt = await provider.prompt(for: request)

        #expect(prompt.spokenText == "Try one careful move for 7 and 3. Then check how it helps with finding partners for 10.")
    }

    @Test
    func curatedProviderTextAvoidsPressureAndNetworkClaims() async {
        let provider = CuratedSmartPlayProvider()
        let context = SmartPlayActivityContext(
            laneID: "numbers",
            activityID: "make-break",
            goal: "making 10",
            problemText: "8 and 2",
            themeID: "space"
        )
        let prompts = [
            await provider.prompt(for: .hint(SmartPlayHintRequest(context: context))),
            await provider.prompt(for: .story(SmartPlayStoryRequest(context: context))),
            await provider.prompt(for: .reviewPrompt(SmartPlayReviewPromptRequest(context: context)))
        ]
        let bannedTerms = [
            "ai",
            "chatgpt",
            "network",
            "internet",
            "timer",
            "hurry",
            "race",
            "wrong",
            "lose",
            "lost",
            "scary",
            "danger"
        ]

        for prompt in prompts {
            let text = prompt.spokenText.lowercased()
            for term in bannedTerms {
                #expect(!text.contains(term))
            }
        }
    }
}
