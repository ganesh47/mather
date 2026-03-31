import AVFoundation
import Foundation

@MainActor
@Observable
final class SpeechService {
    private let synthesizer = AVSpeechSynthesizer()
    private var lastUtteranceID = UUID()
    var hasSpokenSessionIntro = false

    func speak(_ text: String, enabled: Bool) {
        guard enabled, !text.isEmpty else { return }
        synthesizer.stopSpeaking(at: .immediate)
        let utterance = AVSpeechUtterance(string: text)
        utterance.rate = 0.45
        utterance.pitchMultiplier = 1.0
        lastUtteranceID = UUID()
        synthesizer.speak(utterance)
    }

    func speakSessionIntroIfNeeded(enabled: Bool) {
        guard !hasSpokenSessionIntro else { return }
        hasSpokenSessionIntro = true
        speak("Let's make and break numbers to ten.", enabled: enabled)
    }

    func resetSession() {
        hasSpokenSessionIntro = false
    }
}
