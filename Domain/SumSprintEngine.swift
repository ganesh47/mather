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
    private(set) var showTimeoutFeedback: Bool = false
    private(set) var completedSummary: SumSprintSessionSummary? = nil
    private(set) var phase: SumSprintPhase = .idle
    private(set) var difficulty: SumSprintDifficulty = .relaxed

    /// Countdown seconds remaining for the current card.  0 when no timer is active.
    private(set) var cardTimeRemaining: Double = 0

    // MARK: - Dependencies

    private let featureFlags: FeatureFlagService
    private let telemetryWriter: TelemetryWriter
    private let speechService: SpeechService
    private let hapticsService: HapticsService
    let factStore: FactRecordStore
    let feedbackDuration: TimeInterval

    // MARK: - Session tracking

    private var sessionId: UUID = UUID()
    private var sessionStartedAt: Date = .now
    private var cardStartedAt: Date = .now
    private var seenFactKeys: Set<String> = []
    private var timerTask: Task<Void, Never>? = nil
    private var feedbackTask: Task<Void, Never>? = nil
    /// Cards queued to re-appear at end (Sprint mode only — timed-out cards).
    private var requeuedCardFacts: [ArithmeticFact] = []

    // MARK: - Callback

    var onExitToHome: (@MainActor () -> Void)?
    var onSessionComplete: (@MainActor (SumSprintSessionSummary) -> Void)?

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

    func showDifficultyPick() {
        phase = .difficultyPick
    }

    func selectDifficulty(_ d: SumSprintDifficulty) {
        difficulty = d
        startSession()
    }

    func startSession() {
        timerTask?.cancel()
        timerTask = nil
        feedbackTask?.cancel()
        feedbackTask = nil
        sessionId = UUID()
        sessionStartedAt = .now
        seenFactKeys = []
        requeuedCardFacts = []
        currentCardIndex = 0
        currentStreak = 0
        peakStreak = 0
        showCorrectFeedback = false
        showIncorrectFeedback = false
        showTimeoutFeedback = false
        completedSummary = nil

        let records = factStore.fetchAll()
        let facts = SumSprintGenerator.generateSession(
            allRecords: records,
            cardCount: difficulty.cardCount
        )
        cards = facts.map { SumSprintCard(id: UUID(), fact: $0) }

        phase = .session

        logEvent(.sumSprintStarted, payload: [
            "session_id": sessionId.uuidString,
            "card_count": String(cards.count),
            "difficulty": difficulty.rawValue
        ])

        speechService.speak("Let's practice! What's the sum?", enabled: featureFlags.audioEnabled)
        showCurrentCard()
    }

    func exitToHome() {
        timerTask?.cancel()
        timerTask = nil
        feedbackTask?.cancel()
        feedbackTask = nil
        phase = .idle
        onExitToHome?()
    }

    // MARK: - Card interaction

    func appendDigit(_ digit: Int) {
        guard phase == .session, currentCardIndex < cards.count else { return }
        let current = cards[currentCardIndex].typedAnswer
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
            // Record elapsed time
            cards[currentCardIndex].elapsedSeconds = Date().timeIntervalSince(cardStartedAt)
            handleCorrect(isFirstTry: isFirstTry)
        } else {
            handleIncorrect()
        }
    }

    /// Test-only hook for driving near-timeout scenarios without exposing the
    /// countdown setter publicly in production code.
    func setCardTimeRemainingForTests(_ seconds: Double) {
        cardTimeRemaining = seconds
    }

    // MARK: - Private: card display

    private func showCurrentCard() {
        cardStartedAt = .now
        startCardTimer()
        guard currentCardIndex < cards.count else { return }
        let card = cards[currentCardIndex]
        logEvent(.sumSprintCardShown, payload: [
            "card_index": String(currentCardIndex),
            "fact_key": card.fact.factKey,
            "sum": String(card.fact.sum)
        ])
    }

    // MARK: - Private: answer handling

    private func handleCorrect(isFirstTry: Bool) {
        timerTask?.cancel()
        timerTask = nil
        resetFeedbackState()
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

        if currentStreak > 0 && currentStreak % 3 == 0 {
            hapticsService.bondMatchComplete(enabled: featureFlags.hapticsEnabled)
            speechService.speak("\(currentStreak) in a row!", enabled: featureFlags.audioEnabled)
        }

        applyLeitnerUpdate(factKey: card.fact.factKey, correct: true, firstTry: isFirstTry)

        showCorrectFeedback = true
        feedbackTask = Task { @MainActor [weak self] in
            guard let self else { return }
            if self.feedbackDuration > 0 {
                try? await Task.sleep(for: .seconds(self.feedbackDuration))
            }
            guard !Task.isCancelled else { return }
            self.showCorrectFeedback = false
            self.feedbackTask = nil
            self.advanceCard()
        }
    }

    private func handleIncorrect() {
        timerTask?.cancel()
        timerTask = nil
        resetFeedbackState()
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
        feedbackTask = Task { @MainActor [weak self] in
            guard let self else { return }
            if self.feedbackDuration > 0 {
                try? await Task.sleep(for: .seconds(self.feedbackDuration * 0.5))
            }
            guard !Task.isCancelled else { return }
            self.showIncorrectFeedback = false
            self.feedbackTask = nil
        }
    }

    private func handleTimeout() {
        guard phase == .session, currentCardIndex < cards.count else { return }
        timerTask?.cancel()
        timerTask = nil
        resetFeedbackState()
        cardTimeRemaining = 0

        let card = cards[currentCardIndex]
        cards[currentCardIndex].timedOut = true
        cards[currentCardIndex].result = .incorrect(attempts: cards[currentCardIndex].attemptCount + 1)
        cards[currentCardIndex].typedAnswer = ""
        currentStreak = 0

        logEvent(.sumSprintCardAnswered, payload: [
            "fact_key": card.fact.factKey,
            "correct": "false",
            "timed_out": "true",
            "streak": "0"
        ])

        hapticsService.cardSnapMismatch(enabled: featureFlags.hapticsEnabled)
        speechService.speak("Time's up!", enabled: featureFlags.audioEnabled)

        applyLeitnerUpdate(factKey: card.fact.factKey, correct: false, firstTry: false)

        // Sprint: re-queue the timed-out card at the end
        if difficulty == .sprint {
            requeuedCardFacts.append(card.fact)
        }

        seenFactKeys.insert(card.fact.factKey)

        showTimeoutFeedback = true
        feedbackTask = Task { @MainActor [weak self] in
            guard let self else { return }
            if self.feedbackDuration > 0 {
                try? await Task.sleep(for: .seconds(self.feedbackDuration))
            }
            guard !Task.isCancelled else { return }
            self.showTimeoutFeedback = false
            self.feedbackTask = nil
            self.advanceCard()
        }
    }

    private func resetFeedbackState() {
        feedbackTask?.cancel()
        feedbackTask = nil
        showCorrectFeedback = false
        showIncorrectFeedback = false
        showTimeoutFeedback = false
    }

    // MARK: - Private: card advancement

    private func advanceCard() {
        let nextIndex = currentCardIndex + 1
        if nextIndex >= cards.count {
            // Sprint: append any re-queued timed-out cards once
            if difficulty == .sprint && !requeuedCardFacts.isEmpty {
                let extra = requeuedCardFacts.map { SumSprintCard(id: UUID(), fact: $0) }
                cards.append(contentsOf: extra)
                requeuedCardFacts = []
            }
            if nextIndex >= cards.count {
                finishSession()
                return
            }
        }
        currentCardIndex = nextIndex
        showCurrentCard()
    }

    private func finishSession() {
        timerTask?.cancel()
        timerTask = nil
        feedbackTask?.cancel()
        feedbackTask = nil
        cardTimeRemaining = 0
        factStore.incrementSessionCounts(excludingKeys: seenFactKeys)

        let summary = SumSprintSessionSummary(
            sessionId: sessionId,
            startedAt: sessionStartedAt,
            endedAt: .now,
            cards: cards,
            peakStreak: peakStreak,
            difficulty: difficulty
        )
        completedSummary = summary
        phase = .summary
        onSessionComplete?(summary)

        logEvent(.sumSprintCompleted, payload: [
            "session_id": sessionId.uuidString,
            "cards_completed": String(cards.count),
            "peak_streak": String(peakStreak),
            "first_try_accuracy": String(format: "%.2f", summary.firstTryAccuracy),
            "timeout_count": String(summary.timeoutCount),
            "difficulty": difficulty.rawValue
        ])
    }

    // MARK: - Private: countdown timer

    private func startCardTimer() {
        timerTask?.cancel()
        timerTask = nil
        guard let secs = difficulty.secondsPerCard else {
            cardTimeRemaining = 0
            return
        }
        let cardID = cards.indices.contains(currentCardIndex) ? cards[currentCardIndex].id : nil
        cardTimeRemaining = secs
        timerTask = Task { @MainActor [weak self] in
            while !Task.isCancelled {
                guard let self else { break }
                try? await Task.sleep(nanoseconds: 100_000_000)  // 0.1 s tick
                guard !Task.isCancelled else { break }
                guard self.phase == .session, self.cards.indices.contains(self.currentCardIndex) else { break }
                guard self.cards[self.currentCardIndex].id == cardID else { break }
                self.cardTimeRemaining = max(0, self.cardTimeRemaining - 0.1)
                if self.cardTimeRemaining <= 0 {
                    self.handleTimeout()
                    break
                }
            }
        }
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
