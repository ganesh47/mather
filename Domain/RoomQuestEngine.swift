import Foundation
import Observation

enum RoomPhase: Equatable {
    case safetyAck                          // one-time parent safety acknowledgement
    case setup                              // parent placing station markers, sees quantities
    case spot(index: Int)                   // child walking to station i
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
    private(set) var stations: [RoomQuestStation] = []
    var feedbackMessage = ""
    var showCelebration = false

    // On-screen CPA state — mirrors VerticalSliceEngine's public fields
    private(set) var splitLeftCount = 0
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

    func startSession() {
        let problems = ProblemGenerator.generateProblems(config: SliceConfig())
        guard let p = problems.first else { return }
        problem = p
        stations = [
            RoomQuestStation(id: .redRocket, role: .redRocket, quantity: p.decompositionA),
            RoomQuestStation(id: .blueBubble, role: .blueBubble, quantity: p.decompositionB)
        ]
        setupStartedAt = .now
        phase = featureFlags.roomQuestSafetyAcknowledged ? .setup : .safetyAck
        feedbackMessage = "Set up the stations, then scan each one or mark it ready."
        try? telemetryWriter.append(SliceEvent(
            type: .roomQuestStarted,
            payload: [
                "target": String(p.target),
                "decomposition_a": String(p.decompositionA),
                "decomposition_b": String(p.decompositionB)
            ]
        ))
    }

    func acknowledgedSafety() {
        featureFlags.roomQuestSafetyAcknowledged = true
        phase = .setup
    }

    func verifyStationWithCamera(_ role: RoomQuestStationRole) {
        setStationRegistered(role, method: .cameraVerified)
    }

    func confirmStationManually(_ role: RoomQuestStationRole) {
        setStationRegistered(role, method: .manualConfirmed)
    }

    func registerStation(_ role: RoomQuestStationRole) {
        confirmStationManually(role)
    }

    private func setStationRegistered(_ role: RoomQuestStationRole, method: RoomQuestStationVerificationMethod) {
        guard let idx = stations.firstIndex(where: { $0.role == role }) else { return }
        stations[idx].isRegistered = true
        stations[idx].verificationMethod = method
        let methodCopy = method == .cameraVerified ? "Camera check saved." : "Manual confirmation saved."
        feedbackMessage = stations.allSatisfy(\.isRegistered)
            ? "\(methodCopy) Both stations are ready."
            : "\(methodCopy) Now set up the other station."
    }

    var allStationsRegistered: Bool {
        stations.count == 2 && stations.allSatisfy(\.isRegistered)
    }

    var currentStation: RoomQuestStation? {
        guard case .spot(let index) = phase, stations.indices.contains(index) else { return nil }
        return stations[index]
    }

    func markSetupComplete() {
        guard let p = problem else { return }
        guard allStationsRegistered else {
            feedbackMessage = "Scan or confirm both stations before you start."
            return
        }
        let setupMs = setupStartedAt.map { Int(Date.now.timeIntervalSince($0) * 1000) } ?? 0
        try? telemetryWriter.append(SliceEvent(
            type: .roomQuestSetupComplete,
            payload: ["setup_time_ms": String(setupMs)]
        ))
        roomPhaseStartedAt = .now
        phase = .spot(index: 0)
        speechService.speak("Let's make \(p.target)! Find the Red Rocket station and pick up everything there.", enabled: featureFlags.audioEnabled)
        startRoomPhaseTimer()
    }

    func markSpotVisited(index: Int) {
        guard let station = stations[safe: index] else { return }
        let quantity = station.quantity
        try? telemetryWriter.append(SliceEvent(
            type: .roomQuestSpotVisited,
            payload: [
                "spot_index": String(index),
                "quantity": String(quantity),
                "station_role": station.role.rawValue
            ]
        ))
        if index == 0 {
            speechService.speak("Great, now find the Blue Bubble station.", enabled: featureFlags.audioEnabled)
            phase = .spot(index: 1)
        } else {
            speechService.speak("Bring them all back to me!", enabled: featureFlags.audioEnabled)
            phase = .returning
        }
    }

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
        flashCelebration()
    }

    func submitPictorial() {
        phase = .onScreenAbstract
    }

    func submitAbstract() {
        guard let p = problem else { return }
        if equationLeftInput == String(p.decompositionA) && equationRightInput == String(p.decompositionB) {
            flashCelebration()
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

    func pauseSession() {
        let current = phase
        phase = .paused(resumingTo: current)
        roomPhaseTimer?.cancel()
        showCelebration = false
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

    private func flashCelebration() {
        showCelebration = true
        Task { @MainActor [weak self] in
            try? await Task.sleep(for: .seconds(1.5))
            self?.showCelebration = false
        }
    }

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
        speechService.speak("Time's up! Come back to the iPad.", enabled: featureFlags.audioEnabled)
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
            flashCelebration()
        }
    }
}

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
