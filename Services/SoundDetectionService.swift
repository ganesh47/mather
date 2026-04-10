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

    // MARK: - Private

    // nonisolated(unsafe): AVAudioEngine is not Sendable, but we only ever
    // access it from @MainActor methods (start/stop are both @MainActor).
    nonisolated(unsafe) private let audioEngine = AVAudioEngine()
    private var isListening = false
    private var previousRMS: Float = 0
    private var clapResetTask: Task<Void, Never>?

    // MARK: - Lifecycle

    /// Request microphone access (if not yet granted) and begin listening.
    /// Does nothing if already listening.
    func startListening() {
        guard !isListening else { return }
        let inputNode = audioEngine.inputNode
        let format = inputNode.inputFormat(forBus: 0)

        inputNode.installTap(onBus: 0, bufferSize: 2048, format: format) { [weak self] buffer, _ in
            guard let channelData = buffer.floatChannelData?[0] else { return }
            let frameCount = Int(buffer.frameLength)
            var sumOfSquares: Float = 0
            for i in 0..<frameCount {
                sumOfSquares += channelData[i] * channelData[i]
            }
            let rms = (sumOfSquares / Float(frameCount)).squareRoot()

            // The audio tap runs on the audio I/O thread — marshal to @MainActor.
            Task { @MainActor [weak self] in
                self?.evaluateRMS(rms)
            }
        }

        do {
            try audioEngine.start()
            isListening = true
        } catch {
            // Silently fail: microphone permission may be denied, or the
            // audio session may be unavailable. Bond Blast still works without clap.
            inputNode.removeTap(onBus: 0)
        }
    }

    /// Stop listening and tear down the audio tap.
    func stopListening() {
        guard isListening else { return }
        audioEngine.inputNode.removeTap(onBus: 0)
        audioEngine.stop()
        isListening = false
        previousRMS = 0
        clapResetTask?.cancel()
        clapDetected = false
    }

    /// Call after the view has consumed the clap event to prevent re-triggering.
    func resetClap() {
        clapDetected = false
        clapResetTask?.cancel()
    }

    // MARK: - Private helpers

    private func evaluateRMS(_ rms: Float) {
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
}
