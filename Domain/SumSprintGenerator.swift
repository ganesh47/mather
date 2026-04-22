import Foundation

/// Pure enum — no state. Selects which ArithmeticFacts to practice this session
/// based on the current Leitner box state stored in StoredFactRecord.
enum SumSprintGenerator {

    // MARK: - Fact pool

    /// All unique unordered pairs {a, b} where a ≤ b, a ≥ 1, b ≥ 1, a+b in 11…20.
    /// Generated once; 75 facts total (5+6+6+7+7+8+8+9+9+10 per sum 11→20).
    static let allFacts: [ArithmeticFact] = {
        var facts: [ArithmeticFact] = []
        for sum in 11...20 {
            let maxA = sum / 2
            for a in 1...maxA {
                let b = sum - a
                guard b >= 1 else { continue }
                facts.append(ArithmeticFact(id: stableID(a: a, b: b), addendA: a, addendB: b))
            }
        }
        return facts
    }()

    // MARK: - Session selection

    /// Returns up to `cardCount` ArithmeticFacts ordered by Leitner priority.
    /// - Parameter allRecords: Current state from FactRecordStore.fetchAll().
    /// - Parameter cardCount: Maximum cards to return.  Defaults to 10 (Relaxed / Standard).
    static func generateSession(allRecords: [StoredFactRecord], cardCount: Int = 10) -> [ArithmeticFact] {
        let recordByKey = Dictionary(uniqueKeysWithValues: allRecords.map { ($0.factKey, $0) })

        // Partition facts into eligible and ineligible
        var eligible: [ScoredFact] = []
        var ineligible: [ScoredFact] = []

        for fact in allFacts {
            let record = recordByKey[fact.factKey]
            let box = LeitnerBox(rawValue: record?.boxRawValue ?? 0) ?? .box0
            let sinceLastSeen = record?.sessionsSinceLastSeen ?? Int.max
            let attempts = record?.correctStreak ?? 0  // re-use correctStreak as proxy for difficulty

            let scored = ScoredFact(fact: fact, box: box, sinceLastSeen: sinceLastSeen, attempts: attempts)

            if isEligible(box: box, sinceLastSeen: sinceLastSeen) {
                eligible.append(scored)
            } else {
                ineligible.append(scored)
            }
        }

        var selected = prioritizeAndSpreadBySum(eligible)

        // Backfill if fewer than `cardCount` eligible facts
        if selected.count < cardCount {
            // Prefer box0 ineligible facts for backfill, then others
            selected += prioritizeAndSpreadBySum(ineligible)
        }

        let trimmed = Array(selected.prefix(cardCount))
        return diversifyAdjacentSums(in: trimmed).map(\.fact)
    }

    private static func prioritizeAndSpreadBySum(_ facts: [ScoredFact]) -> [ScoredFact] {
        let prioritized = facts.sorted(by: prioritySort)
        guard !prioritized.isEmpty else { return [] }

        let grouped = Dictionary(grouping: prioritized, by: PriorityBucket.init)
        let buckets = grouped.keys.sorted()

        var arranged: [ScoredFact] = []
        arranged.reserveCapacity(prioritized.count)

        for bucket in buckets {
            let bucketFacts = grouped[bucket] ?? []
            arranged += spreadBySum(bucketFacts)
        }

        return arranged
    }

    private static func spreadBySum(_ facts: [ScoredFact]) -> [ScoredFact] {
        guard facts.count > 1 else { return facts }

        var queuesBySum: [Int: [ScoredFact]] = [:]
        var sumOrder: [Int] = []

        for fact in facts {
            if queuesBySum[fact.fact.sum] == nil {
                sumOrder.append(fact.fact.sum)
                queuesBySum[fact.fact.sum] = []
            }
            queuesBySum[fact.fact.sum, default: []].append(fact)
        }

        var arranged: [ScoredFact] = []
        arranged.reserveCapacity(facts.count)

        while arranged.count < facts.count {
            var addedAny = false

            for sum in sumOrder {
                guard var queue = queuesBySum[sum], !queue.isEmpty else { continue }
                arranged.append(queue.removeFirst())
                queuesBySum[sum] = queue
                addedAny = true
            }

            guard addedAny else { break }
        }

        return arranged
    }

    private static func prioritySort(lhs: ScoredFact, rhs: ScoredFact) -> Bool {
        if lhs.box.rawValue != rhs.box.rawValue { return lhs.box.rawValue < rhs.box.rawValue }
        if lhs.attempts != rhs.attempts { return lhs.attempts > rhs.attempts }
        return lhs.fact.sum < rhs.fact.sum
    }

    // MARK: - Helpers

    private static func diversifyAdjacentSums(in facts: [ScoredFact]) -> [ScoredFact] {
        guard facts.count > 1 else { return facts }

        var remaining = facts
        var arranged: [ScoredFact] = []
        var previousSum: Int?

        while !remaining.isEmpty {
            let nextIndex = remaining.firstIndex { candidate in
                guard let previousSum else { return true }
                return candidate.fact.sum != previousSum
            } ?? 0

            let next = remaining.remove(at: nextIndex)
            arranged.append(next)
            previousSum = next.fact.sum
        }

        return arranged
    }

    // MARK: - Helpers

    private static func isEligible(box: LeitnerBox, sinceLastSeen: Int) -> Bool {
        switch box {
        case .box0: return true
        case .box1: return sinceLastSeen >= 2
        case .box2: return sinceLastSeen >= 5
        }
    }

    /// Produces a stable deterministic UUID for a given (a, b) pair.
    /// This is consistent across app launches because it is derived from the fact key string.
    static func stableID(a: Int, b: Int) -> UUID {
        let key = "\(a)+\(b)"
        // Use a simple hash-derived UUID (version 5 style using name bytes)
        var bytes = [UInt8](repeating: 0, count: 16)
        let keyBytes = Array(key.utf8)
        for (i, byte) in keyBytes.enumerated() {
            bytes[i % 16] ^= byte &+ UInt8(i & 0xFF)
        }
        // Set version (4) and variant bits to make it a valid UUID format
        bytes[6] = (bytes[6] & 0x0F) | 0x40
        bytes[8] = (bytes[8] & 0x3F) | 0x80
        return UUID(uuid: (
            bytes[0], bytes[1], bytes[2], bytes[3],
            bytes[4], bytes[5], bytes[6], bytes[7],
            bytes[8], bytes[9], bytes[10], bytes[11],
            bytes[12], bytes[13], bytes[14], bytes[15]
        ))
    }
}

// MARK: - Private helpers

private struct ScoredFact {
    let fact: ArithmeticFact
    let box: LeitnerBox
    let sinceLastSeen: Int
    let attempts: Int
}

private struct PriorityBucket: Hashable, Comparable {
    let boxRawValue: Int
    let attempts: Int

    init(_ fact: ScoredFact) {
        boxRawValue = fact.box.rawValue
        attempts = fact.attempts
    }

    static func < (lhs: PriorityBucket, rhs: PriorityBucket) -> Bool {
        if lhs.boxRawValue != rhs.boxRawValue { return lhs.boxRawValue < rhs.boxRawValue }
        return lhs.attempts > rhs.attempts
    }
}
