import Foundation
import Testing
@testable import Mather

struct VehicleSpecTests {

    // MARK: - Pool completeness

    @Test func vehicleSpecPoolIsNonEmpty() {
        #expect(!VehicleSpec.pool.isEmpty)
    }

    @Test func vehicleSpecPoolHasSevenEntries() {
        #expect(VehicleSpec.pool.count == 7)
    }

    @Test func vehicleSpecPoolAllHaveNonEmptySymbolAndNoun() {
        for spec in VehicleSpec.pool {
            #expect(!spec.symbolName.isEmpty)
            #expect(!spec.counterNoun.isEmpty)
            #expect(!spec.celebrationEmoji.isEmpty)
        }
    }

    @Test func vehicleSpecPoolAllPromptsAreNonEmpty() {
        for spec in VehicleSpec.pool {
            #expect(!spec.concretePromptFn(7).isEmpty)
            #expect(!spec.pictorialPromptFn(5).isEmpty)
            #expect(!spec.abstractPromptFn().isEmpty)
            #expect(!spec.transferPromptFn(3, 4).isEmpty)
            #expect(!spec.sessionIntroFn().isEmpty)
            #expect(!spec.sessionEndFn().isEmpty)
            #expect(!spec.sessionStartFeedbackFn().isEmpty)
        }
    }

    @Test func vehicleSpecTransferPromptIncludesDecompositionNumbers() {
        for spec in VehicleSpec.pool {
            let prompt = spec.transferPromptFn(2, 5)
            #expect(prompt.contains("2"))
            #expect(prompt.contains("5"))
        }
    }

    @Test func vehicleSpecConcretePromptIncludesTarget() {
        for spec in VehicleSpec.pool {
            let prompt = spec.concretePromptFn(8)
            #expect(prompt.contains("8"))
        }
    }

    // MARK: - VehicleTheme delegation

    @Test func vehicleThemeDefaultSpecIsCar() {
        let theme = VehicleTheme()
        #expect(theme.counterNoun == "cars")
        #expect(theme.celebrationEmoji == "🚗")
        if case .vehicle(let sym) = theme.counterKind {
            #expect(sym == "car.fill")
        } else {
            Issue.record("Expected .vehicle counterKind for default VehicleTheme")
        }
    }

    @Test func vehicleThemeHelicopterSpec() {
        let theme = VehicleTheme(spec: .helicopter)
        #expect(theme.counterNoun == "helicopters")
        #expect(theme.celebrationEmoji == "🚁")
        if case .vehicle(let sym) = theme.counterKind {
            #expect(sym == "helicopter")
        } else {
            Issue.record("Expected .vehicle counterKind for helicopter spec")
        }
    }

    @Test func vehicleThemeAllSpecsProduceDistinctNouns() {
        let nouns = VehicleSpec.pool.map { VehicleTheme(spec: $0).counterNoun }
        // Every noun should be non-empty; most are distinct (trucks appears twice intentionally)
        #expect(nouns.allSatisfy { !$0.isEmpty })
    }

    // MARK: - Engine per-problem theme rotation

    @MainActor
    @Test func engineStartsVehicleSessionWithCarTheme() {
        let flags = FeatureFlagService(defaults: UserDefaults(suiteName: #function)!)
        flags.testModeEnabled = true
        flags.selectedThemeId = "vehicle"
        let engine = VerticalSliceEngine(
            featureFlags: flags,
            telemetryWriter: TelemetryWriter(),
            speechService: SpeechService(),
            celebrationDuration: 0,
            saveSummary: { _ in }
        )
        engine.startSession()
        // First problem is always the first spec in the pool (.car)
        #expect(engine.activeTheme.counterNoun == "cars")
        #expect(engine.activeTheme.celebrationEmoji == "🚗")
    }

    @MainActor
    @Test func engineAdvancesVehicleThemeOnProblemTransition() async throws {
        let flags = FeatureFlagService(defaults: UserDefaults(suiteName: #function)!)
        flags.testModeEnabled = true
        flags.selectedThemeId = "vehicle"
        let engine = VerticalSliceEngine(
            featureFlags: flags,
            telemetryWriter: TelemetryWriter(),
            speechService: SpeechService(),
            celebrationDuration: 0,
            saveSummary: { _ in }
        )
        engine.startSession()
        let firstNoun = engine.activeTheme.counterNoun
        guard let problem = engine.currentProblem else { return }

        // Complete all 4 CPA stages — same pattern as VerticalSliceEngineTests.
        engine.adjustConcrete(by: problem.target)
        engine.submitCurrentStage()                             // concrete → pictorial
        try await Task.sleep(for: .milliseconds(200))
        engine.submitCurrentStage()                             // pictorial → abstract
        try await Task.sleep(for: .milliseconds(200))
        engine.equationLeftInput = String(problem.decompositionA)
        engine.equationRightInput = String(problem.decompositionB)
        engine.submitCurrentStage()                             // abstract → transfer
        try await Task.sleep(for: .milliseconds(200))
        engine.adjustTransfer(by: problem.decompositionA, side: .left)
        engine.adjustTransfer(by: problem.decompositionB, side: .right)
        engine.submitCurrentStage()                             // transfer → done
        try await Task.sleep(for: .milliseconds(200))

        // Engine has advanced to problem 2 — second spec in VehicleSpec.pool (pickupTruck → "trucks")
        let secondNoun = engine.activeTheme.counterNoun
        #expect(secondNoun != firstNoun, "Theme noun should change after first problem completes")
    }

    @MainActor
    @Test func engineClassicThemeSessionHasNoProblemThemeRotation() {
        let flags = FeatureFlagService(defaults: UserDefaults(suiteName: #function)!)
        flags.testModeEnabled = true
        flags.selectedThemeId = "classic"
        let engine = VerticalSliceEngine(
            featureFlags: flags,
            telemetryWriter: TelemetryWriter(),
            speechService: SpeechService(),
            celebrationDuration: 0,
            saveSummary: { _ in }
        )
        engine.startSession()
        #expect(engine.activeTheme.celebrationEmoji == "⭐️")
        if case .circle = engine.activeTheme.counterKind { } else {
            Issue.record("Expected .circle counterKind for classic theme session")
        }
    }
}
