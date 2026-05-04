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
    let stepCountService: StepCountService
    let soundDetectionService: SoundDetectionService
    let roomQuestScanner: RoomQuestLiveScanner
    let roomQuestEngine: RoomQuestEngine
    let factStore: FactRecordStore
    let sumSprintEngine: SumSprintEngine
    let gameSessionStore: GameSessionStore
    let gameplayProgressStore: GameplayProgressStore
    let labConceptSessionProgressStore: LabConceptSessionProgressStore
    let explorerLabMasteryStore: ExplorerLabMasteryStore

    var explorerLabMasteryProfile: ExplorerLabMasteryProfile
    var showingProfilePicker = false
    private var pendingGameAction: (() -> Void)?
    private var pendingLabGameplayCompletionContext: LabGameplayCompletionContext?

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

    func markExplorerLabModeCompleted(laneID: CapabilityLaneID, mode: PlayMode) {
        explorerLabMasteryProfile = explorerLabMasteryStore.markCompleted(laneID: laneID, mode: mode)
    }

    func markExplorerLabReviewedCard(laneID: CapabilityLaneID, cardID: String) {
        explorerLabMasteryProfile = explorerLabMasteryStore.markReviewedCard(laneID: laneID, cardID: cardID)
    }

    func setExplorerLabConceptConfidence(
        _ confidence: ConceptConfidence,
        for conceptID: ConceptId,
        laneID: CapabilityLaneID
    ) {
        explorerLabMasteryProfile = explorerLabMasteryStore.setConfidence(
            confidence,
            for: conceptID,
            laneID: laneID
        )
    }

    func prepareLabGameplayCompletion(plan: LabConceptSessionPlan, stage: GuidedLabStage) {
        pendingLabGameplayCompletionContext = LabGameplayCompletionContext(plan: plan, stage: stage)
    }

    func clearLabGameplayCompletion() {
        pendingLabGameplayCompletionContext = nil
    }

    func completePendingLabGameplay(with summary: SumSprintSessionSummary) {
        let context = pendingLabGameplayCompletionContext
        pendingLabGameplayCompletionContext = nil

        let accuracy = summary.cards.isEmpty ? 0 : Double(summary.correctCount) / Double(summary.cards.count)
        let stageSummary = LabStageTimingScoreSummary(
            durationSeconds: summary.endedAt.timeIntervalSince(summary.startedAt),
            scoreSummary: LabSessionScoreSummary(
                conceptTitle: "Number Bonds to 10",
                stageDurations: [.play: summary.endedAt.timeIntervalSince(summary.startedAt)],
                accuracy: accuracy,
                streak: summary.peakStreak,
                weakAreas: summary.timeoutCount > 0 ? ["timed practice"] : [],
                nextRecommendation: "Try Bond Blast when ready"
            )
        )
        _ = labConceptSessionProgressStore.markLabLaunchedGameplayCompleted(context, summary: stageSummary)
    }

    func completePendingLabBondBlast(with summary: SessionSummaryDraft) {
        let context = pendingLabGameplayCompletionContext
        pendingLabGameplayCompletionContext = nil

        let duration = summary.endedAt.timeIntervalSince(summary.startedAt)
        let stageSummary = LabStageTimingScoreSummary(
            durationSeconds: duration,
            scoreSummary: LabSessionScoreSummary(
                conceptTitle: summary.objectiveTitle,
                stageDurations: [.blast: duration],
                accuracy: summary.firstAttemptAccuracy,
                streak: summary.transferCorrectCount,
                weakAreas: [],
                nextRecommendation: "Celebrate the spark score"
            )
        )
        _ = labConceptSessionProgressStore.markLabLaunchedGameplayCompleted(context, summary: stageSummary)
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
        let stepCountService = StepCountService()
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
        self.stepCountService = stepCountService
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
        let gameplayProgressStore = GameplayProgressStore(modelContext: modelContext, activeProfileIdProvider: { profileStore.activeProfileId })
        let labConceptSessionProgressStore = LabConceptSessionProgressStore(activeProfileIdProvider: { profileStore.activeProfileId })
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
        self.gameplayProgressStore = gameplayProgressStore
        self.labConceptSessionProgressStore = labConceptSessionProgressStore
        self.explorerLabMasteryStore = explorerLabMasteryStore
        self.explorerLabMasteryProfile = explorerLabMasteryProfile
        self.sumSprintEngine = sumSprintEngine
        sumSprintEngine.onExitToHome = { [weak vsEngine] in vsEngine?.showHome() }
        vsEngine.onSessionComplete = { [weak self] summary in
            self?.completePendingLabBondBlast(with: summary)
        }
        sumSprintEngine.onSessionComplete = { [weak self, weak gameSessionStore] summary in
            gameSessionStore?.save(
                gameName: "Sum Sprint",
                startedAt: summary.startedAt,
                scoreValue: summary.correctCount,
                scoreLabel: "correct",
                detail: summary.difficulty.rawValue
            )
            self?.completePendingLabGameplay(with: summary)
        }
    }
}
