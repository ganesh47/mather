import Foundation
import SwiftData
import Testing
@testable import Mather

@MainActor
struct RoomQuestEngineTests {

    // MARK: - Helpers

    private func makeEngine(
        safetyAcknowledged: Bool = true,
        scanner: RoomQuestScanner = NoopRoomQuestScanner(),
        stationStore: RoomQuestStationStore? = nil,
        defaultsSuiteName: String = #function
    ) -> RoomQuestEngine {
        let flags = FeatureFlagService(defaults: UserDefaults(suiteName: defaultsSuiteName)!)
        flags.roomQuestSafetyAcknowledged = safetyAcknowledged
        let resolvedStationStore: RoomQuestStationStore
        if let stationStore {
            resolvedStationStore = stationStore
        } else {
            let container = try! ModelContainer(for: StoredRoomQuestStationReference.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
            resolvedStationStore = RoomQuestStationStore(modelContext: container.mainContext, modelContainer: container)
        }
        return RoomQuestEngine(
            featureFlags: flags,
            telemetryWriter: TelemetryWriter(),
            speechService: SpeechService(),
            scanner: scanner,
            stationStore: resolvedStationStore
        )
    }

    // MARK: - Safety acknowledgement

    @Test
    func startSessionEntersSafetyAckWhenNotYetAcknowledged() {
        let engine = makeEngine(safetyAcknowledged: false)
        engine.startSession()
        #expect(engine.phase == .safetyAck)
    }

    @Test
    func startSessionEntersSetupWhenAlreadyAcknowledged() {
        let engine = makeEngine(safetyAcknowledged: true)
        engine.startSession()
        #expect(engine.phase == .setup)
    }

    @Test
    func acknowledgedSafetyTransitionsToSetup() {
        let engine = makeEngine(safetyAcknowledged: false)
        engine.startSession()
        engine.acknowledgedSafety()
        #expect(engine.phase == .setup)
    }

    // MARK: - Room phase state machine

    @Test
    func markSetupCompleteRequiresBothStationsRegistered() {
        let engine = makeEngine()
        engine.startSession()
        engine.markSetupComplete()
        #expect(engine.phase == .setup)
        #expect(engine.feedbackMessage.localizedCaseInsensitiveContains("both stations"))
    }

    @Test
    func markSetupCompleteTransitionsToFirstSpotAfterRegistration() async throws {
        let engine = makeEngine(scanner: FakeRoomQuestScanner { role in
            RoomQuestMarkerScanResult(role: role, markerPayload: "mather:roomquest:redRocket:v1", referenceImageJPEGData: nil, usedARCelebration: true)
        })
        engine.startSession()
        engine.verifyStationWithCamera(.redRocket)
        try await Task.sleep(for: .milliseconds(1300))
        engine.confirmStationManually(.blueBubble)
        engine.markSetupComplete()
        #expect(engine.phase == .spot(index: 0))
    }

    @Test
    func stationVerificationTracksCameraVsManualFallback() async throws {
        let engine = makeEngine(scanner: FakeRoomQuestScanner { role in
            RoomQuestMarkerScanResult(role: role, markerPayload: "mather:roomquest:redRocket:v1", referenceImageJPEGData: nil, usedARCelebration: false)
        })
        engine.startSession()
        engine.verifyStationWithCamera(.redRocket)
        try await Task.sleep(for: .milliseconds(1300))
        engine.confirmStationManually(.blueBubble)

        #expect(engine.stations.first(where: { $0.role == .redRocket })?.verificationMethod == .cameraVerified)
        #expect(engine.stations.first(where: { $0.role == .blueBubble })?.verificationMethod == .manualConfirmed)
        #expect(engine.stations.first(where: { $0.role == .redRocket })?.referenceCaptureState == .captured)
        #expect(engine.stations.first(where: { $0.role == .blueBubble })?.referenceCaptureState == .manualFallback)
    }

    @Test
    func cameraScanSuccessMarksStationAndCelebrates() async throws {
        let engine = makeEngine(scanner: FakeRoomQuestScanner { role in
            RoomQuestMarkerScanResult(role: role, markerPayload: "mather:roomquest:redRocket:v1", referenceImageJPEGData: nil, usedARCelebration: true)
        })

        engine.startSession()
        engine.acknowledgedSafety()
        engine.verifyStationWithCamera(.redRocket)
        try await Task.sleep(for: .milliseconds(100))

        #expect(engine.stations.first(where: { $0.role == .redRocket })?.verificationMethod == .cameraVerified)
        #expect(engine.stations.first(where: { $0.role == .redRocket })?.referenceCaptureState == .captured)
        if case .celebrating(let role, let usedARCelebration) = engine.scanState {
            #expect(role == .redRocket)
            #expect(usedARCelebration)
        } else {
            Issue.record("Expected celebrating scan state after successful camera scan")
        }
    }

    @Test
    func wrongMarkerLeavesStationUnregisteredAndShowsError() async throws {
        let engine = makeEngine(scanner: FakeRoomQuestScanner { role in
            throw RoomQuestScannerError.wrongMarker(expected: role, detected: .blueBubble)
        })

        engine.startSession()
        engine.acknowledgedSafety()
        engine.verifyStationWithCamera(.redRocket)
        try await Task.sleep(for: .milliseconds(100))

        #expect(engine.stations.first(where: { $0.role == .redRocket })?.verificationMethod == nil)
        if case .failed(let role, let message) = engine.scanState {
            #expect(role == .redRocket)
            #expect(message.contains("Blue Bubble"))
        } else {
            Issue.record("Expected failed scan state after wrong-marker scan")
        }
    }

    @Test
    func markSpotVisitedZeroTransitionsToSpotOne() {
        let engine = makeEngine()
        engine.startSession()
        engine.registerStation(.redRocket)
        engine.registerStation(.blueBubble)
        engine.markSetupComplete()
        engine.markSpotVisited(index: 0)
        #expect(engine.phase == .spot(index: 1))
    }

    @Test
    func verifyCurrentSpotWithCameraUnlocksAndAdvances() async throws {
        let engine = makeEngine(scanner: FakeRoomQuestScanner { role in
            RoomQuestMarkerScanResult(role: role, markerPayload: role == .redRocket ? "mather:roomquest:redRocket:v1" : "mather:roomquest:blueBubble:v1", referenceImageJPEGData: nil, usedARCelebration: false)
        })

        engine.startSession()
        engine.verifyStationWithCamera(.redRocket)
        for _ in 0..<200 {
            let redReady = engine.stations.first(where: { $0.role == .redRocket })?.isRegistered == true
            if redReady, case .idle = engine.scanState { break }
            await Task.yield()
            try await Task.sleep(for: .milliseconds(10))
        }

        engine.verifyStationWithCamera(.blueBubble)
        for _ in 0..<200 {
            let blueReady = engine.stations.first(where: { $0.role == .blueBubble })?.isRegistered == true
            if blueReady, case .idle = engine.scanState { break }
            await Task.yield()
            try await Task.sleep(for: .milliseconds(10))
        }
        engine.markSetupComplete()

        engine.verifyCurrentSpotWithCamera()
        for _ in 0..<200 {
            if engine.phase == .spot(index: 1) { break }
            await Task.yield()
            try await Task.sleep(for: .milliseconds(10))
        }

        #expect(engine.phase == .spot(index: 1))
        #expect(engine.currentStation?.role == .blueBubble)
    }

    @Test
    func verifyCurrentSpotWithWrongMarkerDoesNotAdvance() async throws {
        let engine = makeEngine(scanner: FakeRoomQuestScanner { role in
            throw RoomQuestScannerError.wrongMarker(expected: role, detected: role == .redRocket ? .blueBubble : .redRocket)
        })

        engine.startSession()
        engine.registerStation(.redRocket)
        engine.registerStation(.blueBubble)
        engine.markSetupComplete()

        engine.verifyCurrentSpotWithCamera()
        try await Task.sleep(for: .milliseconds(100))

        #expect(engine.phase == .spot(index: 0))
        if case .failed(let role, let message) = engine.scanState {
            #expect(role == .redRocket)
            #expect(message.contains("Blue Bubble"))
        } else {
            Issue.record("Expected failed scan state after wrong-marker hunt scan")
        }
    }

    @Test
    func verifyCurrentSpotReportsAlmostWhenMarkerPayloadDoesNotMatchSavedReference() async throws {
        let setupScanner = FakeRoomQuestScanner { role in
            RoomQuestMarkerScanResult(
                role: role,
                markerPayload: role == .redRocket ? "mather:roomquest:redRocket:v1" : "mather:roomquest:blueBubble:v1",
                referenceImageJPEGData: nil,
                usedARCelebration: false
            )
        }
        let huntScanner = FakeRoomQuestScanner { role in
            RoomQuestMarkerScanResult(
                role: role,
                markerPayload: role == .redRocket ? "mather:roomquest:redRocket:DIFFERENT" : "mather:roomquest:blueBubble:v1",
                referenceImageJPEGData: nil,
                usedARCelebration: false
            )
        }
        let container = try! ModelContainer(for: StoredRoomQuestStationReference.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        let sharedStationStore = RoomQuestStationStore(modelContext: container.mainContext, modelContainer: container)

        let engine = makeEngine(scanner: setupScanner, stationStore: sharedStationStore, defaultsSuiteName: #function + ".setup")
        engine.startSession()
        engine.verifyStationWithCamera(.redRocket)
        try await Task.sleep(for: .milliseconds(1300))
        engine.confirmStationManually(.blueBubble)
        engine.markSetupComplete()

        try sharedStationStore.save(
            RoomQuestStationReferenceDraft(
                role: .redRocket,
                markerPayload: "mather:roomquest:redRocket:v1",
                referenceImageJPEGData: nil,
                capturedAt: .now,
                note: "Reference saved for Red Rocket",
                captureState: .captured
            )
        )
        try sharedStationStore.save(
            RoomQuestStationReferenceDraft(
                role: .blueBubble,
                markerPayload: nil,
                referenceImageJPEGData: nil,
                capturedAt: .now,
                note: "Manual fallback saved",
                captureState: .manualFallback
            )
        )
        let recheckingEngine = makeEngine(scanner: huntScanner, stationStore: sharedStationStore, defaultsSuiteName: #function + ".recheck")
        recheckingEngine.startSession()
        recheckingEngine.registerStation(.redRocket)
        recheckingEngine.registerStation(.blueBubble)
        recheckingEngine.markSetupComplete()

        recheckingEngine.verifyCurrentSpotWithCamera()
        try await Task.sleep(for: .milliseconds(100))

        #expect(recheckingEngine.phase == .spot(index: 0))
        if case .almost(let role, let message) = recheckingEngine.scanState {
            #expect(role == .redRocket)
            #expect(message.localizedCaseInsensitiveContains("almost"))
            #expect(recheckingEngine.currentSpotReferenceLabel.localizedCaseInsensitiveContains("saved camera place"))
            #expect(recheckingEngine.currentSpotStatusTitle.localizedCaseInsensitiveContains("almost there"))
            #expect(recheckingEngine.currentSpotSearchGuidance.localizedCaseInsensitiveContains("move a little closer"))
        } else {
            Issue.record("Expected almost scan state after saved-reference payload mismatch")
        }
    }

    @Test
    func verifyCurrentSpotUsesSavedReferenceCopyAfterSuccessfulSetupScan() async throws {
        let engine = makeEngine(scanner: FakeRoomQuestScanner { role in
            RoomQuestMarkerScanResult(
                role: role,
                markerPayload: role == .redRocket ? "mather:roomquest:redRocket:v1" : "mather:roomquest:blueBubble:v1",
                referenceImageJPEGData: nil,
                usedARCelebration: false
            )
        })

        engine.startSession()
        engine.verifyStationWithCamera(.redRocket)
        try await Task.sleep(for: .milliseconds(1300))
        engine.confirmStationManually(.blueBubble)
        engine.markSetupComplete()

        #expect(engine.currentSpotReferenceLabel.localizedCaseInsensitiveContains("saved camera place"))
        #expect(engine.currentSpotStatusTitle.localizedCaseInsensitiveContains("find the saved place"))
        #expect(engine.currentSpotSearchGuidance.localizedCaseInsensitiveContains("hold the camera still"))
    }

    @Test
    func cameraSetupPersistsSavedPreviewDataWhenScannerProvidesIt() async throws {
        let expectedJPEGData = Data([0xFF, 0xD8, 0xFF, 0xD9])
        let container = try! ModelContainer(for: StoredRoomQuestStationReference.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        let sharedStationStore = RoomQuestStationStore(modelContext: container.mainContext, modelContainer: container)
        let engine = makeEngine(
            scanner: FakeRoomQuestScanner { role in
                RoomQuestMarkerScanResult(
                    role: role,
                    markerPayload: "mather:roomquest:redRocket:v1",
                    referenceImageJPEGData: expectedJPEGData,
                    usedARCelebration: false
                )
            },
            stationStore: sharedStationStore,
            defaultsSuiteName: #function
        )

        engine.startSession()
        engine.verifyStationWithCamera(.redRocket)
        try await Task.sleep(for: .milliseconds(1300))

        #expect(engine.stations.first(where: { $0.role == .redRocket })?.referenceImageJPEGData == expectedJPEGData)
        #expect(try sharedStationStore.reference(for: .redRocket)?.referenceImageJPEGData == expectedJPEGData)
    }

    @Test
    func setupRequiresSavedReferenceStateForEveryStation() {
        var station = RoomQuestStation(id: .redRocket, role: .redRocket, quantity: 5)
        station.isRegistered = true

        #expect(!station.isReadyForRoomQuest)

        station.referenceCaptureState = .manualFallback
        #expect(station.isReadyForRoomQuest)
    }

    @Test
    func verifyCurrentSpotIgnoresDuplicateScanRequestsWhileScanIsActive() async throws {
        let tracker = ScanTracker()
        let scanner = FakeRoomQuestScanner { role in
            await tracker.markStarted()
            while !(await tracker.canFinish) {
                try await Task.sleep(for: .milliseconds(20))
            }
            return RoomQuestMarkerScanResult(
                role: role,
                markerPayload: role == .redRocket ? "mather:roomquest:redRocket:v1" : "mather:roomquest:blueBubble:v1",
                referenceImageJPEGData: nil,
                usedARCelebration: false
            )
        }

        let engine = makeEngine(scanner: scanner)
        engine.startSession()
        engine.registerStation(.redRocket)
        engine.registerStation(.blueBubble)
        engine.markSetupComplete()

        engine.verifyCurrentSpotWithCamera()
        engine.verifyCurrentSpotWithCamera()
        try await Task.sleep(for: .milliseconds(100))

        #expect(await tracker.startCount == 1)
        #expect(engine.phase == .spot(index: 0))

        await tracker.allowFinish()
        try await Task.sleep(for: .milliseconds(1200))

        #expect(engine.phase == .spot(index: 1))
    }

    @Test
    func markSpotVisitedOneTransitionsToReturning() {
        let engine = makeEngine()
        engine.startSession()
        engine.registerStation(.redRocket)
        engine.registerStation(.blueBubble)
        engine.markSetupComplete()
        engine.markSpotVisited(index: 0)
        engine.markSpotVisited(index: 1)
        #expect(engine.phase == .returning)
    }

    @Test
    func markReturnedTransitionsToPictorialAndPrePopulatesSplit() {
        let engine = makeEngine()
        engine.startSession()
        guard let p = engine.problem else { return }
        engine.registerStation(.redRocket)
        engine.registerStation(.blueBubble)
        engine.markSetupComplete()
        engine.markSpotVisited(index: 0)
        engine.markSpotVisited(index: 1)
        engine.markReturned()
        #expect(engine.phase == .onScreenPictorial)
        #expect(engine.splitLeftCount == p.decompositionA)
    }

    // MARK: - On-screen CPA

    @Test
    func submitPictorialTransitionsToAbstract() {
        let engine = makeEngine()
        engine.startSession()
        engine.registerStation(.redRocket)
        engine.registerStation(.blueBubble)
        engine.markSetupComplete()
        engine.markSpotVisited(index: 0)
        engine.markSpotVisited(index: 1)
        engine.markReturned()
        engine.submitPictorial()
        #expect(engine.phase == .onScreenAbstract)
    }

    @Test
    func correctAbstractInputTransitionsToTransfer() {
        let engine = makeEngine()
        engine.startSession()
        guard let p = engine.problem else { return }
        engine.registerStation(.redRocket)
        engine.registerStation(.blueBubble)
        engine.markSetupComplete()
        engine.markSpotVisited(index: 0)
        engine.markSpotVisited(index: 1)
        engine.markReturned()
        engine.submitPictorial()
        engine.equationLeftInput = String(p.decompositionA)
        engine.equationRightInput = String(p.decompositionB)
        engine.submitAbstract()
        #expect(engine.phase == .onScreenTransfer)
    }

    @Test
    func wrongAbstractInputStaysAbstractWithFeedback() {
        let engine = makeEngine()
        engine.startSession()
        engine.registerStation(.redRocket)
        engine.registerStation(.blueBubble)
        engine.markSetupComplete()
        engine.markSpotVisited(index: 0)
        engine.markSpotVisited(index: 1)
        engine.markReturned()
        engine.submitPictorial()
        engine.equationLeftInput = "0"
        engine.equationRightInput = "0"
        engine.submitAbstract()
        #expect(engine.phase == .onScreenAbstract)
        #expect(engine.feedbackMessage.localizedCaseInsensitiveContains("Try again"))
    }

    @Test
    func submitTransferTransitionsToComplete() {
        let engine = makeEngine()
        engine.startSession()
        guard let p = engine.problem else { return }
        engine.registerStation(.redRocket)
        engine.registerStation(.blueBubble)
        engine.markSetupComplete()
        engine.markSpotVisited(index: 0)
        engine.markSpotVisited(index: 1)
        engine.markReturned()
        engine.submitPictorial()
        engine.equationLeftInput = String(p.decompositionA)
        engine.equationRightInput = String(p.decompositionB)
        engine.submitAbstract()
        engine.transferLeftCount = p.decompositionA
        engine.transferRightCount = p.decompositionB
        engine.submitTransfer()
        #expect(engine.phase == .complete)
    }

    // MARK: - Pause / resume

    @Test
    func pauseAndResumeRestoresSpotPhase() {
        let engine = makeEngine()
        engine.startSession()
        engine.registerStation(.redRocket)
        engine.registerStation(.blueBubble)
        engine.markSetupComplete()
        engine.markSpotVisited(index: 0)
        // Phase is now .spot(index: 1)
        engine.pauseSession()
        #expect(engine.phase == .paused(resumingTo: .spot(index: 1)))
        engine.resumeSession()
        #expect(engine.phase == .spot(index: 1))
    }

    @Test
    func abandonSessionCallsExitCallback() {
        let engine = makeEngine()
        engine.startSession()
        engine.registerStation(.redRocket)
        engine.registerStation(.blueBubble)
        engine.markSetupComplete()

        var exitCalled = false
        engine.onExitToHome = { exitCalled = true }

        engine.abandonSession(reason: "parent_abort")
        #expect(engine.phase == .complete)
        #expect(exitCalled)
    }
}

private actor ScanTracker {
    private(set) var startCount = 0
    private(set) var canFinish = false

    func markStarted() {
        startCount += 1
    }

    func allowFinish() {
        canFinish = true
    }
}

private struct FakeRoomQuestScanner: RoomQuestScanner {
    let handler: @MainActor (RoomQuestStationRole) async throws -> RoomQuestMarkerScanResult

    func scanMarker(for role: RoomQuestStationRole) async throws -> RoomQuestMarkerScanResult {
        try await handler(role)
    }
}
