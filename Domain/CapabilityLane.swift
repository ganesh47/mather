import Foundation
import SwiftUI

/// Top-level capability lanes used by Explorer Lab.
///
/// The lab groups activities by the capability a child is growing instead of
/// presenting every mini-game as an unrelated destination.
enum CapabilityLaneID: String, CaseIterable, Codable, Hashable, Identifiable {
    case numbers
    case geometry
    case physics
    case mapWorld
    case discoveryCards
    case chemistry
    case electronics

    var id: String { rawValue }

    var title: String {
        switch self {
        case .numbers:
            return "Numbers Lab"
        case .geometry:
            return "Geometry Lab"
        case .physics:
            return "Physics Lab"
        case .mapWorld:
            return "Geography Lab"
        case .discoveryCards:
            return "Discovery Cards"
        case .chemistry:
            return "Chemistry Lab"
        case .electronics:
            return "Electronics Lab"
        }
    }
}

enum PlayMode: String, CaseIterable, Codable, Hashable, Identifiable {
    case learn = "Learn"
    case explore = "Explore"
    case challenge = "Challenge"
    case timed = "Timed"
    case review = "Review"

    var id: String { rawValue }
}

enum LaneStage: String, CaseIterable, Codable, Hashable, Identifiable {
    case concrete
    case pictorial
    case abstract
    case transfer
    case review

    var id: String { rawValue }

    var title: String {
        switch self {
        case .concrete:
            return "Concrete"
        case .pictorial:
            return "Pictorial"
        case .abstract:
            return "Abstract"
        case .transfer:
            return "Transfer"
        case .review:
            return "Review"
        }
    }
}

enum AgeBand: String, CaseIterable, Codable, Hashable, Identifiable {
    case ages2To12
    case ages4To12
    case future

    var id: String { rawValue }

    var displayLabel: String {
        switch self {
        case .ages2To12:
            return "Ages 2-12"
        case .ages4To12:
            return "Ages 4-12"
        case .future:
            return "Future lane"
        }
    }
}

extension CapabilityLaneID {
    /// Semantic theme color for this lane, shared across all Lab views.
    var themeColor: Color {
        switch self {
        case .numbers: MatherTheme.warm
        case .geometry: MatherTheme.coral
        case .physics: MatherTheme.panelDeep
        case .mapWorld: MatherTheme.softBlue
        case .discoveryCards, .electronics: MatherTheme.accent
        case .chemistry: MatherTheme.warm
        }
    }
}

struct ConceptId: RawRepresentable, ExpressibleByStringLiteral, Codable, Hashable, Identifiable {
    let rawValue: String

    init(rawValue: String) {
        self.rawValue = rawValue
    }

    init(stringLiteral value: String) {
        self.init(rawValue: value)
    }

    var id: String { rawValue }
}

