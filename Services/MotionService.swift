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

    // MARK: - Private

    // nonisolated(unsafe) avoids a Sendable crossing error: CMMotionManager is not
    // Sendable, but we only ever access it from @MainActor methods, so it is safe.
    nonisolated(unsafe) private let manager = CMMotionManager()
    private var shakeResetTask: Task<Void, Never>?

    // MARK: - Lifecycle

    /// Begin streaming device motion at 30 Hz. Safe to call multiple times.
    func startUpdates() {
        guard manager.isDeviceMotionAvailable, !manager.isDeviceMotionActive else { return }
        manager.deviceMotionUpdateInterval = 1.0 / 30.0
        manager.startDeviceMotionUpdates(to: .main) { [weak self] motion, _ in
            guard let motion else { return }
            MainActor.assumeIsolated {
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
    }

    /// Call after the view has consumed a shake event to prevent re-triggering.
    func resetShake() {
        shakeDetected = false
        shakeResetTask?.cancel()
    }

    // MARK: - Private helpers

    private func applyMotion(_ motion: CMDeviceMotion) {
        tiltPitch = motion.attitude.pitch
        tiltRoll  = motion.attitude.roll

        // Shake detection: userAcceleration excludes gravity.
        // A deliberate device shake exceeds 2.5g on at least one axis.
        let acc = motion.userAcceleration
        let magnitude = (acc.x * acc.x + acc.y * acc.y + acc.z * acc.z).squareRoot()
        if magnitude > 2.5 && !shakeDetected {
            triggerShake()
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
