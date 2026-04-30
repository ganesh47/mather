import Foundation

enum ConceptConfidence: String, CaseIterable, Codable, Hashable, Comparable {
    case introduced
    case practicing
    case steady
    case mastered

    var score: Double {
        switch self {
        case .introduced: return 0.25
        case .practicing: return 0.5
        case .steady: return 0.75
        case .mastered: return 1
        }
    }

    static func < (lhs: ConceptConfidence, rhs: ConceptConfidence) -> Bool {
        lhs.score < rhs.score
    }
}

struct LaneMasteryState: Equatable, Codable, Identifiable {
    let id: CapabilityLaneID
    var availableModes: [PlayMode]
    var completedModes: Set<PlayMode>
    var reviewedCardIDs: Set<String>
    var conceptConfidence: [ConceptId: ConceptConfidence]

    init(
        laneID: CapabilityLaneID,
        availableModes: [PlayMode],
        completedModes: Set<PlayMode> = [],
        reviewedCardIDs: Set<String> = [],
        conceptConfidence: [ConceptId: ConceptConfidence] = [:]
    ) {
        self.id = laneID
        self.availableModes = availableModes
        self.completedModes = completedModes
        self.reviewedCardIDs = reviewedCardIDs
        self.conceptConfidence = conceptConfidence
    }

    var completedModeCount: Int {
        availableModes.filter { completedModes.contains($0) }.count
    }

    var masteryFraction: Double {
        let modeFraction: Double
        if availableModes.isEmpty {
            modeFraction = 0
        } else {
            modeFraction = Double(completedModeCount) / Double(availableModes.count)
        }

        guard !conceptConfidence.isEmpty else { return modeFraction }
        let conceptAverage = conceptConfidence.values.map(\.score).reduce(0, +) / Double(conceptConfidence.count)
        return (modeFraction + conceptAverage) / 2
    }

    var progressLabel: String {
        "\(completedModeCount) / \(availableModes.count) modes"
    }

    var masteryPercentLabel: String {
        "\(Int((masteryFraction * 100).rounded()))% ready"
    }

    var nextRecommendedMode: PlayMode? {
        availableModes.first { !completedModes.contains($0) } ?? availableModes.last
    }

    mutating func markCompleted(_ mode: PlayMode) {
        guard availableModes.contains(mode) else { return }
        completedModes.insert(mode)
    }

    mutating func markReviewedCard(id cardID: String) {
        reviewedCardIDs.insert(cardID)
    }

    mutating func setConfidence(_ confidence: ConceptConfidence, for conceptID: ConceptId) {
        conceptConfidence[conceptID] = confidence
    }
}

struct ExplorerLabMasteryProfile: Equatable, Codable {
    var lanes: [CapabilityLaneID: LaneMasteryState]

    init(lanes: [CapabilityLaneID: LaneMasteryState] = [:]) {
        self.lanes = lanes
    }

    subscript(laneID: CapabilityLaneID) -> LaneMasteryState? {
        get { lanes[laneID] }
        set { lanes[laneID] = newValue }
    }

    mutating func ensureLane(_ descriptor: CapabilityLaneDescriptor) -> LaneMasteryState {
        if let existing = lanes[descriptor.id] {
            return existing
        }

        let state = LaneMasteryState(
            laneID: descriptor.id,
            availableModes: descriptor.supportedPlayModes,
            conceptConfidence: Dictionary(uniqueKeysWithValues: descriptor.starterConcepts.map { ($0, .introduced) })
        )
        lanes[descriptor.id] = state
        return state
    }

    static func emptyExplorerProfile() -> ExplorerLabMasteryProfile {
        var profile = ExplorerLabMasteryProfile()
        for descriptor in CapabilityLaneRegistry.all {
            _ = profile.ensureLane(descriptor)
        }
        return profile
    }
}
