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

    @Test func vehicleRoundsSampleAcrossTheCompleteExpandedDeck() {
        let deck = MemoryGalleryTVCategory.vehicles.deck
        let rounds = (0..<MemoryGalleryTVGame.roundsPerGame).map {
            MemoryGalleryTVRound.make(category: .vehicles, index: $0)
        }
        let expectedStride = (deck.count + MemoryGalleryTVGame.roundsPerGame - 1)
            / MemoryGalleryTVGame.roundsPerGame
        let expectedIDs = (0..<MemoryGalleryTVGame.roundsPerGame).map {
            deck[($0 * expectedStride) % deck.count].id
        }

        #expect(rounds.map(\.promptCard.id) == expectedIDs)
        #expect(Set(rounds.map(\.promptCard.id)).count == MemoryGalleryTVGame.roundsPerGame)
    }

    @Test func vehiclePartRoundsUseSpecificPromptsAndRevealRichFacts() {
        let part = MemoryAnimal(
            id: "test-engine",
            name: "Engine",
            picture: .text("Engine"),
            metadata: MemoryCardMetadata(
                deck: .vehicles,
                category: "vehicle part",
                kind: "vehicle part",
                use: "turns fuel into power",
                movement: "moves pistons up and down",
                factCards: [
                    MemoryFactCard(title: "Kind", value: "vehicle part"),
                    MemoryFactCard(title: "Job", value: "Makes power"),
                    MemoryFactCard(title: "Look For", value: "Pistons and cylinders")
                ]
            )
        )
        let round = MemoryGalleryTVRound(
            category: .vehicles,
            index: 0,
            promptCard: part,
            answerChoices: [part]
        )

        #expect(round.isVehiclePartPrompt)
        #expect(round.promptTitle == "Vehicle part")
        #expect(round.choicePrompt == "Which vehicle part is this?")
        #expect(round.learningFacts.map(\.title) == ["Job", "Look For"])
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

@Suite("MemoryGalleryTVGame")
struct MemoryGalleryTVGameTests {
    @Test func gameStartsWithFreshSixRoundSession() throws {
        var game = MemoryGalleryTVGame()

        game.start(category: .animals)

        #expect(game.phase == .playing)
        #expect(game.category == .animals)
        #expect(game.progressText == "Picture 1 of 6")
        #expect(game.correctCount == 0)
        #expect(game.streak == 0)
        #expect(try #require(game.round).category == .animals)
    }

    @Test func correctAndIncorrectAnswersUpdateScoreAndStreakOnce() throws {
        var game = MemoryGalleryTVGame()
        game.start(category: .vehicles)
        let firstRound = try #require(game.round)

        let firstWasCorrect = game.select(answerID: firstRound.correctAnswerID)
        #expect(firstWasCorrect)
        #expect(game.progressText == "Picture 1 of 6")
        #expect(game.correctCount == 1)
        #expect(game.streak == 1)
        #expect(game.bestStreak == 1)
        let duplicateSelectionWasAccepted = game.select(answerID: firstRound.correctAnswerID)
        #expect(!duplicateSelectionWasAccepted)
        #expect(game.correctCount == 1)

        game.advance()
        #expect(game.progressText == "Picture 2 of 6")
        let secondRound = try #require(game.round)
        let wrongAnswer = try #require(secondRound.answerChoices.first { $0.id != secondRound.correctAnswerID })
        let secondWasCorrect = game.select(answerID: wrongAnswer.id)
        #expect(!secondWasCorrect)
        #expect(game.correctCount == 1)
        #expect(game.streak == 0)
        #expect(game.bestStreak == 1)
    }

    @Test func sixthAnswerAdvancesToCompletedCelebration() throws {
        var game = MemoryGalleryTVGame()
        game.start(category: .planets)

        for index in 0..<MemoryGalleryTVGame.roundsPerGame {
            let round = try #require(game.round)
            let wasCorrect = game.select(answerID: round.correctAnswerID)
            #expect(wasCorrect)
            #expect(game.completedRoundCount == index + 1)
            game.advance()
        }

        #expect(game.phase == .completed)
        #expect(game.correctCount == MemoryGalleryTVGame.roundsPerGame)
        #expect(game.bestStreak == MemoryGalleryTVGame.roundsPerGame)
        #expect(game.progressText == "6 pictures complete")
        #expect(game.round == nil)
    }

    @Test func replayAndGalleryChoiceResetAllSessionState() throws {
        var game = MemoryGalleryTVGame()
        game.start(category: .flags)
        let round = try #require(game.round)
        game.select(answerID: round.correctAnswerID)

        game.replay()

        #expect(game.phase == .playing)
        #expect(game.category == .flags)
        #expect(game.completedRoundCount == 0)
        #expect(game.correctCount == 0)
        #expect(game.roundIndex == 0)

        game.chooseAnotherCategory()

        #expect(game.phase == .choosingCategory)
        #expect(game.category == nil)
        #expect(game.correctCount == 0)
    }
}
