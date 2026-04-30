import Testing
@testable import Mather

@MainActor
struct SensorCapabilityServiceTests {

    @Test
    func fixedInspectorReturnsInjectedCapabilities() {
        let expected = DeviceSensorCapabilities(
            supportsMotion: true,
            supportsHeading: false,
            supportsCamera: true,
            supportsMicrophone: false,
            supportsHaptics: true,
            supportsBarometer: false,
            supportsLiDAR: false,
            supportsApplePencil: false
        )
        let service = SensorCapabilityService(inspector: FixedSensorCapabilityInspector(capabilities: expected))

        #expect(service.currentCapabilities() == expected)
    }

    @Test
    func unavailableFixtureReportsEveryCapabilityAsUnavailable() {
        let service = SensorCapabilityService(inspector: FixedSensorCapabilityInspector(capabilities: .unavailable))

        #expect(service.currentCapabilities() == .unavailable)
    }

    @Test
    func currentCapabilitiesAsksInspectorOncePerRead() {
        let inspector = CountingSensorCapabilityInspector(capabilities: .unavailable)
        let service = SensorCapabilityService(inspector: inspector)

        _ = service.currentCapabilities()
        _ = service.currentCapabilities()

        #expect(inspector.readCount == 2)
    }

    @Test
    func systemInspectorIsCallableWithoutPermissionPrompts() {
        let service = SensorCapabilityService()
        let capabilities = service.currentCapabilities()

        #expect(capabilities.supportsApplePencil == false)
    }
}

@MainActor
private struct FixedSensorCapabilityInspector: DeviceSensorCapabilityInspecting {
    let capabilities: DeviceSensorCapabilities

    func currentCapabilities() -> DeviceSensorCapabilities {
        capabilities
    }
}

@MainActor
private final class CountingSensorCapabilityInspector: DeviceSensorCapabilityInspecting {
    private(set) var readCount = 0
    private let capabilities: DeviceSensorCapabilities

    init(capabilities: DeviceSensorCapabilities) {
        self.capabilities = capabilities
    }

    func currentCapabilities() -> DeviceSensorCapabilities {
        readCount += 1
        return capabilities
    }
}
