import Foundation

struct SpacedRepetitionScheduler {
    struct Configuration: Equatable {
        let dueWeakWeight: Double
        let dueSteadyWeight: Double
        let newItemWeight: Double
        let masteredWeight: Double
        let weakReviewInterval: TimeInterval
        let learningInterval: TimeInterval
        let steadyInterval: TimeInterval
        let masteredInterval: TimeInterval

        static let standard = Configuration(
            dueWeakWeight: 1_000,
            dueSteadyWeight: 600,
            newItemWeight: 450,
            masteredWeight: 50,
            weakReviewInterval: 60 * 5,
            learningInterval: 60 * 60,
            steadyInterval: 60 * 60 * 24,
            masteredInterval: 60 * 60 * 24 * 5
        )
    }

    let configuration: Configuration

    init(configuration: Configuration = .standard) {
        self.configuration = configuration
    }

    func repetitionKeys(for thread: GameplayThreadDefinition) -> [GameplayRepetitionKey] {
        thread.entities.flatMap { entity -> [GameplayRepetitionKey] in
            let entityKey = GameplayRepetitionKey(entityID: entity.id)
            let propertyKeys = entity.properties.map {
                GameplayRepetitionKey(entityID: entity.id, propertyTypeID: $0.typeID, propertyValueID: $0.id)
            }
            return [entityKey] + propertyKeys
        }.sorted()
    }

    func selectKeys(
        from candidates: [GameplayRepetitionKey],
        states: [GameplayRepetitionKey: GameplayRepetitionState],
        limit: Int,
        now: Date
    ) -> [GameplayRepetitionKey] {
        guard limit > 0 else { return [] }
        return candidates
            .sorted { lhs, rhs in
                let lhsScore = priorityScore(for: states[lhs] ?? GameplayRepetitionState(key: lhs), now: now)
                let rhsScore = priorityScore(for: states[rhs] ?? GameplayRepetitionState(key: rhs), now: now)
                if lhsScore == rhsScore { return lhs < rhs }
                return lhsScore > rhsScore
            }
            .prefix(limit)
            .map { $0 }
    }

    func buildRound(
        for thread: GameplayThreadDefinition,
        stageKind: GameplayStageKind,
        states: [GameplayRepetitionKey: GameplayRepetitionState],
        itemLimit: Int,
        now: Date,
        seed: UInt64? = nil
    ) -> GameplayRoundDefinition {
        let selected = selectKeys(from: repetitionKeys(for: thread), states: states, limit: itemLimit, now: now)
        let entityIDs = Array(Set(selected.map(\.entityID))).sorted()
        let propertyTypeIDs = Array(Set(selected.compactMap(\.propertyTypeID))).sorted()
        return GameplayRoundDefinition(stageKind: stageKind, entityIDs: entityIDs, propertyTypeIDs: propertyTypeIDs, seed: seed)
    }

    func updatedState(
        from previous: GameplayRepetitionState,
        with event: GameplayExposureEvent,
        at now: Date
    ) -> GameplayRepetitionState {
        var state = previous
        state.lastStageKind = event.stageKind
        state.lastSessionID = event.sessionID
        state.exposureCount += 1
        state.lastSeenAt = event.seenAt

        switch event.wasCorrect {
        case .some(true): state.correctCount += 1
        case .some(false): state.incorrectCount += 1
        case .none: break
        }

        state.confidenceBand = confidenceBand(
            exposureCount: state.exposureCount,
            correctCount: state.correctCount,
            incorrectCount: state.incorrectCount,
            usedHint: event.usedHint,
            attempts: event.attempts
        )
        state.nextDueAt = nextDueDate(for: state.confidenceBand, after: now)
        return state
    }

    func priorityScore(for state: GameplayRepetitionState, now: Date) -> Double {
        if state.exposureCount == 0 { return configuration.newItemWeight }

        let isDue = state.nextDueAt <= now
        let dueBoost = isDue ? dueUrgency(for: state, now: now) : 0
        let weaknessBoost = Double(state.incorrectCount * 90) + max(0, 1 - state.accuracy) * 180

        switch state.confidenceBand {
        case .reviewNeeded:
            return configuration.dueWeakWeight + dueBoost + weaknessBoost
        case .learning:
            return (isDue ? configuration.dueWeakWeight : configuration.dueSteadyWeight) + dueBoost + weaknessBoost
        case .new:
            return configuration.newItemWeight
        case .steady:
            return (isDue ? configuration.dueSteadyWeight : 200) + dueBoost + weaknessBoost
        case .mastered:
            return (isDue ? configuration.dueSteadyWeight / 2 : configuration.masteredWeight) + dueBoost
        }
    }

    private func dueUrgency(for state: GameplayRepetitionState, now: Date) -> Double {
        max(0, now.timeIntervalSince(state.nextDueAt) / 60)
    }

    private func confidenceBand(
        exposureCount: Int,
        correctCount: Int,
        incorrectCount: Int,
        usedHint: Bool,
        attempts: Int
    ) -> GameplayConfidenceBand {
        guard exposureCount > 0 else { return .new }
        if incorrectCount > 0 && (incorrectCount >= correctCount || usedHint || attempts > 1) {
            return .reviewNeeded
        }
        if usedHint || attempts > 1 { return .reviewNeeded }
        if exposureCount < 2 || correctCount < 2 { return .learning }
        if correctCount >= 5 && incorrectCount == 0 { return .mastered }
        return .steady
    }

    private func nextDueDate(for band: GameplayConfidenceBand, after date: Date) -> Date {
        switch band {
        case .new: return date
        case .reviewNeeded: return date.addingTimeInterval(configuration.weakReviewInterval)
        case .learning: return date.addingTimeInterval(configuration.learningInterval)
        case .steady: return date.addingTimeInterval(configuration.steadyInterval)
        case .mastered: return date.addingTimeInterval(configuration.masteredInterval)
        }
    }
}
