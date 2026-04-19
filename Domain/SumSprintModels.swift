import Foundation
import SwiftUI

// MARK: - SumSprintDifficulty

/// Three difficulty tiers selectable from the pre-session picker.
enum SumSprintDifficulty: String, Codable, CaseIterable {
    /// No countdown — child answers at their own pace.  10 cards per session.
    case relaxed
    /// 12-second countdown per card.  10 cards.  Moderate pressure.
    case standard
    /// 8-second countdown per card.  15 cards.  High pressure; timed-out
    /// cards are re-queued at the end so no fact goes unreviewed.
    case sprint

    var label: String {
        switch self {
        case .relaxed:  return "Relaxed"
        case .standard: return "Standard"
        case .sprint:   return "Sprint"
        }
    }

    var emoji: String {
        switch self {
        case .relaxed:  return "🐢"
        case .standard: return "🐇"
        case .sprint:   return "⚡️"
        }
    }

    /// Returns nil for relaxed (no timer).
    var secondsPerCard: Double? {
        switch self {
        case .relaxed:  return nil
        case .standard: return 12
        case .sprint:   return 8
        }
    }

    var cardCount: Int {
        switch self {
        case .relaxed, .standard: return 10
        case .sprint:             return 15
        }
    }

    var description: String {
        switch self {
        case .relaxed:  return "No timer · 10 cards · practice at your own pace"
        case .standard: return "12 s per card · 10 cards · a little pressure"
        case .sprint:   return "8 s per card · 15 cards · missed cards come back!"
        }
    }

    var timerColor: Color {
        switch self {
        case .relaxed:  return MatherTheme.accent
        case .standard: return MatherTheme.warm
        case .sprint:   return MatherTheme.coral
        }
    }
}

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
    /// Seconds from card-shown to correct submission.  Nil if timed out or unanswered.
    var elapsedSeconds: Double? = nil
    var timedOut: Bool = false
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
    let difficulty: SumSprintDifficulty

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

    var timeoutCount: Int { cards.filter(\.timedOut).count }

    /// Elapsed seconds for the fastest first-try correct card.
    var fastestCardSeconds: Double? {
        cards.compactMap { card -> Double? in
            if case .correct(let ft) = card.result, ft { return card.elapsedSeconds }
            return nil
        }.min()
    }
}

// MARK: - Engine phase

enum SumSprintPhase: Equatable {
    case idle
    case difficultyPick
    case session
    case summary
}
