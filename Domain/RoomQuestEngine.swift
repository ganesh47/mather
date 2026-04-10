import Foundation
import Observation

enum RoomPhase: Equatable {
    case safetyAck                          // one-time parent safety acknowledgement
    case setup                              // parent placing spot-cards, sees quantities
    case spot(index: Int)                   // child walking to spot i
    case returning                          // child walking back to iPad
    case onScreenPictorial                  // SplitView (pre-populated from room phase)
    case onScreenAbstract                   // EquationResolveView
    case onScreenTransfer                   // TransferCheckView
    case complete                           // session done
    indirect case paused(resumingTo: RoomPhase)     // hard pause — any phase
}

@MainActor
@Observable
final class RoomQuestEngine {

    // MARK: - State

    private(set) var phase: RoomPhase = .safetyAck
    private(set) var problem: SliceProblem?
    var feedbackMessage = ""

    // On-screen CPA state — mirrors VerticalSliceEngine's public fields
    private(set) var splitLeftCount = 0     // pre-populated from room phase decompositionA
    var equationLeftInput = ""
    var equationRightInput = ""
    var transferLeftCount = 0
    var transferRightCount = 0

    // MARK: - Telemetry timing

    private var setupStartedAt: Date?
    private var roomPhaseStartedAt: Date?
    private var roomPhaseTimer: Task<Void, Never>?

    // MARK: - Dependencies

    private let featureFlags: FeatureFlagService
    private let telemetryWriter: TelemetryWriter
    private let speechService: SpeechService
    private let hapticsService: HapticsService
    /// Set by AppModel after init. Callback to navigate back to Home via VerticalSliceEngine.
    var onExitToHome: (() -> Void)?

    static let roomPhaseLimitSeconds: TimeInterval = 4 * 60

    // MARK: - Init

    init(
        featureFlags: FeatureFlagService,
        telemetryWriter: TelemetryWriter,
        speechService: SpeechService,
        hapticsService: HapticsService = HapticsService()
    ) {
        self.featureFlags = featureFlags
        self.telemetryWriter = telemetryWriter
        self.speechService = speechService
        self.hapticsService = hapticsService
    }

    // MARK: - Session lifecycle

    /// Called when `RoomSessionView` appears. Generates a problem and enters the first phase.
    func startSession() {
        let problems = ProblemGenerator.generateProblems(config: SliceConfig())
        guard let p = problems.first else { return }
        problem = p
        setupStartedAt = .now
        phase = featureFlags.roomQuestSafetyAcknowledged ? .setup : .safetyAck
        feedbackMessage = "Set up the spots, then tap Ready."
        try? telemetryWriter.append(SliceEvent(
            type: .roomQuestStarted,
            payload: [
                "target": String(p.target),
                "decomposition_a": String(p.decompositionA),
                "decomposition_b": String(p.decompositionB)
            ]
        ))
    }

    /// Parent taps "I understand" on the one-time safety acknowledgement screen.
    func acknowledgedSafety() {
        featureFlags.roomQuestSafetyAcknowledged = true
        phase = .setup
    }

    /// Parent taps "Ready — spots are set!" to begin the room phase.
    func markSetupComplete() {
        guard let p = problem else { return }
        let setupMs = setupStartedAt.map { Int(Date.now.timeIntervalSince($0) * 1000) } ?? 0
        try? telemetryWriter.append(SliceEvent(
            type: .roomQuestSetupComplete,
            payload: ["setup_time_ms": String(setupMs)]
        ))
        roomPhaseStartedAt = .now
        phase = .spot(index: 0)
        speechService.speak("Let's make \(p.target)! Walk to the red dot and pick up everything there.")
        startRoomPhaseTimer()
    }

    /// Child or parent confirms arrival at a spot.
    func markSpotVisited(index: Int) {
        guard let p = problem else { return }
        let quantity = index == 0 ? p.decompositionA : p.decompositionB
        try? telemetryWriter.append(SliceEvent(
            type: .roomQuestSpotVisited,
            payload: ["spot_index": String(index), "quantity": String(quantity)]
        ))
        if index == 0 {
            speechService.speak("Great — now walk to the blue dot.")
            phase = .spot(index: 1)
        } else {
            speechService.speak("Bring them all back to me!")
            phase = .returning
        }
    }

    /// Parent or child taps "We're back!" — transitions to on-screen CPA.
    func markReturned() {
        guard let p = problem else { return }
        roomPhaseTimer?.cancel()
        let durationMs = roomPhaseStartedAt.map { Int(Date.now.timeIntervalSince($0) * 1000) } ?? 0
        try? telemetryWriter.append(SliceEvent(
            type: .roomQuestPhaseComplete,
            payload: ["room_phase_duration_ms": String(durationMs), "spots_visited": "2"]
        ))
        splitLeftCount = p.decompositionA
        equationLeftInput = ""
        equationRightInput = ""
        hapticsService.success(enabled: featureFlags.hapticsEnabled)
        phase = .onScreenPictorial
        feedbackMessage = "You collected them! Now let's show the split."
    }

    // MARK: - On-screen CPA

    func submitPictorial() {
        phase = .onScreenAbstract
    }

    func submitAbstract() {
        guard let p = problem else { return }
        if equationLeftInput == String(p.decompositionA) && equationRightInput == String(p.decompositionB) {
            phase = .onScreenTransfer
        } else {
            hapticsService.failure(enabled: featureFlags.hapticsEnabled)
            feedbackMessage = "Try again — check both numbers."
        }
    }

    func submitTransfer() {
        guard let p = problem else { return }
        let correct = transferLeftCount == p.decompositionA && transferRightCount == p.decompositionB
        finishSession(abstractCorrect: correct)
    }

    // MARK: - Pause / abort

    func pauseSession() {
        let current = phase
        phase = .paused(resumingTo: current)
        roomPhaseTimer?.cancel()
        feedbackMessage = "Paused. Tap Resume when ready."
    }

    func resumeSession() {
        guard case .paused(let resumeTo) = phase else { return }
        phase = resumeTo
        if case .spot(_) = resumeTo { startRoomPhaseTimer() }
        if case .returning = resumeTo { startRoomPhaseTimer() }
    }

    func abandonSession(reason: String) {
        roomPhaseTimer?.cancel()
        try? telemetryWriter.append(SliceEvent(
            type: .roomQuestAbandoned, payload: ["reason": reason]
        ))
        phase = .complete
        onExitToHome?()
    }

    // MARK: - Private

    private func startRoomPhaseTimer() {
        roomPhaseTimer = Task { [weak self] in
            try? await Task.sleep(for: .seconds(RoomQuestEngine.roomPhaseLimitSeconds))
            guard !Task.isCancelled, let self else { return }
            self.timerExpired()
        }
    }

    private func timerExpired() {
        guard let p = problem else { return }
        roomPhaseTimer?.cancel()
        splitLeftCount = p.decompositionA
        phase = .onScreenPictorial
        feedbackMessage = "Time's up — let's finish on screen!"
        speechService.speak("Time's up! Come back to the iPad.")
        try? telemetryWriter.append(SliceEvent(
            type: .roomQuestAbandoned, payload: ["reason": "timeout"]
        ))
    }

    private func finishSession(abstractCorrect: Bool) {
        guard let p = problem else { return }
        try? telemetryWriter.append(SliceEvent(
            type: .roomQuestCompleted,
            payload: ["target": String(p.target), "abstract_correct": String(abstractCorrect)]
        ))
        phase = .complete
        feedbackMessage = abstractCorrect ? "Well done! You made \(p.target)." : "Good try!"
        if abstractCorrect {
            hapticsService.success(enabled: featureFlags.hapticsEnabled)
        }
    }
}
