import Foundation

enum SpacedRepetitionScheduler {
    static func makeRound(
        thread: GameplayThreadDefinition,
        stage: GameplayStageDefinition,
        records: [GameplayExposureKey: GameplayExposureRecord] = [:],
        now: Date = Date(),
        seed: UInt64 = 0,
        policy: SpacedRepetitionSelectionPolicy? = nil
    ) -> GameplayRoundDefinition {
        let effectivePolicy = policy ?? SpacedRepetitionSelectionPolicy(maximumItemCount: stage.maximumItemCount)
        let candidates = candidateItems(thread: thread, stage: stage)
        let ranked = candidates.sorted { lhs, rhs in
            let leftRecord = records[recordKey(for: lhs, stageID: stage.id)]
            let rightRecord = records[recordKey(for: rhs, stageID: stage.id)]
            let leftRank = rank(item: lhs, record: leftRecord, now: now, seed: seed)
            let rightRank = rank(item: rhs, record: rightRecord, now: now, seed: seed)
            return leftRank < rightRank
        }
        let selected = Array(ranked.prefix(effectivePolicy.maximumItemCount))
        return GameplayRoundDefinition(
            id: "\(stage.id)-round-\(seed)",
            stageID: stage.id,
            kind: stage.kind,
            items: selected,
            seed: seed
        )
    }

    static func candidateItems(thread: GameplayThreadDefinition, stage: GameplayStageDefinition) -> [GameplayRoundItem] {
        let propertyTypeFilter = Set(stage.propertyTypeIDs)
        var items: [GameplayRoundItem] = []
        for entity in thread.entities {
            if stage.kind == .flashcards || entity.properties.isEmpty {
                items.append(GameplayRoundItem(id: "\(entity.id)::entity", entityID: entity.id, propertyID: nil, propertyTypeID: nil))
                continue
            }
            let properties = entity.properties.filter { propertyTypeFilter.isEmpty || propertyTypeFilter.contains($0.typeID) }
            for property in properties {
                items.append(GameplayRoundItem(id: "\(entity.id)::\(property.id)", entityID: entity.id, propertyID: property.id, propertyTypeID: property.typeID))
            }
        }
        return items
    }

    static func applying(
        updates: [SpacedRepetitionUpdate],
        to records: [GameplayExposureKey: GameplayExposureRecord],
        stageInterval: TimeInterval = 60 * 60 * 24
    ) -> [GameplayExposureKey: GameplayExposureRecord] {
        var next = records
        for update in updates {
            var record = next[update.key] ?? GameplayExposureRecord(key: update.key)
            if update.wasCorrect {
                record.correctCount += 1
            } else {
                record.mistakeCount += 1
            }
            record.lastSeenAt = update.occurredAt
            record.confidenceBand = confidenceBand(correctCount: record.correctCount, mistakeCount: record.mistakeCount)
            record.dueAt = dueDate(for: record, after: update.occurredAt, baseInterval: stageInterval)
            next[update.key] = record
        }
        return next
    }

    static func recordKey(for item: GameplayRoundItem, stageID: String) -> GameplayExposureKey {
        GameplayExposureKey(entityID: item.entityID, propertyID: item.propertyID, stageID: stageID)
    }

    private static func rank(item: GameplayRoundItem, record: GameplayExposureRecord?, now: Date, seed: UInt64) -> GameplayItemRank {
        guard let record else {
            return GameplayItemRank(priority: 1, dueAt: .distantPast, mistakeDebt: 0, tieBreak: stableTieBreak(item.id, seed: seed))
        }
        let isDue = record.dueAt <= now
        let confidencePriority: Int
        switch record.confidenceBand {
        case .reviewNeeded: confidencePriority = 0
        case .new: confidencePriority = 1
        case .learning: confidencePriority = 2
        case .steady: confidencePriority = 4
        }
        let duePenalty = isDue ? 0 : 5
        return GameplayItemRank(
            priority: duePenalty + confidencePriority,
            dueAt: record.dueAt,
            mistakeDebt: -record.mistakeCount,
            tieBreak: stableTieBreak(item.id, seed: seed)
        )
    }

    private static func confidenceBand(correctCount: Int, mistakeCount: Int) -> GameplayConfidenceBand {
        if mistakeCount > 0 && mistakeCount >= correctCount { return .reviewNeeded }
        if correctCount == 0 && mistakeCount == 0 { return .new }
        if correctCount < 3 { return .learning }
        return .steady
    }

    private static func dueDate(for record: GameplayExposureRecord, after date: Date, baseInterval: TimeInterval) -> Date {
        switch record.confidenceBand {
        case .reviewNeeded:
            return date.addingTimeInterval(baseInterval / 24)
        case .new, .learning:
            return date.addingTimeInterval(baseInterval)
        case .steady:
            return date.addingTimeInterval(baseInterval * 5)
        }
    }

    private static func stableTieBreak(_ id: String, seed: UInt64) -> UInt64 {
        var hash = 14_695_981_039_346_656_037 ^ seed
        for byte in id.utf8 {
            hash ^= UInt64(byte)
            hash &*= 1_099_511_628_211
        }
        return hash
    }
}

private struct GameplayItemRank: Comparable {
    let priority: Int
    let dueAt: Date
    let mistakeDebt: Int
    let tieBreak: UInt64

    static func < (lhs: GameplayItemRank, rhs: GameplayItemRank) -> Bool {
        if lhs.priority != rhs.priority { return lhs.priority < rhs.priority }
        if lhs.dueAt != rhs.dueAt { return lhs.dueAt < rhs.dueAt }
        if lhs.mistakeDebt != rhs.mistakeDebt { return lhs.mistakeDebt < rhs.mistakeDebt }
        return lhs.tieBreak < rhs.tieBreak
    }
}
