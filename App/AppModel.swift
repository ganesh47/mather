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
    var angleArcadeEngine: AngleArcadeEngine
    private var angleArcadeProfileScope: String
    let explorerLabMasteryStore: ExplorerLabMasteryStore
    let questCheckpointStore: QuestCheckpointStore
    let learningQuestEngine: LearningQuestEngine
    let laneRecallReviewEngine: LaneRecallReviewEngine
    let iosLearningContentStore = IOSLearningContentStore()
    var rectangleFactoryStartingTarget = 4

    var explorerLabMasteryProfile: ExplorerLabMasteryProfile
    var showingProfilePicker = false
    var learningDataResetIssue: String?
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

    func cancelPendingProfilePick() { pendingGameAction = nil }

    func confirmProfilePick() {
        explorerLabMasteryProfile = explorerLabMasteryStore.load()
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
        guard pendingLabGameplayCompletionContext?.stage == .blast else { return }
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

    func prepareAngleArcadeProfile() {
        let scope = Self.angleArcadeScope(profileID: profileStore.activeProfileId)
        guard scope != angleArcadeProfileScope else { return }
        angleArcadeEngine.cancelFlight()
        angleArcadeProfileScope = scope
        angleArcadeEngine = AngleArcadeEngine(store: Self.angleArcadeStore(scope: scope))
    }

    private static func angleArcadeScope(profileID: String) -> String {
        ProcessInfo.processInfo.arguments.contains("-angle-arcade-ui-test") ? "ipad-ui-test" : "ipad-\(profileID)"
    }

    private static func angleArcadeStore(scope: String) -> AngleArcadeProgressStore {
        let arguments = ProcessInfo.processInfo.arguments
        let defaults = arguments.contains("-angle-arcade-ui-test")
            ? UserDefaults(suiteName: "mather.angleArcade.uiTests")! : .standard
        if arguments.contains("-angle-arcade-ui-test") && arguments.contains("-angle-arcade-reset-progress") {
            defaults.removePersistentDomain(forName: "mather.angleArcade.uiTests")
        }
        return AngleArcadeProgressStore(defaults: defaults, scope: scope)
    }

    func launchLearningQuest(_ questID: LearningQuestID, guidedPlanID: String? = nil, returnLaneID: CapabilityLaneID? = nil, returnToGames: Bool = false) {
        pickProfileThenRun { [weak self] in
            guard let self else { return }
            self.clearLabGameplayCompletion()
            self.learningQuestEngine.start(questID, guidedPlanID: guidedPlanID, returnLaneID: returnLaneID, returnToGames: returnToGames, content: LearningQuestContentSnapshot(catalog: self.iosLearningContentStore.catalog))
            if self.learningQuestEngine.pauseMessage == nil, let guidedPlanID, let plan = LabConceptSessionPlan.plan(for: guidedPlanID) {
                _ = self.labConceptSessionProgressStore.beginGuidedStage(self.learningQuestEngine.checkpoint.step.guidedStage, in: plan)
            }
            self.engine.showLearningQuest(questID)
        }
    }

    func clearActiveProfileLearningData() {
        learningDataResetIssue = nil
        let profileID = profileStore.activeProfileId
        let reports = ParentOffscreenObservationStore()
        var issues: [String] = []
        if !reports.clearSelectedProfile(profileID: profileID), let message = reports.storageIssue?.message { issues.append(message) }
        do { try LearningHandoffStore().reset(profileID: profileID) }
        catch { issues.append("The companion data could not be read and was preserved. Open Continue an idea in Parent Summary to review its recovery options.") }
        historyStore.clearActiveProfile(); gameSessionStore.clearActiveProfile(); telemetryWriter.clearEventsForActiveProfile()
        gameplayProgressStore.clearActiveProfile()
        if !questCheckpointStore.reset(), let message = questCheckpointStore.storageIssue?.message { issues.append(message) }
        labConceptSessionProgressStore.reset()
        explorerLabMasteryStore.reset(); explorerLabMasteryProfile = explorerLabMasteryStore.load()
        angleArcadeEngine.cancelFlight()
        let angleStore = Self.angleArcadeStore(scope: Self.angleArcadeScope(profileID: profileStore.activeProfileId))
        angleStore.clear()
        angleArcadeProfileScope = angleStore.scope
        angleArcadeEngine = AngleArcadeEngine(store: angleStore)
        learningDataResetIssue = issues.isEmpty ? nil : issues.joined(separator: "\n\n")
    }

    func leaveLearningQuest() { returnFromLearningQuest(learningQuestEngine.checkpoint) }
    private func returnFromLearningQuest(_ checkpoint: LearningQuestCheckpoint) {
        if let lane = checkpoint.returnLaneID { engine.showLabLane(lane) }
        else if checkpoint.returnToGames { engine.showLabGames() }
        else { engine.showHome() }
    }

    private var nextResumeThread: GameplayThreadID? {
        guard let saved = gameplayProgressStore.mostRecentCheckpoint(), let thread = GameplayThreadID(rawValue: saved.activityID) else { return nil }
        if let quest = questCheckpointStore.mostRecent, quest.updatedAt > (saved.updatedAt ?? saved.startedAt) { return nil }
        return thread
    }
    private var nextReviewThread: GameplayThreadID? {
        guard questCheckpointStore.mostRecent == nil else { return nil }
        return gameplayProgressStore.dueAndWeakRecords().compactMap { GameplayThreadID(rawValue: $0.threadId) }.first
    }
    var nextLearningQuest: LearningQuestID {
        if let checkpoint = questCheckpointStore.mostRecent { return checkpoint.questID }
        if let quest = gameplayProgressStore.dueAndWeakRecords().compactMap({ LearningQuestID.matching(conceptID: $0.conceptId) }).first { return quest }
        let completedIDs = Set(gameplayProgressStore.allSessions().map(\.threadId))
        return LearningQuestID.pilots.first { !completedIDs.contains($0.activityID) } ?? .numbers
    }
    var nextLearningQuestLabel: String {
        if let thread = nextResumeThread { return "Continue \(iosLearningContentStore.catalog.thread(for: thread).title)" }
        if let checkpoint = questCheckpointStore.mostRecent { return "Continue \(checkpoint.questID.title) · \(checkpoint.step.title)" }
        if let thread = nextReviewThread { return "Remember \(iosLearningContentStore.catalog.thread(for: thread).title)" }
        return "Try \(nextLearningQuest.title)"
    }
    func launchNextLearningQuest() {
        // Re-resolve after child selection so a different child never inherits Resume.
        pickProfileThenRun { [weak self] in
            guard let self else { return }
            if let thread = self.nextResumeThread {
                self.engine.showGameplayThread(thread, returnRoute: .home); return
            }
            if let thread = self.nextReviewThread {
                self.engine.showGameplayThread(thread, returnRoute: .home); return
            }
            let quest = self.nextLearningQuest
            self.learningQuestEngine.start(quest, content: LearningQuestContentSnapshot(catalog: self.iosLearningContentStore.catalog))
            self.engine.showLearningQuest(quest)
        }
    }

    init(modelContext: ModelContext) {
        let profileStore = KidProfileStore(modelContext: modelContext)
        let scope = Self.angleArcadeScope(profileID: profileStore.activeProfileId)
        angleArcadeProfileScope = scope
        angleArcadeEngine = AngleArcadeEngine(store: Self.angleArcadeStore(scope: scope))
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
        roomQuestEngine.onExitToHome = { [weak vsEngine] in vsEngine?.returnFromGameplay(defaultRoute: .home) }

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
        let explorerLabMasteryStore = ExplorerLabMasteryStore(activeProfileIdProvider: { profileStore.activeProfileId })
        let questCheckpointStore = QuestCheckpointStore(
            activeProfileID: { profileStore.activeProfileId },
            priorAttempts: {
                QuestPriorEvidenceReader.attempts(profileID: profileStore.activeProfileId, context: modelContext)
            }
        )
        let learningQuestEngine = LearningQuestEngine(store: questCheckpointStore, activeProfileID: { profileStore.activeProfileId })
        let laneRecallReviewEngine = LaneRecallReviewEngine(activeProfileID: { profileStore.activeProfileId })
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
        self.questCheckpointStore = questCheckpointStore
        self.learningQuestEngine = learningQuestEngine
        self.laneRecallReviewEngine = laneRecallReviewEngine
        self.explorerLabMasteryStore = explorerLabMasteryStore
        self.explorerLabMasteryProfile = explorerLabMasteryProfile
        self.sumSprintEngine = sumSprintEngine
        laneRecallReviewEngine.onSpeak = { [weak speechService, weak featureFlags] text in
            guard let speechService, let featureFlags else { return }
            speechService.speak(text, enabled: featureFlags.audioEnabled)
        }
        laneRecallReviewEngine.onAttempt = { [weak gameplayProgressStore] attempt, sessionID in gameplayProgressStore?.recordAttempts([attempt], sessionID: sessionID) }
        laneRecallReviewEngine.onResult = { [weak gameplayProgressStore] result in gameplayProgressStore?.saveActivityResult(result) }
        learningQuestEngine.onSpeak = { [weak speechService, weak featureFlags] text in
            guard let speechService, let featureFlags else { return }
            speechService.speak(text, enabled: featureFlags.audioEnabled)
        }
        learningQuestEngine.onAttempt = { [weak gameplayProgressStore] attempt, sessionID in
            gameplayProgressStore?.recordAttempts([attempt], sessionID: sessionID)
        }
        learningQuestEngine.onStageCompleted = { [weak labConceptSessionProgressStore] checkpoint, step in
            guard let planID = checkpoint.guidedPlanID, let plan = LabConceptSessionPlan.plan(for: planID) else { return }
            _ = labConceptSessionProgressStore?.markCompleted(step.guidedStage, in: plan)
        }
        learningQuestEngine.onCompleted = { [weak self, weak gameplayProgressStore] checkpoint, result in
            gameplayProgressStore?.saveActivityResult(result)
            self?.markExplorerLabModeCompleted(laneID: checkpoint.questID.laneID, mode: .learn)
            self?.returnFromLearningQuest(checkpoint)
        }
        sumSprintEngine.onExitToHome = { [weak vsEngine] in vsEngine?.returnFromGameplay(defaultRoute: .home) }
        vsEngine.activityProfileIDProvider = { profileStore.activeProfileId }
        roomQuestEngine.activityProfileIDProvider = { profileStore.activeProfileId }
        sumSprintEngine.activityProfileIDProvider = { profileStore.activeProfileId }
        vsEngine.onItemAttempt = { [weak gameplayProgressStore] attempt, sessionID in gameplayProgressStore?.recordAttempts([attempt], sessionID: sessionID) }
        roomQuestEngine.onItemAttempt = { [weak gameplayProgressStore] attempt, sessionID in gameplayProgressStore?.recordAttempts([attempt], sessionID: sessionID) }
        sumSprintEngine.onItemAttempt = { [weak gameplayProgressStore] attempt, sessionID in gameplayProgressStore?.recordAttempts([attempt], sessionID: sessionID) }
        vsEngine.onActivityResult = { [weak gameplayProgressStore] result in gameplayProgressStore?.saveActivityResult(result) }
        roomQuestEngine.onActivityResult = { [weak gameplayProgressStore] result in gameplayProgressStore?.saveActivityResult(result) }
        sumSprintEngine.onActivityResult = { [weak gameplayProgressStore] result in gameplayProgressStore?.saveActivityResult(result) }
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
        roomQuestEngine.onSessionComplete = { [weak gameSessionStore] summary in
            gameSessionStore?.save(
                gameName: "Room Quest",
                startedAt: summary.startedAt,
                scoreValue: summary.collectedTokenCount,
                scoreLabel: "tokens collected",
                detail: summary.abstractCorrect ? "transfer correct" : "transfer retry"
            )
        }
    }
}
