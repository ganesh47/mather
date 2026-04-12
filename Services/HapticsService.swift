import CoreHaptics
import UIKit

/// Provides tactile feedback throughout the app.
///
/// Uses CHHapticEngine for rich, multi-event patterns (Bond Blast card
/// pickup, near-snap magnetic pull, correct snap, mismatch wobble, and
/// celebration rhythm). Falls back to UIImpactFeedbackGenerator when the
/// haptic engine is unavailable (simulator, older hardware).
///
/// All methods are safe to call when haptics are disabled — they return
/// immediately without side effects.
@MainActor
final class HapticsService {

    // MARK: - Testability counters

    private(set) var successFiredCount = 0
    private(set) var failureFiredCount = 0
    private(set) var stageSuccessFiredCount = 0

    // MARK: - Engine

    private var engine: CHHapticEngine?

    init() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }
        do {
            engine = try CHHapticEngine()
            engine?.resetHandler = { [weak self] in
                Task { @MainActor [weak self] in
                    try? self?.engine?.start()
                }
            }
            engine?.stoppedHandler = { _ in }
            try engine?.start()
        } catch {
            engine = nil
        }
    }

    // MARK: - Existing CPA stage feedback

    /// Light haptic for completing an individual CPA stage (not a full problem).
    func stageSuccess(enabled: Bool) {
        guard enabled else { return }
        stageSuccessFiredCount += 1
        playTransient(intensity: 0.5, sharpness: 0.5) {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        }
    }

    /// Medium haptic for completing a full problem (all stages done).
    func success(enabled: Bool) {
        guard enabled else { return }
        successFiredCount += 1
        playTransient(intensity: 0.8, sharpness: 0.7) {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        }
    }

    func failure(enabled: Bool) {
        guard enabled else { return }
        failureFiredCount += 1
        playTransient(intensity: 0.5, sharpness: 0.1) {
            UINotificationFeedbackGenerator().notificationOccurred(.warning)
        }
    }

    // MARK: - Bond Blast haptics

    /// Soft "weight" sensation when a card is picked up / tapped to select.
    func cardPickup(enabled: Bool) {
        guard enabled else { return }
        playTransient(intensity: 0.4, sharpness: 0.6) {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        }
    }

    /// Intensifying magnetic pull as a card nears the correct snap target.
    func cardNearSnap(enabled: Bool) {
        guard enabled else { return }
        guard let engine else {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            return
        }
        do {
            let rampEvent = CHHapticEvent(
                eventType: .hapticContinuous,
                parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.2),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.4)
                ],
                relativeTime: 0,
                duration: 0.2
            )
            let intensityCurve = CHHapticParameterCurve(
                parameterID: .hapticIntensityControl,
                controlPoints: [
                    CHHapticParameterCurve.ControlPoint(relativeTime: 0, value: 0.2),
                    CHHapticParameterCurve.ControlPoint(relativeTime: 0.2, value: 0.7)
                ],
                relativeTime: 0
            )
            let pattern = try CHHapticPattern(events: [rampEvent], parameterCurves: [intensityCurve])
            let player = try engine.makePlayer(with: pattern)
            try player.start(atTime: CHHapticTimeImmediate)
        } catch {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        }
    }

    /// Satisfying "click + echo" when a pair is correctly matched.
    func cardSnapCorrect(enabled: Bool) {
        guard enabled else { return }
        guard let engine else {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            return
        }
        do {
            let click = CHHapticEvent(
                eventType: .hapticTransient,
                parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: 1.0),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.9)
                ],
                relativeTime: 0
            )
            let echo = CHHapticEvent(
                eventType: .hapticTransient,
                parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.5),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.5)
                ],
                relativeTime: 0.08
            )
            let pattern = try CHHapticPattern(events: [click, echo], parameterCurves: [])
            let player = try engine.makePlayer(with: pattern)
            try player.start(atTime: CHHapticTimeImmediate)
        } catch {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        }
    }

    /// Soft, rounded "hmm" when a wrong pair is attempted.
    func cardSnapMismatch(enabled: Bool) {
        guard enabled else { return }
        playTransient(intensity: 0.5, sharpness: 0.1) {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        }
    }

    /// Four rising taps followed by a short sustain — session-closing celebration.
    func bondMatchComplete(enabled: Bool) {
        guard enabled else { return }
        guard let engine else {
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            return
        }
        do {
            let offsets: [(time: Double, intensity: Float, sharpness: Float)] = [
                (0.0,  0.5, 0.8),
                (0.15, 0.65, 0.85),
                (0.30, 0.80, 0.90),
                (0.45, 1.0, 1.0)
            ]
            var events: [CHHapticEvent] = offsets.map { tap in
                CHHapticEvent(
                    eventType: .hapticTransient,
                    parameters: [
                        CHHapticEventParameter(parameterID: .hapticIntensity, value: tap.intensity),
                        CHHapticEventParameter(parameterID: .hapticSharpness, value: tap.sharpness)
                    ],
                    relativeTime: tap.time
                )
            }
            events.append(
                CHHapticEvent(
                    eventType: .hapticContinuous,
                    parameters: [
                        CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.6),
                        CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.5)
                    ],
                    relativeTime: 0.6,
                    duration: 0.3
                )
            )
            let pattern = try CHHapticPattern(events: events, parameterCurves: [])
            let player = try engine.makePlayer(with: pattern)
            try player.start(atTime: CHHapticTimeImmediate)
        } catch {
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        }
    }

    // MARK: - Test support

    func resetCounts() {
        successFiredCount = 0
        failureFiredCount = 0
        stageSuccessFiredCount = 0
    }

    // MARK: - Private helpers

    /// Play a single transient event via CHHapticEngine, falling back to a closure.
    private func playTransient(intensity: Float, sharpness: Float, fallback: () -> Void) {
        guard let engine else {
            fallback()
            return
        }
        do {
            let event = CHHapticEvent(
                eventType: .hapticTransient,
                parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: intensity),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: sharpness)
                ],
                relativeTime: 0
            )
            let pattern = try CHHapticPattern(events: [event], parameterCurves: [])
            let player = try engine.makePlayer(with: pattern)
            try player.start(atTime: CHHapticTimeImmediate)
        } catch {
            fallback()
        }
    }
}
