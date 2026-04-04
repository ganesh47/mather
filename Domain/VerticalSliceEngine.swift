import Foundation
import Observation

enum AppRoute {
    case home
    case sessionConfig
    case session
    case sessionSummary
    case parentSummary
    case settings
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
    var transferCount = 0
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

    init(
        featureFlags: FeatureFlagService,
        telemetryWriter: TelemetryWriter,
        speechService: SpeechService,
        hapticsService: HapticsService = HapticsService(),
        celebrationDuration: TimeInterval = 1.5,
        saveSummary: @escaping (SessionSummaryDraft) -> Void
    ) {
        self.featureFlags = featureFlags
        self.telemetryWriter = telemetryWriter
        self.speechService = speechService
        self.hapticsService = hapticsService
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

    func startSession() {
        config.audioEnabled = featureFlags.audioEnabled
        config.deterministicMode = featureFlags.testModeEnabled
        problems = ProblemGenerator.generateProblems(config: config)
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
        transferCount = 0
        feedbackMessage = "Make the target number with the big counters."
        showCelebration = false
        completedSummary = nil
        sessionStartedAt = .now
        problemStartedAt = .now
        speechService.resetSession()
        speechService.speakSessionIntroIfNeeded()

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
        guard currentProblem != nil else { return }
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

    func adjustTransfer(by delta: Int) {
        guard let currentProblem else { return }
        transferCount = min(max(transferCount + delta, 0), currentProblem.target)
        recordInteraction(action: "transfer_place", value: transferCount)
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
            isCorrect = transferCount == currentProblem.target
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

    private func validateEquation(for problem: SliceProblem) -> Bool {
        guard let left = Int(equationLeftInput), let right = Int(equationRightInput) else { return false }
        return left + right == problem.target
    }

    private func completeStage(successMessage: String) {
        feedbackMessage = successMessage
        speechService.speak(successMessage, enabled: featureFlags.audioEnabled)

        let next = SliceStateMachine.nextStage(after: currentStage, success: true, showTransfer: config.showTransfer)
        recordStageTransition(from: currentStage, to: next)

        let isProblemComplete = currentStage == .transfer || (!config.showTransfer && currentStage == .abstract)
        if isProblemComplete {
            recordProblemCompletion(transferCorrect: true)
            hapticsService.success(enabled: featureFlags.hapticsEnabled)
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
            splitLeftCount = currentProblem?.decompositionA ?? 0
        case .abstract:
            equationLeftInput = ""
            equationRightInput = ""
        case .transfer:
            transferCount = 0
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
            currentStage = .concrete
            currentProblemState = ProblemState()
            concreteWarmCount = 0
            concreteAccentCount = 0
            splitLeftCount = 0
            equationLeftInput = ""
            equationRightInput = ""
            transferCount = 0
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
        let export = try? telemetryWriter.finishSession(session: currentSession, digest: digest)
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
        feedbackMessage = "Session complete. Great job showing the same number in different ways."
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
            objectiveTitle: "Make & Break to 10",
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
            return "The concept is still new. Keep sessions short, use physical objects at home (10 buttons, 10 pebbles), and don't rush to the written equation."
        }
        if accuracy < 0.7 {
            return "Repeat the same range with spoken prompts. At home, practise splitting 6–9 objects into two groups and counting each."
        }
        if accuracy < 0.9 {
            return "Solid progress! Try increasing to 7–8 problems next session when they seem relaxed."
        }
        return "Excellent mastery. Try the full 1–10 range or introduce writing the equation on paper first before using the app."
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
            return "Make \(currentProblem.target) with the counters."
        case .pictorial:
            return "Break \(currentProblem.target) into two groups."
        case .abstract:
            return "Type the same split as an equation."
        case .transfer:
            return "Use the equation to rebuild the whole number."
        case .done:
            return "Nice work."
        }
    }

    private func successMessage(for stage: SliceStage, problem: SliceProblem) -> String {
        switch stage {
        case .concrete:
            return "Yes. You made \(problem.target)."
        case .pictorial:
            return "That break still makes \(problem.target)."
        case .abstract:
            return "Your equation matches the split."
        case .transfer:
            return "You showed the same math in a new direction."
        case .done:
            return "Problem complete."
        }
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
                return "Try tapping the circles one by one until you reach \(problem.target)."
            }
        case .pictorial:
            if attempts == 1 {
                return "Try another break. Both groups together should still make \(problem.target)."
            } else if attempts == 2 {
                return "You have \(splitLeftCount) on the left and \(problem.target - splitLeftCount) on the right. That makes \(splitLeftCount + (problem.target - splitLeftCount))."
            } else {
                return "Any split is fine — left and right just need to add up to \(problem.target)."
            }
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
                return "Look at the equation and rebuild the whole number."
            } else if attempts == 2 {
                return "The equation shows \(problem.decompositionA) + \(problem.decompositionB). How many is that altogether?"
            } else {
                return "Tap until you have \(problem.target) counters — that is what \(problem.decompositionA) + \(problem.decompositionB) equals."
            }
        case .done:
            return "Try again."
        }
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
