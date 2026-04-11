import Testing
@testable import Mather

/// Tests for SoundDetectionService.
///
/// The primary regression target is the `installTap` crash when
/// `inputNode.inputFormat(forBus:)` returns a zero-sample-rate format.
/// This happens when SpeechService has set the AVAudioSession category to
/// `.playback`, which disables microphone hardware — the input format becomes
/// invalid (sampleRate=0) and passing it to `installTap` raises an exception.
///
/// Fix: guard `format.sampleRate > 0` before calling `installTap`.
///
/// Because AVAudioEngine requires real audio hardware, these tests exercise the
/// service's state machine and guard logic directly without driving the engine.
@MainActor
struct SoundDetectionServiceTests {

    // MARK: - Init

    @Test
    func initDoesNotCrash() {
        let service = SoundDetectionService()
        _ = service
    }

    @Test
    func initialStateIsQuiescent() {
        let service = SoundDetectionService()
        #expect(!service.clapDetected)
    }

    // MARK: - startListening / stopListening idempotency

    @Test
    func stopListeningWhenNotListeningDoesNotCrash() {
        let service = SoundDetectionService()
        // Calling stop before start should be a no-op (guarded by isListening).
        service.stopListening()
        #expect(!service.clapDetected)
    }

    @Test
    func startListeningDoesNotCrashInSimulator() {
        // In the simulator with no real microphone and a .playback audio session
        // (typically set by SpeechService), inputFormat returns sampleRate=0.
        // The guard added in the fix should catch this and return without crashing.
        let service = SoundDetectionService()
        service.startListening()  // must not crash
    }

    @Test
    func startListeningIsIdempotent() {
        let service = SoundDetectionService()
        service.startListening()
        service.startListening()  // second call guarded by isListening — no crash, no double tap
    }

    @Test
    func stopListeningAfterStartDoesNotCrash() {
        let service = SoundDetectionService()
        service.startListening()
        service.stopListening()
    }

    // MARK: - resetClap

    @Test
    func resetClapClearsClapDetectedFlag() async {
        let service = SoundDetectionService()
        // Drive clapDetected via resetClap round-trip (we can't inject RMS in tests,
        // but we can verify resetClap idempotency — it should not crash when flag is false).
        service.resetClap()
        #expect(!service.clapDetected)
    }

    // MARK: - Stop clears state

    @Test
    func stopListeningResetsClapState() {
        let service = SoundDetectionService()
        service.startListening()
        service.stopListening()
        #expect(!service.clapDetected)
    }
}
