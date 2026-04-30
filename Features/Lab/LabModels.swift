import Foundation

/// Top-level capability lanes used by Explorer Lab.
///
/// The lab intentionally groups activities by the capability a child is growing,
/// instead of presenting every mini-game as an unrelated destination.
enum CapabilityLaneID: String, CaseIterable, Hashable {
    case numbers
    case geometry
    case physics
    case mapWorld
    case discoveryCards
    case chemistry
    case electronics

    var title: String {
        switch self {
        case .numbers:
            return "Numbers Lab"
        case .geometry:
            return "Geometry Lab"
        case .physics:
            return "Physics Lab"
        case .mapWorld:
            return "Map & World Lab"
        case .discoveryCards:
            return "Discovery Cards"
        case .chemistry:
            return "Chemistry Lab"
        case .electronics:
            return "Electronics Lab"
        }
    }
}

enum PlayMode: String, CaseIterable, Hashable {
    case learn = "Learn"
    case explore = "Explore"
    case challenge = "Challenge"
    case timed = "Timed"
    case review = "Review"
}


struct MixMatchCard: Identifiable, Equatable {
    var id: String { "\(laneID.rawValue)-\(concept)-\(prompt)" }
    let laneID: CapabilityLaneID
    let concept: String
    let prompt: String
    let match: String

    init(laneID: CapabilityLaneID, concept: String, prompt: String, match: String) {
        self.laneID = laneID
        self.concept = concept
        self.prompt = prompt
        self.match = match
    }
}


struct MixMatchReviewSampler: Equatable {
    let laneID: CapabilityLaneID
    let cards: [MixMatchCard]
    private(set) var currentIndex: Int

    init(laneID: CapabilityLaneID, cards: [MixMatchCard], currentIndex: Int = 0) {
        self.laneID = laneID
        self.cards = cards
        if cards.isEmpty {
            self.currentIndex = 0
        } else {
            self.currentIndex = min(max(currentIndex, 0), cards.count - 1)
        }
    }

    var currentCard: MixMatchCard? {
        guard cards.indices.contains(currentIndex) else { return nil }
        return cards[currentIndex]
    }

    var progressLabel: String {
        guard !cards.isEmpty else { return "0 / 0" }
        return "\(currentIndex + 1) / \(cards.count)"
    }

    mutating func advance() {
        guard !cards.isEmpty else { return }
        currentIndex = (currentIndex + 1) % cards.count
    }

    mutating func rewind() {
        guard !cards.isEmpty else { return }
        currentIndex = (currentIndex - 1 + cards.count) % cards.count
    }
}

enum LabActivityID: String, CaseIterable, Hashable {
    case sumSprint
    case roomQuest
    case symmetryFold
    case rectangleFactory
    case factoryCards
    case angleCannon
    case twoFingerProtractor
    case gravityArtist
    case compassAngles
    case waterCycle
    case memoryMatch
}

struct LabActivity: Identifiable, Equatable {
    let id: LabActivityID
    let emoji: String
    let title: String
    let tagline: String
    let modes: [PlayMode]

    init(id: LabActivityID, emoji: String, title: String, tagline: String, modes: [PlayMode]) {
        self.id = id
        self.emoji = emoji
        self.title = title
        self.tagline = tagline
        self.modes = modes
    }
}


struct CapabilityLaneProgress: Equatable {
    let laneID: CapabilityLaneID
    let availableModes: [PlayMode]
    var completedModes: Set<PlayMode>
    var reviewedCardIDs: Set<String>

    init(
        laneID: CapabilityLaneID,
        availableModes: [PlayMode],
        completedModes: Set<PlayMode> = [],
        reviewedCardIDs: Set<String> = []
    ) {
        self.laneID = laneID
        self.availableModes = availableModes
        self.completedModes = completedModes
        self.reviewedCardIDs = reviewedCardIDs
    }

    var completedModeCount: Int {
        availableModes.filter { completedModes.contains($0) }.count
    }

    var progressLabel: String {
        "\(completedModeCount) / \(availableModes.count) modes"
    }

    var masteryFraction: Double {
        guard !availableModes.isEmpty else { return 0 }
        return Double(completedModeCount) / Double(availableModes.count)
    }

    var masteryPercentLabel: String {
        "\(Int((masteryFraction * 100).rounded()))% ready"
    }

    var progressSummaryLabel: String {
        "\(progressLabel) • \(masteryPercentLabel)"
    }

    var nextRecommendedModeLabel: String {
        guard let nextRecommendedMode else { return "Choose any mode" }
        return "Try \(nextRecommendedMode.rawValue) next"
    }

    var nextRecommendedMode: PlayMode? {
        availableModes.first { !completedModes.contains($0) } ?? availableModes.last
    }

    mutating func markCompleted(_ mode: PlayMode) {
        guard availableModes.contains(mode) else { return }
        completedModes.insert(mode)
    }

    mutating func markReviewed(_ card: MixMatchCard) {
        guard card.laneID == laneID else { return }
        reviewedCardIDs.insert(card.id)
    }
}

struct CapabilityLane: Identifiable, Equatable {
    let id: CapabilityLaneID
    let emoji: String
    let promise: String
    let ageBandHint: String
    let modes: [PlayMode]
    let activities: [LabActivity]

    var title: String { id.title }
    var isReady: Bool { !activities.isEmpty }

    var starterMixMatchCards: [MixMatchCard] {
        Self.starterMixMatchCardsByLane[id, default: []]
    }

    var starterMixMatchCount: Int { starterMixMatchCards.count }

    var starterMixMatchConceptPreview: String {
        var seen: Set<String> = []
        let concepts = starterMixMatchCards.compactMap { card -> String? in
            guard !seen.contains(card.concept) else { return nil }
            seen.insert(card.concept)
            return card.concept
        }
        return concepts.prefix(3).joined(separator: " • ")
    }

    var recallReadinessLabel: String {
        "\(starterMixMatchCount) Mix-Match cards ready"
    }

    var starterMixMatchSampler: MixMatchReviewSampler {
        MixMatchReviewSampler(laneID: id, cards: starterMixMatchCards)
    }

    var emptyProgress: CapabilityLaneProgress {
        CapabilityLaneProgress(laneID: id, availableModes: modes)
    }

    static let defaultExplorerLanes: [CapabilityLane] = [
        CapabilityLane(
            id: .numbers,
            emoji: "🔢",
            promise: "Build number bonds, fast facts, arrays, and whole-part thinking.",
            ageBandHint: "Ages 4–12",
            modes: [.learn, .challenge, .timed, .review],
            activities: [
                LabActivity(
                    id: .sumSprint,
                    emoji: "⚡",
                    title: "Sum Sprint",
                    tagline: "Race through sums 11–20",
                    modes: [.challenge, .timed, .review]
                ),
                LabActivity(
                    id: .rectangleFactory,
                    emoji: "🏭",
                    title: "Rectangle Factory",
                    tagline: "Drag frames to find factors",
                    modes: [.learn, .explore, .challenge]
                ),
                LabActivity(
                    id: .factoryCards,
                    emoji: "📦",
                    title: "Packing Cards",
                    tagline: "Practice equal rows first",
                    modes: [.learn, .review]
                ),
            ]
        ),
        CapabilityLane(
            id: .geometry,
            emoji: "📐",
            promise: "Fold, measure, aim, and transform shapes with touch and motion.",
            ageBandHint: "Ages 4–12",
            modes: [.learn, .explore, .challenge, .review],
            activities: [
                LabActivity(
                    id: .symmetryFold,
                    emoji: "🪞",
                    title: "Symmetry Fold",
                    tagline: "Tilt to fold shapes in half",
                    modes: [.explore, .challenge]
                ),
                LabActivity(
                    id: .angleCannon,
                    emoji: "💥",
                    title: "Angle Cannon",
                    tagline: "Tilt to aim — hit the target",
                    modes: [.explore, .challenge, .timed]
                ),
                LabActivity(
                    id: .twoFingerProtractor,
                    emoji: "📐",
                    title: "Protractor",
                    tagline: "Spread two fingers to measure angles",
                    modes: [.learn, .explore]
                ),
            ]
        ),
        CapabilityLane(
            id: .physics,
            emoji: "🧪",
            promise: "Predict motion, gravity, water, and cause-and-effect systems.",
            ageBandHint: "Ages 2–12",
            modes: [.explore, .challenge, .review],
            activities: [
                LabActivity(
                    id: .gravityArtist,
                    emoji: "🎨",
                    title: "Gravity Artist",
                    tagline: "Predict where the ball lands",
                    modes: [.explore, .challenge]
                ),
                LabActivity(
                    id: .waterCycle,
                    emoji: "💧",
                    title: "Water Cycle Lab",
                    tagline: "Predict, make clouds, then rain",
                    modes: [.learn, .explore, .review]
                ),
            ]
        ),
        CapabilityLane(
            id: .mapWorld,
            emoji: "🗺️",
            promise: "Use rooms, compass turns, direction words, and route clues.",
            ageBandHint: "Ages 4–12",
            modes: [.explore, .challenge, .timed],
            activities: [
                LabActivity(
                    id: .roomQuest,
                    emoji: "🗺️",
                    title: "Room Quest",
                    tagline: "Collect tokens around the room",
                    modes: [.explore, .challenge]
                ),
                LabActivity(
                    id: .compassAngles,
                    emoji: "🧭",
                    title: "Compass Walk",
                    tagline: "Turn your body to match the angle",
                    modes: [.explore, .challenge, .timed]
                ),
            ]
        ),
        CapabilityLane(
            id: .discoveryCards,
            emoji: "🃏",
            promise: "Practice names, pictures, categories, and Mix-Match recall.",
            ageBandHint: "Ages 2–12",
            modes: [.learn, .review, .challenge],
            activities: [
                LabActivity(
                    id: .memoryMatch,
                    emoji: "🃏",
                    title: "Memory Match",
                    tagline: "Match pictures and words",
                    modes: [.learn, .review, .challenge]
                ),
            ]
        ),
        CapabilityLane(
            id: .chemistry,
            emoji: "⚗️",
            promise: "Future: sort materials, mix safely, and predict properties.",
            ageBandHint: "Future lane",
            modes: [.explore, .challenge, .review],
            activities: []
        ),
        CapabilityLane(
            id: .electronics,
            emoji: "💡",
            promise: "Future: switches, circuits, sensors, and input/output systems.",
            ageBandHint: "Future lane",
            modes: [.explore, .challenge, .review],
            activities: []
        ),
    ]

    static let starterMixMatchCardsByLane: [CapabilityLaneID: [MixMatchCard]] = [
        .numbers: [
            MixMatchCard(laneID: .numbers, concept: "number-bond", prompt: "6 + 4", match: "10"),
            MixMatchCard(laneID: .numbers, concept: "number-bond", prompt: "7 + 3", match: "10"),
            MixMatchCard(laneID: .numbers, concept: "number-bond", prompt: "8 + 5", match: "13"),
            MixMatchCard(laneID: .numbers, concept: "dot-pattern", prompt: "five-frame full", match: "5"),
            MixMatchCard(laneID: .numbers, concept: "dot-pattern", prompt: "ten-frame 8 dots", match: "8"),
            MixMatchCard(laneID: .numbers, concept: "array", prompt: "3 rows of 4", match: "12"),
            MixMatchCard(laneID: .numbers, concept: "factor-pair", prompt: "2 × 6", match: "12"),
            MixMatchCard(laneID: .numbers, concept: "story-equation", prompt: "9 birds, 2 fly away", match: "9 − 2 = 7"),
        ],
        .geometry: [
            MixMatchCard(laneID: .geometry, concept: "shape", prompt: "3 sides", match: "triangle"),
            MixMatchCard(laneID: .geometry, concept: "shape", prompt: "4 equal sides", match: "square"),
            MixMatchCard(laneID: .geometry, concept: "symmetry", prompt: "butterfly fold", match: "line of symmetry"),
            MixMatchCard(laneID: .geometry, concept: "angle", prompt: "square corner", match: "90°"),
            MixMatchCard(laneID: .geometry, concept: "angle", prompt: "straight line", match: "180°"),
            MixMatchCard(laneID: .geometry, concept: "array-shape", prompt: "2 by 5 rectangle", match: "10 squares"),
            MixMatchCard(laneID: .geometry, concept: "transformation", prompt: "slide", match: "translation"),
            MixMatchCard(laneID: .geometry, concept: "transformation", prompt: "turn", match: "rotation"),
        ],
        .physics: [
            MixMatchCard(laneID: .physics, concept: "motion", prompt: "push harder", match: "moves faster"),
            MixMatchCard(laneID: .physics, concept: "motion", prompt: "steeper ramp", match: "rolls farther"),
            MixMatchCard(laneID: .physics, concept: "gravity", prompt: "drop ball", match: "falls down"),
            MixMatchCard(laneID: .physics, concept: "prediction", prompt: "aim higher", match: "lands farther"),
            MixMatchCard(laneID: .physics, concept: "water-cycle", prompt: "sun warms water", match: "evaporation"),
            MixMatchCard(laneID: .physics, concept: "water-cycle", prompt: "cloud gets heavy", match: "rain"),
            MixMatchCard(laneID: .physics, concept: "float-sink", prompt: "wood block", match: "float"),
            MixMatchCard(laneID: .physics, concept: "balance", prompt: "same weight both sides", match: "level"),
        ],
        .mapWorld: [
            MixMatchCard(laneID: .mapWorld, concept: "direction", prompt: "sunrise", match: "east"),
            MixMatchCard(laneID: .mapWorld, concept: "direction", prompt: "sunset", match: "west"),
            MixMatchCard(laneID: .mapWorld, concept: "turn", prompt: "quarter turn right", match: "90° clockwise"),
            MixMatchCard(laneID: .mapWorld, concept: "turn", prompt: "half turn", match: "180°"),
            MixMatchCard(laneID: .mapWorld, concept: "route", prompt: "start → clue → treasure", match: "path"),
            MixMatchCard(laneID: .mapWorld, concept: "map-symbol", prompt: "star on map", match: "special place"),
            MixMatchCard(laneID: .mapWorld, concept: "scale", prompt: "small map step", match: "big real step"),
            MixMatchCard(laneID: .mapWorld, concept: "compass", prompt: "N", match: "north"),
        ],
        .discoveryCards: [
            MixMatchCard(laneID: .discoveryCards, concept: "animal", prompt: "striped big cat", match: "tiger"),
            MixMatchCard(laneID: .discoveryCards, concept: "animal", prompt: "long-neck animal", match: "giraffe"),
            MixMatchCard(laneID: .discoveryCards, concept: "habitat", prompt: "fish home", match: "water"),
            MixMatchCard(laneID: .discoveryCards, concept: "category", prompt: "apple", match: "fruit"),
            MixMatchCard(laneID: .discoveryCards, concept: "category", prompt: "bus", match: "vehicle"),
            MixMatchCard(laneID: .discoveryCards, concept: "body", prompt: "we hear with", match: "ears"),
            MixMatchCard(laneID: .discoveryCards, concept: "world", prompt: "very cold place", match: "Arctic"),
            MixMatchCard(laneID: .discoveryCards, concept: "vocabulary", prompt: "tiny", match: "small"),
        ],
        .chemistry: [
            MixMatchCard(laneID: .chemistry, concept: "state", prompt: "ice", match: "solid"),
            MixMatchCard(laneID: .chemistry, concept: "state", prompt: "water", match: "liquid"),
            MixMatchCard(laneID: .chemistry, concept: "state", prompt: "steam", match: "gas"),
            MixMatchCard(laneID: .chemistry, concept: "property", prompt: "metal spoon", match: "shiny"),
            MixMatchCard(laneID: .chemistry, concept: "property", prompt: "sponge", match: "soaks water"),
            MixMatchCard(laneID: .chemistry, concept: "mixture", prompt: "sand + pebbles", match: "can separate"),
            MixMatchCard(laneID: .chemistry, concept: "mixture", prompt: "sugar + water", match: "dissolves"),
            MixMatchCard(laneID: .chemistry, concept: "safety", prompt: "unknown liquid", match: "ask grown-up"),
        ],
        .electronics: [
            MixMatchCard(laneID: .electronics, concept: "component", prompt: "battery", match: "power"),
            MixMatchCard(laneID: .electronics, concept: "component", prompt: "wire", match: "path"),
            MixMatchCard(laneID: .electronics, concept: "component", prompt: "switch", match: "open or close"),
            MixMatchCard(laneID: .electronics, concept: "output", prompt: "lamp", match: "light"),
            MixMatchCard(laneID: .electronics, concept: "circuit", prompt: "closed loop", match: "works"),
            MixMatchCard(laneID: .electronics, concept: "circuit", prompt: "broken loop", match: "off"),
            MixMatchCard(laneID: .electronics, concept: "sensor", prompt: "microphone", match: "hears sound"),
            MixMatchCard(laneID: .electronics, concept: "logic", prompt: "two switches both on", match: "AND"),
        ],
    ]

}
