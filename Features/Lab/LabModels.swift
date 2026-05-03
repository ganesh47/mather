import Foundation

enum ChildAgeBand: String, CaseIterable, Hashable {
    case toddler = "2–3"
    case preschool = "4–5"
    case earlyElementary = "6–7"
    case upperElementary = "8–10"
    case preteen = "11–12"

    var label: String { "Ages \(rawValue)" }
}

struct CapabilityAgeEntry: Identifiable, Equatable {
    var id: ChildAgeBand { ageBand }
    let ageBand: ChildAgeBand
    let posture: String
    let entryPlay: String

    var summaryLabel: String {
        "\(ageBand.label): \(entryPlay)"
    }
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

    var accessibilityLabel: String {
        "\(prompt), matches \(match)"
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

struct LaneRecallEntry: Identifiable, Equatable {
    let laneID: CapabilityLaneID
    let card: LearningCard

    var id: String { card.id }

    var title: String {
        card.prompt.displayText ?? card.prompt.speechText
    }

    var answerLabel: String {
        card.answer.displayText ?? card.answer.speechText
    }

    var choiceActions: [LaneRecallReviewAction] {
        card.choices.map { choice in
            LaneRecallReviewAction(
                laneID: laneID,
                cardID: card.id,
                choiceID: choice.id,
                isCorrect: choice.isCorrect
            )
        }
    }
}

struct LaneRecallReviewAction: Equatable {
    let laneID: CapabilityLaneID
    let cardID: String
    let choiceID: String
    let isCorrect: Bool
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
    case shapeGeometry
    case waterCycle
    case soundVolume
    case memoryMatch
    case fruitMemory
}

extension LabActivityID {
    var appRoute: AppRoute {
        switch self {
        case .sumSprint:
            return .sumSprint
        case .roomQuest:
            return .roomQuest
        case .symmetryFold:
            return .symmetryFold
        case .rectangleFactory:
            return .rectangleFactory
        case .factoryCards:
            return .factoryCards
        case .angleCannon:
            return .angleCannon
        case .twoFingerProtractor:
            return .twoFingerProtractor
        case .gravityArtist:
            return .gravityArtist
        case .compassAngles:
            return .compassAngles
        case .shapeGeometry:
            return .shapeGeometry
        case .waterCycle:
            return .waterCycle
        case .soundVolume:
            return .soundVolume
        case .memoryMatch, .fruitMemory:
            return .memory
        }
    }
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

    var accessibilityLabel: String {
        "\(title). \(tagline)"
    }

    var accessibilityHint: String {
        "Launches \(title). Modes: \(modes.map(\.rawValue).joined(separator: ", "))."
    }
}

enum LabSensorNeed: CaseIterable, Equatable {
    case noSpecialSensor
    case motion
    case compass
    case cameraMarkerMode
    case haptics

    func isAvailable(with capabilities: DeviceSensorCapabilities) -> Bool {
        switch self {
        case .noSpecialSensor:
            return true
        case .motion:
            return capabilities.supportsMotion
        case .compass:
            return capabilities.supportsHeading
        case .cameraMarkerMode:
            return capabilities.supportsCamera
        case .haptics:
            return capabilities.supportsHaptics
        }
    }

    func copy(with capabilities: DeviceSensorCapabilities) -> LabSensorAffordance {
        let available = isAvailable(with: capabilities)
        switch self {
        case .noSpecialSensor:
            return LabSensorAffordance(
                need: self,
                isAvailable: true,
                label: "No special sensor needed",
                fallback: nil
            )
        case .motion:
            return LabSensorAffordance(
                need: self,
                isAvailable: available,
                label: available ? "Motion ready" : "Motion unavailable",
                fallback: available ? nil : "Touch fallback available"
            )
        case .compass:
            return LabSensorAffordance(
                need: self,
                isAvailable: available,
                label: available ? "Compass ready" : "Compass unavailable",
                fallback: available ? nil : "Use on-screen turns"
            )
        case .cameraMarkerMode:
            return LabSensorAffordance(
                need: self,
                isAvailable: available,
                label: available ? "Camera marker mode ready" : "Camera marker mode unavailable",
                fallback: available ? nil : "Use tap-to-place stations"
            )
        case .haptics:
            return LabSensorAffordance(
                need: self,
                isAvailable: available,
                label: available ? "Haptics ready" : "Haptics unavailable",
                fallback: available ? nil : "Visual feedback stays available"
            )
        }
    }
}

struct LabSensorAffordance: Identifiable, Equatable {
    var id: LabSensorNeed { need }
    let need: LabSensorNeed
    let isAvailable: Bool
    let label: String
    let fallback: String?

    var displayLabel: String {
        guard let fallback else { return label }
        return "\(label): \(fallback)"
    }

    var accessibilityLabel: String {
        displayLabel
    }

    var accessibilityHint: String {
        if need == .noSpecialSensor {
            return "Works with touch only."
        }
        if isAvailable {
            return "Sensor is ready for this activity."
        }
        guard let fallback else {
            return "This activity still works without extra setup."
        }
        return fallback
    }
}

enum LabLaneCardSection: Equatable {
    case visualSummary
    case promise
    case progressStatus
    case modes
    case playStyles
    case ageEntries
    case recall
    case activities
    case comingSoon
}

struct LabLaneCardPresentation: Equatable {
    let laneID: CapabilityLaneID
    let title: String
    let promiseLine: String
    let progressMicrocopy: String
    let openAffordanceLabel: String
    let accessibilityLabel: String
    let accessibilityHint: String
    let sections: [LabLaneCardSection]

    init(lane: CapabilityLane, progress: CapabilityLaneProgress) {
        self.laneID = lane.id
        title = lane.title
        promiseLine = lane.promise
        progressMicrocopy = "\(progress.progressSummaryLabel) • \(progress.nextRecommendedModeLabel)"
        openAffordanceLabel = "Enter world"
        accessibilityLabel = "\(lane.title). \(lane.ageBandHint). \(lane.promise)"
        accessibilityHint = "Opens \(lane.title) to choose missions, review cards, play styles, and sensor options."
        sections = [
            .visualSummary,
            .promise,
            .progressStatus,
        ]
    }

    var showsDetails: Bool {
        sections.contains(.activities) || sections.contains(.comingSoon)
    }
}

struct LabLaneDetailPresentation: Equatable {
    let laneID: CapabilityLaneID
    let title: String
    let activityCountLabel: String
    let sections: [LabLaneCardSection]

    init(lane: CapabilityLane) {
        laneID = lane.id
        title = lane.title
        activityCountLabel = lane.activities.isEmpty
            ? "Games coming soon"
            : "\(lane.activities.count) game\(lane.activities.count == 1 ? "" : "s") ready"
        sections = [
            .visualSummary,
            lane.isReady ? .activities : .comingSoon,
            .modes,
            .playStyles,
            .ageEntries,
            .recall,
        ]
    }
}

extension LabActivityID {
    var sensorNeeds: [LabSensorNeed] {
        switch self {
        case .sumSprint, .rectangleFactory, .factoryCards, .twoFingerProtractor, .shapeGeometry, .waterCycle, .soundVolume, .memoryMatch, .fruitMemory:
            return [.noSpecialSensor]
        case .symmetryFold, .angleCannon, .gravityArtist:
            return [.motion]
        case .roomQuest:
            return [.cameraMarkerMode, .haptics]
        case .compassAngles:
            return [.compass]
        }
    }

    func sensorAffordances(with capabilities: DeviceSensorCapabilities) -> [LabSensorAffordance] {
        sensorNeeds.map { $0.copy(with: capabilities) }
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

    init(masteryState: LaneMasteryState) {
        self.init(
            laneID: masteryState.id,
            availableModes: masteryState.availableModes,
            completedModes: masteryState.completedModes,
            reviewedCardIDs: masteryState.reviewedCardIDs
        )
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
        "🚀 \(completedModeCount)/\(availableModes.count) missions unlocked"
    }

    var nextRecommendedModeLabel: String {
        guard let nextRecommendedMode else { return "⭐ Choose any mission" }
        return completedModeCount == 0
            ? "⭐ First \(nextRecommendedMode.rawValue) mission waiting"
            : "⭐ Try \(nextRecommendedMode.rawValue) next"
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
    let ageEntries: [CapabilityAgeEntry]
    let activities: [LabActivity]

    var title: String { id.title }
    var isReady: Bool { !activities.isEmpty }

    var accessibilityLabel: String {
        "\(title). \(ageBandHint). \(promise)"
    }

    var accessibilityHint: String {
        isReady ? "Choose an activity or review cards." : "Activities are coming soon. Review cards are available."
    }

    var ageEntryPreview: String {
        ageEntries.prefix(2).map(\.summaryLabel).joined(separator: " • ")
    }

    var modeChoiceCards: [PlayModeChoiceCard] {
        TimerChallengePolicy.choiceCards(for: modes)
    }

    var modeChoicePreviewLabel: String {
        modeChoiceCards.prefix(2).map(\.summaryLabel).joined(separator: " • ")
    }

    var starterMixMatchCards: [MixMatchCard] {
        Self.starterMixMatchCardsByLane[id, default: []]
    }

    var recallEntries: [LaneRecallEntry] {
        Self.starterLearningCardProvider
            .starterCards(for: id)
            .map { LaneRecallEntry(laneID: id, card: $0) }
    }

    var firstRecallEntry: LaneRecallEntry? {
        recallEntries.first
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
        let learningCardCount = recallEntries.count
        guard learningCardCount > 0 else {
            return "\(starterMixMatchCount) Mix-Match cards ready"
        }
        return "\(learningCardCount) recall card + \(starterMixMatchCount) Mix-Match ready"
    }

    var recallAccessibilityLabel: String {
        "\(title) recall. \(recallReadinessLabel). Concepts: \(starterMixMatchConceptPreview)"
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
            ageEntries: [
                CapabilityAgeEntry(ageBand: .preschool, posture: "count and pair", entryPlay: "Bond Blast pairs"),
                CapabilityAgeEntry(ageBand: .earlyElementary, posture: "CPA number bonds", entryPlay: "Make & Break"),
                CapabilityAgeEntry(ageBand: .upperElementary, posture: "strategy and factors", entryPlay: "arrays and races"),
                CapabilityAgeEntry(ageBand: .preteen, posture: "mastery and mental math", entryPlay: "personal-best challenges"),
            ],
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
            ageEntries: [
                CapabilityAgeEntry(ageBand: .preschool, posture: "shape discovery", entryPlay: "shape sort"),
                CapabilityAgeEntry(ageBand: .earlyElementary, posture: "fold and compare", entryPlay: "symmetry play"),
                CapabilityAgeEntry(ageBand: .upperElementary, posture: "measure and transform", entryPlay: "angles and arrays"),
                CapabilityAgeEntry(ageBand: .preteen, posture: "systems and coordinates", entryPlay: "puzzle challenges"),
            ],
            activities: [
                LabActivity(
                    id: .shapeGeometry,
                    emoji: "🔷",
                    title: "Shape Lab",
                    tagline: "Learn shape names, clues, and picture matches",
                    modes: [.learn, .review]
                ),
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
            promise: "Predict motion, gravity, water, sound, and cause-and-effect systems.",
            ageBandHint: "Ages 2–12",
            modes: [.explore, .challenge, .review],
            ageEntries: [
                CapabilityAgeEntry(ageBand: .toddler, posture: "cause and effect", entryPlay: "tap, drop, splash"),
                CapabilityAgeEntry(ageBand: .preschool, posture: "predict and observe", entryPlay: "roll and rain"),
                CapabilityAgeEntry(ageBand: .upperElementary, posture: "forces and systems", entryPlay: "cannon strategy"),
                CapabilityAgeEntry(ageBand: .preteen, posture: "model and explain", entryPlay: "energy puzzles"),
            ],
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
                LabActivity(
                    id: .soundVolume,
                    emoji: "🔊",
                    title: "Sound Lab",
                    tagline: "Match quiet, noisy, and safe listening clues",
                    modes: [.learn, .review]
                ),
            ]
        ),
        CapabilityLane(
            id: .mapWorld,
            emoji: "🗺️",
            promise: "Use rooms, compass turns, direction words, and route clues.",
            ageBandHint: "Ages 4–12",
            modes: [.explore, .challenge, .timed, .review],
            ageEntries: [
                CapabilityAgeEntry(ageBand: .preschool, posture: "left/right and finding", entryPlay: "room clues"),
                CapabilityAgeEntry(ageBand: .earlyElementary, posture: "directions and turns", entryPlay: "compass walk"),
                CapabilityAgeEntry(ageBand: .upperElementary, posture: "maps and scale", entryPlay: "route planning"),
                CapabilityAgeEntry(ageBand: .preteen, posture: "coordinates and strategy", entryPlay: "map challenges"),
            ],
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
            ageEntries: [
                CapabilityAgeEntry(ageBand: .toddler, posture: "name and notice", entryPlay: "big picture cards"),
                CapabilityAgeEntry(ageBand: .preschool, posture: "sort and match", entryPlay: "Mix-Match"),
                CapabilityAgeEntry(ageBand: .earlyElementary, posture: "facts and categories", entryPlay: "choice cards"),
                CapabilityAgeEntry(ageBand: .preteen, posture: "explain and connect", entryPlay: "systems cards"),
            ],
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
            promise: "Sort fruits by color, shape, smell, taste, and where they grow.",
            ageBandHint: "Ages 4–12",
            modes: [.learn, .review, .challenge],
            ageEntries: [
                CapabilityAgeEntry(ageBand: .preschool, posture: "material sorting", entryPlay: "color and texture"),
                CapabilityAgeEntry(ageBand: .earlyElementary, posture: "states and mixtures", entryPlay: "mix and separate"),
                CapabilityAgeEntry(ageBand: .upperElementary, posture: "properties and prediction", entryPlay: "safe reaction cards"),
                CapabilityAgeEntry(ageBand: .preteen, posture: "families and systems", entryPlay: "property puzzles"),
            ],
            activities: [
                LabActivity(
                    id: .fruitMemory,
                    emoji: "🍎",
                    title: "Fruit Memory Cards",
                    tagline: "Match fruits and learn shape, color, taste, smell, and places",
                    modes: [.learn, .review, .challenge]
                ),
            ]
        ),
        CapabilityLane(
            id: .electronics,
            emoji: "💡",
            promise: "Future: switches, circuits, sensors, and input/output systems.",
            ageBandHint: "Future lane",
            modes: [.explore, .challenge, .review],
            ageEntries: [
                CapabilityAgeEntry(ageBand: .preschool, posture: "switch and output", entryPlay: "light on/off"),
                CapabilityAgeEntry(ageBand: .earlyElementary, posture: "circuits and components", entryPlay: "wire paths"),
                CapabilityAgeEntry(ageBand: .upperElementary, posture: "debug and sensors", entryPlay: "input/output"),
                CapabilityAgeEntry(ageBand: .preteen, posture: "logic and systems", entryPlay: "gate puzzles"),
            ],
            activities: []
        ),
    ]

    static let starterLearningCardProvider = DeterministicStarterLearningCardProvider()

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
            MixMatchCard(laneID: .physics, concept: "sound", prompt: "whisper", match: "quiet"),
            MixMatchCard(laneID: .physics, concept: "sound", prompt: "busy road", match: "noise pollution"),
            MixMatchCard(laneID: .physics, concept: "hearing-safety", prompt: "headphones", match: "keep volume low"),
            MixMatchCard(laneID: .physics, concept: "hearing-safety", prompt: "siren", match: "protect ears"),
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
