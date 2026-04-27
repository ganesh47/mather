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

enum MemoryDeckKind: String, Equatable {
    case domesticAnimals
    case birds
    case vehicles
    case planets
    case fishes
    case countries
    case indiaStates

    var displayName: String {
        switch self {
        case .domesticAnimals: return "Animals"
        case .birds: return "Birds"
        case .vehicles: return "Vehicles"
        case .planets: return "Planets"
        case .fishes: return "Fishes"
        case .countries: return "Countries & Capitals"
        case .indiaStates: return "Indian States & Capitals"
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
        bird("bird-a04", name: "Hummer", asset: "MemoryBirdA04", home: "Tropical Americas", lifespan: "3 to 5 years", weight: "3 to 6 g", size: "8 to 12 cm long", colors: "green, purple, teal"),
        bird("bird-a05", name: "Blue Macaw", asset: "MemoryBirdA05", home: "South American forests", lifespan: "35 to 50 years", weight: "1.0 to 1.4 kg", size: "85 to 100 cm long", colors: "blue and gold"),
        bird("bird-a06", name: "Kingfisher", asset: "MemoryBirdA06", home: "Asian and Oceanian waterways", lifespan: "6 to 10 years", weight: "30 to 45 g", size: "16 to 20 cm long", colors: "blue and orange"),
        bird("bird-a07", name: "Hummer", asset: "MemoryBirdA07", home: "South American cloud forests", lifespan: "3 to 5 years", weight: "4 to 7 g", size: "10 to 14 cm long", colors: "gold, orange, brown"),
        bird("bird-a08", name: "Kingfisher", asset: "MemoryBirdA08", home: "Woodland streams in Africa and Asia", lifespan: "5 to 10 years", weight: "35 to 50 g", size: "18 to 22 cm long", colors: "blue, white, black"),
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
        vehicle("car", name: "Car", emoji: "🚗", use: "takes people on road trips", movement: "rolls on four wheels", colors: "many bright paint colors", sound: "vroom"),
        vehicle("bus", name: "Bus", emoji: "🚌", use: "carries lots of people together", movement: "drives on roads with many seats", colors: "yellow, red, blue, green", sound: "rumbling engine"),
        vehicle("train", name: "Train", emoji: "🚂", use: "pulls people or cargo on tracks", movement: "rolls on rails", colors: "black, silver, red, blue", sound: "choo-choo"),
        vehicle("plane", name: "Plane", emoji: "✈️", use: "flies people across the sky", movement: "zooms with wings", colors: "white, blue, silver", sound: "whooshing jet sound"),
        vehicle("boat", name: "Boat", emoji: "⛵", use: "travels across water", movement: "floats and glides", colors: "white, blue, red", sound: "splashing water"),
        vehicle("bike", name: "Bike", emoji: "🚲", use: "helps riders pedal from place to place", movement: "rolls on two wheels", colors: "red, blue, green, black", sound: "spinning wheels"),
        vehicle("truck", name: "Truck", emoji: "🚚", use: "hauls heavy things", movement: "drives with a strong engine", colors: "white, blue, red", sound: "deep engine rumble"),
        vehicle("tractor", name: "Tractor", emoji: "🚜", use: "helps farmers work in fields", movement: "rumbles over dirt with big tires", colors: "green, red, yellow", sound: "put-put engine"),
        vehicle("helicopter", name: "Copter", emoji: "🚁", use: "flies high and can hover", movement: "lifts with spinning blades", colors: "red, blue, white", sound: "whup-whup"),
        vehicle("rocket", name: "Rocket", emoji: "🚀", use: "blasts toward space", movement: "launches straight up fast", colors: "silver, white, red", sound: "roaring blast"),
        vehicle("scooter", name: "Scooter", emoji: "🛵", use: "zips around short city trips", movement: "rolls on two small wheels", colors: "red, teal, yellow", sound: "buzzy motor"),
        vehicle("taxi", name: "Taxi", emoji: "🚕", use: "gives people rides around town", movement: "drives on busy roads", colors: "yellow and black", sound: "honk honk")
    ]

    static let vehicleImageAssetPlan: [MemoryImageAssetPlan] = [
        imagePlan("car", asset: "MemoryVehicleCar", prompt: "kid-friendly side-view car photo or illustration on a clean background", notes: "four wheels clearly visible; avoid brand logos and license plates"),
        imagePlan("bus", asset: "MemoryVehicleBus", prompt: "bright city or school bus, side view, clean background", notes: "large windows and wheels readable at card size"),
        imagePlan("train", asset: "MemoryVehicleTrain", prompt: "locomotive or passenger train on rails, three-quarter view", notes: "rails visible; keep silhouette distinct from bus"),
        imagePlan("plane", asset: "MemoryVehiclePlane", prompt: "airplane in flight or on runway with full wings visible", notes: "wide wing shape must remain legible in square crop"),
        imagePlan("boat", asset: "MemoryVehicleBoat", prompt: "small sailboat or motorboat on water, uncluttered scene", notes: "show waterline; avoid tiny distant boats"),
        imagePlan("bike", asset: "MemoryVehicleBike", prompt: "bicycle side view on clean background", notes: "two wheels and handlebar readable; no rider required"),
        imagePlan("truck", asset: "MemoryVehicleTruck", prompt: "box truck or delivery truck side view, clean background", notes: "large cargo box should distinguish it from car and bus"),
        imagePlan("tractor", asset: "MemoryVehicleTractor", prompt: "farm tractor with large rear tire, field or clean background", notes: "big back wheel is the main recognition cue"),
        imagePlan("helicopter", asset: "MemoryVehicleHelicopter", prompt: "helicopter side view with rotor visible", notes: "rotor and tail boom must fit inside crop"),
        imagePlan("rocket", asset: "MemoryVehicleRocket", prompt: "rocket launch or upright rocket, simple high-contrast composition", notes: "flame plume optional; avoid agency logos unless public-domain provenance is documented"),
        imagePlan("scooter", asset: "MemoryVehicleScooter", prompt: "small scooter or moped side view, clean background", notes: "keep distinct from bike using seat and motor body"),
        imagePlan("taxi", asset: "MemoryVehicleTaxi", prompt: "yellow taxi side or three-quarter view, clean city context", notes: "taxi sign/checker cue useful; avoid visible plate numbers")
    ]

    static let planetImageAssetPlan: [MemoryImageAssetPlan] = [
        imagePlan("planet-mercury", asset: "MemoryPlanetMercury", prompt: "Mercury planet disk, gray cratered surface, black or transparent background", notes: "craters visible; avoid confusing with Moon unless labeled in provenance"),
        imagePlan("planet-venus", asset: "MemoryPlanetVenus", prompt: "Venus planet disk, pale yellow cloud-covered surface", notes: "soft yellow cloud bands; no surface lava imagery unless educationally intentional"),
        imagePlan("planet-earth", asset: "MemoryPlanetEarth", prompt: "Earth planet disk showing blue oceans, green/brown land, white clouds", notes: "full globe preferred; keep recognizable continents/clouds"),
        imagePlan("planet-mars", asset: "MemoryPlanetMars", prompt: "Mars planet disk, rusty red surface with darker markings", notes: "red/orange treatment must be distinct from Venus"),
        imagePlan("planet-jupiter", asset: "MemoryPlanetJupiter", prompt: "Jupiter planet disk with brown cream bands and Great Red Spot", notes: "Great Red Spot is the key recognition cue"),
        imagePlan("planet-saturn", asset: "MemoryPlanetSaturn", prompt: "Saturn with rings, tan/gold planet, transparent or dark background", notes: "rings must fit fully inside square card crop"),
        imagePlan("planet-uranus", asset: "MemoryPlanetUranus", prompt: "Uranus planet disk, pale cyan blue-green, minimal bands", notes: "tilted ring optional only if sourced and legible"),
        imagePlan("planet-neptune", asset: "MemoryPlanetNeptune", prompt: "Neptune planet disk, deep blue with subtle storm/cloud texture", notes: "deeper blue than Uranus; avoid over-saturated fantasy art")
    ]

    static let fishImageAssetPlan: [MemoryImageAssetPlan] = [
        imagePlan("fish-clownfish", asset: "MemoryFishClownfish", prompt: "clownfish with orange body and white bands near coral or sea anemone", notes: "white bands and orange body must be readable; crop out busy reef clutter"),
        imagePlan("fish-goldfish", asset: "MemoryFishGoldfish", prompt: "goldfish side view with rounded body and flowing tail on a clean water background", notes: "orange or gold body should distinguish it from clownfish; avoid bowl-only compositions"),
        imagePlan("fish-betta", asset: "MemoryFishBetta", prompt: "betta fish with large flowing fins, side view, clean aquatic background", notes: "flowing fins are the recognition cue; keep fin edges visible in square crop"),
        imagePlan("fish-angelfish", asset: "MemoryFishAngelfish", prompt: "angelfish with tall triangular fins, side view, simple reef or water background", notes: "tall dorsal and anal fins must stay inside crop; avoid confusing with generic reef fish"),
        imagePlan("fish-catfish", asset: "MemoryFishCatfish", prompt: "catfish with visible whisker-like barbels, side or three-quarter view", notes: "barbels must be clear at card size; prefer uncluttered river or aquarium background"),
        imagePlan("fish-swordtail", asset: "MemoryFishSwordtail", prompt: "swordtail fish side view with long sword-shaped lower tail extension", notes: "tail sword is required for recognition; avoid crops that trim the tail"),
        imagePlan("fish-tuna", asset: "MemoryFishTuna", prompt: "tuna fish with streamlined silver and blue body, side view in open water", notes: "sleek torpedo shape should read clearly; avoid fishing/deck scenes"),
        imagePlan("fish-seahorse", asset: "MemoryFishSeahorse", prompt: "seahorse upright profile with curled tail, clean sea grass or water background", notes: "upright posture and curled tail must be visible; keep subject large in square crop")
    ]

    static let planets: [MemoryAnimal] = [
        planet("planet-mercury", prompt: "☿", name: "Mercury", order: "1st from the Sun", type: "rocky planet", size: "4,879 km wide", colors: "gray", funFact: "A year lasts 88 days"),
        planet("planet-venus", prompt: "♀", name: "Venus", order: "2nd from the Sun", type: "rocky planet", size: "12,104 km wide", colors: "pale yellow", funFact: "It spins very slowly"),
        planet("planet-earth", prompt: "⊕", name: "Earth", order: "3rd from the Sun", type: "rocky planet", size: "12,742 km wide", colors: "blue, green, white", funFact: "It has one moon"),
        planet("planet-mars", prompt: "♂", name: "Mars", order: "4th from the Sun", type: "rocky planet", size: "6,779 km wide", colors: "rusty red", funFact: "It has two small moons"),
        planet("planet-jupiter", prompt: "♃", name: "Jupiter", order: "5th from the Sun", type: "gas giant", size: "139,820 km wide", colors: "brown, cream, orange", funFact: "It is the biggest planet"),
        planet("planet-saturn", prompt: "♄", name: "Saturn", order: "6th from the Sun", type: "gas giant", size: "116,460 km wide", colors: "gold and tan", funFact: "It is famous for bright rings"),
        planet("planet-uranus", prompt: "⛢", name: "Uranus", order: "7th from the Sun", type: "ice giant", size: "50,724 km wide", colors: "icy blue", funFact: "It rotates on its side"),
        planet("planet-neptune", prompt: "♆", name: "Neptune", order: "8th from the Sun", type: "ice giant", size: "49,244 km wide", colors: "deep blue", funFact: "It has very fast winds")
    ]

    static let fishes: [MemoryAnimal] = [
        fish("fish-clownfish", prompt: "Orange reef fish", name: "Clownfish", home: "warm coral reefs", size: "10 to 18 cm long", colors: "orange, white, black", funFact: "It hides safely inside sea anemones"),
        fish("fish-goldfish", prompt: "Golden pond fish", name: "Goldfish", home: "ponds and aquariums", size: "15 to 30 cm long", colors: "gold, orange, white", funFact: "It can remember simple routes and feeding times"),
        fish("fish-betta", prompt: "Flowing fin fish", name: "Betta", home: "slow streams and rice fields", size: "6 to 8 cm long", colors: "red, blue, purple", funFact: "It can breathe some air from the surface"),
        fish("fish-angelfish", prompt: "Tall fin reef fish", name: "Angelfish", home: "coral reefs", size: "15 to 25 cm long", colors: "yellow, blue, black", funFact: "It glides between corals with flat fins"),
        fish("fish-catfish", prompt: "Whiskered river fish", name: "Catfish", home: "rivers, lakes, and ponds", size: "20 to 60 cm long", colors: "gray, brown, black", funFact: "Its whiskers help it sense food in cloudy water"),
        fish("fish-swordtail", prompt: "Tail-sword fish", name: "Swordtail", home: "freshwater streams", size: "8 to 12 cm long", colors: "orange, green, black", funFact: "The male has a long sword-shaped tail"),
        fish("fish-tuna", prompt: "Fast ocean fish", name: "Tuna", home: "open ocean waters", size: "1 to 2 m long", colors: "silver and blue", funFact: "It can swim very fast for long distances"),
        fish("fish-seahorse", prompt: "Tiny upright sea swimmer", name: "Seahorse", home: "sea grass beds and reefs", size: "2 to 15 cm long", colors: "yellow, brown, orange", funFact: "It swims upright and curls its tail")
    ]

    static let countries: [MemoryAnimal] = [
        countryCapital("country-india", country: "India", capital: "New Delhi", continent: "Asia", clue: "home of the Taj Mahal"),
        countryCapital("country-japan", country: "Japan", capital: "Tokyo", continent: "Asia", clue: "known for cherry blossoms and bullet trains"),
        countryCapital("country-france", country: "France", capital: "Paris", continent: "Europe", clue: "home of the Eiffel Tower"),
        countryCapital("country-egypt", country: "Egypt", capital: "Cairo", continent: "Africa", clue: "home of the Great Pyramids"),
        countryCapital("country-brazil", country: "Brazil", capital: "Brasília", continent: "South America", clue: "home of the Amazon rainforest"),
        countryCapital("country-australia", country: "Australia", capital: "Canberra", continent: "Australia", clue: "home of kangaroos and koalas"),
        countryCapital("country-canada", country: "Canada", capital: "Ottawa", continent: "North America", clue: "known for maple leaves and snowy winters"),
        countryCapital("country-kenya", country: "Kenya", capital: "Nairobi", continent: "Africa", clue: "known for savannas and wildlife parks")
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

    static let allAnimalsById: [String: MemoryAnimal] = {
        Dictionary(uniqueKeysWithValues: (domesticAnimals + birds + vehicles + planets + fishes + countries + indiaStates).map { ($0.id, $0) })
    }()


    private static func imagePlan(_ cardId: String, asset: String, prompt: String, notes: String) -> MemoryImageAssetPlan {
        MemoryImageAssetPlan(
            cardId: cardId,
            assetName: asset,
            searchPrompt: prompt,
            styleNotes: notes,
            status: .needsVettedSource
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

    private static func vehicle(_ id: String, name: String, emoji: String, use: String, movement: String, colors: String, sound: String?) -> MemoryAnimal {
        MemoryAnimal(
            id: id,
            name: name,
            picture: .emoji(emoji),
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

    private static func planet(_ id: String, prompt: String, name: String, order: String, type: String, size: String, colors: String, funFact: String) -> MemoryAnimal {
        MemoryAnimal(
            id: id,
            name: name,
            picture: .text(prompt),
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

    private static func fish(_ id: String, prompt: String, name: String, home: String, size: String, colors: String, funFact: String) -> MemoryAnimal {
        MemoryAnimal(
            id: id,
            name: name,
            picture: .text(prompt),
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

    private static func countryCapital(_ id: String, country: String, capital: String, continent: String, clue: String) -> MemoryAnimal {
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
                    MemoryFactCard(title: "Continent", value: continent),
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
    @State private var recentPairHistory: [String] = []
    @State private var learningContent: MemoryLearningContent? = nil

    enum DeckSelection: CaseIterable {
        case domestic, birds, vehicles, planets, fishes, countries, indiaStates

        var label: String {
            switch self {
            case .domestic: return "🐄 Animals"
            case .birds: return "🦜 Birds"
            case .vehicles: return "🚗 Vehicles"
            case .planets: return "🪐 Planets"
            case .fishes: return "🐠 Fishes"
            case .countries: return "🌍 Countries & Capitals"
            case .indiaStates: return "📍 India States & Capitals"
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
            case .indiaStates: return "India States & Capitals"
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
            case .indiaStates: return MemoryDeck.indiaStates
            }
        }
    }

    private var totalPairs: Int { difficulty.pairCount }

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
            HStack(alignment: .top, spacing: 12) {
                Button {
                    appModel.engine.showLab()
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(MatherTheme.accent)
                        .frame(width: 44, height: 44)
                }
                .accessibilityLabel("Back")

                VStack(alignment: .leading, spacing: 2) {
                    Text("Memory Match")
                        .font(.title2.weight(.black))
                        .foregroundStyle(MatherTheme.ink)
                    Text("\(matchedPairs)/\(totalPairs) pairs matched")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(MatherTheme.cardSubtitle)
                }

                Spacer(minLength: 0)
            }

            CardSurface {
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
                cardView(card)
                    .aspectRatio(ResponsiveLayout.memoryCardAspectRatio(for: difficulty), contentMode: .fit)
                    .accessibilityIdentifier(Self.accessibilityIdentifier(for: card))
                    .onTapGesture(count: 2) { handleDoubleTap(card) }
                    .onTapGesture { handleTap(card) }
            }
        }
        .frame(maxWidth: ResponsiveLayout.memoryBoardMaxWidth(for: horizontalSizeClass))
        .frame(maxWidth: .infinity)
    }

    @ViewBuilder
    private func cardView(_ card: MemoryCard) -> some View {
        GeometryReader { proxy in
            let cardHeight = proxy.size.height
            let isMismatch = mismatchIds.contains(card.id)
            let isFlipped = difficulty.faceDown && !card.isSelected && !card.isMatched

            ZStack {
                if isFlipped {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(LinearGradient(colors: [MatherTheme.accent.opacity(0.7), MatherTheme.softBlue.opacity(0.7)], startPoint: .topLeading, endPoint: .bottomTrailing))
                    Text("?")
                        .font(.system(size: min(44, max(32, cardHeight * 0.34)), weight: .black, design: .rounded))
                        .foregroundStyle(.white.opacity(0.6))
                } else {
                    cardFace(card, cardHeight: cardHeight)
                }
            }
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(card.isSelected ? MatherTheme.accent : (card.isMatched ? Color.green : Color.clear), lineWidth: card.isSelected ? 3 : 2)
            )
            .scaleEffect(card.isMatched ? 0.92 : 1.0)
            .opacity(card.isMatched ? 0.68 : 1.0)
            .rotationEffect(isMismatch ? .degrees(-3) : .zero)
            .animation(.spring(response: 0.25, dampingFraction: 0.6), value: card.isSelected)
            .animation(.easeOut(duration: 0.3), value: card.isMatched)
            .animation(isMismatch ? .easeInOut(duration: 0.08).repeatCount(3, autoreverses: true) : .default, value: isMismatch)
        }
    }

    @ViewBuilder
    private func cardFace(_ card: MemoryCard, cardHeight: CGFloat) -> some View {
        let animal = animal(for: card)
        let artStyle = Self.artStyle(for: animal.id)

        switch card.content {
        case .picture(let pictureAnimal):
            ZStack {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(LinearGradient(colors: card.isMatched ? [Color.green.opacity(0.24), Color.green.opacity(0.10)] : [artStyle.topColor, artStyle.bottomColor], startPoint: .topLeading, endPoint: .bottomTrailing))

                Circle()
                    .fill(Color.white.opacity(colorScheme == .dark ? 0.08 : 0.24))
                    .frame(width: cardHeight * 0.72, height: cardHeight * 0.72)
                    .offset(x: cardHeight * 0.16, y: -cardHeight * 0.18)

                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color.white.opacity(colorScheme == .dark ? 0.08 : 0.16))
                    .frame(width: cardHeight * 0.52, height: cardHeight * 0.16)
                    .offset(x: -cardHeight * 0.14, y: cardHeight * 0.24)
                    .rotationEffect(.degrees(-10))

                Image(systemName: artStyle.ornament)
                    .font(.system(size: difficulty == .hard ? 12 : 14, weight: .black))
                    .foregroundStyle(artStyle.ornamentColor.opacity(0.95))
                    .padding(8)
                    .background(Color.white.opacity(colorScheme == .dark ? 0.10 : 0.22), in: Circle())
                    .offset(x: -cardHeight * 0.28, y: -cardHeight * 0.26)

                Circle()
                    .fill(LinearGradient(colors: [artStyle.badgeHighlight, artStyle.badgeColor], startPoint: .top, endPoint: .bottom))
                    .frame(width: cardHeight * 0.62, height: cardHeight * 0.62)
                    .shadow(color: artStyle.badgeColor.opacity(0.25), radius: 10, y: 6)

                Circle()
                    .strokeBorder(Color.white.opacity(colorScheme == .dark ? 0.16 : 0.55), lineWidth: 3)
                    .frame(width: cardHeight * 0.62, height: cardHeight * 0.62)

                pictureView(for: pictureAnimal, emojiSize: min(58, max(34, cardHeight * 0.42)))
                    .frame(width: cardHeight * 0.64, height: cardHeight * 0.64)
            }

        case .label(let labelAnimal):
            ZStack {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(LinearGradient(colors: card.isMatched ? [Color.green.opacity(0.18), Color.green.opacity(0.08)] : [artStyle.topColor.opacity(0.30), artStyle.bottomColor.opacity(0.18)], startPoint: .topLeading, endPoint: .bottomTrailing))

                VStack(spacing: 8) {
                    HStack(spacing: 6) {
                        Image(systemName: artStyle.ornament)
                            .font(.caption.weight(.black))
                        Text("Find the match")
                            .font(.caption2.weight(.bold))
                            .lineLimit(1)
                            .minimumScaleFactor(0.85)
                    }
                    .foregroundStyle(artStyle.ornamentColor)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 5)
                    .background(Color.white.opacity(colorScheme == .dark ? 0.08 : 0.45), in: Capsule())

                    Text(labelAnimal.name)
                        .font(.system(size: Self.labelFontSize(for: difficulty), weight: .black, design: .rounded))
                        .foregroundStyle(MatherTheme.ink)
                        .lineLimit(2)
                        .minimumScaleFactor(Self.labelMinimumScaleFactor(for: difficulty))
                        .allowsTightening(true)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.horizontal, Self.labelHorizontalPadding(for: difficulty))
                        .frame(maxWidth: .infinity, minHeight: cardHeight * 0.34)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 10)
            }
        }
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

                Text(deckSelection == .birds ? "Double-tap any bird card to learn more, or start the next round." : "Round \(roundsPlayed) complete")
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

    static func canOpenLearningDetails(for card: MemoryCard, deckSelection: DeckSelection, difficulty: MemoryDifficulty, showRoundComplete: Bool) -> Bool {
        guard supportsLearningDetails(for: deckSelection) else { return false }
        if card.isMatched { return true }
        guard !showRoundComplete else { return false }
        return difficulty.faceDown ? card.isSelected : true
    }

    static func supportsLearningDetails(for deckSelection: DeckSelection) -> Bool {
        !deckSelection.animals.isEmpty
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
                    Button("Done") { learningContent = nil }
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
        case .indiaStates:
            deckLabel = "India Guide"
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
