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
                }
            }
            .navigationBarTitleDisplayMode(.inline)
        }
        .background(MatherTheme.background.ignoresSafeArea())
    }
}
