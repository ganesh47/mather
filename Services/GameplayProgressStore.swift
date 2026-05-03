import Foundation
import Observation
import SwiftData

@MainActor
@Observable
final class GameplayProgressStore {
    private let modelContext: ModelContext
    private let activeProfileIdProvider: () -> String
    private let encoder = JSONEncoder()

    init(modelContext: ModelContext, activeProfileIdProvider: @escaping () -> String) {
        self.modelContext = modelContext
        self.activeProfileIdProvider = activeProfileIdProvider
    }

    convenience init(modelContext: ModelContext) {
        self.init(modelContext: modelContext, activeProfileIdProvider: { KidProfileStore.defaultProfileId })
    }

    func records(forThread threadID: String, stageID: String? = nil) -> [GameplayExposureKey: GameplayExposureRecord] {
        let profileId = activeProfileIdProvider()
        let descriptor = FetchDescriptor<StoredGameplayProgressRecord>(
            predicate: #Predicate { $0.profileId == profileId && $0.threadId == threadID }
        )
        let stored = ((try? modelContext.fetch(descriptor)) ?? [])
            .filter { stageID == nil || $0.stageId == stageID }
        return Dictionary(uniqueKeysWithValues: stored.map { ($0.exposureKey, $0.exposureRecord) })
    }

    func storedRecords(forThread threadID: String) -> [StoredGameplayProgressRecord] {
        let profileId = activeProfileIdProvider()
        let descriptor = FetchDescriptor<StoredGameplayProgressRecord>(
            predicate: #Predicate { $0.profileId == profileId && $0.threadId == threadID },
            sortBy: [SortDescriptor(\StoredGameplayProgressRecord.nextDueAt)]
        )
        return (try? modelContext.fetch(descriptor)) ?? []
    }

    func makeRound(
        thread: GameplayThreadDefinition,
        stage: GameplayStageDefinition,
        now: Date = Date(),
        seed: UInt64 = 0,
        policy: SpacedRepetitionSelectionPolicy? = nil
    ) -> GameplayRoundDefinition {
        SpacedRepetitionScheduler.makeRound(
            thread: thread,
            stage: stage,
            records: records(forThread: thread.id, stageID: stage.id),
            now: now,
            seed: seed,
            policy: policy
        )
    }

    func markExposed(thread: GameplayThreadDefinition, stage: GameplayStageDefinition, items: [GameplayRoundItem], at date: Date = Date()) {
        for item in items {
            let key = SpacedRepetitionScheduler.recordKey(for: item, stageID: stage.id)
            let stored = progressRecord(for: key, threadID: thread.id) ?? makeStoredRecord(for: key, thread: thread, stage: stage, firstSeenAt: date)
            stored.exposureCount += 1
            stored.lastSeenAt = date
            if stored.firstSeenAt > date { stored.firstSeenAt = date }
            if stored.modelContext == nil { modelContext.insert(stored) }
        }
        try? modelContext.save()
    }

    func apply(
        updates: [SpacedRepetitionUpdate],
        thread: GameplayThreadDefinition,
        stageInterval: TimeInterval = 60 * 60 * 24,
        hintsByKey: [GameplayExposureKey: Int] = [:],
        metadataByKey: [GameplayExposureKey: String] = [:]
    ) {
        var current = records(forThread: thread.id)
        for update in updates {
            current = SpacedRepetitionScheduler.applying(updates: [update], to: current, stageInterval: stageInterval)
            guard let record = current[update.key] else { continue }
            let stage = thread.stages.first { $0.id == update.key.stageID } ?? GameplayStageDefinition(id: update.key.stageID, kind: .flashcards, title: update.key.stageID, prompt: "")
            let stored = progressRecord(for: update.key, threadID: thread.id) ?? makeStoredRecord(for: update.key, thread: thread, stage: stage, firstSeenAt: update.occurredAt)
            stored.apply(record: record)
            stored.exposureCount = max(stored.exposureCount + 1, record.attemptCount)
            stored.hintCount += hintsByKey[update.key] ?? 0
            stored.lastStageId = update.key.stageID
            stored.lastResultMetadata = metadataByKey[update.key]
            if stored.modelContext == nil { modelContext.insert(stored) }
        }
        try? modelContext.save()
    }

    func dueAndWeakRecords(threadID: String, now: Date = Date(), limit: Int = 12) -> [StoredGameplayProgressRecord] {
        storedRecords(forThread: threadID)
            .filter { $0.nextDueAt <= now || $0.confidenceBand == .reviewNeeded || $0.confidenceBand == .learning }
            .sorted { lhs, rhs in
                if lhs.confidencePriority != rhs.confidencePriority { return lhs.confidencePriority < rhs.confidencePriority }
                if lhs.nextDueAt != rhs.nextDueAt { return lhs.nextDueAt < rhs.nextDueAt }
                return lhs.uniqueKey < rhs.uniqueKey
            }
            .prefix(max(0, limit))
            .map { $0 }
    }

    @discardableResult
    func saveThreadSession(
        thread: GameplayThreadDefinition,
        startedAt: Date,
        endedAt: Date = Date(),
        results: [GameplayStageResult]
    ) -> StoredGameplayThreadSession {
        let summary = GameplayScoreSummary.summarize(results)
        let completedStageIDs = results.map(\.stageID)
        let session = StoredGameplayThreadSession(
            profileId: activeProfileIdProvider(),
            threadId: thread.id,
            startedAt: startedAt,
            endedAt: endedAt,
            durationSeconds: endedAt.timeIntervalSince(startedAt),
            completedStageIdsData: try? encoder.encode(completedStageIDs),
            totalScore: summary.scorePoints,
            stars: summary.stars,
            stageSummaryData: try? encoder.encode(results)
        )
        modelContext.insert(session)
        try? modelContext.save()
        return session
    }

    func threadSessions(forThread threadID: String) -> [StoredGameplayThreadSession] {
        let profileId = activeProfileIdProvider()
        let descriptor = FetchDescriptor<StoredGameplayThreadSession>(
            predicate: #Predicate { $0.profileId == profileId && $0.threadId == threadID },
            sortBy: [SortDescriptor(\StoredGameplayThreadSession.startedAt, order: .reverse)]
        )
        return (try? modelContext.fetch(descriptor)) ?? []
    }

    private func progressRecord(for key: GameplayExposureKey, threadID: String) -> StoredGameplayProgressRecord? {
        let profileId = activeProfileIdProvider()
        let uniqueKey = Self.uniqueKey(profileId: profileId, threadID: threadID, key: key)
        var descriptor = FetchDescriptor<StoredGameplayProgressRecord>(
            predicate: #Predicate { $0.uniqueKey == uniqueKey }
        )
        descriptor.fetchLimit = 1
        return try? modelContext.fetch(descriptor).first
    }

    private func makeStoredRecord(for key: GameplayExposureKey, thread: GameplayThreadDefinition, stage: GameplayStageDefinition, firstSeenAt: Date) -> StoredGameplayProgressRecord {
        let profileId = activeProfileIdProvider()
        let entity = thread.entities.first { $0.id == key.entityID }
        let property = entity?.properties.first { $0.id == key.propertyID }
        return StoredGameplayProgressRecord(
            uniqueKey: Self.uniqueKey(profileId: profileId, threadID: thread.id, key: key),
            profileId: profileId,
            threadId: thread.id,
            entityId: key.entityID,
            propertyId: key.propertyID,
            propertyTypeId: property?.typeID,
            propertyValue: property?.value,
            stageId: stage.id,
            firstSeenAt: firstSeenAt,
            lastSeenAt: nil,
            nextDueAt: .distantPast
        )
    }

    static func uniqueKey(profileId: String, threadID: String, key: GameplayExposureKey) -> String {
        [profileId, threadID, key.stageID, key.entityID, key.propertyID ?? "entity"].joined(separator: "::")
    }
}

extension StoredGameplayProgressRecord {
    var exposureKey: GameplayExposureKey {
        GameplayExposureKey(entityID: entityId, propertyID: propertyId, stageID: stageId)
    }

    var confidenceBand: GameplayConfidenceBand {
        GameplayConfidenceBand(rawValue: confidenceBandRawValue) ?? .new
    }

    var exposureRecord: GameplayExposureRecord {
        GameplayExposureRecord(
            key: exposureKey,
            correctCount: correctCount,
            supportedCorrectCount: supportedCorrectCount,
            mistakeCount: incorrectCount,
            lastSeenAt: lastSeenAt,
            lastOutcome: lastOutcomeRawValue.flatMap(GameplayExposureOutcome.init(rawValue:)),
            dueAt: nextDueAt,
            confidenceBand: confidenceBand
        )
    }

    func apply(record: GameplayExposureRecord) {
        correctCount = record.correctCount
        supportedCorrectCount = record.supportedCorrectCount
        incorrectCount = record.mistakeCount
        lastSeenAt = record.lastSeenAt
        lastOutcomeRawValue = record.lastOutcome?.rawValue
        nextDueAt = record.dueAt
        confidenceBandRawValue = record.confidenceBand.rawValue
    }

    fileprivate var confidencePriority: Int {
        switch confidenceBand {
        case .reviewNeeded: return 0
        case .learning: return 1
        case .new: return 2
        case .steady: return 3
        }
    }
}
