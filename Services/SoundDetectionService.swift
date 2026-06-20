import AVFoundation
import Observation

/// Detects hand-clap events via microphone RMS spike analysis.
///
/// Uses an AVAudioRecorder-backed meter for low overhead and zero ML model
/// dependency. A clap signature is an RMS spike from near-silence (< 0.05) to
/// above 0.3 during a meter polling window.
///
/// **Privacy**: Audio data is never stored or transmitted — metering computes
/// only an RMS scalar. The service is started only when
/// `featureFlags.soundReactionEnabled` is true (default: false), and stops
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
    var meterStartupDiagnostics = SoundMeterStartupDiagnostics()

    // MARK: - Private

    // nonisolated(unsafe): AVAudioEngine is kept only for defensive teardown of
    // older tap-backed starts; current starts use AVAudioRecorder metering.
    nonisolated(unsafe) private var audioEngine: AVAudioEngine?
    private var meterRecorder: AVAudioRecorder?
    private var isListening = false
    private var previousRMS: Float = 0
    private var clapResetTask: Task<Void, Never>?
    private var meterPollingTask: Task<Void, Never>?
    private var pendingMeterPermissionRequestID: UUID?
    private var pendingMeterStartAction: (@MainActor () -> Void)?

    // MARK: - Lifecycle

    /// Request microphone access (if not yet granted) and begin listening.
    /// Does nothing if already listening.
    func startListening() {
        startRecorderBackedSoundLabMeter()
    }

    /// Stop listening and tear down microphone metering.
    func stopListening() {
        pendingMeterPermissionRequestID = nil
        pendingMeterStartAction = nil
        meterPollingTask?.cancel()
        meterPollingTask = nil
        meterRecorder?.stop()
        meterRecorder = nil
        guard isListening else {
            previousRMS = 0
            meterReading = SoundMeterReading(rms: 0)
            meterPermissionState = .notStarted
            meterStartupDiagnostics = SoundMeterStartupDiagnostics(phase: .idle)
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
        meterStartupDiagnostics = SoundMeterStartupDiagnostics(phase: .idle)
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
        guard !isListening else { return }
        startRecorderBackedSoundLabMeter()
    }

    func stopSoundLabMeter() {
        stopListening()
    }

    static func audioTapRMS(from buffer: AVAudioPCMBuffer) -> Float? {
        let frameCount = min(Int(buffer.frameLength), Int(buffer.frameCapacity))
        guard frameCount > 0, buffer.format.channelCount > 0 else { return nil }
        guard let channels = buffer.floatChannelData else { return nil }

        let channelData = channels[0]
        var sumOfSquares: Float = 0
        var finiteSampleCount = 0
        for i in 0..<frameCount {
            let sample = channelData[i]
            guard sample.isFinite else { continue }
            sumOfSquares += sample * sample
            finiteSampleCount += 1
        }
        guard finiteSampleCount > 0 else { return 0 }
        let rms = (sumOfSquares / Float(finiteSampleCount)).squareRoot()
        return rms.isFinite ? rms : 0
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

    private func startRecorderBackedSoundLabMeter() {
        let audioSession = AVAudioSession.sharedInstance()
        let preflight = soundMeterPreflight(for: audioSession)
        meterStartupDiagnostics = SoundMeterStartupDiagnostics(
            phase: .preflight,
            authorization: preflight.authorization,
            isInputAvailable: preflight.isInputAvailable
        )

        switch preflight.startupDecision() {
        case .requestPermission:
            requestMicrophonePermission { [weak self] in
                self?.startRecorderBackedSoundLabMeter()
            }
            return
        case .startMeter:
            break
        case .fail(let state):
            resetSoundMeter(to: state, phase: startupPhase(for: state), failure: startupFailure(for: state))
            return
        }

        meterStartupDiagnostics = meterStartupDiagnostics.updating(phase: .activatingSession)
        do {
            try audioSession.setCategory(.playAndRecord, mode: .measurement, options: [.duckOthers, .defaultToSpeaker])
            try audioSession.setActive(true, options: [])
        } catch {
            resetSoundMeter(to: .unavailable, phase: .sessionActivationFailed, failure: .sessionActivation)
            return
        }

        guard audioSession.isInputAvailable, !audioSession.currentRoute.inputs.isEmpty else {
            resetSoundMeter(to: .unavailable, phase: .routeUnavailable, failure: .routeUnavailable)
            return
        }

        meterStartupDiagnostics = meterStartupDiagnostics.updating(
            phase: .preparingRecorder,
            routeInputCount: audioSession.currentRoute.inputs.count
        )

        do {
            let recorder = try makeMeterRecorder()
            recorder.isMeteringEnabled = true
            guard recorder.prepareToRecord(), recorder.record() else {
                resetSoundMeter(to: .unavailable, phase: .recorderStartFailed, failure: .recorderStart)
                return
            }

            meterRecorder = recorder
            isListening = true
            meterPermissionState = .listening
            meterStartupDiagnostics = meterStartupDiagnostics.updating(phase: .listening)
            startMeterPolling()
        } catch {
            resetSoundMeter(to: .unavailable, phase: .recorderStartFailed, failure: .recorderStart)
        }
    }

    private func makeMeterRecorder() throws -> AVAudioRecorder {
        let url = URL(fileURLWithPath: "/dev/null")
        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44_100.0,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.min.rawValue,
        ]
        return try AVAudioRecorder(url: url, settings: settings)
    }

    private func startMeterPolling() {
        meterPollingTask?.cancel()
        meterPollingTask = Task { @MainActor [weak self] in
            while !Task.isCancelled {
                guard let self, let recorder = self.meterRecorder else { return }
                recorder.updateMeters()
                let rms = SoundMeterReading.rms(fromDecibelFS: recorder.averagePower(forChannel: 0))
                self.evaluateRMS(rms)
                try? await Task.sleep(for: .milliseconds(160))
            }
        }
    }

    private func requestMicrophonePermission(then startAction: @escaping @MainActor () -> Void) {
        let requestID = UUID()
        pendingMeterPermissionRequestID = requestID
        pendingMeterStartAction = startAction
        meterPermissionState = .requestingPermission
        meterStartupDiagnostics = meterStartupDiagnostics.updating(phase: .requestingPermission)

        AVAudioSession.sharedInstance().requestRecordPermission { [weak self] granted in
            Task { @MainActor [weak self] in
                guard let self, self.pendingMeterPermissionRequestID == requestID else { return }
                let startAction = self.pendingMeterStartAction
                self.pendingMeterPermissionRequestID = nil
                self.pendingMeterStartAction = nil
                if granted {
                    startAction?()
                } else {
                    self.resetSoundMeter(to: .denied, phase: .permissionDenied, failure: .permissionDenied)
                }
            }
        }
    }

    private func resetSoundMeter(
        to state: SoundMeterPermissionState,
        phase: SoundMeterStartupPhase? = nil,
        failure: SoundMeterStartupFailure? = nil,
        format: SoundMeterAudioFormatSnapshot? = nil
    ) {
        isListening = false
        meterPollingTask?.cancel()
        meterPollingTask = nil
        meterRecorder?.stop()
        meterRecorder = nil
        audioEngine?.inputNode.removeTap(onBus: 0)
        audioEngine?.stop()
        audioEngine = nil
        previousRMS = 0
        meterReading = SoundMeterReading(rms: 0)
        meterPermissionState = state
        meterStartupDiagnostics = meterStartupDiagnostics.updating(
            phase: phase ?? startupPhase(for: state),
            format: format,
            failure: failure ?? startupFailure(for: state)
        )
        clapResetTask?.cancel()
        clapDetected = false
    }

    private func startupPhase(for state: SoundMeterPermissionState) -> SoundMeterStartupPhase {
        switch state {
        case .notStarted: return .idle
        case .requestingPermission: return .requestingPermission
        case .listening: return .listening
        case .unavailable: return .routeUnavailable
        case .denied: return .permissionDenied
        }
    }

    private func startupFailure(for state: SoundMeterPermissionState) -> SoundMeterStartupFailure? {
        switch state {
        case .notStarted, .requestingPermission, .listening:
            return nil
        case .unavailable:
            return .routeUnavailable
        case .denied:
            return .permissionDenied
        }
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
