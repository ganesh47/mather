import XCTest
@testable import Mather

final class LabModelsTests: XCTestCase {
    func testDefaultExplorerLanesExposeCapabilityShell() throws {
        let lanes = CapabilityLane.defaultExplorerLanes
        let laneIDs = lanes.map(\.id)

        XCTAssertEqual(
            laneIDs,
            [.numbers, .geometry, .physics, .mapWorld, .discoveryCards, .chemistry, .electronics]
        )

        for required in [CapabilityLaneID.numbers, .geometry, .physics, .mapWorld] {
            let lane = try XCTUnwrap(lanes.first { $0.id == required })
            XCTAssertFalse(lane.activities.isEmpty, "\(lane.title) should launch at least one pilot activity")
        }
    }

    func testLabSubjectStreamsExposeFocusedSubjectPickerSeparateFromGames() throws {
        let streams = CapabilityLane.labSubjectStreams

        XCTAssertEqual(streams.map(\.id), [.numbers, .geometry, .physics, .mapWorld, .discoveryCards, .chemistry, .electronics])
        XCTAssertEqual(streams.map(\.subjectStreamShortLabel), ["Numbers", "Geometry", "Physics", "Geography/Maps", "Discovery", "Chemistry", "Electronics"])
        XCTAssertEqual(CapabilityLane.subjectStreamSummary, "Numbers · Geometry · Physics · Geography/Maps · Discovery · Chemistry · Electronics")
        XCTAssertTrue(streams.allSatisfy(\.isLabSubjectStream))
        XCTAssertTrue(CapabilityLane.defaultExplorerLanes.first { $0.id == .discoveryCards }?.isLabSubjectStream ?? false)
        XCTAssertTrue(ExplorerGameRegistry.directLaunchEntries.contains { $0.activity.id == .memoryMatch })
    }

    func testMemoryMatchIsEmbeddedInDiscoveryCardsInsteadOfTopLevelLane() throws {
        let lanes = CapabilityLane.defaultExplorerLanes
        let discovery = try XCTUnwrap(lanes.first { $0.id == .discoveryCards })

        XCTAssertTrue(discovery.activities.contains { $0.id == .memoryMatch })
        XCTAssertFalse(CapabilityLaneID.allCases.contains { $0.title == "Memory Match" })
    }


    func testCapabilityLanesExposeAgeBandEntryPoints() throws {
        for lane in CapabilityLane.defaultExplorerLanes {
            XCTAssertGreaterThanOrEqual(lane.ageEntries.count, 4, "\(lane.title) should define multiple age entry points")
            XCTAssertFalse(lane.ageEntryPreview.isEmpty)
        }

        let physics = try XCTUnwrap(CapabilityLane.defaultExplorerLanes.first { $0.id == .physics })
        XCTAssertTrue(physics.ageEntries.contains { $0.ageBand == .toddler })
        XCTAssertTrue(physics.ageEntryPreview.contains("Ages 2–3"))
    }

    func testCapabilityLanesExposeChildChoiceModeCards() throws {
        let numbers = try XCTUnwrap(CapabilityLane.defaultExplorerLanes.first { $0.id == .numbers })

        XCTAssertEqual(numbers.modeChoiceCards.map(\.mode), numbers.modes)
        XCTAssertTrue(numbers.modeChoicePreviewLabel.contains("Learn: calm build"))
        XCTAssertTrue(numbers.modeChoiceCards.contains { $0.mode == .timed && $0.policy.usesTimer })
    }

    func testCapabilityLanesIncludeChoiceBasedPlayModes() {
        let modesByLane = Dictionary(
            uniqueKeysWithValues: CapabilityLane.defaultExplorerLanes.map { ($0.id, Set($0.modes)) }
        )

        XCTAssertTrue(modesByLane[.numbers, default: []].contains(.timed))
        XCTAssertTrue(modesByLane[.geometry, default: []].contains(.explore))
        XCTAssertTrue(modesByLane[.physics, default: []].contains(.review))
        XCTAssertTrue(modesByLane[.mapWorld, default: []].contains(.challenge))
        XCTAssertTrue(modesByLane[.discoveryCards, default: []].contains(.review))
    }

    func testLaneRecallReadinessSummariesExposeCardCountsAndConcepts() throws {
        let numbers = try XCTUnwrap(CapabilityLane.defaultExplorerLanes.first { $0.id == .numbers })

        XCTAssertEqual(numbers.starterMixMatchCount, 8)
        XCTAssertEqual(numbers.recallReadinessLabel, "1 recall card + 8 Mix-Match ready")
        XCTAssertEqual(numbers.recallEntries.count, 1)
        XCTAssertTrue(numbers.starterMixMatchConceptPreview.contains("number-bond"))
    }

    func testRootLaneCardPresentationStaysSparseAndOpensDetailScreen() throws {
        let numbers = try XCTUnwrap(CapabilityLane.defaultExplorerLanes.first { $0.id == .numbers })
        let presentation = LabLaneCardPresentation(
            lane: numbers,
            progress: numbers.emptyProgress
        )

        XCTAssertEqual(presentation.title, "Numbers & Arithmetic")
        XCTAssertEqual(presentation.openAffordanceLabel, "Open")
        XCTAssertEqual(
            presentation.sections,
            [.visualSummary]
        )
        XCTAssertFalse(presentation.showsDetails)
        XCTAssertFalse(presentation.sections.contains(.modes))
        XCTAssertFalse(presentation.sections.contains(.ageEntries))
        XCTAssertFalse(presentation.sections.contains(.recall))
        XCTAssertFalse(presentation.sections.contains(.activities))
        XCTAssertTrue(presentation.accessibilityHint.contains("Opens Numbers & Arithmetic"))
        XCTAssertFalse(presentation.sections.contains(.promise))
        XCTAssertFalse(presentation.sections.contains(.progressStatus))
    }

    func testLaneDetailPresentationRestoresDetailsWithoutDroppingLaunches() throws {
        let numbers = try XCTUnwrap(CapabilityLane.defaultExplorerLanes.first { $0.id == .numbers })
        let presentation = LabLaneDetailPresentation(lane: numbers)

        XCTAssertEqual(presentation.activityCountLabel, "3 games ready")
        XCTAssertEqual(presentation.sections, [.visualSummary, .activities, .progressStatus])
        XCTAssertFalse(presentation.sections.contains(.modes))
        XCTAssertFalse(presentation.sections.contains(.playStyles))
        XCTAssertFalse(presentation.sections.contains(.ageEntries))
        XCTAssertFalse(presentation.sections.contains(.recall))
        XCTAssertTrue(presentation.sections.contains(.activities))
        XCTAssertEqual(numbers.activities.map(\.id), [.sumSprint, .rectangleFactory, .factoryCards])
    }

    func testPhysicsLaneAddsSoundLabAsThirdReadyActivity() throws {
        let physics = try XCTUnwrap(CapabilityLane.defaultExplorerLanes.first { $0.id == .physics })

        XCTAssertEqual(physics.activities.map(\.id), [.gravityArtist, .waterCycle, .soundVolume])
        XCTAssertEqual(LabLaneDetailPresentation(lane: physics).activityCountLabel, "3 games ready")
        XCTAssertTrue(physics.starterMixMatchCards.contains { $0.concept == "sound" && $0.prompt == "whisper" && $0.match == "quiet" })
        XCTAssertTrue(physics.starterMixMatchCards.contains { $0.concept == "hearing-safety" && $0.prompt == "siren" && $0.match == "protect ears" })
    }

    func testLabLaneRouteCarriesSelectedLaneWithoutChangingGameRoutes() throws {
        XCTAssertEqual(AppRoute.lab, AppRoute.lab)
        XCTAssertEqual(AppRoute.labGames, AppRoute.labGames)
        XCTAssertEqual(AppRoute.labLane(.geometry), AppRoute.labLane(.geometry))
        XCTAssertNotEqual(AppRoute.labLane(.geometry), AppRoute.labLane(.numbers))
        XCTAssertEqual(LabActivityID.sumSprint.appRoute, .sumSprint)
        XCTAssertEqual(LabActivityID.shapeGeometry.appRoute, .shapeGeometry)
        XCTAssertEqual(LabActivityID.waterCycle.appRoute, .gameplayThread(.waterCycle))
        XCTAssertEqual(LabActivityID.soundVolume.appRoute, .soundVolume)
        XCTAssertEqual(LabActivityID.memoryMatch.appRoute, .memory)
    }

    func testExplorerPathSplitKeepsLabsAndGamesAsTopLevelChoices() {
        XCTAssertEqual(ExplorerPathID.allCases, [.labs, .games])
        XCTAssertEqual(ExplorerPathPresentation.all.map(\.id), [.labs, .games])

        let labs = ExplorerPathPresentation.all[0]
        let games = ExplorerPathPresentation.all[1]

        XCTAssertEqual(labs.title, "Labs")
        XCTAssertTrue(labs.subtitle.contains("Pick a subject stream"))
        XCTAssertEqual(labs.callToAction, "Choose a subject")
        XCTAssertEqual(labs.symbolName, "sparkles.rectangle.stack.fill")
        XCTAssertTrue(labs.artworkAccessibilityLabel.contains("Labs"))

        XCTAssertEqual(games.title, "Games")
        XCTAssertTrue(games.subtitle.contains("Jump straight into playable games"))
        XCTAssertTrue(games.subtitle.contains("no lab progress changes"))
        XCTAssertEqual(games.callToAction, "Play now")
        XCTAssertEqual(games.symbolName, "gamecontroller.fill")
        XCTAssertTrue(games.artworkAccessibilityLabel.contains("Games"))
    }

    func testGuidedStageArtworkMetadataAvoidsEmbeddedTextDependency() {
        XCTAssertEqual(GuidedLabStage.allCases.map(\.symbolName), [
            "cube.transparent.fill",
            "rectangle.on.rectangle.angled",
            "gamecontroller.fill",
            "flame.fill",
            "star.circle.fill",
        ])
        XCTAssertTrue(GuidedLabStage.allCases.allSatisfy { !$0.artMotif.isEmpty })
        XCTAssertTrue(GuidedLabStage.allCases.allSatisfy { $0.artworkAccessibilityLabel.contains($0.rawValue) })
    }

    func testPhaseOneGuidedLabPathShowsStagedLearningLoop() throws {
        let path = try XCTUnwrap(GuidedLabPath.phaseOne.first)

        XCTAssertEqual(path.laneID, .numbers)
        XCTAssertEqual(path.title, "Numbers Path")
        XCTAssertEqual(path.stages, [.learn, .remember, .play, .blast, .score])
        XCTAssertEqual(path.stages.map(\.rawValue).joined(separator: " → "), "Learn → Remember → Play → Blast → Score")
        XCTAssertEqual(GuidedLabStage.allCases.map(\.microcopy), [
            "See the idea",
            "Recall cards",
            "Practice calmly",
            "Fast round",
            "Celebrate progress",
        ])
    }


    func testNumbersLabNumberBondsPlanDefinesReusableStageOrder() throws {
        let plan = LabConceptSessionPlan.numbersNumberBondsTo10

        XCTAssertEqual(plan.id, "numbers-number-bonds-to-10")
        XCTAssertEqual(plan.laneID, .numbers)
        XCTAssertEqual(plan.title, "Number Bonds to 10")
        XCTAssertEqual(plan.stageOrder, [.learn, .remember, .play, .blast, .score])
        XCTAssertEqual(plan.pathLabel, "Learn → Remember → Play → Blast → Score")
        XCTAssertEqual(plan.startRoute, .sessionConfig)
        XCTAssertEqual(plan.startAffordanceLabel, "Start")
        XCTAssertEqual(plan.continueAffordanceLabel, "Continue")
    }

    func testNumbersLabStageTimerPoliciesStayChildSafe() throws {
        let stages = Dictionary(
            uniqueKeysWithValues: LabConceptSessionPlan.numbersNumberBondsTo10.stages.map { ($0.stage, $0) }
        )

        let learn = try XCTUnwrap(stages[.learn])
        XCTAssertEqual(learn.timerPolicy.pressure, .trackedOnly)
        XCTAssertTrue(learn.timerPolicy.tracksElapsedTime)
        XCTAssertFalse(learn.timerPolicy.showsCountdown)
        XCTAssertFalse(learn.timerPolicy.isPunitive)
        XCTAssertTrue(learn.timerPolicy.childCopy.contains("No rush"))

        let remember = try XCTUnwrap(stages[.remember])
        XCTAssertEqual(remember.timerPolicy.pressure, .none)
        XCTAssertTrue(remember.timerPolicy.tracksElapsedTime)
        XCTAssertFalse(remember.timerPolicy.showsCountdown)
        XCTAssertFalse(remember.timerPolicy.isPunitive)
        XCTAssertTrue(remember.parentCopy.contains("no punitive countdown"))

        let blast = try XCTUnwrap(stages[.blast])
        XCTAssertEqual(blast.timerPolicy.pressure, .readinessGated)
        XCTAssertFalse(blast.timerPolicy.showsCountdown)
        XCTAssertFalse(blast.timerPolicy.isPunitive)
        XCTAssertTrue(blast.childCopy.contains("when you’re ready"))
        XCTAssertTrue(blast.parentCopy.contains("readiness gated"))
    }

    func testNumbersPathCarriesNumberBondsPlanPresentationCopy() throws {
        let path = try XCTUnwrap(GuidedLabPath.phaseOne.first { $0.laneID == .numbers })
        let plan = try XCTUnwrap(path.primaryPlan)

        XCTAssertEqual(path.title, "Numbers Path")
        XCTAssertTrue(path.subtitle.contains("Number Bonds to 10"))
        XCTAssertEqual(path.stages, plan.stageOrder)
        XCTAssertEqual(plan.subtitle, "Build pairs that make ten, remember friendly facts, then celebrate with Bond Blast.")
        XCTAssertEqual(plan.estimatedLength, "8–10 min")
        XCTAssertEqual(plan.masteryStateLabel, "Recommended first")
        XCTAssertEqual(plan.recommendedNextActivity, "Make & Break warm-up")
        XCTAssertTrue(plan.stages.allSatisfy { !$0.accessibilityLabel.isEmpty })
        XCTAssertEqual(plan.stages.map(\.actionLabel), ["Start", "Continue", "Continue", "Continue", "Preview"])
    }

    func testNumbersLabPlanDoesNotChangeDirectGamesRegistry() {
        let entries = ExplorerGameRegistry.directLaunchEntries
        let entryIDs = entries.map(\.activity.id)

        XCTAssertEqual(entryIDs, CapabilityLane.defaultExplorerLanes.flatMap { $0.activities.map(\.id) })
        XCTAssertEqual(entries.first { $0.activity.id == .sumSprint }?.directRoute, .sumSprint)
        XCTAssertEqual(entries.first { $0.activity.id == .rectangleFactory }?.directRoute, .rectangleFactory)
        XCTAssertEqual(entries.first { $0.activity.id == .factoryCards }?.directRoute, .factoryCards)
    }


    func testRoundTimerFoundationTracksTimeWithoutDefaultPressure() {
        let startedAt = Date(timeIntervalSince1970: 100)
        let now = Date(timeIntervalSince1970: 175)
        let gentleTimer = RoundTimerSnapshot(startedAt: startedAt, now: now, limitSeconds: 90, timerPolicy: .calmNoCountdown)

        XCTAssertEqual(gentleTimer.elapsedSeconds, 75)
        XCTAssertNil(gentleTimer.remainingSeconds)
        XCTAssertEqual(gentleTimer.childFacingLabel, "Time spent: 1:15")

        let blastTimer = RoundTimerSnapshot(startedAt: startedAt, now: now, limitSeconds: 90, timerPolicy: .readinessGatedBlast)
        XCTAssertNil(blastTimer.remainingSeconds)
        XCTAssertEqual(blastTimer.childFacingLabel, "Time spent: 1:15")
    }

    func testSessionScoreSummaryKeepsChildCopyEncouragingAndParentDetailSpecific() {
        let score = LabSessionScoreSummary(
            conceptTitle: "number bonds",
            stageDurations: [.learn: 72, .remember: 45, .play: 90, .blast: 30, .score: 15],
            accuracy: 0.82,
            streak: 4,
            weakAreas: ["6 + 4", "7 + 3"],
            nextRecommendation: "Review number bonds tomorrow"
        )

        XCTAssertEqual(score.totalSeconds, 252)
        XCTAssertEqual(score.childCelebrationLine, "Session Complete 🎉 2 tricky ideas will come back soon.")
        XCTAssertTrue(score.parentDetailLines.contains("Total time: 4:12"))
        XCTAssertTrue(score.parentDetailLines.contains("Accuracy: 82%"))
        XCTAssertTrue(score.parentDetailLines.contains("Remember: 0:45"))
        XCTAssertTrue(score.parentDetailLines.contains("Coming back soon: 6 + 4, 7 + 3"))
    }

    func testExplorerGamesRegistryDirectlyLaunchesEveryCurrentExplorerActivity() {
        let expectedEntries = CapabilityLane.defaultExplorerLanes.flatMap { lane in
            lane.activities.map { (laneID: lane.id, activityID: $0.id, route: $0.id.appRoute) }
        }
        let entries = ExplorerGameRegistry.directLaunchEntries

        XCTAssertEqual(entries.map(\.laneID), expectedEntries.map { $0.laneID })
        XCTAssertEqual(entries.map { $0.activity.id }, expectedEntries.map { $0.activityID })
        XCTAssertEqual(entries.map(\.directRoute), expectedEntries.map { $0.route })
        XCTAssertEqual(Set(entries.map(\.id)).count, entries.count)
        XCTAssertTrue(entries.contains { $0.activity.id == .sumSprint && $0.directRoute == .sumSprint })
        XCTAssertTrue(entries.contains { $0.activity.id == .waterCycle && $0.directRoute == .gameplayThread(.waterCycle) })
        XCTAssertTrue(entries.contains { $0.activity.id == .memoryMatch && $0.directRoute == .memory })
    }


    func testRememberStageDeckReusesNumberBondMixMatchAndKeepsCalmPolicy() throws {
        let deck = LabRememberStageDeck.numbersNumberBondsTo10

        XCTAssertEqual(deck.id, .numbersNumberBondsTo10)
        XCTAssertEqual(deck.planID, LabConceptSessionPlan.numbersNumberBondsTo10.id)
        XCTAssertEqual(deck.stage, .remember)
        XCTAssertEqual(deck.laneID, .numbers)
        XCTAssertFalse(deck.hasPunitiveCountdown)
        XCTAssertEqual(deck.timerPolicy, .calmNoCountdown)
        XCTAssertGreaterThanOrEqual(deck.cards.count, 10)
        XCTAssertTrue(deck.cards.contains { $0.id == "numbers-number-bond-6 + 4" || ($0.prompt == "6 + 4" && $0.answer == "10") })
        XCTAssertTrue(deck.cards.contains { $0.prompt == "7 + 3" && $0.answer == "10" })
        XCTAssertTrue(deck.cards.allSatisfy { $0.concept == "number-bond" && $0.laneID == .numbers })
    }

    func testRememberStageExecutionTracksRecallWithoutCountdownPressure() throws {
        let deck = LabRememberStageDeck.numbersNumberBondsTo10
        var execution = LabRememberStageExecution(deck: deck)
        let first = try XCTUnwrap(execution.currentCard)

        XCTAssertEqual(execution.progressLabel, "1 / \(deck.cards.count)")
        XCTAssertFalse(execution.usesPunitiveCountdown)
        XCTAssertFalse(execution.submit(answer: "9"))
        XCTAssertEqual(execution.reviewedCardIDs, [first.id])
        XCTAssertFalse(execution.correctCardIDs.contains(first.id))
        XCTAssertTrue(execution.submit(answer: first.answer))
        XCTAssertTrue(execution.correctCardIDs.contains(first.id))

        execution.advance()

        XCTAssertEqual(execution.progressLabel, "2 / \(deck.cards.count)")
    }

    func testNumbersRememberStageRoutesToReusableRememberDeck() throws {
        let plan = LabConceptSessionPlan.numbersNumberBondsTo10
        let remember = try XCTUnwrap(plan.stages.first { $0.stage == .remember })

        XCTAssertEqual(remember.route, .labRememberStage(.numbersNumberBondsTo10))
        XCTAssertEqual(LabRememberStageDeck.deck(for: .numbersNumberBondsTo10).route, remember.route)
        XCTAssertFalse(remember.timerPolicy.showsCountdown)
        XCTAssertFalse(remember.timerPolicy.isPunitive)
    }


    func testLabConceptProgressCreationAndResumeCopy() throws {
        let plan = LabConceptSessionPlan.numbersNumberBondsTo10
        let startedAt = Date(timeIntervalSince1970: 1_000)
        let progress = LabConceptSessionProgress(plan: plan, startedAt: startedAt)

        XCTAssertEqual(progress.conceptPlanID, plan.id)
        XCTAssertEqual(progress.currentStage, .learn)
        XCTAssertEqual(progress.completedStages, [])
        XCTAssertEqual(progress.lastActivityAt, startedAt)
        XCTAssertEqual(progress.resumeCopy, "Continue: Learn")
        XCTAssertEqual(progress.currentStagePlan(in: plan)?.route, .sessionConfig)
    }

    func testLabConceptProgressNextStageCalculationAndCompletedOrdering() {
        let plan = LabConceptSessionPlan.numbersNumberBondsTo10
        var progress = LabConceptSessionProgress(
            conceptPlanID: plan.id,
            currentStage: .learn,
            completedStages: [.play, .learn, .play],
            lastActivityAt: Date(timeIntervalSince1970: 1_000)
        )

        progress.markCompleted(.remember, in: plan, at: Date(timeIntervalSince1970: 1_100))

        XCTAssertEqual(progress.completedStages, [.learn, .remember, .play])
        XCTAssertEqual(progress.nextIncompleteStage(in: plan), .blast)
        XCTAssertEqual(progress.currentStage, .blast)
        XCTAssertEqual(progress.resumeCopy, "Continue: Blast next")
    }

    func testLabConceptProgressStorePersistsGuidedLaunchWithoutFakingMastery() throws {
        let storage = InMemoryLabConceptSessionProgressDefaults()
        let store = LabConceptSessionProgressStore(
            storage: storage,
            storageKey: "test.lab-progress",
            activeProfileIdProvider: { "profile-a" }
        )
        let plan = LabConceptSessionPlan.numbersNumberBondsTo10
        let launchedAt = Date(timeIntervalSince1970: 2_000)

        let progress = store.beginGuidedStage(.learn, in: plan, at: launchedAt)
        let reloaded = LabConceptSessionProgressStore(
            storage: storage,
            storageKey: "test.lab-progress",
            activeProfileIdProvider: { "profile-a" }
        )

        XCTAssertEqual(progress.currentStage, .learn)
        XCTAssertEqual(progress.completedStages, [])
        XCTAssertEqual(progress.lastActivityAt, launchedAt)
        XCTAssertEqual(reloaded.resumeLabel(for: plan), "Continue: Learn")
        XCTAssertEqual(reloaded.progress(for: plan)?.completedStages, [])
    }

    func testLabConceptProgressStoreScopesByProfile() throws {
        let storage = InMemoryLabConceptSessionProgressDefaults()
        let plan = LabConceptSessionPlan.numbersNumberBondsTo10
        let first = LabConceptSessionProgressStore(
            storage: storage,
            storageKey: "test.lab-progress.profiles",
            activeProfileIdProvider: { "profile-a" }
        )
        let second = LabConceptSessionProgressStore(
            storage: storage,
            storageKey: "test.lab-progress.profiles",
            activeProfileIdProvider: { "profile-b" }
        )

        first.beginGuidedStage(.remember, in: plan, at: Date(timeIntervalSince1970: 3_000))

        XCTAssertEqual(first.currentStage(for: plan), .remember)
        XCTAssertNil(second.progress(for: plan))
        XCTAssertEqual(second.resumeLabel(for: plan), "Start")
    }

    func testRememberStageDeckUsesNumberBondRouteWithoutCountdown() throws {
        let plan = LabConceptSessionPlan.numbersNumberBondsTo10
        let rememberStage = try XCTUnwrap(plan.stages.first { $0.stage == .remember })
        let deck = LabRememberStageDeck.numbersNumberBondsTo10

        let blastStage = try XCTUnwrap(plan.stages.first { $0.stage == .blast })

        XCTAssertEqual(rememberStage.route, .labRememberStage(.numbersNumberBondsTo10))
        XCTAssertEqual(blastStage.route, .session)
        XCTAssertEqual(rememberStage.timerPolicy, .calmNoCountdown)
        XCTAssertFalse(rememberStage.timerPolicy.showsCountdown)
        XCTAssertFalse(rememberStage.timerPolicy.isPunitive)
        XCTAssertEqual(deck.route, .labRememberStage(.numbersNumberBondsTo10))
        XCTAssertTrue(deck.cards.contains { $0.prompt == "6 + 4" && $0.answer == "10" })
        XCTAssertTrue(deck.cards.contains { $0.prompt == "7 + 3" && $0.answer == "10" })
    }



    func testLabBlastStageLaunchesBondBlastFinaleRoute() throws {
        let plan = LabConceptSessionPlan.numbersNumberBondsTo10
        let blast = try XCTUnwrap(plan.stages.first { $0.stage == .blast })

        XCTAssertEqual(blast.title, "Bond Blast")
        XCTAssertEqual(blast.route, .session)
        XCTAssertEqual(blast.timerPolicy, .readinessGatedBlast)
        XCTAssertFalse(blast.timerPolicy.showsCountdown)
        XCTAssertFalse(blast.timerPolicy.isPunitive)
    }

    func testLabLaunchedBlastCompletionAdvancesToScoreWithSummary() throws {
        let storage = InMemoryLabConceptSessionProgressDefaults()
        let store = LabConceptSessionProgressStore(
            storage: storage,
            storageKey: "test.lab-blast-complete",
            activeProfileIdProvider: { "profile-a" }
        )
        let plan = LabConceptSessionPlan.numbersNumberBondsTo10
        let launchedAt = Date(timeIntervalSince1970: 5_000)
        let completedAt = Date(timeIntervalSince1970: 5_045)
        let context = LabGameplayCompletionContext(plan: plan, stage: .blast)
        let summary = LabStageTimingScoreSummary(durationSeconds: 45)

        _ = store.beginGuidedStage(.blast, in: plan, at: launchedAt)
        let progress = try XCTUnwrap(store.markLabLaunchedGameplayCompleted(context, at: completedAt, summary: summary))

        XCTAssertEqual(progress.completedStages, [.blast])
        XCTAssertEqual(progress.currentStage, .score)
        XCTAssertEqual(progress.lastActivityAt, completedAt)
        XCTAssertEqual(progress.stageSummaries[.blast], summary)
    }

    func testLabLaunchedGameplayCompletionAdvancesPlayToBlastWithSummary() throws {
        let storage = InMemoryLabConceptSessionProgressDefaults()
        let store = LabConceptSessionProgressStore(
            storage: storage,
            storageKey: "test.lab-gameplay-complete",
            activeProfileIdProvider: { "profile-a" }
        )
        let plan = LabConceptSessionPlan.numbersNumberBondsTo10
        let launchedAt = Date(timeIntervalSince1970: 4_000)
        let completedAt = Date(timeIntervalSince1970: 4_120)
        let context = LabGameplayCompletionContext(plan: plan, stage: .play)
        let summary = LabStageTimingScoreSummary(durationSeconds: 120)

        _ = store.beginGuidedStage(.play, in: plan, at: launchedAt)
        let progress = try XCTUnwrap(store.markLabLaunchedGameplayCompleted(context, at: completedAt, summary: summary))

        XCTAssertEqual(progress.completedStages, [.play])
        XCTAssertEqual(progress.currentStage, .blast)
        XCTAssertEqual(progress.lastActivityAt, completedAt)
        XCTAssertEqual(progress.stageSummaries[.play], summary)
    }

    func testLabLaunchedGameplayCompletionIsProfileScoped() throws {
        let storage = InMemoryLabConceptSessionProgressDefaults()
        let plan = LabConceptSessionPlan.numbersNumberBondsTo10
        let context = LabGameplayCompletionContext(plan: plan, stage: .play)
        let first = LabConceptSessionProgressStore(
            storage: storage,
            storageKey: "test.lab-gameplay-profile",
            activeProfileIdProvider: { "profile-a" }
        )
        let second = LabConceptSessionProgressStore(
            storage: storage,
            storageKey: "test.lab-gameplay-profile",
            activeProfileIdProvider: { "profile-b" }
        )

        _ = first.beginGuidedStage(.play, in: plan)
        _ = first.markLabLaunchedGameplayCompleted(context)

        XCTAssertEqual(first.progress(for: plan)?.completedStages, [.play])
        XCTAssertNil(second.progress(for: plan))
    }

    func testDirectGameplayCompletionWithoutLabContextDoesNotMutateLabProgress() throws {
        let storage = InMemoryLabConceptSessionProgressDefaults()
        let store = LabConceptSessionProgressStore(storage: storage, storageKey: "test.direct-gameplay-complete")
        let plan = LabConceptSessionPlan.numbersNumberBondsTo10

        XCTAssertNil(store.markLabLaunchedGameplayCompleted(nil))
        XCTAssertNil(store.progress(for: plan))
    }

    func testNonPlayLabCompletionContextDoesNotAdvanceGameplayProgress() throws {
        let storage = InMemoryLabConceptSessionProgressDefaults()
        let store = LabConceptSessionProgressStore(storage: storage, storageKey: "test.non-play-context")
        let plan = LabConceptSessionPlan.numbersNumberBondsTo10
        _ = store.beginGuidedStage(.remember, in: plan)

        XCTAssertNil(store.markLabLaunchedGameplayCompleted(LabGameplayCompletionContext(plan: plan, stage: .remember)))
        XCTAssertEqual(store.currentStage(for: plan), .remember)
        XCTAssertEqual(store.progress(for: plan)?.completedStages, [])
    }

    func testDirectGamesLaunchDoesNotMarkBlastOrScoreComplete() throws {
        let storage = InMemoryLabConceptSessionProgressDefaults()
        let store = LabConceptSessionProgressStore(storage: storage, storageKey: "test.direct-games")
        let plan = LabConceptSessionPlan.numbersNumberBondsTo10
        let directSumSprint = try XCTUnwrap(ExplorerGameRegistry.directLaunchEntries.first { $0.activity.id == .sumSprint })

        XCTAssertEqual(directSumSprint.directRoute, .sumSprint)
        XCTAssertNil(store.progress(for: plan))
        XCTAssertFalse(store.progress(for: plan)?.completedStages.contains(.blast) ?? false)
        XCTAssertFalse(store.progress(for: plan)?.completedStages.contains(.score) ?? false)
    }

}

extension LabModelsTests {
    func testEveryCapabilityLaneDefinesAtLeastEightStarterMixMatchCards() throws {
        for lane in CapabilityLane.defaultExplorerLanes {
            XCTAssertGreaterThanOrEqual(
                lane.starterMixMatchCards.count,
                8,
                "\(lane.title) should have at least eight starter Mix-Match cards"
            )
            XCTAssertTrue(lane.starterMixMatchCards.allSatisfy { $0.laneID == lane.id })
        }
    }


    func testStarterMixMatchSamplerCyclesThroughCards() throws {
        let geometry = try XCTUnwrap(CapabilityLane.defaultExplorerLanes.first { $0.id == .geometry })
        var sampler = geometry.starterMixMatchSampler

        XCTAssertEqual(sampler.progressLabel, "1 / \(geometry.starterMixMatchCards.count)")
        XCTAssertEqual(sampler.currentCard?.prompt, "3 sides")

        sampler.advance()
        XCTAssertEqual(sampler.progressLabel, "2 / \(geometry.starterMixMatchCards.count)")
        XCTAssertEqual(sampler.currentCard?.prompt, "4 equal sides")

        sampler.rewind()
        XCTAssertEqual(sampler.progressLabel, "1 / \(geometry.starterMixMatchCards.count)")
    }


    func testCapabilityLaneProgressTracksModesAndRecommendation() throws {
        let numbers = try XCTUnwrap(CapabilityLane.defaultExplorerLanes.first { $0.id == .numbers })
        var progress = numbers.emptyProgress

        XCTAssertEqual(progress.progressLabel, "0 / 4 modes")
        XCTAssertEqual(progress.masteryPercentLabel, "0% ready")
        XCTAssertEqual(progress.progressSummaryLabel, "🚀 0/4 missions unlocked")
        XCTAssertEqual(progress.nextRecommendedMode, .learn)
        XCTAssertEqual(progress.nextRecommendedModeLabel, "⭐ First Learn mission waiting")

        progress.markCompleted(.learn)
        progress.markCompleted(.timed)

        XCTAssertEqual(progress.progressLabel, "2 / 4 modes")
        XCTAssertEqual(progress.masteryPercentLabel, "50% ready")
        XCTAssertEqual(progress.progressSummaryLabel, "🚀 2/4 missions unlocked")
        XCTAssertEqual(progress.nextRecommendedMode, .challenge)
        XCTAssertEqual(progress.nextRecommendedModeLabel, "⭐ Try Challenge next")
    }

    func testCapabilityLaneProgressTracksReviewedCardsOnlyForItsLane() throws {
        let numbers = try XCTUnwrap(CapabilityLane.defaultExplorerLanes.first { $0.id == .numbers })
        let geometry = try XCTUnwrap(CapabilityLane.defaultExplorerLanes.first { $0.id == .geometry })
        var progress = numbers.emptyProgress

        progress.markReviewed(try XCTUnwrap(numbers.starterMixMatchCards.first))
        progress.markReviewed(try XCTUnwrap(geometry.starterMixMatchCards.first))

        XCTAssertEqual(progress.reviewedCardIDs.count, 1)
    }

    func testCapabilityLaneProgressCanRenderPersistedMasteryState() {
        var masteryState = LaneMasteryState(
            laneID: .numbers,
            availableModes: [.learn, .challenge, .timed, .review]
        )
        masteryState.markCompleted(.learn)
        masteryState.markCompleted(.timed)
        masteryState.markReviewedCard(id: "numbers-number-bond-five-and-five")

        let progress = CapabilityLaneProgress(masteryState: masteryState)

        XCTAssertEqual(progress.progressSummaryLabel, "🚀 2/4 missions unlocked")
        XCTAssertEqual(progress.nextRecommendedModeLabel, "⭐ Try Challenge next")
        XCTAssertEqual(progress.reviewedCardIDs, ["numbers-number-bond-five-and-five"])
    }

    func testStarterMixMatchCardsHaveChildReadablePromptsAndMatches() {
        let allCards = CapabilityLane.defaultExplorerLanes.flatMap(\.starterMixMatchCards)

        XCTAssertFalse(allCards.isEmpty)
        XCTAssertTrue(allCards.allSatisfy { !$0.concept.isEmpty })
        XCTAssertTrue(allCards.allSatisfy { !$0.prompt.isEmpty })
        XCTAssertTrue(allCards.allSatisfy { !$0.match.isEmpty })
        XCTAssertTrue(allCards.allSatisfy { $0.accessibilityLabel.contains("matches") })
        XCTAssertEqual(Set(allCards.map(\.id)).count, allCards.count)
    }

    func testLabLaneActivityAndRecallAccessibilityCopyExposeCriticalContext() throws {
        let numbers = try XCTUnwrap(CapabilityLane.defaultExplorerLanes.first { $0.id == .numbers })
        let sumSprint = try XCTUnwrap(numbers.activities.first { $0.id == .sumSprint })

        XCTAssertTrue(numbers.accessibilityLabel.contains("Numbers Lab"))
        XCTAssertTrue(numbers.accessibilityLabel.contains("Ages 4–12"))
        XCTAssertEqual(numbers.accessibilityHint, "Choose an activity or review cards.")
        XCTAssertTrue(numbers.recallAccessibilityLabel.contains("1 recall card + 8 Mix-Match ready"))
        XCTAssertTrue(numbers.recallAccessibilityLabel.contains("number-bond"))
        XCTAssertEqual(sumSprint.accessibilityLabel, "Sum Sprint. Race through sums 11–20")
        XCTAssertTrue(sumSprint.accessibilityHint.contains("Launches Sum Sprint"))
        XCTAssertTrue(sumSprint.accessibilityHint.contains("Modes: Challenge, Timed, Review"))
    }

    func testActivitySensorNeedsMapToHonestLaneAffordances() {
        XCTAssertEqual(LabActivityID.sumSprint.sensorNeeds, [.noSpecialSensor])
        XCTAssertEqual(LabActivityID.shapeGeometry.sensorNeeds, [.noSpecialSensor])
        XCTAssertEqual(LabActivityID.angleCannon.sensorNeeds, [.motion])
        XCTAssertEqual(LabActivityID.gravityArtist.sensorNeeds, [.motion])
        XCTAssertEqual(LabActivityID.compassAngles.sensorNeeds, [.compass, .stepCounting])
        XCTAssertEqual(LabActivityID.roomQuest.sensorNeeds, [.cameraMarkerMode, .haptics])
        XCTAssertEqual(LabActivityID.soundVolume.sensorNeeds, [.noSpecialSensor])
        XCTAssertEqual(LabActivityID.memoryMatch.sensorNeeds, [.noSpecialSensor])
    }

    func testUnavailableSensorAffordancesExposeVisibleFallbackCopy() {
        let affordances = LabActivityID.roomQuest.sensorAffordances(with: .unavailable)

        XCTAssertEqual(
            affordances.map(\.displayLabel),
            [
                "Camera marker mode unavailable: Use same-place setup",
                "Haptics unavailable: Visual feedback stays available",
            ]
        )
        XCTAssertEqual(affordances.map(\.accessibilityHint), ["Use same-place setup", "Visual feedback stays available"])
        XCTAssertTrue(affordances.allSatisfy { !$0.isAvailable })
    }

    func testAvailableCapabilitiesUseReadyCopyWithoutFallbacks() {
        let capabilities = DeviceSensorCapabilities(
            supportsMotion: true,
            supportsHeading: true,
            supportsCamera: true,
            supportsMicrophone: false,
            supportsHaptics: true,
            supportsBarometer: false,
            supportsStepCounting: true,
            supportsLiDAR: false,
            supportsApplePencil: false
        )

        XCTAssertEqual(
            LabActivityID.angleCannon.sensorAffordances(with: capabilities).map(\.displayLabel),
            ["Tilt ready"]
        )
        XCTAssertEqual(
            LabActivityID.compassAngles.sensorAffordances(with: capabilities).map(\.displayLabel),
            ["Body turns ready", "Step sensing ready"]
        )
        XCTAssertEqual(
            LabActivityID.roomQuest.sensorAffordances(with: capabilities).map(\.displayLabel),
            ["Camera marker mode ready", "Haptics ready"]
        )
        XCTAssertEqual(
            LabActivityID.twoFingerProtractor.sensorAffordances(with: capabilities).map(\.displayLabel),
            ["Touch ready"]
        )
    }

    func testSensorLaunchPolicyKeepsFallbackGamesPlayableButDisablesSensorOnlyRoutes() {
        XCTAssertTrue(LabActivityID.sumSprint.canDirectLaunch(with: .unavailable))
        XCTAssertTrue(LabActivityID.roomQuest.canDirectLaunch(with: .unavailable))
        XCTAssertFalse(LabActivityID.angleCannon.canDirectLaunch(with: .unavailable))
        XCTAssertFalse(LabActivityID.gravityArtist.canDirectLaunch(with: .unavailable))
        XCTAssertFalse(LabActivityID.compassAngles.canDirectLaunch(with: .unavailable))

        let roomQuestCopy = LabActivityID.roomQuest.capabilitySummary(with: .unavailable)
        XCTAssertTrue(roomQuestCopy.contains("Use same-place setup"))
        XCTAssertTrue(roomQuestCopy.contains("Visual feedback stays available"))
    }

    func testSensorAffordancesExposePermissionAwareChildSafeCopy() {
        let unavailableTilt = LabActivityID.angleCannon.sensorAffordances(with: .unavailable)
        XCTAssertEqual(unavailableTilt.first?.accessibilityHint, "This game needs this sensor on the device. Try another game for now.")

        let stepFallback = LabSensorNeed.stepCounting.copy(with: .unavailable)
        XCTAssertEqual(stepFallback.displayLabel, "Step sensing unavailable: Tap each small step instead")
        XCTAssertEqual(stepFallback.accessibilityHint, "Tap each small step instead")
        XCTAssertTrue(stepFallback.permitsLaunch)
    }
    func testGeometryGuidedLabPathExposesShapeAngleAndSymmetryPlans() throws {
        let geometryPath = try XCTUnwrap(GuidedLabPath.phaseOne.first { $0.laneID == .geometry })

        XCTAssertEqual(geometryPath.title, "Geometry Path")
        XCTAssertEqual(geometryPath.stages, [.learn, .remember, .play, .blast, .score])
        XCTAssertEqual(geometryPath.stages.map(\.rawValue).joined(separator: " → "), "Learn → Remember → Play → Blast → Score")
        XCTAssertEqual(geometryPath.sessionPlans.map(\.id), [
            "geometry-shape-names",
            "geometry-angles-basic",
            "geometry-symmetry-folds",
        ])

        for plan in geometryPath.sessionPlans {
            XCTAssertEqual(plan.laneID, .geometry)
            XCTAssertEqual(plan.stageOrder, [.learn, .remember, .play, .blast, .score])
            XCTAssertEqual(plan.pathLabel, "Learn → Remember → Play → Blast → Score")
            XCTAssertEqual(LabConceptSessionPlan.plan(for: plan.id), plan)
            XCTAssertEqual(plan.stages.first { $0.stage == .score }?.route, nil)
            XCTAssertTrue(plan.stages.allSatisfy { !$0.accessibilityLabel.isEmpty })
        }
    }

    func testGeometryStagePlansWrapExistingDirectGamesWithoutChangingGameRoutes() throws {
        let angle = LabConceptSessionPlan.geometryAnglesBasic
        let symmetry = LabConceptSessionPlan.geometrySymmetryFolds
        let shape = LabConceptSessionPlan.geometryShapeNames

        XCTAssertEqual(angle.stages.map(\.route), [
            .twoFingerProtractor,
            .labRememberStage(.geometryAnglesBasic),
            .twoFingerProtractor,
            .angleCannon,
            nil,
        ])
        XCTAssertEqual(symmetry.stages.map(\.route), [
            .symmetryFold,
            .labRememberStage(.geometrySymmetryFolds),
            .symmetryFold,
            .symmetryFold,
            nil,
        ])
        XCTAssertEqual(shape.stages.map(\.route), [
            .shapeGeometry,
            .labRememberStage(.geometryShapeNames),
            .shapeGeometry,
            .shapeGeometry,
            nil,
        ])

        XCTAssertEqual(LabActivityID.angleCannon.appRoute, .angleCannon)
        XCTAssertEqual(LabActivityID.twoFingerProtractor.appRoute, .twoFingerProtractor)
        XCTAssertEqual(LabActivityID.symmetryFold.appRoute, .symmetryFold)
        XCTAssertEqual(LabActivityID.shapeGeometry.appRoute, .shapeGeometry)
    }

    func testGeometryRememberDecksAreCalmReusableCards() throws {
        let decks = [
            LabRememberStageDeck.geometryShapeNames,
            LabRememberStageDeck.geometryAnglesBasic,
            LabRememberStageDeck.geometrySymmetryFolds,
        ]

        XCTAssertEqual(decks.map(\.id), [.geometryShapeNames, .geometryAnglesBasic, .geometrySymmetryFolds])
        for deck in decks {
            XCTAssertEqual(deck.laneID, .geometry)
            XCTAssertEqual(deck.stage, .remember)
            XCTAssertFalse(deck.hasPunitiveCountdown)
            XCTAssertGreaterThanOrEqual(deck.cards.count, 4)
            XCTAssertEqual(LabRememberStageDeck.deck(for: deck.id), deck)
            XCTAssertEqual(LabConceptSessionPlan.plan(for: deck.planID)?.stages.first { $0.stage == .remember }?.route, deck.route)
            XCTAssertTrue(deck.cards.allSatisfy { $0.laneID == .geometry })
            XCTAssertTrue(deck.cards.allSatisfy { !$0.accessibilityLabel.isEmpty })
        }
    }

}


private final class InMemoryLabConceptSessionProgressDefaults: ExplorerLabMasteryKeyValueStore {
    var values: [String: Data] = [:]

    func data(forKey defaultName: String) -> Data? {
        values[defaultName]
    }

    func set(_ value: Data?, forKey defaultName: String) {
        values[defaultName] = value
    }

    func removeObject(forKey defaultName: String) {
        values.removeValue(forKey: defaultName)
    }

}
