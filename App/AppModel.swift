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
    let roomQuestStationStore: RoomQuestStationStore
    let engine: VerticalSliceEngine
    let hapticsService: HapticsService
    let motionService: MotionService
    let soundDetectionService: SoundDetectionService
    let roomQuestScanner: RoomQuestLiveScanner
    let roomQuestEngine: RoomQuestEngine
    let factStore: FactRecordStore
    let sumSprintEngine: SumSprintEngine

    init(modelContext: ModelContext) {
        let featureFlags = FeatureFlagService()
        let speechService = SpeechService()
        let telemetryWriter = TelemetryWriter()
        let historyStore = SessionHistoryStore(modelContext: modelContext)
        let roomQuestStationStore = RoomQuestStationStore(modelContext: modelContext)
        let hapticsService = HapticsService()
        let motionService = MotionService()
        let soundDetectionService = SoundDetectionService()
        let roomQuestScanner = RoomQuestLiveScanner()

        self.featureFlags = featureFlags
        self.speechService = speechService
        self.telemetryWriter = telemetryWriter
        self.historyStore = historyStore
        self.roomQuestStationStore = roomQuestStationStore
        self.hapticsService = hapticsService
        self.motionService = motionService
        self.soundDetectionService = soundDetectionService
        self.roomQuestScanner = roomQuestScanner

        let vsEngine = VerticalSliceEngine(
            featureFlags: featureFlags,
            telemetryWriter: telemetryWriter,
            speechService: speechService,
            hapticsService: hapticsService,
            saveSummary: historyStore.save
        )
        engine = vsEngine

        let roomQuestEngine = RoomQuestEngine(
            featureFlags: featureFlags,
            telemetryWriter: telemetryWriter,
            speechService: speechService,
            hapticsService: hapticsService,
            scanner: roomQuestScanner,
            stationStore: roomQuestStationStore
        )
        self.roomQuestEngine = roomQuestEngine
        roomQuestEngine.onExitToHome = { [weak vsEngine] in vsEngine?.showHome() }

        let factStore = FactRecordStore(modelContext: modelContext)
        let sumSprintEngine = SumSprintEngine(
            featureFlags: featureFlags,
            telemetryWriter: telemetryWriter,
            speechService: speechService,
            hapticsService: hapticsService,
            factStore: factStore
        )
        self.factStore = factStore
        self.sumSprintEngine = sumSprintEngine
        sumSprintEngine.onExitToHome = { [weak vsEngine] in vsEngine?.showHome() }
    }
}
