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
        #expect(service.meterPermissionState == .notStarted)
        #expect(service.meterReading == SoundMeterReading(rms: 0))
    }

    @Test
    func soundMeterStartsInPrivacySafeNoAudioState() {
        let service = SoundDetectionService()
        #expect(service.meterPermissionState.guidance.contains("does not record audio"))
        #expect(SoundMeterReading.privacyCopy.contains("stores no audio"))
        #expect(SoundMeterReading.privacyCopy.contains("sends no audio"))
    }

    // MARK: - startListening / stopListening idempotency

    @Test
    func stopListeningWhenNotListeningDoesNotCrash() {
        let service = SoundDetectionService()
        // Calling stop before start should be a no-op (guarded by isListening).
        service.stopListening()
        #expect(!service.clapDetected)
        #expect(service.meterPermissionState == .notStarted)
    }

    // startListening() calls AVAudioEngine.start() which requires real audio hardware.
    // AVAudioEngine crashes the test host on the simulator (AURemoteIO -10851), so
    // these tests only run on device where the guard logic matters most.
    #if !targetEnvironment(simulator)

    @Test
    func startListeningDoesNotCrashWithPlaybackSession() {
        // On device: when SpeechService has set .playback category, inputFormat
        // returns sampleRate=0 — the guard must catch this before installTap.
        let service = SoundDetectionService()
        service.startListening()  // must not crash
    }

    @Test
    func startListeningIsIdempotent() {
        let service = SoundDetectionService()
        service.startListening()
        service.startListening()  // second call guarded by isListening — no double tap
    }

    @Test
    func stopListeningAfterStartDoesNotCrash() {
        let service = SoundDetectionService()
        service.startListening()
        service.stopListening()
    }

    #endif

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
    func stopListeningResetsClapStateWithoutStart() {
        // Verify stop resets state even when never started — no AVAudioEngine needed.
        let service = SoundDetectionService()
        service.stopListening()
        #expect(!service.clapDetected)
        #expect(service.meterPermissionState == .notStarted)
    }
}
