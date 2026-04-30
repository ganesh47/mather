import Foundation

struct TimerChallengePolicy: Equatable, Sendable {
    struct ChallengeGoal: Equatable, Sendable {
        let targetCount: Int
        let label: String

        init(targetCount: Int, label: String) {
            precondition(targetCount > 0, "Challenge goals should have a positive target.")
            precondition(!label.isEmpty, "Challenge goals should have a label.")
            self.targetCount = targetCount
            self.label = label
        }
    }

    let playMode: PlayMode
    let timeLimitSeconds: Int?
    let challengeGoal: ChallengeGoal?
    let allowsPause: Bool
    let childFacingLabel: String

    var isTimed: Bool { timeLimitSeconds != nil }
    var isChallenge: Bool { challengeGoal != nil }

    init(
        playMode: PlayMode,
        timeLimitSeconds: Int? = nil,
        challengeGoal: ChallengeGoal? = nil,
        allowsPause: Bool = true,
        childFacingLabel: String
    ) {
        if let timeLimitSeconds {
            precondition(timeLimitSeconds > 0, "Timed policies should have a positive duration.")
        }
        precondition(!childFacingLabel.isEmpty, "Timer policy labels should not be empty.")

        self.playMode = playMode
        self.timeLimitSeconds = timeLimitSeconds
        self.challengeGoal = challengeGoal
        self.allowsPause = allowsPause
        self.childFacingLabel = childFacingLabel
    }
}

extension TimerChallengePolicy {
    static let relaxed = TimerChallengePolicy(
        playMode: .learn,
        childFacingLabel: "Take your time"
    )

    static func challenge(targetCount: Int, label: String = "Try the set") -> TimerChallengePolicy {
        TimerChallengePolicy(
            playMode: .challenge,
            challengeGoal: ChallengeGoal(targetCount: targetCount, label: label),
            childFacingLabel: label
        )
    }

    static func timed(seconds: Int, label: String = "Beat the clock") -> TimerChallengePolicy {
        TimerChallengePolicy(
            playMode: .timed,
            timeLimitSeconds: seconds,
            childFacingLabel: label
        )
    }

    static func timedChallenge(
        seconds: Int,
        targetCount: Int,
        label: String = "Try the sprint"
    ) -> TimerChallengePolicy {
        TimerChallengePolicy(
            playMode: .timed,
            timeLimitSeconds: seconds,
            challengeGoal: ChallengeGoal(targetCount: targetCount, label: label),
            childFacingLabel: label
        )
    }
}
