import Foundation

enum MemoryAdventure: String, CaseIterable, Identifiable {
    case busyBuilders, rescueCrew, spaceTrip

    var id: String { rawValue }

    var title: String {
        switch self {
        case .busyBuilders: "Busy Builders"
        case .rescueCrew: "Rescue Crew"
        case .spaceTrip: "Space Trip"
        }
    }

    var introduction: String {
        switch self {
        case .busyBuilders: "Let's build together! Find the matching machines at our busy building site."
        case .rescueCrew: "Our helping team is ready! Find the matching rescue vehicles."
        case .spaceTrip: "Ready for a space trip? Find the matching planets as we explore the solar system."
        }
    }

    var deckKind: MemoryDeckKind { self == .spaceTrip ? .planets : .vehicles }

    var cardIDs: [String] {
        switch self {
        case .busyBuilders:
            ["excavator", "bulldozer", "dump-truck", "concrete-mixer-truck", "mobile-crane", "wheel-loader"]
        case .rescueCrew:
            ["fire-engine", "ambulance", "police-car", "rescue-helicopter", "tow-truck"]
        case .spaceTrip:
            ["planet-mercury", "planet-venus", "planet-earth", "planet-mars", "planet-jupiter", "planet-saturn", "planet-uranus", "planet-neptune"]
        }
    }

    var cards: [MemoryAnimal] {
        cards(from: MemoryDeck.animals(for: deckKind))
    }

    func cards(from availableCards: [MemoryAnimal]) -> [MemoryAnimal] {
        let catalog = Dictionary(uniqueKeysWithValues: availableCards.map { ($0.id, $0) })
        return cardIDs.compactMap { catalog[$0] }
    }

    var sceneAssetName: String {
        switch self {
        case .busyBuilders: "MemoryAdventureBuilders"
        case .rescueCrew: "MemoryAdventureRescue"
        case .spaceTrip: "MemoryAdventureSpace"
        }
    }

    var celebration: String {
        switch self {
        case .busyBuilders: "Teamwork! Every machine has found its partner."
        case .rescueCrew: "Hooray for helpers! Your rescue crew is together."
        case .spaceTrip: "Stellar matching! You've explored a sky full of planets."
        }
    }

    var tryIt: String {
        switch self {
        case .busyBuilders: "Try it! Make your hand a digging bucket. Scoop, lift, and tip!"
        case .rescueCrew: "Try it! Stretch your arms like a helicopter and make a gentle whup-whup sound."
        case .spaceTrip: "Try it! Draw Saturn's rings in the air with your finger."
        }
    }
}
