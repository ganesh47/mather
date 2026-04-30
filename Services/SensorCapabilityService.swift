import AVFoundation
import CoreHaptics
import CoreLocation
import CoreMotion

enum SensorPermissionState: Equatable, Sendable {
    case notRequired
    case notDetermined
    case restricted
    case denied
    case authorized
    case unknown

    var allowsUse: Bool {
        switch self {
        case .notRequired, .authorized:
            true
        case .notDetermined, .restricted, .denied, .unknown:
            false
        }
    }
}

struct DeviceSensorCapability: Equatable, Sendable {
    let hardwareAvailable: Bool
    let permission: SensorPermissionState

    var isReady: Bool {
        hardwareAvailable && permission.allowsUse
    }

    static func available(permission: SensorPermissionState = .notRequired) -> DeviceSensorCapability {
        DeviceSensorCapability(hardwareAvailable: true, permission: permission)
    }

    static func unavailable(permission: SensorPermissionState = .notRequired) -> DeviceSensorCapability {
        DeviceSensorCapability(hardwareAvailable: false, permission: permission)
    }
}

struct DeviceSensorCapabilities: Equatable, Sendable {
    let motion: DeviceSensorCapability
    let heading: DeviceSensorCapability
    let camera: DeviceSensorCapability
    let lidar: DeviceSensorCapability
    let barometer: DeviceSensorCapability
    let microphone: DeviceSensorCapability
    let haptics: DeviceSensorCapability
    let pencil: DeviceSensorCapability

    static let allUnavailable = DeviceSensorCapabilities(
        motion: .unavailable(),
        heading: .unavailable(),
        camera: .unavailable(permission: .notDetermined),
        lidar: .unavailable(permission: .notDetermined),
        barometer: .unavailable(),
        microphone: .unavailable(permission: .notDetermined),
        haptics: .unavailable(),
        pencil: .unavailable()
    )
}

protocol SensorCapabilityProviding {
    var capabilities: DeviceSensorCapabilities { get }
}

/// Simulator-safe capability snapshot for sensor-driven lanes.
///
/// Inspection is intentionally read-only: this service never starts a capture
/// session, starts motion/location updates, or requests permissions.
final class SensorCapabilityService: SensorCapabilityProviding {
    var capabilities: DeviceSensorCapabilities {
        DeviceSensorCapabilities(
            motion: DeviceSensorCapability(
                hardwareAvailable: CMMotionManager().isDeviceMotionAvailable,
                permission: .notRequired
            ),
            heading: DeviceSensorCapability(
                hardwareAvailable: CLLocationManager.headingAvailable(),
                permission: .notRequired
            ),
            camera: DeviceSensorCapability(
                hardwareAvailable: AVCaptureDevice.default(for: .video) != nil,
                permission: Self.capturePermission(for: .video)
            ),
            lidar: DeviceSensorCapability(
                hardwareAvailable: Self.hasLiDARCamera(),
                permission: Self.capturePermission(for: .video)
            ),
            barometer: DeviceSensorCapability(
                hardwareAvailable: CMAltimeter.isRelativeAltitudeAvailable(),
                permission: .notRequired
            ),
            microphone: DeviceSensorCapability(
                hardwareAvailable: AVCaptureDevice.default(for: .audio) != nil,
                permission: Self.capturePermission(for: .audio)
            ),
            haptics: DeviceSensorCapability(
                hardwareAvailable: CHHapticEngine.capabilitiesForHardware().supportsHaptics,
                permission: .notRequired
            ),
            pencil: DeviceSensorCapability(
                hardwareAvailable: Self.hasPencilSupportPlaceholder(),
                permission: .notRequired
            )
        )
    }

    private static func capturePermission(for mediaType: AVMediaType) -> SensorPermissionState {
        switch AVCaptureDevice.authorizationStatus(for: mediaType) {
        case .notDetermined:
            .notDetermined
        case .restricted:
            .restricted
        case .denied:
            .denied
        case .authorized:
            .authorized
        @unknown default:
            .unknown
        }
    }

    private static func hasLiDARCamera() -> Bool {
#if targetEnvironment(simulator)
        false
#else
        AVCaptureDevice.default(.builtInLiDARDepthCamera, for: .video, position: .back) != nil
#endif
    }

    private static func hasPencilSupportPlaceholder() -> Bool {
        // iOS exposes Pencil interactions, not a reliable passive hardware
        // capability query. Keep this conservative until PencilKit work needs it.
        false
    }
}

struct FixedSensorCapabilityService: SensorCapabilityProviding {
    let capabilities: DeviceSensorCapabilities

    init(capabilities: DeviceSensorCapabilities) {
        self.capabilities = capabilities
    }
}
