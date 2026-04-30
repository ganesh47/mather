import Foundation

struct TimerChallengePolicy: Equatable {
    let playMode: PlayMode
    let timerSeconds: Int?
    let startPrompt: String
    let activeTimerLabel: String?
    let completionMessage: String
    let timeExpiredMessage: String?

    var usesTimer: Bool {
        timerSeconds != nil
    }

    static func policy(for playMode: PlayMode) -> TimerChallengePolicy {
        switch playMode {
        case .learn:
            return TimerChallengePolicy(
                playMode: playMode,
                timerSeconds: nil,
                startPrompt: "Build at your own pace.",
                activeTimerLabel: nil,
                completionMessage: "Nice thinking.",
                timeExpiredMessage: nil
            )
        case .explore:
            return TimerChallengePolicy(
                playMode: playMode,
                timerSeconds: nil,
                startPrompt: "Try ideas and see what happens.",
                activeTimerLabel: nil,
                completionMessage: "You explored the pattern.",
                timeExpiredMessage: nil
            )
        case .challenge:
            return TimerChallengePolicy(
                playMode: playMode,
                timerSeconds: nil,
                startPrompt: "Try the challenge when you are ready.",
                activeTimerLabel: nil,
                completionMessage: "Challenge complete.",
                timeExpiredMessage: nil
            )
        case .timed:
            return TimerChallengePolicy(
                playMode: playMode,
                timerSeconds: 60,
                startPrompt: "Tap when ready. The clock starts after your tap.",
                activeTimerLabel: "Time left",
                completionMessage: "Round complete.",
                timeExpiredMessage: "Time is up. Take a breath and try another round."
            )
        case .review:
            return TimerChallengePolicy(
                playMode: playMode,
                timerSeconds: nil,
                startPrompt: "Review a few cards.",
                activeTimerLabel: nil,
                completionMessage: "Review complete.",
                timeExpiredMessage: nil
            )
        }
    }
}

