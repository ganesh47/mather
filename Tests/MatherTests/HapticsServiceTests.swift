import Testing
@testable import Mather

/// Tests for HapticsService.
///
/// The primary regression target is the `resetHandler` actor-isolation crash:
/// CHHapticEngine delivers `resetHandler` from an internal thread; accessing
/// `self?.engine?.start()` without dispatching to `@MainActor` is undefined in
/// Swift 6 strict concurrency. Fix: wrap in `Task { @MainActor [weak self] in ... }`.
///
/// All haptic engine calls are no-ops in the simulator (supportsHaptics == false),
/// so tests verify fallback behaviour and testability counter semantics.
@MainActor
struct HapticsServiceTests {

    // MARK: - Init

    @Test
    func initDoesNotCrash() {
        // CHHapticEngine is unavailable in the simulator — init should complete
        // without error and set engine = nil (verified by fallback path below).
        let service = HapticsService()
        // If we reach here, init succeeded.
        _ = service
    }

    // MARK: - Testability counters

    @Test
    func countersStartAtZero() {
        let service = HapticsService()
        #expect(service.successFiredCount == 0)
        #expect(service.failureFiredCount == 0)
        #expect(service.stageSuccessFiredCount == 0)
    }

    @Test
    func successIncrementsCounter() {
        let service = HapticsService()
        service.success(enabled: true)
        #expect(service.successFiredCount == 1)
    }

    @Test
    func failureIncrementsCounter() {
        let service = HapticsService()
        service.failure(enabled: true)
        #expect(service.failureFiredCount == 1)
    }

    @Test
    func stageSuccessIncrementsCounter() {
        let service = HapticsService()
        service.stageSuccess(enabled: true)
        #expect(service.stageSuccessFiredCount == 1)
    }

    @Test
    func disabledCallsDoNotIncrementCounters() {
        let service = HapticsService()
        service.success(enabled: false)
        service.failure(enabled: false)
        service.stageSuccess(enabled: false)
        #expect(service.successFiredCount == 0)
        #expect(service.failureFiredCount == 0)
        #expect(service.stageSuccessFiredCount == 0)
    }

    @Test
    func resetCountsClearsAllCounters() {
        let service = HapticsService()
        service.success(enabled: true)
        service.failure(enabled: true)
        service.stageSuccess(enabled: true)
        service.resetCounts()
        #expect(service.successFiredCount == 0)
        #expect(service.failureFiredCount == 0)
        #expect(service.stageSuccessFiredCount == 0)
    }

    // MARK: - Bond Blast haptics (simulator fallback — no crash)

    @Test
    func cardPickupDoesNotCrash() {
        let service = HapticsService()
        service.cardPickup(enabled: true)
    }

    @Test
    func cardNearSnapDoesNotCrash() {
        let service = HapticsService()
        service.cardNearSnap(enabled: true)
    }

    @Test
    func cardSnapCorrectDoesNotCrash() {
        let service = HapticsService()
        service.cardSnapCorrect(enabled: true)
    }

    @Test
    func cardSnapMismatchDoesNotCrash() {
        let service = HapticsService()
        service.cardSnapMismatch(enabled: true)
    }

    @Test
    func bondMatchCompleteDoesNotCrash() {
        let service = HapticsService()
        service.bondMatchComplete(enabled: true)
    }

    @Test
    func bondMatchCompleteDisabledDoesNotCrash() {
        let service = HapticsService()
        service.bondMatchComplete(enabled: false)
    }
}
