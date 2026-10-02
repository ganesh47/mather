import Foundation
import SwiftData
import Testing
@testable import Mather

@MainActor
private final class QuestTestProfile { var id = "child-a" }
private final class QuestTestDefaults: ExplorerLabMasteryKeyValueStore {
    var values: [String: Data] = [:]
    func data(forKey key: String) -> Data? { values[key] }
    func set(_ value: Data?, forKey key: String) { values[key] = value }
    func removeObject(forKey key: String) { values.removeValue(forKey: key) }
}

@MainActor
struct LearningQuestTests {
    @Test func dueStandaloneNumberBondReturnsToNumbersInsteadOfUnrelatedNewQuest() throws {
        let schema = Schema([StoredSessionSummary.self, StoredRoomQuestStationReference.self, StoredFactRecord.self, StoredKidProfile.self, StoredTelemetryEvent.self, StoredGameSession.self, StoredGameplayProgressRecord.self, StoredGameplayThreadSession.self])
        let container = try ModelContainer(for: schema, configurations: ModelConfiguration(schema: schema, isStoredInMemoryOnly: true))
        let model = AppModel(modelContext: ModelContext(container))
        model.profileStore.addProfile(name: "Recommendation", emoji: "🌱")
        defer { model.clearActiveProfileLearningData() }
        model.gameplayProgressStore.saveActivityResult(ActivityResult(activityID: LearningQuestID.numbers.activityID,
            title: "Ten Together", startedAt: Date(), attempts: [], completedStageIDs: ["celebrate"]))
        #expect(model.nextLearningQuest == .shapes)
        let attempt = ItemAttempt(activityID: "make-break", conceptID: "number-bonds", entityID: "whole-6",
            stageID: "transfer", outcome: .incorrect, response: "2 + 3")
        model.gameplayProgressStore.recordAttempts([attempt], sessionID: "standalone-number-review")
        #expect(model.nextLearningQuest == .numbers)
        #expect(LearningQuestID.matching(conceptID: "number-bond") == .numbers)
    }
    private func fixture() -> (QuestTestProfile, QuestCheckpointStore, LearningQuestEngine) {
        let profile = QuestTestProfile()
        let store = QuestCheckpointStore(storage: QuestTestDefaults(), activeProfileID: { profile.id })
        return (profile, store, LearningQuestEngine(store: store, activeProfileID: { profile.id }))
    }
    private func answer(_ engine: LearningQuestEngine, _ choice: String) {
        engine.choose(choice); engine.submit(); engine.submit()
    }
    @Test func numbersKeepChildPartitionAndRecordActualTransfer() throws {
        let (_, store, engine) = fixture()
        var result: ActivityResult?
        engine.onCompleted = { _, value in result = value }
        engine.start(.numbers)
        engine.adjustCount(1) // Seven and three are this child's parts.
        engine.submit()
        #expect(engine.checkpoint.learnedLeftPart == 7)
        #expect(engine.checkpoint.choices.contains { $0.id == "3" })
        answer(engine, "3")
        for _ in 0..<3 { engine.adjustCount(1) }
        engine.submit(); engine.submit()
        #expect(engine.checkpoint.step == .challenge)
        for _ in 0..<5 { engine.adjustCount(1) }
        engine.submit(); engine.submit(); engine.submit()
        let saved = try #require(result)
        #expect(saved.completedStageIDs == ["learn", "remember", "play", "challenge", "celebrate"])
        #expect(saved.attempts.filter { $0.outcome == .exposure }.count == 1)
        #expect(saved.attempts.filter { $0.outcome == .independentCorrect }.count == 3)
        #expect(saved.attempts.last?.propertyID == "transfer")
        #expect(saved.attempts.last?.response == "placed=5")
        #expect(saved.profileID == "child-a")
        #expect(store.checkpoint(for: .numbers) == nil)
    }
    @Test func exactResumeIsChildScopedAndFrozenAcrossContentUpdates() throws {
        let (profile, store, engine) = fixture()
        let bundled = IOSLearningCatalog.bundled
        let versionSeven = IOSLearningCatalog(schemaVersion: bundled.schemaVersion, contentVersion: 7, decks: bundled.decks, threads: bundled.threads, assets: bundled.assets)
        engine.start(.numbers, returnLaneID: .numbers, content: LearningQuestContentSnapshot(catalog: versionSeven))
        engine.adjustCount(-2); engine.submit(); engine.choose("6")
        let before = engine.checkpoint
        let resumed = LearningQuestEngine(store: store, activeProfileID: { profile.id })
        resumed.start(.numbers, content: .bundled)
        var restored = resumed.checkpoint
        restored.updatedAt = before.updatedAt
        #expect(restored == before)
        #expect(resumed.checkpoint.contentVersion == 7)
        #expect(resumed.checkpoint.content == before.content)
        #expect(resumed.checkpoint.learnedLeftPart == 4)
        profile.id = "child-b"
        #expect(store.checkpoint(for: .numbers) == nil)
        resumed.start(.numbers)
        #expect(resumed.checkpoint.step == .learn)
        #expect(resumed.checkpoint.profileID == "child-b")
        profile.id = "child-a"
        #expect(store.checkpoint(for: .numbers)?.sessionID == before.sessionID)
    }
    @Test func profileSwitchDuringQuestCannotWriteAnotherChildEvidence() {
        let (profile, store, engine) = fixture()
        engine.start(.numbers); engine.adjustCount(1)
        let before = engine.checkpoint
        profile.id = "child-b"
        engine.adjustCount(1); engine.help(); engine.submit()
        #expect(engine.checkpoint == before)
        #expect(store.mostRecent == nil)
    }
    @Test func helpAndCorrectionAreSupportedWithoutLosingProgress() {
        let (_, _, engine) = fixture()
        engine.start(.numbers); engine.adjustCount(1); engine.submit()
        engine.choose("2"); engine.submit()
        #expect(!engine.checkpoint.accepted)
        engine.help(); engine.choose("3"); engine.submit()
        #expect(engine.checkpoint.accepted)
        #expect(engine.checkpoint.attempts.map(\.outcome) == [.exposure, .incorrect, .help, .supportedCorrect])
        #expect(engine.checkpoint.completedSteps == [.learn, .remember])
    }
    @Test func circuitPredictionAndRepairAreDistinctEvidence() {
        let (_, _, engine) = fixture()
        engine.start(.circuitSpark); engine.toggleSwitch(); engine.submit()
        answer(engine, "closed")
        engine.repairWire(); engine.submit(); engine.submit()
        engine.choose("off"); engine.submit()
        #expect(engine.checkpoint.predictionMade)
        #expect(!engine.checkpoint.accepted)
        engine.toggleSwitch(second: true); engine.submit()
        let transfer = engine.checkpoint.attempts.filter { $0.stageID == "challenge" }
        #expect(transfer.count == 2)
        #expect(Set(transfer.map(\.entityID)).count == 2)
        #expect(transfer.map(\.response) == ["off", "wire=true;switch=true;second=true"])
        #expect(transfer.allSatisfy { $0.outcome == .independentCorrect })
    }
    @Test func shapeExplorationNeedsFourShapesAndRotationAndRejectsCollinearCorners() {
        let (_, _, engine) = fixture()
        engine.start(.shapes); engine.turnShape()
        #expect(!engine.checkpoint.canSubmit)
        for shape in ["circle", "square", "rectangle"] { engine.selectShape(shape) }
        #expect(engine.checkpoint.canSubmit)
        engine.submit(); answer(engine, "triangle")
        for index in [0, 2, 4] { engine.togglePoint(index) }
        engine.submit()
        #expect(!engine.checkpoint.accepted)
        engine.togglePoint(2); engine.togglePoint(1); engine.submit()
        #expect(engine.checkpoint.accepted)
        #expect(engine.checkpoint.attempts.last?.outcome == .supportedCorrect)
    }
    @Test func waterRequiresWarmThenCoolAndTransfersToColdCup() {
        let (_, _, engine) = fixture()
        engine.start(.waterCycle); engine.coolWater(); engine.submit()
        #expect(engine.checkpoint.step == .learn)
        engine.warmWater(); engine.coolWater(); engine.submit()
        answer(engine, "vapor"); answer(engine, "drops")
        engine.choose("outside"); engine.submit()
        #expect(engine.checkpoint.accepted)
        #expect(engine.checkpoint.attempts.last?.propertyID == "transfer")
    }
    @Test func allFourGuidedPlansHaveSubjectAlignedCompletableRoutes() {
        let plans = [LabConceptSessionPlan.numbersNumberBondsTo10, .geometryShapeNames, .geometryAnglesBasic, .geometrySymmetryFolds]
        let (_, _, engine) = fixture()
        var stages: [LearningQuestStep] = []
        engine.onStageCompleted = { _, step in stages.append(step) }
        for plan in plans {
            let quest = LearningQuestID.guided(plan.id)!
            #expect(plan.stages.allSatisfy { $0.route == .learningQuest(quest) })
            #expect(plan.pathLabel == "Learn → Remember → Play → Challenge → Celebrate")
        }
        engine.start(.angles, guidedPlanID: LabConceptSessionPlan.geometryAnglesBasic.id)
        engine.changeAngle(15); engine.submit(); answer(engine, "90")
        for _ in 0..<4 { engine.changeAngle(15) }
        engine.submit(); engine.submit()
        for _ in 0..<6 { engine.changeAngle(15) }
        engine.submit(); engine.submit(); engine.submit()
        #expect(stages == LearningQuestStep.allCases)
        stages = []
        engine.start(.symmetry, guidedPlanID: LabConceptSessionPlan.geometrySymmetryFolds.id)
        engine.fold(); engine.submit(); answer(engine, "match")
        engine.toggleMirrorCell(0); engine.submit(); engine.submit()
        engine.toggleMirrorCell(0); engine.toggleMirrorCell(2); engine.fold()
        engine.submit(); engine.submit(); engine.submit()
        #expect(stages == LearningQuestStep.allCases)
    }
    @Test func originReturnsFromEveryGameAndSurvivesFactoryHandoff() throws {
        let schema = Schema([StoredSessionSummary.self, StoredRoomQuestStationReference.self, StoredFactRecord.self, StoredKidProfile.self, StoredTelemetryEvent.self, StoredGameSession.self, StoredGameplayProgressRecord.self, StoredGameplayThreadSession.self])
        let container = try ModelContainer(for: schema, configurations: ModelConfiguration(schema: schema, isStoredInMemoryOnly: true))
        let model = AppModel(modelContext: ModelContext(container)), engine = model.engine
        for route in [AppRoute.sumSprint, .symmetryFold, .angleCannon, .twoFingerProtractor, .gravityArtist, .compassAngles, .rectangleFactory, .roomQuest, .soundVolume, .memory] {
            engine.showActivity(route, returnRoute: .labLane(.geometry))
            engine.returnFromGameplay(defaultRoute: .home)
            #expect(engine.route == .labLane(.geometry))
            #expect(engine.gameplayReturnRoute == nil)
        }
        engine.showActivity(.factoryCards, returnRoute: .labGames)
        engine.showActivity(.rectangleFactory, returnRoute: engine.gameplayReturnRoute)
        engine.returnFromGameplay(defaultRoute: .home)
        #expect(engine.route == .labGames)
        engine.showActivity(.sumSprint, returnRoute: .labLane(.numbers)); engine.showHome()
        #expect(engine.route == .home)
        #expect(engine.gameplayReturnRoute == nil)
    }
    @Test func clearingSelectedChildPreservesOthersAndClearAllRemovesEveryCheckpoint() {
        let (profile, store, engine) = fixture()
        engine.start(.numbers)
        profile.id = "child-b"; engine.start(.shapes)
        store.reset()
        #expect(store.mostRecent == nil)
        profile.id = "child-a"
        #expect(store.checkpoint(for: .numbers) != nil)
        store.clearAllProfiles()
        #expect(store.mostRecent == nil)
    }
    @Test func legacyExplorerHistoryIsReadableWithoutAssigningItToAnyChild() throws {
        let defaults = QuestTestDefaults(), profile = QuestTestProfile()
        var legacy = ExplorerLabMasteryProfile.emptyExplorerProfile()
        legacy.updateLane(.numbers) { $0.markCompleted(.learn); $0.setConfidence(.mastered, for: "number-bond") }
        defaults.set(try JSONEncoder().encode(legacy), forKey: ExplorerLabMasteryStore.legacyDeviceStorageKey)
        let store = ExplorerLabMasteryStore(storage: defaults, activeProfileIdProvider: { profile.id })
        #expect(store.legacyDeviceHistory == legacy)
        #expect(store.load()[.numbers]?.completedModes.isEmpty == true)
        store.markCompleted(laneID: .numbers, mode: .learn)
        profile.id = "child-b"
        #expect(store.load()[.numbers]?.completedModes.isEmpty == true)
        profile.id = "child-a"
        #expect(store.load()[.numbers]?.completedModes == [.learn])
    }
    @Test func launchReResolvesExactResumeAfterTheProfilePicker() throws {
        let schema = Schema([StoredSessionSummary.self, StoredRoomQuestStationReference.self, StoredFactRecord.self, StoredKidProfile.self, StoredTelemetryEvent.self, StoredGameSession.self, StoredGameplayProgressRecord.self, StoredGameplayThreadSession.self])
        let container = try ModelContainer(for: schema, configurations: ModelConfiguration(schema: schema, isStoredInMemoryOnly: true))
        let model = AppModel(modelContext: ModelContext(container))
        let previousSkip = model.featureFlags.skipProfilePicker, previousAudio = model.featureFlags.audioEnabled
        defer { model.featureFlags.skipProfilePicker = previousSkip; model.featureFlags.audioEnabled = previousAudio }
        model.featureFlags.skipProfilePicker = false; model.featureFlags.audioEnabled = false
        model.profileStore.addProfile(name: "First", emoji: "🦊")
        let first = model.profileStore.activeProfileId
        model.learningQuestEngine.start(.numbers); model.learningQuestEngine.adjustCount(1); model.learningQuestEngine.submit()
        model.profileStore.addProfile(name: "Second", emoji: "🐼")
        let second = model.profileStore.activeProfileId
        model.profileStore.setActiveProfile(id: first)
        model.launchLearningQuest(.numbers, guidedPlanID: LabConceptSessionPlan.numbersNumberBondsTo10.id, returnLaneID: .numbers)
        #expect(model.showingProfilePicker)
        model.profileStore.setActiveProfile(id: second); model.confirmProfilePick()
        #expect(model.learningQuestEngine.checkpoint.profileID == second)
        #expect(model.learningQuestEngine.checkpoint.step == .learn)
        #expect(model.learningQuestEngine.checkpoint.attempts.isEmpty)
        #expect(model.labConceptSessionProgressStore.currentStage(for: .numbersNumberBondsTo10) == .learn)
        model.clearActiveProfileLearningData()
        model.profileStore.setActiveProfile(id: first)
        #expect(model.questCheckpointStore.checkpoint(for: .numbers)?.step == .remember)
        model.clearActiveProfileLearningData()
    }
    @Test func resettingSelectedChildClearsRetainedAnglePassportAndPreservesOtherChild() throws {
        let schema = Schema([StoredSessionSummary.self, StoredRoomQuestStationReference.self, StoredFactRecord.self, StoredKidProfile.self, StoredTelemetryEvent.self, StoredGameSession.self, StoredGameplayProgressRecord.self, StoredGameplayThreadSession.self])
        let container = try ModelContainer(for: schema, configurations: ModelConfiguration(schema: schema, isStoredInMemoryOnly: true))
        let model = AppModel(modelContext: ModelContext(container))
        model.profileStore.addProfile(name: "First", emoji: "🦊")
        let first = model.profileStore.activeProfileId
        model.profileStore.addProfile(name: "Second", emoji: "🐼")
        let second = model.profileStore.activeProfileId
        let firstStore = AngleArcadeProgressStore(scope: "ipad-\(first)")
        let secondStore = AngleArcadeProgressStore(scope: "ipad-\(second)")
        defer { firstStore.save(AngleArcadeProgress()); secondStore.save(AngleArcadeProgress()) }
        let levelID = AngleArcadeCampaign.levels[0].id
        var saved = AngleArcadeProgress()
        saved.completions[levelID] = AngleArcadeCompletion(assisted: true)
        firstStore.save(saved); secondStore.save(saved)
        model.prepareAngleArcadeProfile()
        #expect(model.angleArcadeEngine.progress.hasCompleted(levelID))
        model.clearActiveProfileLearningData()
        #expect(model.angleArcadeEngine.progress.completions.isEmpty)
        #expect(secondStore.load().completions.isEmpty)
        #expect(firstStore.load().hasCompleted(levelID))
        model.profileStore.setActiveProfile(id: first)
        model.prepareAngleArcadeProfile()
        #expect(model.angleArcadeEngine.progress.hasCompleted(levelID))
    }
    @Test func parentEvidenceSeparatesExposureSupportAndActualTransferAndDeduplicates() {
        func attempt(_ outcome: ItemAttemptOutcome, property: String? = nil) -> ItemAttempt {
            ItemAttempt(activityID: "quest", conceptID: "parts", entityID: UUID().uuidString, propertyID: property, stageID: "challenge", outcome: outcome)
        }
        let transfer = attempt(.independentCorrect, property: "transfer")
        let summary = ParentLearningEvidenceSummary(attempts: [attempt(.exposure), attempt(.help), attempt(.supportedCorrect, property: "transfer"), transfer, transfer])
        #expect(summary.exposures == 1)
        #expect(summary.independent == 1)
        #expect(summary.supported == 1)
        #expect(summary.independentTransfers == 1)
    }
}
