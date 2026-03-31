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

    var concreteCount = 0
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
    private let saveSummary: (SessionSummaryDraft) -> Void

    init(
        featureFlags: FeatureFlagService,
        telemetryWriter: TelemetryWriter,
        speechService: SpeechService,
        saveSummary: @escaping (SessionSummaryDraft) -> Void
    ) {
        self.featureFlags = featureFlags
        self.telemetryWriter = telemetryWriter
        self.speechService = speechService
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
        concreteCount = 0
        splitLeftCount = 0
        equationLeftInput = ""
        equationRightInput = ""
        transferCount = 0
        feedbackMessage = "Make the target number with the big counters."
        showCelebration = false
        completedSummary = nil
        speechService.resetSession()
        speechService.speakSessionIntroIfNeeded(enabled: featureFlags.audioEnabled)

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
        guard let currentProblem else { return }
        concreteCount = min(max(concreteCount + delta, 0), currentProblem.target)
        recordInteraction(action: "place", value: concreteCount)
    }

    func moveSplit(delta: Int) {
        guard let currentProblem else { return }
        splitLeftCount = min(max(splitLeftCount + delta, 0), currentProblem.target)
        recordInteraction(action: "split", value: splitLeftCount)
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
        }
    }

    func replayPrompt() {
        speechService.speak(promptForCurrentStage(), enabled: featureFlags.audioEnabled)
    }

    private func validateEquation(for problem: SliceProblem) -> Bool {
        guard let left = Int(equationLeftInput), let right = Int(equationRightInput) else { return false }
        return left + right == problem.target && left == splitLeftCount && right == (problem.target - splitLeftCount)
    }

    private func completeStage(successMessage: String) {
        showCelebration = true
        feedbackMessage = successMessage
        speechService.speak(successMessage, enabled: featureFlags.audioEnabled)

        let next = SliceStateMachine.nextStage(after: currentStage, success: true, showTransfer: config.showTransfer)
        if currentStage == .transfer || (!config.showTransfer && currentStage == .abstract) {
            recordProblemCompletion(transferCorrect: true)
        }

        currentStage = next
        currentProblemState.stage = next

        if next == .done {
            advanceProblemOrFinishSession()
        } else {
            prepareForStage(next)
        }
    }

    private func prepareForStage(_ stage: SliceStage) {
        showCelebration = false
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
        if currentProblemIndex + 1 < problems.count {
            currentProblemIndex += 1
            currentStage = .concrete
            currentProblemState = ProblemState()
            concreteCount = 0
            splitLeftCount = 0
            equationLeftInput = ""
            equationRightInput = ""
            transferCount = 0
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
        let latencySource = currentSession.problems.map { max($0.events.count * 600, 600) }
        let median = latencySource.sorted().dropFirst(latencySource.count / 2).first ?? 0
        let accuracy = completed == 0 ? 0 : Double(firstTryCount) / Double(completed)

        return ParentDigest(
            objectiveTitle: "Make & Break to 10",
            firstAttemptAccuracy: accuracy,
            medianLatencyMs: median,
            problemsCompleted: completed,
            transferCorrectCount: transferCorrect,
            nextTargetHint: accuracy < 0.7 ? "Repeat the same range with spoken prompts." : "Increase to 7 or 8 problems when the child stays relaxed."
        )
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

    private func recordProblemCompletion(transferCorrect: Bool) {
        guard let currentProblem else { return }
        let problemSession = ProblemSession(
            problemId: currentProblem.id,
            givenAt: .now,
            events: [
                SliceEvent(
                    type: .problemCompleted,
                    payload: [
                        "problem_id": currentProblem.id.uuidString,
                        "attempts": String(currentProblemState.attempts),
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
        switch stage {
        case .concrete:
            return "Keep counting. Make exactly \(problem.target)."
        case .pictorial:
            return "Try another break. Both groups together should still make \(problem.target)."
        case .abstract:
            return "Use the same two parts you just built."
        case .transfer:
            return "Look at the equation and rebuild the whole number."
        case .done:
            return "Try again."
        }
    }

    private func appendDigit(to string: String, digit: Int) -> String {
        let candidate = (string + String(digit)).prefix(2)
        let numeric = Int(candidate) ?? 0
        return numeric > 10 ? string : String(candidate)
    }
}

enum EquationSide {
    case left
    case right
}
