import Foundation
import SwiftData

/// Read-only freshness migration input. Aggregate exposure can prevent a fresh
/// claim, but never creates an answer, parent report or mastery event.
@MainActor
enum QuestPriorEvidenceReader {
    static func attempts(profileID: String, context: ModelContext) -> [ItemAttempt]? {
        let descriptor = FetchDescriptor<StoredGameplayProgressRecord>(predicate: #Predicate { $0.profileId == profileID })
        guard let records = try? context.fetch(descriptor) else { return nil }
        var attempts: [ItemAttempt] = []
        for record in records {
            guard let quest = LearningQuestID.allCases.first(where: { $0.activityID == record.threadId }) else { continue }
            let journal: [ItemAttempt]
            if let data = record.itemAttemptsData {
                guard let decoded = try? JSONDecoder().decode([ItemAttempt].self, from: data),
                      decoded.allSatisfy({ $0.profileID == nil || $0.profileID == profileID }) else { return nil }
                journal = decoded
                attempts += decoded
            } else { journal = [] }
            if (journal.isEmpty || journal.contains(where: { $0.itemVariantID == nil })),
               record.exposureCount > 0 || record.correctCount > 0 || record.incorrectCount > 0 || record.supportedCorrectCount > 0 {
                // This transient marker is used only to conservatively seed seen
                // default probes. The stored journal and its metadata stay intact.
                attempts.append(ItemAttempt(activityID: record.threadId, conceptID: quest.conceptID,
                    entityID: record.entityId, propertyID: record.propertyId, stageID: record.stageId,
                    outcome: .exposure, occurredAt: record.firstSeenAt, profileID: profileID,
                    sessionID: "legacy-seen-" + record.uniqueKey, contentVersion: max(1, record.evidenceContentVersion)))
            }
        }
        return attempts
    }
}
