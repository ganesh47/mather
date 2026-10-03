import Testing
@testable import Mather

@MainActor
@Suite("Memory selection safety")
struct MemorySelectionSafetyTests {
    @Test func enrichedAnimalsAndMachinesExposeDiscoveryInDetailsAndReadAloud() throws {
        let service = MemoryCardDescribeService(appleIntelligenceEnabled: { false })
        let cow = try #require(MemoryDeck.domesticAnimals.first { $0.id == "cow" })
        let excavator = try #require(MemoryDeck.vehicles.first { $0.id == "excavator" })
        for (animal, selection) in [(cow, MemoryView.DeckSelection.domestic), (excavator, .vehicles)] {
            let description = service.fallbackDescription(for: animal)
            let content = MemoryView.learningContent(for: animal, deckSelection: selection, description: description)
            for title in ["Look closely", "Try it"] {
                let discovery = try #require(animal.detailCards.first { $0.title == title })
                #expect(content.factChips.contains(discovery))
                #expect(content.readAloudText.contains(discovery.value))
            }
        }
    }

    @Test func geographyDescriptionsKeepPassportOrder() {
        let service = MemoryCardDescribeService(appleIntelligenceEnabled: { false })
        let country = MemoryDeck.countries[0]
        #expect(service.fallbackDescription(for: country).factChips.map(\.title) == [
            "Country", "Capital", "Language", "Currency", "Currency Symbol", "Continent", "Map Shape", "Monument"
        ])
    }

    @Test func concealedCardsDoNotSpeakAndHintedCardsExposeOnlyVisibleContent() {
        let animal = MemoryDeck.domesticAnimals[0]
        let concealed = MemoryCard(pairId: animal.id, content: .picture(animal))
        #expect(MemoryView.selectionSpeech(for: concealed, difficulty: .hard) == nil)
        #expect(MemoryView.accessibilityLabel(for: concealed, difficulty: .hard) == "Face down memory card")
        let hinted = MemoryView.displayedCard(concealed, hinted: true)
        #expect(!MemoryView.learningCardModel(for: hinted, difficulty: .hard, isIncorrect: false).isFaceDown)
        #expect(MemoryView.accessibilityLabel(for: hinted, difficulty: .hard).contains(animal.canonicalName))
        #expect(!MemoryView.displayedCard(concealed, hinted: false).isSelected)
    }

    @Test func countryQuizCluesSpeakTheClueWhileNameCardsSpeakTheAnswer() {
        let country = MemoryDeck.countryFlags[0]
        for kind in CountryMemoryClueKind.allCases {
            let transformed = MemoryView.countryClueAnimal(for: country, clueKind: kind)
            let picture = MemoryCard(pairId: transformed.id, content: .picture(transformed), isSelected: true)
            let label = MemoryCard(pairId: transformed.id, content: .label(transformed), isSelected: true)
            #expect(MemoryView.selectionSpeech(for: picture, difficulty: .hard) == MemoryView.accessibilityLabel(for: picture))
            #expect(MemoryView.selectionSpeech(for: picture, difficulty: .hard) != country.canonicalName)
            #expect(MemoryView.selectionSpeech(for: label, difficulty: .hard) == country.canonicalName)
            #expect(MemoryView.learningCardModel(for: label, difficulty: .hard, isIncorrect: false).display == .text(country.canonicalName))
        }
    }

    @Test func textPromptSpeaksDisplayedContent() {
        let animal = MemoryDeck.numberBondsTo10[0]
        let card = MemoryCard(pairId: animal.id, content: .picture(animal), isSelected: true)
        if case .text(let text) = animal.picture {
            #expect(MemoryView.selectionSpeech(for: card, difficulty: .hard) == text)
            #expect(MemoryView.selectionSpeech(for: card, difficulty: .hard) != animal.canonicalName)
        } else {
            Issue.record("Number bonds must present a sum prompt")
        }
    }
}
