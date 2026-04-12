import Foundation
import Testing
@testable import Mather

@MainActor
struct RoomQuestEngineTests {

    // MARK: - Helpers

    private func makeEngine(safetyAcknowledged: Bool = true) -> RoomQuestEngine {
        let flags = FeatureFlagService(defaults: UserDefaults(suiteName: #function)!)
        flags.roomQuestSafetyAcknowledged = safetyAcknowledged
        return RoomQuestEngine(
            featureFlags: flags,
            telemetryWriter: TelemetryWriter(),
            speechService: SpeechService()
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
    func markSetupCompleteTransitionsToFirstSpotAfterRegistration() {
        let engine = makeEngine()
        engine.startSession()
        engine.verifyStationWithCamera(.redRocket)
        engine.confirmStationManually(.blueBubble)
        engine.markSetupComplete()
        #expect(engine.phase == .spot(index: 0))
    }

    @Test
    func stationVerificationTracksCameraVsManualFallback() {
        let engine = makeEngine()
        engine.startSession()
        engine.verifyStationWithCamera(.redRocket)
        engine.confirmStationManually(.blueBubble)

        #expect(engine.stations.first(where: { $0.role == .redRocket })?.verificationMethod == .cameraVerified)
        #expect(engine.stations.first(where: { $0.role == .blueBubble })?.verificationMethod == .manualConfirmed)
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
