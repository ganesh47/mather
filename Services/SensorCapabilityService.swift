import ARKit
import AVFoundation
import CoreHaptics
import CoreLocation
import CoreMotion
import UIKit

/// Immutable snapshot of device sensors that Explorer Lab activities may depend on.
///
/// These values are hardware capability checks only. They do not represent permission
/// authorization and must be safe to inspect before an activity starts.
struct DeviceSensorCapabilities: Equatable, Sendable {
    let supportsMotion: Bool
    let supportsHeading: Bool
    let supportsCamera: Bool
    let supportsMicrophone: Bool
    let supportsHaptics: Bool
    let supportsBarometer: Bool
    let supportsStepCounting: Bool

    /// LiDAR is currently only a readiness signal for future Explorer Lab lanes.
    let supportsLiDAR: Bool

    /// Apple Pencil capability cannot be reliably detected without interaction.
    /// Keep this conservative until a Pencil-specific lane defines its runtime needs.
    let supportsApplePencil: Bool

    static let unavailable = DeviceSensorCapabilities(
        supportsMotion: false,
        supportsHeading: false,
        supportsCamera: false,
        supportsMicrophone: false,
        supportsHaptics: false,
        supportsBarometer: false,
        supportsStepCounting: false,
        supportsLiDAR: false,
        supportsApplePencil: false
    )
}

@MainActor
protocol DeviceSensorCapabilityInspecting {
    func currentCapabilities() -> DeviceSensorCapabilities
}

/// Reads device hardware availability without starting sensors or asking for permissions.
@MainActor
final class SensorCapabilityService {
    private let inspector: any DeviceSensorCapabilityInspecting

    init(inspector: any DeviceSensorCapabilityInspecting = SystemDeviceSensorCapabilityInspector()) {
        self.inspector = inspector
    }

    func currentCapabilities() -> DeviceSensorCapabilities {
        inspector.currentCapabilities()
    }
}

@MainActor
struct SystemDeviceSensorCapabilityInspector: DeviceSensorCapabilityInspecting {
    func currentCapabilities() -> DeviceSensorCapabilities {
        let motionManager = CMMotionManager()

        return DeviceSensorCapabilities(
            supportsMotion: motionManager.isDeviceMotionAvailable || motionManager.isAccelerometerAvailable,
            supportsHeading: CLLocationManager.headingAvailable(),
            supportsCamera: UIImagePickerController.isSourceTypeAvailable(.camera),
            supportsMicrophone: AVAudioSession.sharedInstance().isInputAvailable,
            supportsHaptics: CHHapticEngine.capabilitiesForHardware().supportsHaptics,
            supportsBarometer: CMAltimeter.isRelativeAltitudeAvailable(),
            supportsStepCounting: CMPedometer.isStepCountingAvailable(),
            supportsLiDAR: ARWorldTrackingConfiguration.supportsSceneReconstruction(.mesh),
            supportsApplePencil: false
        )
    }
}
