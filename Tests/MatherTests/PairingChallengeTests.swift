import Testing
@testable import Mather

struct PairingChallengeTests {
    @Test
    func matchesConfiguredPairAndEmitsChildFeedback() {
        let challenge = PairingChallenge<String>.numberBonds(target: 6)
        var session = PairingChallengeSession(challenge: challenge)

        let outcome = session.attempt(leftID: "left-1", rightID: "right-5")

        #expect(outcome.result == .matched)
        #expect(outcome.pairID == "bond-1-5")
        #expect(outcome.feedback.spokenPrompt == "1 and 5 make 6.")
        #expect(outcome.hapticCue == .match)
        #expect(session.matchCount == 1)
        #expect(session.attemptCount == 1)
        #expect(!session.isComplete)
    }

    @Test
    func preventsDuplicateMatchesFromCountingTwice() {
        let challenge = PairingChallenge<String>.numberBonds(target: 6)
        var session = PairingChallengeSession(challenge: challenge)

        _ = session.attempt(leftID: "left-1", rightID: "right-5")
        let duplicate = session.attempt(leftID: "left-1", rightID: "right-5")

        #expect(duplicate.result == .alreadyMatched)
        #expect(duplicate.hapticCue == .none)
        #expect(session.matchCount == 1)
        #expect(session.attemptCount == 1)
    }

    @Test
    func mismatchDoesNotCompleteOrRecordPair() {
        let challenge = PairingChallenge<String>.numberBonds(target: 6)
        var session = PairingChallengeSession(challenge: challenge)

        let outcome = session.attempt(leftID: "left-1", rightID: "right-4")

        #expect(outcome.result == .mismatch)
        #expect(outcome.pairID == nil)
        #expect(outcome.feedback == .tryAgain("Try another pair."))
        #expect(outcome.hapticCue == .mismatch)
        #expect(session.matchCount == 0)
        #expect(session.attemptCount == 1)
        #expect(!session.isComplete)
    }

    @Test
    func lastPairCompletesChallenge() {
        let challenge = PairingChallenge<String>.numberBonds(target: 4)
        var session = PairingChallengeSession(challenge: challenge)

        let first = session.attempt(leftID: "left-1", rightID: "right-3")
        let second = session.attempt(leftID: "left-2", rightID: "right-2")

        #expect(first.result == .matched)
        #expect(second.result == .completed)
        #expect(second.feedback == .completed("Challenge complete."))
        #expect(second.hapticCue == .complete)
        #expect(session.isComplete)
        #expect(session.remainingPairCount == 0)
    }

    @Test
    func timedChallengeUsesTimerPolicyAndLocksAfterExpiration() {
        let challenge = PairingChallenge<String>.geometryShapes(playMode: .timed)
        var session = PairingChallengeSession(challenge: challenge)

        #expect(challenge.config.timer.playMode == .timed)
        #expect(challenge.config.timer.usesTimer)
        #expect(challenge.config.timer.durationSeconds == 60)
        #expect(!session.timerStarted)

        session.startTimerIfNeeded()
        #expect(session.timerStarted)

        let expiredFeedback = session.expireTimer()
        let outcome = session.attempt(leftID: "circle", rightID: "round")

        #expect(expiredFeedback == .timeExpired("Time is up. Take a breath and try another round."))
        #expect(outcome.result == .timeExpired)
        #expect(outcome.hapticCue == .none)
        #expect(session.matchCount == 0)
        #expect(session.attemptCount == 0)
    }

    @Test
    func staticChallengeFactoriesCoverTargetPairingStyles() {
        let numberBond = PairingChallenge<String>.numberBonds(target: 10)
        let geometry = PairingChallenge<String>.geometryShapes()
        let physics = PairingChallenge<String>.physicsCauseEffect()
        let map = PairingChallenge<String>.mapPlaces()

        #expect(numberBond.config.kind == .numberBond)
        #expect(numberBond.pairs.allSatisfy { $0.id.hasPrefix("bond-") })
        #expect(geometry.config.kind == .geometry)
        #expect(geometry.pair(leftID: "triangle", rightID: "three-sides") != nil)
        #expect(physics.config.kind == .physics)
        #expect(physics.pair(leftID: "drop", rightID: "falls") != nil)
        #expect(map.config.kind == .mapWorld)
        #expect(map.pair(leftID: "river", rightID: "blue-line") != nil)
    }
}
