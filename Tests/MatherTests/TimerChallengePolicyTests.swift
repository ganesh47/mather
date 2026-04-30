import XCTest
@testable import Mather

final class TimerChallengePolicyTests: XCTestCase {
    func testRelaxedPolicyHasNoTimerOrChallengeGoal() {
        let policy = TimerChallengePolicy.relaxed

        XCTAssertEqual(policy.playMode, .learn)
        XCTAssertFalse(policy.isTimed)
        XCTAssertFalse(policy.isChallenge)
        XCTAssertNil(policy.timeLimitSeconds)
        XCTAssertNil(policy.challengeGoal)
        XCTAssertEqual(policy.childFacingLabel, "Take your time")
    }

    func testTimedAndChallengePoliciesCanBeOptionalOrCombined() throws {
        let timed = TimerChallengePolicy.timed(seconds: 60)
        let challenge = TimerChallengePolicy.challenge(targetCount: 8, label: "Try eight")
        let combined = TimerChallengePolicy.timedChallenge(seconds: 90, targetCount: 10)

        XCTAssertTrue(timed.isTimed)
        XCTAssertFalse(timed.isChallenge)
        XCTAssertEqual(timed.timeLimitSeconds, 60)

        XCTAssertFalse(challenge.isTimed)
        XCTAssertTrue(challenge.isChallenge)
        XCTAssertEqual(try XCTUnwrap(challenge.challengeGoal).targetCount, 8)

        XCTAssertTrue(combined.isTimed)
        XCTAssertTrue(combined.isChallenge)
        XCTAssertEqual(combined.timeLimitSeconds, 90)
        XCTAssertEqual(try XCTUnwrap(combined.challengeGoal).targetCount, 10)
    }

    func testDefaultPolicyLabelsAvoidShameLanguage() {
        let labels = [
            TimerChallengePolicy.relaxed.childFacingLabel,
            TimerChallengePolicy.challenge(targetCount: 5).childFacingLabel,
            TimerChallengePolicy.timed(seconds: 30).childFacingLabel,
            TimerChallengePolicy.timedChallenge(seconds: 45, targetCount: 6).childFacingLabel,
        ]
        let shameWords = ["fail", "failed", "wrong", "slow", "bad", "mistake", "missed", "lost"]

        for label in labels {
            let lowercased = label.lowercased()
            XCTAssertFalse(
                shameWords.contains { lowercased.contains($0) },
                "\(label) should avoid shame language"
            )
        }
    }
}
