import Testing
@testable import Mather

struct TimerChallengePolicyTests {
    @Test
    func timedPolicyUsesOptInCountdown() {
        let policy = TimerChallengePolicy.policy(for: .timed)

        #expect(policy.usesTimer)
        #expect(policy.timerSeconds == 60)
        #expect(policy.startPrompt.contains("Tap when ready"))
        #expect(policy.activeTimerLabel == "Time left")
        #expect(policy.timeExpiredMessage != nil)
    }

    @Test
    func nonTimedModesDoNotUseCountdowns() {
        for mode in PlayMode.allCases where mode != .timed {
            let policy = TimerChallengePolicy.policy(for: mode)

            #expect(!policy.usesTimer)
            #expect(policy.timerSeconds == nil)
            #expect(policy.activeTimerLabel == nil)
            #expect(policy.timeExpiredMessage == nil)
        }
    }

    @Test
    func choiceCardsExposeChildChoiceCopy() {
        let cards = TimerChallengePolicy.choiceCards(for: [.learn, .challenge, .timed, .review])

        #expect(cards.map(\.mode) == [.learn, .challenge, .timed, .review])
        #expect(cards.first?.summaryLabel == "Learn: calm build")
        #expect(cards.first { $0.mode == .timed }?.policy.usesTimer == true)
        #expect(cards.first { $0.mode == .timed }?.detail.contains("choose") == true)
    }

    @Test
    func policyCopyAvoidsShameAndPressureLanguage() {
        let blockedTerms = [
            "shame",
            "fail",
            "failed",
            "wrong",
            "lose",
            "lost",
            "hurry",
            "punish",
            "punishment",
        ]

        for mode in PlayMode.allCases {
            let policy = TimerChallengePolicy.policy(for: mode)
            let text = [
                policy.startPrompt,
                policy.activeTimerLabel,
                policy.completionMessage,
                policy.timeExpiredMessage,
                policy.choiceCard.title,
                policy.choiceCard.flavor,
                policy.choiceCard.detail,
            ]
            .compactMap { $0 }
            .joined(separator: " ")
            .lowercased()

            for term in blockedTerms {
                #expect(!text.contains(term))
            }
        }
    }
}

