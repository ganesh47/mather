import Foundation
import Testing
import SwiftData
@testable import Mather

@MainActor
struct SumSprintEngineTests {

    // MARK: - Helpers

    private func makeEngine(feedbackDuration: TimeInterval = 0) throws -> (SumSprintEngine, FeatureFlagService) {
        let flags = FeatureFlagService(defaults: UserDefaults(suiteName: #function)!)
        flags.sumSprintEnabled = true
        flags.audioEnabled = false
        flags.hapticsEnabled = false

        let schema = Schema([StoredFactRecord.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: config)
        let store = FactRecordStore(modelContext: ModelContext(container))

        let engine = SumSprintEngine(
            featureFlags: flags,
            telemetryWriter: TelemetryWriter(),
            speechService: SpeechService(),
            factStore: store,
            feedbackDuration: feedbackDuration
        )
        return (engine, flags)
    }

    // MARK: - Session start

    @Test
    func startSessionPopulates10Cards() throws {
        let (engine, _) = try makeEngine()
        engine.startSession()
        #expect(engine.cards.count == 10)
    }

    @Test
    func startSessionSetsPhaseToSession() throws {
        let (engine, _) = try makeEngine()
        engine.startSession()
        #expect(engine.phase == .session)
    }

    @Test
    func startSessionResetsStreak() throws {
        let (engine, _) = try makeEngine()
        engine.startSession()
        #expect(engine.currentStreak == 0)
        #expect(engine.peakStreak == 0)
    }

    // MARK: - Digit input

    @Test
    func appendDigitUpdatesTypedAnswer() throws {
        let (engine, _) = try makeEngine()
        engine.startSession()
        engine.appendDigit(7)
        #expect(engine.cards[0].typedAnswer == "7")
    }

    @Test
    func appendDigitCapsAtTwoDigits() throws {
        let (engine, _) = try makeEngine()
        engine.startSession()
        engine.appendDigit(1)
        engine.appendDigit(2)
        engine.appendDigit(3) // should be ignored
        #expect(engine.cards[0].typedAnswer == "12")
    }

    @Test
    func deleteLastDigitRemovesCharacter() throws {
        let (engine, _) = try makeEngine()
        engine.startSession()
        engine.appendDigit(1)
        engine.appendDigit(5)
        engine.deleteLastDigit()
        #expect(engine.cards[0].typedAnswer == "1")
    }

    @Test
    func deleteLastDigitOnEmptyAnswerIsNoop() throws {
        let (engine, _) = try makeEngine()
        engine.startSession()
        engine.deleteLastDigit()
        #expect(engine.cards[0].typedAnswer == "")
    }

    // MARK: - Submit answer

    @Test
    func correctAnswerFirstTryAdvancesCardIndex() async throws {
        let (engine, _) = try makeEngine()
        engine.startSession()
        let fact = engine.cards[0].fact
        let sumStr = String(fact.sum)
        for ch in sumStr { engine.appendDigit(Int(String(ch))!) }
        engine.submitAnswer()
        // Wait for async feedback task to complete (feedbackDuration = 0)
        try await Task.sleep(for: .milliseconds(50))
        #expect(engine.currentCardIndex == 1)
    }

    @Test
    func incorrectAnswerResetsStreak() async throws {
        let (engine, _) = try makeEngine()
        engine.startSession()
        // Answer first card correctly
        let fact0 = engine.cards[0].fact
        for ch in String(fact0.sum) { engine.appendDigit(Int(String(ch))!) }
        engine.submitAnswer()
        try await Task.sleep(for: .milliseconds(50))
        #expect(engine.currentStreak == 1)

        // Answer second card incorrectly (enter wrong number)
        engine.appendDigit(1)
        engine.submitAnswer()
        #expect(engine.currentStreak == 0)
    }

    @Test
    func consecutiveCorrectFirstTryIncrementsStreak() async throws {
        let (engine, _) = try makeEngine()
        engine.startSession()

        for i in 0..<3 {
            let fact = engine.cards[i].fact
            for ch in String(fact.sum) { engine.appendDigit(Int(String(ch))!) }
            engine.submitAnswer()
            try await Task.sleep(for: .milliseconds(50))
        }
        #expect(engine.currentStreak == 3)
        #expect(engine.peakStreak == 3)
    }

    @Test
    func peakStreakRetainsMaxAfterReset() async throws {
        let (engine, _) = try makeEngine()
        engine.startSession()

        // Build streak of 3
        for i in 0..<3 {
            let fact = engine.cards[i].fact
            for ch in String(fact.sum) { engine.appendDigit(Int(String(ch))!) }
            engine.submitAnswer()
            try await Task.sleep(for: .milliseconds(50))
        }

        // Wrong answer on card 4
        engine.appendDigit(1)
        engine.submitAnswer()

        #expect(engine.currentStreak == 0)
        #expect(engine.peakStreak == 3)
    }

    // MARK: - Leitner box transitions

    @Test
    func correctFirstTryPromotesBox0ToBox1() async throws {
        let (engine, _) = try makeEngine()
        engine.startSession()

        let fact = engine.cards[0].fact
        for ch in String(fact.sum) { engine.appendDigit(Int(String(ch))!) }
        engine.submitAnswer()
        try await Task.sleep(for: .milliseconds(50))

        let record = engine.factStore.record(forKey: fact.factKey)
        #expect(record != nil)
        #expect(record?.boxRawValue == LeitnerBox.box1.rawValue)
    }

    @Test
    func correctFirstTryPromotesBox1ToBox2() async throws {
        let (engine, _) = try makeEngine()
        engine.startSession()

        // Pre-seed the first card's fact in box1
        let fact = engine.cards[0].fact
        engine.factStore.upsert(factKey: fact.factKey) { record in
            record.boxRawValue = LeitnerBox.box1.rawValue
        }

        for ch in String(fact.sum) { engine.appendDigit(Int(String(ch))!) }
        engine.submitAnswer()
        try await Task.sleep(for: .milliseconds(50))

        let record = engine.factStore.record(forKey: fact.factKey)
        #expect(record?.boxRawValue == LeitnerBox.box2.rawValue)
    }

    @Test
    func incorrectAnswerDemotesBox1ToBox0() throws {
        let (engine, _) = try makeEngine()
        engine.startSession()

        let fact = engine.cards[0].fact
        engine.factStore.upsert(factKey: fact.factKey) { record in
            record.boxRawValue = LeitnerBox.box1.rawValue
        }

        // Enter wrong answer
        engine.appendDigit(1)
        engine.submitAnswer()

        let record = engine.factStore.record(forKey: fact.factKey)
        #expect(record?.boxRawValue == LeitnerBox.box0.rawValue)
    }

    @Test
    func incorrectAnswerDemotesBox2ToBox0() throws {
        let (engine, _) = try makeEngine()
        engine.startSession()

        let fact = engine.cards[0].fact
        engine.factStore.upsert(factKey: fact.factKey) { record in
            record.boxRawValue = LeitnerBox.box2.rawValue
        }

        engine.appendDigit(1)
        engine.submitAnswer()

        let record = engine.factStore.record(forKey: fact.factKey)
        #expect(record?.boxRawValue == LeitnerBox.box0.rawValue)
    }

    @Test
    func incorrectAnswerClearsTypedAnswer() throws {
        let (engine, _) = try makeEngine()
        engine.startSession()
        engine.appendDigit(1)
        engine.submitAnswer() // wrong (sum is 11–20, entered "1")
        #expect(engine.cards[0].typedAnswer == "")
    }

    // MARK: - Session completion

    @Test
    func allCardsAnsweredTransitionsToSummaryPhase() async throws {
        let (engine, _) = try makeEngine()
        engine.startSession()

        for i in 0..<engine.cards.count {
            let fact = engine.cards[i].fact
            for ch in String(fact.sum) { engine.appendDigit(Int(String(ch))!) }
            engine.submitAnswer()
            try await Task.sleep(for: .milliseconds(50))
        }

        #expect(engine.phase == .summary)
        #expect(engine.completedSummary != nil)
    }

    @Test
    func completedSummaryHasCorrectCardCount() async throws {
        let (engine, _) = try makeEngine()
        engine.startSession()

        for i in 0..<engine.cards.count {
            let fact = engine.cards[i].fact
            for ch in String(fact.sum) { engine.appendDigit(Int(String(ch))!) }
            engine.submitAnswer()
            try await Task.sleep(for: .milliseconds(50))
        }

        #expect(engine.completedSummary?.cards.count == 10)
    }

    // MARK: - Navigation

    @Test
    func exitToHomeCallsCallback() throws {
        let (engine, _) = try makeEngine()
        var callbackFired = false
        engine.onExitToHome = { callbackFired = true }
        engine.exitToHome()
        #expect(callbackFired == true)
        #expect(engine.phase == .idle)
    }

    // MARK: - Feature flag

    @Test
    func sumSprintEnabledDefaultsFalse() {
        let flags = FeatureFlagService(defaults: UserDefaults(suiteName: #function)!)
        #expect(flags.sumSprintEnabled == false)
    }

    // MARK: - Cards contain valid sums

    @Test
    func allCardsHaveSumsIn11To20() throws {
        let (engine, _) = try makeEngine()
        engine.startSession()
        for card in engine.cards {
            #expect(card.fact.sum >= 11)
            #expect(card.fact.sum <= 20)
        }
    }
}
