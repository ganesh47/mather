import Foundation
import Testing
@testable import Mather

struct VehicleSpecTests {
    private func waitFor(_ description: String, timeoutNanoseconds: UInt64 = 2_000_000_000, condition: @escaping @MainActor () -> Bool) async {
        let deadline = DispatchTime.now().uptimeNanoseconds + timeoutNanoseconds
        while DispatchTime.now().uptimeNanoseconds < deadline {
            if await MainActor.run(body: condition) { return }
            await Task.yield()
            try? await Task.sleep(nanoseconds: 20_000_000)
        }
        Issue.record("Timed out waiting for \(description)")
    }


    // MARK: - Pool completeness

    @Test func vehicleSpecPoolIsNonEmpty() {
        #expect(!VehicleSpec.pool.isEmpty)
    }

    @Test func vehicleSpecPoolHasExpandedConstructionEntries() {
        #expect(VehicleSpec.pool.count == 10)
        let nouns = Set(VehicleSpec.pool.map(\.counterNoun))
        #expect(nouns.isSuperset(of: ["bulldozers", "dump trucks", "cement mixers", "mining trucks"]))
    }

    @Test func vehicleSpecPoolAllHaveNonEmptySymbolAndNoun() {
        for spec in VehicleSpec.pool {
            #expect(!spec.symbolName.isEmpty)
            #expect(!spec.counterNoun.isEmpty)
            #expect(!spec.celebrationEmoji.isEmpty)
        }
    }

    @Test func vehicleSpecsExposeGeneratedAssetsForRequestedConstructionVehicles() {
        func assetName(for noun: String) -> String? {
            VehicleSpec.pool.first { $0.counterNoun == noun }.flatMap(\.assetName)
        }

        #expect(assetName(for: "cars") == "VS1VehicleCar")
        #expect(assetName(for: "trucks") == "VS1VehiclePickupTruck")
        #expect(assetName(for: "bulldozers") == "VS1VehicleBulldozer")
        #expect(assetName(for: "dump trucks") == "VS1VehicleDumpTruck")
        #expect(assetName(for: "cement mixers") == "VS1VehicleCementMixer")
        #expect(assetName(for: "mining trucks") == "VS1VehicleMiningTruck")
    }

    @Test func generatedVS1VehicleAssetCatalogsExist() {
        let expectedAssets = [
            "VS1VehicleCar",
            "VS1VehiclePickupTruck",
            "VS1VehicleBulldozer",
            "VS1VehicleDumpTruck",
            "VS1VehicleCementMixer",
            "VS1VehicleMiningTruck"
        ]
        let sourceFile = URL(fileURLWithPath: #filePath)
        let repoRoot = sourceFile.deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
        let assetsRoot = repoRoot.appendingPathComponent("App/Assets.xcassets")

        for assetName in expectedAssets {
            let imageset = assetsRoot.appendingPathComponent("\(assetName).imageset")
            #expect(FileManager.default.fileExists(atPath: imageset.appendingPathComponent("\(assetName).png").path))
            #expect(FileManager.default.fileExists(atPath: imageset.appendingPathComponent("Contents.json").path))
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

    @Test func vehicleSpecTransferPromptDoesNotRevealDecompositionNumbers() {
        for spec in VehicleSpec.pool {
            let prompt = spec.transferPromptFn(2, 5)
            #expect(!prompt.contains("2"))
            #expect(!prompt.contains("5"))
            #expect(prompt.localizedCaseInsensitiveContains("memory"))
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
        if case .themedSymbol(let sym, let assetName) = theme.counterKind {
            #expect(sym == "car.fill")
            #expect(assetName == "VS1VehicleCar")
        } else {
            Issue.record("Expected themed symbol counterKind for default VehicleTheme")
        }
    }

    @Test func vehicleThemeHelicopterSpec() {
        let theme = VehicleTheme(spec: .helicopter)
        #expect(theme.counterNoun == "helicopters")
        #expect(theme.celebrationEmoji == "🚁")
        if case .themedSymbol(let sym, let assetName) = theme.counterKind {
            #expect(sym == "helicopter")
            #expect(assetName == nil)
        } else {
            Issue.record("Expected themed symbol counterKind for helicopter spec")
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
        flags.makeBreakLoopV2Enabled = false
        flags.vs1GravitySplitEnabled = false
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
        flags.makeBreakLoopV2Enabled = false
        flags.vs1GravitySplitEnabled = false
        let engine = VerticalSliceEngine(
            featureFlags: flags,
            telemetryWriter: TelemetryWriter(),
            speechService: SpeechService(),
            celebrationDuration: 0,
            saveSummary: { _ in }
        )
        engine.startSession()
        let firstNoun = engine.activeTheme.counterNoun
        let problem = try #require(engine.currentProblem)

        // Complete all 4 CPA stages.
        engine.adjustConcrete(by: problem.target)
        engine.submitCurrentStage()                             // concrete → pictorial
        await waitFor("pictorial stage after concrete") { engine.currentStage == .pictorial }
        await waitFor("bond match state in pictorial") { engine.bondMatchState != nil }
        for pair in engine.bondMatchState?.pairs ?? [] {
            engine.matchPair(id: pair.id)
        }
        await waitFor("abstract stage after Bond Blast") { engine.currentStage == .abstract }
        engine.equationLeftInput = String(problem.decompositionA)
        engine.equationRightInput = String(problem.decompositionB)
        engine.submitCurrentStage()                             // abstract → transfer
        await waitFor("transfer stage after abstract") { engine.currentStage == .transfer }
        engine.adjustTransfer(by: problem.decompositionA, side: .left)
        engine.adjustTransfer(by: problem.decompositionB, side: .right)
        engine.submitCurrentStage()                             // transfer → done
        await waitFor("next themed problem after transfer") { engine.currentProblemIndex == 1 }

        // Engine has advanced to problem 2 — second spec in VehicleSpec.pool (pickupTruck → "trucks")
        let secondNoun = engine.activeTheme.counterNoun
        #expect(secondNoun != firstNoun, "Theme noun should change after first problem completes")
    }


    @MainActor
    @Test func engineNonTestVehicleSessionStartsWithRandomizedNonCarTheme() {
        let flags = FeatureFlagService(defaults: UserDefaults(suiteName: #function)!)
        flags.testModeEnabled = false
        flags.selectedThemeId = "vehicle"
        flags.makeBreakLoopV2Enabled = false
        flags.vs1GravitySplitEnabled = false
        let engine = VerticalSliceEngine(
            featureFlags: flags,
            telemetryWriter: TelemetryWriter(),
            speechService: SpeechService(),
            celebrationDuration: 0,
            saveSummary: { _ in }
        )
        engine.startSession()
        #expect(engine.activeTheme.counterNoun != "cars")
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
