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
            .waterCycle: .waterCycle,
            .memoryMatch: .memory,
        ]

        #expect(Set(expectedRoutes.keys) == Set(LabActivityID.allCases))
        for activityID in LabActivityID.allCases {
            let expectedRoute = try #require(expectedRoutes[activityID])
            #expect(activityID.appRoute == expectedRoute)
        }
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
    func discoveryChemistryAndElectronicsShellsStayRegistered() throws {
        let lanes = CapabilityLane.defaultExplorerLanes
        let discovery = try #require(lanes.first { $0.id == .discoveryCards })
        let chemistry = try #require(lanes.first { $0.id == .chemistry })
        let electronics = try #require(lanes.first { $0.id == .electronics })

        #expect(discovery.activities.map(\.id) == [.memoryMatch])
        #expect(discovery.starterMixMatchCards.count >= 8)
        #expect(discovery.modeChoiceCards.count == discovery.modes.count)

        for futureShell in [chemistry, electronics] {
            #expect(futureShell.activities.isEmpty)
            #expect(!futureShell.promise.isEmpty)
            #expect(futureShell.ageBandHint == "Future lane")
            #expect(futureShell.starterMixMatchCards.count >= 8)
            #expect(futureShell.modeChoiceCards.count == futureShell.modes.count)
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
