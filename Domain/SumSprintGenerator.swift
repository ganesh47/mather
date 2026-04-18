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

    /// Returns up to 10 ArithmeticFacts ordered by Leitner priority.
    /// - Parameter allRecords: Current state from FactRecordStore.fetchAll().
    /// - Parameter sessionCount: Used only in tests to verify determinism; not used in selection logic.
    static func generateSession(allRecords: [StoredFactRecord]) -> [ArithmeticFact] {
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

        // Sort: box0 first, then box1, then box2; within each box, most attempts first
        let sorted = eligible.sorted { lhs, rhs in
            if lhs.box.rawValue != rhs.box.rawValue { return lhs.box.rawValue < rhs.box.rawValue }
            return lhs.attempts > rhs.attempts
        }

        var selected = sorted

        // Backfill if fewer than 10 eligible facts
        if selected.count < 10 {
            // Prefer box0 ineligible facts for backfill, then others
            let backfill = ineligible.sorted { lhs, rhs in
                if lhs.box.rawValue != rhs.box.rawValue { return lhs.box.rawValue < rhs.box.rawValue }
                return lhs.attempts > rhs.attempts
            }
            selected += backfill
        }

        let trimmed = Array(selected.prefix(10))
        return diversifyAdjacentSums(in: trimmed).map(\.fact)
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
