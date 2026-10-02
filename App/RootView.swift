import Observation
import SwiftData
import SwiftUI

struct RootView: View {
    @Bindable var appModel: AppModel
    @Environment(\.scenePhase) private var scenePhase
    @Query(sort: \StoredSessionSummary.startedAt, order: .reverse) private var sessionSummaries: [StoredSessionSummary]
    @Query(sort: \StoredGameSession.startedAt, order: .reverse) private var gameSessions: [StoredGameSession]
    @Query(sort: \StoredKidProfile.createdAt) private var kidProfiles: [StoredKidProfile]

    private var activeProfileSummaries: [StoredSessionSummary] {
        sessionSummaries.filter { $0.profileId == appModel.profileStore.activeProfileId }
    }

    private var activeProfileGameSessions: [StoredGameSession] {
        gameSessions.filter { $0.profileId == appModel.profileStore.activeProfileId }
    }

    private static func isContentBoundary(_ route: AppRoute) -> Bool {
        switch route { case .home, .lab, .labGames, .labLane, .settings, .parentSummary: true; default: false }
    }

    var body: some View {
        NavigationStack {
            Group {
                switch appModel.engine.route {
                case .home:
                    HomeView(appModel: appModel)
                case .sessionConfig:
                    SessionConfigView(appModel: appModel)
                case .session:
                    SliceSessionView(appModel: appModel)
                case .sessionSummary:
                    SessionSummaryView(appModel: appModel)
                case .parentSummary:
                    ParentSummaryView(appModel: appModel, summaries: activeProfileSummaries, gameSessions: activeProfileGameSessions, profiles: kidProfiles)
                case .settings:
                    SettingsView(appModel: appModel, summaries: activeProfileSummaries, gameSessions: activeProfileGameSessions)
                case .roomQuest:
                    RoomSessionView(engine: appModel.roomQuestEngine, vsEngine: appModel.engine)
                        .sheet(item: Binding(
                            get: { appModel.roomQuestScanner.activeSession },
                            set: { _ in }
                        )) { _ in
                            RoomQuestScannerSheet(scanner: appModel.roomQuestScanner)
                        }
                case .rectangleFactory:
                    RectangleFactoryView(appModel: appModel, initialTarget: appModel.rectangleFactoryStartingTarget)
                case .factoryCards:
                    FactoryCardsView(appModel: appModel)
                case .sumSprint:
                    switch appModel.sumSprintEngine.phase {
                    case .idle:
                        HomeView(appModel: appModel)
                    case .difficultyPick:
                        SumSprintDifficultyView(
                            engine: appModel.sumSprintEngine,
                            onExit: { appModel.sumSprintEngine.exitToHome() }
                        )
                    case .session:
                        SumSprintSessionView(appModel: appModel)
                    case .summary:
                        if let summary = appModel.sumSprintEngine.completedSummary {
                            SumSprintSummaryView(
                                summary: summary,
                                onPlayAgain: { appModel.sumSprintEngine.showDifficultyPick() },
                                onDone: { appModel.sumSprintEngine.exitToHome() }
                            )
                        }
                    }
                case .symmetryFold:
                    SymmetryFoldView(appModel: appModel)
                case .angleCannon:
                    AngleCannonView(appModel: appModel)
                case .twoFingerProtractor:
                    TwoFingerProtractorView(appModel: appModel)
                case .gravityArtist:
                    GravityArtistView(appModel: appModel)
                case .compassAngles:
                    CompassAnglesView(appModel: appModel)
                case .lab:
                    LabView(appModel: appModel, initialPath: .labs)
                case .labGames:
                    LabView(appModel: appModel, initialPath: .games)
                case .labLane(let laneID):
                    LabLaneDetailView(appModel: appModel, laneID: laneID)
                case .memory:
                    MemoryView(appModel: appModel, contentCatalog: appModel.iosLearningContentStore.catalog)
                case .memoryDeck(let deckKind):
                    MemoryView(appModel: appModel, initialDeckKind: deckKind, contentCatalog: appModel.iosLearningContentStore.catalog)
                case .labRememberStage(let deckID):
                    LabRememberStageView(appModel: appModel, deckID: deckID)
                case .waterCycle:
                    WaterCycleLabView(appModel: appModel)
                case .gameplayThread(let threadID):
                    GameplayThreadView(thread: appModel.iosLearningContentStore.catalog.thread(for: threadID), contentVersion: appModel.iosLearningContentStore.catalog.contentVersion, assetURLs: appModel.iosLearningContentStore.assetURLs, appModel: appModel)
                case .soundVolume:
                    SoundVolumeLabView(appModel: appModel)
                case .learningQuest:
                    LearningQuestView(appModel: appModel, engine: appModel.learningQuestEngine)
                case .shapeGeometry:
                    GameplayThreadView(thread: appModel.iosLearningContentStore.catalog.thread(for: .shapes), contentVersion: appModel.iosLearningContentStore.catalog.contentVersion, assetURLs: appModel.iosLearningContentStore.assetURLs, appModel: appModel)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
        }
        .onAppear {
            if ProcessInfo.processInfo.arguments.contains("-angle-arcade-ui-test") { appModel.engine.showAngleCannon() }
        }
        .background(MatherTheme.background.ignoresSafeArea())
        .environment(\.learningContentAssetURLs, appModel.iosLearningContentStore.assetURLs)
        .onChange(of: appModel.profileStore.activeProfileId) { _, _ in
            appModel.explorerLabMasteryProfile = appModel.explorerLabMasteryStore.load()
        }
        .onChange(of: appModel.engine.route) { _, route in
            if Self.isContentBoundary(route) { appModel.iosLearningContentStore.activatePending() }
        }
        .onChange(of: appModel.iosLearningContentStore.catalog.contentVersion) { _, version in
            appModel.gameplayProgressStore.invalidateCatalogConfidence(contentVersion: version)
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { Task { @MainActor in await refreshContent() } }
        }
        .task {
            appModel.gameplayProgressStore.invalidateCatalogConfidence(contentVersion: appModel.iosLearningContentStore.catalog.contentVersion)
            await refreshContent()
        }
        .sheet(isPresented: $appModel.showingProfilePicker, onDismiss: { appModel.cancelPendingProfilePick() }) {
            ProfilePickerView(store: appModel.profileStore) {
                appModel.confirmProfilePick()
            }
        }
    }

    private func refreshContent() async {
        if appModel.featureFlags.testModeEnabled && UserDefaults.standard.bool(forKey: "uiTest.disableContentRefresh") { return }
        guard let value = Bundle.main.object(forInfoDictionaryKey: "IOSLearningContentURL") as? String,
              let url = URL(string: value) else { return }
        await appModel.iosLearningContentStore.refresh(from: url,
            canActivate: { Self.isContentBoundary(appModel.engine.route) })
    }
}
