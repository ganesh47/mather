import Foundation
import Testing
#if os(tvOS)
@testable import MatherTV
#else
@testable import Mather
#endif

@MainActor
struct WorldQuestTests {
    @Test func bundledCatalogHasCompleteRosterAndUsableGeometry() throws {
        // Application resources belong to the host app, not the test bundle.
        let catalog = try CountryCatalog.load()
        #expect(catalog.countries.count == 195)
        #expect(catalog.starterIDs.count == 12)
        #expect(catalog.boundaryViewpoint == "India")
        #expect(catalog.country("VAT")?.name == "Vatican City")
        #expect(catalog.country("PSX")?.name == "Palestine")
        #expect(catalog.country("TWN") == nil)
        #expect(catalog.country("RUS")?.continent == .europe)
        #expect(catalog.country("TUR")?.continent == .asia)
        #expect(catalog.features.contains { $0.id == "GRL" })
        #expect(catalog.features.contains { feature in
            feature.rings.count > 1 && feature.id == "FJI"
        })
        #expect(throws: (any Error).self) { try CountryCatalog.decode(Data("{}".utf8)) }
    }

    @Test func everyCountryCanReachEveryOtherCountryInEveryPack() throws {
        let catalog = try CountryCatalog.load()
        for pack in WorldQuestPack.allCases {
            let countries = catalog.countries(in: pack)
            let navigation = WorldQuestNavigation(countries: countries, aspectRatio: catalog.aspectRatio)
            let ids = Set(countries.map(\.id))
            for country in countries {
                #expect(navigation.reachable(from: country.id) == ids, "\(pack): \(country.id)")
            }
        }
    }

    @Test func deterministicQuestionsAndNeutralNavigation() throws {
        let catalog = try CountryCatalog.load()
        let first = WorldQuestEngine(catalog: catalog)
        let second = WorldQuestEngine(catalog: catalog)
        first.start(pack: .starter, mode: .practice, seed: 42)
        second.start(pack: .starter, mode: .practice, seed: 42)
        #expect(first.questions == second.questions)
        #expect(Set(first.questions).count == 10)
        #expect(Set(first.questions).isSubset(of: Set(catalog.starterIDs)))
        second.start(pack: .starter, mode: .practice, seed: 91)
        #expect(first.questions != second.questions)
        #expect(first.selectableCountries == second.selectableCountries)
    }

    @Test func timerWaitsForSpeechAndPreservesTimeAcrossInterruptions() throws {
        let catalog = try CountryCatalog.load()
        var now = 100.0
        let engine = WorldQuestEngine(catalog: catalog, now: { now })
        engine.start(pack: .starter, mode: .timed, seed: 42)
        now += 40
        engine.tick()
        #expect(engine.remainingSeconds == 20)
        engine.resume(.narration)
        now += 5
        engine.tick()
        #expect(engine.remainingSeconds == 15)
        engine.suspend(.narration)
        engine.suspend(.interruption)
        now += 50
        engine.resume(.narration)
        engine.tick()
        #expect(engine.remainingSeconds == 15)
        #expect(engine.needsResume)
        #expect(!engine.submit(countryID: try #require(engine.target).id))
        engine.resume(.interruption)
        now += 14.9
        engine.tick()
        #expect(engine.phase == .answering)
        now += 0.1
        engine.tick()
        #expect(engine.phase == .feedback)
        #expect(engine.answers.last?.outcome == .revealed)
        #expect(engine.answers.last?.seconds == 20)
    }

    @Test func deadlineWinsOverSubmissionAndCannotDoubleComplete() throws {
        let catalog = try CountryCatalog.load()
        var now = 0.0
        let engine = WorldQuestEngine(catalog: catalog, now: { now })
        engine.start(pack: .starter, mode: .timed, seed: 12)
        engine.resume(.narration)
        let target = try #require(engine.target)
        now = 20
        #expect(!engine.submit(countryID: target.id))
        engine.reveal()
        engine.tick()
        #expect(engine.answers.count == 1)
        #expect(engine.answers[0].outcome == .revealed)
        engine.advance()
        #expect(engine.questionIndex == 1)
        #expect(engine.remainingSeconds == 20)
        #expect(engine.isSuspended)
    }

    @Test func wrongAnswersRetryAndHintsMarkAssistance() throws {
        let catalog = try CountryCatalog.load()
        let engine = WorldQuestEngine(catalog: catalog)
        engine.start(pack: .starter, mode: .practice, seed: 42)
        engine.resume(.narration)
        let target = try #require(engine.target)
        let wrong = try #require(engine.selectableCountries.first { $0.id != target.id })
        #expect(!engine.submit(countryID: "invalid"))
        #expect(engine.attempts == 0)
        #expect(!engine.submit(countryID: wrong.id))
        #expect(engine.phase == .answering)
        #expect(engine.attempts == 1)
        engine.hint()
        #expect(engine.hintContinent == target.continent)
        #expect(engine.submit(countryID: target.id))
        #expect(engine.answers.last?.outcome == .assisted)
        #expect(engine.answers.last?.attempts == 2)
        #expect(!engine.submit(countryID: target.id))
        #expect(engine.answers.count == 1)
    }

    @Test func practiceNeverExpiresAndExplorationDoesNotCreateQuizProgress() throws {
        var now = 0.0
        let engine = WorldQuestEngine(catalog: try CountryCatalog.load(), now: { now })
        engine.start(pack: .oceania, mode: .practice, seed: 9)
        engine.resume(.narration)
        now = 1000
        engine.tick()
        #expect(engine.phase == .answering)
        #expect(engine.submit(countryID: try #require(engine.target).id))
        engine.start(pack: .world, mode: .explore, seed: 9)
        #expect(engine.phase == .exploring)
        #expect(engine.questions.isEmpty)
        #expect(engine.answers.isEmpty)
        #expect(engine.completion == nil)
        #expect(!engine.submit(countryID: "IND"))
    }

    @Test func completedSessionIsRecordedOnceAndCorruptStorageRecovers() throws {
        let suite = "worldQuest.tests.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        defaults.set(Data("broken".utf8), forKey: WorldQuestProgressStore.storageKey)
        let store = WorldQuestProgressStore(defaults: defaults)
        #expect(store.progress.sessions.isEmpty)
        let engine = WorldQuestEngine(catalog: try CountryCatalog.load(), now: { 0 })
        engine.start(pack: .starter, mode: .timed, seed: 42)
        for index in 0..<10 {
            engine.resume(.narration)
            if index == 0 { engine.reveal() }
            else {
                if index == 1 { engine.hint() }
                #expect(engine.submit(countryID: try #require(engine.target).id))
            }
            engine.advance()
        }
        let session = try #require(engine.completion)
        #expect(engine.phase == .completed)
        #expect(session.answers.count == 10)
        #expect(session.independentCount == 8)
        #expect(session.assistedCount == 1)
        #expect(session.revealedCount == 1)
        #expect(session.firstTryCount == 8)
        #expect(session.meanSuccessfulSeconds == 0)
        store.record(session)
        store.record(session)
        #expect(store.progress.sessions.count == 1)
        #expect(store.progress.countryStamps.count == 9)
        let restored = WorldQuestProgressStore(defaults: defaults)
        #expect(restored.progress.countryStamps == store.progress.countryStamps)
        restored.record(session)
        #expect(restored.progress.sessions.count == 1)
        engine.returnToSetup()
        #expect(engine.completion == nil)
    }
}
