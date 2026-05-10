import Foundation
import Testing
@testable import Mather

@MainActor
struct LabRouteRegressionTests {
    @Test
    func everyExplorerLabActivityIsReachableFromExactlyOneCapabilityLane() {
        let activitiesByLane = CapabilityLane.defaultExplorerLanes.flatMap { lane in
            lane.activities.map { (laneID: lane.id, activityID: $0.id) }
        }
        let activityIDs = activitiesByLane.map(\.activityID)

        #expect(Set(activityIDs) == Set(LabActivityID.allCases))
        #expect(activityIDs.count == LabActivityID.allCases.count)

        for activityID in LabActivityID.allCases {
            let hostLanes = activitiesByLane.filter { $0.activityID == activityID }.map(\.laneID)
            #expect(hostLanes.count == 1, "\(activityID.rawValue) should be exposed by exactly one lane")
        }
    }

    @Test
    func explorerLabActivitiesMapToCurrentAppRoutes() throws {
        let expectedRoutes: [LabActivityID: AppRoute] = [
            .sumSprint: .sumSprint,
            .roomQuest: .roomQuest,
            .symmetryFold: .symmetryFold,
            .rectangleFactory: .rectangleFactory,
            .factoryCards: .factoryCards,
            .angleCannon: .angleCannon,
            .twoFingerProtractor: .twoFingerProtractor,
            .gravityArtist: .gravityArtist,
            .compassAngles: .compassAngles,
            .shapeGeometry: .shapeGeometry,
            .waterCycle: .gameplayThread(.waterCycle),
            .soundVolume: .soundVolume,
            .memoryMatch: .memory,
            .countryCards: .gameplayThread(.countries),
            .worldAnimalSafari: .gameplayThread(.worldAnimals),
            .worldBirdSafari: .gameplayThread(.worldBirds),
            .fruitCards: .gameplayThread(.fruits),
            .circuitSpark: .gameplayThread(.electronics),
        ]

        #expect(Set(expectedRoutes.keys) == Set(LabActivityID.allCases))
        for activityID in LabActivityID.allCases {
            let expectedRoute = try #require(expectedRoutes[activityID])
            #expect(activityID.appRoute == expectedRoute)
        }
    }

    @Test
    func explorerLabContentRoutesUseReusableGameplayThreads() {
        let reusableThreadRoutes: [LabActivityID: GameplayThreadID] = [
            .countryCards: .countries,
            .worldAnimalSafari: .worldAnimals,
            .worldBirdSafari: .worldBirds,
            .fruitCards: .fruits,
            .waterCycle: .waterCycle,
            .circuitSpark: .electronics,
        ]

        for (activityID, threadID) in reusableThreadRoutes {
            #expect(activityID.appRoute == .gameplayThread(threadID))
            #expect(GameplayThreadCatalog.thread(for: threadID).stages.map(\.kind) == [.flashcards, .easyMemory, .flipMemory, .bondBlast, .multipleChoice])
        }
    }

    @Test
    func legacyWaterCycleRouteRemainsAvailableButExplorerLabDelegatesToGameplayThread() {
        let engine = makeEngine()

        engine.showWaterCycle()
        #expect(engine.route == .gameplayThread(.waterCycle))

        engine.showLegacyWaterCycleLab()
        #expect(engine.route == .waterCycle)
    }

    @Test
    func labGameRoutesCanReturnHomeThroughSharedRouteAPI() {
        let engine = makeEngine()
        let labRoutes = Set(LabActivityID.allCases.map(\.appRoute))

        for route in labRoutes {
            engine.show(route)
            #expect(engine.route == route)

            engine.showHome()
            #expect(engine.route == .home)
        }
    }

    @Test
    func gameplayThreadReturnRouteCanLandBackOnLaunchingLabLane() {
        let engine = makeEngine()

        engine.showGameplayThread(.countries, returnRoute: .labLane(.mapWorld))
        #expect(engine.route == .gameplayThread(.countries))
        #expect(engine.gameplayReturnRoute == .labLane(.mapWorld))

        engine.returnFromGameplay(defaultRoute: .lab)
        #expect(engine.route == .labLane(.mapWorld))
        #expect(engine.gameplayReturnRoute == nil)
    }

    @Test
    func directGameplayThreadLaunchStillHasNoLabProgressReturnContext() {
        let engine = makeEngine()

        engine.showCountriesGameplayThread()

        #expect(engine.route == .gameplayThread(.countries))
        #expect(engine.gameplayReturnRoute == nil)
    }

    @Test
    func discoveryChemistryAndElectronicsLanesExposePlayableActivities() throws {
        let lanes = CapabilityLane.defaultExplorerLanes
        let discovery = try #require(lanes.first { $0.id == .discoveryCards })
        let chemistry = try #require(lanes.first { $0.id == .chemistry })
        let electronics = try #require(lanes.first { $0.id == .electronics })

        #expect(discovery.activities.map(\.id) == [.memoryMatch])
        #expect(discovery.starterMixMatchCards.count >= 8)
        #expect(discovery.modeChoiceCards.count == discovery.modes.count)

        #expect(chemistry.activities.map(\.id) == [.fruitCards])
        #expect(chemistry.activities.first?.title == "Fruit Cards")

        #expect(electronics.activities.map(\.id) == [.circuitSpark])
        #expect(electronics.activities.first?.title == "Circuit Spark")
        #expect(electronics.activities.first?.accessibilityLabel.contains("batteries") == true)
        #expect(electronics.accessibilityHint == "Choose an activity or review cards.")
        #expect(!electronics.promise.contains("Future"))
        for lane in [chemistry, electronics] {
            #expect(!lane.promise.isEmpty)
            #expect(lane.starterMixMatchCards.count >= 8)
            #expect(lane.modeChoiceCards.count == lane.modes.count)
        }
    }

    @Test
    func everyCapabilityLaneExposesRecallEntries() {
        let lanes = CapabilityLane.defaultExplorerLanes

        #expect(Set(lanes.map(\.id)) == Set(CapabilityLaneID.allCases))

        for lane in lanes {
            #expect(!lane.recallEntries.isEmpty, "\(lane.id.rawValue) should expose recall cards")
            #expect(lane.recallEntries.allSatisfy { $0.laneID == lane.id })
            #expect(lane.modes.contains(.review), "\(lane.id.rawValue) should expose Review mode")
        }
    }

    @Test
    func laneDetailPresentationPrioritizesActivitiesBeforeSupportMetadata() throws {
        let readyLane = try #require(CapabilityLane.defaultExplorerLanes.first { $0.id == .numbers })
        let electronicsLane = try #require(CapabilityLane.defaultExplorerLanes.first { $0.id == .electronics })

        #expect(LabLaneDetailPresentation(lane: readyLane).sections == [
            .visualSummary,
            .activities,
            .progressStatus,
        ])
        #expect(LabLaneDetailPresentation(lane: electronicsLane).sections == [
            .visualSummary,
            .activities,
            .progressStatus,
        ])
        #expect(LabLaneDetailPresentation(lane: electronicsLane).activityCountLabel == "1 game ready")
    }

    @Test
    func recallReviewActionsMapBackToOwningLane() throws {
        for lane in CapabilityLane.defaultExplorerLanes {
            let entry = try #require(lane.firstRecallEntry)
            let actions = entry.choiceActions

            #expect(!actions.isEmpty)
            #expect(actions.allSatisfy { $0.laneID == lane.id })
            #expect(actions.allSatisfy { $0.cardID == entry.card.id })
            #expect(Set(actions.map(\.choiceID)) == Set(entry.card.choices.map(\.id)))
            #expect(actions.filter(\.isCorrect).map(\.choiceID) == entry.card.correctChoices.map(\.id))
        }
    }

    private func makeEngine() -> VerticalSliceEngine {
        let flags = FeatureFlagService(defaults: UserDefaults(suiteName: "LabRouteRegressionTests")!)
        flags.testModeEnabled = true
        flags.audioEnabled = false
        return VerticalSliceEngine(
            featureFlags: flags,
            telemetryWriter: TelemetryWriter(),
            speechService: SpeechService(),
            celebrationDuration: 0,
            saveSummary: { _ in }
        )
    }
}
