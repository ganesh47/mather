import Foundation

enum RoomQuestScanMode {
    case setup    // parent capturing a reference photo during station setup
    case verify   // child confirming they are standing at the right spot
}

/// Reference data passed to verify-mode scanner so it can compare the saved place.
struct RoomQuestSavedReference: Equatable {
    let imageJPEGData: Data?
    let latitude: Double?
    let longitude: Double?
    let gpsAccuracy: Double?
}

struct RoomQuestMarkerScanResult: Equatable {
    let role: RoomQuestStationRole
    let markerPayload: String?
    let referenceImageJPEGData: Data?
    let referenceLatitude: Double?
    let referenceLongitude: Double?
    let referenceGPSAccuracy: Double?
    let usedARCelebration: Bool

    init(
        role: RoomQuestStationRole,
        markerPayload: String?,
        referenceImageJPEGData: Data?,
        referenceLatitude: Double? = nil,
        referenceLongitude: Double? = nil,
        referenceGPSAccuracy: Double? = nil,
        usedARCelebration: Bool
    ) {
        self.role = role
        self.markerPayload = markerPayload
        self.referenceImageJPEGData = referenceImageJPEGData
        self.referenceLatitude = referenceLatitude
        self.referenceLongitude = referenceLongitude
        self.referenceGPSAccuracy = referenceGPSAccuracy
        self.usedARCelebration = usedARCelebration
    }
}

enum RoomQuestScannerError: Error, Equatable {
    case cancelled
    case unavailable
    case wrongMarker(expected: RoomQuestStationRole, detected: RoomQuestStationRole)
}

@MainActor
protocol RoomQuestScanner {
    func scanMarker(
        for role: RoomQuestStationRole,
        mode: RoomQuestScanMode,
        savedReference: RoomQuestSavedReference?
    ) async throws -> RoomQuestMarkerScanResult
}

extension RoomQuestScanner {
    /// Convenience — callers that don't need to pass a saved reference.
    func scanMarker(for role: RoomQuestStationRole, mode: RoomQuestScanMode) async throws -> RoomQuestMarkerScanResult {
        try await scanMarker(for: role, mode: mode, savedReference: nil)
    }
}

struct NoopRoomQuestScanner: RoomQuestScanner {
    func scanMarker(for role: RoomQuestStationRole, mode: RoomQuestScanMode, savedReference: RoomQuestSavedReference?) async throws -> RoomQuestMarkerScanResult {
        throw RoomQuestScannerError.unavailable
    }
}
