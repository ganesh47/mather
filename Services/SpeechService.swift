import AVFoundation
import Foundation

@MainActor
@Observable
final class SpeechService {
    private let synthesizer = AVSpeechSynthesizer()
    private var lastUtteranceID = UUID()
    var hasSpokenSessionIntro = false

    init() {
        // Use .playback category so prompts are audible even when the hardware
        // ringer/silent switch is off. .spokenAudio mode pauses other audio
        // during speech; .duckOthers lowers (rather than cuts) background audio.
        // The in-app audio toggle (speak(_:enabled:)) remains the parent's control.
        try? AVAudioSession.sharedInstance().setCategory(
            .playback,
            mode: .spokenAudio,
            options: .duckOthers
        )
        try? AVAudioSession.sharedInstance().setActive(true)
    }

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
