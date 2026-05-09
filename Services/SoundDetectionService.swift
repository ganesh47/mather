import AVFoundation
import Observation

/// Detects hand-clap events via microphone RMS spike analysis.
///
/// Uses AVAudioEngine (NOT SoundAnalysis) for low latency and zero ML model
/// overhead. A clap signature is an RMS spike from near-silence (< 0.05) to
/// above 0.3 within one ~46 ms buffer window.
///
/// **Privacy**: Audio data is never stored or transmitted — the tap computes
/// only an RMS scalar. The service is started only when
/// `featureFlags.soundReactionEnabled` is true (default: true), and stops
/// immediately when BondMatchView disappears.
///
/// Requires `NSMicrophoneUsageDescription` in Info.plist.
@MainActor
@Observable
final class SoundDetectionService {

    // MARK: - Observable state

    /// Momentarily true when a clap is detected; auto-resets after 500 ms.
    var clapDetected: Bool = false

    /// Local-only RMS loudness estimate for Sound Lab meter UI. Audio is never stored or transmitted.
    var meterReading = SoundMeterReading(rms: 0)
    var meterPermissionState: SoundMeterPermissionState = .notStarted

    // MARK: - Private

    // nonisolated(unsafe): AVAudioEngine is not Sendable, but we only ever
    // access it from @MainActor methods (start/stop are both @MainActor).
    nonisolated(unsafe) private var audioEngine: AVAudioEngine?
    private var isListening = false
    private var previousRMS: Float = 0
    private var clapResetTask: Task<Void, Never>?
    private var pendingMeterPermissionRequestID: UUID?

    // MARK: - Lifecycle

    /// Request microphone access (if not yet granted) and begin listening.
    /// Does nothing if already listening.
    func startListening() {
        guard !isListening else { return }
        let audioSession = AVAudioSession.sharedInstance()

        switch soundMeterPreflight(for: audioSession).startupDecision() {
        case .requestPermission:
            requestMicrophonePermission()
            return
        case .startMeter:
            break
        case .fail(let state):
            resetSoundMeter(to: state)
            return
        }

        do {
            try audioSession.setCategory(.playAndRecord, mode: .measurement, options: [.duckOthers, .defaultToSpeaker])
            try audioSession.setActive(true, options: [])
        } catch {
            resetSoundMeter(to: .unavailable)
            return
        }

        let engine = AVAudioEngine()
        let inputNode = engine.inputNode
        let format = inputNode.inputFormat(forBus: 0)
        // When input hardware is unavailable, inputFormat can return a
        // zero-sample-rate format — installTap would crash.
        guard format.sampleRate > 0, format.channelCount > 0 else {
            resetSoundMeter(to: .unavailable)
            return
        }

        inputNode.removeTap(onBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 2048, format: format) { [weak self] buffer, _ in
            guard let channelData = buffer.floatChannelData?[0] else { return }
            let frameCount = Int(buffer.frameLength)
            guard frameCount > 0 else { return }
            var sumOfSquares: Float = 0
            var finiteSampleCount = 0
            for i in 0..<frameCount {
                let sample = channelData[i]
                guard sample.isFinite else { continue }
                sumOfSquares += sample * sample
                finiteSampleCount += 1
            }
            let rms = finiteSampleCount > 0 ? (sumOfSquares / Float(finiteSampleCount)).squareRoot() : 0

            // The audio tap runs on the audio I/O thread — marshal to @MainActor.
            Task { @MainActor [weak self] in
                self?.evaluateRMS(rms.isFinite ? rms : 0)
            }
        }

        do {
            try engine.start()
            audioEngine = engine
            isListening = true
            meterPermissionState = .listening
        } catch {
            // Silently fail: microphone permission may be denied, or the
            // audio session may be unavailable. Bond Blast still works without clap.
            inputNode.removeTap(onBus: 0)
            resetSoundMeter(to: .unavailable)
        }
    }

    /// Stop listening and tear down the audio tap.
    func stopListening() {
        pendingMeterPermissionRequestID = nil
        guard isListening else {
            previousRMS = 0
            meterReading = SoundMeterReading(rms: 0)
            meterPermissionState = .notStarted
            clapResetTask?.cancel()
            clapDetected = false
            return
        }
        audioEngine?.inputNode.removeTap(onBus: 0)
        audioEngine?.stop()
        audioEngine = nil
        isListening = false
        previousRMS = 0
        meterReading = SoundMeterReading(rms: 0)
        meterPermissionState = .notStarted
        clapResetTask?.cancel()
        clapDetected = false
    }

    /// Call after the view has consumed the clap event to prevent re-triggering.
    func resetClap() {
        clapDetected = false
        clapResetTask?.cancel()
    }

    // MARK: - Private helpers

    func startSoundLabMeter() {
        startListening()
    }

    func stopSoundLabMeter() {
        stopListening()
    }

    private func evaluateRMS(_ rms: Float) {
        meterReading = SoundMeterReading(rms: rms)
        // Clap signature: near-silence followed by a sharp spike.
        if rms > 0.3 && previousRMS < 0.05 && !clapDetected {
            clapDetected = true
            clapResetTask?.cancel()
            clapResetTask = Task { @MainActor [weak self] in
                try? await Task.sleep(for: .milliseconds(500))
                self?.clapDetected = false
            }
        }
        previousRMS = rms
    }

    private func requestMicrophonePermission() {
        let requestID = UUID()
        pendingMeterPermissionRequestID = requestID
        meterPermissionState = .requestingPermission

        AVAudioSession.sharedInstance().requestRecordPermission { [weak self] granted in
            Task { @MainActor [weak self] in
                guard let self, self.pendingMeterPermissionRequestID == requestID else { return }
                self.pendingMeterPermissionRequestID = nil
                if granted {
                    self.startListening()
                } else {
                    self.resetSoundMeter(to: .denied)
                }
            }
        }
    }

    private func resetSoundMeter(to state: SoundMeterPermissionState) {
        isListening = false
        audioEngine?.inputNode.removeTap(onBus: 0)
        audioEngine?.stop()
        audioEngine = nil
        previousRMS = 0
        meterReading = SoundMeterReading(rms: 0)
        meterPermissionState = state
        clapResetTask?.cancel()
        clapDetected = false
    }

    private func soundMeterPreflight(for audioSession: AVAudioSession) -> SoundMeterStartupPreflight {
        SoundMeterStartupPreflight(
            isInputAvailable: audioSession.isInputAvailable,
            authorization: microphoneAuthorization(for: audioSession)
        )
    }

    private func microphoneAuthorization(for audioSession: AVAudioSession) -> SoundMeterMicrophoneAuthorization {
        switch audioSession.recordPermission {
        case .undetermined:
            return .undetermined
        case .denied:
            return .denied
        case .granted:
            return .granted
        @unknown default:
            return .unknown
        }
    }
}
