import Foundation

struct WorldMapPoint: Codable, Equatable, Sendable {
    let x: Double
    let y: Double

    init(x: Double, y: Double) { self.x = x; self.y = y }

    init(from decoder: any Decoder) throws {
        var values = try decoder.unkeyedContainer()
        x = try values.decode(Double.self)
        y = try values.decode(Double.self)
    }

    func encode(to encoder: any Encoder) throws {
        var values = encoder.unkeyedContainer()
        try values.encode(x)
        try values.encode(y)
    }
}

enum WorldQuestContinent: String, Codable, CaseIterable, Sendable {
    case africa = "Africa", asia = "Asia", europe = "Europe"
    case northAmerica = "North America", southAmerica = "South America", oceania = "Oceania"
}

struct WorldQuestCountry: Codable, Identifiable, Equatable, Sendable {
    let id: String
    let name: String
    let continent: WorldQuestContinent
    let anchor: WorldMapPoint
    let longitude: Double
    let latitude: Double
    /// Source area in square degrees, used only to decide whether to show a location marker.
    let area: Double

    var locationDescription: String {
        "Location in \(continent.rawValue), near \(Int(abs(latitude).rounded())) degrees \(latitude >= 0 ? "north" : "south"), \(Int(abs(longitude).rounded())) degrees \(longitude >= 0 ? "east" : "west")"
    }
}

struct WorldMapFeature: Codable, Identifiable, Sendable {
    let id: String
    /// Exterior and interior rings use even-odd filling; components retain date-line cuts.
    let rings: [[WorldMapPoint]]
}

struct CountryCatalog: Codable, Sendable {
    let schemaVersion: Int
    let projection: String
    let aspectRatio: Double
    let boundaryViewpoint: String
    let sourceVersion: String
    let starterIDs: [String]
    let countries: [WorldQuestCountry]
    let features: [WorldMapFeature]

    enum ContentError: Error { case missingResource, invalidCatalog }

    static func load(bundle: Bundle = .main) throws -> CountryCatalog {
        guard let url = bundle.url(forResource: "world-quest-map", withExtension: "json") else {
            throw ContentError.missingResource
        }
        return try decode(Data(contentsOf: url))
    }

    static func decode(_ data: Data) throws -> CountryCatalog {
        let catalog = try JSONDecoder().decode(Self.self, from: data)
        try catalog.validate()
        return catalog
    }

    func validate() throws {
        let ids = Set(countries.map(\.id))
        let featureIDs = Set(features.map(\.id))
        guard schemaVersion == 1, countries.count == 195, ids.count == 195,
              starterIDs.count == 12, Set(starterIDs).count == 12, Set(starterIDs).isSubset(of: ids),
              features.count == featureIDs.count, ids.isSubset(of: featureIDs),
              aspectRatio.isFinite, aspectRatio > 1, boundaryViewpoint == "India",
              countries.allSatisfy({ !$0.name.isEmpty && Self.valid($0.anchor) && $0.area > 0 }),
              features.allSatisfy({ !$0.rings.isEmpty && $0.rings.allSatisfy {
                  $0.count >= 4 && $0.first == $0.last && $0.allSatisfy(Self.valid)
              } }) else { throw ContentError.invalidCatalog }
    }

    private static func valid(_ point: WorldMapPoint) -> Bool {
        point.x.isFinite && point.y.isFinite && (0...1).contains(point.x) && (0...1).contains(point.y)
    }

    func country(_ id: String) -> WorldQuestCountry? { countries.first { $0.id == id } }

    func countries(in pack: WorldQuestPack) -> [WorldQuestCountry] {
        switch pack {
        case .starter: countries.filter { starterIDs.contains($0.id) }
        case .world: countries
        default: countries.filter { $0.continent.rawValue == pack.rawValue }
        }
    }
}

enum WorldQuestPack: String, Codable, CaseIterable, Identifiable, Sendable {
    case starter = "Starter", africa = "Africa", asia = "Asia", europe = "Europe"
    case northAmerica = "North America", southAmerica = "South America", oceania = "Oceania", world = "Whole World"
    var id: String { rawValue }
}

enum WorldQuestMode: String, Codable, CaseIterable, Identifiable, Sendable {
    case explore = "Explore", practice = "Practice", timed = "Timed"
    var id: String { rawValue }
    var detail: String {
        switch self {
        case .explore: "Discover country names and places"
        case .practice: "Find 10 countries at your own pace"
        case .timed: "20 seconds to find each country"
        }
    }
}

enum WorldQuestOutcome: String, Codable, Sendable { case independent, assisted, revealed }

struct WorldQuestAnswer: Codable, Equatable, Sendable {
    let countryID: String
    let outcome: WorldQuestOutcome
    let attempts: Int
    let seconds: Double
}

struct WorldQuestSession: Codable, Identifiable, Sendable {
    let id: UUID
    let pack: WorldQuestPack
    let mode: WorldQuestMode
    let answers: [WorldQuestAnswer]
    let completedAt: Date

    var independentCount: Int { answers.filter { $0.outcome == .independent }.count }
    var assistedCount: Int { answers.filter { $0.outcome == .assisted }.count }
    var revealedCount: Int { answers.filter { $0.outcome == .revealed }.count }
    var firstTryCount: Int { answers.filter { $0.outcome == .independent && $0.attempts == 1 }.count }
    var meanSuccessfulSeconds: Double? {
        let successful = answers.filter { $0.outcome != .revealed }
        return successful.isEmpty ? nil : successful.map(\.seconds).reduce(0, +) / Double(successful.count)
    }
}

/// SplitMix64 gives reproducible shuffles on all supported platforms.
struct WorldQuestRandom: RandomNumberGenerator {
    var state: UInt64
    mutating func next() -> UInt64 {
        state &+= 0x9e3779b97f4a7c15
        var value = state
        value = (value ^ (value >> 30)) &* 0xbf58476d1ce4e5b9
        value = (value ^ (value >> 27)) &* 0x94d049bb133111eb
        return value ^ (value >> 31)
    }
}
