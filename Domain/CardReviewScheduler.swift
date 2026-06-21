import Foundation

struct CardReviewScheduler {
    typealias Clock = () -> Date

    struct Configuration: Hashable {
        var incorrectRetryDelay: TimeInterval
        var supportedCorrectDelay: TimeInterval
        var independentCorrectIntervals: [TimeInterval]
        var interleaveWindow: TimeInterval

        init(
            incorrectRetryDelay: TimeInterval = 5 * 60,
            supportedCorrectDelay: TimeInterval = 30 * 60,
            independentCorrectIntervals: [TimeInterval] = [
                24 * 60 * 60,
                3 * 24 * 60 * 60,
                7 * 24 * 60 * 60,
                14 * 24 * 60 * 60,
            ],
            interleaveWindow: TimeInterval = 30 * 60
        ) {
            self.incorrectRetryDelay = incorrectRetryDelay
            self.supportedCorrectDelay = supportedCorrectDelay
            self.independentCorrectIntervals = independentCorrectIntervals
            self.interleaveWindow = interleaveWindow
        }
    }

    private let clock: Clock
    private let configuration: Configuration

    init(configuration: Configuration = Configuration()) {
        self.clock = Date.init
        self.configuration = configuration
    }

    init(now: Date, configuration: Configuration = Configuration()) {
        self.clock = { now }
        self.configuration = configuration
    }

    init(clock: @escaping Clock, configuration: Configuration = Configuration()) {
        self.clock = clock
        self.configuration = configuration
    }

    func progress(after result: CardReviewResult, from progress: CardProgress) -> CardProgress {
        var updated = progress
        let now = clock()
        updated.timesSeen += 1
        updated.lastReviewedAt = now
        updated.lastReviewResult = result

        switch result {
        case .correct:
            updated.correctCount += 1
            updated.currentCorrectStreak += 1
        case .supportedCorrect:
            updated.correctCount += 1
            updated.currentCorrectStreak = 0
        case .incorrect:
            updated.incorrectCount += 1
            updated.currentCorrectStreak = 0
        }

        return updated
    }

    func card(_ card: LearningCard, after result: CardReviewResult) -> LearningCard {
        var updated = card
        updated.progress = progress(after: result, from: card.progress)
        return updated
    }

    func nextReviewDate(for progress: CardProgress) -> Date {
        nextReviewDate(for: progress, at: clock())
    }

    private func nextReviewDate(for progress: CardProgress, at now: Date) -> Date {
        guard let lastReviewedAt = progress.lastReviewedAt else {
            return now
        }

        switch progress.lastReviewResult {
        case .incorrect:
            return lastReviewedAt.addingTimeInterval(configuration.incorrectRetryDelay)
        case .supportedCorrect:
            return lastReviewedAt.addingTimeInterval(configuration.supportedCorrectDelay)
        case .correct:
            return lastReviewedAt.addingTimeInterval(independentCorrectInterval(for: progress.currentCorrectStreak))
        case nil:
            return lastReviewedAt.addingTimeInterval(independentCorrectInterval(for: progress.currentCorrectStreak))
        }
    }

    func isDue(_ card: LearningCard) -> Bool {
        let now = clock()
        return nextReviewDate(for: card.progress, at: now) <= now
    }

    func reviewQueue(from cards: [LearningCard], limit: Int, includeFutureCards: Bool = false) -> [LearningCard] {
        guard limit > 0 else { return [] }

        let now = clock()
        var remaining = cards
            .map { ScheduledCard(card: $0, dueAt: nextReviewDate(for: $0.progress, at: now)) }
            .filter { includeFutureCards || $0.dueAt <= now }
            .sorted()

        var selected: [ScheduledCard] = []
        selected.reserveCapacity(min(limit, remaining.count))

        while selected.count < limit, !remaining.isEmpty {
            let selectedIndex = nextSelectionIndex(in: remaining, after: selected.last)
            selected.append(remaining.remove(at: selectedIndex))
        }

        return selected.map(\.card)
    }

    private func independentCorrectInterval(for streak: Int) -> TimeInterval {
        guard !configuration.independentCorrectIntervals.isEmpty else { return 0 }
        let index = max(0, min(streak - 1, configuration.independentCorrectIntervals.count - 1))
        return configuration.independentCorrectIntervals[index]
    }

    private func nextSelectionIndex(in remaining: [ScheduledCard], after previous: ScheduledCard?) -> Int {
        guard let previous else { return 0 }

        let windowEnd = remaining[0].dueAt.addingTimeInterval(configuration.interleaveWindow)
        let pool = remaining.enumerated().filter { $0.element.dueAt <= windowEnd }

        if let match = pool.first(where: {
            $0.element.card.laneID != previous.card.laneID
                && $0.element.card.conceptID != previous.card.conceptID
        }) {
            return match.offset
        }

        if let match = pool.first(where: { $0.element.card.laneID != previous.card.laneID }) {
            return match.offset
        }

        return 0
    }
}

private struct ScheduledCard: Comparable {
    let card: LearningCard
    let dueAt: Date

    static func < (lhs: ScheduledCard, rhs: ScheduledCard) -> Bool {
        if lhs.dueAt != rhs.dueAt {
            return lhs.dueAt < rhs.dueAt
        }
        if lhs.card.laneID.rawValue != rhs.card.laneID.rawValue {
            return lhs.card.laneID.rawValue < rhs.card.laneID.rawValue
        }
        if lhs.card.conceptID.rawValue != rhs.card.conceptID.rawValue {
            return lhs.card.conceptID.rawValue < rhs.card.conceptID.rawValue
        }
        return lhs.card.id < rhs.card.id
    }
}
