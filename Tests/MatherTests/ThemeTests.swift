import Foundation
import Testing
@testable import Mather

private func waitFor(_ description: String, timeoutNanoseconds: UInt64 = 2_000_000_000, condition: @escaping @MainActor () -> Bool) async {
    let deadline = DispatchTime.now().uptimeNanoseconds + timeoutNanoseconds
    while DispatchTime.now().uptimeNanoseconds < deadline {
        if await MainActor.run(body: condition) { return }
        await Task.yield()
        try? await Task.sleep(nanoseconds: 20_000_000)
    }
    Issue.record("Timed out waiting for \(description)")
}

// MARK: - Test helpers

private struct RocketTheme: SliceTheme {
    var counterKind: CounterKind { .circle }
    var celebrationEmoji: String { "🚀" }
    var counterNoun: String { "rockets" }
    func concretePrompt(target: Int) -> String { "Launch \(target) rockets." }
    func pictorialPrompt(target: Int) -> String { "Split the rockets into two pads." }
    func abstractPrompt() -> String { "Type the rocket equation." }
    func transferPrompt(decompositionA: Int, decompositionB: Int) -> String {
        "Relaunch the same total from memory."
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
        #expect(!prompt.contains("3"))
        #expect(!prompt.contains("4"))
        #expect(prompt.localizedCaseInsensitiveContains("memory"))
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
        #expect(theme.sessionIntroPhrase() == "Let's make and break numbers in different ways.")
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

    // MARK: - VehicleTheme (PR4)

    @Test func vehicleThemeCounterKindIsThemedSymbol() {
        let theme = VehicleTheme()
        if case .themedSymbol(let sym, let assetName) = theme.counterKind {
            #expect(sym == "car.fill")
            #expect(assetName == "VS1VehicleCar")
        } else {
            Issue.record("Expected themed symbol counter kind with 'car.fill' symbol")
        }
    }

    @Test func vehicleThemeCelebrationEmoji() {
        #expect(VehicleTheme().celebrationEmoji == "🚗")
    }

    @Test func vehicleThemePromptsAreDistinctFromClassic() {
        let classic = ClassicTheme()
        let vehicle = VehicleTheme()
        #expect(vehicle.concretePrompt(target: 7) != classic.concretePrompt(target: 7))
        #expect(vehicle.pictorialPrompt(target: 5) != classic.pictorialPrompt(target: 5))
        #expect(vehicle.abstractPrompt() != classic.abstractPrompt())
        #expect(vehicle.transferPrompt(decompositionA: 3, decompositionB: 4) != classic.transferPrompt(decompositionA: 3, decompositionB: 4))
        #expect(vehicle.celebrationEmoji != classic.celebrationEmoji)
    }

    @Test func vehicleThemeStageSuccessPhrasesAreDistinctFromClassicForCPAStages() {
        let classic = ClassicTheme()
        let vehicle = VehicleTheme()
        // Abstract and done phrases are intentionally theme-neutral ("Your equation matches the split",
        // "Problem complete") — only concrete, pictorial, and transfer are theme-specific.
        let themedStages: [SliceStage] = [.concrete, .pictorial, .transfer]
        for stage in themedStages {
            #expect(vehicle.stageSuccessPhrase(for: stage, target: 6) != classic.stageSuccessPhrase(for: stage, target: 6))
        }
    }

    @Test func vehicleThemeSessionPhrasesDiffer() {
        #expect(VehicleTheme().sessionIntroPhrase() != ClassicTheme().sessionIntroPhrase())
        #expect(VehicleTheme().sessionEndPhrase() != ClassicTheme().sessionEndPhrase())
        #expect(VehicleTheme().sessionStartFeedback() != ClassicTheme().sessionStartFeedback())
    }

    @Test func vehicleTransferPromptDoesNotRevealDecompositionNumbers() {
        let prompt = VehicleTheme().transferPrompt(decompositionA: 2, decompositionB: 5)
        #expect(!prompt.contains("2"))
        #expect(!prompt.contains("5"))
        #expect(prompt.localizedCaseInsensitiveContains("memory"))
    }

    // MARK: - SpaceTheme

    @Test func spaceThemeCounterKindIsThemedSymbol() {
        let theme = SpaceTheme()
        if case .themedSymbol(let sym, let assetName) = theme.counterKind {
            #expect(sym == "sparkles")
            #expect(assetName == nil)
        } else {
            Issue.record("Expected themed symbol counter kind for SpaceTheme")
        }
    }

    @Test func spaceThemePromptsAreDistinctFromClassic() {
        let classic = ClassicTheme()
        let space = SpaceTheme()
        #expect(space.concretePrompt(target: 7) != classic.concretePrompt(target: 7))
        #expect(space.pictorialPrompt(target: 5) != classic.pictorialPrompt(target: 5))
        #expect(space.abstractPrompt() != classic.abstractPrompt())
        #expect(space.transferPrompt(decompositionA: 3, decompositionB: 4) != classic.transferPrompt(decompositionA: 3, decompositionB: 4))
        #expect(space.celebrationEmoji != classic.celebrationEmoji)
    }

    @Test func spaceTransferPromptDoesNotRevealDecompositionNumbers() {
        let prompt = SpaceTheme().transferPrompt(decompositionA: 2, decompositionB: 5)
        #expect(!prompt.contains("2"))
        #expect(!prompt.contains("5"))
        #expect(prompt.localizedCaseInsensitiveContains("memory"))
    }

    // MARK: - Celebration emoji (PR8)

    @Test func celebrationEmojiDistinctBetweenThemes() {
        #expect(VehicleTheme().celebrationEmoji != ClassicTheme().celebrationEmoji)
        #expect(SpaceTheme().celebrationEmoji != ClassicTheme().celebrationEmoji)
        #expect(!VehicleTheme().celebrationEmoji.isEmpty)
        #expect(!SpaceTheme().celebrationEmoji.isEmpty)
        #expect(!ClassicTheme().celebrationEmoji.isEmpty)
    }

    // MARK: - Engine vocabulary routing (PR2)

    // MARK: - Theme picker wiring (PR9)

    @MainActor
    @Test func startSessionWithVehicleThemeIdActivatesVehicleTheme() {
        let flags = FeatureFlagService(defaults: UserDefaults(suiteName: #function)!)
        flags.testModeEnabled = true
        flags.makeBreakLoopV2Enabled = false
        flags.selectedThemeId = "vehicle"
        let engine = VerticalSliceEngine(
            featureFlags: flags,
            telemetryWriter: TelemetryWriter(),
            speechService: SpeechService(),
            celebrationDuration: 0,
            saveSummary: { _ in }
        )
        engine.startSession()
        #expect(engine.feedbackMessage == "Park 6 cars in the garage.")
        #expect(engine.activeTheme.celebrationEmoji == "🚗")
        if case .themedSymbol = engine.activeTheme.counterKind { } else {
            Issue.record("Expected themed symbol counter kind after startSession with selectedThemeId=vehicle")
        }
    }

    @MainActor
    @Test func startSessionWithSpaceThemeIdActivatesSpaceTheme() {
        let flags = FeatureFlagService(defaults: UserDefaults(suiteName: #function)!)
        flags.testModeEnabled = true
        flags.makeBreakLoopV2Enabled = false
        flags.selectedThemeId = "space"
        let engine = VerticalSliceEngine(
            featureFlags: flags,
            telemetryWriter: TelemetryWriter(),
            speechService: SpeechService(),
            celebrationDuration: 0,
            saveSummary: { _ in }
        )
        engine.startSession()
        #expect(engine.feedbackMessage == "Load 6 star bolts for the rocket.")
        #expect(engine.activeTheme.counterNoun == "star bolts")
        #expect(engine.activeTheme.celebrationEmoji == "🚀")
        if case .themedSymbol(let sym, let assetName) = engine.activeTheme.counterKind {
            #expect(sym == "sparkles")
            #expect(assetName == nil)
        } else {
            Issue.record("Expected themed symbol counter kind after startSession with selectedThemeId=space")
        }
    }

    @MainActor
    @Test func startSessionWithPlanetsAliasActivatesSpaceTheme() {
        let flags = FeatureFlagService(defaults: UserDefaults(suiteName: #function)!)
        flags.testModeEnabled = true
        flags.makeBreakLoopV2Enabled = false
        flags.selectedThemeId = "planets"
        let engine = VerticalSliceEngine(
            featureFlags: flags,
            telemetryWriter: TelemetryWriter(),
            speechService: SpeechService(),
            celebrationDuration: 0,
            saveSummary: { _ in }
        )
        engine.startSession()
        #expect(engine.activeTheme.counterNoun == "star bolts")
        #expect(engine.activeTheme.celebrationEmoji == "🚀")
    }

    @MainActor
    @Test func startSessionWithClassicThemeIdActivatesClassicTheme() {
        let flags = FeatureFlagService(defaults: UserDefaults(suiteName: #function)!)
        flags.testModeEnabled = true
        flags.makeBreakLoopV2Enabled = false
        flags.selectedThemeId = "classic"
        let engine = VerticalSliceEngine(
            featureFlags: flags,
            telemetryWriter: TelemetryWriter(),
            speechService: SpeechService(),
            celebrationDuration: 0,
            saveSummary: { _ in }
        )
        engine.startSession()
        #expect(engine.feedbackMessage == "Make 6 with the counters.")
        #expect(engine.activeTheme.celebrationEmoji == "⭐️")
        if case .circle = engine.activeTheme.counterKind { } else {
            Issue.record("Expected .circle counter kind after startSession with selectedThemeId=classic")
        }
    }

    @MainActor
    @Test func unknownThemeIdDefaultsToClassic() {
        let flags = FeatureFlagService(defaults: UserDefaults(suiteName: #function)!)
        flags.testModeEnabled = true
        flags.selectedThemeId = "unknown_theme_xyz"
        let engine = VerticalSliceEngine(
            featureFlags: flags,
            telemetryWriter: TelemetryWriter(),
            speechService: SpeechService(),
            celebrationDuration: 0,
            saveSummary: { _ in }
        )
        engine.startSession()
        // Unknown IDs fall through to ClassicTheme
        #expect(engine.activeTheme.celebrationEmoji == "⭐️")
    }

    @MainActor
    @Test func engineUsesInjectedThemeSessionStartFeedback() {
        let flags = FeatureFlagService(defaults: UserDefaults(suiteName: #function)!)
        flags.testModeEnabled = true
        flags.makeBreakLoopV2Enabled = false
        let engine = VerticalSliceEngine(
            featureFlags: flags,
            telemetryWriter: TelemetryWriter(),
            speechService: SpeechService(),
            activeTheme: RocketTheme(),
            celebrationDuration: 0,
            saveSummary: { _ in }
        )
        engine.startSession()
        #expect(engine.feedbackMessage == "Launch 6 rockets.")
    }

    @MainActor
    @Test func engineUsesClassicThemeSessionStartFeedbackByDefault() {
        let flags = FeatureFlagService(defaults: UserDefaults(suiteName: #function)!)
        flags.testModeEnabled = true
        flags.makeBreakLoopV2Enabled = false
        let engine = VerticalSliceEngine(
            featureFlags: flags,
            telemetryWriter: TelemetryWriter(),
            speechService: SpeechService(),
            celebrationDuration: 0,
            saveSummary: { _ in }
        )
        engine.startSession()
        #expect(engine.feedbackMessage == "Make 6 with the counters.")
    }

    @MainActor
    @Test func engineConcretePromptComesFromTheme() async throws {
        let flags = FeatureFlagService(defaults: UserDefaults(suiteName: #function)!)
        flags.testModeEnabled = true
        flags.makeBreakLoopV2Enabled = false
        flags.vs1GravitySplitEnabled = false
        let engine = VerticalSliceEngine(
            featureFlags: flags,
            telemetryWriter: TelemetryWriter(),
            speechService: SpeechService(),
            activeTheme: RocketTheme(),
            celebrationDuration: 0,
            saveSummary: { _ in }
        )
        engine.startSession()
        // The pictorial slot now uses Bond Blast copy rather than the theme-specific split prompt.
        engine.adjustConcrete(by: engine.currentProblem?.target ?? 0)
        engine.submitCurrentStage()
        let expected = "Match pairs that make 6 seeds."
        await waitFor("bond blast prompt after concrete submit") {
            engine.feedbackMessage == expected
        }
        #expect(engine.feedbackMessage == expected)
    }

    // MARK: - counterNoun (UX review fix)

    @Test func classicThemeCounterNounIsCounters() {
        #expect(ClassicTheme().counterNoun == "counters")
    }

    @Test func vehicleThemeCounterNounIsCars() {
        #expect(VehicleTheme().counterNoun == "cars")
    }

    @Test func spaceThemeCounterNounIsStarBolts() {
        #expect(SpaceTheme().counterNoun == "star bolts")
    }

    /// After 3 concrete failures with VehicleTheme, the feedback hint must say "cars" not "circles".
    @MainActor
    @Test func engineConcreteFailureHintUsesThemeCounterNoun() {
        let flags = FeatureFlagService(defaults: UserDefaults(suiteName: #function)!)
        flags.testModeEnabled = true
        flags.makeBreakLoopV2Enabled = false
        let engine = VerticalSliceEngine(
            featureFlags: flags,
            telemetryWriter: TelemetryWriter(),
            speechService: SpeechService(),
            activeTheme: VehicleTheme(),
            celebrationDuration: 0,
            saveSummary: { _ in }
        )
        engine.startSession()
        // Submit wrong answer three times to reach the "tapping the X" hint
        engine.submitCurrentStage() // attempt 1 — wrong (count is 0)
        engine.submitCurrentStage() // attempt 2
        engine.submitCurrentStage() // attempt 3 → counterNoun hint
        #expect(engine.feedbackMessage.contains("cars"))
        #expect(!engine.feedbackMessage.contains("circles"))
    }

    @MainActor
    @Test func engineConcreteFailureHintUsesSpaceCounterNoun() {
        let flags = FeatureFlagService(defaults: UserDefaults(suiteName: #function)!)
        flags.testModeEnabled = true
        flags.makeBreakLoopV2Enabled = false
        let engine = VerticalSliceEngine(
            featureFlags: flags,
            telemetryWriter: TelemetryWriter(),
            speechService: SpeechService(),
            activeTheme: SpaceTheme(),
            celebrationDuration: 0,
            saveSummary: { _ in }
        )
        engine.startSession()
        engine.submitCurrentStage()
        engine.submitCurrentStage()
        engine.submitCurrentStage()
        #expect(engine.feedbackMessage.contains("star bolts"))
        #expect(!engine.feedbackMessage.contains("circles"))
    }
}
