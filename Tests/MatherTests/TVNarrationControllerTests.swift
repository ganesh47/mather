import Foundation
import Testing
@testable import Mather

@MainActor
struct TVNarrationControllerTests {
    @MainActor
    private final class Playback {
        var spoken: [String] = []
        var stopCount = 0
        var speaking = false
        var voiceOver = false
        var waits: [CheckedContinuation<Void, Never>] = []

        func makeController() -> TVNarrationController {
            TVNarrationController(
                speak: { self.spoken.append($0) },
                stop: { self.stopCount += 1; self.speaking = false },
                isSpeaking: { self.speaking },
                voiceOverRunning: { self.voiceOver },
                delay: { _ in await withCheckedContinuation { self.waits.append($0) } }
            )
        }

        func settle() async {
            for _ in 0..<20 { await Task.yield() }
        }

        func releaseWaits() async {
            let pending = waits
            waits.removeAll()
            for wait in pending { wait.resume() }
            await settle()
        }
    }

    @Test func rapidFocusChangesOnlySpeakLatestChoice() async {
        let playback = Playback()
        let narration = playback.makeController()
        narration.focus("Three")
        await playback.settle()
        narration.focus("Eight")
        await playback.settle()
        await playback.releaseWaits()
        #expect(playback.spoken == ["Eight"])
        narration.stop()
    }

    @Test func automaticFocusWaitsForPromptThenSpeaksChoice() async {
        let playback = Playback()
        let narration = playback.makeController()
        narration.presentPrompt("Which animal is this?")
        playback.speaking = true
        narration.focus("Lion")
        await playback.settle()
        await playback.releaseWaits()
        #expect(playback.spoken == ["Which animal is this?"])
        playback.speaking = false
        await playback.releaseWaits()
        #expect(playback.spoken == ["Which animal is this?", "Lion"])
        narration.stop()
    }

    @Test func repeatRetainsPromptAfterFeedbackAndCancelsPendingChoice() async {
        let playback = Playback()
        let narration = playback.makeController()
        narration.presentPrompt("What is three plus eight?")
        narration.announce("Try again.")
        narration.focus("Twelve")
        await playback.settle()
        narration.repeatPrompt()
        await playback.releaseWaits()
        #expect(playback.spoken == ["What is three plus eight?", "Try again.", "What is three plus eight?"])
        narration.stop()
    }

    @Test func leavingScreenCancelsPendingFocus() async {
        let playback = Playback()
        let narration = playback.makeController()
        narration.focus("Circle")
        await playback.settle()
        narration.stop()
        await playback.releaseWaits()
        #expect(playback.spoken.isEmpty)
        #expect(playback.stopCount == 1)
    }

    @Test func voiceOverSuppressesAllCustomAudioAndStopsExistingSpeech() async {
        let playback = Playback()
        let narration = playback.makeController()
        narration.presentPrompt("Find a triangle.")
        narration.focus("Square")
        await playback.settle()
        playback.voiceOver = true
        narration.voiceOverStatusChanged()
        narration.announce("Try again.")
        narration.repeatPrompt()
        narration.focus("Triangle")
        await playback.releaseWaits()
        #expect(playback.spoken == ["Find a triangle."])
        #expect(playback.stopCount >= 1)
        playback.voiceOver = false
        narration.repeatPrompt()
        #expect(playback.spoken.last == "Find a triangle.")
        narration.stop()
    }
    @Test func backgroundStopsPendingAndBlocksLateFocusUntilForeground() async {
        let playback = Playback()
        let narration = playback.makeController()
        narration.presentPrompt("Find a circle.")
        narration.focus("Square")
        await playback.settle()
        narration.applicationWillResignActive()
        narration.focus("Circle")
        narration.repeatPrompt()
        await playback.releaseWaits()
        #expect(playback.spoken == ["Find a circle."])
        narration.applicationDidBecomeActive()
        narration.repeatPrompt()
        #expect(playback.spoken == ["Find a circle.", "Find a circle."])
        narration.stop()
    }

    @Test func muteStopsPendingSpeechAndRetainsPromptForExplicitUnmute() async {
        let playback = Playback()
        let narration = playback.makeController()
        narration.presentPrompt("Find a pair.")
        narration.focus("Bulldozer")
        await playback.settle()
        narration.setAudioEnabled(false)
        narration.announce("A pair!")
        narration.repeatPrompt()
        narration.focus("Crane")
        await playback.releaseWaits()
        #expect(playback.spoken == ["Find a pair."])
        #expect(!narration.audioEnabled && narration.currentPrompt == "Find a pair.")
        narration.setAudioEnabled(true)
        narration.repeatPrompt()
        #expect(playback.spoken == ["Find a pair.", "Find a pair."])
        narration.stop()
    }
}
