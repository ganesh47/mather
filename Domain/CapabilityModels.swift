import Foundation

struct CapabilityLaneDescriptor: Identifiable, Equatable {
    let id: CapabilityLaneID
    let emoji: String
    let promise: String
    let ageBand: AgeBand
    let stages: [LaneStage]
    let supportedPlayModes: [PlayMode]
    let starterConcepts: [ConceptId]

    var title: String { id.title }
    var ageBandHint: String { ageBand.displayLabel }
}

enum CapabilityLaneRegistry {
    static let all: [CapabilityLaneDescriptor] = [
        CapabilityLaneDescriptor(
            id: .numbers,
            emoji: "🔢",
            promise: "Build number bonds, fast facts, arrays, and whole-part thinking.",
            ageBand: .ages4To12,
            stages: [.concrete, .pictorial, .abstract, .transfer, .review],
            supportedPlayModes: [.learn, .challenge, .timed, .review],
            starterConcepts: ["number-bond", "dot-pattern", "array", "factor-pair", "story-equation"]
        ),
        CapabilityLaneDescriptor(
            id: .geometry,
            emoji: "📐",
            promise: "Fold, measure, aim, and transform shapes with touch and motion.",
            ageBand: .ages4To12,
            stages: [.concrete, .pictorial, .abstract, .transfer, .review],
            supportedPlayModes: [.learn, .explore, .challenge, .review],
            starterConcepts: ["shape", "symmetry", "angle", "array-shape", "transformation"]
        ),
        CapabilityLaneDescriptor(
            id: .physics,
            emoji: "🧪",
            promise: "Predict motion, gravity, water, and cause-and-effect systems.",
            ageBand: .ages2To12,
            stages: [.concrete, .pictorial, .transfer, .review],
            supportedPlayModes: [.explore, .challenge, .review],
            starterConcepts: ["motion", "gravity", "prediction", "water-cycle", "float-sink", "balance"]
        ),
        CapabilityLaneDescriptor(
            id: .mapWorld,
            emoji: "🗺️",
            promise: "Use rooms, compass turns, direction words, and route clues.",
            ageBand: .ages4To12,
            stages: [.concrete, .pictorial, .abstract, .transfer, .review],
            supportedPlayModes: [.explore, .challenge, .timed, .review],
            starterConcepts: ["direction", "turn", "route", "map-symbol", "scale", "compass"]
        ),
        CapabilityLaneDescriptor(
            id: .discoveryCards,
            emoji: "🃏",
            promise: "Practice names, pictures, categories, and Mix-Match recall.",
            ageBand: .ages2To12,
            stages: [.pictorial, .abstract, .review],
            supportedPlayModes: [.learn, .review, .challenge],
            starterConcepts: ["animal", "habitat", "category", "body", "world", "vocabulary"]
        ),
        CapabilityLaneDescriptor(
            id: .chemistry,
            emoji: "⚗️",
            promise: "Future: sort materials, mix safely, and predict properties.",
            ageBand: .future,
            stages: [.concrete, .pictorial, .transfer, .review],
            supportedPlayModes: [.explore, .challenge, .review],
            starterConcepts: ["state", "property", "mixture", "safety"]
        ),
        CapabilityLaneDescriptor(
            id: .electronics,
            emoji: "💡",
            promise: "Future: switches, circuits, sensors, and input/output systems.",
            ageBand: .future,
            stages: [.concrete, .pictorial, .abstract, .transfer, .review],
            supportedPlayModes: [.explore, .challenge, .review],
            starterConcepts: ["component", "output", "circuit", "sensor", "logic"]
        ),
    ]

    static func descriptor(for laneID: CapabilityLaneID) -> CapabilityLaneDescriptor? {
        all.first { $0.id == laneID }
    }
}
