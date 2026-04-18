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
    private let scanner: RoomQuestScanner
    private let stationStore: RoomQuestStationStore
    var onExitToHome: (() -> Void)?

    private(set) var scanState: RoomQuestScanState = .idle

    static let roomPhaseLimitSeconds: TimeInterval = 4 * 60

    // MARK: - Init

    init(
        featureFlags: FeatureFlagService,
        telemetryWriter: TelemetryWriter,
        speechService: SpeechService,
        hapticsService: HapticsService = HapticsService(),
        scanner: RoomQuestScanner = NoopRoomQuestScanner(),
        stationStore: RoomQuestStationStore
    ) {
        self.featureFlags = featureFlags
        self.telemetryWriter = telemetryWriter
        self.speechService = speechService
        self.hapticsService = hapticsService
        self.scanner = scanner
        self.stationStore = stationStore
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
        loadSavedReferenceState()
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
        guard featureFlags.roomQuestMarkerSetupEnabled else {
            feedbackMessage = "Camera setup is off right now. Use the same-place fallback."
            scanState = .failed(role: role, message: feedbackMessage)
            return
        }

        guard !isScanActive else { return }

        scanState = .scanning(role: role)
        feedbackMessage = "Scan the \(role.title) marker with the camera."
        try? telemetryWriter.append(SliceEvent(type: .roomQuestReferenceCaptureStarted, payload: ["station_role": role.rawValue]))

        Task { @MainActor [weak self] in
            guard let self else { return }
            do {
                let result = try await scanner.scanMarker(for: role)
                self.setStationRegistered(result.role, method: .cameraVerified)
                self.captureReference(for: result)
                self.scanState = .celebrating(role: result.role, usedARCelebration: result.usedARCelebration)
                self.hapticsService.success(enabled: self.featureFlags.hapticsEnabled)
                self.speechService.speak("You found \(result.role.title)!", enabled: self.featureFlags.audioEnabled)
                try? await Task.sleep(for: .seconds(1.2))
                if case .celebrating(let currentRole, _) = self.scanState, currentRole == result.role {
                    self.scanState = .idle
                }
            } catch let error as RoomQuestScannerError {
                switch error {
                case .cancelled:
                    self.feedbackMessage = "Camera check cancelled. Use the same-place fallback or try again."
                case .unavailable:
                    self.feedbackMessage = "Camera scan is unavailable on this device right now. Use the same-place fallback."
                case .wrongMarker(let expected, let detected):
                    self.feedbackMessage = "That looked like \(detected.title). Scan the \(expected.title) marker instead."
                }
                self.scanState = .failed(role: role, message: self.feedbackMessage)
            } catch {
                self.feedbackMessage = "Camera check did not finish. Try again or use the same-place fallback."
                self.scanState = .failed(role: role, message: self.feedbackMessage)
            }
        }
    }

    func confirmStationManually(_ role: RoomQuestStationRole) {
        scanState = .idle
        persistReferenceState(.manualFallback, for: role, markerPayload: nil, note: "Manual fallback saved")
        setStationRegistered(role, method: .manualConfirmed)
    }

    func registerStation(_ role: RoomQuestStationRole) {
        scanState = .idle
        if let station = stations.first(where: { $0.role == role }), station.referenceCaptureState == .captured {
            setStationRegistered(role, method: .cameraVerified)
        } else {
            confirmStationManually(role)
        }
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

    var currentSpotReferenceLabel: String {
        guard let station = currentStation else { return "" }

        switch station.referenceCaptureState {
        case .captured:
            return "Saved camera reference ready for \(station.role.title)."
        case .manualFallback:
            return "No camera reference was saved for \(station.role.title)."
        case .notCaptured:
            return "Reference still needs to be saved for \(station.role.title)."
        }
    }

    var currentSpotSearchGuidance: String {
        guard let station = currentStation else { return "" }

        switch scanState {
        case .almost(let role, _):
            return "Almost. Hold still, move a little closer, and point back at the saved \(role.title) place."
        case .failed(let role, _):
            return "Try again. Look for the saved \(role.title) place, then ask a grown-up to use fallback if the camera keeps missing it."
        case .celebrating(let role, _):
            return "You found the saved \(role.title) place."
        case .idle, .scanning:
            if station.referenceCaptureState == .captured {
                return "Look for the saved \(station.role.title) place, then hold the camera still for a recheck."
            } else {
                return "Look for \(station.role.title), then ask a grown-up to use fallback if the camera cannot help yet."
            }
        }
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

    func verifyCurrentSpotWithCamera() {
        guard case .spot(let index) = phase,
              let station = stations[safe: index]
        else { return }

        guard !isScanActive else { return }

        scanState = .scanning(role: station.role)
        feedbackMessage = station.referenceCaptureState == .captured
            ? "Rechecking the saved \(station.role.title) place."
            : "Scan \(station.role.title) to unlock the collect step."

        Task { @MainActor [weak self] in
            guard let self else { return }
            do {
                let result = try await scanner.scanMarker(for: station.role)

                if let savedReference = try? stationStore.reference(for: station.role),
                   let expectedRole = savedReference.role,
                   expectedRole != result.role {
                    self.feedbackMessage = "That is not the saved \(station.role.title) place yet. Try again."
                    self.scanState = .failed(role: station.role, message: self.feedbackMessage)
                    return
                }

                if let savedReference = try? stationStore.reference(for: station.role),
                   savedReference.captureState == .captured,
                   let savedMarkerPayload = savedReference.markerPayload,
                   let scannedMarkerPayload = result.markerPayload,
                   savedMarkerPayload != scannedMarkerPayload {
                    self.feedbackMessage = "Almost. This looks close, but it is not the saved \(station.role.title) place yet."
                    self.scanState = .almost(role: station.role, message: self.feedbackMessage)
                    return
                }

                self.setReferenceState(.captured, for: station.role, note: "Saved camera reference ready for recheck")
                self.scanState = .celebrating(role: result.role, usedARCelebration: result.usedARCelebration)
                self.hapticsService.success(enabled: self.featureFlags.hapticsEnabled)
                self.speechService.speak("You found the saved \(result.role.title) place. Collect \(station.quantity).", enabled: self.featureFlags.audioEnabled)
                self.feedbackMessage = "Found it. Collect \(station.quantity) \(station.quantity == 1 ? "token" : "tokens")."
                try? await Task.sleep(for: .seconds(1.0))
                self.scanState = .idle
                self.markSpotVisited(index: index)
            } catch let error as RoomQuestScannerError {
                switch error {
                case .cancelled:
                    self.feedbackMessage = "Camera check cancelled. Use fallback if you already found \(station.role.title)."
                case .unavailable:
                    self.feedbackMessage = "Camera scan is unavailable right now. Use fallback if needed."
                case .wrongMarker(let expected, let detected):
                    self.feedbackMessage = "That looked like \(detected.title). Try again at the saved \(expected.title) place."
                }
                self.scanState = .failed(role: station.role, message: self.feedbackMessage)
            } catch {
                self.feedbackMessage = "Camera check did not finish. Try again or use fallback."
                self.scanState = .failed(role: station.role, message: self.feedbackMessage)
            }
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

    private func captureReference(for result: RoomQuestMarkerScanResult) {
        guard featureFlags.roomQuestReferenceCaptureEnabled else { return }

        persistReferenceState(.captured, for: result.role, markerPayload: result.markerPayload, note: "Reference saved for \(result.role.title)")
    }

    private func persistReferenceState(_ state: RoomQuestReferenceCaptureState, for role: RoomQuestStationRole, markerPayload: String?, note: String) {
        let draft = RoomQuestStationReferenceDraft(
            role: role,
            markerPayload: markerPayload,
            capturedAt: .now,
            note: note,
            captureState: state
        )

        do {
            try stationStore.save(draft)
            setReferenceState(state, for: role, note: note)
            try? telemetryWriter.append(SliceEvent(
                type: .roomQuestReferenceCaptureCompleted,
                payload: [
                    "station_role": role.rawValue,
                    "saved": String(state == .captured),
                    "capture_state": state.rawValue,
                    "marker_payload_present": String(markerPayload != nil)
                ]
            ))
        } catch {
            setReferenceState(.notCaptured, for: role, note: "Reference save failed")
            try? telemetryWriter.append(SliceEvent(
                type: .roomQuestReferenceCaptureCompleted,
                payload: [
                    "station_role": role.rawValue,
                    "saved": "false",
                    "capture_state": RoomQuestReferenceCaptureState.notCaptured.rawValue
                ]
            ))
        }
    }

    private func setReferenceState(_ state: RoomQuestReferenceCaptureState, for role: RoomQuestStationRole, note: String) {
        guard let idx = stations.firstIndex(where: { $0.role == role }) else { return }
        stations[idx].referenceCaptureState = state
        stations[idx].referenceNote = note
    }

    private func loadSavedReferenceState() {
        for role in RoomQuestStationRole.allCases {
            guard let savedReference = try? stationStore.reference(for: role),
                  let captureState = savedReference.captureState else { continue }
            setReferenceState(captureState, for: role, note: savedReference.note)
        }
    }

    private var isScanActive: Bool {
        switch scanState {
        case .scanning, .celebrating:
            return true
        case .idle, .almost, .failed:
            return false
        }
    }
}

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
