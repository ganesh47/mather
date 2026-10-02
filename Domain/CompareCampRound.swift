import Foundation

struct CompareCampChoice: Identifiable, Equatable, Sendable {
    let id: String
    let title: String
    let spokenTitle: String
    let symbolName: String
    let value: Int?
}

struct CompareCampRound: Equatable, Sendable {
    let index: Int
    let category: CompareCampCategory
    /// The actual task may differ from the chosen adventure or scaffolded practice.
    let activity: CompareCampActivity
    let stage: CompareCampStage
    let leftCount: Int
    let rightCount: Int
    let maxCount: Int
    let choices: [CompareCampChoice]

    var relation: CompareCampRelation { .comparing(leftCount, rightCount) }
    var difference: Int { abs(leftCount - rightCount) }
    var usesTimer: Bool { false }
    var correctAnswerID: String {
        switch activity {
        case .more, .adventure:
            return relation == .equal ? "same" : relation == .greater ? "left" : "right"
        case .fewer:
            return relation == .equal ? "same" : relation == .less ? "left" : "right"
        case .symbols: return relation.rawValue
        case .difference: return "number-\(difference)"
        case .makeEqual: return "balanced"
        }
    }
    var question: String {
        switch activity {
        case .adventure, .more: return "Which group has more?"
        case .fewer: return "Which group has fewer?"
        case .makeEqual: return "Can you make the groups match?"
        case .difference: return "How many extra are in the bigger group?"
        case .symbols: return "Which sign fits between the numbers?"
        }
    }
    var spokenPrompt: String {
        let subject = category.tokenPlural
        switch activity {
        case .makeEqual:
            return "Make the two groups of \(subject) match. Add or remove one on the left, then choose Check Match. Press Play Pause to hear the question again."
        case .symbols:
            return "Compare \(leftCount) with \(rightCount). Choose less than, equal to, or greater than. You can count or pair the groups for help."
        case .difference:
            return "How many extra \(subject) are in the bigger group? Match one from each group, then count the ones left over. Equal groups have zero extras."
        case .more, .adventure:
            return "Which group has more \(subject)? Choose left, right, or the same. Take your time. You can count or pair them for help."
        case .fewer:
            return "Which group has fewer \(subject)? Fewer means a smaller number. Choose left, right, or the same. You can count or pair them for help."
        }
    }
    var explanation: String {
        let quantities = "Left has \(category.quantityText(leftCount)). Right has \(category.quantityText(rightCount))."
        if relation == .equal { return "\(quantities) They match, with no extras. \(leftCount) is equal to \(rightCount)." }
        let bigger = relation == .greater ? "left" : "right"
        let smaller = relation == .greater ? "right" : "left"
        return "\(quantities) The \(bigger) group has more and the \(smaller) has fewer. After pairing, \(difference) \(difference == 1 ? "is" : "are") left over. \(leftCount) \(relation.spokenName) \(rightCount)."
    }

    /// A deterministic task generator makes replay varied and count/relation invariants testable.
    static func make(
        category: CompareCampCategory, activity: CompareCampActivity,
        difficulty: CompareCampDifficulty, index: Int, seed: UInt64 = 0,
        previous: CompareCampRound? = nil
    ) -> Self {
        let normalizedIndex = positiveModulo(index, 8)
        let stage = CompareCampStage.allCases[normalizedIndex / 2]
        let task = actualActivity(activity, index: normalizedIndex)
        let categoryIndex = CompareCampCategory.all.firstIndex { $0.id == category.id } ?? 0
        var random = CompareCampRandom(seed: seed
                                       &+ UInt64(normalizedIndex) &* 0x9E3779B97F4A7C15
                                       &+ UInt64(categoryIndex) &* 0xD1B54A32D192ED03)
        let subject = stage == .transfer ? transferCategory(from: category, random: &random) : category
        let maxCount = difficulty.maxCount
        // Every three comparison tasks rotate through less/equal/greater. Build
        // tasks begin unequal so selecting Check Match alone cannot solve them.
        let offset = Int(seed % 3)
        var desired = CompareCampRelation.allCases[(normalizedIndex + offset) % 3]
        if task == .makeEqual, desired == .equal {
            desired = normalizedIndex.isMultiple(of: 2) ? .less : .greater
        }
        var pairs: [(Int, Int)] = []
        for left in 0...maxCount {
            for right in 0...maxCount where CompareCampRelation.comparing(left, right) == desired {
                if let previous, left == previous.leftCount, right == previous.rightCount { continue }
                pairs.append((left, right))
            }
        }
        let pair = pairs[random.nextInt(upperBound: pairs.count)]
        let answerDifference = abs(pair.0 - pair.1)
        let choices = makeChoices(activity: task, difference: answerDifference, maxCount: maxCount, random: &random)
        return Self(index: normalizedIndex, category: subject, activity: task, stage: stage,
                    leftCount: pair.0, rightCount: pair.1, maxCount: maxCount, choices: choices)
    }

    private static func actualActivity(_ activity: CompareCampActivity, index: Int) -> CompareCampActivity {
        if activity == .adventure {
            return [.makeEqual, .makeEqual, .more, .fewer, .symbols, .symbols, .more, .difference][index]
        }
        // Introduce signs through manipulable quantities before displaying a
        // bare comparison. Difference practice begins with building a match.
        if activity == .symbols {
            return [.makeEqual, .makeEqual, .more, .fewer, .symbols, .symbols, .symbols, .symbols][index]
        }
        if activity == .difference, index < 2 { return .makeEqual }
        return activity
    }

    private static func transferCategory(from original: CompareCampCategory, random: inout CompareCampRandom) -> CompareCampCategory {
        let options = CompareCampCategory.all.filter { $0.region != original.region }
        return options[random.nextInt(upperBound: options.count)]
    }

    private static func makeChoices(
        activity: CompareCampActivity, difference: Int, maxCount: Int,
        random: inout CompareCampRandom
    ) -> [CompareCampChoice] {
        switch activity {
        case .makeEqual: return []
        case .symbols:
            return CompareCampRelation.allCases.map {
                CompareCampChoice(id: $0.rawValue, title: $0.symbol,
                                  spokenTitle: $0 == .less ? "Less than" : $0 == .equal ? "Equal to" : "Greater than",
                                  symbolName: $0 == .less ? "lessthan" : $0 == .equal ? "equal" : "greaterthan", value: nil)
            }
        case .difference:
            var values = [difference]
            // Plausible neighbouring counts, always distinct and in range.
            for delta in [1, -1, 2, -2, 3, -3] {
                let value = difference + delta
                if (0...maxCount).contains(value), !values.contains(value) { values.append(value) }
                if values.count == 3 { break }
            }
            values.sort()
            let rotation = random.nextInt(upperBound: values.count)
            let rotated = Array(values[rotation...]) + Array(values[..<rotation])
            return rotated.map { CompareCampChoice(id: "number-\($0)", title: "\($0)", spokenTitle: "\($0) extra", symbolName: "circle", value: $0) }
        default:
            let word = activity == .fewer ? "fewer" : "more"
            return [
                .init(id: "left", title: "Left has \(word)", spokenTitle: "Left has \(word)", symbolName: "arrow.left.circle.fill", value: nil),
                .init(id: "same", title: "They are the same", spokenTitle: "They have the same number", symbolName: "equal.circle.fill", value: nil),
                .init(id: "right", title: "Right has \(word)", spokenTitle: "Right has \(word)", symbolName: "arrow.right.circle.fill", value: nil)
            ]
        }
    }

    private static func positiveModulo(_ value: Int, _ divisor: Int) -> Int {
        let remainder = value % divisor
        return remainder < 0 ? remainder + divisor : remainder
    }
}

private struct CompareCampRandom {
    private var state: UInt64
    init(seed: UInt64) { state = seed }
    mutating func nextInt(upperBound: Int) -> Int {
        precondition(upperBound > 0)
        state &+= 0x9E3779B97F4A7C15
        var value = state
        value = (value ^ (value >> 30)) &* 0xBF58476D1CE4E5B9
        value = (value ^ (value >> 27)) &* 0x94D049BB133111EB
        value ^= value >> 31
        return Int(value % UInt64(upperBound))
    }
}
