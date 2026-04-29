import Foundation

enum ArrayPreludeDifficulty: String, CaseIterable, Equatable {
    case easy
    case standard
    case flip

    var menuLabel: String {
        switch self {
        case .easy: "Easy"
        case .standard: "Standard"
        case .flip: "Flip mode"
        }
    }

    var pairCount: Int {
        switch self {
        case .easy: 3
        case .standard: 4
        case .flip: 4
        }
    }

    var showsEquation: Bool {
        switch self {
        case .easy: false
        case .standard, .flip: true
        }
    }

    var startsFaceDown: Bool {
        self == .flip
    }
}

struct ArrayFact: Identifiable, Hashable {
    let rows: Int
    let columns: Int

    init(rows: Int, columns: Int) {
        precondition(rows > 1, "Array prelude facts should avoid 1-row multiplication introductions.")
        precondition(columns > 1, "Array prelude facts should avoid 1-column multiplication introductions.")
        self.rows = rows
        self.columns = columns
    }

    var id: String { canonicalKey }
    var product: Int { rows * columns }
    var canonicalRows: Int { min(rows, columns) }
    var canonicalColumns: Int { max(rows, columns) }
    var canonicalKey: String { "\(canonicalRows)x\(canonicalColumns)" }
    var rowColumnPhrase: String { "\(rows) rows of \(columns)" }
    var spokenPrompt: String { "Pack \(product) boxes as \(rows) rows of \(columns)." }
    var equationText: String { "\(rows) x \(columns) = \(product)" }

    func matches(product: Int) -> Bool {
        self.product == product
    }
}

struct ArrayPreludeRound: Equatable {
    struct Step: Identifiable, Equatable {
        let fact: ArrayFact
        let totalChoices: [Int]

        var id: String { fact.id }
    }

    let difficulty: ArrayPreludeDifficulty
    let steps: [Step]

    static let teachingFacts: [ArrayFact] = [
        ArrayFact(rows: 2, columns: 2),
        ArrayFact(rows: 2, columns: 3),
        ArrayFact(rows: 3, columns: 2),
        ArrayFact(rows: 2, columns: 4),
        ArrayFact(rows: 3, columns: 3),
        ArrayFact(rows: 3, columns: 4),
        ArrayFact(rows: 4, columns: 3)
    ]

    static func make(difficulty: ArrayPreludeDifficulty, seed: Int = 0) -> ArrayPreludeRound {
        let rotated = rotatedFacts(seed: seed)
        let uniqueFacts = uniqueByCanonicalKey(rotated).prefix(difficulty.pairCount)
        let steps = uniqueFacts.map { fact in
            Step(fact: fact, totalChoices: totalChoices(for: fact))
        }
        return ArrayPreludeRound(difficulty: difficulty, steps: Array(steps))
    }

    static func handoffTarget(after round: ArrayPreludeRound) -> Int {
        round.steps.last?.fact.product ?? 4
    }

    private static func rotatedFacts(seed: Int) -> [ArrayFact] {
        guard !teachingFacts.isEmpty else { return [] }
        let offset = abs(seed) % teachingFacts.count
        return Array(teachingFacts.dropFirst(offset)) + Array(teachingFacts.prefix(offset))
    }

    private static func uniqueByCanonicalKey(_ facts: [ArrayFact]) -> [ArrayFact] {
        var seen: Set<String> = []
        return facts.filter { fact in
            seen.insert(fact.canonicalKey).inserted
        }
    }

    private static func totalChoices(for fact: ArrayFact) -> [Int] {
        let candidates = [
            fact.product,
            fact.product + fact.rows,
            max(2, fact.product - fact.columns),
            fact.product + fact.columns
        ]
        var seen: Set<Int> = []
        return candidates
            .filter { $0 >= 2 }
            .filter { seen.insert($0).inserted }
            .prefix(3)
            .sorted()
    }
}
