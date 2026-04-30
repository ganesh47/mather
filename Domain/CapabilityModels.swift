import Foundation

struct CapabilityLaneDescriptor: Identifiable, Equatable, Sendable {
    let id: CapabilityLaneID
    let symbolName: String
    let ageBand: AgeBand
    let promise: String
    let defaultModes: [PlayMode]
    let stages: [LaneStage]
    let featuredConcepts: [ConceptId]
    let isAvailable: Bool

    var title: String { id.title }
    var shortTitle: String { id.shortTitle }
    var ageBandLabel: String { ageBand.displayName }

    init(
        id: CapabilityLaneID,
        symbolName: String,
        ageBand: AgeBand,
        promise: String,
        defaultModes: [PlayMode],
        stages: [LaneStage],
        featuredConcepts: [ConceptId],
        isAvailable: Bool
    ) {
        self.id = id
        self.symbolName = symbolName
        self.ageBand = ageBand
        self.promise = promise
        self.defaultModes = defaultModes
        self.stages = stages
        self.featuredConcepts = featuredConcepts
        self.isAvailable = isAvailable
    }
}

struct CapabilityLaneRegistry: Equatable, Sendable {
    let descriptors: [CapabilityLaneDescriptor]

    init(descriptors: [CapabilityLaneDescriptor]) {
        self.descriptors = descriptors
    }

    func descriptor(for laneID: CapabilityLaneID) -> CapabilityLaneDescriptor? {
        descriptors.first { $0.id == laneID }
    }
}

extension CapabilityLaneRegistry {
    static let explorerLab = CapabilityLaneRegistry(descriptors: [
        CapabilityLaneDescriptor(
            id: .numbers,
            symbolName: "number",
            ageBand: .mixed,
            promise: "Build number bonds, fast facts, arrays, and whole-part thinking.",
            defaultModes: [.learn, .challenge, .timed, .review],
            stages: [.concrete, .pictorial, .abstract, .recall, .quiz, .transfer, .summary],
            featuredConcepts: [
                .laneSpecific(.numbers, "number-bond"),
                .laneSpecific(.numbers, "dot-pattern"),
                .laneSpecific(.numbers, "array")
            ],
            isAvailable: true
        ),
        CapabilityLaneDescriptor(
            id: .geometry,
            symbolName: "ruler",
            ageBand: .mixed,
            promise: "Fold, measure, aim, and transform shapes with touch and motion.",
            defaultModes: [.learn, .explore, .challenge, .review],
            stages: [.concrete, .pictorial, .abstract, .recall, .quiz, .transfer, .summary],
            featuredConcepts: [
                .laneSpecific(.geometry, "shape"),
                .laneSpecific(.geometry, "symmetry"),
                .laneSpecific(.geometry, "angle")
            ],
            isAvailable: true
        ),
        CapabilityLaneDescriptor(
            id: .physics,
            symbolName: "atom",
            ageBand: .mixed,
            promise: "Predict motion, gravity, water, and cause-and-effect systems.",
            defaultModes: [.explore, .challenge, .review],
            stages: [.concrete, .pictorial, .recall, .quiz, .transfer, .summary],
            featuredConcepts: [
                .laneSpecific(.physics, "motion"),
                .laneSpecific(.physics, "gravity"),
                .laneSpecific(.physics, "water-cycle")
            ],
            isAvailable: true
        ),
        CapabilityLaneDescriptor(
            id: .mapWorld,
            symbolName: "map",
            ageBand: .mixed,
            promise: "Use rooms, compass turns, direction words, and route clues.",
            defaultModes: [.explore, .challenge, .timed],
            stages: [.concrete, .pictorial, .abstract, .recall, .quiz, .transfer, .summary],
            featuredConcepts: [
                .laneSpecific(.mapWorld, "direction"),
                .laneSpecific(.mapWorld, "turn"),
                .laneSpecific(.mapWorld, "route")
            ],
            isAvailable: true
        ),
        CapabilityLaneDescriptor(
            id: .discoveryCards,
            symbolName: "rectangle.on.rectangle",
            ageBand: .mixed,
            promise: "Practice names, pictures, categories, and Mix-Match recall.",
            defaultModes: [.learn, .review, .challenge],
            stages: [.pictorial, .recall, .quiz, .summary],
            featuredConcepts: [
                .laneSpecific(.discoveryCards, "category"),
                .laneSpecific(.discoveryCards, "vocabulary"),
                .laneSpecific(.discoveryCards, "world")
            ],
            isAvailable: true
        ),
        CapabilityLaneDescriptor(
            id: .chemistry,
            symbolName: "flask",
            ageBand: .future,
            promise: "Future: sort materials, mix safely, and predict properties.",
            defaultModes: [.explore, .challenge, .review],
            stages: [.concrete, .pictorial, .recall, .quiz, .summary],
            featuredConcepts: [
                .laneSpecific(.chemistry, "state"),
                .laneSpecific(.chemistry, "property"),
                .laneSpecific(.chemistry, "mixture")
            ],
            isAvailable: false
        ),
        CapabilityLaneDescriptor(
            id: .electronics,
            symbolName: "lightbulb",
            ageBand: .future,
            promise: "Future: switches, circuits, sensors, and input/output systems.",
            defaultModes: [.explore, .challenge, .review],
            stages: [.concrete, .pictorial, .abstract, .recall, .quiz, .summary],
            featuredConcepts: [
                .laneSpecific(.electronics, "component"),
                .laneSpecific(.electronics, "circuit"),
                .laneSpecific(.electronics, "sensor")
            ],
            isAvailable: false
        ),
    ])
}
