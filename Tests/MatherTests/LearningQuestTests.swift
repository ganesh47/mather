import Foundation
import SwiftData
import Testing
@testable import Mather

@MainActor
private final class QuestTestProfile { var id = "child-a" }
private final class QuestTestDefaults: ExplorerLabMasteryKeyValueStore {
    var values: [String: Data] = [:]
    var rejectWrites = false
    func data(forKey key: String) -> Data? { values[key] }
    func set(_ value: Data?, forKey key: String) { if !rejectWrites { values[key] = value } }
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
        engine.submit(); engine.submit()
        #expect(engine.checkpoint.step == .challenge)
        #expect(engine.checkpoint.numberProbe.id == "coat-7-1")
        for _ in 0..<6 { engine.adjustCount(1) }
        engine.submit(); engine.submit(); engine.submit()
        let saved = try #require(result)
        #expect(saved.completedStageIDs == ["learn", "remember", "play", "challenge", "celebrate"])
        #expect(saved.attempts.filter { $0.outcome == .exposure }.count == 1)
        #expect(saved.attempts.filter { $0.outcome == .independentCorrect }.count == 3)
        #expect(saved.attempts.first { $0.stageID == "play" }?.outcome == .supportedCorrect)
        #expect(saved.attempts.first { $0.stageID == "play" }?.isFreshProbe == false)
        #expect(saved.attempts.last?.propertyID == "transfer")
        #expect(saved.attempts.last?.response == "placed=6")
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
        #expect(transfer.map(\.outcome) == [.independentCorrect, .supportedCorrect])
        #expect(transfer.last?.appHintUsed == true)
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
        let firstKey = "mather.angle-arcade.progress.v1.ipad-\(first)"
        let firstBytes = UserDefaults.standard.data(forKey: firstKey)
        let secondKey = "mather.angle-arcade.progress.v1.ipad-\(second)"
        var future = saved
        future.schemaVersion = 2
        let retained = try JSONEncoder().encode(future)
        UserDefaults.standard.set(retained, forKey: secondKey)
        model.angleArcadeEngine.beginSession()
        #expect(model.angleArcadeEngine.pauseMessage != nil)
        #expect(UserDefaults.standard.data(forKey: secondKey) == retained)
        model.clearActiveProfileLearningData()
        #expect(model.angleArcadeEngine.pauseMessage == nil)
        #expect(model.angleArcadeEngine.progress.completions.isEmpty)
        #expect(secondStore.load()?.completions.isEmpty == true)
        #expect(firstStore.load()?.hasCompleted(levelID) == true)
        #expect(UserDefaults.standard.data(forKey: firstKey) == firstBytes)
        model.profileStore.setActiveProfile(id: first)
        model.prepareAngleArcadeProfile()
        #expect(model.angleArcadeEngine.progress.hasCompleted(levelID))
    }
    @Test func parentEvidenceSeparatesExposureSupportAndActualTransferAndDeduplicates() {
        func attempt(_ outcome: ItemAttemptOutcome, property: String? = nil) -> ItemAttempt {
            ItemAttempt(activityID: "quest", conceptID: "parts", entityID: UUID().uuidString, propertyID: property, stageID: "challenge", outcome: outcome, isFreshProbe: property == "transfer" ? true : nil)
        }
        let transfer = attempt(.independentCorrect, property: "transfer")
        let summary = ParentLearningEvidenceSummary(attempts: [attempt(.exposure), attempt(.help), attempt(.supportedCorrect, property: "transfer"), transfer, transfer])
        #expect(summary.exposures == 1)
        #expect(summary.independent == 1)
        #expect(summary.supported == 1)
        #expect(summary.independentTransfers == 1)
    }
    private func finishNumbers(_ engine: LearningQuestEngine) {
        engine.adjustCount(1); engine.submit()
        engine.choose(String(engine.checkpoint.numberAnswer)); engine.submit(); engine.submit()
        for _ in 0..<engine.checkpoint.numberAnswer { engine.adjustCount(1) }
        engine.submit(); engine.submit()
        while engine.checkpoint.step == .challenge {
            for _ in 0..<engine.checkpoint.numberAnswer { engine.adjustCount(1) }
            engine.submit(); engine.submit()
        }
        engine.submit()
    }
    @Test func reviewedNumberBankHasCorrectUniqueChangedWholeProbesAndCompleteChoices() {
        let probes = LearningNumbersVariant.reviewed.flatMap(\.probes)
        #expect(probes.count == 6)
        #expect(Set(probes.map(\.id)).count == probes.count)
        #expect(Set(probes.map { "\($0.total)-\($0.knownPart)" }).count == probes.count)
        for (ordinal, variant) in LearningNumbersVariant.reviewed.enumerated() {
            #expect(variant.isReviewed)
            #expect(Set(variant.probes.map(\.answer)).count == variant.probes.count)
            #expect(LearningNumbersVariant.at(ordinal: ordinal + 3) == variant)
            #expect(variant.probes.allSatisfy { (1...9).contains($0.total) && (1..<$0.total).contains($0.knownPart) && $0.answer + $0.knownPart == $0.total })
            for part in 0...10 {
                var state = LearningQuestCheckpoint(profileID: "child-a", questID: .numbers, numbersVariant: variant)
                state.step = .remember; state.learnedLeftPart = part
                #expect(state.choices.count == 3)
                #expect(Set(state.choices.map(\.id)).count == 3)
                #expect(state.choices.contains { $0.id == String(10-part) })
            }
        }
    }
    @Test func repeatedSupportedPracticeAndIndependentFreshProbeRemainDistinctAfterResume() throws {
        let (profile, store, engine) = fixture()
        engine.start(.numbers); engine.adjustCount(1); engine.submit(); engine.help()
        engine.choose("3"); engine.submit(); engine.submit()
        let resumed = LearningQuestEngine(store: store, activeProfileID: { profile.id })
        var replay: [ItemAttempt] = []
        resumed.onAttempt = { attempt, _ in replay.append(attempt) }
        resumed.start(.numbers)
        #expect(replay.map(\.id) == engine.checkpoint.attempts.map(\.id))
        for _ in 0..<3 { resumed.adjustCount(1) }
        resumed.submit()
        #expect(resumed.checkpoint.attempts.last?.outcome == .supportedCorrect)
        #expect(resumed.checkpoint.attempts.last?.appHintUsed == true)
        #expect(resumed.checkpoint.attempts.last?.isFreshProbe == false)
        resumed.submit(); resumed.help()
        for _ in 0..<5 { resumed.adjustCount(1) }
        resumed.submit(); resumed.submit()
        #expect(resumed.checkpoint.step == .challenge)
        #expect(!resumed.checkpoint.completedSteps.contains(.challenge))
        #expect(resumed.checkpoint.counterCount == 0)
        let freshCheckpoint = resumed.checkpoint
        let resumedProbe = LearningQuestEngine(store: store, activeProfileID: { profile.id })
        resumedProbe.start(.numbers)
        var restored = resumedProbe.checkpoint; restored.updatedAt = freshCheckpoint.updatedAt
        #expect(restored == freshCheckpoint)
        #expect(resumedProbe.checkpoint.numberProbeIndex == 1)
        for _ in 0..<6 { resumedProbe.adjustCount(1) }
        resumedProbe.submit()
        let last = try #require(resumedProbe.checkpoint.attempts.last)
        #expect(last.outcome == .independentCorrect)
        #expect(last.appHintUsed == false)
        #expect(last.isFreshProbe == true)
        #expect(last.adultHelp == .unknown)
        #expect(resumedProbe.checkpoint.completedSteps.contains(.challenge))
    }
    @Test func rotationIsPersistentChildScopedAndRecycledProbesAreNotFresh() throws {
        let (profile, store, engine) = fixture()
        var variants: [String] = []
        for index in 0..<4 {
            engine.start(.numbers)
            variants.append(try #require(engine.checkpoint.numbersVariant).id)
            #expect(engine.checkpoint.numberProbeFreshness == [index < 3, index < 3])
            let before = engine.checkpoint
            engine.start(.numbers)
            #expect(engine.checkpoint.variantOrdinal == before.variantOrdinal)
            finishNumbers(engine)
        }
        #expect(variants == LearningNumbersVariant.reviewed.map(\.id) + [LearningNumbersVariant.reviewed[0].id])
        profile.id = "child-b"; engine.start(.numbers)
        #expect(engine.checkpoint.variantOrdinal == 0)
        #expect(engine.checkpoint.numberProbeFreshness == [true, true])
        store.reset(); engine.start(.numbers)
        #expect(engine.checkpoint.variantOrdinal == 0)
        profile.id = "child-a"; engine.start(.numbers)
        #expect(engine.checkpoint.variantOrdinal == 4)
        store.clearAllProfiles(); engine.start(.numbers)
        #expect(engine.checkpoint.variantOrdinal == 0)
    }
    @Test func legacyCheckpointRetainsSingleTaskAndSupportWhileUnknownBankIsRejected() throws {
        let (profile, store, engine) = fixture()
        var old = LearningQuestCheckpoint(profileID: profile.id, questID: .numbers, numbersVariant: nil, variantOrdinal: nil)
        old.step = .challenge; old.counterCount = 4
        old.attempts = [ItemAttempt(activityID: old.activityID, conceptID: "number-bond", entityID: "number-bond.challenge", propertyID: "transfer", stageID: "challenge", outcome: .help)]
        let encoded = try JSONEncoder().encode(old)
        let decoded = try JSONDecoder().decode(LearningQuestCheckpoint.self, from: encoded)
        store.save(decoded); engine.start(.numbers)
        #expect(engine.checkpoint.numbersVariant == nil)
        #expect(engine.checkpoint.numberProbeCount == 1)
        engine.adjustCount(1); engine.submit()
        #expect(engine.checkpoint.attempts.last?.outcome == .supportedCorrect)
        #expect(engine.checkpoint.attempts.last?.isFreshProbe == nil)
        engine.submit(); #expect(engine.checkpoint.step == .celebrate)
        var corrupted = LearningQuestCheckpoint(profileID: profile.id, questID: .numbers)
        corrupted.numbersVariant = .init(id: "unreviewed", initialPart: 99, probes: [])
        #expect(!store.save(corrupted))
        #expect(store.checkpoint(for: .numbers)?.numbersVariant == nil)
    }
    @Test func recognitionChoiceLabelsDoNotNameTheAnswer() {
        for quest in [LearningQuestID.shapes, .angles, .symmetry, .circuitSpark] {
            var state = LearningQuestCheckpoint(profileID: "child-a", questID: quest)
            state.step = .remember
            #expect(state.choices.allSatisfy { $0.label.hasPrefix("Picture ") })
        }
        var shape = LearningQuestCheckpoint(profileID: "child-a", questID: .shapes)
        shape.step = .challenge
        #expect(shape.choices.allSatisfy { $0.label.hasPrefix("Picture ") })
        #expect(LearningQuestID.allCases.allSatisfy { !$0.offscreenPrompt.isEmpty })
    }

    @Test func reviewedPilotVariantsCompleteAndResumeWithTheirFrozenArrangement() throws {
        for quest in [LearningQuestID.shapes, .waterCycle, .circuitSpark] {
            let (profile, store, engine) = fixture()
            for ordinal in 0..<3 {
                engine.start(quest)
                let variant = try #require(engine.checkpoint.pilotVariant)
                #expect(variant.isReviewed)
                #expect(engine.checkpoint.pilotProbeFresh == (ordinal < 2))
                switch quest {
                case .shapes:
                    for shape in ["circle", "square", "rectangle"] { engine.selectShape(shape) }
                    engine.turnShape(); engine.submit(); answer(engine, "triangle")
                    for point in [0, 1, 3] { engine.togglePoint(point) }
                    engine.submit(); engine.submit()
                case .waterCycle:
                    engine.warmWater(); engine.coolWater(); engine.submit()
                    answer(engine, "vapor"); answer(engine, "drops")
                case .circuitSpark:
                    engine.toggleSwitch(); engine.submit(); answer(engine, "closed")
                    engine.repairWire(); engine.submit(); engine.submit()
                default: break
                }
                let resumed = LearningQuestEngine(store: store, activeProfileID: { profile.id })
                resumed.start(quest)
                #expect(resumed.checkpoint.pilotVariant == variant)
                #expect(resumed.checkpoint.step == .challenge)
                switch quest {
                case .shapes: resumed.choose(variant.shapeKind!); resumed.submit()
                case .waterCycle: resumed.choose("outside"); resumed.submit()
                case .circuitSpark:
                    #expect(resumed.checkpoint.switchClosed == (variant.openSwitch != 1))
                    #expect(resumed.checkpoint.secondSwitchClosed == (variant.openSwitch != 2))
                    resumed.choose("off"); resumed.submit()
                    if !resumed.checkpoint.switchClosed { resumed.toggleSwitch() }
                    if !resumed.checkpoint.secondSwitchClosed { resumed.toggleSwitch(second: true) }
                    resumed.submit()
                default: break
                }
                #expect(resumed.checkpoint.accepted)
                let probes = resumed.checkpoint.attempts.filter { $0.stageID == "challenge" && $0.isFreshProbe == true }
                #expect(probes.count == (ordinal < 2 ? 1 : 0))
                #expect(probes.allSatisfy { $0.outcome == .independentCorrect && $0.adultHelp == .unknown })
                resumed.submit(); resumed.submit()
                #expect(store.checkpoint(for: quest) == nil)
            }
        }
    }
    @Test func parentTaskDenominatorsDeduplicateRetriesAndExcludeUnverifiedTransfers() {
        let when = Date(timeIntervalSince1970: 100)
        func event(_ entity: String, _ outcome: ItemAttemptOutcome, stage: String, fresh: Bool? = nil) -> ItemAttempt {
            ItemAttempt(activityID: "quest-numbers", conceptID: "number-bond", entityID: entity,
                propertyID: stage == "challenge" ? "transfer" : "practice", stageID: stage, outcome: outcome,
                occurredAt: when, profileID: "child-a", sessionID: "session-a", isFreshProbe: fresh, adultHelp: .unknown)
        }
        let fresh = event("fresh-two", .independentCorrect, stage: "challenge", fresh: true)
        let events = [event("practice", .help, stage: "remember"), event("practice", .supportedCorrect, stage: "remember"),
            event("practice", .supportedCorrect, stage: "play"), event("fresh-one", .incorrect, stage: "challenge", fresh: true),
            event("fresh-one", .supportedCorrect, stage: "challenge", fresh: true), fresh, fresh,
            event("legacy", .independentCorrect, stage: "challenge")]
        let summary = ParentLearningEvidenceSummary(attempts: events)
        #expect(summary.tasksAttempted == 4)
        #expect(summary.independent == 2)
        #expect(summary.supported == 2)
        #expect(summary.freshProbes == 2)
        #expect(summary.independentTransfers == 1)
        #expect(summary.unverifiedTransfers == 1)
        let rows = ParentLearningConceptEvidence.rows(from: events)
        #expect(rows.count == 1)
        #expect(rows.first?.title == "Parts and wholes")
        #expect(rows.first?.latestDate == when)
        #expect(rows.first?.summary == summary)
    }

}

@MainActor
struct QuestCheckpointStorageTests {
    private let key = "learningQuestCheckpoints.v1"
    private var historyKey: String { key + ".reviewedVariants.v1" }
    private func checkpoints() throws -> Data {
        let a = LearningQuestCheckpoint(profileID: "child-a", questID: .numbers)
        let b = LearningQuestCheckpoint(profileID: "child-b", questID: .numbers, numbersVariant: nil, variantOrdinal: nil)
        return try JSONEncoder().encode(["child-a": ["numbers": a], "child-b": ["numbers": b]])
    }
    private func history() -> Data {
        Data("{\"ordinals\":{\"child-a::numbers\":2,\"child-b::shapes\":5},\"seenNumberProbes\":{\"child-a\":[\"picnic-8-3\"],\"child-b\":[\"shape-door-rectangle\"]}}".utf8)
    }
    @Test func nonDataDefaultsAtEitherKeyCannotBeTreatedAsMissing() throws {
        for badKey in [key, historyKey] {
            let suite = "quest-checkpoint-test-\(UUID().uuidString)"
            let defaults = try #require(UserDefaults(suiteName: suite))
            defer { defaults.removePersistentDomain(forName: suite) }
            defaults.set("future typed value", forKey: badKey)
            let store = QuestCheckpointStore(storage: defaults, activeProfileID: { "child-a" })
            #expect(store.storageIssue != nil)
            #expect(!store.save(LearningQuestCheckpoint(profileID: "child-a", questID: .numbers)))
            #expect(!store.reset() && !store.markProbeSeen("new"))
            #expect(store.nextVariantOrdinal(for: .numbers) == nil && store.hasSeenProbe("old"))
            #expect(defaults.string(forKey: badKey) == "future typed value")
            store.clearAllProfiles()
            #expect(defaults.object(forKey: badKey) == nil && store.refreshStorage())
        }
    }
    @Test func unknownCheckpointForAnyChildPreservesBothKeysAndBlocksEveryMutation() throws {
        let valid = try checkpoints(), oldHistory = history()
        var future = try #require(JSONSerialization.jsonObject(with: valid) as? [String: [String: [String: Any]]])
        future["child-b"]?["numbers"]?["schemaVersion"] = 2
        let futureSchema = try JSONSerialization.data(withJSONObject: future)
        future["child-b"]?["numbers"]?["schemaVersion"] = 1
        future["child-b"]?["numbers"]?["futureProgress"] = "keep this"
        let extraField = try JSONSerialization.data(withJSONObject: future)
        future["child-b"]?["numbers"]?.removeValue(forKey: "futureProgress")
        future["child-b"]?["numbers"]?["profileID"] = "wrong-child"
        let wrongChild = try JSONSerialization.data(withJSONObject: future)
        for bytes in [Data("bad bytes".utf8), Data("{\"schemaVersion\":2,\"profiles\":{}}".utf8), futureSchema, extraField, wrongChild] {
            let defaults = QuestTestDefaults(); defaults.set(bytes, forKey: key); defaults.set(oldHistory, forKey: historyKey)
            let store = QuestCheckpointStore(storage: defaults, activeProfileID: { "child-a" })
            #expect(store.checkpointState == .unsupported)
            #expect(store.variantHistoryState == .healthy)
            #expect(store.storageIssue == .unsupportedCheckpoints)
            #expect(store.checkpoint(for: .numbers) == nil && store.mostRecent == nil)
            #expect(!store.save(LearningQuestCheckpoint(profileID: "child-a", questID: .numbers)))
            #expect(!store.remove(.numbers) && !store.reset())
            #expect(store.nextVariantOrdinal(for: .numbers) == nil)
            #expect(!store.markProbeSeen("new-probe"))
            #expect(!store.seedKnownProbeHistory())
            #expect(store.hasSeenProbe("never-seen"))
            #expect(defaults.data(forKey: key) == bytes)
            #expect(defaults.data(forKey: historyKey) == oldHistory)
        }
    }
    @Test func unknownVariantHistoryNeverRestartsFreshnessOrOverwritesAnotherChild() throws {
        let valid = try checkpoints()
        for bytes in [Data("broken history".utf8), Data("{\"version\":2,\"ordinals\":{},\"seenNumberProbes\":{}}".utf8),
            Data("{\"ordinals\":{\"child-b::numbers\":-1},\"seenNumberProbes\":{}}".utf8),
            Data("{\"ordinals\":{\"child-b::futureQuest\":4},\"seenNumberProbes\":{}}".utf8)] {
            let defaults = QuestTestDefaults(); defaults.set(valid, forKey: key); defaults.set(bytes, forKey: historyKey)
            let store = QuestCheckpointStore(storage: defaults, activeProfileID: { "child-a" })
            #expect(store.checkpointState == .healthy && store.variantHistoryState == .unsupported)
            #expect(store.storageIssue == .unsupportedVariantHistory)
            #expect(store.hasSeenProbe("picnic-8-3"))
            #expect(store.nextVariantOrdinal(for: .numbers) == nil)
            #expect(!store.markProbeSeen("new-item") && !store.reset() && !store.remove(.numbers))
            #expect(!store.seedKnownProbeHistory())
            #expect(!store.save(LearningQuestCheckpoint(profileID: "child-a", questID: .numbers)))
            #expect(defaults.data(forKey: historyKey) == bytes && defaults.data(forKey: key) == valid)
        }
    }
    @Test func legacyAndCurrentProfilesSurviveSelectedResetAndExplicitAllResetRecovers() throws {
        let defaults = QuestTestDefaults(); defaults.set(try checkpoints(), forKey: key); defaults.set(history(), forKey: historyKey)
        let profile = QuestTestProfile(), store = QuestCheckpointStore(storage: defaults, activeProfileID: { profile.id })
        #expect(store.storageIssue == nil && store.checkpointState == .healthy && store.variantHistoryState == .healthy)
        profile.id = "child-b"
        let legacy = try #require(store.checkpoint(for: .numbers))
        #expect(legacy.numbersVariant == nil && legacy.numberProbeCount == 1)
        profile.id = "child-a"
        #expect(store.reset())
        #expect(store.checkpoint(for: .numbers) == nil)
        #expect(store.nextVariantOrdinal(for: .numbers) == 0)
        profile.id = "child-b"
        #expect(store.checkpoint(for: .numbers) == legacy)
        #expect(store.nextVariantOrdinal(for: .shapes) == 5)
        #expect(store.hasSeenProbe("shape-door-rectangle"))
        let bytes = Data("unreadable".utf8); defaults.set(bytes, forKey: historyKey)
        #expect(!store.refreshStorage())
        // A failed selected-child reset cannot delete valid checkpoints or unknown history.
        let before = defaults.data(forKey: key)
        #expect(!store.reset())
        #expect(defaults.data(forKey: key) == before && defaults.data(forKey: historyKey) == bytes)
        store.clearAllProfiles()
        #expect(store.storageIssue == nil && store.checkpointState == .missing && store.variantHistoryState == .missing)
        #expect(defaults.data(forKey: key) == nil && defaults.data(forKey: historyKey) == nil)
        let engine = LearningQuestEngine(store: store, activeProfileID: { profile.id }); engine.start(.numbers)
        #expect(engine.pauseMessage == nil && engine.checkpoint.variantOrdinal == 0)
        #expect(engine.checkpoint.numberProbeFreshness == [true, true])
    }
    @Test func pausedEngineDoesNotCreateReplayMutateOrPublishEvidence() throws {
        for badKey in [key, historyKey] {
            let defaults = QuestTestDefaults(), bytes = Data("future data".utf8)
            defaults.set(bytes, forKey: badKey)
            let store = QuestCheckpointStore(storage: defaults, activeProfileID: { "child-a" })
            let engine = LearningQuestEngine(store: store, activeProfileID: { "child-a" }), before = engine.checkpoint
            var events = 0, stages = 0, completions = 0
            engine.onAttempt = { _, _ in events += 1 }; engine.onStageCompleted = { _, _ in stages += 1 }; engine.onCompleted = { _, _ in completions += 1 }
            engine.start(.shapes); engine.adjustCount(1); engine.selectShape("rectangle"); engine.turnShape(); engine.help(); engine.submit()
            #expect(engine.pauseMessage?.contains("preserved") == true && engine.requestedQuestID == .shapes)
            #expect(engine.checkpoint == before)
            #expect(events == 0 && stages == 0 && completions == 0)
            #expect(defaults.data(forKey: badKey) == bytes)
            store.clearAllProfiles(); engine.start(.numbers)
            #expect(engine.pauseMessage == nil)
            let running = engine.checkpoint
            defaults.set(bytes, forKey: historyKey)
            engine.adjustCount(1); engine.help(); engine.submit()
            #expect(engine.checkpoint == running && engine.pauseMessage != nil)
            #expect(events == 0 && stages == 0 && completions == 0)
        }
    }
    @Test func failedCheckpointWriteDoesNotPublishAnUnsavedAttempt() throws {
        let defaults = QuestTestDefaults(), store = QuestCheckpointStore(storage: QuestTestDefaults(), activeProfileID: { "child-a" })
        #expect(store.checkpointState == .missing && store.variantHistoryState == .missing)
        let actual = QuestCheckpointStore(storage: defaults, activeProfileID: { "child-a" })
        let engine = LearningQuestEngine(store: actual, activeProfileID: { "child-a" })
        engine.start(.numbers); engine.adjustCount(1)
        let before = engine.checkpoint, savedBytes = defaults.data(forKey: key)
        var events = 0, stages = 0
        engine.onAttempt = { _, _ in events += 1 }; engine.onStageCompleted = { _, _ in stages += 1 }
        defaults.rejectWrites = true; engine.submit()
        #expect(actual.storageIssue == .couldNotSave && engine.pauseMessage != nil)
        #expect(engine.checkpoint == before && events == 0 && stages == 0)
        #expect(defaults.data(forKey: key) == savedBytes)
    }
}

@MainActor
struct LegacyQuestProbeMigrationTests {
    @Test func legacyExposureMarkersSeedDefaultsWithoutCreatingScoredEvidence() {
        let markers = LearningQuestID.pilots.map { quest in
            ItemAttempt(activityID: quest.activityID, conceptID: quest.conceptID, entityID: quest.conceptID + ".challenge",
                stageID: "legacy", outcome: .exposure, profileID: "child-a")
        }
        let store = QuestCheckpointStore(storage: QuestTestDefaults(), activeProfileID: { "child-a" }, priorAttempts: { markers })
        let engine = LearningQuestEngine(store: store, activeProfileID: { "child-a" })
        var events = 0, stages = 0
        engine.onAttempt = { _, _ in events += 1 }; engine.onStageCompleted = { _, _ in stages += 1 }
        for quest in LearningQuestID.pilots {
            engine.start(quest)
            #expect(store.hasSeenProbe(LearningQuestProbeIdentity.legacyDefault(for: quest)!))
            #expect(engine.checkpoint.attempts.isEmpty && events == 0 && stages == 0)
            if quest == .numbers { #expect(engine.checkpoint.numberProbeFreshness == [false, true]) }
            else { #expect(engine.checkpoint.pilotProbeFresh == false) }
        }
        // Seeing the practice portion of a bank variant does not mean its fresh
        // challenge was seen. Its item identity must actually be a probe.
        let practice = ItemAttempt(activityID: "quest-shapes", conceptID: "shape", entityID: "shape.remember",
            propertyID: "practice", stageID: "remember", outcome: .independentCorrect, itemVariantID: "shape-sign-triangle")
        #expect(LearningQuestProbeIdentity.knownProbe(in: practice) == nil)
    }
    @Test func unknownPriorJournalPausesWithoutAllocatingOrPublishingFreshEvidence() throws {
        let defaults = QuestTestDefaults(), profile = QuestTestProfile()
        var journalReadable = false
        let key = "learningQuestCheckpoints.v1", historyKey = key + ".reviewedVariants.v1"
        let legacy = LearningQuestCheckpoint(profileID: profile.id, questID: .numbers, numbersVariant: nil, variantOrdinal: nil)
        let other = LearningQuestCheckpoint(profileID: "other-child", questID: .numbers, numbersVariant: nil, variantOrdinal: nil)
        let checkpoints = try JSONEncoder().encode([profile.id: ["numbers": legacy], "other-child": ["numbers": other]])
        let history = Data("{\"ordinals\":{},\"seenNumberProbes\":{}}".utf8)
        defaults.set(checkpoints, forKey: key); defaults.set(history, forKey: historyKey)
        let store = QuestCheckpointStore(storage: defaults, activeProfileID: { profile.id }, priorAttempts: { journalReadable ? [] : nil })
        let engine = LearningQuestEngine(store: store, activeProfileID: { profile.id }), before = engine.checkpoint
        var events = 0, stages = 0
        engine.onAttempt = { _, _ in events += 1 }; engine.onStageCompleted = { _, _ in stages += 1 }
        engine.start(.numbers); engine.adjustCount(1); engine.help(); engine.submit()
        #expect(store.storageIssue == .unsupportedPriorAttempts && engine.pauseMessage != nil)
        #expect(engine.checkpoint == before && events == 0 && stages == 0)
        #expect(defaults.data(forKey: key) == checkpoints && defaults.data(forKey: historyKey) == history)
        #expect(store.nextVariantOrdinal(for: .numbers) == nil && store.hasSeenProbe("picnic-8-3"))
        journalReadable = true
        #expect(store.reset()) // The selected-child external journal was cleared first.
        let remaining = try JSONDecoder().decode([String: [String: LearningQuestCheckpoint]].self, from: #require(defaults.data(forKey: key)))
        #expect(remaining["other-child"]?["numbers"] == other && remaining[profile.id] == nil)
        engine.start(.numbers)
        #expect(engine.pauseMessage == nil && engine.checkpoint.numberProbeFreshness == [true, true])
        journalReadable = false; store.clearAllProfiles(); engine.start(.numbers)
        #expect(engine.pauseMessage != nil) // Deleting checkpoints alone does not repair an unreadable external journal.
    }
    @Test func circuitVoiceOverStatesDescribeBothReviewedArrangementsWithoutAnswer() {
        for (ordinal, variant) in LearningPilotVariant.reviewed(for: .circuitSpark).enumerated() {
            var state = LearningQuestCheckpoint(profileID: "child-a", questID: .circuitSpark, numbersVariant: nil,
                variantOrdinal: ordinal, pilotVariant: variant, pilotProbeFresh: true)
            state.step = .challenge; state.wireConnected = true
            state.switchClosed = variant.openSwitch != 1; state.secondSwitchClosed = variant.openSwitch != 2
            let label = state.circuitAccessibilityDescription
            #expect(label.contains("Wire is connected."))
            #expect(label.contains("First, upper switch is \(state.switchClosed ? "closed" : "open")."))
            #expect(label.contains("Second, lower switch is \(state.secondSwitchClosed ? "closed" : "open")."))
            #expect(!label.contains("Bulb is off") && !label.contains("Bulb is lit"))
            #expect(label.contains("Predict what the bulb will do"))
            state.wireConnected = false
            #expect(state.circuitAccessibilityDescription.contains("Wire has a gap."))
            state.predictionMade = true
            #expect(state.circuitAccessibilityDescription.contains("Bulb is off."))
            state.wireConnected = true; state.switchClosed = true; state.secondSwitchClosed = true
            #expect(state.circuitAccessibilityDescription.contains("Bulb is lit."))
        }
    }
    @Test func legacyNumberAliasAndRestoredAttemptStayUnverifiedWhileNextSessionIsRepeated() throws {
        let defaults = QuestTestDefaults(), profile = QuestTestProfile()
        defaults.set(Data("{\"ordinals\":{},\"seenNumberProbes\":{\"child-a\":[\"legacy-picnic-8-3\"]}}".utf8), forKey: "learningQuestCheckpoints.v1.reviewedVariants.v1")
        let store = QuestCheckpointStore(storage: defaults, activeProfileID: { profile.id })
        #expect(store.hasSeenProbe("picnic-8-3") && store.hasSeenProbe("legacy-picnic-8-3"))
        var legacy = LearningQuestCheckpoint(profileID: profile.id, questID: .numbers, numbersVariant: nil, variantOrdinal: nil)
        legacy.step = .challenge; legacy.counterCount = 4
        let old = ItemAttempt(activityID: legacy.activityID, conceptID: "number-bond", entityID: "number-bond.challenge",
            propertyID: "transfer", stageID: "challenge", outcome: .help, response: "legacy-help")
        legacy.attempts = [old]
        #expect(store.save(legacy))
        let engine = LearningQuestEngine(store: store, activeProfileID: { profile.id })
        engine.start(.numbers)
        #expect(engine.checkpoint.attempts == [old] && engine.checkpoint.numberProbe.id == "legacy-picnic-8-3")
        #expect(engine.checkpoint.isFreshNumberProbe == nil)
        engine.adjustCount(1); engine.submit(); engine.submit(); engine.submit()
        engine.start(.numbers)
        #expect(engine.checkpoint.numbersVariant?.id == "numbers-v1-picnic")
        #expect(engine.checkpoint.numberProbeFreshness == [false, true])
        #expect(old.isFreshProbe == nil && old.itemVariantID == nil && old.adultHelp == nil)
    }
    @Test func completedLegacyLedgerSeedsOnlyKnownOwnedDefaultsWithoutRewritingAttempts() {
        let profile = QuestTestProfile(), defaults = QuestTestDefaults()
        let old = LearningQuestID.pilots.map { quest in
            ItemAttempt(activityID: quest.activityID, conceptID: quest.conceptID,
                entityID: quest.conceptID + ".challenge" + (quest == .circuitSpark ? ".prediction" : ""),
                propertyID: "transfer", stageID: "challenge", outcome: .independentCorrect,
                profileID: "child-a", sessionID: "old-\(quest.id)")
        }
        let attempts = old + [ItemAttempt(activityID: "quest-numbers", conceptID: "number-bond", entityID: "number-bond.challenge",
            propertyID: "transfer", stageID: "challenge", outcome: .incorrect, profileID: "other-child")]
        let store = QuestCheckpointStore(storage: defaults, activeProfileID: { profile.id }, priorAttempts: { attempts })
        let engine = LearningQuestEngine(store: store, activeProfileID: { profile.id })
        for quest in LearningQuestID.pilots {
            engine.start(quest)
            if quest == .numbers { #expect(engine.checkpoint.numberProbeFreshness == [false, true]) }
            else { #expect(engine.checkpoint.pilotProbeFresh == false) }
            #expect(store.hasSeenProbe(LearningQuestProbeIdentity.legacyDefault(for: quest)!))
        }
        #expect(attempts.prefix(4) == old[...])
        #expect(old.allSatisfy { $0.isFreshProbe == nil && $0.itemVariantID == nil })
        #expect(store.hasSeenProbe("coat-7-1") == false)
        #expect(store.hasSeenProbe("shape-sign-triangle") == false)
        #expect(store.hasSeenProbe("water-cold-bottle") == false)
        #expect(store.hasSeenProbe("circuit-first-switch-open") == false)
        profile.id = "unseen-child"; engine.start(.numbers)
        #expect(engine.checkpoint.numberProbeFreshness == [true, true])
    }
    @Test func enteringAndCompletingLegacyDefaultProbeSeedsLaterReviewedSessions() throws {
        for quest in LearningQuestID.pilots {
            let profile = QuestTestProfile(), store = QuestCheckpointStore(storage: QuestTestDefaults(), activeProfileID: { "child-a" })
            var legacy = LearningQuestCheckpoint(profileID: profile.id, questID: quest, numbersVariant: nil, variantOrdinal: nil)
            legacy.step = .play
            legacy.counterCount = 0
            if quest == .waterCycle { legacy.waterState = 1 }
            if quest == .circuitSpark { legacy.wireConnected = false; legacy.switchClosed = true }
            #expect(store.save(legacy))
            let engine = LearningQuestEngine(store: store, activeProfileID: { profile.id })
            engine.start(quest)
            switch quest {
            case .numbers: engine.adjustCount(4)
            case .shapes: for point in [0, 1, 3] { engine.togglePoint(point) }
            case .waterCycle: engine.choose("drops")
            case .circuitSpark: engine.repairWire()
            default: break
            }
            engine.submit(); engine.submit()
            #expect(engine.checkpoint.step == .challenge)
            #expect(store.hasSeenProbe(LearningQuestProbeIdentity.legacyDefault(for: quest)!))
            switch quest {
            case .numbers: engine.adjustCount(5); engine.submit()
            case .shapes: engine.choose("rectangle"); engine.submit()
            case .waterCycle: engine.choose("outside"); engine.submit()
            case .circuitSpark: engine.choose("off"); engine.submit(); engine.toggleSwitch(second: true); engine.submit()
            default: break
            }
            #expect(engine.checkpoint.accepted)
            let legacyAttempts = engine.checkpoint.attempts.filter { $0.stageID == "challenge" }
            #expect(legacyAttempts.allSatisfy { $0.isFreshProbe == nil })
            engine.submit(); engine.submit()
            #expect(store.checkpoint(for: quest) == nil)
            engine.start(quest)
            if quest == .numbers { #expect(engine.checkpoint.numberProbeFreshness == [false, true]) }
            else { #expect(engine.checkpoint.pilotProbeFresh == false) }
            #expect(engine.pauseMessage == nil)
        }
    }
}
