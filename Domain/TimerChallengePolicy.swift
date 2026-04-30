import Foundation


struct PlayModeChoiceCard: Identifiable, Equatable {
    let mode: PlayMode
    let title: String
    let flavor: String
    let detail: String
    let policy: TimerChallengePolicy

    var id: PlayMode { mode }

    var summaryLabel: String {
        "\(title): \(flavor)"
    }

    var accessibilityLabel: String {
        "\(title). \(flavor). \(detail)"
    }
}

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

    var choiceCard: PlayModeChoiceCard {
        switch playMode {
        case .learn:
            return PlayModeChoiceCard(
                mode: playMode,
                title: "Learn",
                flavor: "calm build",
                detail: "Build at your own pace with hints ready.",
                policy: self
            )
        case .explore:
            return PlayModeChoiceCard(
                mode: playMode,
                title: "Explore",
                flavor: "try ideas",
                detail: "Move pieces, sensors, or cards and notice what changes.",
                policy: self
            )
        case .challenge:
            return PlayModeChoiceCard(
                mode: playMode,
                title: "Challenge",
                flavor: "tricky puzzle",
                detail: "Pick a goal when you feel ready.",
                policy: self
            )
        case .timed:
            return PlayModeChoiceCard(
                mode: playMode,
                title: "Timed",
                flavor: "rocket round",
                detail: "Start the clock only after you choose it.",
                policy: self
            )
        case .review:
            return PlayModeChoiceCard(
                mode: playMode,
                title: "Review",
                flavor: "memory boost",
                detail: "Bring back cards and ideas you have seen before.",
                policy: self
            )
        }
    }

    static func choiceCards(for modes: [PlayMode]) -> [PlayModeChoiceCard] {
        modes.map { policy(for: $0).choiceCard }
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

