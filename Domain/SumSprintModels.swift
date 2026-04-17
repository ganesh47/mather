import Foundation

// MARK: - ArithmeticFact

/// A single addition fact: addendA + addendB = sum, where sum is in 11…20.
struct ArithmeticFact: Identifiable, Codable, Hashable {
    let id: UUID
    let addendA: Int
    let addendB: Int

    var sum: Int { addendA + addendB }

    /// Stable string key used as the primary key in StoredFactRecord.
    var factKey: String { "\(addendA)+\(addendB)" }
}

// MARK: - LeitnerBox

enum LeitnerBox: Int, Codable, CaseIterable {
    case box0 = 0   // new / failed — shown every session
    case box1 = 1   // first correct — shown every 2 sessions
    case box2 = 2   // mastered — shown every 5 sessions
}

// MARK: - Card

struct SumSprintCard: Identifiable, Equatable {
    let id: UUID
    let fact: ArithmeticFact
    var typedAnswer: String = ""
    var result: CardResult = .unanswered
    var attemptCount: Int = 0
}

enum CardResult: Equatable {
    case unanswered
    case correct(firstTry: Bool)
    case incorrect(attempts: Int)
}

// MARK: - Session summary

struct SumSprintSessionSummary: Equatable {
    let sessionId: UUID
    let startedAt: Date
    let endedAt: Date
    let cards: [SumSprintCard]
    let peakStreak: Int

    var correctCount: Int {
        cards.filter {
            if case .correct = $0.result { return true }
            return false
        }.count
    }

    var firstTryAccuracy: Double {
        guard !cards.isEmpty else { return 0 }
        let firstTry = cards.filter {
            if case .correct(let ft) = $0.result { return ft }
            return false
        }.count
        return Double(firstTry) / Double(cards.count)
    }
}

// MARK: - Engine phase

enum SumSprintPhase: Equatable {
    case idle
    case session
    case summary
}
