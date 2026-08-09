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
        let roundGoal = MemoryGalleryTVGame.roundGoal(for: .vehicles)
        let rounds = (0..<roundGoal).map {
            MemoryGalleryTVRound.make(category: .vehicles, index: $0)
        }
        let expectedIDs = (0..<roundGoal).map {
            deck[$0 * deck.count / roundGoal].id
        }

        #expect(rounds.map(\.promptCard.id) == expectedIDs)
        #expect(Set(rounds.map(\.promptCard.id)).count == roundGoal)
    }

    @Test func thirtyCountryRoundsCoverTheDeckBeforeRepeating() {
        let deck = MemoryGalleryTVCategory.flags.deck
        let roundGoal = MemoryGalleryTVGame.roundGoal(for: .flags)
        let rounds = (0..<roundGoal).map {
            MemoryGalleryTVRound.make(category: .flags, index: $0)
        }
        let expectedIDs = (0..<roundGoal).map {
            deck[$0 % deck.count].id
        }

        #expect(rounds.map(\.promptCard.id) == expectedIDs)
        #expect(Set(rounds.prefix(deck.count).map(\.promptCard.id)).count == deck.count)
        #expect(rounds.count == 30)
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
        let round = MemoryGalleryTVRound.make(category: .flags, index: 2)

        #expect(round.category.title == "Countries")
        #expect(round.category.subtitle == "Flags, money & landmarks")
        #expect(round.promptTitle == "Country flag")
        #expect(round.choicePrompt == "Which country has this flag?")
        #expect(round.promptCard.metadata.deck == .countryFlags)
        #expect(round.promptCard.canonicalName == round.promptCard.name)
        #expect(round.answerChoices.allSatisfy { $0.metadata.deck == .countryFlags })
    }

    @Test func countryGameWeightsThirtyQuestionsTowardLandmarksAndMoney() {
        let rounds = (0..<MemoryGalleryTVGame.countryRoundGoal).map {
            MemoryGalleryTVRound.make(category: .flags, index: $0)
        }

        #expect(Array(rounds.prefix(10).map(\.countryPromptKind)) == [
            .monument, .currency, .flag, .monument, .currency,
            .capital, .monument, .currency, .officialLanguage, .flag
        ])
        #expect(rounds.filter { $0.countryPromptKind == .monument }.count == 9)
        #expect(rounds.filter { $0.countryPromptKind == .currency }.count == 9)
        #expect(rounds.filter { $0.countryPromptKind == .flag }.count == 6)
        #expect(rounds.filter { $0.countryPromptKind == .capital }.count == 3)
        #expect(rounds.filter { $0.countryPromptKind == .officialLanguage }.count == 3)

        guard case .asset(let monumentAsset) = rounds[0].promptPicture else {
            Issue.record("Expected a monument image prompt")
            return
        }
        guard case .asset(let currencyAsset) = rounds[1].promptPicture else {
            Issue.record("Expected a currency image prompt")
            return
        }
        guard case .text(let capital) = rounds[5].promptPicture else {
            Issue.record("Expected a capital-name prompt")
            return
        }
        guard case .text(let language) = rounds[8].promptPicture else {
            Issue.record("Expected an official-language prompt")
            return
        }

        #expect(monumentAsset.hasPrefix("MemoryMonument"))
        #expect(currencyAsset.hasPrefix("MemoryCurrency"))
        #expect(capital == rounds[5].promptCard.detailCards.first { $0.title == "Capital" }?.value)
        #expect(language == rounds[8].promptCard.detailCards.first { $0.title == "Language" }?.value)
    }

    @Test func countryChallengeAnswersRemainCountryNamesAndAvoidDuplicateClues() {
        for index in 0..<MemoryGalleryTVGame.countryRoundGoal {
            let round = MemoryGalleryTVRound.make(category: .flags, index: index)
            #expect(round.answerChoices.count == MemoryGalleryTVRound.choiceCount)
            #expect(round.answerChoices.contains { $0.id == round.correctAnswerID })
            #expect(round.answerChoices.allSatisfy { $0.name == $0.canonicalName })

            let clueTitle: String?
            switch round.countryPromptKind {
            case .currency: clueTitle = "Currency"
            case .capital: clueTitle = "Capital"
            case .officialLanguage: clueTitle = "Language"
            case .monument: clueTitle = "Monument"
            case .flag, nil: clueTitle = nil
            }
            if let clueTitle {
                let clues = round.answerChoices.compactMap { card in
                    card.detailCards.first { $0.title == clueTitle }?.value
                }
                #expect(Set(clues).count == clues.count)
            }
        }
    }

    @Test func countryRevealPrioritizesACompactPassportOfRichFacts() {
        let country = MemoryAnimal(
            id: "test-country",
            name: "Testland",
            picture: .text("Flag"),
            metadata: MemoryCardMetadata(
                deck: .countryFlags,
                category: "country flag",
                kind: "country flag",
                factCards: [
                    MemoryFactCard(title: "Country", value: "Testland"),
                    MemoryFactCard(title: "Colors", value: "blue and gold"),
                    MemoryFactCard(title: "Monument", value: "Sky Tower"),
                    MemoryFactCard(title: "Currency", value: "Star coin ★"),
                    MemoryFactCard(title: "Official Language", value: "Testish"),
                    MemoryFactCard(title: "Capital", value: "Test City")
                ]
            )
        )
        let round = MemoryGalleryTVRound(
            category: .flags,
            index: 0,
            promptCard: country,
            answerChoices: [country]
        )

        #expect(round.learningFacts.map(\.title) == [
            "Capital", "Official Language", "Currency", "Monument"
        ])
    }
}

@Suite("MemoryGalleryTVGame")
struct MemoryGalleryTVGameTests {
    @Test func standardGalleryStartsWithFreshSixRoundSession() throws {
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

        for index in 0..<MemoryGalleryTVGame.standardRoundGoal {
            let round = try #require(game.round)
            let wasCorrect = game.select(answerID: round.correctAnswerID)
            #expect(wasCorrect)
            #expect(game.completedRoundCount == index + 1)
            game.advance()
        }

        #expect(game.phase == .completed)
        #expect(game.correctCount == MemoryGalleryTVGame.standardRoundGoal)
        #expect(game.bestStreak == MemoryGalleryTVGame.standardRoundGoal)
        #expect(game.progressText == "6 pictures complete")
        #expect(game.round == nil)
    }

    @Test func countryGalleryCompletesAfterThirtyQuestions() throws {
        var game = MemoryGalleryTVGame()
        game.start(category: .flags)

        #expect(game.roundGoal == 30)
        #expect(game.progressText == "Question 1 of 30")

        for index in 0..<MemoryGalleryTVGame.countryRoundGoal {
            let round = try #require(game.round)
            let wasCorrect = game.select(answerID: round.correctAnswerID)
            #expect(wasCorrect)
            #expect(game.completedRoundCount == index + 1)
            game.advance()
        }

        #expect(game.phase == .completed)
        #expect(game.correctCount == 30)
        #expect(game.progressText == "30 questions complete")
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
