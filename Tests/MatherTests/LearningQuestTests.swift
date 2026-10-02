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
        store.save(corrupted)
        #expect(store.checkpoint(for: .numbers) == nil)
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
