import Foundation

/// Stable identifiers for Explorer Lab capability lanes.
enum CapabilityLaneID: String, CaseIterable, Codable, Hashable, Sendable {
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

    var shortTitle: String {
        switch self {
        case .numbers:
            return "Numbers"
        case .geometry:
            return "Geometry"
        case .physics:
            return "Physics"
        case .mapWorld:
            return "Map & World"
        case .discoveryCards:
            return "Discovery"
        case .chemistry:
            return "Chemistry"
        case .electronics:
            return "Electronics"
        }
    }
}

enum PlayMode: String, CaseIterable, Codable, Hashable, Sendable {
    case learn = "Learn"
    case explore = "Explore"
    case challenge = "Challenge"
    case timed = "Timed"
    case review = "Review"
}

enum LaneStage: String, CaseIterable, Codable, Hashable, Sendable {
    case concrete
    case pictorial
    case abstract
    case recall
    case quiz
    case transfer
    case summary

    var displayName: String {
        switch self {
        case .concrete:
            return "Concrete"
        case .pictorial:
            return "Pictorial"
        case .abstract:
            return "Abstract"
        case .recall:
            return "Recall"
        case .quiz:
            return "Quiz"
        case .transfer:
            return "Transfer"
        case .summary:
            return "Summary"
        }
    }
}

enum AgeBand: String, CaseIterable, Codable, Hashable, Sendable {
    case preschool
    case earlyElementary
    case elementary
    case mixed
    case future

    var displayName: String {
        switch self {
        case .preschool:
            return "Ages 2-5"
        case .earlyElementary:
            return "Ages 4-7"
        case .elementary:
            return "Ages 6-12"
        case .mixed:
            return "Ages 4-12"
        case .future:
            return "Future lane"
        }
    }
}

/// Open-ended concept identifier for lane-specific content.
///
/// Keep this as a string wrapper so new concepts can be added in each lane
/// without changing a central enum.
struct ConceptId: RawRepresentable, Codable, Hashable, Sendable, ExpressibleByStringLiteral {
    let rawValue: String

    init(rawValue: String) {
        precondition(!rawValue.isEmpty, "ConceptId should not be empty.")
        self.rawValue = rawValue
    }

    init(stringLiteral value: StringLiteralType) {
        self.init(rawValue: value)
    }
}

extension ConceptId {
    static func laneSpecific(_ lane: CapabilityLaneID, _ localID: String) -> ConceptId {
        ConceptId(rawValue: "\(lane.rawValue).\(localID)")
    }
}
