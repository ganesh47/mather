import Foundation

enum ProblemGenerator {
    // Seed covers varied decomposition patterns:
    // - spread pairs (large difference: 1+5, 1+6, 2+7) reveal the range of a number
    // - mid pairs (3+4, 3+6) are the "non-round" preferred by the spec
    // - symmetric pairs (3+3, 4+4) test understanding that a+a is valid
    // - reversed pairs (6+2 after 2+6) expose commutativity across problems
    private static let deterministicSeed: [(Int, Int, Int)] = [
        (6, 3, 3),  // symmetric — 6 = 3+3
        (7, 3, 4),  // mid spread
        (8, 2, 6),  // wider spread
        (9, 4, 5),  // near-equal
        (10, 4, 6), // non-round, not anchored to 5
        (6, 1, 5),  // extreme spread
        (8, 6, 2),  // reversed of (8,2,6) — commutativity
        (7, 6, 1),  // high-low reversed
    ]

    static func generateProblems(config: SliceConfig) -> [SliceProblem] {
        let tuples: [(Int, Int, Int)]
        if config.deterministicMode {
            tuples = deterministicSeed.filter { config.targetRange.contains($0.0) }
        } else {
            tuples = randomTuples(in: config.targetRange, count: max(config.maxProblems, 6))
        }

        return tuples.prefix(config.maxProblems).enumerated().map { index, tuple in
            SliceProblem(
                target: tuple.0,
                decompositionA: tuple.1,
                decompositionB: tuple.2,
                difficultyTier: index < 3 ? 1 : 2
            )
        }
    }

    private static func randomTuples(in range: ClosedRange<Int>, count: Int) -> [(Int, Int, Int)] {
        (0..<count).map { _ in
            let target = Int.random(in: range)
            let left = Int.random(in: 0...target)
            return (target, left, target - left)
        }
    }
}
