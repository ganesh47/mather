import Foundation

struct RoomQuestMarkerScanResult: Equatable {
    let role: RoomQuestStationRole
    let markerPayload: String?
    let referenceImageJPEGData: Data?
    let usedARCelebration: Bool
}

enum RoomQuestScannerError: Error, Equatable {
    case cancelled
    case unavailable
    case wrongMarker(expected: RoomQuestStationRole, detected: RoomQuestStationRole)
}

@MainActor
protocol RoomQuestScanner {
    func scanMarker(for role: RoomQuestStationRole) async throws -> RoomQuestMarkerScanResult
}

struct NoopRoomQuestScanner: RoomQuestScanner {
    func scanMarker(for role: RoomQuestStationRole) async throws -> RoomQuestMarkerScanResult {
        throw RoomQuestScannerError.unavailable
    }
}
