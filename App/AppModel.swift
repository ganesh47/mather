import Foundation
import Observation
import SwiftData

@MainActor
@Observable
final class AppModel {
    let featureFlags: FeatureFlagService
    let speechService: SpeechService
    let telemetryWriter: TelemetryWriter
    let historyStore: SessionHistoryStore
    let engine: VerticalSliceEngine

    init(modelContext: ModelContext) {
        let featureFlags = FeatureFlagService()
        let speechService = SpeechService()
        let telemetryWriter = TelemetryWriter()
        let historyStore = SessionHistoryStore(modelContext: modelContext)

        self.featureFlags = featureFlags
        self.speechService = speechService
        self.telemetryWriter = telemetryWriter
        self.historyStore = historyStore
        engine = VerticalSliceEngine(
            featureFlags: featureFlags,
            telemetryWriter: telemetryWriter,
            speechService: speechService,
            saveSummary: historyStore.save
        )
    }
}
