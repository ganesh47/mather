import Foundation
import Testing
@testable import Mather

struct CountryGameplayThreadTests {
    private let requiredPropertyTypeIDs: Set<String> = ["capital", "currency", "flag", "map-shape", "continent", "language", "clue"]

    @Test
    func countriesThreadMigratesAllCurrentCountryCardsWithRequiredProperties() throws {
        let thread = CountryGameplayThread.thread

        #expect(thread.id == "countries")
        #expect(thread.title == "Country Cards")
        #expect(thread.stages.map(\.kind) == [.flashcards, .easyMemory, .flipMemory, .bondBlast, .multipleChoice])
        #expect(thread.entities.map(\.id) == [
            "country-india",
            "country-japan",
            "country-france",
            "country-egypt",
            "country-brazil",
            "country-australia",
            "country-canada",
            "country-kenya",
            "country-united-states",
            "country-united-kingdom",
            "country-china",
            "country-germany",
            "country-mexico",
            "country-south-africa",
            "country-italy",
            "country-saudi-arabia",
        ])
        #expect(thread.entities.count >= 16)
        let representedContinents = Set(thread.entities.compactMap { $0.properties.first { $0.typeID == "continent" }?.value })
        #expect(representedContinents.isSuperset(of: ["Asia", "Europe", "Africa", "North America", "South America", "Australia"]))
        #expect(Set(thread.propertyTypes.map(\.id)).isSuperset(of: requiredPropertyTypeIDs))

        for entity in thread.entities {
            let propertyTypeIDs = Set(entity.properties.map(\.typeID))
            #expect(propertyTypeIDs.isSuperset(of: requiredPropertyTypeIDs), "\(entity.name) is missing a required country property")
            #expect(entity.visualKey?.isEmpty == false)
            #expect(entity.visualAssetName == nil || entity.visualAssetName?.hasPrefix("MemoryFlag") == true)
            #expect(entity.properties.first { $0.typeID == "flag" }?.visualAssetName == entity.visualAssetName)
            #expect(!(entity.properties.first { $0.typeID == "map-shape" }?.value.isEmpty ?? true))
            #expect(entity.properties.first { $0.typeID == "map-shape" }?.visualShapeKey == entity.id)
        }
    }

    @Test
    func specificCountryFactsMatchCurrentMemoryInventory() throws {
        let entities = Dictionary(uniqueKeysWithValues: CountryGameplayThread.thread.entities.map { ($0.id, $0) })

        try expectCountry(entities["country-india"], capital: "New Delhi", currency: "Indian rupee", continent: "Asia", language: "Hindi and English", flagAsset: "MemoryFlagIndia")
        try expectCountry(entities["country-japan"], capital: "Tokyo", currency: "yen", continent: "Asia", language: "Japanese", flagAsset: "MemoryFlagJapan")
        try expectCountry(entities["country-france"], capital: "Paris", currency: "euro", continent: "Europe", language: "French", flagAsset: "MemoryFlagFrance")
        try expectCountry(entities["country-egypt"], capital: "Cairo", currency: "Egyptian pound", continent: "Africa", language: "Arabic", flagAsset: "MemoryFlagEgypt")
        try expectCountry(entities["country-brazil"], capital: "Brasília", currency: "Brazilian real", continent: "South America", language: "Portuguese", flagAsset: "MemoryFlagBrazil")
        try expectCountry(entities["country-australia"], capital: "Canberra", currency: "Australian dollar", continent: "Australia", language: "English", flagAsset: "MemoryFlagAustralia")
        try expectCountry(entities["country-canada"], capital: "Ottawa", currency: "Canadian dollar", continent: "North America", language: "English and French", flagAsset: "MemoryFlagCanada")
        try expectCountry(entities["country-kenya"], capital: "Nairobi", currency: "Kenyan shilling", continent: "Africa", language: "Swahili and English", flagAsset: "MemoryFlagKenya")
        try expectCountry(entities["country-united-states"], capital: "Washington, D.C.", currency: "United States dollar", continent: "North America", language: "English", flagAsset: nil)
        try expectCountry(entities["country-united-kingdom"], capital: "London", currency: "pound sterling", continent: "Europe", language: "English", flagAsset: nil)
        try expectCountry(entities["country-china"], capital: "Beijing", currency: "Chinese yuan", continent: "Asia", language: "Mandarin Chinese", flagAsset: nil)
        try expectCountry(entities["country-germany"], capital: "Berlin", currency: "euro", continent: "Europe", language: "German", flagAsset: nil)
        try expectCountry(entities["country-mexico"], capital: "Mexico City", currency: "Mexican peso", continent: "North America", language: "Spanish", flagAsset: nil)
        try expectCountry(entities["country-south-africa"], capital: "Pretoria", currency: "South African rand", continent: "Africa", language: "Zulu, Xhosa, Afrikaans, English, and more", flagAsset: nil)
        try expectCountry(entities["country-italy"], capital: "Rome", currency: "euro", continent: "Europe", language: "Italian", flagAsset: nil)
        try expectCountry(entities["country-saudi-arabia"], capital: "Riyadh", currency: "Saudi riyal", continent: "Asia", language: "Arabic", flagAsset: nil)
    }

    @Test
    func countryStageRoundsUseReusableStageModels() throws {
        let thread = CountryGameplayThread.thread

        let flashcards = try round(kind: .flashcards, thread: thread)
        #expect(flashcards.items.count == 8)
        #expect(thread.entities.count > flashcards.items.count)
        #expect(flashcards.items.allSatisfy { $0.propertyID == nil })
        #expect(GameplayStageContentBuilder.flashcards(thread: thread, round: flashcards).count == 8)

        let easy = try round(kind: .easyMemory, thread: thread)
        #expect(!easy.items.isEmpty)
        #expect(easy.items.allSatisfy { $0.propertyTypeID == "flag" })
        let easyPairs = GameplayStageContentBuilder.matchPairs(thread: thread, round: easy)
        #expect(!easyPairs.isEmpty)
        #expect(easyPairs.allSatisfy { $0.left.presentation == .visualOnly })
        #expect(easyPairs.allSatisfy { $0.right.presentation == .titleOnly })

        let flip = try round(kind: .flipMemory, thread: thread)
        #expect(flip.items.allSatisfy { ["flag", "capital", "currency"].contains($0.propertyTypeID ?? "") })

        let bondBlast = try round(kind: .bondBlast, thread: thread)
        #expect(bondBlast.items.count == 10)
        #expect(bondBlast.items.allSatisfy { ["capital", "currency", "continent", "language", "map-shape"].contains($0.propertyTypeID ?? "") })

        let quiz = try round(kind: .multipleChoice, thread: thread)
        let questions = GameplayStageContentBuilder.multipleChoiceQuestions(thread: thread, round: quiz)
        #expect(!questions.isEmpty)
        #expect(questions.allSatisfy { $0.choices.contains($0.answer) })
    }

    @Test
    func countryEasyMemoryStartsWithDeterministicFlagNameRoundWithoutDuplicateVisibleAnswers() throws {
        let thread = CountryGameplayThread.thread
        let stage = try #require(thread.stages.first { $0.kind == .easyMemory })
        #expect(stage.propertyTypeIDs == ["flag"])
        #expect(stage.prompt.localizedCaseInsensitiveContains("country name"))
        #expect(stage.prompt.localizedCaseInsensitiveContains("flag"))

        let round = SpacedRepetitionScheduler.makeRound(thread: thread, stage: stage, seed: 912)
        let pairs = GameplayStageContentBuilder.matchPairs(thread: thread, round: round)

        #expect(round.items.count == min(stage.maximumItemCount, thread.entities.count))
        #expect(round.items.allSatisfy { $0.propertyTypeID == "flag" })
        #expect(pairs.allSatisfy { $0.left.title == "Name this flag" })
        #expect(pairs.allSatisfy { $0.left.presentation == .visualOnly })
        #expect(pairs.allSatisfy { $0.left.visualAssetName != nil || $0.left.visualKey != nil })
        #expect(pairs.allSatisfy { pair in thread.entities.contains { $0.id == pair.right.entityID && $0.name == pair.right.title } })
        #expect(pairs.allSatisfy { $0.right.subtitle == "Country name" })
        #expect(pairs.allSatisfy { $0.right.presentation == .titleOnly })
        #expect(pairs.allSatisfy { $0.right.visualKey == nil && $0.right.visualAssetName == nil })
        #expect(Set(pairs.map { $0.right.title.lowercased() }).count == pairs.count)
    }


    @Test
    func countryContinentQuizDoesNotRepeatVisibleAnswerLabels() throws {
        let thread = CountryGameplayThread.thread
        let selectedIDs = ["country-kenya", "country-egypt", "country-canada", "country-india"]
        let items = try selectedIDs.map { entityID in
            let entity = try #require(thread.entities.first { $0.id == entityID })
            let continent = try #require(entity.properties.first { $0.typeID == "continent" })
            return GameplayRoundItem(
                id: "quiz-\(entityID)-continent",
                entityID: entityID,
                propertyID: continent.id,
                propertyTypeID: continent.typeID
            )
        }
        let round = GameplayRoundDefinition(
            id: "country-continent-duplicates",
            stageID: "multiple-choice",
            kind: .multipleChoice,
            items: items,
            seed: 95
        )

        let questions = GameplayStageContentBuilder.multipleChoiceQuestions(thread: thread, round: round, choicesPerQuestion: 4)
        let kenyaQuestion = try #require(questions.first { $0.answer.entityID == "country-kenya" })

        #expect(kenyaQuestion.prompt == "Which one matches Kenya?")
        #expect(kenyaQuestion.answer.title == "Africa")
        #expect(kenyaQuestion.choices.map(\.title).filter { $0 == "Africa" }.count == 1)
        #expect(questions.allSatisfy { question in
            Set(question.choices.map { $0.title.lowercased() }).count == question.choices.count
        })
    }

    @Test
    func mapShapeQuizItemsCarryDrawableShapeKeys() throws {
        let thread = CountryGameplayThread.thread
        let stage = try #require(thread.stages.first { $0.kind == .multipleChoice })
        let round = SpacedRepetitionScheduler.makeRound(thread: thread, stage: stage, seed: 18)
        let questions = GameplayStageContentBuilder.multipleChoiceQuestions(thread: thread, round: round)
        let mapShapeAnswers = questions.map(\.answer).filter { $0.subtitle == "Map Shape" }

        #expect(!mapShapeAnswers.isEmpty)
        #expect(mapShapeAnswers.allSatisfy { $0.visualShapeKey == $0.entityID })
        #expect(mapShapeAnswers.allSatisfy { $0.visualAssetName == nil })
    }

    @Test
    @MainActor
    func countryCardsLaunchesCountriesGameplayThreadDirectly() {
        #expect(LabActivityID.countryCards.appRoute == .gameplayThread(.countries))

        let engine = makeEngine()
        engine.showCountriesGameplayThread()
        #expect(engine.route == .gameplayThread(.countries))
    }

    private func expectCountry(
        _ entity: GameplayEntity?,
        capital: String,
        currency: String,
        continent: String,
        language: String,
        flagAsset: String?
    ) throws {
        let entity = try #require(entity)
        #expect(entity.visualAssetName == flagAsset)
        #expect(entity.properties.first { $0.typeID == "capital" }?.value == capital)
        #expect(entity.properties.first { $0.typeID == "currency" }?.value == currency)
        #expect(entity.properties.first { $0.typeID == "continent" }?.value == continent)
        #expect(entity.properties.first { $0.typeID == "language" }?.value == language)
        #expect(entity.properties.first { $0.typeID == "flag" }?.visualAssetName == flagAsset)
    }

    private func round(kind: GameplayStageKind, thread: GameplayThreadDefinition) throws -> GameplayRoundDefinition {
        let stage = try #require(thread.stages.first { $0.kind == kind })
        return SpacedRepetitionScheduler.makeRound(thread: thread, stage: stage, seed: 912)
    }

    @MainActor
    private func makeEngine() -> VerticalSliceEngine {
        let flags = FeatureFlagService(defaults: UserDefaults(suiteName: "CountryGameplayThreadTests")!)
        flags.testModeEnabled = true
        flags.audioEnabled = false
        return VerticalSliceEngine(
            featureFlags: flags,
            telemetryWriter: TelemetryWriter(),
            speechService: SpeechService(),
            celebrationDuration: 0,
            saveSummary: { _ in }
        )
    }
}
