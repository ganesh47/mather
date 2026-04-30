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

struct CapabilityLane: Identifiable, Equatable {
    let id: CapabilityLaneID
    let emoji: String
    let promise: String
    let ageBandHint: String
    let modes: [PlayMode]
    let activities: [LabActivity]

    var title: String { id.title }
    var isReady: Bool { !activities.isEmpty }

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
}
