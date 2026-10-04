import AVFoundation
import Foundation
import Observation
import UIKit

/// Keeps TV instructions repeatable while allowing the latest focused choice to be read.
@MainActor
@Observable
final class TVNarrationController {
    private(set) var currentPrompt: String?
    private(set) var audioEnabled = true
    @ObservationIgnored private let speakText: (String) -> Void
    @ObservationIgnored private let stopPlayback: () -> Void
    @ObservationIgnored private let isSpeaking: () -> Bool
    @ObservationIgnored private let voiceOverRunning: () -> Bool
    @ObservationIgnored private let delay: (Duration) async throws -> Void
    @ObservationIgnored private var focusTask: Task<Void, Never>?
    @ObservationIgnored private var voiceOverTask: Task<Void, Never>?
    @ObservationIgnored private var backgroundTask: Task<Void, Never>?
    @ObservationIgnored private var foregroundTask: Task<Void, Never>?
    @ObservationIgnored private var applicationActive = true
    @ObservationIgnored private var interruptionTask: Task<Void, Never>?
    @ObservationIgnored private var focusGeneration = 0
    @ObservationIgnored private var protectsAnnouncement = false

    convenience init() {
        let speech = SpeechService()
        self.init(
            speak: { speech.speak($0, enabled: true) },
            stop: { speech.stop() },
            isSpeaking: { speech.isSpeaking },
            voiceOverRunning: { UIAccessibility.isVoiceOverRunning }
        )
    }

    init(
        speak: @escaping (String) -> Void,
        stop: @escaping () -> Void,
        isSpeaking: @escaping () -> Bool = { false },
        voiceOverRunning: @escaping () -> Bool = { UIAccessibility.isVoiceOverRunning },
        delay: @escaping (Duration) async throws -> Void = { try await Task.sleep(for: $0) }
    ) {
        speakText = speak
        stopPlayback = stop
        self.isSpeaking = isSpeaking
        self.voiceOverRunning = voiceOverRunning
        self.delay = delay
        voiceOverTask = Task { @MainActor [weak self] in
            for await _ in NotificationCenter.default.notifications(named: UIAccessibility.voiceOverStatusDidChangeNotification) {
                self?.voiceOverStatusChanged()
            }
        }
        backgroundTask = Task { @MainActor [weak self] in
            for await _ in NotificationCenter.default.notifications(named: UIApplication.willResignActiveNotification) {
                self?.applicationWillResignActive()
            }
        }
        foregroundTask = Task { @MainActor [weak self] in
            for await _ in NotificationCenter.default.notifications(named: UIApplication.didBecomeActiveNotification) {
                self?.applicationDidBecomeActive()
            }
        }
        interruptionTask = Task { @MainActor [weak self] in
            for await _ in NotificationCenter.default.notifications(named: AVAudioSession.interruptionNotification) {
                self?.stop()
            }
        }
    }

    func presentPrompt(_ text: String) {
        currentPrompt = text
        announce(text)
    }

    func announce(_ text: String) {
        cancelFocus()
        protectsAnnouncement = true
        guard applicationActive, audioEnabled, !voiceOverRunning(), !text.isEmpty else {
            stopPlayback()
            return
        }
        speakText(text)
    }

    func focus(_ text: String?) {
        cancelFocus()
        guard applicationActive, audioEnabled, let text, !text.isEmpty, !voiceOverRunning() else { return }
        let generation = focusGeneration
        focusTask = Task { @MainActor [weak self, delay] in
            do {
                try await delay(.milliseconds(350))
                // Automatic focus on screen entry must not cut off the instructions.
                while let self, self.protectsAnnouncement, self.isSpeaking() {
                    guard !Task.isCancelled, self.focusGeneration == generation else { return }
                    if self.voiceOverRunning() { self.voiceOverStatusChanged(); return }
                    try await delay(.milliseconds(100))
                }
                guard let self, !Task.isCancelled, self.focusGeneration == generation else { return }
                guard self.applicationActive, self.audioEnabled, !self.voiceOverRunning() else { self.voiceOverStatusChanged(); return }
                self.protectsAnnouncement = false
                self.speakText(text)
            } catch {
                // A focus change or leaving the screen cancels pending narration.
            }
        }
    }

    func repeatPrompt() {
        guard let currentPrompt else { return }
        announce(currentPrompt)
    }

    /// Activity-local mute preserves the repeatable prompt and accessibility announcements.
    func setAudioEnabled(_ enabled: Bool) {
        audioEnabled = enabled
        if !enabled { stop() }
    }

    func stop() {
        cancelFocus()
        protectsAnnouncement = false
        stopPlayback()
    }

    func applicationWillResignActive() {
        applicationActive = false
        stop()
    }

    func applicationDidBecomeActive() {
        applicationActive = true
    }

    /// Also called by the notification listener when VoiceOver is enabled mid-speech.
    func voiceOverStatusChanged() {
        if voiceOverRunning() { stop() }
    }

    private func cancelFocus() {
        focusGeneration += 1
        focusTask?.cancel()
        focusTask = nil
    }

    deinit {
        focusTask?.cancel()
        voiceOverTask?.cancel()
        backgroundTask?.cancel()
        interruptionTask?.cancel()
        foregroundTask?.cancel()
    }
}
