import Foundation

enum ProblemGenerator {
    private static let deterministicSeed: [(Int, Int, Int)] = [
        (6, 1, 5),
        (7, 2, 5),
        (8, 3, 5),
        (9, 4, 5),
        (10, 5, 5),
        (6, 2, 4),
        (7, 3, 4),
        (8, 4, 4)
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
