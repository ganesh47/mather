import Foundation

enum RoomQuestScanMode {
    case setup    // parent capturing a reference photo during station setup
    case verify   // child confirming they are standing at the right spot
}

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
    func scanMarker(for role: RoomQuestStationRole, mode: RoomQuestScanMode) async throws -> RoomQuestMarkerScanResult
}

struct NoopRoomQuestScanner: RoomQuestScanner {
    func scanMarker(for role: RoomQuestStationRole, mode: RoomQuestScanMode) async throws -> RoomQuestMarkerScanResult {
        throw RoomQuestScannerError.unavailable
    }
}
