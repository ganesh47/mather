import SwiftData
import SwiftUI

@main
struct MatherApp: App {
    private let container: ModelContainer
    @State private var appModel: AppModel

    init() {
        do {
            container = try ModelContainer(for: StoredSessionSummary.self)
            _appModel = State(initialValue: AppModel(modelContext: container.mainContext))
        } catch {
            fatalError("Failed to create model container: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            RootView(appModel: appModel)
                .modelContainer(container)
        }
    }
}
