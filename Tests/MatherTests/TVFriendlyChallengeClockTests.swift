import Testing
@testable import Mather

@MainActor
struct TVFriendlyChallengeClockTests {
    private final class TimeSource { var time: Double = 10 }

    @Test func untimedIsDefaultAndDoesNotExpire() {
        let source = TimeSource()
        let clock = TVFriendlyChallengeClock(now: { source.time })
        clock.start()
        source.time += 1000
        clock.refresh()
        #expect(!clock.isEnabled && !clock.isRunning && !clock.isExpired)
    }

    @Test func expiryFreezesUntilMoreTimeWithoutStartingANewRound() {
        let source = TimeSource()
        let clock = TVFriendlyChallengeClock(now: { source.time })
        clock.configure(seconds: 10)
        clock.start()
        source.time += 10
        clock.refresh()
        #expect(clock.isExpired && clock.isPaused && clock.remainingSeconds == 0)
        source.time += 200
        clock.refresh()
        #expect(clock.elapsedSeconds == 10)
        clock.addMoreTime(seconds: 60)
        #expect(!clock.isExpired && clock.remainingSeconds == 60)
        source.time += 5
        clock.refresh()
        #expect(clock.remainingSeconds == 55)
    }

    @Test func overlappingInterruptionsRequireEachReasonToClose() {
        let source = TimeSource()
        let clock = TVFriendlyChallengeClock(now: { source.time })
        clock.configure(seconds: 120)
        clock.start()
        source.time += 4
        clock.pause(.options)
        clock.pause(.background)
        source.time += 100
        clock.resume(.options)
        clock.refresh()
        #expect(clock.isPaused && clock.remainingSeconds == 116)
        clock.resume(.background)
        source.time += 2
        clock.refresh()
        #expect(!clock.isPaused && clock.remainingSeconds == 114)
    }

    @Test func hintAndFeedbackPauseAndUntimedRecoveryKeepsSupportSeparate() {
        let source = TimeSource()
        let clock = TVFriendlyChallengeClock(now: { source.time })
        clock.configure(seconds: 2)
        clock.start()
        clock.pause(.hint)
        clock.pause(.feedback)
        source.time += 50
        clock.resume(.hint)
        clock.refresh()
        #expect(clock.remainingSeconds == 2)
        clock.resume(.feedback)
        source.time += 2
        clock.refresh()
        #expect(clock.isExpired)
        clock.chooseUntimed()
        #expect(!clock.isEnabled && !clock.isExpired && !clock.isRunning)
        source.time += 50
        clock.refresh()
        #expect(clock.elapsedSeconds == 2)
    }

    @Test func stopAndReplayCancelOldTiming() {
        let source = TimeSource()
        let clock = TVFriendlyChallengeClock(now: { source.time })
        clock.configure(seconds: 30)
        clock.start()
        source.time += 5
        clock.stop()
        source.time += 80
        clock.refresh()
        #expect(clock.remainingSeconds == 25 && !clock.isRunning)
        clock.configure(seconds: 30)
        clock.start()
        #expect(clock.remainingSeconds == 30 && clock.elapsedSeconds == 0)
    }

    @Test func newRoundWhileBackgroundedStartsPausedAndBackwardTimeDoesNotSubtract() {
        let source = TimeSource()
        let clock = TVFriendlyChallengeClock(now: { source.time })
        clock.pause(.background)
        clock.configure(seconds: 10)
        clock.start()
        source.time += 90
        clock.refresh()
        #expect(clock.isPaused && clock.remainingSeconds == 10)
        clock.resume(.background)
        source.time -= 1
        clock.refresh()
        #expect(clock.remainingSeconds == 10)
    }
}
