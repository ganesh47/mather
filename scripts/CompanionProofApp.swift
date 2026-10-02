import SwiftUI

/// Synthetic-only app entry point used by the isolated UI proof harness, never a release target.
@main
@MainActor
struct CompanionProofApp: App {
    @State private var store: LearningHandoffStore

    init() {
        let defaults = UserDefaults(suiteName: "mather.companion.ui-proof.synthetic")!
        let store = LearningHandoffStore(defaults: defaults)
        if ProcessInfo.processInfo.arguments.contains("-companion-reset") { store.resetAll() }
        _store = State(initialValue: store)
    }

    var body: some Scene {
        WindowGroup {
            LearningCompanionView(profileID: "synthetic-A", displayName: "Synthetic learner A", store: store, audioEnabled: false)
        }
    }
}
