import Foundation
import Observation

/// Owns all learning state. Focus, navigation and animation remain in the view.
@MainActor
@Observable
final class CompareCampEngine {
    enum Phase: Equatable { case choosingCamp, playing, completed }

    private(set) var phase: Phase = .choosingCamp
    private(set) var category: CompareCampCategory?
    private(set) var activity: CompareCampActivity = .adventure
    private(set) var difficulty: CompareCampDifficulty = .growing
    private(set) var seed: UInt64 = 0
    private(set) var round: CompareCampRound?
    private(set) var roundIndex = 0
    private(set) var completedRoundCount = 0
    private(set) var firstTryCount = 0
    private(set) var helpedRoundCount = 0
    private(set) var currentLeftCount = 0
    private(set) var selectedAnswerID: String?
    private(set) var lastAnswerWasCorrect: Bool?
    private(set) var hintShown = false
    private(set) var isArranged = false
    private(set) var countedLeft = 0
    private(set) var countedRight = 0
    private(set) var completion: CompareCampSessionResult?
    private var attemptCount = 0
    private var usedHelp = false

    var roundGoal: Int { 8 }
    var currentRightCount: Int { round?.rightCount ?? 0 }
    var hasSolvedRound: Bool { lastAnswerWasCorrect == true }
    var canAdd: Bool { canBuild && currentLeftCount < difficulty.maxCount }
    var canRemove: Bool { canBuild && currentLeftCount > 0 }
    var pairedCount: Int { min(currentLeftCount, round?.rightCount ?? 0) }
    var unmatchedLeft: Int { max(0, currentLeftCount - pairedCount) }
    var unmatchedRight: Int { max(0, (round?.rightCount ?? 0) - pairedCount) }
    var revealedLeftCount: Int? { countedLeft >= currentLeftCount ? currentLeftCount : nil }
    var revealedRightCount: Int? {
        guard let round else { return nil }
        return countedRight >= round.rightCount ? round.rightCount : nil
    }
    var progressText: String {
        switch phase {
        case .choosingCamp: return "Choose your camp"
        case .playing: return "Stop \(roundIndex + 1) of \(roundGoal)"
        case .completed: return "\(completedRoundCount) discoveries complete"
        }
    }
    var feedbackText: String {
        if hasSolvedRound {
            if round?.activity == .makeEqual { return "You made a match! Both groups have \(currentLeftCount)." }
            return "You found it! \(round?.explanation ?? "")"
        }
        if lastAnswerWasCorrect == false {
            return round?.activity == .makeEqual
                ? "Keep exploring. Add or remove one, then check your match."
                : "Let's look again. You can count each group or pair them up."
        }
        if hintShown { return "Pair one from each group. Look for any that have no partner." }
        return "Take your time. Every discovery starts with a little exploring."
    }
    var currentPrompt: String {
        switch phase {
        case .choosingCamp:
            return "Welcome to Compare Camp. Choose a place, a number size, and an adventure. Swipe to explore and press select to choose."
        case .completed:
            return "Camp complete! You made \(completedRoundCount) discoveries. Choose Play Again for a new adventure, or choose another camp."
        case .playing:
            guard let round else { return "" }
            if hasSolvedRound {
                let explanation = round.activity == .makeEqual
                    ? "You made a match. Both groups have \(round.category.quantityText(currentLeftCount)). \(currentLeftCount) is equal to \(round.rightCount)."
                    : round.explanation
                return "\(explanation) Press select on \(roundIndex == roundGoal - 1 ? "Finish Camp" : "Next Stop") to continue."
            }
            if hintShown {
                return "\(round.spokenPrompt) Pair one from each group. A pair has one left and one right. Look for the ones with no partner. If all have partners, the groups match."
            }
            return round.spokenPrompt
        }
    }

    func start(
        category: CompareCampCategory, activity: CompareCampActivity = .adventure,
        difficulty: CompareCampDifficulty = .growing, seed: UInt64 = 0
    ) {
        self.category = category
        self.activity = activity
        self.difficulty = difficulty
        self.seed = seed
        phase = .playing
        roundIndex = 0
        completedRoundCount = 0
        firstTryCount = 0
        helpedRoundCount = 0
        completion = nil
        loadRound(previous: nil)
    }

    @discardableResult
    func select(answerID: String) -> Bool {
        guard phase == .playing, !hasSolvedRound, let round, round.activity != .makeEqual,
              round.choices.contains(where: { $0.id == answerID }) else { return false }
        selectedAnswerID = answerID
        return evaluate(answerID == round.correctAnswerID)
    }

    /// Remote controls change exactly one item at a time. Reject other deltas,
    /// including overflowing integers, rather than silently changing the task.
    func adjustLeft(by delta: Int) {
        guard canBuild, delta == 1 || delta == -1 else { return }
        guard delta == 1 ? canAdd : canRemove else { return }
        currentLeftCount += delta
        countedLeft = 0
        selectedAnswerID = nil
        lastAnswerWasCorrect = nil
    }

    @discardableResult
    func checkBuild() -> Bool {
        guard canBuild, let round else { return false }
        let correct = currentLeftCount == round.rightCount
        selectedAnswerID = correct ? "balanced" : "check"
        return evaluate(correct)
    }

    func showHint() {
        guard phase == .playing, !hasSolvedRound else { return }
        hintShown = true
        isArranged = true
        usedHelp = true
    }

    func arrange() {
        guard phase == .playing, !hasSolvedRound else { return }
        isArranged = true
        usedHelp = true
    }

    /// Advances a tally once per item. A completed tally cannot inflate counts.
    @discardableResult
    func countNext(side: CompareCampSide) -> Int? {
        guard phase == .playing, !hasSolvedRound, let round else { return nil }
        switch side {
        case .left:
            guard countedLeft < currentLeftCount else { return nil }
            countedLeft += 1
            usedHelp = true
            return countedLeft
        case .right:
            guard countedRight < round.rightCount else { return nil }
            countedRight += 1
            usedHelp = true
            return countedRight
        }
    }

    func advance() {
        guard phase == .playing, hasSolvedRound else { return }
        if completedRoundCount == roundGoal {
            guard let category else { return }
            phase = .completed
            completion = CompareCampSessionResult(
                categoryID: category.id, activity: activity, difficulty: difficulty, seed: seed,
                roundsCompleted: completedRoundCount, firstTryCount: firstTryCount,
                helpedRoundCount: helpedRoundCount
            )
            return
        }
        let previous = round
        roundIndex += 1
        loadRound(previous: previous)
    }

    func replay() {
        guard let category else { return }
        start(category: category, activity: activity, difficulty: difficulty, seed: seed &+ 1)
    }

    func chooseAnotherCamp() {
        phase = .choosingCamp
        round = nil
        roundIndex = 0
        completedRoundCount = 0
        firstTryCount = 0
        helpedRoundCount = 0
        completion = nil
        selectedAnswerID = nil
        lastAnswerWasCorrect = nil
        hintShown = false
        isArranged = false
        countedLeft = 0
        countedRight = 0
        currentLeftCount = 0
        attemptCount = 0
        usedHelp = false
    }

    private var canBuild: Bool { phase == .playing && !hasSolvedRound && round?.activity == .makeEqual }

    private func evaluate(_ correct: Bool) -> Bool {
        lastAnswerWasCorrect = correct
        if correct {
            completedRoundCount += 1
            if attemptCount == 0 { firstTryCount += 1 }
            if usedHelp || attemptCount > 0 { helpedRoundCount += 1 }
        } else {
            attemptCount += 1
        }
        return correct
    }

    private func loadRound(previous: CompareCampRound?) {
        guard let category else { return }
        round = .make(category: category, activity: activity, difficulty: difficulty,
                      index: roundIndex, seed: seed, previous: previous)
        currentLeftCount = round?.leftCount ?? 0
        selectedAnswerID = nil
        lastAnswerWasCorrect = nil
        hintShown = false
        isArranged = false
        countedLeft = 0
        countedRight = 0
        attemptCount = 0
        usedHelp = false
    }
}
