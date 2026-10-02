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
        let requestedPolicy = policy ?? SpacedRepetitionSelectionPolicy(maximumItemCount: stage.maximumItemCount)
        let effectivePolicy = SpacedRepetitionSelectionPolicy(maximumItemCount: min(4, requestedPolicy.maximumItemCount),
            dueItemRatio: requestedPolicy.dueItemRatio, reviewNeededPriority: requestedPolicy.reviewNeededPriority,
            newItemPriority: requestedPolicy.newItemPriority, steadyPriority: requestedPolicy.steadyPriority)
        let candidates = candidateItems(thread: thread, stage: stage)
        let ranked = candidates.sorted { lhs, rhs in
            let leftRecord = records[recordKey(for: lhs, stageID: stage.id)]
            let rightRecord = records[recordKey(for: rhs, stageID: stage.id)]
            let leftRank = rank(item: lhs, record: leftRecord, now: now, seed: seed, policy: effectivePolicy)
            let rightRank = rank(item: rhs, record: rightRecord, now: now, seed: seed, policy: effectivePolicy)
            return leftRank < rightRank
        }
        // Reserve a small place for exploration, while keeping due/recovery items first.
        let due = ranked.filter { records[recordKey(for: $0, stageID: stage.id)].map { $0.dueAt <= now } ?? false }
        let new = ranked.filter { records[recordKey(for: $0, stageID: stage.id)] == nil }
        let dueQuota = Int(ceil(Double(effectivePolicy.maximumItemCount) * effectivePolicy.dueItemRatio))
        let preferred = Array(due.prefix(dueQuota)) + Array(new.prefix(max(0, effectivePolicy.maximumItemCount - dueQuota)))
        let preferredIDs = Set(preferred.map(\.id))
        let selected = childSafeSelection(
            from: preferred + ranked.filter { !preferredIDs.contains($0.id) },
            maximumItemCount: effectivePolicy.maximumItemCount,
            stageKind: stage.kind,
            thread: thread
        )
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
            let properties = entity.properties.filter { property in
                guard propertyTypeFilter.isEmpty || propertyTypeFilter.contains(property.typeID) else { return false }
                guard stage.kind == .multipleChoice else { return true }
                let values = Set(thread.entities.flatMap { $0.properties.filter { $0.typeID == property.typeID }.map {
                    $0.value.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
                } })
                return values.count >= 2
            }
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
            switch update.outcome {
            case .correct:
                record.correctCount += 1
                record.consecutiveIndependentCorrect += 1
                if let sessionID = update.sessionID { record.independentSessionIDs.insert(sessionID) }
            case .supportedCorrect:
                record.supportedCorrectCount += 1
                record.consecutiveIndependentCorrect = 0
                record.independentSessionIDs.removeAll()
            case .incorrect:
                record.mistakeCount += 1
                record.consecutiveIndependentCorrect = 0
                record.independentSessionIDs.removeAll()
            }
            record.lastSeenAt = update.occurredAt
            record.lastOutcome = update.outcome
            record.confidenceBand = confidenceBand(for: record)
            record.dueAt = dueDate(for: record, after: update.occurredAt, baseInterval: stageInterval)
            next[update.key] = record
        }
        return next
    }

    static func recordKey(for item: GameplayRoundItem, stageID: String) -> GameplayExposureKey {
        GameplayExposureKey(entityID: item.entityID, propertyID: item.propertyID, stageID: stageID)
    }

    private static func childSafeSelection(
        from ranked: [GameplayRoundItem],
        maximumItemCount: Int,
        stageKind: GameplayStageKind,
        thread: GameplayThreadDefinition
    ) -> [GameplayRoundItem] {
        let limit = max(1, maximumItemCount)
        guard stageKind == .easyMemory || stageKind == .flipMemory else {
            return Array(ranked.prefix(limit))
        }

        var selected: [GameplayRoundItem] = []
        var selectedEntityIDs = Set<String>()
        var selectedAnswerKeys = Set<String>()
        for item in ranked {
            guard selected.count < limit else { break }
            let answerKey = visibleAnswerKey(for: item, in: thread)
            if !selectedEntityIDs.contains(item.entityID), !selectedAnswerKeys.contains(answerKey) {
                selectedEntityIDs.insert(item.entityID)
                selectedAnswerKeys.insert(answerKey)
                selected.append(item)
            }
        }
        return selected
    }

    private static func visibleAnswerKey(for item: GameplayRoundItem, in thread: GameplayThreadDefinition) -> String {
        guard let entity = thread.entities.first(where: { $0.id == item.entityID }),
              let property = entity.properties.first(where: { $0.id == item.propertyID }) ?? entity.properties.first
        else {
            return item.id.lowercased()
        }
        return "\(property.typeID)::\(property.value)".trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }

    private static func rank(item: GameplayRoundItem, record: GameplayExposureRecord?, now: Date, seed: UInt64, policy: SpacedRepetitionSelectionPolicy) -> GameplayItemRank {
        guard let record else {
            return GameplayItemRank(priority: policy.newItemPriority, dueAt: .distantPast, mistakeDebt: 0, tieBreak: stableTieBreak(item.id, seed: seed))
        }
        let isDue = record.dueAt <= now
        let confidencePriority: Int
        switch record.lastOutcome {
        case .incorrect:
            confidencePriority = policy.reviewNeededPriority
        case .supportedCorrect:
            confidencePriority = policy.newItemPriority
        case .correct, nil:
            switch record.confidenceBand {
            case .reviewNeeded: confidencePriority = policy.reviewNeededPriority
            case .new: confidencePriority = policy.newItemPriority
            case .learning: confidencePriority = policy.newItemPriority + 1
            case .steady: confidencePriority = policy.steadyPriority
            }
        }
        let duePenalty = isDue ? 0 : 5
        return GameplayItemRank(
            priority: duePenalty + confidencePriority,
            dueAt: record.dueAt,
            mistakeDebt: -record.mistakeCount,
            tieBreak: stableTieBreak(item.id, seed: seed)
        )
    }

    private static func confidenceBand(for record: GameplayExposureRecord) -> GameplayConfidenceBand {
        if record.lastOutcome == .incorrect { return .reviewNeeded }
        if record.attemptCount == 0 { return .new }
        if record.consecutiveIndependentCorrect >= 3 && record.independentSessionIDs.count >= 2 { return .steady }
        return .learning
    }

    private static func dueDate(for record: GameplayExposureRecord, after date: Date, baseInterval: TimeInterval) -> Date {
        guard let outcome = record.lastOutcome else { return date }
        let configuration = CardReviewScheduler.Configuration(
            incorrectRetryDelay: baseInterval / 24,
            supportedCorrectDelay: baseInterval / 2,
            independentCorrectIntervals: [baseInterval, baseInterval * 3, baseInterval * 5],
            interleaveWindow: baseInterval / 48
        )
        let progress = CardProgress(
            timesSeen: record.attemptCount,
            correctCount: record.totalSuccessfulCount,
            incorrectCount: record.mistakeCount,
            currentCorrectStreak: outcome == .correct ? max(1, record.consecutiveIndependentCorrect) : 0,
            lastReviewedAt: date,
            lastReviewResult: outcome.cardReviewResult
        )
        return CardReviewScheduler(now: date, configuration: configuration).nextReviewDate(for: progress)
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
