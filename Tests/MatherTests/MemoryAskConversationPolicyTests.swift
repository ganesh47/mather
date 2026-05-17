import Testing
@testable import Mather

@Suite("MemoryAskConversationPolicy")
struct MemoryAskConversationPolicyTests {
    private struct StubTurnProvider: MemoryAskConversationTurnProvider {
        let isAvailable: Bool
        let turns: [MemoryAskSuggestedTurn]

        func suggestedTurns(for animal: MemoryAnimal) async throws -> [MemoryAskSuggestedTurn] {
            turns
        }
    }

    @MainActor
    @Test func jupiterGetsSuggestedCardTurns() async {
        let jupiter = MemoryDeck.planets.first { $0.canonicalName == "Jupiter" }!
        let session = await MemoryAskConversationPolicy().startSession(for: jupiter)

        #expect(session.cardId == "planet-jupiter")
        #expect(session.source == .deterministicFallback)
        #expect(session.suggestedTurns.map(\.question) == [
            "Where is Jupiter?",
            "How big is Jupiter?",
            "What is special about Jupiter?"
        ])
        let spokenAnswers = session.suggestedTurns.map(\.answer).joined(separator: " ")
        #expect(spokenAnswers.localizedCaseInsensitiveContains("139,820 km"))
        #expect(spokenAnswers.localizedCaseInsensitiveContains("biggest planet"))
    }

    @MainActor
    @Test func unavailableProviderUsesDeterministicFallback() async {
        let provider = StubTurnProvider(
            isAvailable: false,
            turns: [
                MemoryAskSuggestedTurn(id: "generated", question: "Generated?", answer: "Generated answer.")
            ]
        )
        let session = await MemoryAskConversationPolicy(provider: provider).startSession(for: MemoryDeck.planets[4])

        #expect(session.source == .deterministicFallback)
        #expect(session.suggestedTurns.map(\.id).contains("generated") == false)
        #expect(session.suggestedTurns.count == 3)
    }

    @MainActor
    @Test func fallbackProvidesTurnsForEveryMemoryDeckCard() async {
        let policy = MemoryAskConversationPolicy()

        for deck in MemoryView.DeckSelection.allCases {
            for animal in deck.animals {
                let session = await policy.startSession(for: animal)
                #expect(session.source == .deterministicFallback)
                #expect(!session.suggestedTurns.isEmpty, "Missing ask turns for \(deck.menuLabel): \(animal.id)")
            }
        }
    }

    @MainActor
    @Test func fallbackUsesCustomFactCardsWhenMetadataHasNoGenericTurns() async {
        let policy = MemoryAskConversationPolicy()
        let evaporation = MemoryDeck.waterCycle.first { $0.id == "water-cycle-evaporation" }!
        let fruit = MemoryDeck.fruits.first { $0.detailCards.contains { $0.title == "Taste" } }!

        let waterSession = await policy.startSession(for: evaporation)
        let fruitSession = await policy.startSession(for: fruit)

        #expect(waterSession.suggestedTurns.contains { $0.id == "fact-concept" || $0.id == "fact-action" })
        #expect(waterSession.suggestedTurns.contains { $0.answer.localizedCaseInsensitiveContains("Action:") })
        #expect(fruitSession.suggestedTurns.contains { $0.id == "fact-taste" || $0.id == "fact-usually-found" })
    }

    @MainActor
    @Test func availableProviderCanSupplyBoundedSuggestedTurnsOnly() async {
        let provider = StubTurnProvider(
            isAvailable: true,
            turns: [
                MemoryAskSuggestedTurn(id: "spot", question: "What spot is on Jupiter?", answer: "Jupiter has a storm called the Great Red Spot."),
                MemoryAskSuggestedTurn(id: "off-card", question: "Tell me about bedtime", answer: "This is not about the current card.")
            ]
        )
        let session = await MemoryAskConversationPolicy(provider: provider).startSession(for: MemoryDeck.planets[4])

        #expect(session.source == .appleIntelligenceSuggested)
        #expect(session.suggestedTurns == [
            MemoryAskSuggestedTurn(id: "spot", question: "What spot is on Jupiter?", answer: "Jupiter has a storm called the Great Red Spot.")
        ])
    }

    @MainActor
    @Test func offScopeRequestGetsCardOnlyRefusal() async {
        var session = await MemoryAskConversationPolicy().startSession(for: MemoryDeck.planets[4])

        let response = session.respond(to: .unsupportedTopic)

        #expect(response.kind == .refusal)
        #expect(response.spokenText == "I can only talk about this card. Pick one of the card questions.")
        #expect(session.selectedTurnIDs.isEmpty)
    }

    @MainActor
    @Test func sessionRetainsOnlySelectedTurnIDsNotTranscriptText() async {
        var session = await MemoryAskConversationPolicy().startSession(for: MemoryDeck.planets[4])
        let firstTurn = session.suggestedTurns[0]

        let response = session.respond(to: .suggestedTurn(id: firstTurn.id))

        #expect(response.kind == .answer)
        #expect(session.selectedTurnIDs == [firstTurn.id])
        #expect(String(describing: session.selectedTurnIDs).contains(firstTurn.answer) == false)
        #expect(Mirror(reflecting: session).children.map { $0.label ?? "" }.contains("transcript") == false)
    }

    @MainActor
    @Test func suggestedTurnSelectionReturnsOnlyTheChosenCardAnswer() async {
        var session = await MemoryAskConversationPolicy().startSession(for: MemoryDeck.planets[4])
        let jupiterSizeTurn = session.suggestedTurns.first { $0.id == "size" }!

        let response = session.respond(to: .suggestedTurn(id: jupiterSizeTurn.id))

        #expect(response.kind == .answer)
        #expect(response.spokenText == jupiterSizeTurn.answer)
        #expect(response.spokenText.localizedCaseInsensitiveContains("Jupiter"))
        #expect(response.spokenText.localizedCaseInsensitiveContains("139,820 km"))
        #expect(session.selectedTurnIDs == ["size"])
    }

    @MainActor
    @Test func policyDoesNotPermitUnrestrictedChatOrMicrophoneInput() {
        #expect(MemoryAskConversationPolicy.allowsMicrophoneInput == false)
        #expect(MemoryAskConversationPolicy.allowsFreeformTextInput == false)
        #expect(MemoryAskConversationPolicy.supportedInputModes == [.suggestedTurnSelection])
    }
}
