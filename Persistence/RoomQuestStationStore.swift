import Foundation
import SwiftData

@MainActor
final class RoomQuestStationStore {
    private let modelContainer: ModelContainer?
    private let modelContext: ModelContext

    init(modelContext: ModelContext, modelContainer: ModelContainer? = nil) {
        self.modelContainer = modelContainer
        self.modelContext = modelContext
    }

    func save(_ draft: RoomQuestStationReferenceDraft) throws {
        let roleRaw = draft.role.rawValue
        let descriptor = FetchDescriptor<StoredRoomQuestStationReference>(
            predicate: #Predicate { $0.roleRawValue == roleRaw }
        )

        if let existing = try modelContext.fetch(descriptor).first {
            existing.markerPayload = draft.markerPayload
            existing.capturedAt = draft.capturedAt
            existing.note = draft.note
            existing.imageJPEGData = draft.imageJPEGData
        } else {
            modelContext.insert(
                StoredRoomQuestStationReference(
                    role: draft.role,
                    markerPayload: draft.markerPayload,
                    capturedAt: draft.capturedAt,
                    note: draft.note,
                    imageJPEGData: draft.imageJPEGData
                )
            )
        }

        try modelContext.save()
    }

    func reference(for role: RoomQuestStationRole) throws -> StoredRoomQuestStationReference? {
        let roleRaw = role.rawValue
        let descriptor = FetchDescriptor<StoredRoomQuestStationReference>(
            predicate: #Predicate { $0.roleRawValue == roleRaw }
        )
        return try modelContext.fetch(descriptor).first
    }

    func clearAll() throws {
        let descriptor = FetchDescriptor<StoredRoomQuestStationReference>()
        for item in try modelContext.fetch(descriptor) {
            modelContext.delete(item)
        }
        try modelContext.save()
    }
}
