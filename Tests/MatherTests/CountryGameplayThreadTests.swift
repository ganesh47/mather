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
        ])
        #expect(Set(thread.propertyTypes.map(\.id)).isSuperset(of: requiredPropertyTypeIDs))

        for entity in thread.entities {
            let propertyTypeIDs = Set(entity.properties.map(\.typeID))
            #expect(propertyTypeIDs.isSuperset(of: requiredPropertyTypeIDs), "\(entity.name) is missing a required country property")
            #expect(entity.visualAssetName?.hasPrefix("MemoryFlag") == true)
            #expect(entity.properties.first { $0.typeID == "flag" }?.visualAssetName == entity.visualAssetName)
            #expect(!(entity.properties.first { $0.typeID == "map-shape" }?.value.isEmpty ?? true))
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
    }

    @Test
    func countryStageRoundsUseReusableStageModels() throws {
        let thread = CountryGameplayThread.thread

        let flashcards = try round(kind: .flashcards, thread: thread)
        #expect(flashcards.items.count == 8)
        #expect(flashcards.items.allSatisfy { $0.propertyID == nil })
        #expect(GameplayStageContentBuilder.flashcards(thread: thread, round: flashcards).count == 8)

        let easy = try round(kind: .easyMemory, thread: thread)
        #expect(!easy.items.isEmpty)
        #expect(easy.items.allSatisfy { ["flag", "capital", "continent"].contains($0.propertyTypeID ?? "") })
        #expect(!GameplayStageContentBuilder.matchPairs(thread: thread, round: easy).isEmpty)

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
    @MainActor
    func countryCardsLaunchesCountriesGameplayThreadDirectly() {
        #expect(LabActivityID.countryCards.appRoute == .gameplayThread(.countries))

        let engine = makeEngine()
        engine.showCountriesGameplayThread()
        #expect(engine.route == .gameplayThread("countries"))
    }

    private func expectCountry(
        _ entity: GameplayEntity?,
        capital: String,
        currency: String,
        continent: String,
        language: String,
        flagAsset: String
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
