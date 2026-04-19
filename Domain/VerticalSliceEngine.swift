import Foundation
import Observation

enum AppRoute {
    case home
    case sessionConfig
    case session
    case sessionSummary
    case parentSummary
    case settings
    case roomQuest
    case sumSprint
    case symmetryFold
    case rectangleFactory
    case angleCannon
    case twoFingerProtractor
    case gravityArtist
    case compassAngles
    case lab
}

@MainActor
@Observable
final class VerticalSliceEngine {
    private(set) var route: AppRoute = .home
    private(set) var config = SliceConfig()
    private(set) var problems: [SliceProblem] = []
    private(set) var currentProblemIndex = 0
    private(set) var currentSession = SliceSession(sessionId: UUID(), startedAt: .now, endedAt: nil, problems: [], schemaVersion: TelemetryWriter.schemaVersion)
    private(set) var currentStage: SliceStage = .concrete
    private(set) var currentProblemState = ProblemState()
    private var sessionStartedAt: Date = .now
    private var problemStartedAt: Date = .now
    private let sessionTimeLimitSeconds: TimeInterval = 7 * 60

    var concreteWarmCount = 0
    var concreteAccentCount = 0
    var splitLeftCount = 0
    var equationLeftInput = ""
    var equationRightInput = ""
    var transferLeftCount = 0
    var transferRightCount = 0
    private(set) var bondMatchState: BondMatchState? = nil
    private(set) var gravitySplitState: GravitySplitState? = nil
    private(set) var sumSprintBurstState: SumSprintBurstState? = nil
    /// Recorded on the first tilt sample after the stage becomes active.
    /// All subsequent tilt is computed as a delta from this neutral position,
    /// so the puzzle cannot be accidentally solved by simply picking up the device.
    private var gravitySplitNeutralRoll: Double? = nil
    var feedbackMessage = "Tap Play to start."
    var showCelebration = false
    var completedSummary: SessionSummaryDraft?

    private let telemetryWriter: TelemetryWriter
    private let featureFlags: FeatureFlagService
    private let speechService: SpeechService
    private let hapticsService: HapticsService
    private let saveSummary: (SessionSummaryDraft) -> Void
    // Injected so unit tests can pass 0 to skip the animation delay.
    let celebrationDuration: TimeInterval
    // Frozen at startSession(); never changes mid-session.
    // Unit tests can inject any SliceTheme to verify prompt routing.
    private(set) var activeTheme: any SliceTheme
    // When a custom theme is injected at init time, startSession() preserves it
    // instead of resolving from featureFlags. This lets unit tests use arbitrary
    // theme implementations (e.g. RocketTheme) without registering them in flags.
    private let hasInjectedTheme: Bool
    // Per-problem theme rotation for VehicleTheme — one spec per problem, cycling
    // through VehicleSpec.pool. Empty for ClassicTheme or injected-theme sessions.
    private var problemThemes: [any SliceTheme] = []

    init(
        featureFlags: FeatureFlagService,
        telemetryWriter: TelemetryWriter,
        speechService: SpeechService,
        hapticsService: HapticsService = HapticsService(),
        activeTheme: (any SliceTheme)? = nil,
        celebrationDuration: TimeInterval = 1.5,
        saveSummary: @escaping (SessionSummaryDraft) -> Void
    ) {
        self.featureFlags = featureFlags
        self.telemetryWriter = telemetryWriter
        self.speechService = speechService
        self.hapticsService = hapticsService
        self.hasInjectedTheme = activeTheme != nil
        self.activeTheme = activeTheme ?? ClassicTheme()
        self.celebrationDuration = celebrationDuration
        self.saveSummary = saveSummary
    }

    var currentProblem: SliceProblem? {
        guard problems.indices.contains(currentProblemIndex) else { return nil }
        return problems[currentProblemIndex]
    }

    var progressLabel: String {
        guard !problems.isEmpty else { return "0 / 0" }
        return "\(min(currentProblemIndex + 1, problems.count)) / \(problems.count)"
    }

    var exportArtifact: ExportArtifact? {
        telemetryWriter.currentExport
    }

    var concreteCount: Int { concreteWarmCount + concreteAccentCount }

    func showSettings() { route = .settings }
    func showHome() { route = .home }
    func showParentSummary() { route = .parentSummary }
    func showSessionConfig() { route = .sessionConfig }
    func showRoomQuest() { route = .roomQuest }
    func showSumSprint() { route = .sumSprint }
    func showSymmetryFold() { route = .symmetryFold }
    func showRectangleFactory() { route = .rectangleFactory }
    func showAngleCannon() { route = .angleCannon }
    func showTwoFingerProtractor() { route = .twoFingerProtractor }
    func showGravityArtist() { route = .gravityArtist }
    func showCompassAngles() { route = .compassAngles }
    func showLab() { route = .lab }

    func startSession() {
        // Freeze the active theme from the user's current selection — unless a custom
        // theme was injected at init time (e.g. in unit tests using an arbitrary theme).
        if !hasInjectedTheme {
            if featureFlags.selectedThemeId == "vehicle" {
                config.audioEnabled = featureFlags.audioEnabled
                config.deterministicMode = featureFlags.testModeEnabled
                problems = ProblemGenerator.generateProblems(config: config)
                let pool = VehicleSpec.pool
                problemThemes = problems.indices.map { i in VehicleTheme(spec: pool[i % pool.count]) }
                activeTheme = problemThemes[0]
            } else {
                activeTheme = ClassicTheme()
                problemThemes = []
                config.audioEnabled = featureFlags.audioEnabled
                config.deterministicMode = featureFlags.testModeEnabled
                problems = ProblemGenerator.generateProblems(config: config)
            }
        } else {
            problemThemes = []
            config.audioEnabled = featureFlags.audioEnabled
            config.deterministicMode = featureFlags.testModeEnabled
            problems = ProblemGenerator.generateProblems(config: config)
        }
        currentProblemIndex = 0
        currentStage = .concrete
        currentProblemState = ProblemState()
        currentSession = SliceSession(
            sessionId: UUID(),
            startedAt: .now,
            endedAt: nil,
            problems: [],
            schemaVersion: TelemetryWriter.schemaVersion
        )
        concreteWarmCount = 0
        concreteAccentCount = 0
        splitLeftCount = 0
        equationLeftInput = ""
        equationRightInput = ""
        transferLeftCount = 0
        transferRightCount = 0
        bondMatchState = nil
        gravitySplitState = nil
        sumSprintBurstState = nil
        gravitySplitNeutralRoll = nil
        feedbackMessage = activeTheme.sessionStartFeedback()
        showCelebration = false
        completedSummary = nil
        sessionStartedAt = .now
        problemStartedAt = .now
        speechService.resetSession()
        speechService.speakSessionIntro(activeTheme.sessionIntroPhrase())

        do {
            try telemetryWriter.beginSession(sessionId: currentSession.sessionId, featureFlags: featureFlags)
            logProblemPresented()
        } catch {
            feedbackMessage = "Telemetry setup failed, but play can continue."
        }
        route = .session
    }

    func updateConfig(problemCount: Int? = nil, audioEnabled: Bool? = nil) {
        if let problemCount { config.maxProblems = problemCount }
        if let audioEnabled { config.audioEnabled = audioEnabled }
    }

    func adjustConcrete(by delta: Int) {
        setConcreteTotal(concreteCount + delta)
    }

    func adjustConcrete(by delta: Int, side: ConcreteGroup) {
        guard let currentProblem else { return }
        switch side {
        case .warm:
            let maxWarm = min(5, max(currentProblem.target - concreteAccentCount, 0))
            concreteWarmCount = min(max(concreteWarmCount + delta, 0), maxWarm)
            recordInteraction(action: "place_warm", value: concreteWarmCount)
        case .accent:
            let maxAccent = min(5, max(currentProblem.target - concreteWarmCount, 0))
            concreteAccentCount = min(max(concreteAccentCount + delta, 0), maxAccent)
            recordInteraction(action: "place_accent", value: concreteAccentCount)
        }
        #if targetEnvironment(simulator)
        print("[Mather][concrete] warm=\(concreteWarmCount) accent=\(concreteAccentCount) total=\(concreteCount) target=\(currentProblem.target)")
        #endif
    }

    func moveSplit(delta: Int) {
        guard let currentProblem else { return }
        splitLeftCount = min(max(splitLeftCount + delta, 0), currentProblem.target)
        recordInteraction(action: "split", value: splitLeftCount)
        #if targetEnvironment(simulator)
        print("[Mather][split] left=\(splitLeftCount) right=\(currentProblem.target - splitLeftCount)")
        #endif
    }

    func appendEquationDigit(_ digit: Int, side: EquationSide) {
        switch side {
        case .left:
            equationLeftInput = appendDigit(to: equationLeftInput, digit: digit)
        case .right:
            equationRightInput = appendDigit(to: equationRightInput, digit: digit)
        }
        recordInteraction(action: "select", value: digit)
    }

    func clearEquation(side: EquationSide) {
        switch side {
        case .left: equationLeftInput = ""
        case .right: equationRightInput = ""
        }
    }

    var transferCount: Int { transferLeftCount + transferRightCount }

    func adjustTransfer(by delta: Int, side: TransferSide) {
        guard let currentProblem else { return }
        switch side {
        case .left:
            transferLeftCount = min(max(transferLeftCount + delta, 0), currentProblem.target)
            recordInteraction(action: "transfer_left_place", value: transferLeftCount)
        case .right:
            transferRightCount = min(max(transferRightCount + delta, 0), currentProblem.target)
            recordInteraction(action: "transfer_right_place", value: transferRightCount)
        }
    }

    func submitCurrentStage() {
        guard let currentProblem else { return }
        // Guard: ignore taps while celebration is playing — stage hasn't advanced yet
        // and a second submit would register as an erroneous attempt.
        guard !showCelebration else { return }
        currentProblemState.attempts += 1

        let isCorrect: Bool
        switch currentStage {
        case .concrete:
            isCorrect = concreteCount == currentProblem.target
        case .pictorial:
            isCorrect = splitLeftCount + (currentProblem.target - splitLeftCount) == currentProblem.target
        case .abstract:
            isCorrect = validateEquation(for: currentProblem)
        case .transfer:
            isCorrect = transferLeftCount == currentProblem.decompositionA
                && transferRightCount == currentProblem.decompositionB
        case .gravitySplit:
            isCorrect = gravitySplitState?.isLocked == true
        case .sumSprint:
            isCorrect = sumSprintBurstState?.isComplete == true
        case .bondMatch:
            // Bond Blast is not submitted via submitCurrentStage — pairs are matched
            // individually via matchPair(id:). This case is unreachable in practice.
            isCorrect = bondMatchState?.isComplete == true
        case .done:
            isCorrect = true
        }

        currentProblemState.isCorrect = isCorrect
        if isCorrect {
            completeStage(successMessage: successMessage(for: currentStage, problem: currentProblem))
        } else {
            feedbackMessage = feedbackMessageForFailure(stage: currentStage, problem: currentProblem)
            speechService.speak(feedbackMessage, enabled: featureFlags.audioEnabled)
            hapticsService.failure(enabled: featureFlags.hapticsEnabled)
        }
    }

    func replayPrompt() {
        speechService.speak(promptForCurrentStage(), enabled: featureFlags.audioEnabled)
    }

    func appendSumSprintDigit(_ digit: Int) {
        guard currentStage == .sumSprint, var state = sumSprintBurstState,
              state.cards.indices.contains(state.currentCardIndex) else { return }
        let current = state.cards[state.currentCardIndex].typedAnswer
        guard current.count < 2 else { return }
        state.cards[state.currentCardIndex].typedAnswer = current + String(digit)
        sumSprintBurstState = state
    }

    func deleteSumSprintDigit() {
        guard currentStage == .sumSprint, var state = sumSprintBurstState,
              state.cards.indices.contains(state.currentCardIndex) else { return }
        let current = state.cards[state.currentCardIndex].typedAnswer
        guard !current.isEmpty else { return }
        state.cards[state.currentCardIndex].typedAnswer = String(current.dropLast())
        sumSprintBurstState = state
    }

    func submitSumSprintCard() {
        guard currentStage == .sumSprint, var state = sumSprintBurstState,
              state.cards.indices.contains(state.currentCardIndex) else { return }
        guard let entered = Int(state.cards[state.currentCardIndex].typedAnswer) else { return }
        let card = state.cards[state.currentCardIndex]
        let isCorrect = entered == card.answer
        recordInteraction(action: "sum_sprint_submit", value: entered)

        if isCorrect {
            state.cards[state.currentCardIndex].isCorrect = true
            try? telemetryWriter.append(
                SliceEvent(type: .sumSprintCardAnswered, payload: [
                    "problem_id": currentProblem?.id.uuidString ?? "",
                    "card_index": String(state.currentCardIndex),
                    "prompt": card.prompt,
                    "correct": "true"
                ])
            )
            state.currentCardIndex += 1
            sumSprintBurstState = state
            if state.isComplete, let problem = currentProblem {
                completeStage(successMessage: successMessage(for: .sumSprint, problem: problem))
            } else {
                if let nextCard = state.currentCard {
                    try? telemetryWriter.append(
                        SliceEvent(type: .sumSprintCardShown, payload: [
                            "problem_id": currentProblem?.id.uuidString ?? "",
                            "card_index": String(state.currentCardIndex),
                            "prompt": nextCard.prompt
                        ])
                    )
                }
                feedbackMessage = promptForCurrentStage()
            }
        } else {
            try? telemetryWriter.append(
                SliceEvent(type: .sumSprintCardAnswered, payload: [
                    "problem_id": currentProblem?.id.uuidString ?? "",
                    "card_index": String(state.currentCardIndex),
                    "prompt": card.prompt,
                    "correct": "false"
                ])
            )
            feedbackMessage = "Try again. Solve this one before Bond Blast."
            speechService.speak(feedbackMessage, enabled: featureFlags.audioEnabled)
            hapticsService.failure(enabled: featureFlags.hapticsEnabled)
        }
    }

    // MARK: - Bond Blast actions

    /// Called by BondMatchView when the child begins dragging or taps a left card.
    func bondDragStarted(pairId: UUID) {
        guard currentStage == .pictorial || currentStage == .bondMatch else { return }
        hapticsService.cardPickup(enabled: featureFlags.hapticsEnabled)
        logBondMatchTelemetry("pair_drag_started", extra: ["pair_id": pairId.uuidString])
    }

    /// Called by BondMatchView when a dragged card is hovering near a snap target.
    func bondNearTarget() {
        guard currentStage == .pictorial || currentStage == .bondMatch else { return }
        hapticsService.cardNearSnap(enabled: featureFlags.hapticsEnabled)
    }

    /// Called when the child successfully matches a complement pair.
    /// Advances to `.done` when all pairs are matched.
    func matchPair(id: UUID) {
        guard (currentStage == .pictorial || currentStage == .bondMatch),
              let problem = currentProblem,
              var state = bondMatchState,
              let idx = state.pairs.firstIndex(where: { $0.id == id }) else { return }

        state.pairs[idx].isMatched = true
        let pair = state.pairs[idx]
        bondMatchState = state

        logBondMatchTelemetry("pair_matched", extra: [
            "left": String(pair.left),
            "right": String(pair.right),
            "match_count": String(state.matchCount)
        ])
        hapticsService.cardSnapCorrect(enabled: featureFlags.hapticsEnabled)

        if state.isComplete {
            let msg = "Amazing! You matched all the bonds for \(problem.target)!"
            completeStage(successMessage: msg)
        }
    }

    /// Called when the child drops a card on the wrong target.
    func mismatchPair() {
        guard (currentStage == .pictorial || currentStage == .bondMatch), let problem = currentProblem else { return }
        logBondMatchTelemetry("pair_mismatch", extra: [:])
        hapticsService.cardSnapMismatch(enabled: featureFlags.hapticsEnabled)
        let msg = "Try again! Find two numbers that make \(problem.target)."
        feedbackMessage = msg
        speechService.speak(msg, enabled: featureFlags.audioEnabled)
    }

    // MARK: - Gravity Split actions

    func adjustGravitySplitByTilt(_ tiltRoll: Double) {
        guard currentStage == .gravitySplit else { return }
        gravitySplitNeutralRoll = tiltRoll
    }

    func adjustGravitySplitByTap(delta: Int, side: TransferSide = .left) {
        guard currentStage == .gravitySplit, var state = gravitySplitState,
              !state.isLocked else { return }

        let previousLeft = state.leftCount
        let previousRight = state.rightCount
        switch side {
        case .left:
            state.adjustLeft(by: delta)
        case .right:
            state.adjustRight(by: delta)
        }
        gravitySplitState = state

        if state.leftCount != previousLeft || state.rightCount != previousRight {
            hapticsService.counterSettle(enabled: featureFlags.hapticsEnabled)
            hapticsService.counterSlide(enabled: featureFlags.hapticsEnabled)
        }

        if state.isLocked, let problem = currentProblem {
            hapticsService.balanceLock(enabled: featureFlags.hapticsEnabled)
            completeStage(successMessage: successMessage(for: .gravitySplit, problem: problem))
        }
    }

    func resetGravitySplit() {
        guard currentStage == .gravitySplit, let problem = currentProblem else { return }
        gravitySplitState = GravitySplitState(problem: problem)
        gravitySplitNeutralRoll = nil
    }

    private func validateEquation(for problem: SliceProblem) -> Bool {
        guard let left = Int(equationLeftInput), let right = Int(equationRightInput) else { return false }
        return left + right == problem.target
    }

    private func completeStage(successMessage: String) {
        feedbackMessage = successMessage
        speechService.speak(successMessage, enabled: featureFlags.audioEnabled)

        // Bond Blast fires only on the last problem of the session.
        let isLastProblem = currentProblemIndex + 1 >= problems.count
        let makeBreakLoopV2Enabled = featureFlags.makeBreakLoopV2Enabled
        let showBondMatch = makeBreakLoopV2Enabled || (featureFlags.vs1BondMatchEnabled && isLastProblem)
        let showGravitySplit = makeBreakLoopV2Enabled || featureFlags.vs1GravitySplitEnabled

        let next = SliceStateMachine.nextStage(
            after: currentStage,
            success: true,
            showTransfer: config.showTransfer,
            showGravitySplit: showGravitySplit,
            showBondMatch: showBondMatch,
            makeBreakLoopV2Enabled: makeBreakLoopV2Enabled
        )
        recordStageTransition(from: currentStage, to: next)

        // A problem is complete when the next stage is .done (the last meaningful
        // stage has been cleared). This handles all paths: with/without transfer,
        // with/without bond match.
        let isProblemComplete = next == .done
        if isProblemComplete {
            recordProblemCompletion(transferCorrect: true)
            if currentStage == .bondMatch {
                hapticsService.bondMatchComplete(enabled: featureFlags.hapticsEnabled)
            } else {
                hapticsService.success(enabled: featureFlags.hapticsEnabled)
            }
        } else {
            hapticsService.stageSuccess(enabled: featureFlags.hapticsEnabled)
        }
        // Show the celebration overlay then advance the stage.
        // The entire transition (showCelebration reset + stage advance + next-stage prep)
        // is deferred into the Task so the overlay has time to render and animate.
        // celebrationDuration is injected — unit tests pass 0 to skip the wait.
        showCelebration = true
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(celebrationDuration))
            showCelebration = false
            currentStage = next
            currentProblemState.stage = next
            if next == .done {
                advanceProblemOrFinishSession()
            } else {
                prepareForStage(next)
            }
        }
    }

    private func prepareForStage(_ stage: SliceStage) {
        switch stage {
        case .pictorial:
            if let problem = currentProblem {
                bondMatchState = BondMatchState(
                    target: problem.target,
                    pairs: BondMatchState.makePairs(for: problem.target)
                )
                logBondMatchTelemetry("bond_match_started", extra: [
                    "target": String(problem.target),
                    "pair_count": String(bondMatchState?.pairs.count ?? 0),
                    "entry_stage": SliceStage.pictorial.rawValue
                ])
            }
        case .abstract:
            bondMatchState = nil
            equationLeftInput = ""
            equationRightInput = ""
        case .transfer:
            transferLeftCount = 0
            transferRightCount = 0
        case .gravitySplit:
            if let problem = currentProblem {
                gravitySplitState = GravitySplitState(problem: problem)
                gravitySplitNeutralRoll = nil   // re-calibrate on first tilt after stage entry
            }
        case .sumSprint:
            bondMatchState = nil
            gravitySplitState = nil
            if let problem = currentProblem {
                let burst = SumSprintBurstState.make(for: problem)
                sumSprintBurstState = burst
                try? telemetryWriter.append(
                    SliceEvent(type: .sumSprintStarted, payload: [
                        "problem_id": problem.id.uuidString,
                        "target": String(problem.target),
                        "card_count": String(burst.cards.count)
                    ])
                )
                if let card = burst.currentCard {
                    try? telemetryWriter.append(
                        SliceEvent(type: .sumSprintCardShown, payload: [
                            "problem_id": problem.id.uuidString,
                            "card_index": "0",
                            "prompt": card.prompt
                        ])
                    )
                }
            }
        case .bondMatch:
            if let problem = currentProblem {
                bondMatchState = BondMatchState(
                    target: problem.target,
                    pairs: BondMatchState.makePairs(for: problem.target)
                )
                logBondMatchTelemetry("bond_match_started", extra: [
                    "target": String(problem.target),
                    "pair_count": String(bondMatchState?.pairs.count ?? 0),
                    "entry_stage": SliceStage.bondMatch.rawValue
                ])
            }
        case .concrete, .done:
            break
        }
        feedbackMessage = promptForCurrentStage()
        speechService.speak(feedbackMessage, enabled: featureFlags.audioEnabled)
    }

    private func advanceProblemOrFinishSession() {
        let elapsed = Date.now.timeIntervalSince(sessionStartedAt)
        let timeCapReached = elapsed >= sessionTimeLimitSeconds
        if currentProblemIndex + 1 < problems.count && !timeCapReached {
            currentProblemIndex += 1
            if !problemThemes.isEmpty {
                activeTheme = problemThemes[currentProblemIndex % problemThemes.count]
            }
            currentStage = .concrete
            currentProblemState = ProblemState()
            concreteWarmCount = 0
            concreteAccentCount = 0
            splitLeftCount = 0
            equationLeftInput = ""
            equationRightInput = ""
            transferLeftCount = 0
            transferRightCount = 0
            gravitySplitState = nil
            gravitySplitNeutralRoll = nil
            sumSprintBurstState = nil
            problemStartedAt = .now
            feedbackMessage = promptForCurrentStage()
            logProblemPresented()
        } else {
            endSession()
        }
    }

    private func endSession() {
        currentSession.endedAt = .now
        let digest = buildDigest()
        let export = try? telemetryWriter.finishSession(session: currentSession, digest: digest, themeId: featureFlags.selectedThemeId)
        let summary = SessionSummaryDraft(
            sessionId: currentSession.sessionId.uuidString,
            startedAt: currentSession.startedAt,
            endedAt: currentSession.endedAt ?? .now,
            objectiveTitle: digest.objectiveTitle,
            problemsCompleted: digest.problemsCompleted,
            firstAttemptAccuracy: digest.firstAttemptAccuracy,
            transferCorrectCount: digest.transferCorrectCount,
            medianLatencyMs: digest.medianLatencyMs,
            nextTargetHint: digest.nextTargetHint,
            exportFileName: export?.fileName ?? "session-\(currentSession.sessionId.uuidString).jsonl"
        )
        saveSummary(summary)
        completedSummary = summary
        feedbackMessage = activeTheme.sessionEndPhrase()
        route = .sessionSummary
    }

    private func buildDigest() -> ParentDigest {
        let completed = currentSession.problems.count
        let firstTryCount = currentSession.problems.filter(\.firstTryCorrect).count
        let transferCorrect = currentSession.problems.filter(\.transferCorrect).count
        let latencies = currentSession.problems.compactMap { problem -> Int? in
            guard let event = problem.events.first(where: { $0.type == .problemCompleted }),
                  let ms = Int(event.payload["time_ms"] ?? "") else { return nil }
            return ms
        }
        let sorted = latencies.sorted()
        let median = sorted.isEmpty ? 0 : sorted[sorted.count / 2]
        let accuracy = completed == 0 ? 0 : Double(firstTryCount) / Double(completed)

        return ParentDigest(
            objectiveTitle: "Make & Break Numbers",
            firstAttemptAccuracy: accuracy,
            medianLatencyMs: median,
            problemsCompleted: completed,
            transferCorrectCount: transferCorrect,
            nextTargetHint: nextHint(accuracy: accuracy, transferCorrect: transferCorrect, completed: completed)
        )
    }

    private func nextHint(accuracy: Double, transferCorrect: Int, completed: Int) -> String {
        guard completed > 0 else {
            return "Complete a session to see personalised recommendations here."
        }
        let transferRate = Double(transferCorrect) / Double(completed)
        // Transfer success much lower than overall accuracy → abstract-to-concrete
        // connection isn't formed yet; suggest home reinforcement
        if transferRate < accuracy - 0.3 {
            return "Your child found the reverse (equation → counters) harder. Try this at home: write '3 + 4 =' on paper and ask them to show it with grapes or blocks."
        }
        if accuracy < 0.5 {
            return "The concept is still new. Keep sessions short, use physical objects at home (up to 20 buttons or pebbles), and don't rush to the written equation."
        }
        if accuracy < 0.7 {
            return "Repeat the same range with spoken prompts. At home, practise splitting groups of 4–12 objects into two parts and counting each."
        }
        if accuracy < 0.9 {
            return "Solid progress! Try increasing to 7–8 problems next session when they seem relaxed."
        }
        return "Excellent mastery. Try the full 1–20 range or introduce writing the equation on paper first before using the app."
    }

    private func logProblemPresented() {
        guard let currentProblem else { return }
        try? telemetryWriter.append(
            SliceEvent(
                type: .problemPresented,
                payload: [
                    "problem_id": currentProblem.id.uuidString,
                    "target": String(currentProblem.target),
                    "stage": currentStage.rawValue,
                    "difficulty_tag": currentProblem.skillTag
                ]
            )
        )
    }

    private func recordInteraction(action: String, value: Int) {
        guard let currentProblem else { return }
        try? telemetryWriter.append(
            SliceEvent(
                type: .interaction,
                payload: [
                    "problem_id": currentProblem.id.uuidString,
                    "action": action,
                    "value": String(value),
                    "stage": currentStage.rawValue
                ]
            )
        )
    }

    private func recordStageTransition(from: SliceStage, to: SliceStage) {
        guard let currentProblem else { return }
        try? telemetryWriter.append(
            SliceEvent(
                type: .stageTransition,
                payload: [
                    "problem_id": currentProblem.id.uuidString,
                    "from": from.rawValue,
                    "to": to.rawValue,
                    "decomposition_a": String(currentProblem.decompositionA),
                    "decomposition_b": String(currentProblem.decompositionB),
                    "entered_left": equationLeftInput,
                    "entered_right": equationRightInput
                ]
            )
        )
    }

    private func recordProblemCompletion(transferCorrect: Bool) {
        guard let currentProblem else { return }
        let elapsedMs = Int(Date.now.timeIntervalSince(problemStartedAt) * 1000)
        currentProblemState.timeSpentMs = elapsedMs
        let problemSession = ProblemSession(
            problemId: currentProblem.id,
            givenAt: problemStartedAt,
            events: [
                SliceEvent(
                    type: .problemCompleted,
                    payload: [
                        "problem_id": currentProblem.id.uuidString,
                        "attempts": String(currentProblemState.attempts),
                        "time_ms": String(elapsedMs),
                        "transfer_correct": String(transferCorrect)
                    ]
                )
            ],
            firstTryCorrect: currentProblemState.attempts == 1,
            attemptCount: currentProblemState.attempts,
            retryCount: max(currentProblemState.attempts - 1, 0),
            transferCorrect: transferCorrect
        )
        currentSession.problems.append(problemSession)
        try? telemetryWriter.append(problemSession.events[0])
    }

    private func promptForCurrentStage() -> String {
        guard let currentProblem else { return "Start a session to play." }
        switch currentStage {
        case .concrete:
            return activeTheme.concretePrompt(target: currentProblem.target)
        case .pictorial, .bondMatch:
            return "Bond Blast! Match the pairs that make \(currentProblem.target)!"
        case .sumSprint:
            if let card = sumSprintBurstState?.currentCard {
                return "Quick Sum Sprint. Solve \(card.prompt), then finish with Bond Blast."
            }
            return "Quick Sum Sprint! Solve a tiny burst, then finish with Bond Blast."
        case .abstract:
            return activeTheme.abstractPrompt()
        case .transfer:
            return "Show the same two parts with counters."
        case .gravitySplit:
            let a = currentProblem.decompositionA
            let b = currentProblem.decompositionB
            return "Use plus and minus to build \(a) on one side and \(b) on the other."
        case .done:
            return "Nice work."
        }
    }

    private func successMessage(for stage: SliceStage, problem: SliceProblem) -> String {
        activeTheme.stageSuccessPhrase(for: stage, target: problem.target)
    }

    private func feedbackMessageForFailure(stage: SliceStage, problem: SliceProblem) -> String {
        let attempts = currentProblemState.attempts
        switch stage {
        case .concrete:
            if attempts == 1 {
                return "Keep counting. Make exactly \(problem.target)."
            } else if attempts == 2 {
                return "You have \(concreteCount). How many more do you need to make \(problem.target)?"
            } else {
                return "Try tapping the \(activeTheme.counterNoun) one by one until you reach \(problem.target)."
            }
        case .pictorial, .bondMatch:
            return "Try another pair. Look for two numbers that add up to \(problem.target)."
        case .abstract:
            if attempts == 1 {
                return "Use two numbers that add up to \(problem.target)."
            } else if attempts == 2 {
                return "Try \(problem.decompositionA) and \(problem.decompositionB). What do they add up to?"
            } else {
                return "Type \(problem.decompositionA) on the left and \(problem.decompositionB) on the right."
            }
        case .transfer:
            if attempts == 1 {
                return "Show the same two parts with counters."
            } else if attempts == 2 {
                return "Use the same two numbers you wrote and build them with counters."
            } else {
                return "Build the same equation again with counters, one group on each side."
            }
        case .gravitySplit:
            return "Keep building the split. Put \(problem.decompositionA) on one side and \(problem.decompositionB) on the other."
        case .sumSprint:
            return "Keep going. Finish this quick sprint before Bond Blast."
        case .done:
            return "Try again."
        }
    }

    private func logBondMatchTelemetry(_ action: String, extra: [String: String]) {
        guard let currentProblem else { return }
        var payload = extra
        payload["problem_id"] = currentProblem.id.uuidString
        payload["action"] = action
        payload["stage"] = currentStage.rawValue
        try? telemetryWriter.append(
            SliceEvent(type: .interaction, payload: payload)
        )
    }

    private func appendDigit(to string: String, digit: Int) -> String {
        let candidate = (string + String(digit)).prefix(2)
        let numeric = Int(candidate) ?? 0
        return numeric > 10 ? string : String(candidate)
    }

    private func setConcreteTotal(_ total: Int) {
        let maxTotal = currentProblem?.target ?? 10
        let clamped = min(max(total, 0), maxTotal)
        concreteWarmCount = min(clamped, 5)
        concreteAccentCount = max(clamped - concreteWarmCount, 0)
        recordInteraction(action: "place", value: concreteCount)
        #if targetEnvironment(simulator)
        print("[Mather][concrete] warm=\(concreteWarmCount) accent=\(concreteAccentCount) total=\(concreteCount)")
        #endif
    }
}

enum EquationSide {
    case left
    case right
}

enum ConcreteGroup {
    case warm
    case accent
}

enum TransferSide {
    case left
    case right
}
