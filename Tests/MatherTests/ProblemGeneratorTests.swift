import Testing
@testable import Mather

struct ProblemGeneratorTests {
    @Test
    func deterministicGenerationIsStableAcrossExpandedRange() {
        let config = SliceConfig(maxProblems: 8, minTarget: 1, maxTarget: 20, showTransfer: true, audioEnabled: true, deterministicMode: true)

        let first = ProblemGenerator.generateProblems(config: config)
        let second = ProblemGenerator.generateProblems(config: config)

        #expect(first.map(\.target) == [6, 9, 4, 12, 7, 15, 3, 18])
        #expect(first.map(\.target) == second.map(\.target))
        #expect(first.map(\.decompositionA) == second.map(\.decompositionA))
        #expect(first.map(\.decompositionB) == second.map(\.decompositionB))
        #expect(Set(first.map(\.target)).count == first.count)
    }

    @Test
    func defaultConfigSupportsFullOneToTwentyRange() {
        let config = SliceConfig()
        #expect(config.targetRange == 1...20)
    }

    @Test
    func randomGenerationUsesRequestedRangeAndAvoidsImmediateRepeats() {
        let config = SliceConfig(maxProblems: 12, minTarget: 1, maxTarget: 20, showTransfer: true, audioEnabled: true, deterministicMode: false)

        let problems = ProblemGenerator.generateProblems(config: config)
        let targets = problems.map(\.target)

        #expect(problems.count == 12)
        #expect(targets.allSatisfy { (1...20).contains($0) })
        #expect(targets.adjacentPairs().allSatisfy { $0 != $1 })
    }

    @Test
    func randomizedSessionsDoNotAllStartAtSix() {
        let config = SliceConfig(maxProblems: 6, minTarget: 1, maxTarget: 20, showTransfer: true, audioEnabled: true, deterministicMode: false)

        let starts = (0..<24).compactMap { _ in
            ProblemGenerator.generateProblems(config: config).first?.target
        }

        #expect(starts.count == 24)
        #expect(Set(starts).count > 1)
        #expect(starts.contains(where: { $0 != 6 }))
    }

    @Test
    func generatedDecompositionsAlwaysSumToTarget() {
        let config = SliceConfig(maxProblems: 24, minTarget: 1, maxTarget: 20, showTransfer: true, audioEnabled: true, deterministicMode: false)

        let problems = ProblemGenerator.generateProblems(config: config)

        #expect(problems.allSatisfy { $0.decompositionA + $0.decompositionB == $0.target })
        #expect(problems.allSatisfy { $0.decompositionA >= 0 && $0.decompositionB >= 0 })
    }
}

private extension Array where Element == Int {
    func adjacentPairs() -> [(Int, Int)] {
        guard count > 1 else { return [] }
        return zip(self, dropFirst()).map { ($0, $1) }
    }
}
