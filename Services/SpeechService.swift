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

    // Always speaks the session intro regardless of the audio toggle — the child
    // should always hear a spoken start cue. The parent's mute toggle applies to
    // in-session prompts only (via speak(_:enabled:)).
    func speakSessionIntro(_ phrase: String) {
        guard !hasSpokenSessionIntro else { return }
        hasSpokenSessionIntro = true
        speak(phrase, enabled: true)
    }

    func resetSession() {
        hasSpokenSessionIntro = false
    }
}
