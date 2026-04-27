import Foundation

enum ProblemGenerator {
    // Ordered fixture for deterministic mode. It spans the full 1...20 band while
    // mixing small/large targets and symmetric/asymmetric decompositions so tests
    // stay reproducible without every session feeling anchored to a simple climb.
    private static let deterministicSeed: [(Int, Int, Int)] = [
        (6, 3, 3),
        (9, 4, 5),
        (4, 1, 3),
        (12, 5, 7),
        (7, 2, 5),
        (15, 7, 8),
        (3, 1, 2),
        (18, 8, 10),
        (10, 4, 6),
        (1, 1, 0),
        (14, 6, 8),
        (5, 2, 3),
        (20, 9, 11),
        (8, 6, 2),
        (16, 8, 8),
        (2, 1, 1),
        (11, 5, 6),
        (19, 9, 10),
        (13, 4, 9),
        (17, 3, 14),
    ]

    static func generateProblems(config: SliceConfig) -> [SliceProblem] {
        let tuples: [(Int, Int, Int)]
        if config.deterministicMode {
            tuples = deterministicTuples(in: config.targetRange, count: max(config.maxProblems, 6))
        } else {
            tuples = randomTuples(in: config.targetRange, count: max(config.maxProblems, 6))
        }

        return tuples.prefix(config.maxProblems).enumerated().map { index, tuple in
            SliceProblem(
                target: tuple.0,
                decompositionA: tuple.1,
                decompositionB: tuple.2,
                difficultyTier: difficultyTier(for: tuple.0, index: index)
            )
        }
    }

    private static func deterministicTuples(in range: ClosedRange<Int>, count: Int) -> [(Int, Int, Int)] {
        let fixture = deterministicSeed.filter { range.contains($0.0) }
        guard range.upperBound > 20 else { return fixture }

        var tuples: [(Int, Int, Int)] = []
        var usedTargets = Set<Int>()

        func appendTarget(_ target: Int) {
            guard range.contains(target), !usedTargets.contains(target) else { return }
            usedTargets.insert(target)

            if let seeded = deterministicSeed.first(where: { $0.0 == target }) {
                tuples.append(seeded)
            } else {
                let decomposition = deterministicDecomposition(for: target, index: tuples.count)
                tuples.append((target, decomposition.0, decomposition.1))
            }
        }

        appendTarget(fixture.first?.0 ?? range.lowerBound)
        appendTarget(fixture.dropFirst().first?.0 ?? min(range.lowerBound + 1, range.upperBound))

        let highTargets = [
            max(21, range.upperBound / 2),
            range.upperBound,
            max(21, (range.upperBound * 3) / 4),
            max(21, range.upperBound / 3),
        ]
        highTargets.forEach(appendTarget)
        fixture.dropFirst(2).forEach { appendTarget($0.0) }

        for target in range where tuples.count < count {
            appendTarget(target)
        }

        return tuples
    }

    private static func randomTuples(in range: ClosedRange<Int>, count: Int) -> [(Int, Int, Int)] {
        guard count > 0 else { return [] }

        var tuples: [(Int, Int, Int)] = []
        var previousTarget: Int? = nil

        while tuples.count < count {
            let target = nextTarget(in: range, previousTarget: previousTarget)
            let decomposition = makeDecomposition(for: target, favorZero: tuples.isEmpty && target <= 2)
            tuples.append((target, decomposition.0, decomposition.1))
            previousTarget = target
        }

        return tuples
    }

    private static func nextTarget(in range: ClosedRange<Int>, previousTarget: Int?) -> Int {
        let candidates = Array(range).filter { $0 != previousTarget }
        guard let previousTarget else { return candidates.randomElement() ?? range.lowerBound }
        guard !candidates.isEmpty else { return previousTarget }

        let nearby = candidates.filter { abs($0 - previousTarget) <= 4 }
        let preferred = nearby.isEmpty ? candidates : nearby
        return preferred.randomElement() ?? candidates[0]
    }

    private static func makeDecomposition(for target: Int, favorZero: Bool = false) -> (Int, Int) {
        guard target > 0 else { return (0, 0) }

        let nonZeroPairs = (1..<target).map { ($0, target - $0) }
        if nonZeroPairs.isEmpty || favorZero {
            let left = Int.random(in: 0...target)
            return (left, target - left)
        }

        let symmetricPairs = nonZeroPairs.filter { $0.0 == $0.1 }
        let asymmetricPairs = nonZeroPairs.filter { $0.0 != $0.1 }

        let basePair: (Int, Int)
        switch Int.random(in: 0..<100) {
        case 0..<25 where !symmetricPairs.isEmpty:
            basePair = symmetricPairs.randomElement() ?? nonZeroPairs[0]
        case 25..<85 where !asymmetricPairs.isEmpty:
            basePair = asymmetricPairs.randomElement() ?? nonZeroPairs[0]
        default:
            basePair = nonZeroPairs.randomElement() ?? nonZeroPairs[0]
        }

        return Bool.random() ? basePair : (basePair.1, basePair.0)
    }

    private static func deterministicDecomposition(for target: Int, index: Int) -> (Int, Int) {
        guard target > 0 else { return (0, 0) }
        guard target > 1 else { return (1, 0) }

        let offset = index % 4
        let left = min(max((target / 2) - offset, 1), target - 1)
        return (left, target - left)
    }

    private static func difficultyTier(for target: Int, index: Int) -> Int {
        if target <= 5 { return 1 }
        if target <= 10 { return index < 2 ? 1 : 2 }
        return 2
    }
}
