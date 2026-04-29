import Foundation

/// Route Quest is a Room Quest route mode: scripted route progression,
/// not exact indoor positioning. Sensor readings are optional evidence for
/// completing nodes, never the source of truth for the child's location.
enum RouteQuestStepValidation: String, Codable, Equatable, CaseIterable {
    case manualConfirm
    case parentAssist
    case motionEvidence
}

enum RouteQuestCompletionMethod: String, Codable, Equatable, CaseIterable {
    case motion
    case manual
    case parentAssist = "parent_assist"
    case scan
    case fallback
}

enum RouteQuestNodeKind: Codable, Equatable {
    case start
    case turn(targetDegrees: Double, toleranceDegrees: Double)
    case step(count: Int, validation: RouteQuestStepValidation)
    case station(role: RoomQuestStationRole, quantity: Int)
    case returnHome

    var telemetryName: String {
        switch self {
        case .start: "start"
        case .turn: "turn"
        case .step: "step"
        case .station: "station"
        case .returnHome: "return_home"
        }
    }
}

struct RouteQuestNode: Identifiable, Codable, Equatable {
    let id: UUID
    let order: Int
    let kind: RouteQuestNodeKind
    let prompt: String

    init(id: UUID = UUID(), order: Int, kind: RouteQuestNodeKind, prompt: String) {
        self.id = id
        self.order = order
        self.kind = kind
        self.prompt = prompt
    }
}

struct RouteQuestRoute: Identifiable, Codable, Equatable {
    let id: UUID
    let templateName: String
    let nodes: [RouteQuestNode]

    init(id: UUID = UUID(), templateName: String, nodes: [RouteQuestNode]) {
        self.id = id
        self.templateName = templateName
        self.nodes = nodes.sorted { $0.order < $1.order }
    }

    /// First MVP route: short, parent-gated, and manually completable.
    /// It reuses Room Quest station roles and keeps steps parent/child-confirmed.
    static func twoStationMVP(id: UUID = UUID()) -> RouteQuestRoute {
        RouteQuestRoute(
            id: id,
            templateName: "room_route_two_station_mvp",
            nodes: [
                RouteQuestNode(order: 0, kind: .start, prompt: "Start at home base."),
                RouteQuestNode(order: 1, kind: .turn(targetDegrees: 45, toleranceDegrees: 12), prompt: "Turn right forty-five degrees."),
                RouteQuestNode(order: 2, kind: .step(count: 5, validation: .manualConfirm), prompt: "Take five careful steps."),
                RouteQuestNode(order: 3, kind: .station(role: .redRocket, quantity: 3), prompt: "Find Red Rocket and collect three."),
                RouteQuestNode(order: 4, kind: .turn(targetDegrees: -90, toleranceDegrees: 12), prompt: "Turn left ninety degrees."),
                RouteQuestNode(order: 5, kind: .step(count: 4, validation: .manualConfirm), prompt: "Take four careful steps."),
                RouteQuestNode(order: 6, kind: .station(role: .blueBubble, quantity: 2), prompt: "Find Blue Bubble and collect two."),
                RouteQuestNode(order: 7, kind: .returnHome, prompt: "Walk carefully back to home base.")
            ]
        )
    }
}

struct RouteQuestProgress: Codable, Equatable {
    let routeId: UUID
    var currentNodeIndex: Int
    var completedNodeIds: [UUID]
    var fallbackCount: Int
    var routeStartedAt: Date

    init(routeId: UUID, currentNodeIndex: Int = 0, completedNodeIds: [UUID] = [], fallbackCount: Int = 0, routeStartedAt: Date = .now) {
        self.routeId = routeId
        self.currentNodeIndex = currentNodeIndex
        self.completedNodeIds = completedNodeIds
        self.fallbackCount = fallbackCount
        self.routeStartedAt = routeStartedAt
    }

    func currentNode(in route: RouteQuestRoute) -> RouteQuestNode? {
        guard route.id == routeId, route.nodes.indices.contains(currentNodeIndex) else { return nil }
        return route.nodes[currentNodeIndex]
    }

    func isComplete(for route: RouteQuestRoute) -> Bool {
        route.id == routeId && currentNodeIndex >= route.nodes.count
    }

    mutating func completeCurrentNode(in route: RouteQuestRoute, method: RouteQuestCompletionMethod) -> RouteQuestNode? {
        guard let node = currentNode(in: route) else { return nil }
        if !completedNodeIds.contains(node.id) {
            completedNodeIds.append(node.id)
        }
        if method == .fallback {
            fallbackCount += 1
        }
        currentNodeIndex += 1
        return node
    }
}

enum RouteQuestTelemetry {
    static func payload(
        route: RouteQuestRoute,
        node: RouteQuestNode,
        method: RouteQuestCompletionMethod,
        elapsedMilliseconds: Int,
        sensorAvailable: Bool? = nil
    ) -> [String: String] {
        var payload: [String: String] = [
            "route_id": route.id.uuidString,
            "route_template": route.templateName,
            "node_index": String(node.order),
            "node_kind": node.kind.telemetryName,
            "completion_method": method.rawValue,
            "elapsed_ms": String(elapsedMilliseconds)
        ]

        switch node.kind {
        case .turn(let targetDegrees, let toleranceDegrees):
            payload["target_deg"] = Self.formatDegrees(targetDegrees)
            payload["tolerance_deg"] = Self.formatDegrees(toleranceDegrees)
        case .step(let count, let validation):
            payload["target_steps"] = String(count)
            payload["step_validation"] = validation.rawValue
        case .station(let role, let quantity):
            payload["station_role"] = role.rawValue
            payload["station_quantity"] = String(quantity)
        case .start, .returnHome:
            break
        }

        if let sensorAvailable {
            payload["sensor_available"] = sensorAvailable ? "true" : "false"
        }
        return payload
    }

    private static func formatDegrees(_ value: Double) -> String {
        value.rounded() == value ? String(Int(value)) : String(value)
    }
}
