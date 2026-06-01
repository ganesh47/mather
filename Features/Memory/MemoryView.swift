import SwiftUI

// MARK: - Data model

enum MemoryPicture: Equatable {
    case emoji(String)
    case asset(String)
    case text(String)
}

struct MemoryFactCard: Equatable, Hashable {
    let title: String
    let value: String
}

enum MemoryDeckKind: String, Equatable, Hashable {
    case domesticAnimals
    case birds
    case vehicles
    case planets
    case fishes
    case countries
    case countryFlags
    case indiaStates
    case waterCycle
    case fruits
    case numberBondsTo10

    var displayName: String {
        switch self {
        case .domesticAnimals: return "Animals"
        case .birds: return "Birds"
        case .vehicles: return "Vehicles"
        case .planets: return "Planets"
        case .fishes: return "Fishes"
        case .countries: return "Countries & Capitals"
        case .countryFlags: return "Countries & Flags"
        case .indiaStates: return "Indian States & Capitals"
        case .waterCycle: return "Water Cycle"
        case .fruits: return "Fruits"
        case .numberBondsTo10: return "Number Bonds to 10"
        }
    }
}

struct MemoryCardMetadata: Equatable {
    let deck: MemoryDeckKind
    let category: String
    let kind: String
    let habitat: String?
    let lifespan: String?
    let weight: String?
    let size: String?
    let colors: String?
    let use: String?
    let movement: String?
    let sound: String?
    let factCards: [MemoryFactCard]

    init(
        deck: MemoryDeckKind,
        category: String,
        kind: String,
        habitat: String? = nil,
        lifespan: String? = nil,
        weight: String? = nil,
        size: String? = nil,
        colors: String? = nil,
        use: String? = nil,
        movement: String? = nil,
        sound: String? = nil,
        factCards: [MemoryFactCard]? = nil
    ) {
        self.deck = deck
        self.category = category
        self.kind = kind
        self.habitat = habitat
        self.lifespan = lifespan
        self.weight = weight
        self.size = size
        self.colors = colors
        self.use = use
        self.movement = movement
        self.sound = sound
        self.factCards = factCards ?? Self.defaultFactCards(
            kind: kind,
            habitat: habitat,
            lifespan: lifespan,
            weight: weight,
            size: size,
            colors: colors,
            use: use,
            movement: movement,
            sound: sound
        )
    }

    private static func defaultFactCards(
        kind: String,
        habitat: String?,
        lifespan: String?,
        weight: String?,
        size: String?,
        colors: String?,
        use: String?,
        movement: String?,
        sound: String?
    ) -> [MemoryFactCard] {
        var facts: [MemoryFactCard] = [MemoryFactCard(title: "Kind", value: kind)]
        func append(_ title: String, _ value: String?) {
            guard let value, !value.isEmpty else { return }
            facts.append(MemoryFactCard(title: title, value: value))
        }
        append("Home", habitat)
        append("Use", use)
        append("Moves", movement)
        append("Sound", sound)
        append("Lifespan", lifespan)
        append("Weight", weight)
        append("Size", size)
        append("Colors", colors)
        return facts
    }
}

struct MemoryLearningContent: Identifiable, Equatable {
    let animal: MemoryAnimal
    let title: String
    let shortDescription: String
    let factChips: [MemoryFactCard]
    let sourceBadge: String
    let readAloudText: String

    var id: String { animal.id }
}


struct MemoryImageAssetPlan: Equatable {
    enum Status: Equatable {
        case needsVettedSource
        case readyForAssetImport(sourceName: String, license: String)
    }

    let cardId: String
    let assetName: String
    let searchPrompt: String
    let styleNotes: String
    let status: Status
}

struct MemoryImageAssetProvenance: Equatable {
    let assetName: String
    let cardId: String
    let sourceName: String
    let creator: String
    let creditLine: String
    let license: String
    let licenseUrl: String
    let retrievedAt: String
    let originalFileName: String
    let originalSha256: String
    let derivativeFileName: String
    let derivativeSha256: String
    let derivativeChanges: String
    let licenseAllowsReuse: Bool
    let noThirdPartyRestrictionFound: Bool
    let noLogoOrEndorsementRisk: Bool
    let noPeopleOrPrivacyRisk: Bool
    let childCardLegibilityChecked: Bool
}

struct MemoryAnimal: Identifiable, Equatable {
    let id: String
    let name: String
    let canonicalName: String
    let picture: MemoryPicture
    let metadata: MemoryCardMetadata

    init(id: String, name: String, canonicalName: String? = nil, picture: MemoryPicture, metadata: MemoryCardMetadata) {
        self.id = id
        self.name = name
        self.canonicalName = canonicalName ?? name
        self.picture = picture
        self.metadata = metadata
    }

    var selectionKey: String {
        id
    }

    var detailCards: [MemoryFactCard] {
        metadata.factCards
    }

    var emoji: String? {
        guard case let .emoji(value) = picture else { return nil }
        return value
    }

    var imageAssetName: String? {
        guard case let .asset(value) = picture else { return nil }
        return value
    }
}

struct MemoryCard: Identifiable {
    enum Content {
        case picture(MemoryAnimal)
        case label(MemoryAnimal)
    }

    let id = UUID()
    let pairId: String
    let content: Content
    var isMatched: Bool = false
    var isSelected: Bool = false
}

struct MemoryArtStyle {
    let topColor: Color
    let bottomColor: Color
    let badgeColor: Color
    let badgeHighlight: Color
    let ornament: String
    let ornamentColor: Color
}

// MARK: - Decks

enum MemoryDeck {
    static let domesticAnimals: [MemoryAnimal] = [
        domesticAnimal("cow", name: "Cow", emoji: "🐄", habitat: "farms and grassy fields", colors: "black and white", sound: "gentle moo", movement: "walks on four sturdy legs"),
        domesticAnimal("dog", name: "Dog", emoji: "🐕", habitat: "homes, parks, and farms", colors: "many coat colors", sound: "happy bark", movement: "runs and plays quickly"),
        domesticAnimal("cat", name: "Cat", emoji: "🐈", habitat: "homes and gardens", colors: "many fur colors", sound: "soft meow", movement: "tiptoes and pounces"),
        domesticAnimal("sheep", name: "Sheep", emoji: "🐑", habitat: "farms and open pastures", colors: "white and cream", sound: "gentle baa", movement: "walks together in flocks"),
        domesticAnimal("pig", name: "Pig", emoji: "🐖", habitat: "barnyards and farms", colors: "pink, brown, or black", sound: "snort and oink", movement: "trots and roots around"),
        domesticAnimal("horse", name: "Horse", emoji: "🐎", habitat: "stables, ranches, and fields", colors: "brown, black, white, or chestnut", sound: "neigh", movement: "gallops fast"),
        domesticAnimal("rabbit", name: "Rabbit", emoji: "🐇", habitat: "gardens, meadows, and homes", colors: "white, brown, gray", sound: "quiet squeaks", movement: "hops with long back legs"),
        domesticAnimal("duck", name: "Duck", emoji: "🦆", habitat: "ponds, lakes, and farms", colors: "white, brown, or green", sound: "quack", movement: "waddles, swims, and flies short distances"),
        domesticAnimal("rooster", name: "Rooster", emoji: "🐓", habitat: "farmyards", colors: "red, gold, green", sound: "cock-a-doodle-doo", movement: "struts and flaps"),
        domesticAnimal("goat", name: "Goat", emoji: "🐐", habitat: "farms and rocky hills", colors: "white, brown, black", sound: "maa", movement: "climbs and balances well"),
        domesticAnimal("turkey", name: "Turkey", emoji: "🦃", habitat: "farms and woodlands", colors: "brown, bronze, black", sound: "gobble", movement: "walks with strong legs"),
        domesticAnimal("goldfish", name: "Goldfish", emoji: "🐟", habitat: "ponds and aquariums", colors: "orange and gold", sound: nil, movement: "swims with a swishy tail"),
        domesticAnimal("mouse", name: "Mouse", emoji: "🐁", habitat: "fields, barns, and homes", colors: "gray, brown, white", sound: "tiny squeak", movement: "scurries fast"),
        domesticAnimal("frog", name: "Frog", emoji: "🐸", habitat: "ponds, streams, and wet grass", colors: "green and brown", sound: "ribbit", movement: "jumps and swims"),
        domesticAnimal("camel", name: "Camel", emoji: "🐪", habitat: "deserts and dry plains", colors: "sand and tan", sound: "grumbly groan", movement: "walks far on long legs"),
        domesticAnimal("llama", name: "Llama", emoji: "🦙", habitat: "mountain farms and grasslands", colors: "white, brown, black", sound: "soft hum", movement: "walks sure-footedly"),
        domesticAnimal("donkey", name: "Donkey", emoji: "🫏", habitat: "farms and dry grasslands", colors: "gray or brown", sound: "hee-haw", movement: "walks steadily and carries loads"),
        domesticAnimal("ox", name: "Ox", emoji: "🐂", habitat: "farms and fields", colors: "brown, black, white", sound: "deep moo", movement: "pulls and plods with strength")
    ]

    static let birds: [MemoryAnimal] = [
        bird("bird-a01", name: "Macaw", asset: "MemoryBirdA01", home: "South American rainforests", lifespan: "40 to 50 years", weight: "0.9 to 1.2 kg", size: "80 to 90 cm long", colors: "red, yellow, blue"),
        bird("bird-a02", name: "Toucan", asset: "MemoryBirdA02", home: "Central and South American forests", lifespan: "15 to 20 years", weight: "0.3 to 0.5 kg", size: "50 to 60 cm long", colors: "black, yellow, orange"),
        bird("bird-a03", name: "Cockatoo", asset: "MemoryBirdA03", home: "Australia and nearby islands", lifespan: "40 to 70 years", weight: "0.8 to 1.0 kg", size: "45 to 55 cm long", colors: "white and yellow"),
        bird("bird-a04", name: "Hummingbird", asset: "MemoryBirdA04", home: "Tropical Americas", lifespan: "3 to 5 years", weight: "3 to 6 g", size: "8 to 12 cm long", colors: "green, purple, teal"),
        bird("bird-a05", name: "Blue Macaw", asset: "MemoryBirdA05", home: "South American forests", lifespan: "35 to 50 years", weight: "1.0 to 1.4 kg", size: "85 to 100 cm long", colors: "blue and gold"),
        bird("bird-a06", name: "Kingfisher", asset: "MemoryBirdA06", home: "Asian and Oceanian waterways", lifespan: "6 to 10 years", weight: "30 to 45 g", size: "16 to 20 cm long", colors: "blue and orange"),
        bird("bird-a07", name: "Sunbird", asset: "MemoryBirdA07", home: "South American cloud forests", lifespan: "3 to 5 years", weight: "4 to 7 g", size: "10 to 14 cm long", colors: "gold, orange, brown"),
        bird("bird-a08", name: "Pied Kingfisher", asset: "MemoryBirdA08", home: "Woodland streams in Africa and Asia", lifespan: "5 to 10 years", weight: "35 to 50 g", size: "18 to 22 cm long", colors: "blue, white, black"),
        bird("bird-a09", name: "Toucan", asset: "MemoryBirdA09", home: "Tropical South America", lifespan: "15 to 20 years", weight: "0.5 to 0.7 kg", size: "55 to 65 cm long", colors: "black, white, orange"),
        bird("bird-a10", name: "Parrot", asset: "MemoryBirdA10", home: "Tropical forests", lifespan: "20 to 30 years", weight: "0.2 to 0.4 kg", size: "25 to 35 cm long", colors: "green, yellow, red"),
        bird("bird-a11", name: "Palm Bird", asset: "MemoryBirdA11", home: "New Guinea and northern Australia", lifespan: "40 to 60 years", weight: "0.9 to 1.2 kg", size: "55 to 65 cm long", colors: "charcoal and red"),
        bird("bird-a12", name: "Flamingo", asset: "MemoryBirdA12", home: "Warm lakes and lagoons", lifespan: "20 to 30 years", weight: "2 to 3 kg", size: "100 to 140 cm tall", colors: "pink and coral"),
        bird("bird-a13", name: "Blue Bird", asset: "MemoryBirdA13", home: "Forest edges in tropical America", lifespan: "10 to 15 years", weight: "0.2 to 0.3 kg", size: "25 to 35 cm long", colors: "blue and gold"),
        bird("bird-a14", name: "Parrot", asset: "MemoryBirdA14", home: "Oceania rainforests", lifespan: "20 to 35 years", weight: "0.2 to 0.4 kg", size: "30 to 35 cm long", colors: "green and red"),
        bird("bird-a15", name: "Songbird", asset: "MemoryBirdA15", home: "Tropical gardens and forests", lifespan: "6 to 10 years", weight: "25 to 40 g", size: "15 to 18 cm long", colors: "green and yellow"),
        bird("bird-a16", name: "Hoopoe", asset: "MemoryBirdA16", home: "Africa, Europe, and Asia", lifespan: "8 to 10 years", weight: "45 to 90 g", size: "25 to 32 cm long", colors: "cinnamon, black, white"),
        bird("bird-a17", name: "Crested Bird", asset: "MemoryBirdA17", home: "Island forests", lifespan: "10 to 15 years", weight: "0.2 to 0.4 kg", size: "25 to 35 cm long", colors: "white, blue, silver"),
        bird("bird-a18", name: "Ibis", asset: "MemoryBirdA18", home: "South American wetlands", lifespan: "15 to 20 years", weight: "0.8 to 1.2 kg", size: "55 to 65 cm long", colors: "scarlet red"),
        bird("bird-b01", name: "Macaw", asset: "MemoryBirdB01", home: "South American rainforests", lifespan: "35 to 50 years", weight: "0.9 to 1.3 kg", size: "75 to 90 cm long", colors: "blue and gold"),
        bird("bird-b02", name: "Spoonbill", asset: "MemoryBirdB02", home: "American marshes and coasts", lifespan: "10 to 15 years", weight: "1.2 to 1.8 kg", size: "70 to 85 cm long", colors: "pink and white"),
        bird("bird-b03", name: "Finch", asset: "MemoryBirdB03", home: "Northern Australia", lifespan: "4 to 8 years", weight: "12 to 16 g", size: "12 to 14 cm long", colors: "green, yellow, purple"),
        bird("bird-b04", name: "Crowned Bird", asset: "MemoryBirdB04", home: "New Guinea forests", lifespan: "15 to 25 years", weight: "2.0 to 2.5 kg", size: "65 to 75 cm tall", colors: "blue and maroon"),
        bird("bird-b05", name: "Parrot", asset: "MemoryBirdB05", home: "South American forests", lifespan: "25 to 35 years", weight: "0.3 to 0.5 kg", size: "30 to 40 cm long", colors: "red and green"),
        bird("bird-b06", name: "Green Bird", asset: "MemoryBirdB06", home: "African forest canopies", lifespan: "8 to 12 years", weight: "0.2 to 0.4 kg", size: "30 to 40 cm long", colors: "emerald green"),
        bird("bird-b07", name: "Cockatoo", asset: "MemoryBirdB07", home: "Australia", lifespan: "30 to 50 years", weight: "0.5 to 0.8 kg", size: "40 to 50 cm long", colors: "white and yellow"),
        bird("bird-b08", name: "Parrotlet", asset: "MemoryBirdB08", home: "Dry forests of the Americas", lifespan: "8 to 12 years", weight: "25 to 35 g", size: "12 to 15 cm long", colors: "green and blue"),
        bird("bird-b09", name: "Golden Bird", asset: "MemoryBirdB09", home: "Asian mountain forests", lifespan: "6 to 10 years", weight: "0.6 to 0.8 kg", size: "90 to 110 cm long", colors: "gold, red, green"),
        bird("bird-b10", name: "Turaco", asset: "MemoryBirdB10", home: "African forests", lifespan: "10 to 15 years", weight: "0.2 to 0.4 kg", size: "35 to 45 cm long", colors: "green and crimson"),
        bird("bird-b11", name: "Peafowl", asset: "MemoryBirdB11", home: "India and Sri Lanka", lifespan: "15 to 20 years", weight: "4 to 6 kg", size: "90 to 115 cm body length", colors: "blue and emerald"),
        bird("bird-b12", name: "Green Bird", asset: "MemoryBirdB12", home: "Woodland edges", lifespan: "8 to 12 years", weight: "0.2 to 0.3 kg", size: "25 to 35 cm long", colors: "green and yellow"),
        bird("bird-b13", name: "Ibis", asset: "MemoryBirdB13", home: "Tropical wetlands", lifespan: "15 to 20 years", weight: "0.8 to 1.2 kg", size: "55 to 65 cm long", colors: "red and coral"),
        bird("bird-b14", name: "Pink Cockatoo", asset: "MemoryBirdB14", home: "Inland Australia", lifespan: "40 to 60 years", weight: "0.3 to 0.4 kg", size: "35 to 40 cm long", colors: "pink and white"),
        bird("bird-b15", name: "Peafowl", asset: "MemoryBirdB15", home: "Asian grasslands and gardens", lifespan: "15 to 20 years", weight: "3 to 5 kg", size: "85 to 100 cm body length", colors: "blue, green, bronze"),
        bird("bird-b16", name: "Puffin", asset: "MemoryBirdB16", home: "North Atlantic coasts", lifespan: "20 to 25 years", weight: "0.3 to 0.5 kg", size: "28 to 34 cm long", colors: "black, white, orange"),
        bird("bird-b17", name: "Black Palm", asset: "MemoryBirdB17", home: "New Guinea and Australia", lifespan: "40 to 60 years", weight: "0.8 to 1.1 kg", size: "55 to 65 cm long", colors: "charcoal and red"),
        bird("bird-b18", name: "Bee-eater", asset: "MemoryBirdB18", home: "Africa and South Asia", lifespan: "5 to 8 years", weight: "20 to 35 g", size: "20 to 25 cm long", colors: "green, blue, gold")
    ]

    static let vehicles: [MemoryAnimal] = [
        vehicle("car", name: "Car", emoji: "🚗", asset: "MemoryVehicleCar", use: "takes people on road trips", movement: "rolls on four wheels", colors: "many bright paint colors", sound: "vroom"),
        vehicle("bus", name: "Bus", emoji: "🚌", asset: "MemoryVehicleBus", use: "carries lots of people together", movement: "drives on roads with many seats", colors: "yellow, red, blue, green", sound: "rumbling engine"),
        vehicle("train", name: "Train", emoji: "🚂", asset: "MemoryVehicleTrain", use: "pulls people or cargo on tracks", movement: "rolls on rails", colors: "black, silver, red, blue", sound: "choo-choo"),
        vehicle("plane", name: "Plane", emoji: "✈️", asset: "MemoryVehiclePlane", use: "flies people across the sky", movement: "zooms with wings", colors: "white, blue, silver", sound: "whooshing jet sound"),
        vehicle("boat", name: "Boat", emoji: "⛵", asset: "MemoryVehicleBoat", use: "travels across water", movement: "floats and glides", colors: "white, blue, red", sound: "splashing water"),
        vehicle("bike", name: "Bike", emoji: "🚲", asset: "MemoryVehicleBike", use: "helps riders pedal from place to place", movement: "rolls on two wheels", colors: "red, blue, green, black", sound: "spinning wheels"),
        vehicle("truck", name: "Truck", emoji: "🚚", asset: "MemoryVehicleTruck", use: "hauls heavy things", movement: "drives with a strong engine", colors: "white, blue, red", sound: "deep engine rumble"),
        vehicle("tractor", name: "Tractor", emoji: "🚜", asset: "MemoryVehicleTractor", use: "helps farmers work in fields", movement: "rumbles over dirt with big tires", colors: "green, red, yellow", sound: "put-put engine"),
        vehicle("helicopter", name: "Copter", emoji: "🚁", asset: "MemoryVehicleHelicopter", use: "flies high and can hover", movement: "lifts with spinning blades", colors: "red, blue, white", sound: "whup-whup"),
        vehicle("rocket", name: "Rocket", emoji: "🚀", asset: "MemoryVehicleRocket", use: "blasts toward space", movement: "launches straight up fast", colors: "silver, white, red", sound: "roaring blast"),
        vehicle("scooter", name: "Scooter", emoji: "🛵", asset: "MemoryVehicleScooter", use: "zips around short city trips", movement: "rolls on two small wheels", colors: "red, teal, yellow", sound: "buzzy motor"),
        vehicle("taxi", name: "Taxi", emoji: "🚕", asset: "MemoryVehicleTaxi", use: "gives people rides around town", movement: "drives on busy roads", colors: "yellow and black", sound: "honk honk")
    ]

    static let vehicleImageAssetPlan: [MemoryImageAssetPlan] = [
        importedImagePlan("car", asset: "MemoryVehicleCar", prompt: "kid-friendly side-view car photo or illustration on a clean background", notes: "four wheels clearly visible; avoid brand logos and license plates", sourceName: "Project-owned deterministic drawing", license: "Project-owned"),
        importedImagePlan("bus", asset: "MemoryVehicleBus", prompt: "bright city or school bus, side view, clean background", notes: "large windows and wheels readable at card size", sourceName: "Project-owned deterministic drawing", license: "Project-owned"),
        importedImagePlan("train", asset: "MemoryVehicleTrain", prompt: "locomotive or passenger train on rails, three-quarter view", notes: "rails visible; keep silhouette distinct from bus", sourceName: "Project-owned deterministic drawing", license: "Project-owned"),
        importedImagePlan("plane", asset: "MemoryVehiclePlane", prompt: "airplane in flight or on runway with full wings visible", notes: "wide wing shape must remain legible in square crop", sourceName: "Project-owned deterministic drawing", license: "Project-owned"),
        importedImagePlan("boat", asset: "MemoryVehicleBoat", prompt: "small sailboat or motorboat on water, uncluttered scene", notes: "show waterline; avoid tiny distant boats", sourceName: "Project-owned deterministic drawing", license: "Project-owned"),
        importedImagePlan("bike", asset: "MemoryVehicleBike", prompt: "bicycle side view on clean background", notes: "two wheels and handlebar readable; no rider required", sourceName: "Project-owned deterministic drawing", license: "Project-owned"),
        importedImagePlan("truck", asset: "MemoryVehicleTruck", prompt: "box truck or delivery truck side view, clean background", notes: "large cargo box should distinguish it from car and bus", sourceName: "Project-owned deterministic drawing", license: "Project-owned"),
        importedImagePlan("tractor", asset: "MemoryVehicleTractor", prompt: "farm tractor with large rear tire, field or clean background", notes: "big back wheel is the main recognition cue", sourceName: "Project-owned deterministic drawing", license: "Project-owned"),
        importedImagePlan("helicopter", asset: "MemoryVehicleHelicopter", prompt: "helicopter side view with rotor visible", notes: "rotor and tail boom must fit inside crop", sourceName: "Project-owned deterministic drawing", license: "Project-owned"),
        importedImagePlan("rocket", asset: "MemoryVehicleRocket", prompt: "rocket launch or upright rocket, simple high-contrast composition", notes: "flame plume optional; avoid agency logos unless public-domain provenance is documented", sourceName: "Project-owned deterministic drawing", license: "Project-owned"),
        importedImagePlan("scooter", asset: "MemoryVehicleScooter", prompt: "small scooter or moped side view, clean background", notes: "keep distinct from bike using seat and motor body", sourceName: "Project-owned deterministic drawing", license: "Project-owned"),
        importedImagePlan("taxi", asset: "MemoryVehicleTaxi", prompt: "yellow taxi side or three-quarter view, clean city context", notes: "taxi sign/checker cue useful; avoid visible plate numbers", sourceName: "Project-owned deterministic drawing", license: "Project-owned")
    ]

    static let planetImageAssetPlan: [MemoryImageAssetPlan] = [
        importedImagePlan("planet-mercury", asset: "MemoryPlanetMercury", prompt: "Mercury planet disk, gray cratered surface, black or transparent background", notes: "craters visible; avoid confusing with Moon unless labeled in provenance", sourceName: "Project-owned deterministic drawing", license: "Project-owned"),
        importedImagePlan("planet-venus", asset: "MemoryPlanetVenus", prompt: "Venus planet disk, pale yellow cloud-covered surface", notes: "soft yellow cloud bands; no surface lava imagery unless educationally intentional", sourceName: "Project-owned deterministic drawing", license: "Project-owned"),
        importedImagePlan("planet-earth", asset: "MemoryPlanetEarth", prompt: "Earth planet disk showing blue oceans, green/brown land, white clouds", notes: "full globe preferred; keep recognizable continents/clouds", sourceName: "Project-owned deterministic drawing", license: "Project-owned"),
        importedImagePlan("planet-mars", asset: "MemoryPlanetMars", prompt: "Mars planet disk, rusty red surface with darker markings", notes: "red/orange treatment must be distinct from Venus", sourceName: "Project-owned deterministic drawing", license: "Project-owned"),
        importedImagePlan("planet-jupiter", asset: "MemoryPlanetJupiter", prompt: "Jupiter planet disk with brown cream bands and Great Red Spot", notes: "Great Red Spot is the key recognition cue", sourceName: "Project-owned deterministic drawing", license: "Project-owned"),
        importedImagePlan("planet-saturn", asset: "MemoryPlanetSaturn", prompt: "Saturn with rings, tan/gold planet, transparent or dark background", notes: "rings must fit fully inside square card crop", sourceName: "Project-owned deterministic drawing", license: "Project-owned"),
        importedImagePlan("planet-uranus", asset: "MemoryPlanetUranus", prompt: "Uranus planet disk, pale cyan blue-green, minimal bands", notes: "tilted ring optional only if sourced and legible", sourceName: "Project-owned deterministic drawing", license: "Project-owned"),
        importedImagePlan("planet-neptune", asset: "MemoryPlanetNeptune", prompt: "Neptune planet disk, deep blue with subtle storm/cloud texture", notes: "deeper blue than Uranus; avoid over-saturated fantasy art", sourceName: "Project-owned deterministic drawing", license: "Project-owned")
    ]

    static let fishImageAssetPlan: [MemoryImageAssetPlan] = [
        importedImagePlan("fish-clownfish", asset: "MemoryFishClownfish", prompt: "clownfish with orange body and white bands near coral or sea anemone", notes: "white bands and orange body must be readable; crop out busy reef clutter", sourceName: "Project-owned deterministic drawing", license: "Project-owned"),
        importedImagePlan("fish-goldfish", asset: "MemoryFishGoldfish", prompt: "goldfish side view with rounded body and flowing tail on a clean water background", notes: "orange or gold body should distinguish it from clownfish; avoid bowl-only compositions", sourceName: "Project-owned deterministic drawing", license: "Project-owned"),
        importedImagePlan("fish-betta", asset: "MemoryFishBetta", prompt: "betta fish with large flowing fins, side view, clean aquatic background", notes: "flowing fins are the recognition cue; keep fin edges visible in square crop", sourceName: "Project-owned deterministic drawing", license: "Project-owned"),
        importedImagePlan("fish-angelfish", asset: "MemoryFishAngelfish", prompt: "angelfish with tall triangular fins, side view, simple reef or water background", notes: "tall dorsal and anal fins must stay inside crop; avoid confusing with generic reef fish", sourceName: "Project-owned deterministic drawing", license: "Project-owned"),
        importedImagePlan("fish-catfish", asset: "MemoryFishCatfish", prompt: "catfish with visible whisker-like barbels, side or three-quarter view", notes: "barbels must be clear at card size; prefer uncluttered river or aquarium background", sourceName: "Project-owned deterministic drawing", license: "Project-owned"),
        importedImagePlan("fish-swordtail", asset: "MemoryFishSwordtail", prompt: "swordtail fish side view with long sword-shaped lower tail extension", notes: "tail sword is required for recognition; avoid crops that trim the tail", sourceName: "Project-owned deterministic drawing", license: "Project-owned"),
        importedImagePlan("fish-tuna", asset: "MemoryFishTuna", prompt: "tuna fish with streamlined silver and blue body, side view in open water", notes: "sleek torpedo shape should read clearly; avoid fishing/deck scenes", sourceName: "Project-owned deterministic drawing", license: "Project-owned"),
        importedImagePlan("fish-seahorse", asset: "MemoryFishSeahorse", prompt: "seahorse upright profile with curled tail, clean sea grass or water background", notes: "upright posture and curled tail must be visible; keep subject large in square crop", sourceName: "Project-owned deterministic drawing", license: "Project-owned")
    ]

    static let planets: [MemoryAnimal] = [
        planet("planet-mercury", prompt: "☿", asset: "MemoryPlanetMercury", name: "Mercury", order: "1st from the Sun", type: "rocky planet", size: "4,879 km wide", colors: "gray", funFact: "A year lasts 88 days"),
        planet("planet-venus", prompt: "♀", asset: "MemoryPlanetVenus", name: "Venus", order: "2nd from the Sun", type: "rocky planet", size: "12,104 km wide", colors: "pale yellow", funFact: "It spins very slowly"),
        planet("planet-earth", prompt: "⊕", asset: "MemoryPlanetEarth", name: "Earth", order: "3rd from the Sun", type: "rocky planet", size: "12,742 km wide", colors: "blue, green, white", funFact: "It has one moon"),
        planet("planet-mars", prompt: "♂", asset: "MemoryPlanetMars", name: "Mars", order: "4th from the Sun", type: "rocky planet", size: "6,779 km wide", colors: "rusty red", funFact: "It has two small moons"),
        planet("planet-jupiter", prompt: "♃", asset: "MemoryPlanetJupiter", name: "Jupiter", order: "5th from the Sun", type: "gas giant", size: "139,820 km wide", colors: "brown, cream, orange", funFact: "It is the biggest planet"),
        planet("planet-saturn", prompt: "♄", asset: "MemoryPlanetSaturn", name: "Saturn", order: "6th from the Sun", type: "gas giant", size: "116,460 km wide", colors: "gold and tan", funFact: "It is famous for bright rings"),
        planet("planet-uranus", prompt: "⛢", asset: "MemoryPlanetUranus", name: "Uranus", order: "7th from the Sun", type: "ice giant", size: "50,724 km wide", colors: "icy blue", funFact: "It rotates on its side"),
        planet("planet-neptune", prompt: "♆", asset: "MemoryPlanetNeptune", name: "Neptune", order: "8th from the Sun", type: "ice giant", size: "49,244 km wide", colors: "deep blue", funFact: "It has very fast winds")
    ]

    static let fishes: [MemoryAnimal] = [
        fish("fish-clownfish", prompt: "Orange reef fish", asset: "MemoryFishClownfish", name: "Clownfish", home: "warm coral reefs", size: "10 to 18 cm long", colors: "orange, white, black", funFact: "It hides safely inside sea anemones"),
        fish("fish-goldfish", prompt: "Golden pond fish", asset: "MemoryFishGoldfish", name: "Goldfish", home: "ponds and aquariums", size: "15 to 30 cm long", colors: "gold, orange, white", funFact: "It can remember simple routes and feeding times"),
        fish("fish-betta", prompt: "Flowing fin fish", asset: "MemoryFishBetta", name: "Betta", home: "slow streams and rice fields", size: "6 to 8 cm long", colors: "red, blue, purple", funFact: "It can breathe some air from the surface"),
        fish("fish-angelfish", prompt: "Tall fin reef fish", asset: "MemoryFishAngelfish", name: "Angelfish", home: "coral reefs", size: "15 to 25 cm long", colors: "yellow, blue, black", funFact: "It glides between corals with flat fins"),
        fish("fish-catfish", prompt: "Whiskered river fish", asset: "MemoryFishCatfish", name: "Catfish", home: "rivers, lakes, and ponds", size: "20 to 60 cm long", colors: "gray, brown, black", funFact: "Its whiskers help it sense food in cloudy water"),
        fish("fish-swordtail", prompt: "Tail-sword fish", asset: "MemoryFishSwordtail", name: "Swordtail", home: "freshwater streams", size: "8 to 12 cm long", colors: "orange, green, black", funFact: "The male has a long sword-shaped tail"),
        fish("fish-tuna", prompt: "Fast ocean fish", asset: "MemoryFishTuna", name: "Tuna", home: "open ocean waters", size: "1 to 2 m long", colors: "silver and blue", funFact: "It can swim very fast for long distances"),
        fish("fish-seahorse", prompt: "Tiny upright sea swimmer", asset: "MemoryFishSeahorse", name: "Seahorse", home: "sea grass beds and reefs", size: "2 to 15 cm long", colors: "yellow, brown, orange", funFact: "It swims upright and curls its tail")
    ]

    static let countries: [MemoryAnimal] = [
        countryCapital("country-india", country: "India", capital: "New Delhi", continent: "Asia", language: "Hindi and English", currency: "Indian rupee", mapShape: "wide triangle-like peninsula", clue: "home of the Taj Mahal"),
        countryCapital("country-japan", country: "Japan", capital: "Tokyo", continent: "Asia", language: "Japanese", currency: "yen", mapShape: "long island chain", clue: "known for cherry blossoms and bullet trains"),
        countryCapital("country-france", country: "France", capital: "Paris", continent: "Europe", language: "French", currency: "euro", mapShape: "hexagon-like outline", clue: "home of the Eiffel Tower"),
        countryCapital("country-egypt", country: "Egypt", capital: "Cairo", continent: "Africa", language: "Arabic", currency: "Egyptian pound", mapShape: "square-like shape with Sinai corner", clue: "home of the Great Pyramids"),
        countryCapital("country-brazil", country: "Brazil", capital: "Brasília", continent: "South America", language: "Portuguese", currency: "Brazilian real", mapShape: "large east-bulging outline", clue: "home of the Amazon rainforest"),
        countryCapital("country-australia", country: "Australia", capital: "Canberra", continent: "Australia", language: "English", currency: "Australian dollar", mapShape: "big island continent", clue: "home of kangaroos and koalas"),
        countryCapital("country-canada", country: "Canada", capital: "Ottawa", continent: "North America", language: "English and French", currency: "Canadian dollar", mapShape: "very wide northern outline", clue: "known for maple leaves and snowy winters"),
        countryCapital("country-kenya", country: "Kenya", capital: "Nairobi", continent: "Africa", language: "Swahili and English", currency: "Kenyan shilling", mapShape: "east Africa shape by the Indian Ocean", clue: "known for savannas and wildlife parks")
    ]

    static let countryFlags: [MemoryAnimal] = [
        flagCountry("country-flag-india", country: "India", asset: "MemoryFlagIndia", isoAlpha2: "IN", continent: "Asia", capital: "New Delhi", colors: "saffron, white, green, navy blue", clue: "home of the Taj Mahal"),
        flagCountry("country-flag-japan", country: "Japan", asset: "MemoryFlagJapan", isoAlpha2: "JP", continent: "Asia", capital: "Tokyo", colors: "white and red", clue: "known for cherry blossoms and bullet trains"),
        flagCountry("country-flag-france", country: "France", asset: "MemoryFlagFrance", isoAlpha2: "FR", continent: "Europe", capital: "Paris", colors: "blue, white, red", clue: "home of the Eiffel Tower"),
        flagCountry("country-flag-egypt", country: "Egypt", asset: "MemoryFlagEgypt", isoAlpha2: "EG", continent: "Africa", capital: "Cairo", colors: "red, white, black, gold", clue: "home of the Great Pyramids"),
        flagCountry("country-flag-brazil", country: "Brazil", asset: "MemoryFlagBrazil", isoAlpha2: "BR", continent: "South America", capital: "Brasília", colors: "green, yellow, blue, white", clue: "home of the Amazon rainforest"),
        flagCountry("country-flag-australia", country: "Australia", asset: "MemoryFlagAustralia", isoAlpha2: "AU", continent: "Australia", capital: "Canberra", colors: "blue, red, white", clue: "home of kangaroos and koalas"),
        flagCountry("country-flag-canada", country: "Canada", asset: "MemoryFlagCanada", isoAlpha2: "CA", continent: "North America", capital: "Ottawa", colors: "red and white", clue: "known for maple leaves and snowy winters"),
        flagCountry("country-flag-kenya", country: "Kenya", asset: "MemoryFlagKenya", isoAlpha2: "KE", continent: "Africa", capital: "Nairobi", colors: "black, red, green, white", clue: "known for savannas and wildlife parks")
    ]

    static let indiaStates: [MemoryAnimal] = [
        indiaStateCapital("state-maharashtra", state: "Maharashtra", capital: "Mumbai", region: "west India", clue: "Gateway of India and Bollywood"),
        indiaStateCapital("state-karnataka", state: "Karnataka", capital: "Bengaluru", region: "south India", clue: "gardens, rockets, and tech city"),
        indiaStateCapital("state-tamil-nadu", state: "Tamil Nadu", capital: "Chennai", region: "south India", clue: "temples, music, and Marina Beach"),
        indiaStateCapital("state-west-bengal", state: "West Bengal", capital: "Kolkata", region: "east India", clue: "Howrah Bridge and rasgulla"),
        indiaStateCapital("state-gujarat", state: "Gujarat", capital: "Gandhinagar", region: "west India", clue: "Gir lions and white desert festival"),
        indiaStateCapital("state-rajasthan", state: "Rajasthan", capital: "Jaipur", region: "northwest India", clue: "pink city and desert forts"),
        indiaStateCapital("state-kerala", state: "Kerala", capital: "Thiruvananthapuram", region: "south India", clue: "backwaters and coconut trees"),
        indiaStateCapital("state-assam", state: "Assam", capital: "Dispur", region: "northeast India", clue: "tea gardens and one-horned rhinos")
    ]

    static let numberBondsTo10: [MemoryAnimal] = [
        numberBondTo10("bond-1-9", prompt: "1 + 9", match: "10", clue: "One and nine fill the ten-frame."),
        numberBondTo10("bond-2-8", prompt: "2 + 8", match: "10", clue: "Two and eight make a full ten."),
        numberBondTo10("bond-3-7", prompt: "3 + 7", match: "10", clue: "Three and seven are friendly ten partners."),
        numberBondTo10("bond-4-6", prompt: "4 + 6", match: "10", clue: "Four and six snap together to ten."),
        numberBondTo10("bond-5-5", prompt: "5 + 5", match: "10", clue: "Five and five are doubles that make ten."),
        numberBondTo10("bond-6-4", prompt: "6 + 4", match: "10", clue: "Six needs four more to make ten."),
        numberBondTo10("bond-7-3", prompt: "7 + 3", match: "10", clue: "Seven needs three more to make ten."),
        numberBondTo10("bond-8-2", prompt: "8 + 2", match: "10", clue: "Eight and two complete the ten-frame."),
        numberBondTo10("bond-9-1", prompt: "9 + 1", match: "10", clue: "Nine needs one more to make ten."),
        numberBondTo10("bond-10-0", prompt: "10 + 0", match: "10", clue: "Ten and zero stay ten."),
    ]

    static let fruits: [MemoryAnimal] = [
        fruit("fruit-apple", name: "Apple", emoji: "🍎", shape: "round", colors: "red, green, or yellow", taste: "sweet and crisp", smell: "fresh and fruity", foundIn: "India, China, the United States, and Europe"),
        fruit("fruit-banana", name: "Banana", emoji: "🍌", shape: "long and curved", colors: "yellow", taste: "sweet and soft", smell: "gentle tropical smell", foundIn: "India, Ecuador, the Philippines, and Brazil"),
        fruit("fruit-mango", name: "Mango", emoji: "🥭", shape: "oval", colors: "yellow, orange, green, or red", taste: "very sweet and juicy", smell: "rich tropical smell", foundIn: "India, Mexico, Thailand, and Pakistan"),
        fruit("fruit-orange", name: "Orange", emoji: "🍊", shape: "round", colors: "orange", taste: "sweet and tangy", smell: "bright citrus smell", foundIn: "Brazil, India, China, and Spain"),
        fruit("fruit-grape", name: "Grape", emoji: "🍇", shape: "small round bunches", colors: "green, red, or purple", taste: "sweet and juicy", smell: "light fruity smell", foundIn: "Italy, China, the United States, and India"),
        fruit("fruit-watermelon", name: "Watermelon", emoji: "🍉", shape: "large oval", colors: "green outside and red inside", taste: "sweet and watery", smell: "fresh melon smell", foundIn: "India, China, Turkey, and Brazil"),
        fruit("fruit-pineapple", name: "Pineapple", emoji: "🍍", shape: "oval with spiky crown", colors: "gold and green", taste: "sweet and tangy", smell: "strong tropical smell", foundIn: "Costa Rica, India, the Philippines, and Thailand"),
        fruit("fruit-strawberry", name: "Strawberry", emoji: "🍓", shape: "heart-shaped", colors: "red with tiny seeds", taste: "sweet and a little tart", smell: "sweet berry smell", foundIn: "United States, Mexico, Spain, and India")
    ]

    static let waterCycle: [MemoryAnimal] = [
        waterCycleConcept("water-cycle-evaporation", name: "Evaporation", asset: "MemoryWaterCycleEvaporation", action: "warm water goes up", whereSeen: "above warm ponds, lakes, and puddles", everydayWords: "The sun warms water into vapor", cycleStep: "Water rises into the air"),
        waterCycleConcept("water-cycle-condensation", name: "Condensation", asset: "MemoryWaterCycleCondensation", action: "tiny drops make a cloud", whereSeen: "inside cool clouds", everydayWords: "Vapor cools and gathers as tiny drops", cycleStep: "Drops gather together"),
        waterCycleConcept("water-cycle-precipitation", name: "Precipitation", asset: "MemoryWaterCyclePrecipitation", action: "rain falls down", whereSeen: "under heavy clouds", everydayWords: "Cloud drops get heavy and fall", cycleStep: "Rain returns to the ground"),
        waterCycleConcept("water-cycle-collection", name: "Collection", asset: "MemoryWaterCycleCollection", action: "water gathers again", whereSeen: "in ponds, lakes, rivers, and puddles", everydayWords: "Fallen water gathers in low places", cycleStep: "Water waits for the sun again"),
        waterCycleConcept("water-cycle-sun-heat", name: "Sun Heat", asset: "MemoryWaterCycleSunHeat", action: "the sun warms water", whereSeen: "where sunlight touches water", everydayWords: "Warm sunlight starts the cycle", cycleStep: "Heat helps water rise"),
        waterCycleConcept("water-cycle-vapor", name: "Vapor", asset: "MemoryWaterCycleVapor", action: "water is in the air", whereSeen: "above warm water", everydayWords: "Vapor is water we cannot easily see", cycleStep: "Vapor moves upward"),
        waterCycleConcept("water-cycle-cloud", name: "Cloud", asset: "MemoryWaterCycleCloud", action: "drops gather together", whereSeen: "up in the sky", everydayWords: "A cloud holds many tiny drops", cycleStep: "Clouds can grow heavy"),
        waterCycleConcept("water-cycle-pond", name: "Pond", asset: "MemoryWaterCyclePond", action: "water waits here", whereSeen: "on the ground after rain", everydayWords: "A pond can collect rain water", cycleStep: "Collected water can rise again")
    ]

    static let waterCycleImageAssetPlan: [MemoryImageAssetPlan] = [
        importedImagePlan("water-cycle-evaporation", asset: "MemoryWaterCycleEvaporation", prompt: "warm sun over pond with vapor rising", notes: "rising vapor must be readable at card size", sourceName: "Codex CLI image generation water cycle prompt family", license: "Project-owned"),
        importedImagePlan("water-cycle-condensation", asset: "MemoryWaterCycleCondensation", prompt: "vapor dots gathering into a cloud", notes: "cloud and gathered drops should be visually central", sourceName: "Codex CLI image generation water cycle prompt family", license: "Project-owned"),
        importedImagePlan("water-cycle-precipitation", asset: "MemoryWaterCyclePrecipitation", prompt: "rain falling from a cloud into a pond", notes: "falling rain should be distinct from vapor", sourceName: "Codex CLI image generation water cycle prompt family", license: "Project-owned"),
        importedImagePlan("water-cycle-collection", asset: "MemoryWaterCycleCollection", prompt: "rain water collecting in pond or lake", notes: "pond should read as the destination for rain", sourceName: "Codex CLI image generation water cycle prompt family", license: "Project-owned"),
        importedImagePlan("water-cycle-sun-heat", asset: "MemoryWaterCycleSunHeat", prompt: "sun warming water", notes: "sun rays should clearly touch water", sourceName: "Codex CLI image generation water cycle prompt family", license: "Project-owned"),
        importedImagePlan("water-cycle-vapor", asset: "MemoryWaterCycleVapor", prompt: "water vapor rising from a pond", notes: "vapor arrows should differ from rain drops", sourceName: "Codex CLI image generation water cycle prompt family", license: "Project-owned"),
        importedImagePlan("water-cycle-cloud", asset: "MemoryWaterCycleCloud", prompt: "cloud with tiny gathered drops", notes: "cloud should be clear without needing text", sourceName: "Codex CLI image generation water cycle prompt family", license: "Project-owned"),
        importedImagePlan("water-cycle-pond", asset: "MemoryWaterCyclePond", prompt: "pond holding collected water after rain", notes: "pond should be large and high contrast", sourceName: "Codex CLI image generation water cycle prompt family", license: "Project-owned")
    ]

    static let allAnimalsById: [String: MemoryAnimal] = {
        Dictionary(uniqueKeysWithValues: (domesticAnimals + birds + vehicles + planets + fishes + countries + countryFlags + indiaStates + waterCycle + fruits).map { ($0.id, $0) })
    }()

    static let imageAssetProvenance: [MemoryImageAssetProvenance] = [
        generatedIssue352ImageProvenance(assetName: "MemoryPlanetMercury", cardId: "planet-mercury", sha256: "9308f539c70807709f96c98d6d70f6e931cb7095f2dd9049fa1f47be83032081"),
        generatedIssue352ImageProvenance(assetName: "MemoryPlanetVenus", cardId: "planet-venus", sha256: "3f94177e135f7dff55b73f6091141bc6aba555e5717ceadb6b012667cf6cb6e4"),
        generatedIssue352ImageProvenance(assetName: "MemoryPlanetEarth", cardId: "planet-earth", sha256: "77c3e4b4d267e283d2bb5efbaf2a45d8412ebee55bc15957ef1ad2514a635466"),
        generatedIssue352ImageProvenance(assetName: "MemoryPlanetMars", cardId: "planet-mars", sha256: "8975ed07bbbe2fc471c9373d63fab8f85a0e8d3e115ea160ee73bc00724d0d6e"),
        generatedIssue352ImageProvenance(assetName: "MemoryPlanetJupiter", cardId: "planet-jupiter", sha256: "0197f506bd7e414c337e9ba3543a4cf4cad5f99855e353cba8a7aca9c799da40"),
        generatedIssue352ImageProvenance(assetName: "MemoryPlanetSaturn", cardId: "planet-saturn", sha256: "798d945d730902e9d8cd438a121bc10f09a96f341fdabeec183ff64b493f3439"),
        generatedIssue352ImageProvenance(assetName: "MemoryPlanetUranus", cardId: "planet-uranus", sha256: "88e2d9c7cf3859fe88ab02a41aeb642f048760940164f84f37ed888f46d748fd"),
        generatedIssue352ImageProvenance(assetName: "MemoryPlanetNeptune", cardId: "planet-neptune", sha256: "ffc0a56865f63c42190a01825e29711596415e4aeecdf4c0d236a0d38ec12a03"),
        generatedIssue352ImageProvenance(assetName: "MemoryVehicleCar", cardId: "car", sha256: "322156d48b0625d864b17fcd5c85d480b3938cb350ece977692ae5c34910a2a5"),
        generatedIssue352ImageProvenance(assetName: "MemoryVehicleBus", cardId: "bus", sha256: "850e2541f2eee679c5f02c4037588125b69ed049ace670fd1790498e934cb639"),
        generatedIssue352ImageProvenance(assetName: "MemoryVehicleTrain", cardId: "train", sha256: "3eb0d1f9ec3327ea786822796d0a4cd05721512fac86a6e6e8cf443bf5ca4d60"),
        generatedIssue352ImageProvenance(assetName: "MemoryVehiclePlane", cardId: "plane", sha256: "64109fdb182213310e6951783540fb419969b250185ac47f12085270ee07dd2f"),
        generatedIssue352ImageProvenance(assetName: "MemoryVehicleBoat", cardId: "boat", sha256: "6249a276351fd91a2f81b78371c78349a5802c6de242721a8391f290ef9b5924"),
        generatedIssue352ImageProvenance(assetName: "MemoryVehicleBike", cardId: "bike", sha256: "e4bdd509af598bdc0b9407c85ee27987460808846b01dd28972a8c6ecbc4e276"),
        generatedIssue352ImageProvenance(assetName: "MemoryVehicleTruck", cardId: "truck", sha256: "daca358c96d2a4e5ecfd6a502631213a83f6628ee790e1330ce80d794af7af51"),
        generatedIssue352ImageProvenance(assetName: "MemoryVehicleTractor", cardId: "tractor", sha256: "fa46188e68866c975e751d30d4dcfbef7f5946f2fb5f7a535008f594283394fe"),
        generatedIssue352ImageProvenance(assetName: "MemoryVehicleHelicopter", cardId: "helicopter", sha256: "b968b491b968e0aeb371c405f303adf3f301ffc71059f904e8630ecb7f4aced2"),
        generatedIssue352ImageProvenance(assetName: "MemoryVehicleRocket", cardId: "rocket", sha256: "329909c4b26c533933e422a2062bf5f563b32fd687c34ee19d8c842495b23dea"),
        generatedIssue352ImageProvenance(assetName: "MemoryVehicleScooter", cardId: "scooter", sha256: "a73d39d0d34154e2040d6fe9a5d7884901696a0385a8d94b949bf6c9b0bb4492"),
        generatedIssue352ImageProvenance(assetName: "MemoryVehicleTaxi", cardId: "taxi", sha256: "3da398ace4c4d435b5ce3833d1407e296947e598c1ec88653d7848e8f63ea628"),
        generatedImageProvenance(assetName: "MemoryFishClownfish", cardId: "fish-clownfish", sha256: "994003f9911cd64dae9b0b788918a64ca4bf0a9ca8c2889ecb9dfca6903d9c6b"),
        generatedImageProvenance(assetName: "MemoryFishGoldfish", cardId: "fish-goldfish", sha256: "03e5d0f461f714cff979eba3c154b3f1012f8880c88fca509cdabeb74ddc4dde"),
        generatedImageProvenance(assetName: "MemoryFishBetta", cardId: "fish-betta", sha256: "32da3532b489e9c7d20394cec5b99897c2011cc2a92809ced0b249d74e1aa200"),
        generatedImageProvenance(assetName: "MemoryFishAngelfish", cardId: "fish-angelfish", sha256: "8da0cff35ded5222747f099b3ca785719c9700c17514aa2f69fd3ff5b5b904c6"),
        generatedImageProvenance(assetName: "MemoryFishCatfish", cardId: "fish-catfish", sha256: "e2d712233b9fd1d4f5fa5d3c167329d19784fb72784ce062ee8231cc7e19a1fe"),
        generatedImageProvenance(assetName: "MemoryFishSwordtail", cardId: "fish-swordtail", sha256: "decdde0bb9874d8d7b5f3c07c544f342dd339c69c42f135eee8f134a1ea18a19"),
        generatedImageProvenance(assetName: "MemoryFishTuna", cardId: "fish-tuna", sha256: "d9716931aba86201236c724311c5b8fae07b6dca705ca059cd9c7247b33b67a3"),
        generatedImageProvenance(assetName: "MemoryFishSeahorse", cardId: "fish-seahorse", sha256: "90a58259c3a44be96017c86b1d4a165fc507ba24d9baf2c53b9dad23c1ff50a0"),
        generatedFlagProvenance(assetName: "MemoryFlagIndia", cardId: "country-flag-india", sha256: "532012f66641b8e0ddd64628305810178bd97bb35e13086c00ee2ba597ae45f2"),
        generatedFlagProvenance(assetName: "MemoryFlagJapan", cardId: "country-flag-japan", sha256: "b2d751e8a2b4a7987c5268b5edb12b45a5cdda7dd9977d027311aba9401b39ef"),
        generatedFlagProvenance(assetName: "MemoryFlagFrance", cardId: "country-flag-france", sha256: "c9912731f78d48a59bcad43a2e0014ac83ef7887277b8a4ad8728803a3c74ff4"),
        generatedFlagProvenance(assetName: "MemoryFlagEgypt", cardId: "country-flag-egypt", sha256: "f307582ff40e2c27ebf25e244fa34330b671f30cf44df07e75fc122f3402ddd8"),
        generatedFlagProvenance(assetName: "MemoryFlagBrazil", cardId: "country-flag-brazil", sha256: "ac1235d39036fd5ed000a10dd0e49d939eda8db1632c831d8453be301aa6c272"),
        generatedFlagProvenance(assetName: "MemoryFlagAustralia", cardId: "country-flag-australia", sha256: "07e169c5a54af9027fbafe0348e4505b09112cd077d1e3fbcf37a206be37c119"),
        generatedFlagProvenance(assetName: "MemoryFlagCanada", cardId: "country-flag-canada", sha256: "b3712b0ba8bb6c0bb9d40878b9ba8af8dfcd42f5fc35823472d4324ef580132c"),
        generatedFlagProvenance(assetName: "MemoryFlagKenya", cardId: "country-flag-kenya", sha256: "174a01c7a8f65e7b4e7fc976edb1f239617042113a82335fa7ff7455ea1657e9"),
        generatedWaterCycleProvenance(assetName: "MemoryWaterCycleEvaporation", cardId: "water-cycle-evaporation", sha256: "5f7571966da3b6242143f3a44e73c41ee81f1085849a32f9a067b6124a996569"),
        generatedWaterCycleProvenance(assetName: "MemoryWaterCycleCondensation", cardId: "water-cycle-condensation", sha256: "9698adba516d56e3f4b9f30465630b4af094a03a6f111fde71622b02df2e7fe2"),
        generatedWaterCycleProvenance(assetName: "MemoryWaterCyclePrecipitation", cardId: "water-cycle-precipitation", sha256: "5cd079edf33046af063ad95cdc34d75d1783c2af5561b6478d4cbf39fb0b5dc1"),
        generatedWaterCycleProvenance(assetName: "MemoryWaterCycleCollection", cardId: "water-cycle-collection", sha256: "cc5e445e06d97f817e01bfc1977621fd68259f0620b43c1fc57fba3c5e612a31"),
        generatedWaterCycleProvenance(assetName: "MemoryWaterCycleSunHeat", cardId: "water-cycle-sun-heat", sha256: "78eda4860d8e9a467e59cd74fb857aa01745adbdfab504b1acc4049c15743621"),
        generatedWaterCycleProvenance(assetName: "MemoryWaterCycleVapor", cardId: "water-cycle-vapor", sha256: "b18c6b62a49da2c32206fe750468626675067ee7aac36fbbb1a8186ef04e6a2b"),
        generatedWaterCycleProvenance(assetName: "MemoryWaterCycleCloud", cardId: "water-cycle-cloud", sha256: "9b4ec5f6b72b03b0e0ec9e730164de97b9e532043c07b16f62937a71499518c9"),
        generatedWaterCycleProvenance(assetName: "MemoryWaterCyclePond", cardId: "water-cycle-pond", sha256: "97829a63dda1473845eadb5c54b3701d5eca265f73044920de36f00bc941acce")
    ]


    private static func imagePlan(_ cardId: String, asset: String, prompt: String, notes: String) -> MemoryImageAssetPlan {
        MemoryImageAssetPlan(
            cardId: cardId,
            assetName: asset,
            searchPrompt: prompt,
            styleNotes: notes,
            status: .needsVettedSource
        )
    }

    private static func importedImagePlan(_ cardId: String, asset: String, prompt: String, notes: String, sourceName: String, license: String) -> MemoryImageAssetPlan {
        MemoryImageAssetPlan(
            cardId: cardId,
            assetName: asset,
            searchPrompt: prompt,
            styleNotes: notes,
            status: .readyForAssetImport(sourceName: sourceName, license: license)
        )
    }

    private static func generatedIssue352ImageProvenance(assetName: String, cardId: String, sha256: String) -> MemoryImageAssetProvenance {
        MemoryImageAssetProvenance(
            assetName: assetName,
            cardId: cardId,
            sourceName: "Project-owned deterministic drawing",
            creator: "OpenAI Codex for ganesh47/mather",
            creditLine: "Project-owned artwork created for Mather issue #352",
            license: "Project-owned; no third-party source material",
            licenseUrl: "",
            retrievedAt: "2026-04-27",
            originalFileName: "\(assetName).png",
            originalSha256: sha256,
            derivativeFileName: "\(assetName).png",
            derivativeSha256: sha256,
            derivativeChanges: "Generated directly as a 512x512 transparent PNG with Pillow vector drawing commands; no third-party material used.",
            licenseAllowsReuse: true,
            noThirdPartyRestrictionFound: true,
            noLogoOrEndorsementRisk: true,
            noPeopleOrPrivacyRisk: true,
            childCardLegibilityChecked: true
        )
    }

    private static func generatedImageProvenance(assetName: String, cardId: String, sha256: String) -> MemoryImageAssetProvenance {
        MemoryImageAssetProvenance(
            assetName: assetName,
            cardId: cardId,
            sourceName: "Project-owned deterministic drawing",
            creator: "OpenAI Codex for ganesh47/mather",
            creditLine: "Project-owned artwork created for Mather issue #379",
            license: "Project-owned; no third-party source material",
            licenseUrl: "",
            retrievedAt: "2026-04-27",
            originalFileName: "\(assetName).png",
            originalSha256: sha256,
            derivativeFileName: "\(assetName).png",
            derivativeSha256: sha256,
            derivativeChanges: "Generated directly as a 512x512 transparent PNG with Pillow vector drawing commands; no third-party material used.",
            licenseAllowsReuse: true,
            noThirdPartyRestrictionFound: true,
            noLogoOrEndorsementRisk: true,
            noPeopleOrPrivacyRisk: true,
            childCardLegibilityChecked: true
        )
    }

    private static func generatedFlagProvenance(assetName: String, cardId: String, sha256: String) -> MemoryImageAssetProvenance {
        MemoryImageAssetProvenance(
            assetName: assetName,
            cardId: cardId,
            sourceName: "Project-owned deterministic educational flag drawing",
            creator: "OpenAI Codex for ganesh47/mather",
            creditLine: "Project-owned artwork created for Mather issue #744",
            license: "Project-owned; no third-party source files or copied artwork",
            licenseUrl: "",
            retrievedAt: "2026-04-29",
            originalFileName: "\(assetName).png",
            originalSha256: sha256,
            derivativeFileName: "\(assetName).png",
            derivativeSha256: sha256,
            derivativeChanges: "Generated directly as a 512x512 transparent PNG with Pillow vector drawing commands from basic flag geometry and colors; no third-party image file was imported.",
            licenseAllowsReuse: true,
            noThirdPartyRestrictionFound: true,
            noLogoOrEndorsementRisk: true,
            noPeopleOrPrivacyRisk: true,
            childCardLegibilityChecked: true
        )
    }

    private static func generatedWaterCycleProvenance(assetName: String, cardId: String, sha256: String) -> MemoryImageAssetProvenance {
        MemoryImageAssetProvenance(
            assetName: assetName,
            cardId: cardId,
            sourceName: "Codex CLI image generation water cycle prompt family",
            creator: "OpenAI Codex for ganesh47/mather",
            creditLine: "Project-owned artwork created for Mather issue #771",
            license: "Project-owned; no third-party source material",
            licenseUrl: "",
            retrievedAt: "2026-04-29",
            originalFileName: "\(assetName).png",
            originalSha256: sha256,
            derivativeFileName: "\(assetName).png",
            derivativeSha256: sha256,
            derivativeChanges: "Generated with Codex CLI image generation on 2026-04-29 using the child-friendly water cycle memory-card prompt family; resized to 512x512 PNG and chroma-key background removed locally; no third-party material used.",
            licenseAllowsReuse: true,
            noThirdPartyRestrictionFound: true,
            noLogoOrEndorsementRisk: true,
            noPeopleOrPrivacyRisk: true,
            childCardLegibilityChecked: true
        )
    }

    private static func domesticAnimal(_ id: String, name: String, emoji: String, habitat: String, colors: String, sound: String?, movement: String) -> MemoryAnimal {
        MemoryAnimal(
            id: id,
            name: name,
            picture: .emoji(emoji),
            metadata: MemoryCardMetadata(
                deck: .domesticAnimals,
                category: "animal",
                kind: "domestic animal",
                habitat: habitat,
                colors: colors,
                movement: movement,
                sound: sound
            )
        )
    }

    private static func bird(_ id: String, name: String, asset: String, home: String, lifespan: String, weight: String, size: String, colors: String) -> MemoryAnimal {
        MemoryAnimal(
            id: id,
            name: name,
            picture: .asset(asset),
            metadata: MemoryCardMetadata(
                deck: .birds,
                category: "bird",
                kind: "bird",
                habitat: home,
                lifespan: lifespan,
                weight: weight,
                size: size,
                colors: colors,
                movement: "flies with wings",
                factCards: [
                    MemoryFactCard(title: "Name", value: name),
                    MemoryFactCard(title: "Home", value: home),
                    MemoryFactCard(title: "Lifespan", value: lifespan),
                    MemoryFactCard(title: "Weight", value: weight),
                    MemoryFactCard(title: "Size", value: size),
                    MemoryFactCard(title: "Colors", value: colors)
                ]
            )
        )
    }

    private static func vehicle(_ id: String, name: String, emoji: String, asset: String? = nil, use: String, movement: String, colors: String, sound: String?) -> MemoryAnimal {
        MemoryAnimal(
            id: id,
            name: name,
            picture: asset.map { .asset($0) } ?? .emoji(emoji),
            metadata: MemoryCardMetadata(
                deck: .vehicles,
                category: "vehicle",
                kind: "vehicle",
                colors: colors,
                use: use,
                movement: movement,
                sound: sound
            )
        )
    }

    private static func planet(_ id: String, prompt: String, asset: String? = nil, name: String, order: String, type: String, size: String, colors: String, funFact: String) -> MemoryAnimal {
        MemoryAnimal(
            id: id,
            name: name,
            picture: asset.map { .asset($0) } ?? .text(prompt),
            metadata: MemoryCardMetadata(
                deck: .planets,
                category: "planet",
                kind: type,
                habitat: "our solar system",
                size: size,
                colors: colors,
                movement: "orbits the Sun",
                factCards: [
                    MemoryFactCard(title: "Name", value: name),
                    MemoryFactCard(title: "Order", value: order),
                    MemoryFactCard(title: "Type", value: type),
                    MemoryFactCard(title: "Size", value: size),
                    MemoryFactCard(title: "Fun Fact", value: funFact)
                ]
            )
        )
    }

    private static func fish(_ id: String, prompt: String, asset: String? = nil, name: String, home: String, size: String, colors: String, funFact: String) -> MemoryAnimal {
        MemoryAnimal(
            id: id,
            name: name,
            picture: asset.map { .asset($0) } ?? .text(prompt),
            metadata: MemoryCardMetadata(
                deck: .fishes,
                category: "fish",
                kind: "fish",
                habitat: home,
                size: size,
                colors: colors,
                movement: "swims with fins",
                factCards: [
                    MemoryFactCard(title: "Name", value: name),
                    MemoryFactCard(title: "Home", value: home),
                    MemoryFactCard(title: "Size", value: size),
                    MemoryFactCard(title: "Colors", value: colors),
                    MemoryFactCard(title: "Fun Fact", value: funFact)
                ]
            )
        )
    }

    private static func fruit(_ id: String, name: String, emoji: String, shape: String, colors: String, taste: String, smell: String, foundIn: String) -> MemoryAnimal {
        MemoryAnimal(
            id: id,
            name: name,
            picture: .emoji(emoji),
            metadata: MemoryCardMetadata(
                deck: .fruits,
                category: "fruit",
                kind: "fruit",
                habitat: foundIn,
                colors: colors,
                use: taste,
                movement: "grows on plants and travels from farms to markets",
                sound: smell,
                factCards: [
                    MemoryFactCard(title: "Fruit", value: name),
                    MemoryFactCard(title: "Shape", value: shape),
                    MemoryFactCard(title: "Color", value: colors),
                    MemoryFactCard(title: "Taste", value: taste),
                    MemoryFactCard(title: "Smell", value: smell),
                    MemoryFactCard(title: "Usually Found", value: foundIn)
                ]
            )
        )
    }

    private static func countryCapital(_ id: String, country: String, capital: String, continent: String, language: String, currency: String, mapShape: String, clue: String) -> MemoryAnimal {
        MemoryAnimal(
            id: id,
            name: capital,
            canonicalName: country,
            picture: .text(country),
            metadata: MemoryCardMetadata(
                deck: .countries,
                category: "country",
                kind: "country and capital",
                habitat: continent,
                factCards: [
                    MemoryFactCard(title: "Country", value: country),
                    MemoryFactCard(title: "Capital", value: capital),
                    MemoryFactCard(title: "Language", value: language),
                    MemoryFactCard(title: "Currency", value: currency),
                    MemoryFactCard(title: "Continent", value: continent),
                    MemoryFactCard(title: "Map Shape", value: mapShape),
                    MemoryFactCard(title: "Bucket", value: "Place in \(continent)"),
                    MemoryFactCard(title: "Known For", value: clue)
                ]
            )
        )
    }

    private static func flagCountry(_ id: String, country: String, asset: String, isoAlpha2: String, continent: String, capital: String, colors: String, clue: String) -> MemoryAnimal {
        MemoryAnimal(
            id: id,
            name: country,
            canonicalName: country,
            picture: .asset(asset),
            metadata: MemoryCardMetadata(
                deck: .countryFlags,
                category: "country flag",
                kind: "country flag",
                habitat: continent,
                colors: colors,
                factCards: [
                    MemoryFactCard(title: "Country", value: country),
                    MemoryFactCard(title: "Flag", value: "Flag of \(country)"),
                    MemoryFactCard(title: "ISO Code", value: isoAlpha2),
                    MemoryFactCard(title: "Capital", value: capital),
                    MemoryFactCard(title: "Continent", value: continent),
                    MemoryFactCard(title: "Colors", value: colors),
                    MemoryFactCard(title: "Known For", value: clue)
                ]
            )
        )
    }

    private static func indiaStateCapital(_ id: String, state: String, capital: String, region: String, clue: String) -> MemoryAnimal {
        MemoryAnimal(
            id: id,
            name: capital,
            canonicalName: state,
            picture: .text(state),
            metadata: MemoryCardMetadata(
                deck: .indiaStates,
                category: "state",
                kind: "Indian state and capital",
                habitat: region,
                factCards: [
                    MemoryFactCard(title: "State", value: state),
                    MemoryFactCard(title: "Capital", value: capital),
                    MemoryFactCard(title: "Region", value: region),
                    MemoryFactCard(title: "Known For", value: clue)
                ]
            )
        )
    }

    private static func waterCycleConcept(_ id: String, name: String, asset: String, action: String, whereSeen: String, everydayWords: String, cycleStep: String) -> MemoryAnimal {
        MemoryAnimal(
            id: id,
            name: name,
            picture: .asset(asset),
            metadata: MemoryCardMetadata(
                deck: .waterCycle,
                category: "water cycle concept",
                kind: "water cycle concept",
                habitat: whereSeen,
                movement: action,
                factCards: [
                    MemoryFactCard(title: "Concept", value: name),
                    MemoryFactCard(title: "Action", value: action),
                    MemoryFactCard(title: "Where", value: whereSeen),
                    MemoryFactCard(title: "Everyday Words", value: everydayWords),
                    MemoryFactCard(title: "Cycle Step", value: cycleStep)
                ]
            )
        )
    }

    private static func numberBondTo10(_ id: String, prompt: String, match: String, clue: String) -> MemoryAnimal {
        MemoryAnimal(
            id: id,
            name: match,
            canonicalName: "\(prompt) = \(match)",
            picture: .text(prompt),
            metadata: MemoryCardMetadata(
                deck: .numberBondsTo10,
                category: "number bond",
                kind: "number bond to 10",
                factCards: [
                    MemoryFactCard(title: "Prompt", value: prompt),
                    MemoryFactCard(title: "Match", value: match),
                    MemoryFactCard(title: "Clue", value: clue),
                    MemoryFactCard(title: "Stage", value: "Remember — calm retrieval, no countdown")
                ]
            )
        )
    }
}

// MARK: - Game difficulty

enum MemoryDifficulty: CaseIterable {
    case easy
    case medium
    case hard

    var pairCount: Int {
        switch self {
        case .easy: return 3
        case .medium: return 4
        case .hard: return 6
        }
    }

    var faceDown: Bool { self == .hard }

    var label: String {
        switch self {
        case .easy: return "Easy"
        case .medium: return "Medium"
        case .hard: return "Flip!"
        }
    }

    var menuLabel: String {
        switch self {
        case .easy: return "Easy"
        case .medium: return "Medium"
        case .hard: return "Flip mode"
        }
    }

    var columns: Int {
        switch self {
        case .easy: return 3
        case .medium: return 4
        case .hard: return 4
        }
    }
}

struct MemoryView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Bindable var appModel: AppModel

    @State private var deck: [MemoryAnimal] = MemoryDeck.domesticAnimals
    @State private var difficulty: MemoryDifficulty = .easy
    @State private var cards: [MemoryCard] = []
    @State private var firstSelected: MemoryCard? = nil
    @State private var matchedPairs: Int = 0
    @State private var roundsPlayed: Int = 0
    @State private var sessionStart: Date = .now
    @State private var mismatchIds: Set<UUID> = []
    @State private var isProcessingMismatch = false
    @State private var showRoundComplete = false
    @State private var deckSelection: DeckSelection = .domestic
    @State private var directEntryKind: MemoryDeckKind? = nil
    @State private var recentPairHistory: [String] = []
    @State private var learningContent: MemoryLearningContent? = nil
    @State private var askSession: MemoryAskConversationSession? = nil
    @State private var latestAskResponse: MemoryAskResponse? = nil

    init(appModel: AppModel, initialDeckKind: MemoryDeckKind? = nil) {
        self.appModel = appModel
        let initialSelection = DeckSelection(kind: initialDeckKind)
        _deck = State(initialValue: initialSelection.animals)
        _deckSelection = State(initialValue: initialSelection)
        _directEntryKind = State(initialValue: Self.directStagedEntryKind(for: initialDeckKind))
        _difficulty = State(initialValue: Self.initialDifficulty(for: initialDeckKind))
    }

    enum DeckSelection: CaseIterable {
        case domestic, birds, vehicles, planets, fishes, countries, countryFlags, indiaStates, waterCycle, fruits, numberBondsTo10

        init(kind: MemoryDeckKind?) {
            switch kind {
            case .domesticAnimals: self = .domestic
            case .birds: self = .birds
            case .vehicles: self = .vehicles
            case .planets: self = .planets
            case .fishes: self = .fishes
            case .countries: self = .countries
            case .countryFlags: self = .countryFlags
            case .indiaStates: self = .indiaStates
            case .waterCycle: self = .waterCycle
            case .fruits: self = .fruits
            case .numberBondsTo10: self = .numberBondsTo10
            case nil: self = .domestic
            }
        }

        var label: String {
            switch self {
            case .domestic: return "🐄 Animals"
            case .birds: return "🦜 Birds"
            case .vehicles: return "🚗 Vehicles"
            case .planets: return "🪐 Planets"
            case .fishes: return "🐠 Fishes"
            case .countries: return "🌍 Countries & Capitals"
            case .countryFlags: return "🏳️ Countries & Flags"
            case .indiaStates: return "📍 India States & Capitals"
            case .waterCycle: return "💧 Water Cycle"
            case .fruits: return "🍎 Fruits"
            case .numberBondsTo10: return "🔟 Number Bonds"
            }
        }

        var menuLabel: String {
            switch self {
            case .domestic: return "Animals"
            case .birds: return "Birds"
            case .vehicles: return "Vehicles"
            case .planets: return "Planets"
            case .fishes: return "Fishes"
            case .countries: return "Countries & Capitals"
            case .countryFlags: return "Countries & Flags"
            case .indiaStates: return "India States & Capitals"
            case .waterCycle: return "Water Cycle"
            case .fruits: return "Fruits"
            case .numberBondsTo10: return "Number Bonds to 10"
            }
        }

        var animals: [MemoryAnimal] {
            switch self {
            case .domestic: return MemoryDeck.domesticAnimals
            case .birds: return MemoryDeck.birds
            case .vehicles: return MemoryDeck.vehicles
            case .planets: return MemoryDeck.planets
            case .fishes: return MemoryDeck.fishes
            case .countries: return MemoryDeck.countries
            case .countryFlags: return MemoryDeck.countryFlags
            case .indiaStates: return MemoryDeck.indiaStates
            case .waterCycle: return MemoryDeck.waterCycle
            case .fruits: return MemoryDeck.fruits
            case .numberBondsTo10: return MemoryDeck.numberBondsTo10
            }
        }
    }

    private var totalPairs: Int { difficulty.pairCount }
    private var isDirectStagedEntry: Bool { directEntryKind != nil }

    var body: some View {
        ZStack {
            MatherTheme.background.ignoresSafeArea()
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    header
                        .padding(.horizontal, 20)
                        .padding(.top, 16)
                        .padding(.bottom, 12)

                    cardGrid
                        .padding(.horizontal, 20)
                        .padding(.bottom, 20)
                }
            }

            if showRoundComplete { roundCompleteOverlay }
        }
        .sheet(item: $learningContent) { content in
            learningSheet(for: content)
        }
        .onAppear {
            sessionStart = .now
            dealRound()
        }
        .onDisappear {
            guard roundsPlayed > 0 else { return }
            appModel.gameSessionStore.save(
                gameName: "Memory Match",
                startedAt: sessionStart,
                scoreValue: roundsPlayed,
                scoreLabel: "rounds"
            )
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 16) {
            ViewThatFits(in: .horizontal) {
                HStack(alignment: .top, spacing: 12) {
                    backButton
                    memoryHeaderCopy
                    Spacer(minLength: 0)
                }

                VStack(alignment: .leading, spacing: 8) {
                    backButton
                    memoryHeaderCopy
                }
            }

            CardSurface {
                if isDirectStagedEntry {
                    directStagedEntryStatus
                } else {
                    deckAndDifficultyChooser
                }
            }
        }
    }


    private var backButton: some View {
        Button {
            appModel.engine.showLab()
        } label: {
            Image(systemName: "chevron.left")
                .font(.title3.weight(.semibold))
                .foregroundStyle(MatherTheme.accent)
                .frame(width: 44, height: 44)
        }
        .accessibilityLabel("Back")
    }

    private var memoryHeaderCopy: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text("Memory Match")
                .font(.title2.weight(.black))
                .foregroundStyle(MatherTheme.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.82)
            Text("\(matchedPairs)/\(totalPairs) pairs matched")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(MatherTheme.cardSubtitle)
            if Self.supportsLearningDetails(for: deckSelection) {
                Text(Self.learnMoreHintText(for: deckSelection))
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(MatherTheme.cardSubtitle)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityIdentifier("memory-learn-more-hint")
            }
        }
    }

    private var deckAndDifficultyChooser: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Choose a deck and level")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(MatherTheme.cardSubtitle)

            VStack(spacing: 10) {
                Menu {
                    ForEach(DeckSelection.allCases, id: \.label) { selectedDeck in
                        Button(selectedDeck.label) {
                            deckSelection = selectedDeck
                            deck = selectedDeck.animals
                            recentPairHistory = []
                            dealRound()
                        }
                    }
                } label: {
                    controlLabel(title: "Deck", value: deckSelection.menuLabel, tint: MatherTheme.accent)
                }
                .accessibilityIdentifier("memory-deck-menu")

                Menu {
                    ForEach(MemoryDifficulty.allCases, id: \.label) { selectedDifficulty in
                        Button(selectedDifficulty.label) {
                            difficulty = selectedDifficulty
                            dealRound()
                        }
                    }
                } label: {
                    controlLabel(title: "Difficulty", value: difficulty.menuLabel, tint: MatherTheme.warm)
                }
                .accessibilityIdentifier("memory-difficulty-menu")
            }
        }
    }

    private var directStagedEntryStatus: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(deckSelection.menuLabel)
                .font(.headline.weight(.black))
                .foregroundStyle(MatherTheme.ink)
                .accessibilityIdentifier("memory-direct-deck-title")

            Text("Stage \(Self.stageNumber(for: difficulty)) of \(Self.directStageDifficulties.count): \(difficulty.menuLabel)")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(MatherTheme.cardSubtitle)
                .accessibilityIdentifier("memory-direct-stage-label")
        }
    }

    private func controlLabel(title: String, value: String, tint: Color) -> some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(MatherTheme.cardSubtitle)
                Text(value)
                    .font(.headline.weight(.bold))
                    .foregroundStyle(MatherTheme.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
            }

            Spacer(minLength: 12)

            Image(systemName: "chevron.up.chevron.down")
                .font(.caption.weight(.bold))
                .foregroundStyle(tint)
                .padding(10)
                .background(tint.opacity(colorScheme == .dark ? 0.24 : 0.12), in: Capsule())
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(MatherTheme.background.opacity(colorScheme == .dark ? 0.4 : 1), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .contentShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private var cardGrid: some View {
        let columns = [GridItem(.adaptive(minimum: ResponsiveLayout.memoryCardMinimumWidth(for: difficulty)), spacing: 14)]
        return LazyVGrid(columns: columns, spacing: 14) {
            ForEach(cards) { card in
                let canLearn = Self.canOpenLearningDetails(for: card, deckSelection: deckSelection, difficulty: difficulty, showRoundComplete: showRoundComplete)
                cardView(card)
                    .aspectRatio(ResponsiveLayout.memoryCardAspectRatio(for: difficulty), contentMode: .fit)
                    .accessibilityIdentifier(Self.accessibilityIdentifier(for: card))
                    .accessibilityLabel(Self.accessibilityLabel(for: card, difficulty: difficulty))
                    .accessibilityHint(Self.accessibilityHint(for: card, difficulty: difficulty))
                    .onTapGesture(count: 2) { handleDoubleTap(card) }
                    .onTapGesture { handleTap(card) }
                    .modifier(MemoryLearnMoreAccessibilityModifier(
                        actionName: canLearn ? Self.learnAboutActionName(for: animal(for: card)) : nil,
                        action: { handleDoubleTap(card) }
                    ))
            }
        }
        .frame(maxWidth: ResponsiveLayout.memoryBoardMaxWidth(for: horizontalSizeClass))
        .frame(maxWidth: .infinity)
    }

    @ViewBuilder
    private func cardView(_ card: MemoryCard) -> some View {
        LearningCardView(model: Self.learningCardModel(for: card, difficulty: difficulty, isIncorrect: mismatchIds.contains(card.id)))
    }

    @ViewBuilder
    private func pictureView(for animal: MemoryAnimal, emojiSize preferredEmojiSize: CGFloat? = nil) -> some View {
        switch animal.picture {
        case .emoji(let emoji):
            Text(emoji)
                .font(.system(size: preferredEmojiSize ?? emojiSize))
                .shadow(color: .black.opacity(0.10), radius: 3, y: 2)
        case .asset(let assetName):
            Image(assetName)
                .resizable()
                .scaledToFit()
                .shadow(color: .black.opacity(0.08), radius: 3, y: 2)
                .padding(4)
        case .text(let value):
            Text(value)
                .font(.system(size: difficulty == .hard ? 18 : 22, weight: .black, design: .rounded))
                .foregroundStyle(MatherTheme.ink)
                .multilineTextAlignment(.center)
                .lineLimit(3)
                .minimumScaleFactor(0.52)
                .padding(10)
        }
    }

    private func animal(for card: MemoryCard) -> MemoryAnimal {
        switch card.content {
        case .picture(let animal), .label(let animal): return animal
        }
    }

    static func labelFontSize(for difficulty: MemoryDifficulty) -> CGFloat {
        switch difficulty {
        case .easy: return 18
        case .medium: return 16
        case .hard: return 14
        }
    }

    static func labelMinimumScaleFactor(for difficulty: MemoryDifficulty) -> CGFloat {
        switch difficulty {
        case .easy: return 0.82
        case .medium: return 0.72
        case .hard: return 0.58
        }
    }


    static func labelHorizontalPadding(for difficulty: MemoryDifficulty) -> CGFloat {
        switch difficulty {
        case .easy: return 8
        case .medium: return 6
        case .hard: return 4
        }
    }

    static func artStyle(for pairId: String) -> MemoryArtStyle {
        if pairId.hasPrefix("bird-") {
            let birdStyles: [MemoryArtStyle] = [
                MemoryArtStyle(topColor: MatherTheme.warm.opacity(0.28), bottomColor: MatherTheme.coral.opacity(0.18), badgeColor: MatherTheme.warm, badgeHighlight: Color.white.opacity(0.95), ornament: "sun.max.fill", ornamentColor: MatherTheme.coral),
                MemoryArtStyle(topColor: MatherTheme.softBlue.opacity(0.30), bottomColor: MatherTheme.accent.opacity(0.18), badgeColor: MatherTheme.accent, badgeHighlight: Color.white.opacity(0.92), ornament: "drop.fill", ornamentColor: MatherTheme.softBlue),
                MemoryArtStyle(topColor: MatherTheme.accent.opacity(0.24), bottomColor: MatherTheme.warm.opacity(0.18), badgeColor: MatherTheme.accent, badgeHighlight: Color.white.opacity(0.92), ornament: "sparkles", ornamentColor: MatherTheme.warm),
                MemoryArtStyle(topColor: MatherTheme.panelDeep.opacity(0.24), bottomColor: MatherTheme.softBlue.opacity(0.16), badgeColor: MatherTheme.panelDeep, badgeHighlight: Color.white.opacity(0.84), ornament: "moon.stars.fill", ornamentColor: MatherTheme.softBlue),
                MemoryArtStyle(topColor: MatherTheme.coral.opacity(0.22), bottomColor: MatherTheme.warm.opacity(0.16), badgeColor: MatherTheme.coral, badgeHighlight: Color.white.opacity(0.92), ornament: "heart.fill", ornamentColor: MatherTheme.warm),
                MemoryArtStyle(topColor: MatherTheme.softBlue.opacity(0.24), bottomColor: MatherTheme.background.opacity(0.12), badgeColor: MatherTheme.softBlue, badgeHighlight: Color.white.opacity(0.96), ornament: "leaf.fill", ornamentColor: MatherTheme.accent),
                MemoryArtStyle(topColor: MatherTheme.warm.opacity(0.24), bottomColor: MatherTheme.panel.opacity(0.16), badgeColor: MatherTheme.panel, badgeHighlight: Color.white.opacity(0.92), ornament: "bird.fill", ornamentColor: MatherTheme.coral),
                MemoryArtStyle(topColor: MatherTheme.accent.opacity(0.22), bottomColor: MatherTheme.coral.opacity(0.14), badgeColor: MatherTheme.accent, badgeHighlight: Color.white.opacity(0.94), ornament: "rainbow", ornamentColor: MatherTheme.coral)
            ]
            let styleIndex = abs(pairId.hashValue) % birdStyles.count
            return birdStyles[styleIndex]
        }

        switch pairId {
        case "cow", "sheep", "rabbit", "llama", "goat":
            return MemoryArtStyle(topColor: MatherTheme.warm.opacity(0.30), bottomColor: MatherTheme.accent.opacity(0.22), badgeColor: MatherTheme.warm, badgeHighlight: Color.white.opacity(0.92), ornament: "sparkles", ornamentColor: MatherTheme.accent)
        case "dog", "cat", "mouse", "pig", "donkey":
            return MemoryArtStyle(topColor: MatherTheme.softBlue.opacity(0.28), bottomColor: MatherTheme.accent.opacity(0.16), badgeColor: MatherTheme.softBlue, badgeHighlight: Color.white.opacity(0.90), ornament: "heart.fill", ornamentColor: MatherTheme.coral)
        case "horse", "camel", "ox", "tractor", "truck":
            return MemoryArtStyle(topColor: MatherTheme.warm.opacity(0.22), bottomColor: MatherTheme.panelDeep.opacity(0.18), badgeColor: MatherTheme.panel, badgeHighlight: MatherTheme.warm.opacity(0.88), ornament: "sun.max.fill", ornamentColor: MatherTheme.warm)
        case "duck", "swan", "goose", "boat":
            return MemoryArtStyle(topColor: MatherTheme.softBlue.opacity(0.30), bottomColor: MatherTheme.background.opacity(0.10), badgeColor: MatherTheme.softBlue, badgeHighlight: Color.white.opacity(0.95), ornament: "drop.fill", ornamentColor: MatherTheme.accent)
        case "rooster", "turkey", "chicken", "babychick", "hatchedchick":
            return MemoryArtStyle(topColor: MatherTheme.coral.opacity(0.28), bottomColor: MatherTheme.warm.opacity(0.18), badgeColor: MatherTheme.coral, badgeHighlight: MatherTheme.warm.opacity(0.86), ornament: "star.fill", ornamentColor: MatherTheme.warm)
        case "goldfish", "frog":
            return MemoryArtStyle(topColor: MatherTheme.accent.opacity(0.24), bottomColor: MatherTheme.warm.opacity(0.18), badgeColor: MatherTheme.accent, badgeHighlight: MatherTheme.warm.opacity(0.88), ornament: "bubbles.and.sparkles.fill", ornamentColor: MatherTheme.softBlue)
        case "car", "bus", "taxi", "scooter", "bike":
            return MemoryArtStyle(topColor: MatherTheme.coral.opacity(0.24), bottomColor: MatherTheme.warm.opacity(0.16), badgeColor: MatherTheme.coral, badgeHighlight: Color.white.opacity(0.90), ornament: "road.lanes", ornamentColor: MatherTheme.panelDeep)
        case "train", "plane", "helicopter", "rocket":
            return MemoryArtStyle(topColor: MatherTheme.softBlue.opacity(0.28), bottomColor: MatherTheme.accent.opacity(0.18), badgeColor: MatherTheme.accent, badgeHighlight: Color.white.opacity(0.92), ornament: "wind", ornamentColor: MatherTheme.softBlue)
        default:
            return MemoryArtStyle(topColor: MatherTheme.panel.opacity(0.22), bottomColor: MatherTheme.softBlue.opacity(0.16), badgeColor: MatherTheme.panel, badgeHighlight: Color.white.opacity(0.90), ornament: "sparkles", ornamentColor: MatherTheme.accent)
        }
    }

    static func buildCards(for animals: [MemoryAnimal]) -> [MemoryCard] {
        animals.flatMap { animal in
            [
                MemoryCard(pairId: animal.id, content: .picture(animal)),
                MemoryCard(pairId: animal.id, content: .label(animal))
            ]
        }
    }

    private var emojiSize: CGFloat {
        switch difficulty {
        case .easy: return 56
        case .medium: return 48
        case .hard: return 40
        }
    }

    private var roundCompleteOverlay: some View {
        VStack {
            Spacer()

            VStack(spacing: 14) {
                Text("🎉 All matched!")
                    .font(.title2.weight(.black))
                    .foregroundStyle(MatherTheme.ink)

                Text(Self.roundCompleteMessage(for: deckSelection, roundsPlayed: roundsPlayed))
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(MatherTheme.cardSubtitle)
                    .multilineTextAlignment(.center)

                Button("Next Round") {
                    nextRound()
                }
                .buttonStyle(PrimaryActionButtonStyle())
                .frame(maxWidth: 240)
            }
            .padding(24)
            .frame(maxWidth: .infinity)
            .background(RoundedRectangle(cornerRadius: 24, style: .continuous).fill(MatherTheme.card).shadow(color: .black.opacity(0.18), radius: 24, y: 8))
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }

    static func preferredRoundAnimals(from deck: [MemoryAnimal], pairCount: Int, recentPairHistory: [String]) -> [MemoryAnimal] {
        let recentSet = Set(recentPairHistory)
        let freshPool = deck.filter { !recentSet.contains($0.id) }
        let primaryPool = freshPool.count >= pairCount ? freshPool : deck

        var chosen = Array(primaryPool.shuffled().prefix(pairCount))
        if chosen.count < pairCount {
            let chosenIds = Set(chosen.map(\.id))
            chosen.append(contentsOf: deck.filter { !chosenIds.contains($0.id) }.shuffled().prefix(pairCount - chosen.count))
        }
        return chosen
    }

    static func updatedRecentPairHistory(previous: [String], newRoundAnimals: [MemoryAnimal], pairCount: Int) -> [String] {
        let historyWindow = max(pairCount * 2, pairCount)
        return Array((previous + newRoundAnimals.map(\.id)).suffix(historyWindow))
    }

    static let directStageDifficulties: [MemoryDifficulty] = [.easy, .medium, .hard]

    static func directStagedEntryKind(for initialDeckKind: MemoryDeckKind?) -> MemoryDeckKind? {
        switch initialDeckKind {
        case .fruits, .countries, .numberBondsTo10:
            return initialDeckKind
        case .domesticAnimals, .birds, .vehicles, .planets, .fishes, .countryFlags, .indiaStates, .waterCycle, nil:
            return nil
        }
    }

    static func initialDifficulty(for initialDeckKind: MemoryDeckKind?) -> MemoryDifficulty {
        directStagedEntryKind(for: initialDeckKind) == nil ? .easy : directStageDifficulties[0]
    }

    static func stageNumber(for difficulty: MemoryDifficulty) -> Int {
        (directStageDifficulties.firstIndex(of: difficulty) ?? 0) + 1
    }

    static func nextDirectStageDifficulty(after difficulty: MemoryDifficulty) -> MemoryDifficulty {
        guard let index = directStageDifficulties.firstIndex(of: difficulty) else {
            return directStageDifficulties[0]
        }
        let nextIndex = min(index + 1, directStageDifficulties.count - 1)
        return directStageDifficulties[nextIndex]
    }

    static func shouldHideChooser(for initialDeckKind: MemoryDeckKind?) -> Bool {
        directStagedEntryKind(for: initialDeckKind) != nil
    }

    static func canOpenLearningDetails(for card: MemoryCard, deckSelection: DeckSelection, difficulty: MemoryDifficulty, showRoundComplete: Bool) -> Bool {
        guard supportsLearningDetails(for: deckSelection) else { return false }
        if card.isMatched { return true }
        guard !showRoundComplete else { return false }
        return difficulty.faceDown ? card.isSelected : true
    }

    static func supportsLearningDetails(for deckSelection: DeckSelection) -> Bool {
        !deckSelection.animals.isEmpty
    }

    static func learnMoreHintText(for deckSelection: DeckSelection) -> String {
        supportsLearningDetails(for: deckSelection) ? "Double-tap a card to learn more" : ""
    }

    static func roundCompleteMessage(for deckSelection: DeckSelection, roundsPlayed: Int) -> String {
        supportsLearningDetails(for: deckSelection)
            ? "Double-tap a card to learn more, or start the next round."
            : "Round \(roundsPlayed) complete"
    }

    static func learnAboutActionName(for animal: MemoryAnimal) -> String {
        "Learn about \(animal.canonicalName)"
    }

    static func learningContent(for animal: MemoryAnimal, deckSelection: DeckSelection, description: MemoryCardDescription) -> MemoryLearningContent {
        let sourceBadge = learningSourceBadge(for: deckSelection, source: description.source)
        let factChips = description.factChips.map { MemoryFactCard(title: $0.title, value: $0.value) }
        return MemoryLearningContent(
            animal: animal,
            title: description.title,
            shortDescription: description.shortDescription,
            factChips: factChips,
            sourceBadge: sourceBadge,
            readAloudText: learningReadAloudText(for: description.title, summary: description.shortDescription, factChips: factChips, sourceBadge: sourceBadge)
        )
    }

    private func handleDoubleTap(_ card: MemoryCard) {
        guard Self.canOpenLearningDetails(for: card, deckSelection: deckSelection, difficulty: difficulty, showRoundComplete: showRoundComplete) else { return }
        let selectedAnimal = animal(for: card)
        askSession = nil
        latestAskResponse = nil
        learningContent = Self.learningContent(
            for: selectedAnimal,
            deckSelection: deckSelection,
            description: appModel.memoryCardDescribeService.fallbackDescription(for: selectedAnimal)
        )
        Task { @MainActor in
            let description = await appModel.memoryCardDescribeService.describe(selectedAnimal)
            learningContent = Self.learningContent(for: selectedAnimal, deckSelection: deckSelection, description: description)
        }
    }

    @ViewBuilder
    private func learningSheet(for content: MemoryLearningContent) -> some View {
        let animal = content.animal
        let artStyle = Self.artStyle(for: animal.id)

        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 18) {
                    HStack(alignment: .center, spacing: 16) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 24, style: .continuous)
                                .fill(LinearGradient(colors: [artStyle.topColor, artStyle.bottomColor], startPoint: .topLeading, endPoint: .bottomTrailing))
                                .frame(width: 108, height: 108)

                            pictureView(for: animal)
                                .frame(width: 80, height: 80)
                        }
                        .accessibilityHidden(true)

                        VStack(alignment: .leading, spacing: 8) {
                            Text(content.title)
                                .font(.title3.weight(.black))
                                .foregroundStyle(MatherTheme.ink)
                                .accessibilityIdentifier("memory-learning-title")

                            Text(content.shortDescription)
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(MatherTheme.cardSubtitle)
                                .accessibilityIdentifier("memory-learning-description")

                            Text(content.sourceBadge)
                                .font(.caption.weight(.bold))
                                .foregroundStyle(artStyle.ornamentColor)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(Color.white.opacity(colorScheme == .dark ? 0.08 : 0.6), in: Capsule())
                                .accessibilityIdentifier("memory-learning-source-badge")
                        }

                        Spacer(minLength: 0)
                    }

                    Button {
                        appModel.speechService.speakLearningDetails(content.readAloudText, enabled: appModel.featureFlags.audioEnabled)
                    } label: {
                        Label("Read Aloud", systemImage: "speaker.wave.2.fill")
                            .font(.headline.weight(.bold))
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(PrimaryActionButtonStyle())
                    .accessibilityIdentifier("memory-learning-read-aloud")

                    MemoryAskConversationSection(
                        session: askSession,
                        latestResponse: latestAskResponse,
                        startConversation: {
                            Task { @MainActor in
                                askSession = await MemoryAskConversationPolicy().startSession(for: animal)
                                latestAskResponse = nil
                            }
                        },
                        selectTurn: { turn in
                            guard var session = askSession else { return }
                            let response = session.respond(to: .suggestedTurn(id: turn.id))
                            askSession = session
                            latestAskResponse = response
                            appModel.speechService.speakLearningDetails(response.spokenText, enabled: appModel.featureFlags.audioEnabled)
                        },
                        replayLatestAnswer: {
                            guard let latestAskResponse else { return }
                            appModel.speechService.speakLearningDetails(latestAskResponse.spokenText, enabled: appModel.featureFlags.audioEnabled)
                        }
                    )

                    LazyVGrid(columns: [GridItem(.adaptive(minimum: ResponsiveLayout.memoryLearningFactMinimumWidth(for: horizontalSizeClass)), spacing: 10)], spacing: 10) {
                        ForEach(content.factChips, id: \.self) { fact in
                            VStack(alignment: .leading, spacing: 4) {
                                Text(fact.title)
                                    .font(.caption.weight(.bold))
                                    .foregroundStyle(artStyle.ornamentColor)

                                Text(fact.value)
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(MatherTheme.ink)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(12)
                            .background(MatherTheme.background.opacity(colorScheme == .dark ? 0.45 : 1), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                        }
                    }
                    .accessibilityIdentifier("memory-learning-fact-chips")
                }
                .padding(20)
                .frame(maxWidth: ResponsiveLayout.memoryLearningSheetMaxWidth(for: horizontalSizeClass), alignment: .leading)
                .frame(maxWidth: .infinity)
            }
            .background(MatherTheme.background.ignoresSafeArea())
            .navigationTitle("Learn")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        learningContent = nil
                        askSession = nil
                        latestAskResponse = nil
                    }
                        .accessibilityIdentifier("memory-learning-done")
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    private func dealRound() {
        let roundAnimals = Self.preferredRoundAnimals(from: deck, pairCount: totalPairs, recentPairHistory: recentPairHistory)
        recentPairHistory = Self.updatedRecentPairHistory(previous: recentPairHistory, newRoundAnimals: roundAnimals, pairCount: totalPairs)
        cards = Self.buildCards(for: roundAnimals).shuffled()
        learningContent = nil
        askSession = nil
        latestAskResponse = nil
        firstSelected = nil
        matchedPairs = 0
        mismatchIds = []
        isProcessingMismatch = false
        showRoundComplete = false
    }

    private func handleTap(_ card: MemoryCard) {
        guard !card.isMatched, !isProcessingMismatch, !card.isSelected else { return }

        if let idx = cards.firstIndex(where: { $0.id == card.id }) {
            cards[idx].isSelected = true
        }
        appModel.hapticsService.counterSettle(enabled: appModel.featureFlags.hapticsEnabled)

        guard let first = firstSelected else {
            firstSelected = card
            return
        }

        firstSelected = nil

        if first.pairId == card.pairId {
            Task { @MainActor in
                try? await Task.sleep(for: .milliseconds(300))
                markMatched(pairId: card.pairId)
            }
        } else {
            isProcessingMismatch = true
            mismatchIds = [first.id, card.id]
            Task { @MainActor in
                try? await Task.sleep(for: .milliseconds(600))
                deselect(id: first.id)
                deselect(id: card.id)
                mismatchIds = []
                isProcessingMismatch = false
            }
        }
    }

    private func markMatched(pairId: String) {
        for idx in cards.indices where cards[idx].pairId == pairId {
            cards[idx].isMatched = true
            cards[idx].isSelected = false
        }
        matchedPairs += 1
        appModel.hapticsService.stageSuccess(enabled: appModel.featureFlags.hapticsEnabled)

        if matchedPairs == totalPairs {
            roundsPlayed += 1
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                showRoundComplete = true
            }
            appModel.speechService.speak("Amazing! All matched!", enabled: appModel.featureFlags.audioEnabled)
        }
    }

    private func deselect(id: UUID) {
        if let idx = cards.firstIndex(where: { $0.id == id }) {
            cards[idx].isSelected = false
        }
    }

    private func nextRound() {
        learningContent = nil
        if isDirectStagedEntry {
            difficulty = Self.nextDirectStageDifficulty(after: difficulty)
        }
        withAnimation(.easeOut(duration: 0.2)) {
            showRoundComplete = false
        }
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(250))
            dealRound()
        }
    }


    static func accessibilityIdentifier(for card: MemoryCard) -> String {
        let kind: String
        switch card.content {
        case .picture:
            kind = "picture"
        case .label:
            kind = "label"
        }
        return "memory-card-\(card.pairId)-\(kind)"
    }

    static func accessibilityLabel(for card: MemoryCard) -> String {
        switch card.content {
        case .picture(let animal):
            if animal.metadata.deck == .countryFlags {
                return "Flag of \(animal.canonicalName)"
            }
            return animal.canonicalName
        case .label(let animal):
            return animal.name
        }
    }

    static func accessibilityLabel(for card: MemoryCard, difficulty: MemoryDifficulty) -> String {
        if difficulty.faceDown && !card.isSelected && !card.isMatched {
            return "Face down memory card"
        }

        let state: String
        if card.isMatched {
            state = "matched"
        } else if card.isSelected {
            state = "selected"
        } else {
            state = "visible"
        }
        return "\(accessibilityLabel(for: card)), \(state)"
    }

    static func accessibilityHint(for card: MemoryCard, difficulty: MemoryDifficulty) -> String {
        if card.isMatched {
            return "Matched card."
        }
        if difficulty.faceDown && !card.isSelected {
            return "Tap to turn this card over."
        }
        return "Tap to choose this card."
    }

    static func learningCardModel(for card: MemoryCard, difficulty: MemoryDifficulty, isIncorrect: Bool) -> LearningCardViewModel {
        let display: LearningCardDisplay
        switch card.content {
        case .picture(let pictureAnimal):
            display = Self.learningCardDisplay(for: pictureAnimal.picture)
        case .label(let labelAnimal):
            display = .text(labelAnimal.name)
        }

        return LearningCardViewModel(
            id: card.id.uuidString,
            display: display,
            accessibilityLabel: accessibilityLabel(for: card, difficulty: difficulty),
            accessibilityHint: accessibilityHint(for: card, difficulty: difficulty),
            isFaceDown: difficulty.faceDown && !card.isSelected && !card.isMatched,
            isSelected: card.isSelected,
            isMatched: card.isMatched,
            isIncorrect: isIncorrect
        )
    }

    private static func learningCardDisplay(for picture: MemoryPicture) -> LearningCardDisplay {
        switch picture {
        case .emoji(let emoji):
            return .emoji(emoji)
        case .asset(let assetName):
            return .asset(assetName)
        case .text(let value):
            return .text(value)
        }
    }

    private static func learningSourceBadge(for deckSelection: DeckSelection, source: MemoryCardDescriptionSource) -> String {
        let deckLabel: String
        switch deckSelection {
        case .birds:
            deckLabel = "Bird Guide"
        case .domestic:
            deckLabel = "Animal Guide"
        case .vehicles:
            deckLabel = "Vehicle Guide"
        case .planets:
            deckLabel = "Planet Guide"
        case .fishes:
            deckLabel = "Fish Guide"
        case .countries:
            deckLabel = "Country Guide"
        case .countryFlags:
            deckLabel = "Flag Guide"
        case .indiaStates:
            deckLabel = "India Guide"
        case .waterCycle:
            deckLabel = "Water Cycle Guide"
        case .fruits:
            deckLabel = "Fruit Guide"
        case .numberBondsTo10:
            deckLabel = "Number Bond Guide"
        }

        switch source {
        case .appleIntelligence:
            return "Apple Intelligence + \(deckLabel)"
        case .curatedFallback:
            return deckLabel
        }
    }

    private static func learningReadAloudText(for title: String, summary: String, factChips: [MemoryFactCard], sourceBadge: String) -> String {
        let facts = factChips.map { "\($0.title): \($0.value)." }.joined(separator: " ")
        return "\(title). \(summary) Source: \(sourceBadge). \(facts)"
    }
}

private struct MemoryLearnMoreAccessibilityModifier: ViewModifier {
    let actionName: String?
    let action: () -> Void

    @ViewBuilder
    func body(content: Content) -> some View {
        if let actionName {
            content.accessibilityAction(named: Text(actionName)) {
                action()
            }
        } else {
            content
        }
    }
}

private struct MemoryAskConversationSection: View {
    @Environment(\.colorScheme) private var colorScheme

    let session: MemoryAskConversationSession?
    let latestResponse: MemoryAskResponse?
    let startConversation: () -> Void
    let selectTurn: (MemoryAskSuggestedTurn) -> Void
    let replayLatestAnswer: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let session {
                Text("Ask about this card")
                    .font(.headline.weight(.black))
                    .foregroundStyle(MatherTheme.ink)

                VStack(spacing: 10) {
                    ForEach(session.suggestedTurns) { turn in
                        Button {
                            selectTurn(turn)
                        } label: {
                            Label(turn.question, systemImage: "questionmark.circle.fill")
                                .lineLimit(2)
                                .minimumScaleFactor(0.78)
                                .multilineTextAlignment(.center)
                                .frame(maxWidth: .infinity, minHeight: 80)
                        }
                        .buttonStyle(SecondaryTileButtonStyle(fill: MatherTheme.softBlue.opacity(colorScheme == .dark ? 0.34 : 0.62)))
                        .accessibilityIdentifier("memory-ask-suggested-turn-\(turn.id)")
                    }
                }

                if let latestResponse {
                    VStack(alignment: .leading, spacing: 10) {
                        Text(latestResponse.spokenText)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(MatherTheme.ink)
                            .fixedSize(horizontal: false, vertical: true)
                            .accessibilityIdentifier("memory-ask-latest-answer")

                        Button {
                            replayLatestAnswer()
                        } label: {
                            Label("Replay answer", systemImage: "speaker.wave.2.fill")
                                .font(.subheadline.weight(.bold))
                                .frame(maxWidth: .infinity, minHeight: 52)
                        }
                        .buttonStyle(SecondaryTileButtonStyle(fill: MatherTheme.warm.opacity(colorScheme == .dark ? 0.28 : 0.52)))
                        .accessibilityIdentifier("memory-ask-replay-answer")
                    }
                    .padding(12)
                    .background(MatherTheme.background.opacity(colorScheme == .dark ? 0.45 : 1), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                }
            } else {
                Button {
                    startConversation()
                } label: {
                    Label("Ask about this card", systemImage: "questionmark.bubble.fill")
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                        .frame(maxWidth: .infinity, minHeight: 80)
                }
                .buttonStyle(SecondaryTileButtonStyle(fill: MatherTheme.softBlue.opacity(colorScheme == .dark ? 0.34 : 0.62)))
                .accessibilityIdentifier("memory-ask-about-this-card")
            }
        }
    }
}
