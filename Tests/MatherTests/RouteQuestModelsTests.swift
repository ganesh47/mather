import Foundation
import Testing
@testable import Mather

struct RouteQuestModelsTests {
    @Test func twoStationMVPOrdersSafeScriptedNodes() {
        let route = RouteQuestRoute.twoStationMVP(id: UUID(uuidString: "00000000-0000-0000-0000-000000000739")!)

        #expect(route.templateName == "room_route_two_station_mvp")
        #expect(route.nodes.map(\.order) == Array(0..<8))
        #expect(route.nodes.first?.kind == .start)
        #expect(route.nodes.last?.kind == .returnHome)
        #expect(route.nodes.contains { $0.kind == .step(count: 5, validation: .manualConfirm) })
        #expect(route.nodes.contains { $0.kind == .station(role: .redRocket, quantity: 3) })
        #expect(route.nodes.contains { $0.kind == .station(role: .blueBubble, quantity: 2) })
    }

    @Test func progressAdvancesByExplicitNodeCompletionOnly() {
        let route = RouteQuestRoute.twoStationMVP(id: UUID(uuidString: "00000000-0000-0000-0000-000000000739")!)
        var progress = RouteQuestProgress(routeId: route.id, routeStartedAt: Date(timeIntervalSince1970: 739))

        #expect(progress.currentNode(in: route)?.kind == .start)
        let completedStart = progress.completeCurrentNode(in: route, method: .manual)

        #expect(completedStart?.kind == .start)
        #expect(progress.completedNodeIds == [route.nodes[0].id])
        #expect(progress.currentNode(in: route)?.kind == .turn(targetDegrees: 45, toleranceDegrees: 12))
        #expect(!progress.isComplete(for: route))
    }

    @Test func fallbackCompletionIsCountedWithoutBlockingRoute() {
        let route = RouteQuestRoute.twoStationMVP()
        var progress = RouteQuestProgress(routeId: route.id)

        for _ in 0..<route.nodes.count {
            _ = progress.completeCurrentNode(in: route, method: .fallback)
        }

        #expect(progress.isComplete(for: route))
        #expect(progress.currentNode(in: route) == nil)
        #expect(progress.fallbackCount == route.nodes.count)
    }

    @Test func routeQuestPayloadIncludesNodeSpecificFieldsWithoutRawPathData() {
        let route = RouteQuestRoute.twoStationMVP(id: UUID(uuidString: "00000000-0000-0000-0000-000000000739")!)
        let turn = route.nodes[1]
        let payload = RouteQuestTelemetry.payload(route: route, node: turn, method: .motion, elapsedMilliseconds: 1_250, sensorAvailable: true)

        #expect(payload["route_template"] == "room_route_two_station_mvp")
        #expect(payload["node_index"] == "1")
        #expect(payload["node_kind"] == "turn")
        #expect(payload["target_deg"] == "45")
        #expect(payload["tolerance_deg"] == "12")
        #expect(payload["completion_method"] == "motion")
        #expect(payload["sensor_available"] == "true")
        #expect(payload["latitude"] == nil)
        #expect(payload["longitude"] == nil)
        #expect(payload["route_path"] == nil)
    }

    @Test func routeQuestTelemetryEventNamesAreStable() {
        #expect(SliceEventType.routeQuestStarted.rawValue == "route_quest_started")
        #expect(SliceEventType.routeQuestNodeStarted.rawValue == "route_quest_node_started")
        #expect(SliceEventType.routeQuestTurnCompleted.rawValue == "route_quest_turn_completed")
        #expect(SliceEventType.routeQuestStepCompleted.rawValue == "route_quest_step_completed")
        #expect(SliceEventType.routeQuestStationConfirmed.rawValue == "route_quest_station_confirmed")
        #expect(SliceEventType.routeQuestFallbackUsed.rawValue == "route_quest_fallback_used")
        #expect(SliceEventType.routeQuestCompleted.rawValue == "route_quest_completed")
        #expect(SliceEventType.routeQuestAbandoned.rawValue == "route_quest_abandoned")
    }
}
