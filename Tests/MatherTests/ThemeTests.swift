import Foundation
import Testing
@testable import Mather

// MARK: - Test helpers

private struct RocketTheme: SliceTheme {
    var counterKind: CounterKind { .circle }
    var celebrationEmoji: String { "🚀" }
    func concretePrompt(target: Int) -> String { "Launch \(target) rockets." }
    func pictorialPrompt(target: Int) -> String { "Split the rockets into two pads." }
    func abstractPrompt() -> String { "Type the rocket equation." }
    func transferPrompt(decompositionA: Int, decompositionB: Int) -> String {
        "Relaunch \(decompositionA) and \(decompositionB) rockets."
    }
    func stageSuccessPhrase(for stage: SliceStage, target: Int) -> String { "Blast off!" }
    func sessionIntroPhrase() -> String { "Let's count rockets." }
    func sessionEndPhrase() -> String { "Mission complete." }
    func sessionStartFeedback() -> String { "Place the rockets on the pad." }
}

struct ThemeTests {

    // MARK: - ClassicTheme

    @Test func classicThemeCounterKindIsCircle() {
        let theme = ClassicTheme()
        #expect(theme.counterKind == .circle)
    }

    @Test func classicThemeCelebrationEmoji() {
        #expect(ClassicTheme().celebrationEmoji == "⭐️")
    }

    @Test func classicThemeConcretePrompt() {
        #expect(ClassicTheme().concretePrompt(target: 7) == "Make 7 with the counters.")
    }

    @Test func classicThemePictorialPrompt() {
        #expect(ClassicTheme().pictorialPrompt(target: 5) == "Break 5 into two groups.")
    }

    @Test func classicThemeAbstractPrompt() {
        #expect(ClassicTheme().abstractPrompt() == "Type the same split as an equation.")
    }

    @Test func classicThemeTransferPrompt() {
        let prompt = ClassicTheme().transferPrompt(decompositionA: 3, decompositionB: 4)
        #expect(prompt.contains("3"))
        #expect(prompt.contains("4"))
    }

    @Test func classicThemeStageSuccessPhrases() {
        let theme = ClassicTheme()
        #expect(theme.stageSuccessPhrase(for: .concrete, target: 6) == "Yes. You made 6.")
        #expect(theme.stageSuccessPhrase(for: .pictorial, target: 8) == "That break still makes 8.")
        #expect(theme.stageSuccessPhrase(for: .abstract, target: 5) == "Your equation matches the split.")
        #expect(theme.stageSuccessPhrase(for: .transfer, target: 7) == "You matched the same equation with counters.")
    }

    @Test func classicThemeSessionPhrases() {
        let theme = ClassicTheme()
        #expect(theme.sessionIntroPhrase() == "Let's make and break numbers to ten.")
        #expect(!theme.sessionEndPhrase().isEmpty)
        #expect(!theme.sessionStartFeedback().isEmpty)
    }

    // MARK: - Engine default theme

    @MainActor
    @Test func engineDefaultThemeIsClassic() {
        let flags = FeatureFlagService(defaults: UserDefaults(suiteName: #function)!)
        let engine = VerticalSliceEngine(
            featureFlags: flags,
            telemetryWriter: TelemetryWriter(),
            speechService: SpeechService(),
            celebrationDuration: 0,
            saveSummary: { _ in }
        )
        // ClassicTheme returns .circle
        if case .circle = engine.activeTheme.counterKind { } else {
            Issue.record("Expected .circle counter kind from default theme")
        }
        #expect(engine.activeTheme.celebrationEmoji == "⭐️")
    }

    @MainActor
    @Test func engineAcceptsInjectedTheme() {
        let flags = FeatureFlagService(defaults: UserDefaults(suiteName: #function)!)
        let engine = VerticalSliceEngine(
            featureFlags: flags,
            telemetryWriter: TelemetryWriter(),
            speechService: SpeechService(),
            activeTheme: ClassicTheme(),
            celebrationDuration: 0,
            saveSummary: { _ in }
        )
        #expect(engine.activeTheme.celebrationEmoji == "⭐️")
    }

    // MARK: - Engine vocabulary routing (PR2)

    @MainActor
    @Test func engineUsesInjectedThemeSessionStartFeedback() {
        let flags = FeatureFlagService(defaults: UserDefaults(suiteName: #function)!)
        flags.testModeEnabled = true
        let engine = VerticalSliceEngine(
            featureFlags: flags,
            telemetryWriter: TelemetryWriter(),
            speechService: SpeechService(),
            activeTheme: RocketTheme(),
            celebrationDuration: 0,
            saveSummary: { _ in }
        )
        engine.startSession()
        #expect(engine.feedbackMessage == "Place the rockets on the pad.")
    }

    @MainActor
    @Test func engineUsesClassicThemeSessionStartFeedbackByDefault() {
        let flags = FeatureFlagService(defaults: UserDefaults(suiteName: #function)!)
        flags.testModeEnabled = true
        let engine = VerticalSliceEngine(
            featureFlags: flags,
            telemetryWriter: TelemetryWriter(),
            speechService: SpeechService(),
            celebrationDuration: 0,
            saveSummary: { _ in }
        )
        engine.startSession()
        #expect(engine.feedbackMessage == "Make the target number with the big counters.")
    }

    @MainActor
    @Test func engineConcretePromptComesFromTheme() async throws {
        let flags = FeatureFlagService(defaults: UserDefaults(suiteName: #function)!)
        flags.testModeEnabled = true
        let engine = VerticalSliceEngine(
            featureFlags: flags,
            telemetryWriter: TelemetryWriter(),
            speechService: SpeechService(),
            activeTheme: RocketTheme(),
            celebrationDuration: 0,
            saveSummary: { _ in }
        )
        engine.startSession()
        // After advancing to pictorial, feedbackMessage should use theme pictorialPrompt
        engine.adjustConcrete(by: engine.currentProblem?.target ?? 0)
        engine.submitCurrentStage()
        try await Task.sleep(for: .milliseconds(200))
        #expect(engine.feedbackMessage == "Split the rockets into two pads.")
    }
}
