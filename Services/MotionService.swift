import CoreMotion
import Observation

/// Wraps CMMotionManager with @MainActor isolation.
///
/// Delivers device attitude (pitch/roll) for tilt drift and detects
/// shake gestures for the Bond Blast shuffle mechanic. No permissions
/// required — CoreMotion device motion is always available.
///
/// Start/stop lifecycle is managed by BondMatchView via onAppear/onDisappear.
@MainActor
@Observable
final class MotionService {

    // MARK: - Observable state

    /// Pitch (forward/backward tilt) in radians. Positive = top tilts away.
    var tiltPitch: Double = 0
    /// Roll (left/right tilt) in radians. Positive = right side tilts down.
    var tiltRoll: Double = 0
    /// Set to true for one shake event, then auto-resets after 500 ms.
    var shakeDetected: Bool = false
    /// Body-relative yaw in degrees (0 at start, positive = turned right).
    /// Updated only while `startRelativeYawTracking()` has been called.
    /// Requires `startUpdates()` to already be active.
    var relativeYaw: Double = 0

    /// True after at least one yaw update has been received since the last `startRelativeYawTracking()` call.
    /// Views can watch this to detect silent motion failures on iOS 26+ devices.
    private(set) var relativeYawResponsive = false

    // MARK: - Private

    // nonisolated(unsafe) avoids a Sendable crossing error: CMMotionManager is not
    // Sendable, but we only ever access it from @MainActor methods, so it is safe.
    nonisolated(unsafe) private let manager = CMMotionManager()
    private var shakeResetTask: Task<Void, Never>?
    nonisolated(unsafe) private var referenceAttitude: CMAttitude? = nil
    private(set) var trackingRelativeYaw = false

    // MARK: - Lifecycle

    /// Begin streaming device motion at 30 Hz. Safe to call multiple times.
    func startUpdates() {
        guard manager.isDeviceMotionAvailable, !manager.isDeviceMotionActive else { return }
        manager.deviceMotionUpdateInterval = 1.0 / 30.0
        manager.startDeviceMotionUpdates(to: .main) { [weak self] motion, _ in
            guard let motion else { return }
            Task { @MainActor [weak self] in
                self?.applyMotion(motion)
            }
        }
    }

    /// Stop all device motion updates and reset tilt state.
    func stopUpdates() {
        manager.stopDeviceMotionUpdates()
        shakeResetTask?.cancel()
        tiltPitch = 0
        tiltRoll = 0
        shakeDetected = false
        relativeYaw = 0
        referenceAttitude = nil
        trackingRelativeYaw = false
    }

    /// Begin tracking body-relative yaw. Call after `startUpdates()`.
    /// Captures the current attitude as reference on the next motion callback.
    func startRelativeYawTracking() {
        referenceAttitude = nil
        relativeYaw = 0
        relativeYawResponsive = false
        trackingRelativeYaw = true
    }

    /// Stop tracking relative yaw without stopping all device-motion updates.
    func stopRelativeYawTracking() {
        trackingRelativeYaw = false
        referenceAttitude = nil
        relativeYaw = 0
        relativeYawResponsive = false
    }

    // Exposed for test injection only — do not call from production views.
    func applyRelativeYaw(_ yaw: Double) {
        relativeYaw = yaw
    }

    /// Call after the view has consumed a shake event to prevent re-triggering.
    func resetShake() {
        shakeDetected = false
        shakeResetTask?.cancel()
    }

    // MARK: - Internal helpers (visible for testing)

    /// Apply pre-computed motion values. Extracted so unit tests can drive state
    /// without needing a real CMMotionManager or device hardware.
    func applyMotionValues(pitch: Double, roll: Double, accelerationMagnitude: Double) {
        tiltPitch = pitch
        tiltRoll  = roll
        if accelerationMagnitude > 2.5 && !shakeDetected {
            triggerShake()
        }
    }

    /// Convert CoreMotion's reference-relative attitude yaw to the app's
    /// child-facing body-turn convention: positive means the child turned right.
    ///
    /// `CMAttitude.yaw` increases in the opposite direction from the Compass
    /// Angles UI/copy contract, so keep the sign flip at the sensor boundary
    /// instead of mirroring individual game views.
    nonisolated static func bodyRelativeYawDegrees(fromCoreMotionYawRadians yaw: Double) -> Double {
        -(yaw * 180 / .pi)
    }

    // MARK: - Private helpers

    private func applyMotion(_ motion: CMDeviceMotion) {
        let acc = motion.userAcceleration
        let magnitude = (acc.x * acc.x + acc.y * acc.y + acc.z * acc.z).squareRoot()
        applyMotionValues(
            pitch: motion.attitude.pitch,
            roll: motion.attitude.roll,
            accelerationMagnitude: magnitude
        )

        guard trackingRelativeYaw else { return }
        if referenceAttitude == nil {
            referenceAttitude = motion.attitude.copy() as? CMAttitude
        }
        if let ref = referenceAttitude {
            let current = motion.attitude.copy() as! CMAttitude
            current.multiply(byInverseOf: ref)
            relativeYaw = Self.bodyRelativeYawDegrees(fromCoreMotionYawRadians: current.yaw)
            relativeYawResponsive = true
        }
    }

    private func triggerShake() {
        shakeDetected = true
        shakeResetTask?.cancel()
        shakeResetTask = Task { @MainActor [weak self] in
            try? await Task.sleep(for: .milliseconds(600))
            self?.shakeDetected = false
        }
    }
}
