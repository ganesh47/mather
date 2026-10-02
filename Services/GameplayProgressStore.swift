import Foundation
import Observation
import SwiftData

@MainActor
@Observable
final class GameplayProgressStore {
    private let modelContext: ModelContext
    private let activeProfileIdProvider: () -> String
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    private let defaults: UserDefaults

    init(modelContext: ModelContext, activeProfileIdProvider: @escaping () -> String, defaults: UserDefaults = .standard) {
        self.modelContext = modelContext
        self.activeProfileIdProvider = activeProfileIdProvider
        self.defaults = defaults
    }

    convenience init(modelContext: ModelContext) {
        self.init(modelContext: modelContext, activeProfileIdProvider: { KidProfileStore.defaultProfileId })
    }

    var activeProfileID: String { activeProfileIdProvider() }

    func records(forThread threadID: String, stageID: String? = nil, contentVersion: Int? = nil) -> [GameplayExposureKey: GameplayExposureRecord] {
        let profileId = activeProfileIdProvider()
        let descriptor = FetchDescriptor<StoredGameplayProgressRecord>(
            predicate: #Predicate { $0.profileId == profileId && $0.threadId == threadID }
        )
        let stored = ((try? modelContext.fetch(descriptor)) ?? [])
            .filter { stageID == nil || $0.stageId == stageID }
        stored.forEach(migrateLegacyEvidence)
        if let contentVersion {
            stored.forEach { prepareEvidence($0, for: contentVersion) }
            try? modelContext.save()
        }
        let eligible = stored.filter { contentVersion == nil || $0.evidenceContentVersion == contentVersion }
        return Dictionary(uniqueKeysWithValues: eligible.map { ($0.exposureKey, $0.exposureRecord) })
    }

    func storedRecords(forThread threadID: String) -> [StoredGameplayProgressRecord] {
        let profileId = activeProfileIdProvider()
        let descriptor = FetchDescriptor<StoredGameplayProgressRecord>(
            predicate: #Predicate { $0.profileId == profileId && $0.threadId == threadID },
            sortBy: [SortDescriptor(\StoredGameplayProgressRecord.nextDueAt)]
        )
        let records = (try? modelContext.fetch(descriptor)) ?? []
        records.forEach(migrateLegacyEvidence)
        return records
    }

    func makeRound(
        thread: GameplayThreadDefinition,
        stage: GameplayStageDefinition,
        now: Date = Date(),
        seed: UInt64 = 0,
        policy: SpacedRepetitionSelectionPolicy? = nil,
        contentVersion: Int = 1
    ) -> GameplayRoundDefinition {
        SpacedRepetitionScheduler.makeRound(
            thread: thread,
            stage: stage,
            records: records(forThread: thread.id, stageID: stage.id, contentVersion: contentVersion),
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
            stored.evidenceSchemaVersion = 1
            stored.evidenceContentVersion = max(1, stored.evidenceContentVersion)
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

    func allSessions() -> [StoredGameplayThreadSession] {
        let profileId = activeProfileIdProvider()
        let descriptor = FetchDescriptor<StoredGameplayThreadSession>(
            predicate: #Predicate { $0.profileId == profileId },
            sortBy: [SortDescriptor(\StoredGameplayThreadSession.startedAt, order: .reverse)]
        )
        return (try? modelContext.fetch(descriptor)) ?? []
    }

    func allRecords() -> [StoredGameplayProgressRecord] {
        let profileId = activeProfileIdProvider()
        let descriptor = FetchDescriptor<StoredGameplayProgressRecord>(predicate: #Predicate { $0.profileId == profileId })
        let records = (try? modelContext.fetch(descriptor)) ?? []
        records.forEach(migrateLegacyEvidence)
        return records
    }

    /// Apply catalog changes before recommendations, including children who are not selected.
    /// Historical events remain intact; bundled standalone activities have their own version.
    func invalidateCatalogConfidence(contentVersion: Int) {
        guard contentVersion > 0 else { return }
        let catalogActivities = Set(GameplayThreadID.allCases.map(\.rawValue)
            + LearningQuestID.allCases.map(\.activityID) + [LabActivityID.memoryMatch.rawValue])
        let records = (try? modelContext.fetch(FetchDescriptor<StoredGameplayProgressRecord>())) ?? []
        for record in records where catalogActivities.contains(record.threadId) {
            migrateLegacyEvidence(record)
            prepareEvidence(record, for: contentVersion)
        }
        try? modelContext.save()
    }

    /// Persist each actual interaction immediately; repeated checkpoint writes are idempotent.
    func recordAttempts(_ attempts: [ItemAttempt], sessionID: String) {
        for source in attempts {
            if let profileID = source.profileID, profileID != activeProfileID { continue }
            if let version = source.contentVersion, version < 1 { continue }
            var attempt = source.withContext(profileID: activeProfileIdProvider(), sessionID: sessionID, contentVersion: source.contentVersion ?? 1)
            let key = attempt.exposureKey
            let stored = progressRecord(for: key, threadID: attempt.activityID) ?? StoredGameplayProgressRecord(
                uniqueKey: Self.uniqueKey(profileId: activeProfileIdProvider(), threadID: attempt.activityID, key: key),
                profileId: activeProfileIdProvider(), threadId: attempt.activityID, entityId: attempt.entityID,
                propertyId: attempt.propertyID, stageId: attempt.stageID, firstSeenAt: attempt.occurredAt
            )
            migrateLegacyEvidence(stored)
            var journal = stored.itemAttemptsData.flatMap { try? decoder.decode([ItemAttempt].self, from: $0) } ?? []
            guard !journal.contains(where: { $0.id == attempt.id }) else { continue }
            attempt = ActivityEvidenceNormalizer.normalized([attempt], after: journal)[0]
            journal.append(attempt)
            stored.itemAttemptsData = try? encoder.encode(journal)
            stored.conceptId = attempt.conceptID
            let version = attempt.contentVersion ?? max(1, stored.evidenceContentVersion)
            prepareEvidence(stored, for: version)
            // Paused older packs remain history; they cannot establish confidence in newer answers.
            if version < stored.evidenceContentVersion {
                if stored.modelContext == nil { modelContext.insert(stored) }
                continue
            }
            stored.lastSeenAt = attempt.occurredAt
            stored.lastStageId = attempt.stageID
            switch attempt.outcome {
            case .exposure:
                stored.exposureCount += 1
                if stored.exposureRecord.attemptCount == 0 { stored.nextDueAt = attempt.occurredAt.addingTimeInterval(24 * 60 * 60) }
            case .help:
                stored.hintCount += 1
                stored.consecutiveIndependentCorrect = 0
                stored.independentSessionIdsData = nil
                if stored.confidenceBand == .steady { stored.confidenceBandRawValue = GameplayConfidenceBand.learning.rawValue }
                stored.nextDueAt = attempt.occurredAt.addingTimeInterval(12 * 60 * 60)
            case .independentCorrect, .supportedCorrect, .incorrect:
                guard let outcome = attempt.outcome.recallOutcome else { continue }
                let update = SpacedRepetitionUpdate(key: key, outcome: outcome, occurredAt: attempt.occurredAt, sessionID: sessionID)
                if let updated = SpacedRepetitionScheduler.applying(updates: [update], to: [key: stored.exposureRecord])[key] {
                    stored.apply(record: updated)
                }
            }
            stored.evidenceSchemaVersion = 1
            if stored.modelContext == nil { modelContext.insert(stored) }
        }
        try? modelContext.save()
    }

    @discardableResult
    func saveActivityResult(_ result: ActivityResult) -> StoredGameplayThreadSession? {
        if let profileID = result.profileID, profileID != activeProfileID { return nil }
        // A stale or mixed-child callback must never become the active child's history.
        guard result.attempts.allSatisfy({ $0.profileID == nil || $0.profileID == activeProfileID }) else { return nil }
        var seenIDs = Set<UUID>()
        let contextualized = result.attempts.filter { seenIDs.insert($0.id).inserted }
            .map { $0.withContext(profileID: activeProfileID, sessionID: result.id, contentVersion: result.contentVersion) }
        recordAttempts(contextualized, sessionID: result.id)
        // Use the persisted, normalized outcomes for both scores and the parent journal.
        let journal = storedRecords(forThread: result.activityID).flatMap {
            $0.itemAttemptsData.flatMap { try? decoder.decode([ItemAttempt].self, from: $0) } ?? []
        }
        let canonicalByID = Dictionary(journal.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
        let canonical = contextualized.compactMap { canonicalByID[$0.id] }
        let resultID = activeProfileIdProvider() + "::" + result.id
        var existing = FetchDescriptor<StoredGameplayThreadSession>(predicate: #Predicate { $0.id == resultID })
        existing.fetchLimit = 1
        let saved = try? modelContext.fetch(existing).first
        let successes = canonical.filter { $0.outcome == .independentCorrect || $0.outcome == .supportedCorrect }.count
        let session = saved ?? StoredGameplayThreadSession(id: resultID, profileId: activeProfileIdProvider(), threadId: result.activityID,
            startedAt: result.startedAt, endedAt: result.endedAt, durationSeconds: max(0, result.endedAt.timeIntervalSince(result.startedAt)),
            completedStageIdsData: try? encoder.encode(result.completedStageIDs), totalScore: successes * 10,
            stars: result.completedStageIDs.isEmpty ? 0 : 3)
        session.endedAt = result.endedAt
        session.durationSeconds = max(0, result.endedAt.timeIntervalSince(result.startedAt))
        session.completedStageIdsData = try? encoder.encode(result.completedStageIDs)
        session.totalScore = successes * 10
        session.stars = result.completedStageIDs.isEmpty ? 0 : 3
        session.activityTitle = result.title
        session.itemAttemptsData = try? encoder.encode(canonical)
        session.evidenceSchemaVersion = 1
        if session.modelContext == nil { modelContext.insert(session) }
        try? modelContext.save()
        return session
    }

    func dueAndWeakRecords(now: Date = Date(), limit: Int = 12) -> [StoredGameplayProgressRecord] {
        allRecords().filter { $0.nextDueAt <= now && $0.confidenceBand != .new || $0.confidenceBand == .reviewNeeded }
            .sorted {
                if $0.confidencePriority != $1.confidencePriority { return $0.confidencePriority < $1.confidencePriority }
                return $0.nextDueAt < $1.nextDueAt
            }.prefix(max(0, limit)).map { $0 }
    }

    func checkpoint(for activityID: String) -> QuestCheckpoint? {
        defaults.data(forKey: checkpointKey(activityID)).flatMap { try? decoder.decode(QuestCheckpoint.self, from: $0) }
    }

    func saveCheckpoint(_ checkpoint: QuestCheckpoint) {
        if let profileID = checkpoint.profileID, profileID != activeProfileID { return }
        var contextualized = checkpoint
        contextualized.profileID = activeProfileID
        contextualized.updatedAt = Date()
        defaults.set(try? encoder.encode(contextualized), forKey: checkpointKey(checkpoint.activityID))
    }

    func mostRecentCheckpoint() -> QuestCheckpoint? {
        let prefix = "learningCheckpoint.v1." + activeProfileID + "."
        return defaults.dictionaryRepresentation().keys.filter { $0.hasPrefix(prefix) }
            .compactMap { key in defaults.data(forKey: key).flatMap { try? decoder.decode(QuestCheckpoint.self, from: $0) } }
            .filter { $0.profileID == activeProfileID }
            .max { ($0.updatedAt ?? $0.startedAt) < ($1.updatedAt ?? $1.startedAt) }
    }

    func clearCheckpoint(for activityID: String) { defaults.removeObject(forKey: checkpointKey(activityID)) }

    func clearActiveProfile() {
        let profileID = activeProfileIdProvider()
        allRecords().forEach { modelContext.delete($0) }
        allSessions().forEach { modelContext.delete($0) }
        clearCheckpoints(prefix: "learningCheckpoint.v1." + profileID + ".")
        try? modelContext.save()
    }

    func clearAllProfiles() {
        ((try? modelContext.fetch(FetchDescriptor<StoredGameplayProgressRecord>())) ?? []).forEach { modelContext.delete($0) }
        ((try? modelContext.fetch(FetchDescriptor<StoredGameplayThreadSession>())) ?? []).forEach { modelContext.delete($0) }
        clearCheckpoints(prefix: "learningCheckpoint.v1.")
        try? modelContext.save()
    }

    private func clearCheckpoints(prefix: String) {
        for key in defaults.dictionaryRepresentation().keys where key.hasPrefix(prefix) { defaults.removeObject(forKey: key) }
    }

    private func checkpointKey(_ activityID: String) -> String { "learningCheckpoint.v1.\(activeProfileIdProvider()).\(activityID)" }

    private func prepareEvidence(_ stored: StoredGameplayProgressRecord, for contentVersion: Int) {
        guard contentVersion > stored.evidenceContentVersion else { return }
        stored.evidenceContentVersion = contentVersion
        stored.consecutiveIndependentCorrect = 0
        stored.independentSessionIdsData = nil
        stored.lastOutcomeRawValue = nil
        stored.confidenceBandRawValue = GameplayConfidenceBand.new.rawValue
        stored.nextDueAt = .distantPast
    }

    private func migrateLegacyEvidence(_ stored: StoredGameplayProgressRecord) {
        guard stored.evidenceSchemaVersion == 0 else { return }
        stored.legacyAggregateCountsData = try? encoder.encode([stored.correctCount, stored.supportedCorrectCount, stored.incorrectCount, stored.hintCount])
        stored.correctCount = 0
        stored.supportedCorrectCount = 0
        stored.incorrectCount = 0
        stored.hintCount = 0
        stored.consecutiveIndependentCorrect = 0
        stored.independentSessionIdsData = nil
        stored.lastOutcomeRawValue = nil
        stored.confidenceBandRawValue = GameplayConfidenceBand.new.rawValue
        stored.nextDueAt = .distantPast
        stored.evidenceSchemaVersion = 1
        if stored.modelContext != nil { try? modelContext.save() }
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
            confidenceBand: confidenceBand,
            consecutiveIndependentCorrect: consecutiveIndependentCorrect,
            independentSessionIDs: independentSessionIdsData.flatMap { try? JSONDecoder().decode(Set<String>.self, from: $0) } ?? []
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
        consecutiveIndependentCorrect = record.consecutiveIndependentCorrect
        independentSessionIdsData = try? JSONEncoder().encode(record.independentSessionIDs)
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
