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

        XCTAssertEqual(presentation.title, "Numbers Lab")
        XCTAssertEqual(presentation.openAffordanceLabel, "Enter world")
        XCTAssertEqual(
            presentation.sections,
            [.visualSummary, .promise, .progressStatus]
        )
        XCTAssertFalse(presentation.showsDetails)
        XCTAssertFalse(presentation.sections.contains(.modes))
        XCTAssertFalse(presentation.sections.contains(.ageEntries))
        XCTAssertFalse(presentation.sections.contains(.recall))
        XCTAssertFalse(presentation.sections.contains(.activities))
        XCTAssertTrue(presentation.accessibilityHint.contains("Opens Numbers Lab"))
    }

    func testLaneDetailPresentationRestoresDetailsWithoutDroppingLaunches() throws {
        let numbers = try XCTUnwrap(CapabilityLane.defaultExplorerLanes.first { $0.id == .numbers })
        let presentation = LabLaneDetailPresentation(lane: numbers)

        XCTAssertEqual(presentation.activityCountLabel, "3 games ready")
        XCTAssertTrue(presentation.sections.contains(.modes))
        XCTAssertTrue(presentation.sections.contains(.playStyles))
        XCTAssertTrue(presentation.sections.contains(.ageEntries))
        XCTAssertTrue(presentation.sections.contains(.recall))
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
        XCTAssertTrue(labs.subtitle.contains("Guided sessions"))
        XCTAssertEqual(labs.callToAction, "Start a learning path")

        XCTAssertEqual(games.title, "Games")
        XCTAssertTrue(games.subtitle.contains("Jump straight into"))
        XCTAssertEqual(games.callToAction, "Play now")
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
        XCTAssertEqual(plan.stages.map(\.actionLabel), ["Start", "Continue", "Continue", "Preview", "Preview"])
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
        XCTAssertEqual(LabActivityID.compassAngles.sensorNeeds, [.compass])
        XCTAssertEqual(LabActivityID.roomQuest.sensorNeeds, [.cameraMarkerMode, .haptics])
        XCTAssertEqual(LabActivityID.soundVolume.sensorNeeds, [.noSpecialSensor])
        XCTAssertEqual(LabActivityID.memoryMatch.sensorNeeds, [.noSpecialSensor])
    }

    func testUnavailableSensorAffordancesExposeVisibleFallbackCopy() {
        let affordances = LabActivityID.roomQuest.sensorAffordances(with: .unavailable)

        XCTAssertEqual(
            affordances.map(\.displayLabel),
            [
                "Camera marker mode unavailable: Use tap-to-place stations",
                "Haptics unavailable: Visual feedback stays available",
            ]
        )
        XCTAssertEqual(affordances.map(\.accessibilityHint), ["Use tap-to-place stations", "Visual feedback stays available"])
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
            supportsLiDAR: false,
            supportsApplePencil: false
        )

        XCTAssertEqual(
            LabActivityID.angleCannon.sensorAffordances(with: capabilities).map(\.displayLabel),
            ["Motion ready"]
        )
        XCTAssertEqual(
            LabActivityID.compassAngles.sensorAffordances(with: capabilities).map(\.displayLabel),
            ["Compass ready"]
        )
        XCTAssertEqual(
            LabActivityID.roomQuest.sensorAffordances(with: capabilities).map(\.displayLabel),
            ["Camera marker mode ready", "Haptics ready"]
        )
        XCTAssertEqual(
            LabActivityID.twoFingerProtractor.sensorAffordances(with: capabilities).map(\.displayLabel),
            ["No special sensor needed"]
        )
    }
}
