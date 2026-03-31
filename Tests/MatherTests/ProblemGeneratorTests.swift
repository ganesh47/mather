import Testing
@testable import Mather

struct ProblemGeneratorTests {
    @Test
    func deterministicGenerationIsStable() {
        let config = SliceConfig(maxProblems: 4, minTarget: 6, maxTarget: 10, showTransfer: true, audioEnabled: true, deterministicMode: true)

        let first = ProblemGenerator.generateProblems(config: config)
        let second = ProblemGenerator.generateProblems(config: config)

        #expect(first.map(\.target) == [6, 7, 8, 9])
        #expect(first.map(\.target) == second.map(\.target))
        #expect(first.map(\.decompositionA) == second.map(\.decompositionA))
        #expect(first.map(\.decompositionB) == second.map(\.decompositionB))
    }
}
