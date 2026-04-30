import Foundation
import Observation
import SwiftData

@MainActor
@Observable
final class AppModel {
    let profileStore: KidProfileStore
    let featureFlags: FeatureFlagService
    let speechService: SpeechService
    let memoryCardDescribeService: MemoryCardDescribeService
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
    let gameSessionStore: GameSessionStore
    let explorerLabMasteryStore: ExplorerLabMasteryStore

    var explorerLabMasteryProfile: ExplorerLabMasteryProfile
    var showingProfilePicker = false
    private var pendingGameAction: (() -> Void)?

    func pickProfileThenRun(_ action: @escaping () -> Void) {
        if featureFlags.skipProfilePicker {
            action()
            return
        }
        pendingGameAction = action
        showingProfilePicker = true
    }

    func confirmProfilePick() {
        showingProfilePicker = false
        let action = pendingGameAction
        pendingGameAction = nil
        action?()
    }

    init(modelContext: ModelContext) {
        let profileStore = KidProfileStore(modelContext: modelContext)
        let featureFlags = FeatureFlagService()
        let speechService = SpeechService()
        let memoryCardDescribeService = MemoryCardDescribeService(appleIntelligenceEnabled: { featureFlags.memoryCardAppleIntelligenceEnabled })
        let telemetryWriter = TelemetryWriter(modelContext: modelContext, activeProfileIdProvider: { profileStore.activeProfileId })
        let historyStore = SessionHistoryStore(modelContext: modelContext, activeProfileIdProvider: { profileStore.activeProfileId })
        let roomQuestStationStore = RoomQuestStationStore(modelContext: modelContext)
        let hapticsService = HapticsService()
        let motionService = MotionService()
        let soundDetectionService = SoundDetectionService()
        let roomQuestScanner = RoomQuestLiveScanner()

        self.featureFlags = featureFlags
        self.profileStore = profileStore
        self.speechService = speechService
        self.memoryCardDescribeService = memoryCardDescribeService
        self.telemetryWriter = telemetryWriter
        self.historyStore = historyStore
        self.roomQuestStationStore = roomQuestStationStore
        self.hapticsService = hapticsService
        self.motionService = motionService
        self.soundDetectionService = soundDetectionService
        self.roomQuestScanner = roomQuestScanner
        roomQuestScanner.featureFlags = featureFlags

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
            motionService: motionService,
            scanner: roomQuestScanner,
            stationStore: roomQuestStationStore
        )
        self.roomQuestEngine = roomQuestEngine
        roomQuestEngine.onExitToHome = { [weak vsEngine] in vsEngine?.showHome() }

        roomQuestScanner.onVerifyFeedback = { [weak speechService, weak featureFlags] feedback in
            guard let speechService, let featureFlags else { return }
            switch feedback {
            case .close(let wasGPS):
                let msg = wasGPS
                    ? "Almost there! Walk a little closer, then check again."
                    : "Almost! Try to match the saved photo."
                speechService.speak(msg, enabled: featureFlags.audioEnabled)
            case .noMatch(let wasGPS):
                let msg = wasGPS
                    ? "Wrong place. Keep looking around."
                    : "That doesn't look right. Keep searching."
                speechService.speak(msg, enabled: featureFlags.audioEnabled)
            default:
                break
            }
        }

        let factStore = FactRecordStore(modelContext: modelContext, activeProfileIdProvider: { profileStore.activeProfileId })
        let gameSessionStore = GameSessionStore(modelContext: modelContext, activeProfileIdProvider: { profileStore.activeProfileId })
        let explorerLabMasteryStore = ExplorerLabMasteryStore()
        let explorerLabMasteryProfile = explorerLabMasteryStore.load()
        let sumSprintEngine = SumSprintEngine(
            featureFlags: featureFlags,
            telemetryWriter: telemetryWriter,
            speechService: speechService,
            hapticsService: hapticsService,
            factStore: factStore
        )
        self.factStore = factStore
        self.gameSessionStore = gameSessionStore
        self.explorerLabMasteryStore = explorerLabMasteryStore
        self.explorerLabMasteryProfile = explorerLabMasteryProfile
        self.sumSprintEngine = sumSprintEngine
        sumSprintEngine.onExitToHome = { [weak vsEngine] in vsEngine?.showHome() }
        sumSprintEngine.onSessionComplete = { [weak gameSessionStore] summary in
            gameSessionStore?.save(
                gameName: "Sum Sprint",
                startedAt: summary.startedAt,
                scoreValue: summary.correctCount,
                scoreLabel: "correct",
                detail: summary.difficulty.rawValue
            )
        }
    }
}
