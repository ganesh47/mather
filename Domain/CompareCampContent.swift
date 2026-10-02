import Foundation

enum CompareCampRegion: String, CaseIterable, Identifiable, Codable, Sendable {
    case woodland, ocean, sky, space, travel, builders

    var id: String { rawValue }
    var title: String {
        switch self {
        case .woodland: return "Green Trail"
        case .ocean: return "Ocean Cove"
        case .sky: return "Bird Grove"
        case .space: return "Star Camp"
        case .travel: return "On the Move"
        case .builders: return "Builder Valley"
        }
    }
    var symbolName: String {
        switch self {
        case .woodland: return "leaf.fill"
        case .ocean: return "fish.fill"
        case .sky: return "bird.fill"
        case .space: return "sparkles"
        case .travel: return "car.fill"
        case .builders: return "hammer.fill"
        }
    }
    var categories: [CompareCampCategory] { CompareCampCategory.all.filter { $0.region == self } }
}

/// Artwork identifies the subject; the view renders one distinct tile per object.
/// Decorative scenery is never part of the evidence used to answer a question.
struct CompareCampCategory: Identifiable, Equatable, Codable, Sendable {
    let id: String
    let title: String
    let subtitle: String
    let region: CompareCampRegion
    let tokenName: String
    let tokenPlural: String
    let tokenSymbol: String
    let tokenEmoji: String?
    let tokenAssetName: String?
    let artAssetName: String
    let accentHex: String

    func quantityText(_ count: Int) -> String { "\(count) \(count == 1 ? tokenName : tokenPlural)" }

    static let all: [Self] = [
        camp("apple-orchard", "Apple Orchard", "Pack a picnic", .woodland, "apple", "apples", "apple.logo", "CompareCampApple", "F5AD6B"),
        camp("flower-garden", "Flower Garden", "Grow a colorful camp", .woodland, "flower", "flowers", "camera.macro", "CompareCampFlower", "F4A7C4"),
        camp("leaf-trail", "Leaf Trail", "Gather forest treasures", .woodland, "leaf", "leaves", "leaf.fill", "CompareCampLeaf", "9ED5A0"),
        camp("sheep-meadow", "Sheep Meadow", "Help the fluffy flock", .woodland, "sheep", "sheep", "pawprint.fill", "CompareCampSheep", "DDD5B2"),
        camp("clownfish-reef", "Clownfish Reef", "Meet bright reef friends", .ocean, "clownfish", "clownfish", "fish.fill", "MemoryFishClownfish", "F8AE76"),
        camp("goldfish-pond", "Goldfish Pond", "Make a splash", .ocean, "goldfish", "goldfish", "fish.fill", "MemoryFishGoldfish", "F9D574"),
        camp("seahorse-bay", "Seahorse Bay", "Visit curly-tailed friends", .ocean, "seahorse", "seahorses", "water.waves", "MemoryFishSeahorse", "9DDCE2"),
        camp("angelfish-lagoon", "Angelfish Lagoon", "Explore the calm lagoon", .ocean, "angelfish", "angelfish", "fish.fill", "MemoryFishAngelfish", "B8CFF4"),
        camp("macaw-canopy", "Macaw Canopy", "Find rainbow feathers", .sky, "macaw", "macaws", "bird.fill", "CompareCampMacaw", "F1B389"),
        camp("peafowl-garden", "Peafowl Garden", "Enjoy a feather parade", .sky, "peafowl", "peafowl", "bird.fill", "CompareCampPeafowl", "8DD1C1"),
        camp("flamingo-lake", "Flamingo Lake", "Visit the pink flock", .sky, "flamingo", "flamingos", "bird.fill", "CompareCampFlamingo", "EEACC7"),
        camp("puffin-cliffs", "Puffin Cliffs", "Look out over the sea", .sky, "puffin", "puffins", "bird.fill", "CompareCampPuffin", "B8D9EF"),
        camp("earth-workshop", "Earth Workshop", "Sort little planet models", .space, "Earth model", "Earth models", "globe.americas.fill", "MemoryPlanetEarth", "95C6F4"),
        camp("mars-workshop", "Mars Workshop", "Count red planet models", .space, "Mars model", "Mars models", "circle.fill", "MemoryPlanetMars", "F0A28C"),
        camp("jupiter-workshop", "Jupiter Workshop", "Explore striped models", .space, "Jupiter model", "Jupiter models", "circle.fill", "MemoryPlanetJupiter", "E3C294"),
        camp("saturn-workshop", "Saturn Workshop", "Count models with rings", .space, "Saturn model", "Saturn models", "sparkles", "MemoryPlanetSaturn", "DFCFAC"),
        camp("car-camp", "Car Camp", "Park a colorful convoy", .travel, "car", "cars", "car.fill", "MemoryVehicleCar", "F5AFA6"),
        camp("train-station", "Train Station", "All aboard the number trail", .travel, "train", "trains", "tram.fill", "MemoryVehicleTrain", "B6CAF8"),
        camp("boat-harbor", "Boat Harbor", "Bring the boats home", .travel, "boat", "boats", "sailboat.fill", "MemoryVehicleBoat", "8DD5E6"),
        camp("airplane-field", "Airplane Field", "Get ready to take off", .travel, "airplane", "airplanes", "airplane", "MemoryVehiclePlane", "BDD6EC"),
        camp("excavator-hill", "Excavator Hill", "Dig into a new adventure", .builders, "excavator", "excavators", "hammer.fill", "MemoryVehicleExcavator", "F8CF79"),
        camp("bulldozer-trail", "Bulldozer Trail", "Build a path together", .builders, "bulldozer", "bulldozers", "hammer.fill", "MemoryVehicleBulldozer", "EBC477"),
        camp("dump-truck-quarry", "Dump Truck Quarry", "Help the hauling crew", .builders, "dump truck", "dump trucks", "truck.box.fill", "MemoryVehicleDumpTruck", "F5B582"),
        camp("mixer-yard", "Mixer Yard", "Mix up some number fun", .builders, "mixer truck", "mixer trucks", "truck.box.fill", "MemoryVehicleConcreteMixerTruck", "B5D7BB")
    ]

    static var first: Self { all[0] }

    private static func camp(
        _ id: String, _ title: String, _ subtitle: String, _ region: CompareCampRegion,
        _ singular: String, _ plural: String, _ symbol: String, _ asset: String, _ accent: String
    ) -> Self {
        Self(id: id, title: title, subtitle: subtitle, region: region, tokenName: singular,
             tokenPlural: plural, tokenSymbol: symbol, tokenEmoji: nil, tokenAssetName: asset,
             artAssetName: asset, accentHex: accent)
    }
}

enum CompareCampDifficulty: String, CaseIterable, Identifiable, Codable, Sendable {
    case small, growing, big
    var id: String { rawValue }
    var maxCount: Int { self == .small ? 5 : self == .growing ? 10 : 20 }
    var title: String { self == .small ? "Little Steps" : self == .growing ? "Growing Explorer" : "Big Adventure" }
    var subtitle: String { "Groups from 0 to \(maxCount)" }
}

enum CompareCampActivity: String, CaseIterable, Identifiable, Codable, Sendable {
    case adventure, more, fewer, makeEqual, difference, symbols
    var id: String { rawValue }
    var title: String {
        switch self {
        case .adventure: return "Camp Adventure"
        case .more: return "Find More"
        case .fewer: return "Find Fewer"
        case .makeEqual: return "Make a Match"
        case .difference: return "How Many Extra?"
        case .symbols: return "Number Signs"
        }
    }
    var subtitle: String {
        switch self {
        case .adventure: return "Build, compare, discover"
        case .more: return "Find the bigger group"
        case .fewer: return "Find the smaller group"
        case .makeEqual: return "Add or remove to balance"
        case .difference: return "Pair up and count the extras"
        case .symbols: return "Connect groups to <, =, >"
        }
    }
    var symbolName: String {
        switch self {
        case .adventure: return "map.fill"
        case .more: return "plus.circle.fill"
        case .fewer: return "minus.circle.fill"
        case .makeEqual: return "equal.circle.fill"
        case .difference: return "square.stack.3d.up.fill"
        case .symbols: return "lessthan.circle.fill"
        }
    }
}

enum CompareCampStage: String, CaseIterable, Codable, Sendable {
    case concrete, pictorial, abstract, transfer
    var title: String {
        switch self {
        case .concrete: return "Build & Explore"
        case .pictorial: return "Picture & Compare"
        case .abstract: return "Number Discovery"
        case .transfer: return "Try Somewhere New"
        }
    }
}

enum CompareCampSide: String, Codable, Sendable { case left, right }

enum CompareCampRelation: String, CaseIterable, Codable, Sendable {
    case less, equal, greater
    var symbol: String { self == .less ? "<" : self == .equal ? "=" : ">" }
    var spokenName: String { self == .less ? "is less than" : self == .equal ? "is equal to" : "is greater than" }
    static func comparing(_ left: Int, _ right: Int) -> Self { left < right ? .less : left == right ? .equal : .greater }
}
