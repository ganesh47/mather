import SwiftData
import SwiftUI

@main
struct MatherApp: App {
    private let container: ModelContainer
    @State private var appModel: AppModel

    init() {
        let schema = Schema([
            StoredSessionSummary.self,
            StoredRoomQuestStationReference.self,
            StoredFactRecord.self,
            StoredKidProfile.self,
            StoredTelemetryEvent.self,
            StoredGameSession.self,
            StoredGameplayProgressRecord.self,
            StoredGameplayThreadSession.self
        ])
        container = Self.makeModelContainer(schema: schema)
        let appModel = AppModel(modelContext: container.mainContext)
        Self.seedSessionHistoryIfRequested(using: appModel)
        Self.seedGameHistoryIfRequested(using: appModel)
        Self.applyUITestStartRouteIfRequested(using: appModel)
        _appModel = State(initialValue: appModel)
    }

    private static func makeModelContainer(schema: Schema) -> ModelContainer {
        let storeURL = SwiftDataStoreRecovery.defaultStoreURL()
        let configuration = ModelConfiguration(schema: schema, url: storeURL)
        do {
            return try ModelContainer(for: schema, configurations: configuration)
        } catch {
            // Migration failure (common on major OS upgrades). Quarantine only Mather's
            // configured SwiftData store so unrelated app-support sqlite files are preserved.
            SwiftDataStoreRecovery.quarantineStore(at: storeURL)
            do {
                return try ModelContainer(for: schema, configurations: configuration)
            } catch {
                fatalError("Failed to create model container after store reset: \(error)")
            }
        }
    }

    var body: some Scene {
        WindowGroup {
            RootView(appModel: appModel)
                .modelContainer(container)
                .preferredColorScheme(Self.preferredColorSchemeForUITests())
        }
    }
}

private extension MatherApp {
    static func preferredColorSchemeForUITests() -> ColorScheme? {
        let arguments = ProcessInfo.processInfo.arguments
        guard let flagIndex = arguments.firstIndex(of: "-uiTest.appearance"),
              arguments.indices.contains(flagIndex + 1) else { return nil }

        switch arguments[flagIndex + 1].lowercased() {
        case "light": return .light
        case "dark": return .dark
        default: return nil
        }
    }

    static func applyUITestStartRouteIfRequested(using appModel: AppModel) {
        let arguments = ProcessInfo.processInfo.arguments
        guard let flagIndex = arguments.firstIndex(of: "-uiTest.startRoute"),
              arguments.indices.contains(flagIndex + 1) else { return }

        switch arguments[flagIndex + 1].lowercased() {
        case "lab", "explorerlab", "explorer-lab":
            appModel.engine.showLab()
        case "labgames", "lab-games":
            appModel.engine.showLabGames()
        case "shapegeometry", "shape-geometry", "shapes":
            appModel.engine.showShapeGeometry()
        case "geometrylane", "geometry-lane":
            appModel.engine.showLabLane(.geometry)
        case "watercycle", "water-cycle", "watercyclethread", "water-cycle-thread":
            appModel.engine.showWaterCycle()
        case "watercyclelab", "water-cycle-lab", "legacy-watercycle", "legacy-water-cycle":
            appModel.engine.showLegacyWaterCycleLab()
        case "bondblast", "bond-blast", "bondblastfinale", "bond-blast-finale":
            appModel.engine.startBondBlastFinale(target: uiTestBondBlastTarget(from: arguments))
        default:
            break
        }
    }


    static func uiTestBondBlastTarget(from arguments: [String]) -> Int {
        guard let flagIndex = arguments.firstIndex(of: "-uiTest.bondBlastTarget"),
              arguments.indices.contains(flagIndex + 1),
              let target = Int(arguments[flagIndex + 1]) else { return 10 }
        return target
    }

    static func seedSessionHistoryIfRequested(using appModel: AppModel) {
        let arguments = ProcessInfo.processInfo.arguments
        guard let flagIndex = arguments.firstIndex(of: "-uiTest.seedHistory"),
              arguments.indices.contains(flagIndex + 1),
              let requestedCount = Int(arguments[flagIndex + 1]) else { return }

        appModel.historyStore.clearAllProfiles()
        appModel.gameSessionStore.clearAllProfiles()

        for index in 0..<max(requestedCount, 0) {
            let startedAt = Date.now.addingTimeInterval(TimeInterval(-index * 3_600))
            let sessionId = "ui-test-seeded-\(index)"
            let draft = SessionSummaryDraft(
                sessionId: sessionId,
                startedAt: startedAt,
                endedAt: startedAt.addingTimeInterval(300),
                objectiveTitle: "Make & Break",
                problemsCompleted: 4 + index,
                firstAttemptAccuracy: index == 0 ? 0.75 : 0.5,
                transferCorrectCount: 2 + (index % 2),
                medianLatencyMs: 90_000 + (index * 15_000),
                nextTargetHint: "UI test seeded session history.",
                exportFileName: "swiftdata://session/\(sessionId)"
            )
            appModel.historyStore.save(draft)
        }
    }

    static func seedGameHistoryIfRequested(using appModel: AppModel) {
        let arguments = ProcessInfo.processInfo.arguments
        guard let flagIndex = arguments.firstIndex(of: "-uiTest.seedGameHistory"),
              arguments.indices.contains(flagIndex + 1),
              let requestedCount = Int(arguments[flagIndex + 1]) else { return }

        appModel.historyStore.clearAllProfiles()
        appModel.gameSessionStore.clearAllProfiles()

        let fixtures = [
            ("Sum Sprint", "correct", "Fluency practice"),
            ("Angle Cannon", "targets hit", "Angle practice"),
            ("Memory", "rounds", "Pattern recall")
        ]

        for index in 0..<max(requestedCount, 0) {
            let fixture = fixtures[index % fixtures.count]
            appModel.gameSessionStore.save(
                gameName: fixture.0,
                startedAt: Date.now.addingTimeInterval(TimeInterval(-index * 2_400)),
                scoreValue: 6 + index,
                scoreLabel: fixture.1,
                detail: fixture.2
            )
        }
    }
}
