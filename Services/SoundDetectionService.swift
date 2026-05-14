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
    var meterStartupDiagnostics = SoundMeterStartupDiagnostics()

    // MARK: - Private

    // nonisolated(unsafe): AVAudioEngine is not Sendable, but we only ever
    // access it from @MainActor methods (start/stop are both @MainActor).
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
        guard !isListening else { return }
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
                self?.startListening()
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

        let engine = AVAudioEngine()
        let inputNode = engine.inputNode
        let format = inputNode.outputFormat(forBus: 0)
        let formatSnapshot = SoundMeterAudioFormatSnapshot(format: format)
        meterStartupDiagnostics = meterStartupDiagnostics.updating(
            phase: .checkingInputFormat,
            routeInputCount: audioSession.currentRoute.inputs.count,
            format: formatSnapshot
        )
        // When input hardware is unavailable or the route changes, the input
        // node can expose a zero/unknown format. Installing a tap with that
        // format can raise an Objective-C/AudioUnit assertion instead of a
        // catchable Swift error, so fail closed before the tap boundary.
        guard formatSnapshot.isUsableForAudioTap else {
            resetSoundMeter(to: .unavailable, phase: .inputFormatUnavailable, failure: .inputFormatUnavailable, format: formatSnapshot)
            return
        }

        inputNode.removeTap(onBus: 0)
        engine.prepare()
        meterStartupDiagnostics = meterStartupDiagnostics.updating(phase: .installingAudioTap, format: formatSnapshot)
        inputNode.installTap(onBus: 0, bufferSize: 2048, format: format) { [weak self] buffer, _ in
            guard let rms = SoundDetectionService.audioTapRMS(from: buffer) else { return }

            // The audio tap runs on the audio I/O thread — marshal to @MainActor.
            Task { @MainActor [weak self] in
                self?.evaluateRMS(rms)
            }
        }

        meterStartupDiagnostics = meterStartupDiagnostics.updating(phase: .startingAudioEngine)
        do {
            try engine.start()
            audioEngine = engine
            isListening = true
            meterPermissionState = .listening
            meterStartupDiagnostics = meterStartupDiagnostics.updating(phase: .listening)
        } catch {
            // Silently fail: microphone permission may be denied, or the
            // audio session may be unavailable. Bond Blast still works without clap.
            inputNode.removeTap(onBus: 0)
            resetSoundMeter(to: .unavailable, phase: .engineStartFailed, failure: .engineStart)
        }
    }

    /// Stop listening and tear down the audio tap.
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
