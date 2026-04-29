import Foundation
import Observation

enum RoomPhase: Equatable {
    case safetyAck                          // one-time parent safety acknowledgement
    case setup                              // parent placing station markers, sees quantities
    case routeNode(index: Int)              // scripted Route Quest node
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
    private(set) var route: RouteQuestRoute?
    private(set) var routeProgress: RouteQuestProgress?

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
    private var routeNodeStartedAt: Date?

    // MARK: - Dependencies

    private let featureFlags: FeatureFlagService
    var settings: FeatureFlagService { featureFlags }
    private let telemetryWriter: TelemetryWriter
    private let speechService: SpeechService
    private let hapticsService: HapticsService
    private let motionService: MotionService?
    private let scanner: RoomQuestScanner
    private let stationStore: RoomQuestStationStore
    var onExitToHome: (() -> Void)?
    private(set) var sessionStartedAt: Date = .now

    private(set) var scanState: RoomQuestScanState = .idle

    static let roomPhaseLimitSeconds: TimeInterval = 4 * 60

    // MARK: - Init

    init(
        featureFlags: FeatureFlagService,
        telemetryWriter: TelemetryWriter,
        speechService: SpeechService,
        hapticsService: HapticsService = HapticsService(),
        motionService: MotionService? = nil,
        scanner: RoomQuestScanner = NoopRoomQuestScanner(),
        stationStore: RoomQuestStationStore
    ) {
        self.featureFlags = featureFlags
        self.telemetryWriter = telemetryWriter
        self.speechService = speechService
        self.hapticsService = hapticsService
        self.motionService = motionService
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
        sessionStartedAt = .now
        route = nil
        routeProgress = nil
        phase = featureFlags.roomQuestSafetyAcknowledged ? .setup : .safetyAck
        feedbackMessage = "Set up the stations, then scan each one or mark it ready."
        if telemetryWriter.currentSessionId == nil {
            try? telemetryWriter.beginSession(sessionId: UUID(), featureFlags: featureFlags)
        }
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
                let result = try await scanner.scanMarker(for: role, mode: .setup, savedReference: nil)
                guard self.captureReference(for: result) else {
                    self.feedbackMessage = "We found \(result.role.title), but could not save its hiding-place reference yet. Try again."
                    self.scanState = .failed(role: role, message: self.feedbackMessage)
                    return
                }
                self.setStationRegistered(result.role, method: .cameraVerified)
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
        stations.count == 2 && stations.allSatisfy(\.isReadyForRoomQuest)
    }

    var missingSetupRequirementsMessage: String {
        let pendingRoles = stations.filter { !$0.isReadyForRoomQuest }.map { $0.role.title }
        guard !pendingRoles.isEmpty else { return "Both stations are ready for Room Quest." }

        if pendingRoles.count == 1 {
            return "Finish setup for \(pendingRoles[0]) before you start."
        }

        return "Finish setup for both stations before you start."
    }

    var currentStation: RoomQuestStation? {
        switch phase {
        case .spot(let index):
            guard stations.indices.contains(index) else { return nil }
            return stations[index]
        case .routeNode:
            guard let node = currentRouteNode,
                  case .station(let role, _) = node.kind
            else { return nil }
            return stations.first { $0.role == role }
        default:
            return nil
        }
    }

    var currentRouteNode: RouteQuestNode? {
        guard let route, let routeProgress else { return nil }
        return routeProgress.currentNode(in: route)
    }

    var currentRouteYaw: Double {
        motionService?.relativeYaw ?? 0
    }

    var routeNodeCount: Int {
        route?.nodes.count ?? 0
    }

    var currentRouteNodeNumber: Int {
        guard let routeProgress else { return 0 }
        return min(routeProgress.currentNodeIndex + 1, routeNodeCount)
    }

    var currentRouteTurnProgressText: String {
        guard let node = currentRouteNode,
              case .turn(let targetDegrees, _) = node.kind
        else { return "" }
        let remaining = CompassMath.angularDistance(currentRouteYaw, targetDegrees)
        return "\(Int(remaining.rounded()))° to go"
    }

    var currentSpotReferenceLabel: String {
        guard let station = currentStation else { return "" }

        switch station.referenceCaptureState {
        case .captured:
            return "Saved camera place for \(station.role.title)"
        case .manualFallback:
            return "No saved camera place for \(station.role.title)"
        case .notCaptured:
            return "Camera place not saved for \(station.role.title)"
        }
    }

    var currentSpotStatusTitle: String {
        guard let station = currentStation else { return "" }

        switch scanState {
        case .almost:
            return "Almost there"
        case .failed:
            return "Not this place yet"
        case .celebrating:
            return "You found it"
        case .scanning:
            return "Checking the camera"
        case .idle:
            return station.referenceCaptureState == .captured ? "Find the saved place" : "Find \(station.role.title)"
        }
    }

    var currentSpotSearchGuidance: String {
        guard let station = currentStation else { return "" }

        switch scanState {
        case .almost(let role, _):
            return "Hold still, move a little closer, and point back at the saved \(role.title) place."
        case .failed(let role, _):
            return "Try again at the saved \(role.title) place. Ask a grown-up to use fallback if the camera keeps missing it."
        case .celebrating(let role, _):
            return "Now collect from the saved \(role.title) place."
        case .scanning(let role):
            return "Keep the camera pointed at \(role.title) until it finishes checking."
        case .idle:
            switch station.referenceCaptureState {
            case .captured:
                return "Walk to the saved \(station.role.title) place and tap 'Recheck' to confirm you're there."
            case .manualFallback:
                return "No camera reference saved for \(station.role.title). Tap 'I found it' when you get there."
            case .notCaptured:
                return "Look for \(station.role.title), then start with a camera check. A grown-up fallback appears if the scan misses."
            }
        }
    }

    var shouldShowSpotManualFallback: Bool {
        guard let station = currentStation else { return false }

        switch scanState {
        case .almost, .failed:
            return true
        case .idle:
            // Show fallback immediately when no camera reference was saved or setup was skipped
            return station.referenceCaptureState == .manualFallback
                || station.referenceCaptureState == .notCaptured
        case .scanning, .celebrating:
            return false
        }
    }

    var currentSpotParentConsentTitle: String {
        switch scanState {
        case .almost:
            return "Grown-up confirms this is the place"
        case .failed:
            return "Grown-up confirms fallback"
        case .idle:
            return currentStation?.role.fallbackButtonTitle ?? "I found it"
        case .scanning, .celebrating:
            return currentStation?.role.fallbackButtonTitle ?? "I found it"
        }
    }

    func acceptCurrentSpotWithParentConsent() {
        let routeStation = currentRouteStationContext()
        let legacyIndex: Int?
        let station: RoomQuestStation?
        if case .spot(let index) = phase {
            legacyIndex = index
            station = stations[safe: index]
        } else {
            legacyIndex = nil
            station = routeStation?.station
        }
        guard let station, shouldShowSpotManualFallback else { return }

        let scanOutcome: String = {
            switch scanState {
            case .almost: return "almost"
            case .failed: return "failed"
            case .idle: return "manual_fallback"
            case .scanning: return "scanning"
            case .celebrating: return "celebrating"
            }
        }()
        try? telemetryWriter.append(SliceEvent(
            type: .interaction,
            payload: [
                "action": "room_quest_parent_consent_accept",
                "station_role": station.role.rawValue,
                "spot_index": legacyIndex.map(String.init) ?? String(routeStation?.node.order ?? 0),
                "scan_outcome": scanOutcome
            ]
        ))
        feedbackMessage = "Grown-up confirmed this place. Collect \(station.quantity) \(station.quantity == 1 ? "token" : "tokens")."
        scanState = .idle
        if let legacyIndex {
            markSpotVisited(index: legacyIndex)
        } else {
            completeCurrentRouteNode(method: .fallback)
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
        if featureFlags.routeQuestEnabled {
            startRouteQuest(problem: p)
        } else {
            phase = .spot(index: 0)
            speechService.speak("Let's make \(p.target)! Find the Red Rocket station and pick up everything there.", enabled: featureFlags.audioEnabled)
        }
        startRoomPhaseTimer()
    }

    private func startRouteQuest(problem: SliceProblem) {
        let nextRoute = routeForCurrentProblem(problem)
        route = nextRoute
        routeProgress = RouteQuestProgress(routeId: nextRoute.id, routeStartedAt: .now)
        try? telemetryWriter.append(SliceEvent(
            type: .routeQuestStarted,
            payload: [
                "route_id": nextRoute.id.uuidString,
                "route_template": nextRoute.templateName,
                "node_count": String(nextRoute.nodes.count)
            ]
        ))
        enterRouteNode(index: 0)
    }

    private func routeForCurrentProblem(_ problem: SliceProblem) -> RouteQuestRoute {
        let baseRoute = RouteQuestRoute.twoStationMVP()
        let nodes = baseRoute.nodes.map { node in
            switch node.kind {
            case .station(.redRocket, _):
                return RouteQuestNode(
                    id: node.id,
                    order: node.order,
                    kind: .station(role: .redRocket, quantity: problem.decompositionA),
                    prompt: "Find Red Rocket and collect \(problem.decompositionA)."
                )
            case .station(.blueBubble, _):
                return RouteQuestNode(
                    id: node.id,
                    order: node.order,
                    kind: .station(role: .blueBubble, quantity: problem.decompositionB),
                    prompt: "Find Blue Bubble and collect \(problem.decompositionB)."
                )
            default:
                return node
            }
        }
        return RouteQuestRoute(id: baseRoute.id, templateName: baseRoute.templateName, nodes: nodes)
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
        let routeStation = currentRouteStationContext()
        let legacyIndex: Int?
        let station: RoomQuestStation?
        if case .spot(let index) = phase {
            legacyIndex = index
            station = stations[safe: index]
        } else {
            legacyIndex = nil
            station = routeStation?.station
        }
        guard let station else { return }

        guard !isScanActive else { return }

        scanState = .scanning(role: station.role)
        feedbackMessage = station.referenceCaptureState == .captured
            ? "Rechecking the saved \(station.role.title) place."
            : "Scan \(station.role.title) to unlock the collect step."

        // Build saved-place reference so the scanner can do photo + GPS comparison.
        let savedRef: RoomQuestSavedReference? = station.referenceCaptureState == .captured
            ? RoomQuestSavedReference(
                imageJPEGData: station.referenceImageJPEGData,
                latitude: station.referenceLatitude,
                longitude: station.referenceLongitude,
                gpsAccuracy: station.referenceGPSAccuracy
              )
            : nil

        Task { @MainActor [weak self] in
            guard let self else { return }
            do {
                let result = try await scanner.scanMarker(for: station.role, mode: .verify, savedReference: savedRef)

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

                self.setReferenceState(
                    .captured,
                    for: station.role,
                    note: "Saved camera reference ready for recheck",
                    referenceImageJPEGData: station.referenceImageJPEGData
                )
                self.scanState = .celebrating(role: result.role, usedARCelebration: result.usedARCelebration)
                self.hapticsService.success(enabled: self.featureFlags.hapticsEnabled)
                self.speechService.speak("You found the saved \(result.role.title) place. Collect \(station.quantity).", enabled: self.featureFlags.audioEnabled)
                self.feedbackMessage = "Found it. Collect \(station.quantity) \(station.quantity == 1 ? "token" : "tokens")."
                try? await Task.sleep(for: .seconds(1.0))
                self.scanState = .idle
                if let legacyIndex {
                    self.markSpotVisited(index: legacyIndex)
                } else {
                    self.completeCurrentRouteNode(method: .scan)
                }
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

    func confirmRouteStart() {
        guard let node = currentRouteNode, case .start = node.kind else { return }
        completeCurrentRouteNode(method: .manual)
    }

    func checkRouteTurn() {
        guard let node = currentRouteNode,
              case .turn(let targetDegrees, let toleranceDegrees) = node.kind
        else { return }
        if CompassMath.isInSnapZone(yaw: currentRouteYaw, target: targetDegrees, tolerance: toleranceDegrees) {
            hapticsService.success(enabled: featureFlags.hapticsEnabled)
            completeCurrentRouteNode(method: .motion, sensorAvailable: motionService != nil)
        } else {
            hapticsService.failure(enabled: featureFlags.hapticsEnabled)
            feedbackMessage = "Turn a little more slowly. \(currentRouteTurnProgressText)."
        }
    }

    func confirmRouteTurnWithParentAssist() {
        guard let node = currentRouteNode, case .turn(_, _) = node.kind else { return }
        completeCurrentRouteNode(method: .parentAssist, sensorAvailable: motionService != nil)
    }

    func confirmRouteSteps() {
        guard let node = currentRouteNode, case .step(_, _) = node.kind else { return }
        completeCurrentRouteNode(method: .manual)
    }

    func confirmRouteReturnHome() {
        guard let node = currentRouteNode, case .returnHome = node.kind else { return }
        completeCurrentRouteNode(method: .manual)
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
        motionService?.stopRelativeYawTracking()
        showCelebration = false
        feedbackMessage = "Paused. Tap Resume when ready."
    }

    func resumeSession() {
        guard case .paused(let resumeTo) = phase else { return }
        phase = resumeTo
        if case .spot(_) = resumeTo { startRoomPhaseTimer() }
        if case .routeNode(_) = resumeTo {
            prepareCurrentRouteNodeForEntry()
            startRoomPhaseTimer()
        }
        if case .returning = resumeTo { startRoomPhaseTimer() }
    }

    func abandonSession(reason: String) {
        roomPhaseTimer?.cancel()
        motionService?.stopRelativeYawTracking()
        try? telemetryWriter.append(SliceEvent(
            type: .roomQuestAbandoned, payload: ["reason": reason]
        ))
        if routeProgress != nil {
            try? telemetryWriter.append(SliceEvent(
                type: .routeQuestAbandoned, payload: ["reason": reason]
            ))
        }
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
        if routeProgress != nil {
            try? telemetryWriter.append(SliceEvent(
                type: .routeQuestAbandoned, payload: ["reason": "timeout"]
            ))
        }
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

    private func enterRouteNode(index: Int) {
        guard let route, route.nodes.indices.contains(index) else {
            markReturned()
            return
        }
        routeProgress?.currentNodeIndex = index
        phase = .routeNode(index: index)
        prepareCurrentRouteNodeForEntry()
    }

    private func prepareCurrentRouteNodeForEntry() {
        guard let route, let node = currentRouteNode else { return }
        routeNodeStartedAt = .now
        scanState = .idle
        feedbackMessage = node.prompt
        if case .turn(_, _) = node.kind {
            motionService?.startUpdates()
            motionService?.startRelativeYawTracking()
        } else {
            motionService?.stopRelativeYawTracking()
        }
        try? telemetryWriter.append(SliceEvent(
            type: .routeQuestNodeStarted,
            payload: RouteQuestTelemetry.payload(
                route: route,
                node: node,
                method: .manual,
                elapsedMilliseconds: 0,
                sensorAvailable: motionService != nil
            )
        ))
        speechService.speak(node.prompt, enabled: featureFlags.audioEnabled)
    }

    private func completeCurrentRouteNode(method: RouteQuestCompletionMethod, sensorAvailable: Bool? = nil) {
        guard let route, var progress = routeProgress, let node = progress.currentNode(in: route) else { return }
        let elapsedMs = routeNodeStartedAt.map { Int(Date.now.timeIntervalSince($0) * 1000) } ?? 0
        let completed = progress.completeCurrentNode(in: route, method: method)
        routeProgress = progress
        motionService?.stopRelativeYawTracking()

        if method == .fallback {
            try? telemetryWriter.append(SliceEvent(
                type: .routeQuestFallbackUsed,
                payload: RouteQuestTelemetry.payload(
                    route: route,
                    node: node,
                    method: method,
                    elapsedMilliseconds: elapsedMs,
                    sensorAvailable: sensorAvailable
                )
            ))
        }
        if completed != nil {
            let completionPayload = RouteQuestTelemetry.payload(
                route: route,
                node: node,
                method: method,
                elapsedMilliseconds: elapsedMs,
                sensorAvailable: sensorAvailable
            )
            let completionEvent: SliceEvent
            switch node.kind {
            case .turn:
                completionEvent = SliceEvent(type: .routeQuestTurnCompleted, payload: completionPayload)
            case .step:
                completionEvent = SliceEvent(type: .routeQuestStepCompleted, payload: completionPayload)
            case .station:
                completionEvent = SliceEvent(type: .routeQuestStationConfirmed, payload: completionPayload)
            case .start, .returnHome:
                var payload = completionPayload
                payload["action"] = "route_quest_node_completed"
                completionEvent = SliceEvent(type: .interaction, payload: payload)
            }
            try? telemetryWriter.append(completionEvent)
        }

        if progress.isComplete(for: route) {
            let routeElapsedMs = Int(Date.now.timeIntervalSince(progress.routeStartedAt) * 1000)
            try? telemetryWriter.append(SliceEvent(
                type: .routeQuestCompleted,
                payload: [
                    "route_id": route.id.uuidString,
                    "route_template": route.templateName,
                    "elapsed_ms": String(routeElapsedMs),
                    "fallback_count": String(progress.fallbackCount)
                ]
            ))
            markReturned()
        } else {
            enterRouteNode(index: progress.currentNodeIndex)
        }
    }

    private func currentRouteStationContext() -> (node: RouteQuestNode, station: RoomQuestStation)? {
        guard case .routeNode(_) = phase,
              let node = currentRouteNode,
              case .station(let role, _) = node.kind,
              let station = stations.first(where: { $0.role == role })
        else { return nil }
        return (node, station)
    }

    private func captureReference(for result: RoomQuestMarkerScanResult) -> Bool {
        guard featureFlags.roomQuestReferenceCaptureEnabled else { return false }

        return persistReferenceState(
            .captured,
            for: result.role,
            markerPayload: result.markerPayload,
            referenceImageJPEGData: result.referenceImageJPEGData,
            referenceLatitude: result.referenceLatitude,
            referenceLongitude: result.referenceLongitude,
            referenceGPSAccuracy: result.referenceGPSAccuracy,
            note: result.referenceImageJPEGData == nil
                ? "Reference saved for \(result.role.title)"
                : "Photo saved for \(result.role.title)"
        )
    }

    @discardableResult
    private func persistReferenceState(
        _ state: RoomQuestReferenceCaptureState,
        for role: RoomQuestStationRole,
        markerPayload: String?,
        referenceImageJPEGData: Data? = nil,
        referenceLatitude: Double? = nil,
        referenceLongitude: Double? = nil,
        referenceGPSAccuracy: Double? = nil,
        note: String
    ) -> Bool {
        let draft = RoomQuestStationReferenceDraft(
            role: role,
            markerPayload: markerPayload,
            referenceImageJPEGData: referenceImageJPEGData,
            referenceLatitude: referenceLatitude,
            referenceLongitude: referenceLongitude,
            referenceGPSAccuracy: referenceGPSAccuracy,
            capturedAt: .now,
            note: note,
            captureState: state
        )

        do {
            try stationStore.save(draft)
            setReferenceState(state, for: role, note: note, referenceImageJPEGData: referenceImageJPEGData, referenceLatitude: referenceLatitude, referenceLongitude: referenceLongitude, referenceGPSAccuracy: referenceGPSAccuracy)
            try? telemetryWriter.append(SliceEvent(
                type: .roomQuestReferenceCaptureCompleted,
                payload: [
                    "station_role": role.rawValue,
                    "saved": String(state == .captured),
                    "capture_state": state.rawValue,
                    "reference_image_present": String(referenceImageJPEGData != nil),
                    "marker_payload_present": String(markerPayload != nil),
                    "gps_present": String(referenceLatitude != nil)
                ]
            ))
            return true
        } catch {
            setReferenceState(.notCaptured, for: role, note: "Reference save failed", referenceImageJPEGData: nil)
            try? telemetryWriter.append(SliceEvent(
                type: .roomQuestReferenceCaptureCompleted,
                payload: [
                    "station_role": role.rawValue,
                    "saved": "false",
                    "capture_state": RoomQuestReferenceCaptureState.notCaptured.rawValue
                ]
            ))
            return false
        }
    }

    private func setReferenceState(
        _ state: RoomQuestReferenceCaptureState,
        for role: RoomQuestStationRole,
        note: String,
        referenceImageJPEGData: Data?,
        referenceLatitude: Double? = nil,
        referenceLongitude: Double? = nil,
        referenceGPSAccuracy: Double? = nil
    ) {
        guard let idx = stations.firstIndex(where: { $0.role == role }) else { return }
        stations[idx].referenceCaptureState = state
        stations[idx].referenceNote = note
        stations[idx].referenceImageJPEGData = referenceImageJPEGData
        stations[idx].referenceLatitude = referenceLatitude
        stations[idx].referenceLongitude = referenceLongitude
        stations[idx].referenceGPSAccuracy = referenceGPSAccuracy
    }

    private func loadSavedReferenceState() {
        for role in RoomQuestStationRole.allCases {
            guard let savedReference = try? stationStore.reference(for: role),
                  let captureState = savedReference.captureState else { continue }
            setReferenceState(
                captureState,
                for: role,
                note: savedReference.note,
                referenceImageJPEGData: savedReference.referenceImageJPEGData,
                referenceLatitude: savedReference.referenceLatitude,
                referenceLongitude: savedReference.referenceLongitude,
                referenceGPSAccuracy: savedReference.referenceGPSAccuracy
            )
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
