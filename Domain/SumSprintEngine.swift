import Foundation
import Observation

@MainActor
@Observable
final class SumSprintEngine {

    // MARK: - Published state

    private(set) var cards: [SumSprintCard] = []
    private(set) var currentCardIndex: Int = 0
    private(set) var currentStreak: Int = 0
    private(set) var peakStreak: Int = 0
    private(set) var showCorrectFeedback: Bool = false
    private(set) var showIncorrectFeedback: Bool = false
    private(set) var completedSummary: SumSprintSessionSummary? = nil
    private(set) var phase: SumSprintPhase = .idle

    // MARK: - Dependencies

    private let featureFlags: FeatureFlagService
    private let telemetryWriter: TelemetryWriter
    private let speechService: SpeechService
    private let hapticsService: HapticsService
    // Internal so @testable import tests can verify Leitner state directly
    let factStore: FactRecordStore
    let feedbackDuration: TimeInterval

    // MARK: - Session tracking

    private var sessionId: UUID = UUID()
    private var sessionStartedAt: Date = .now
    private var seenFactKeys: Set<String> = []

    // MARK: - Callback

    var onExitToHome: (@MainActor () -> Void)?

    // MARK: - Init

    init(
        featureFlags: FeatureFlagService,
        telemetryWriter: TelemetryWriter,
        speechService: SpeechService,
        hapticsService: HapticsService = HapticsService(),
        factStore: FactRecordStore,
        feedbackDuration: TimeInterval = 0.6
    ) {
        self.featureFlags = featureFlags
        self.telemetryWriter = telemetryWriter
        self.speechService = speechService
        self.hapticsService = hapticsService
        self.factStore = factStore
        self.feedbackDuration = feedbackDuration
    }

    // MARK: - Navigation

    func startSession() {
        sessionId = UUID()
        sessionStartedAt = .now
        seenFactKeys = []
        currentCardIndex = 0
        currentStreak = 0
        peakStreak = 0
        showCorrectFeedback = false
        showIncorrectFeedback = false
        completedSummary = nil

        let records = factStore.fetchAll()
        let facts = SumSprintGenerator.generateSession(allRecords: records)
        cards = facts.map { SumSprintCard(id: UUID(), fact: $0) }

        phase = .session

        logEvent(.sumSprintStarted, payload: [
            "session_id": sessionId.uuidString,
            "card_count": String(cards.count)
        ])

        speechService.speak("Let's practice! What's the sum?", enabled: featureFlags.audioEnabled)
        showCurrentCard()
    }

    func exitToHome() {
        phase = .idle
        onExitToHome?()
    }

    // MARK: - Card interaction

    func appendDigit(_ digit: Int) {
        guard phase == .session, currentCardIndex < cards.count else { return }
        let current = cards[currentCardIndex].typedAnswer
        // Max 2 digits: sums are at most 20
        guard current.count < 2 else { return }
        cards[currentCardIndex].typedAnswer = current + String(digit)
    }

    func deleteLastDigit() {
        guard phase == .session, currentCardIndex < cards.count else { return }
        let current = cards[currentCardIndex].typedAnswer
        guard !current.isEmpty else { return }
        cards[currentCardIndex].typedAnswer = String(current.dropLast())
    }

    func submitAnswer() {
        guard phase == .session, currentCardIndex < cards.count else { return }
        let card = cards[currentCardIndex]
        guard let entered = Int(card.typedAnswer) else { return }

        let isCorrect = entered == card.fact.sum
        cards[currentCardIndex].attemptCount += 1
        let isFirstTry = cards[currentCardIndex].attemptCount == 1

        seenFactKeys.insert(card.fact.factKey)

        if isCorrect {
            handleCorrect(isFirstTry: isFirstTry)
        } else {
            handleIncorrect()
        }
    }

    // MARK: - Private

    private func showCurrentCard() {
        guard currentCardIndex < cards.count else { return }
        let card = cards[currentCardIndex]
        logEvent(.sumSprintCardShown, payload: [
            "card_index": String(currentCardIndex),
            "fact_key": card.fact.factKey,
            "sum": String(card.fact.sum)
        ])
    }

    private func handleCorrect(isFirstTry: Bool) {
        let card = cards[currentCardIndex]
        cards[currentCardIndex].result = .correct(firstTry: isFirstTry)

        currentStreak += 1
        peakStreak = max(peakStreak, currentStreak)

        logEvent(.sumSprintCardAnswered, payload: [
            "fact_key": card.fact.factKey,
            "correct": "true",
            "first_try": String(isFirstTry),
            "streak": String(currentStreak)
        ])

        hapticsService.cardSnapCorrect(enabled: featureFlags.hapticsEnabled)

        // Streak milestone every 3
        if currentStreak > 0 && currentStreak % 3 == 0 {
            hapticsService.bondMatchComplete(enabled: featureFlags.hapticsEnabled)
            speechService.speak("\(currentStreak) in a row!", enabled: featureFlags.audioEnabled)
        }

        applyLeitnerUpdate(factKey: card.fact.factKey, correct: true, firstTry: isFirstTry)

        showCorrectFeedback = true
        Task { @MainActor in
            if feedbackDuration > 0 {
                try? await Task.sleep(for: .seconds(feedbackDuration))
            }
            showCorrectFeedback = false
            advanceCard()
        }
    }

    private func handleIncorrect() {
        let card = cards[currentCardIndex]
        let attempts = cards[currentCardIndex].attemptCount
        cards[currentCardIndex].result = .incorrect(attempts: attempts)
        cards[currentCardIndex].typedAnswer = ""

        currentStreak = 0

        logEvent(.sumSprintCardAnswered, payload: [
            "fact_key": card.fact.factKey,
            "correct": "false",
            "attempts": String(attempts),
            "streak": "0"
        ])

        hapticsService.cardSnapMismatch(enabled: featureFlags.hapticsEnabled)
        speechService.speak("Try again!", enabled: featureFlags.audioEnabled)

        applyLeitnerUpdate(factKey: card.fact.factKey, correct: false, firstTry: false)

        showIncorrectFeedback = true
        Task { @MainActor in
            if feedbackDuration > 0 {
                try? await Task.sleep(for: .seconds(feedbackDuration * 0.5))
            }
            showIncorrectFeedback = false
        }
    }

    private func advanceCard() {
        let nextIndex = currentCardIndex + 1
        if nextIndex >= cards.count {
            finishSession()
        } else {
            currentCardIndex = nextIndex
            showCurrentCard()
        }
    }

    private func finishSession() {
        factStore.incrementSessionCounts(excludingKeys: seenFactKeys)

        let summary = SumSprintSessionSummary(
            sessionId: sessionId,
            startedAt: sessionStartedAt,
            endedAt: .now,
            cards: cards,
            peakStreak: peakStreak
        )
        completedSummary = summary
        phase = .summary

        logEvent(.sumSprintCompleted, payload: [
            "session_id": sessionId.uuidString,
            "cards_completed": String(cards.count),
            "peak_streak": String(peakStreak),
            "first_try_accuracy": String(format: "%.2f", summary.firstTryAccuracy)
        ])
    }

    // MARK: - Leitner updates

    private func applyLeitnerUpdate(factKey: String, correct: Bool, firstTry: Bool) {
        factStore.upsert(factKey: factKey) { record in
            record.lastSeenAt = .now
            record.sessionsSinceLastSeen = 0

            let currentBox = LeitnerBox(rawValue: record.boxRawValue) ?? .box0

            if correct && firstTry {
                record.correctStreak += 1
                switch currentBox {
                case .box0: record.boxRawValue = LeitnerBox.box1.rawValue
                case .box1: record.boxRawValue = LeitnerBox.box2.rawValue
                case .box2: break
                }
            } else if !correct {
                record.correctStreak = 0
                record.boxRawValue = LeitnerBox.box0.rawValue
            }
        }
    }

    // MARK: - Telemetry

    private func logEvent(_ type: SliceEventType, payload: [String: String]) {
        try? telemetryWriter.append(
            SliceEvent(type: type, payload: payload)
        )
    }
}
