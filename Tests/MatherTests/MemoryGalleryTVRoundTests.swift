import Testing
@testable import Mather

@Suite("MemoryGalleryTVRound")
struct MemoryGalleryTVRoundTests {
    @Test func categoriesMapToPlayableSharedMemoryDecks() {
        #expect(MemoryGalleryTVCategory.allCases.map(\.deckKind) == [
            .domesticAnimals,
            .vehicles,
            .planets,
            .countryFlags
        ])

        for category in MemoryGalleryTVCategory.allCases {
            #expect(category.deck.count >= MemoryGalleryTVRound.choiceCount)
        }
    }

    @Test func roundIncludesPromptAsOneOfFourAnswerChoices() {
        let round = MemoryGalleryTVRound.make(category: .vehicles, index: 2)

        #expect(round.answerChoices.count == 4)
        #expect(Set(round.answerChoices.map(\.id)).count == 4)
        #expect(round.answerChoices.map(\.id).contains(round.correctAnswerID))
        #expect(MemoryGalleryTVRound.isCorrect(selectionID: round.promptCard.id, for: round))
    }

    @Test func roundIndexWrapsAcrossDeckBounds() {
        let deckCount = MemoryGalleryTVCategory.planets.deck.count
        let wrapped = MemoryGalleryTVRound.make(category: .planets, index: deckCount + 1)
        let expected = MemoryGalleryTVCategory.planets.deck[1]

        #expect(wrapped.promptCard.id == expected.id)
    }

    @Test func flagRoundsUseCountryNamesForAnswers() {
        let round = MemoryGalleryTVRound.make(category: .flags, index: 0)

        #expect(round.promptCard.metadata.deck == .countryFlags)
        #expect(round.promptCard.canonicalName == round.promptCard.name)
        #expect(round.answerChoices.allSatisfy { $0.metadata.deck == .countryFlags })
    }
}
