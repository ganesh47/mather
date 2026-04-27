import Testing
@testable import Mather

/// Regression tests for MotionService actor-isolation safety.
///
/// The primary regression target is the Bond Blast crash (issues #155, #158, #159, #160, #162)
/// caused by `MainActor.assumeIsolated` trapping on iOS 26 when the CMMotionManager
/// delivery context no longer satisfies the Swift 6.2 main-actor executor check.
///
/// The fix replaces `assumeIsolated` with `Task { @MainActor in ... }`, which dispatches
/// safely regardless of which executor the CMMotionManager callback runs on.
///
/// These tests drive `applyMotionValues(pitch:roll:accelerationMagnitude:)` directly —
/// the internal method extracted to make state updates testable without hardware.
@MainActor
struct MotionServiceTests {

    // MARK: - applyMotionValues — tilt state

    @Test
    func applyMotionValuesSetsCorrectTiltState() {
        let service = MotionService()
        service.applyMotionValues(pitch: 0.3, roll: -0.1, accelerationMagnitude: 0.2)
        #expect(service.tiltPitch == 0.3)
        #expect(service.tiltRoll  == -0.1)
    }

    @Test
    func applyMotionValuesUpdatesOnEachCall() {
        let service = MotionService()
        service.applyMotionValues(pitch: 0.1, roll: 0.2, accelerationMagnitude: 0.0)
        service.applyMotionValues(pitch: 0.5, roll: -0.5, accelerationMagnitude: 0.0)
        #expect(service.tiltPitch == 0.5)
        #expect(service.tiltRoll  == -0.5)
    }

    // MARK: - Relative yaw conversion

    @Test
    func coreMotionNegativeYawMapsToRightTurn() {
        let degrees = MotionService.bodyRelativeYawDegrees(fromCoreMotionDeltaYawRadians: -.pi / 2)
        #expect(abs(degrees - 90) < 0.01)
    }

    @Test
    func coreMotionPositiveYawMapsToLeftTurn() {
        let degrees = MotionService.bodyRelativeYawDegrees(fromCoreMotionDeltaYawRadians: .pi / 2)
        #expect(abs(degrees - (-90)) < 0.01)
    }

    // MARK: - Shake detection

    @Test
    func belowThresholdDoesNotTriggerShake() {
        let service = MotionService()
        service.applyMotionValues(pitch: 0, roll: 0, accelerationMagnitude: 1.0)
        #expect(!service.shakeDetected)
    }

    @Test
    func aboveThresholdTriggersShake() {
        let service = MotionService()
        service.applyMotionValues(pitch: 0, roll: 0, accelerationMagnitude: 3.0)
        #expect(service.shakeDetected)
    }

    @Test
    func shakeDoesNotRetriggerWhileAlreadyDetected() {
        let service = MotionService()
        service.applyMotionValues(pitch: 0, roll: 0, accelerationMagnitude: 3.0)
        #expect(service.shakeDetected)
        // A second large shake while shakeDetected=true should not cause any error.
        // The guard `!shakeDetected` in applyMotionValues prevents double-trigger.
        service.applyMotionValues(pitch: 0, roll: 0, accelerationMagnitude: 3.0)
        #expect(service.shakeDetected) // still true, no crash
    }

    @Test
    func resetShakeClearsFlag() {
        let service = MotionService()
        service.applyMotionValues(pitch: 0, roll: 0, accelerationMagnitude: 3.0)
        service.resetShake()
        #expect(!service.shakeDetected)
    }

    // MARK: - stopUpdates resets state

    @Test
    func stopUpdatesResetsTiltAndShakeState() {
        let service = MotionService()
        service.applyMotionValues(pitch: 0.4, roll: -0.3, accelerationMagnitude: 3.0)
        service.stopUpdates()
        #expect(service.tiltPitch == 0)
        #expect(service.tiltRoll  == 0)
        #expect(!service.shakeDetected)
    }

    // MARK: - Background-thread dispatch safety
    //
    // This test proves that `Task { @MainActor in ... }` reaches the main actor
    // safely from a detached background task — the pattern that replaced
    // `MainActor.assumeIsolated`, which would fatal-trap in the same scenario.

    @Test
    func applyMotionValuesReachesMainActorFromBackgroundTask() async {
        let service = MotionService()
        await withCheckedContinuation { continuation in
            Task.detached {
                // Simulate what a CMMotionManager callback does after the fix:
                // dispatch to main actor via Task, not assumeIsolated.
                Task { @MainActor in
                    service.applyMotionValues(pitch: 0.7, roll: 0.0, accelerationMagnitude: 0.0)
                    continuation.resume()
                }
            }
        }
        #expect(service.tiltPitch == 0.7)
    }
}
