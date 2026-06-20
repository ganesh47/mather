import AVFoundation
import Testing
@testable import Mather

/// Tests for SoundDetectionService.
///
/// The primary regression target is microphone startup safety. Bond Blast clap
/// detection now uses the same recorder-backed meter path as Sound Lab so it
/// does not install an AVAudioEngine tap on the audio I/O thread.
///
/// Because live microphone startup requires real audio hardware, these tests
/// exercise the service's state machine and guard logic without driving input.
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

    @Test
    func initialStartupDiagnosticsArePrivacySafeAndIdle() {
        let service = SoundDetectionService()
        #expect(service.meterStartupDiagnostics.phase == .idle)
        #expect(service.meterStartupDiagnostics.authorization == nil)
        #expect(service.meterStartupDiagnostics.routeInputCount == nil)
        #expect(service.meterStartupDiagnostics.inputSampleRate == nil)
        #expect(service.meterStartupDiagnostics.failure == nil)
    }

    @Test
    func audioTapFormatSnapshotFailsClosedForUnsafeFormats() {
        #expect(SoundMeterAudioFormatSnapshot(sampleRate: 44_100, channelCount: 1).isUsableForAudioTap)
        #expect(!SoundMeterAudioFormatSnapshot(sampleRate: 0, channelCount: 1).isUsableForAudioTap)
        #expect(!SoundMeterAudioFormatSnapshot(sampleRate: .nan, channelCount: 1).isUsableForAudioTap)
        #expect(!SoundMeterAudioFormatSnapshot(sampleRate: 44_100, channelCount: 0).isUsableForAudioTap)
        #expect(!SoundMeterAudioFormatSnapshot(sampleRate: 44_100, channelCount: 1, commonFormat: .pcmFormatInt16).isUsableForAudioTap)
        #expect(!SoundMeterAudioFormatSnapshot(sampleRate: 44_100, channelCount: 1, isInterleaved: true).isUsableForAudioTap)
    }

    @Test
    func startupDiagnosticsCaptureOnlyCoarseAudioState() {
        let diagnostics = SoundMeterStartupDiagnostics(
            phase: .checkingInputFormat,
            authorization: .granted,
            isInputAvailable: true,
            routeInputCount: 1
        ).updating(format: SoundMeterAudioFormatSnapshot(sampleRate: 48_000, channelCount: 1))

        #expect(diagnostics.phase == .checkingInputFormat)
        #expect(diagnostics.authorization == .granted)
        #expect(diagnostics.isInputAvailable == true)
        #expect(diagnostics.routeInputCount == 1)
        #expect(diagnostics.inputSampleRate == 48_000)
        #expect(diagnostics.inputChannelCount == 1)
        #expect(diagnostics.failure == nil)
    }

    @Test
    func audioTapRMSIgnoresEmptyBuffers() {
        let format = AVAudioFormat(commonFormat: .pcmFormatFloat32, sampleRate: 44_100, channels: 1, interleaved: false)!
        let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: 0)!
        buffer.frameLength = 0

        #expect(SoundDetectionService.audioTapRMS(from: buffer) == nil)
    }

    @Test
    func audioTapRMSSanitizesNonFiniteSamples() {
        let format = AVAudioFormat(commonFormat: .pcmFormatFloat32, sampleRate: 44_100, channels: 1, interleaved: false)!
        let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: 4)!
        buffer.frameLength = 4
        let samples = buffer.floatChannelData![0]
        samples[0] = 0.3
        samples[1] = .nan
        samples[2] = .infinity
        samples[3] = 0.4

        let rms = SoundDetectionService.audioTapRMS(from: buffer)
        #expect(rms != nil)
        #expect(abs(rms! - 0.35355338) < 0.0001)
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

    // startListening() starts live microphone metering, so these tests only run
    // on device where the guard logic matters most.
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
