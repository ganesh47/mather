import AVFoundation
import Testing
@testable import Mather

struct SensorCapabilityServiceTests {

    @Test
    func readinessRequiresHardwareAndUsablePermission() {
        #expect(DeviceSensorCapability.available().isReady)
        #expect(DeviceSensorCapability.available(permission: .authorized).isReady)
        #expect(!DeviceSensorCapability.available(permission: .notDetermined).isReady)
        #expect(!DeviceSensorCapability.available(permission: .denied).isReady)
        #expect(!DeviceSensorCapability.unavailable().isReady)
    }

    @Test
    func fixedServiceReturnsInjectedCapabilities() {
        let expected = DeviceSensorCapabilities(
            motion: .available(),
            heading: .available(),
            camera: .available(permission: .authorized),
            lidar: .unavailable(permission: .authorized),
            barometer: .available(),
            microphone: .available(permission: .denied),
            haptics: .unavailable(),
            pencil: .unavailable()
        )

        let service = FixedSensorCapabilityService(capabilities: expected)

        #expect(service.capabilities == expected)
        #expect(service.capabilities.motion.isReady)
        #expect(!service.capabilities.lidar.isReady)
        #expect(!service.capabilities.microphone.isReady)
    }

    @Test
    func allUnavailableFixtureCoversEverySensorField() {
        let capabilities = DeviceSensorCapabilities.allUnavailable

        #expect(!capabilities.motion.isReady)
        #expect(!capabilities.heading.isReady)
        #expect(!capabilities.camera.isReady)
        #expect(!capabilities.lidar.isReady)
        #expect(!capabilities.barometer.isReady)
        #expect(!capabilities.microphone.isReady)
        #expect(!capabilities.haptics.isReady)
        #expect(!capabilities.pencil.isReady)
    }

    @Test
    func platformServiceSnapshotDoesNotRequestCapturePermissions() {
        let cameraBefore = AVCaptureDevice.authorizationStatus(for: .video)
        let microphoneBefore = AVCaptureDevice.authorizationStatus(for: .audio)

        let capabilities = SensorCapabilityService().capabilities

        let cameraAfter = AVCaptureDevice.authorizationStatus(for: .video)
        let microphoneAfter = AVCaptureDevice.authorizationStatus(for: .audio)

        #expect(cameraAfter == cameraBefore)
        #expect(microphoneAfter == microphoneBefore)
        #expect(capabilities.camera.permission == SensorPermissionState(captureAuthorizationStatus: cameraAfter))
        #expect(capabilities.microphone.permission == SensorPermissionState(captureAuthorizationStatus: microphoneAfter))
    }
}

private extension SensorPermissionState {
    init(captureAuthorizationStatus status: AVAuthorizationStatus) {
        switch status {
        case .notDetermined:
            self = .notDetermined
        case .restricted:
            self = .restricted
        case .denied:
            self = .denied
        case .authorized:
            self = .authorized
        @unknown default:
            self = .unknown
        }
    }
}
