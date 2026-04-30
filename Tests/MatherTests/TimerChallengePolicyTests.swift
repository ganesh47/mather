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

