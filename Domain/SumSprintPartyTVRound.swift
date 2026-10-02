import Foundation

struct SumSprintPartyTVFact: Identifiable, Codable, Equatable, Hashable {
    let addendA: Int
    let addendB: Int

    var id: String { "\(addendA)+\(addendB)" }
    var sum: Int { addendA + addendB }
    var promptText: String { "\(addendA) + \(addendB)" }
    var spokenPrompt: String { "What is \(addendA) plus \(addendB)?" }
}

struct SumSprintPartyTVRound: Codable, Equatable {
    let index: Int
    let fact: SumSprintPartyTVFact
    let answerChoices: [Int]

    var correctAnswer: Int { fact.sum }
    var usesTimer: Bool { false }

    static let choiceCount = 4
    static let answerRange = 11...20

    static let factPool: [SumSprintPartyTVFact] = {
        var facts: [SumSprintPartyTVFact] = []
        for sum in answerRange {
            for addendA in 1...(sum / 2) {
                facts.append(SumSprintPartyTVFact(addendA: addendA, addendB: sum - addendA))
            }
        }
        return facts
    }()

    static func make(index: Int) -> SumSprintPartyTVRound {
        precondition(!factPool.isEmpty, "Sum Sprint Party needs at least one fact.")
        let normalizedIndex = positiveModulo(index, factPool.count)
        let fact = factPool[normalizedIndex]
        return SumSprintPartyTVRound(
            index: normalizedIndex,
            fact: fact,
            answerChoices: answerChoices(for: fact)
        )
    }

    static func answerChoices(for fact: SumSprintPartyTVFact) -> [Int] {
        let distractors = distractors(for: fact)
        let orderedChoices = [fact.sum] + distractors
        return rotate(orderedChoices, by: rotationOffset(for: fact))
    }

    /// Reviewed learning ranges include smaller totals; legacy round APIs stay intact.
    static func facts(through maximum: Int) -> [SumSprintPartyTVFact] {
        guard [5, 10, 20].contains(maximum) else { return [] }
        return (2...maximum).flatMap { sum in
            (1...(sum / 2)).map { SumSprintPartyTVFact(addendA: $0, addendB: sum - $0) }
        }
    }

    static func answerChoices(for fact: SumSprintPartyTVFact, through maximum: Int) -> [Int] {
        guard [5, 10, 20].contains(maximum), (2...maximum).contains(fact.sum) else { return [] }
        let range = 1...maximum
        var distractors: [Int] = []
        for delta in [1, -1, 2, -2, 3, -3, 4, -4] {
            let candidate = fact.sum + delta
            if range.contains(candidate), !distractors.contains(candidate) { distractors.append(candidate) }
        }
        let choices = [fact.sum] + distractors.prefix(choiceCount - 1)
        return rotate(Array(choices), by: rotationOffset(for: fact))
    }

    static func isCorrect(selection: Int?, for round: SumSprintPartyTVRound) -> Bool {
        selection == round.correctAnswer
    }

    private static func distractors(for fact: SumSprintPartyTVFact) -> [Int] {
        var candidates: [Int] = []
        let deltas = [1, -1, 2, -2, 3, -3, 4, -4]

        for delta in deltas {
            let candidate = fact.sum + delta
            if answerRange.contains(candidate), candidate != fact.sum, !candidates.contains(candidate) {
                candidates.append(candidate)
            }
        }

        for candidate in answerRange where candidate != fact.sum && !candidates.contains(candidate) {
            candidates.append(candidate)
        }

        return Array(candidates.prefix(choiceCount - 1))
    }

    private static func rotationOffset(for fact: SumSprintPartyTVFact) -> Int {
        positiveModulo(fact.addendA * 31 + fact.addendB * 17 + fact.sum, choiceCount)
    }

    private static func positiveModulo(_ value: Int, _ divisor: Int) -> Int {
        let remainder = value % divisor
        return remainder >= 0 ? remainder : remainder + divisor
    }

    private static func rotate(_ values: [Int], by offset: Int) -> [Int] {
        guard !values.isEmpty else { return values }
        let split = positiveModulo(offset, values.count)
        return Array(values[split...]) + Array(values[..<split])
    }
}
