import Observation
import SwiftData
import SwiftUI

struct RootView: View {
    @Bindable var appModel: AppModel
    @Query(sort: \StoredSessionSummary.startedAt, order: .reverse) private var sessionSummaries: [StoredSessionSummary]

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
                    ParentSummaryView(appModel: appModel, summaries: sessionSummaries)
                case .settings:
                    SettingsView(appModel: appModel, summaries: sessionSummaries)
                case .roomQuest:
                    RoomSessionView(engine: appModel.roomQuestEngine, vsEngine: appModel.engine)
                        .sheet(item: Binding(
                            get: { appModel.roomQuestScanner.activeSession },
                            set: { _ in }
                        )) { _ in
                            RoomQuestScannerSheet(scanner: appModel.roomQuestScanner)
                        }
                case .rectangleFactory:
                    RectangleFactoryView(appModel: appModel)
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
                    LabView(appModel: appModel)
                case .memory:
                    MemoryView(appModel: appModel)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
        }
        .background(MatherTheme.background.ignoresSafeArea())
    }
}
