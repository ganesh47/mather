import Foundation

// MARK: - Data model

enum MemoryPicture: Equatable, Codable {
    case emoji(String)
    case asset(String)
    case text(String)

    private enum CodingKeys: String, CodingKey { case kind, value }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        let value = try values.decode(String.self, forKey: .value)
        switch try values.decode(String.self, forKey: .kind) {
        case "emoji": self = .emoji(value)
        case "asset": self = .asset(value)
        case "text": self = .text(value)
        default: throw DecodingError.dataCorruptedError(forKey: .kind, in: values, debugDescription: "Unsupported picture kind")
        }
    }

    func encode(to encoder: Encoder) throws {
        var values = encoder.container(keyedBy: CodingKeys.self)
        let kind: String
        let value: String
        switch self {
        case .emoji(let text): kind = "emoji"; value = text
        case .asset(let name): kind = "asset"; value = name
        case .text(let text): kind = "text"; value = text
        }
        try values.encode(kind, forKey: .kind)
        try values.encode(value, forKey: .value)
    }
}

struct MemoryFactCard: Equatable, Hashable, Codable {
    let title: String
    let value: String
}

struct MemoryLearningArtwork: Equatable, Hashable, Codable {
    let title: String
    let assetName: String
}

enum MemoryDeckKind: String, CaseIterable, Equatable, Hashable, Codable {
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

struct MemoryCardMetadata: Equatable, Codable {
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

struct MemoryImageAssetProvenance: Equatable, Codable {
    let assetName: String
    let cardId: String
    let sourceName: String
    let sourceUrl: String
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

struct MemoryAnimal: Identifiable, Equatable, Codable {
    let id: String
    let name: String
    let canonicalName: String
    let picture: MemoryPicture
    let metadata: MemoryCardMetadata
    let learningArtwork: [MemoryLearningArtwork]

    init(
        id: String,
        name: String,
        canonicalName: String? = nil,
        picture: MemoryPicture,
        metadata: MemoryCardMetadata,
        learningArtwork: [MemoryLearningArtwork] = []
    ) {
        self.id = id
        self.name = name
        self.canonicalName = canonicalName ?? name
        self.picture = picture
        self.metadata = metadata
        self.learningArtwork = learningArtwork
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

// MARK: - Decks

enum MemoryDeck {
    static let availableDeckKinds: [MemoryDeckKind] = MemoryDeckKind.allCases

    static func animals(for kind: MemoryDeckKind) -> [MemoryAnimal] {
        switch kind {
        case .domesticAnimals: return domesticAnimals
        case .birds: return birds
        case .vehicles: return vehicles
        case .planets: return planets
        case .fishes: return fishes
        case .countries: return countries
        case .countryFlags: return countryFlags
        case .indiaStates: return indiaStates
        case .waterCycle: return waterCycle
        case .fruits: return fruits
        case .numberBondsTo10: return numberBondsTo10
        }
    }

    static let allDeckAnimals: [MemoryAnimal] = availableDeckKinds.flatMap { animals(for: $0) }

    static let domesticAnimals: [MemoryAnimal] = [
        domesticAnimal("cow", name: "Cow", asset: "MemoryAnimalCow", habitat: "farms and grassy fields", colors: "black and white", sound: "gentle moo", movement: "walks on four sturdy legs"),
        domesticAnimal("dog", name: "Dog", asset: "MemoryAnimalDog", habitat: "homes, parks, and farms", colors: "many coat colors", sound: "happy bark", movement: "runs and plays quickly"),
        domesticAnimal("cat", name: "Cat", asset: "MemoryAnimalCat", habitat: "homes and gardens", colors: "many fur colors", sound: "soft meow", movement: "tiptoes and pounces"),
        domesticAnimal("sheep", name: "Sheep", asset: "CompareCampSheep", habitat: "farms and open pastures", colors: "white and cream", sound: "gentle baa", movement: "walks together in flocks"),
        domesticAnimal("pig", name: "Pig", asset: "MemoryAnimalPig", habitat: "barnyards and farms", colors: "pink, brown, or black", sound: "snort and oink", movement: "trots and roots around"),
        domesticAnimal("horse", name: "Horse", asset: "MemoryAnimalHorse", habitat: "stables, ranches, and fields", colors: "brown, black, white, or chestnut", sound: "neigh", movement: "gallops fast"),
        domesticAnimal("rabbit", name: "Rabbit", asset: "MemoryAnimalRabbit", habitat: "gardens, meadows, and homes", colors: "white, brown, gray", sound: "quiet squeaks", movement: "hops with long back legs"),
        domesticAnimal("duck", name: "Duck", asset: "MemoryAnimalDuck", habitat: "ponds, lakes, and farms", colors: "white, brown, or green", sound: "quack", movement: "waddles, swims, and flies short distances"),
        domesticAnimal("rooster", name: "Rooster", asset: "MemoryAnimalRooster", habitat: "farmyards", colors: "red, gold, green", sound: "cock-a-doodle-doo", movement: "struts and flaps"),
        domesticAnimal("goat", name: "Goat", asset: "MemoryAnimalGoat", habitat: "farms and rocky hills", colors: "white, brown, black", sound: "maa", movement: "climbs and balances well"),
        domesticAnimal("turkey", name: "Turkey", asset: "MemoryAnimalTurkey", habitat: "farms and woodlands", colors: "brown, bronze, black", sound: "gobble", movement: "walks with strong legs"),
        domesticAnimal("goldfish", name: "Goldfish", asset: "MemoryAnimalGoldfish", habitat: "ponds and aquariums", colors: "orange and gold", sound: nil, movement: "swims with a swishy tail"),
        domesticAnimal("mouse", name: "Mouse", asset: "MemoryAnimalMouse", habitat: "fields, barns, and homes", colors: "gray, brown, white", sound: "tiny squeak", movement: "scurries fast"),
        domesticAnimal("frog", name: "Frog", asset: "MemoryAnimalFrog", habitat: "ponds, streams, and wet grass", colors: "green and brown", sound: "ribbit", movement: "jumps and swims"),
        domesticAnimal("camel", name: "Camel", asset: "MemoryAnimalCamel", habitat: "deserts and dry plains", colors: "sand and tan", sound: "grumbly groan", movement: "walks far on long legs"),
        domesticAnimal("llama", name: "Llama", asset: "MemoryAnimalLlama", habitat: "mountain farms and grasslands", colors: "white, brown, black", sound: "soft hum", movement: "walks sure-footedly"),
        domesticAnimal("donkey", name: "Donkey", asset: "MemoryAnimalDonkey", habitat: "farms and dry grasslands", colors: "gray or brown", sound: "hee-haw", movement: "walks steadily and carries loads"),
        domesticAnimal("ox", name: "Ox", asset: "MemoryAnimalOx", habitat: "farms and fields", colors: "brown, black, white", sound: "deep moo", movement: "pulls and plods with strength")
    ]

    static let birds: [MemoryAnimal] = [
        bird("bird-a01", name: "Scarlet Macaw", asset: "CompareCampMacaw", home: "South American rainforests", lifespan: "40 to 50 years", weight: "0.9 to 1.2 kg", size: "80 to 90 cm long", colors: "red, yellow, blue"),
        bird("bird-a02", name: "Yellow-billed Toucan", asset: "MemoryBirdCleanA02", home: "Central and South American forests", lifespan: "15 to 20 years", weight: "0.3 to 0.5 kg", size: "50 to 60 cm long", colors: "black, yellow, orange"),
        bird("bird-a03", name: "Yellow-crested Cockatoo", asset: "MemoryBirdCleanA03", home: "Australia and nearby islands", lifespan: "40 to 70 years", weight: "0.8 to 1.0 kg", size: "45 to 55 cm long", colors: "white and yellow"),
        bird("bird-a04", name: "Hummingbird", asset: "MemoryBirdCleanA04", home: "Tropical Americas", lifespan: "3 to 5 years", weight: "3 to 6 g", size: "8 to 12 cm long", colors: "green, purple, teal"),
        bird("bird-a05", name: "Blue Macaw", asset: "MemoryBirdCleanA05", home: "South American forests", lifespan: "35 to 50 years", weight: "1.0 to 1.4 kg", size: "85 to 100 cm long", colors: "blue and gold"),
        bird("bird-a06", name: "Kingfisher", asset: "MemoryBirdCleanA06", home: "Asian and Oceanian waterways", lifespan: "6 to 10 years", weight: "30 to 45 g", size: "16 to 20 cm long", colors: "blue and orange"),
        bird("bird-a07", name: "Sunbird", asset: "MemoryBirdCleanA07", home: "African and Asian gardens and forests", lifespan: "3 to 5 years", weight: "4 to 7 g", size: "10 to 14 cm long", colors: "gold, orange, brown"),
        bird("bird-a08", name: "Pied Kingfisher", asset: "MemoryBirdCleanA08", home: "Rivers and lakes in Africa and Asia", lifespan: "Varies by individual", weight: "Varies by individual", size: "25 to 30 cm long", colors: "black and white"),
        bird("bird-a09", name: "Orange-billed Toucan", asset: "MemoryBirdCleanA09", home: "Tropical South America", lifespan: "15 to 20 years", weight: "0.5 to 0.7 kg", size: "55 to 65 cm long", colors: "black, white, orange"),
        bird("bird-a10", name: "Green Parrot", asset: "MemoryBirdCleanA10", home: "Tropical forests", lifespan: "20 to 30 years", weight: "0.2 to 0.4 kg", size: "25 to 35 cm long", colors: "green, yellow, red"),
        bird("bird-a11", name: "Palm Bird", asset: "MemoryBirdCleanA11", home: "New Guinea and northern Australia", lifespan: "40 to 60 years", weight: "0.9 to 1.2 kg", size: "55 to 65 cm long", colors: "charcoal and red"),
        bird("bird-a12", name: "Flamingo", asset: "CompareCampFlamingo", home: "Warm lakes and lagoons", lifespan: "20 to 30 years", weight: "2 to 3 kg", size: "100 to 140 cm tall", colors: "pink and coral"),
        bird("bird-a13", name: "Blue Bird", asset: "MemoryBirdCleanA13", home: "Forest edges in tropical America", lifespan: "10 to 15 years", weight: "0.2 to 0.3 kg", size: "25 to 35 cm long", colors: "blue and gold"),
        bird("bird-a14", name: "Red-faced Parrot", asset: "MemoryBirdCleanA14", home: "Oceania rainforests", lifespan: "20 to 35 years", weight: "0.2 to 0.4 kg", size: "30 to 35 cm long", colors: "green and red"),
        bird("bird-a15", name: "Songbird", asset: "MemoryBirdCleanA15", home: "Tropical gardens and forests", lifespan: "6 to 10 years", weight: "25 to 40 g", size: "15 to 18 cm long", colors: "green and yellow"),
        bird("bird-a16", name: "Hoopoe", asset: "MemoryBirdCleanA16", home: "Africa, Europe, and Asia", lifespan: "8 to 10 years", weight: "45 to 90 g", size: "25 to 32 cm long", colors: "cinnamon, black, white"),
        bird("bird-a17", name: "Crested Bird", asset: "MemoryBirdCleanA17", home: "Island forests", lifespan: "10 to 15 years", weight: "0.2 to 0.4 kg", size: "25 to 35 cm long", colors: "white, blue, silver"),
        bird("bird-a18", name: "Ibis", asset: "MemoryBirdCleanA18", home: "South American wetlands", lifespan: "15 to 20 years", weight: "0.8 to 1.2 kg", size: "55 to 65 cm long", colors: "scarlet red"),
        bird("bird-b01", name: "Blue-and-gold Macaw", asset: "MemoryBirdCleanB01", home: "South American rainforests", lifespan: "35 to 50 years", weight: "0.9 to 1.3 kg", size: "75 to 90 cm long", colors: "blue and gold"),
        bird("bird-b02", name: "Spoonbill", asset: "MemoryBirdCleanB02", home: "American marshes and coasts", lifespan: "10 to 15 years", weight: "1.2 to 1.8 kg", size: "70 to 85 cm long", colors: "pink and white"),
        bird("bird-b03", name: "Finch", asset: "MemoryBirdCleanB03", home: "Northern Australia", lifespan: "4 to 8 years", weight: "12 to 16 g", size: "12 to 14 cm long", colors: "green, yellow, purple"),
        bird("bird-b04", name: "Crowned Bird", asset: "MemoryBirdCleanB04", home: "New Guinea forests", lifespan: "15 to 25 years", weight: "2.0 to 2.5 kg", size: "65 to 75 cm tall", colors: "blue and maroon"),
        bird("bird-b05", name: "Red-and-green Parrot", asset: "MemoryBirdCleanB05", home: "South American forests", lifespan: "25 to 35 years", weight: "0.3 to 0.5 kg", size: "30 to 40 cm long", colors: "red and green"),
        bird("bird-b06", name: "Green Bird", asset: "MemoryBirdCleanB06", home: "African forest canopies", lifespan: "8 to 12 years", weight: "0.2 to 0.4 kg", size: "30 to 40 cm long", colors: "emerald green"),
        bird("bird-b07", name: "White Cockatoo", asset: "MemoryBirdCleanB07", home: "Australia", lifespan: "30 to 50 years", weight: "0.5 to 0.8 kg", size: "40 to 50 cm long", colors: "white and yellow"),
        bird("bird-b08", name: "Parrotlet", asset: "MemoryBirdCleanB08", home: "Dry forests of the Americas", lifespan: "8 to 12 years", weight: "25 to 35 g", size: "12 to 15 cm long", colors: "green and blue"),
        bird("bird-b09", name: "Storybook Golden Bird", asset: "MemoryBirdCleanB09", home: "Asian mountain forests", lifespan: "6 to 10 years", weight: "0.6 to 0.8 kg", size: "90 to 110 cm long", colors: "gold, red, green"),
        bird("bird-b10", name: "Turaco", asset: "MemoryBirdCleanB10", home: "African forests", lifespan: "10 to 15 years", weight: "0.2 to 0.4 kg", size: "35 to 45 cm long", colors: "green and crimson"),
        bird("bird-b11", name: "Peafowl", asset: "CompareCampPeafowl", home: "India and Sri Lanka", lifespan: "15 to 20 years", weight: "4 to 6 kg", size: "90 to 115 cm body length", colors: "blue and emerald"),
        bird("bird-b12", name: "Yellow-green Bird", asset: "MemoryBirdCleanB12", home: "Woodland edges", lifespan: "8 to 12 years", weight: "0.2 to 0.3 kg", size: "25 to 35 cm long", colors: "green and yellow"),
        bird("bird-b13", name: "Coral Ibis", asset: "MemoryBirdCleanB13", home: "Tropical wetlands", lifespan: "15 to 20 years", weight: "0.8 to 1.2 kg", size: "55 to 65 cm long", colors: "red and coral"),
        bird("bird-b14", name: "Pink Cockatoo", asset: "MemoryBirdCleanB14", home: "Inland Australia", lifespan: "40 to 60 years", weight: "0.3 to 0.4 kg", size: "35 to 40 cm long", colors: "pink and white"),
        bird("bird-b15", name: "Garden Peafowl", asset: "MemoryBirdCleanB15", home: "Asian grasslands and gardens", lifespan: "15 to 20 years", weight: "3 to 5 kg", size: "85 to 100 cm body length", colors: "blue, green, bronze"),
        bird("bird-b16", name: "Puffin", asset: "CompareCampPuffin", home: "North Atlantic coasts", lifespan: "20 to 25 years", weight: "0.3 to 0.5 kg", size: "28 to 34 cm long", colors: "black, white, orange"),
        bird("bird-b17", name: "Black Palm", asset: "MemoryBirdCleanB17", home: "New Guinea and Australia", lifespan: "40 to 60 years", weight: "0.8 to 1.1 kg", size: "55 to 65 cm long", colors: "charcoal and red"),
        bird("bird-b18", name: "Bee-eater", asset: "MemoryBirdCleanB18", home: "Africa and South Asia", lifespan: "5 to 8 years", weight: "20 to 35 g", size: "20 to 25 cm long", colors: "green, blue, gold")
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
        vehicle("taxi", name: "Taxi", emoji: "🚕", asset: "MemoryVehicleTaxi", use: "gives people rides around town", movement: "drives on busy roads", colors: "yellow and black", sound: "honk honk"),

        // Look inside a vehicle: one clear job and motion clue per mechanical part.
        vehiclePart("vehicle-part-engine", name: "Engine", asset: "MemoryVehiclePartEngine", foundIn: "under the hood or behind the cab", job: "turns fuel or electricity into motion", howItWorks: "moving parts spin a shaft that helps turn the wheels", remember: "The engine makes the power"),
        vehiclePart("vehicle-part-transmission", name: "Gears", asset: "MemoryVehiclePartTransmission", foundIn: "between the engine and the driven wheels", job: "chooses how strongly or quickly the wheels turn", howItWorks: "different-sized gears trade speed for turning force", remember: "Low gear gives more push; high gear helps with speed"),
        vehiclePart("vehicle-part-brakes", name: "Brakes", asset: "MemoryVehiclePartBrakes", foundIn: "beside each wheel", job: "slows or stops the vehicle", howItWorks: "pads squeeze a spinning disc to make friction", remember: "Friction changes motion into heat"),
        vehiclePart("vehicle-part-wheel-axle", name: "Wheel & Axle", asset: "MemoryVehiclePartWheelAxle", foundIn: "under the vehicle", job: "supports the vehicle and lets it roll", howItWorks: "the axle turns while round wheels travel over the ground", remember: "A wheel and axle is a simple machine"),
        vehiclePart("vehicle-part-steering", name: "Steering", asset: "MemoryVehiclePartSteering", foundIn: "from the driver controls to the front wheels", job: "points the vehicle in a new direction", howItWorks: "turning the steering wheel angles the road wheels", remember: "Steering changes direction, not speed"),
        vehiclePart("vehicle-part-suspension", name: "Suspension", asset: "MemoryVehiclePartSuspension", foundIn: "between each wheel and the vehicle body", job: "helps the tires stay on the ground over bumps", howItWorks: "springs flex and shock absorbers calm the bouncing", remember: "Suspension makes the ride steadier"),

        // Worksite, hauling, mining, and rescue vehicles with distinctive mechanisms.
        advancedVehicle("mobile-crane", name: "Mobile Crane", asset: "MemoryVehicleMobileCrane", group: "crane", job: "lifts heavy loads at changing worksites", keyPart: "telescoping boom and outriggers", howItWorks: "hydraulic cylinders extend the boom while outriggers make a wide, steady base", safetyFact: "The load must stay within the crane's lifting limit"),
        advancedVehicle("crawler-crane", name: "Crawler Crane", asset: "MemoryVehicleCrawlerCrane", group: "crane", job: "lifts very heavy loads on rough ground", keyPart: "lattice boom and wide crawler tracks", howItWorks: "tracks spread the crane's weight and cables raise the hook", safetyFact: "A clear swing area keeps people away from the moving boom"),
        advancedVehicle("wheel-loader", name: "Wheel Loader", asset: "MemoryVehicleWheelLoader", group: "loader", job: "scoops and carries loose rock, sand, or soil", keyPart: "large front bucket", howItWorks: "hydraulic arms lift the bucket and a hinged middle helps it steer", safetyFact: "The bucket stays low while travelling for better balance"),
        advancedVehicle("skid-steer-loader", name: "Skid-Steer Loader", asset: "MemoryVehicleSkidSteerLoader", group: "loader", job: "works in small construction spaces", keyPart: "lift arms with changeable attachments", howItWorks: "wheels on opposite sides turn at different speeds so it can pivot", safetyFact: "The safety bar helps protect the operator"),
        advancedVehicle("backhoe-loader", name: "Backhoe Loader", asset: "MemoryVehicleBackhoeLoader", group: "loader", job: "loads material and digs trenches", keyPart: "front bucket and rear backhoe", howItWorks: "hydraulics move both tools and stabilizer legs steady the machine", safetyFact: "Only one digging end works at a time"),
        advancedVehicle("dump-truck", name: "Dump Truck", asset: "MemoryVehicleDumpTruck", group: "truck", job: "carries and unloads sand, gravel, or soil", keyPart: "tilting cargo bed", howItWorks: "a hydraulic ram lifts the front of the bed so material slides out", safetyFact: "It unloads only on firm, level ground"),
        advancedVehicle("concrete-mixer-truck", name: "Mixer Truck", asset: "MemoryVehicleConcreteMixerTruck", group: "truck", job: "brings wet concrete to a building site", keyPart: "rotating mixing drum", howItWorks: "spiral blades mix while turning one way and unload while turning the other way", safetyFact: "Workers keep clear of the turning drum and chute"),
        advancedVehicle("garbage-truck", name: "Garbage Truck", asset: "MemoryVehicleGarbageTruck", group: "truck", job: "collects rubbish and carries it away", keyPart: "lifting hopper and compactor", howItWorks: "the hopper lifts bins and the compactor presses rubbish into less space", safetyFact: "Flashing lights warn others when the truck stops often"),
        advancedVehicle("tow-truck", name: "Tow Truck", asset: "MemoryVehicleTowTruck", group: "truck", job: "moves a vehicle that cannot drive", keyPart: "wheel lift or flatbed", howItWorks: "a winch pulls the vehicle and strong straps hold it securely", safetyFact: "Warning lights help drivers see the stopped tow truck"),
        advancedVehicle("mining-haul-truck", name: "Mining Haul Truck", asset: "MemoryVehicleMiningHaulTruck", group: "mining vehicle", job: "carries huge loads of rock at a mine", keyPart: "giant tires and reinforced dump body", howItWorks: "a powerful drive system moves loads on steep mine roads", safetyFact: "Smaller vehicles stay where the driver can see them"),
        advancedVehicle("excavator", name: "Excavator", asset: "MemoryVehicleExcavator", group: "earthmover", job: "digs deep holes and moves earth", keyPart: "boom, stick, bucket, and rotating cab", howItWorks: "hydraulic cylinders move the arm and the upper body turns on a platform", safetyFact: "People stay outside its wide swing area"),
        advancedVehicle("bulldozer", name: "Bulldozer", asset: "MemoryVehicleBulldozer", group: "earthmover", job: "pushes soil and levels rough ground", keyPart: "wide front blade and crawler tracks", howItWorks: "tracks grip loose ground while the blade pushes material", safetyFact: "The driver checks the ground before working near an edge"),
        advancedVehicle("fire-engine", name: "Fire Engine", asset: "MemoryVehicleFireEngine", group: "emergency vehicle", job: "brings firefighters, water, hoses, and tools", keyPart: "water pump and hose connections", howItWorks: "the pump adds pressure so water can travel through a hose", safetyFact: "Sirens and flashing lights ask traffic to make a safe path"),
        advancedVehicle("ambulance", name: "Ambulance", asset: "MemoryVehicleAmbulance", group: "emergency vehicle", job: "brings medical helpers and carries patients safely", keyPart: "stretcher and medical equipment", howItWorks: "a secure treatment cabin lets helpers care for a patient while travelling", safetyFact: "Seat belts hold everyone safely during the ride"),
        advancedVehicle("police-car", name: "Police Car", asset: "MemoryVehiclePoliceCar", group: "emergency vehicle", job: "helps officers reach emergencies and keep roads safe", keyPart: "radio, lights, and siren", howItWorks: "the radio shares information while lights and siren warn nearby traffic", safetyFact: "Drivers slow down and make space when it approaches"),
        advancedVehicle("rescue-helicopter", name: "Rescue Helicopter", asset: "MemoryVehicleRescueHelicopter", group: "emergency aircraft", job: "reaches people where roads cannot", keyPart: "main rotor and rescue winch", howItWorks: "rotor blades make lift and the winch raises a rescuer or patient", safetyFact: "Loose objects must stay far from the powerful rotor wind")
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
        importedImagePlan("taxi", asset: "MemoryVehicleTaxi", prompt: "yellow taxi side or three-quarter view, clean city context", notes: "taxi sign/checker cue useful; avoid visible plate numbers", sourceName: "Project-owned deterministic drawing", license: "Project-owned"),
        importedImagePlan("vehicle-part-engine", asset: "MemoryVehiclePartEngine", prompt: "kid-friendly cutaway engine showing pistons and crankshaft", notes: "focus on the engine; use simple color coding and no tiny labels", sourceName: "Codex project-owned vehicle learning artwork", license: "Project-owned"),
        importedImagePlan("vehicle-part-transmission", asset: "MemoryVehiclePartTransmission", prompt: "large and small vehicle gears meshing inside a simple transmission cutaway", notes: "gear teeth and size difference must read at card size", sourceName: "Codex project-owned vehicle learning artwork", license: "Project-owned"),
        importedImagePlan("vehicle-part-brakes", asset: "MemoryVehiclePartBrakes", prompt: "vehicle brake disc with caliper and pads in a clean cutaway", notes: "make the squeezing pads visually clear without arrows or labels", sourceName: "Codex project-owned vehicle learning artwork", license: "Project-owned"),
        importedImagePlan("vehicle-part-wheel-axle", asset: "MemoryVehiclePartWheelAxle", prompt: "two vehicle wheels connected by one visible axle", notes: "simple-machine relationship should be unmistakable", sourceName: "Codex project-owned vehicle learning artwork", license: "Project-owned"),
        importedImagePlan("vehicle-part-steering", asset: "MemoryVehiclePartSteering", prompt: "steering wheel and linkage visibly connected to angled front wheels", notes: "show cause and effect in one uncluttered cutaway", sourceName: "Codex project-owned vehicle learning artwork", license: "Project-owned"),
        importedImagePlan("vehicle-part-suspension", asset: "MemoryVehiclePartSuspension", prompt: "vehicle coil spring and shock absorber beside a wheel", notes: "spring and shock absorber must both remain distinct", sourceName: "Codex project-owned vehicle learning artwork", license: "Project-owned"),
        importedImagePlan("mobile-crane", asset: "MemoryVehicleMobileCrane", prompt: "mobile truck crane with telescoping boom, hook, and deployed outriggers", notes: "show all outriggers and keep boom inside the square crop", sourceName: "Codex project-owned vehicle learning artwork", license: "Project-owned"),
        importedImagePlan("crawler-crane", asset: "MemoryVehicleCrawlerCrane", prompt: "crawler crane with lattice boom, hook cables, and wide tracks", notes: "lattice boom and tracks distinguish it from mobile crane", sourceName: "Codex project-owned vehicle learning artwork", license: "Project-owned"),
        importedImagePlan("wheel-loader", asset: "MemoryVehicleWheelLoader", prompt: "articulated wheel loader carrying stones in a raised front bucket", notes: "hinged middle, four tires, and bucket should be visible", sourceName: "Codex project-owned vehicle learning artwork", license: "Project-owned"),
        importedImagePlan("skid-steer-loader", asset: "MemoryVehicleSkidSteerLoader", prompt: "compact skid-steer loader with side lift arms and front bucket", notes: "compact proportions and side arms distinguish it from wheel loader", sourceName: "Codex project-owned vehicle learning artwork", license: "Project-owned"),
        importedImagePlan("backhoe-loader", asset: "MemoryVehicleBackhoeLoader", prompt: "backhoe loader side view with front bucket and rear digging arm", notes: "both tools must fit fully and read clearly", sourceName: "Codex project-owned vehicle learning artwork", license: "Project-owned"),
        importedImagePlan("dump-truck", asset: "MemoryVehicleDumpTruck", prompt: "construction dump truck tipping a raised cargo bed", notes: "raised bed is the main recognition cue", sourceName: "Codex project-owned vehicle learning artwork", license: "Project-owned"),
        importedImagePlan("concrete-mixer-truck", asset: "MemoryVehicleConcreteMixerTruck", prompt: "concrete mixer truck with spiral drum and unloading chute", notes: "large drum silhouette and chute should be visible", sourceName: "Codex project-owned vehicle learning artwork", license: "Project-owned"),
        importedImagePlan("garbage-truck", asset: "MemoryVehicleGarbageTruck", prompt: "garbage truck lifting a bin into its rear hopper", notes: "show the lifting mechanism without logos or text", sourceName: "Codex project-owned vehicle learning artwork", license: "Project-owned"),
        importedImagePlan("tow-truck", asset: "MemoryVehicleTowTruck", prompt: "tow truck using a wheel lift and winch to carry a small car", notes: "connection between truck and car should be clear", sourceName: "Codex project-owned vehicle learning artwork", license: "Project-owned"),
        importedImagePlan("mining-haul-truck", asset: "MemoryVehicleMiningHaulTruck", prompt: "giant mining haul truck beside a tiny pickup truck for scale", notes: "huge tires and deep dump body are key recognition cues", sourceName: "Codex project-owned vehicle learning artwork", license: "Project-owned"),
        importedImagePlan("excavator", asset: "MemoryVehicleExcavator", prompt: "tracked excavator with boom, stick, bucket, and rotating cab", notes: "show all three arm sections and full tracks", sourceName: "Codex project-owned vehicle learning artwork", license: "Project-owned"),
        importedImagePlan("bulldozer", asset: "MemoryVehicleBulldozer", prompt: "crawler bulldozer pushing soil with a broad front blade", notes: "wide blade and tracks should dominate the silhouette", sourceName: "Codex project-owned vehicle learning artwork", license: "Project-owned"),
        importedImagePlan("fire-engine", asset: "MemoryVehicleFireEngine", prompt: "fire engine with visible pump panel, coiled hose, and ladder", notes: "avoid department marks; distinguish equipment from a plain red truck", sourceName: "Codex project-owned vehicle learning artwork", license: "Project-owned"),
        importedImagePlan("ambulance", asset: "MemoryVehicleAmbulance", prompt: "ambulance with rear medical cabin and simple emergency light bar", notes: "no real service logos; keep medical cabin recognizable", sourceName: "Codex project-owned vehicle learning artwork", license: "Project-owned"),
        importedImagePlan("police-car", asset: "MemoryVehiclePoliceCar", prompt: "friendly unbranded police patrol car with light bar and radio antenna", notes: "no real agency marks, badges, or readable text", sourceName: "Codex project-owned vehicle learning artwork", license: "Project-owned"),
        importedImagePlan("rescue-helicopter", asset: "MemoryVehicleRescueHelicopter", prompt: "rescue helicopter hovering with a visible side winch", notes: "show the full rotor and winch; no real agency logo", sourceName: "Codex project-owned vehicle learning artwork", license: "Project-owned")
    ]

    static let planetImageAssetPlan: [MemoryImageAssetPlan] = [
        importedImagePlan("planet-mercury", asset: "MemoryPlanetMercury", prompt: "NASA MESSENGER global Mercury mosaic", notes: "orthographic projection from spacecraft images; craters remain visible at card size", sourceName: "NASA Science mission imagery", license: "NASA media usage guidelines"),
        importedImagePlan("planet-venus", asset: "MemoryPlanetVenus", prompt: "NASA Mariner 10 view of Venus's cloud-covered disk", notes: "show the real cloud deck, not the radar-mapped surface often used in illustrations", sourceName: "NASA Science mission imagery", license: "NASA media usage guidelines"),
        importedImagePlan("planet-earth", asset: "MemoryPlanetEarth", prompt: "NASA VIIRS Blue Marble Earth composite", notes: "full globe with recognizable land, ocean, and clouds", sourceName: "NASA Science mission imagery", license: "NASA media usage guidelines"),
        importedImagePlan("planet-mars", asset: "MemoryPlanetMars", prompt: "NASA Viking global color mosaic of Mars", notes: "near-natural color orthographic projection with polar cap and Valles Marineris visible", sourceName: "NASA Science mission imagery", license: "NASA media usage guidelines"),
        importedImagePlan("planet-jupiter", asset: "MemoryPlanetJupiter", prompt: "NASA Cassini true-color Jupiter globe", notes: "spacecraft mosaic projected onto a globe; Great Red Spot remains visible", sourceName: "NASA Science mission imagery", license: "NASA media usage guidelines"),
        importedImagePlan("planet-saturn", asset: "MemoryPlanetSaturn", prompt: "NASA Cassini natural-color Saturn panorama", notes: "full ring system must remain inside the square card", sourceName: "NASA Science mission imagery", license: "NASA media usage guidelines"),
        importedImagePlan("planet-uranus", asset: "MemoryPlanetUranus", prompt: "NASA Voyager 2 full-disk view of Uranus", notes: "use the pale blue-green observed disk without invented surface detail", sourceName: "NASA Science mission imagery", license: "NASA media usage guidelines"),
        importedImagePlan("planet-neptune", asset: "MemoryPlanetNeptune", prompt: "NASA Voyager 2 full-disk view of Neptune", notes: "retain the mission image's visible clouds and Great Dark Spot", sourceName: "NASA Science mission imagery", license: "NASA media usage guidelines")
    ]

    static let fishImageAssetPlan: [MemoryImageAssetPlan] = [
        importedImagePlan("fish-clownfish", asset: "MemoryFishClownfishStorybook", prompt: "clownfish with orange body and white bands near coral or sea anemone", notes: "white bands and orange body must be readable; crop out busy reef clutter", sourceName: "Built-in ImageGen storybook artwork", license: "Project-owned"),
        importedImagePlan("fish-goldfish", asset: "MemoryFishGoldfishStorybook", prompt: "goldfish side view with rounded body and flowing tail on a clean water background", notes: "orange or gold body should distinguish it from clownfish; avoid bowl-only compositions", sourceName: "Built-in ImageGen storybook artwork", license: "Project-owned"),
        importedImagePlan("fish-betta", asset: "MemoryFishBettaStorybook", prompt: "betta fish with large flowing fins, side view, clean aquatic background", notes: "flowing fins are the recognition cue; keep fin edges visible in square crop", sourceName: "Built-in ImageGen storybook artwork", license: "Project-owned"),
        importedImagePlan("fish-angelfish", asset: "MemoryFishAngelfishStorybook", prompt: "freshwater angelfish with tall triangular fins and black bands, side view", notes: "tall dorsal and anal fins must stay inside crop; avoid confusing with generic reef fish", sourceName: "Built-in ImageGen storybook artwork", license: "Project-owned"),
        importedImagePlan("fish-catfish", asset: "MemoryFishCatfishStorybook", prompt: "catfish with visible whisker-like barbels, side or three-quarter view", notes: "barbels must be clear at card size; prefer uncluttered river or aquarium background", sourceName: "Built-in ImageGen storybook artwork", license: "Project-owned"),
        importedImagePlan("fish-swordtail", asset: "MemoryFishSwordtailStorybook", prompt: "swordtail fish side view with long sword-shaped lower tail extension", notes: "tail sword is required for recognition; avoid crops that trim the tail", sourceName: "Built-in ImageGen storybook artwork", license: "Project-owned"),
        importedImagePlan("fish-tuna", asset: "MemoryFishTunaStorybook", prompt: "tuna fish with streamlined silver and blue body, side view in open water", notes: "sleek torpedo shape should read clearly; avoid fishing/deck scenes", sourceName: "Built-in ImageGen storybook artwork", license: "Project-owned"),
        importedImagePlan("fish-seahorse", asset: "MemoryFishSeahorseStorybook", prompt: "seahorse upright profile with curled tail, clean sea grass or water background", notes: "upright posture and curled tail must be visible; keep subject large in square crop", sourceName: "Built-in ImageGen storybook artwork", license: "Project-owned")
    ]

    static let planets: [MemoryAnimal] = [
        planet("planet-mercury", prompt: "☿", asset: "MemoryPlanetMercury", name: "Mercury", order: "1st from the Sun", type: "rocky planet", size: "4,879 km wide", colors: "gray", funFact: "A year lasts 88 days"),
        planet("planet-venus", prompt: "♀", asset: "MemoryPlanetVenus", name: "Venus", order: "2nd from the Sun", type: "rocky planet", size: "12,104 km wide", colors: "creamy white and pale tan", funFact: "It spins very slowly"),
        planet("planet-earth", prompt: "⊕", asset: "MemoryPlanetEarth", name: "Earth", order: "3rd from the Sun", type: "rocky planet", size: "12,742 km wide", colors: "blue, green, white", funFact: "It has one moon"),
        planet("planet-mars", prompt: "♂", asset: "MemoryPlanetMars", name: "Mars", order: "4th from the Sun", type: "rocky planet", size: "6,779 km wide", colors: "rusty red", funFact: "It has two small moons"),
        planet("planet-jupiter", prompt: "♃", asset: "MemoryPlanetJupiter", name: "Jupiter", order: "5th from the Sun", type: "gas giant", size: "139,820 km wide", colors: "brown, cream, orange", funFact: "It is the biggest planet"),
        planet("planet-saturn", prompt: "♄", asset: "MemoryPlanetSaturn", name: "Saturn", order: "6th from the Sun", type: "gas giant", size: "116,460 km wide", colors: "gold and tan", funFact: "It is famous for bright rings"),
        planet("planet-uranus", prompt: "⛢", asset: "MemoryPlanetUranus", name: "Uranus", order: "7th from the Sun", type: "ice giant", size: "50,724 km wide", colors: "icy blue", funFact: "It rotates on its side"),
        planet("planet-neptune", prompt: "♆", asset: "MemoryPlanetNeptune", name: "Neptune", order: "8th from the Sun", type: "ice giant", size: "49,244 km wide", colors: "deep blue", funFact: "It has very fast winds")
    ]

    static let fishes: [MemoryAnimal] = [
        fish("fish-clownfish", prompt: "Orange reef fish", asset: "MemoryFishClownfishStorybook", name: "Clownfish", home: "warm coral reefs", size: "10 to 18 cm long", colors: "orange, white, black", funFact: "It hides safely inside sea anemones"),
        fish("fish-goldfish", prompt: "Golden pond fish", asset: "MemoryFishGoldfishStorybook", name: "Goldfish", home: "ponds and aquariums", size: "15 to 30 cm long", colors: "gold, orange, white", funFact: "It can remember simple routes and feeding times"),
        fish("fish-betta", prompt: "Flowing fin fish", asset: "MemoryFishBettaStorybook", name: "Betta", home: "slow streams and rice fields", size: "6 to 8 cm long", colors: "red, blue, purple", funFact: "It can breathe some air from the surface"),
        fish("fish-angelfish", prompt: "Tall fin freshwater fish", asset: "MemoryFishAngelfishStorybook", name: "Angelfish", home: "freshwater rivers in South America", size: "up to about 18 cm long", colors: "silver, yellow, black", funFact: "Its long fins make a tall, triangular shape"),
        fish("fish-catfish", prompt: "Whiskered river fish", asset: "MemoryFishCatfishStorybook", name: "Catfish", home: "rivers, lakes, and ponds", size: "20 to 60 cm long", colors: "gray, brown, black", funFact: "Its whiskers help it sense food in cloudy water"),
        fish("fish-swordtail", prompt: "Tail-sword fish", asset: "MemoryFishSwordtailStorybook", name: "Swordtail", home: "freshwater streams", size: "8 to 12 cm long", colors: "orange, green, black", funFact: "The male has a long sword-shaped tail"),
        fish("fish-tuna", prompt: "Fast ocean fish", asset: "MemoryFishTunaStorybook", name: "Tuna", home: "open ocean waters", size: "1 to 2 m long", colors: "silver and blue", funFact: "It can swim very fast for long distances"),
        fish("fish-seahorse", prompt: "Tiny upright sea swimmer", asset: "MemoryFishSeahorseStorybook", name: "Seahorse", home: "sea grass beds and reefs", size: "2 to 15 cm long", colors: "yellow, brown, orange", funFact: "It swims upright and curls its tail")
    ]

    static let countries: [MemoryAnimal] = [
        countryCapital("country-india", country: "India", capital: "New Delhi", continent: "Asia", language: "Hindi and English for Union government", currency: "Indian rupee (INR)", currencySymbol: "₹", mapShape: "wide triangle-like peninsula", monument: "Taj Mahal", assetSuffix: "India"),
        countryCapital("country-japan", country: "Japan", capital: "Tokyo", continent: "Asia", language: "Japanese", currency: "Japanese yen (JPY)", currencySymbol: "¥", mapShape: "long island chain", monument: "Himeji Castle", assetSuffix: "Japan"),
        countryCapital("country-france", country: "France", capital: "Paris", continent: "Europe", language: "French", currency: "Euro (EUR)", currencySymbol: "€", mapShape: "hexagon-like outline", monument: "Eiffel Tower", assetSuffix: "France"),
        countryCapital("country-egypt", country: "Egypt", capital: "Cairo", continent: "Africa", language: "Arabic", currency: "Egyptian pound (EGP)", currencySymbol: "E£", mapShape: "square-like shape with Sinai corner", monument: "Great Pyramid of Giza", assetSuffix: "Egypt"),
        countryCapital("country-brazil", country: "Brazil", capital: "Brasília", continent: "South America", language: "Portuguese", currency: "Brazilian real (BRL)", currencySymbol: "R$", mapShape: "large east-bulging outline", monument: "Christ the Redeemer", assetSuffix: "Brazil"),
        countryCapital("country-australia", country: "Australia", capital: "Canberra", continent: "Australia", language: "English (national language)", currency: "Australian dollar (AUD)", currencySymbol: "A$", mapShape: "big island continent", monument: "Sydney Opera House", assetSuffix: "Australia"),
        countryCapital("country-canada", country: "Canada", capital: "Ottawa", continent: "North America", language: "English and French", currency: "Canadian dollar (CAD)", currencySymbol: "C$", mapShape: "very wide northern outline", monument: "CN Tower", assetSuffix: "Canada"),
        countryCapital("country-kenya", country: "Kenya", capital: "Nairobi", continent: "Africa", language: "Kiswahili and English", currency: "Kenyan shilling (KES)", currencySymbol: "KSh", mapShape: "east Africa shape by the Indian Ocean", monument: "Kenyatta International Convention Centre", assetSuffix: "Kenya"),
        countryCapital("country-united-states", country: "United States", capital: "Washington, D.C.", continent: "North America", language: "English", currency: "United States dollar (USD)", currencySymbol: "$", mapShape: "wide country between the Atlantic and Pacific Oceans", monument: "Statue of Liberty", assetSuffix: "UnitedStates"),
        countryCapital("country-united-kingdom", country: "United Kingdom", capital: "London", continent: "Europe", language: "English; Welsh in Wales", currency: "Pound sterling (GBP)", currencySymbol: "£", mapShape: "island group in northwest Europe", monument: "Elizabeth Tower (Big Ben)", assetSuffix: "UnitedKingdom"),
        countryCapital("country-china", country: "China", capital: "Beijing", continent: "Asia", language: "Standard Chinese (Putonghua)", currency: "Chinese yuan (CNY)", currencySymbol: "¥", mapShape: "large east Asia outline", monument: "Great Wall of China", assetSuffix: "China"),
        countryCapital("country-germany", country: "Germany", capital: "Berlin", continent: "Europe", language: "German", currency: "Euro (EUR)", currencySymbol: "€", mapShape: "central Europe outline", monument: "Brandenburg Gate", assetSuffix: "Germany"),
        countryCapital("country-mexico", country: "Mexico", capital: "Mexico City", continent: "North America", language: "Spanish and 68 Indigenous national languages", currency: "Mexican peso (MXN)", currencySymbol: "Mex$", mapShape: "long country south of the United States", monument: "Chichén Itzá", assetSuffix: "Mexico"),
        countryCapital("country-south-africa", country: "South Africa", capital: "Pretoria", capitalDetail: "Pretoria (administrative)", continent: "Africa", language: "12 official languages, including isiZulu and isiXhosa", currency: "South African rand (ZAR)", currencySymbol: "R", mapShape: "southern tip of Africa", monument: "Union Buildings", assetSuffix: "SouthAfrica"),
        countryCapital("country-italy", country: "Italy", capital: "Rome", continent: "Europe", language: "Italian", currency: "Euro (EUR)", currencySymbol: "€", mapShape: "boot-shaped peninsula", monument: "Colosseum", assetSuffix: "Italy"),
        countryCapital("country-saudi-arabia", country: "Saudi Arabia", capital: "Riyadh", continent: "Asia", language: "Arabic", currency: "Saudi riyal (SAR)", currencySymbol: "SAR", mapShape: "large Arabian Peninsula outline", monument: "Masmak Fort", assetSuffix: "SaudiArabia")
    ]

    static let countryFlags: [MemoryAnimal] = [
        flagCountry("country-flag-india", country: "India", picture: .asset("MemoryFlagIndia"), isoAlpha2: "IN", continent: "Asia", capital: "New Delhi", language: "Hindi and English for Union government", currency: "Indian rupee (INR)", currencySymbol: "₹", colors: "saffron, white, green, navy blue", monument: "Taj Mahal", assetSuffix: "India"),
        flagCountry("country-flag-japan", country: "Japan", picture: .asset("MemoryFlagJapan"), isoAlpha2: "JP", continent: "Asia", capital: "Tokyo", language: "Japanese", currency: "Japanese yen (JPY)", currencySymbol: "¥", colors: "white and red", monument: "Himeji Castle", assetSuffix: "Japan"),
        flagCountry("country-flag-france", country: "France", picture: .asset("MemoryFlagFrance"), isoAlpha2: "FR", continent: "Europe", capital: "Paris", language: "French", currency: "Euro (EUR)", currencySymbol: "€", colors: "blue, white, red", monument: "Eiffel Tower", assetSuffix: "France"),
        flagCountry("country-flag-egypt", country: "Egypt", picture: .asset("MemoryFlagEgypt"), isoAlpha2: "EG", continent: "Africa", capital: "Cairo", language: "Arabic", currency: "Egyptian pound (EGP)", currencySymbol: "E£", colors: "red, white, black, gold", monument: "Great Pyramid of Giza", assetSuffix: "Egypt"),
        flagCountry("country-flag-brazil", country: "Brazil", picture: .asset("MemoryFlagBrazil"), isoAlpha2: "BR", continent: "South America", capital: "Brasília", language: "Portuguese", currency: "Brazilian real (BRL)", currencySymbol: "R$", colors: "green, yellow, blue, white", monument: "Christ the Redeemer", assetSuffix: "Brazil"),
        flagCountry("country-flag-australia", country: "Australia", picture: .asset("MemoryFlagAustralia"), isoAlpha2: "AU", continent: "Australia", capital: "Canberra", language: "English (national language)", currency: "Australian dollar (AUD)", currencySymbol: "A$", colors: "blue, red, white", monument: "Sydney Opera House", assetSuffix: "Australia"),
        flagCountry("country-flag-canada", country: "Canada", picture: .asset("MemoryFlagCanada"), isoAlpha2: "CA", continent: "North America", capital: "Ottawa", language: "English and French", currency: "Canadian dollar (CAD)", currencySymbol: "C$", colors: "red and white", monument: "CN Tower", assetSuffix: "Canada"),
        flagCountry("country-flag-kenya", country: "Kenya", picture: .asset("MemoryFlagKenya"), isoAlpha2: "KE", continent: "Africa", capital: "Nairobi", language: "Kiswahili and English", currency: "Kenyan shilling (KES)", currencySymbol: "KSh", colors: "black, red, green, white", monument: "Kenyatta International Convention Centre", assetSuffix: "Kenya"),
        flagCountry("country-flag-united-states", country: "United States", picture: .emoji("🇺🇸"), isoAlpha2: "US", continent: "North America", capital: "Washington, D.C.", language: "English", currency: "United States dollar (USD)", currencySymbol: "$", colors: "red, white, blue", monument: "Statue of Liberty", assetSuffix: "UnitedStates"),
        flagCountry("country-flag-united-kingdom", country: "United Kingdom", picture: .emoji("🇬🇧"), isoAlpha2: "GB", continent: "Europe", capital: "London", language: "English; Welsh in Wales", currency: "Pound sterling (GBP)", currencySymbol: "£", colors: "red, white, blue", monument: "Elizabeth Tower (Big Ben)", assetSuffix: "UnitedKingdom"),
        flagCountry("country-flag-china", country: "China", picture: .emoji("🇨🇳"), isoAlpha2: "CN", continent: "Asia", capital: "Beijing", language: "Standard Chinese (Putonghua)", currency: "Chinese yuan (CNY)", currencySymbol: "¥", colors: "red and yellow", monument: "Great Wall of China", assetSuffix: "China"),
        flagCountry("country-flag-germany", country: "Germany", picture: .emoji("🇩🇪"), isoAlpha2: "DE", continent: "Europe", capital: "Berlin", language: "German", currency: "Euro (EUR)", currencySymbol: "€", colors: "black, red, gold", monument: "Brandenburg Gate", assetSuffix: "Germany"),
        flagCountry("country-flag-mexico", country: "Mexico", picture: .emoji("🇲🇽"), isoAlpha2: "MX", continent: "North America", capital: "Mexico City", language: "Spanish and 68 Indigenous national languages", currency: "Mexican peso (MXN)", currencySymbol: "Mex$", colors: "green, white, red", monument: "Chichén Itzá", assetSuffix: "Mexico"),
        flagCountry("country-flag-south-africa", country: "South Africa", picture: .emoji("🇿🇦"), isoAlpha2: "ZA", continent: "Africa", capital: "Pretoria (administrative)", language: "12 official languages, including isiZulu and isiXhosa", currency: "South African rand (ZAR)", currencySymbol: "R", colors: "red, blue, green, black, white, yellow", monument: "Union Buildings", assetSuffix: "SouthAfrica"),
        flagCountry("country-flag-italy", country: "Italy", picture: .emoji("🇮🇹"), isoAlpha2: "IT", continent: "Europe", capital: "Rome", language: "Italian", currency: "Euro (EUR)", currencySymbol: "€", colors: "green, white, red", monument: "Colosseum", assetSuffix: "Italy"),
        flagCountry("country-flag-saudi-arabia", country: "Saudi Arabia", picture: .emoji("🇸🇦"), isoAlpha2: "SA", continent: "Asia", capital: "Riyadh", language: "Arabic", currency: "Saudi riyal (SAR)", currencySymbol: "SAR", colors: "green and white", monument: "Masmak Fort", assetSuffix: "SaudiArabia")
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
        numberBondTo10("bond-1-9", prompt: "1 + ? = 10", match: "9", clue: "One and nine fill the ten-frame."),
        numberBondTo10("bond-2-8", prompt: "2 + ? = 10", match: "8", clue: "Two and eight make a full ten."),
        numberBondTo10("bond-3-7", prompt: "3 + ? = 10", match: "7", clue: "Three and seven are friendly ten partners."),
        numberBondTo10("bond-4-6", prompt: "4 + ? = 10", match: "6", clue: "Four and six snap together to ten."),
        numberBondTo10("bond-5-5", prompt: "5 + ? = 10", match: "5", clue: "Five and five are doubles that make ten."),
        numberBondTo10("bond-6-4", prompt: "6 + ? = 10", match: "4", clue: "Six needs four more to make ten."),
        numberBondTo10("bond-7-3", prompt: "7 + ? = 10", match: "3", clue: "Seven needs three more to make ten."),
        numberBondTo10("bond-8-2", prompt: "8 + ? = 10", match: "2", clue: "Eight and two complete the ten-frame."),
        numberBondTo10("bond-9-1", prompt: "9 + ? = 10", match: "1", clue: "Nine needs one more to make ten."),
        numberBondTo10("bond-10-0", prompt: "10 + ? = 10", match: "0", clue: "Ten and zero stay ten."),
    ]

    static let fruits: [MemoryAnimal] = [
        fruit("fruit-apple", name: "Apple", asset: "CompareCampApple", shape: "round", colors: "red, green, or yellow", taste: "sweet and crisp", smell: "fresh and fruity", foundIn: "India, China, the United States, and Europe"),
        fruit("fruit-banana", name: "Banana", asset: "MemoryFruitBanana", shape: "long and curved", colors: "yellow", taste: "sweet and soft", smell: "gentle tropical smell", foundIn: "India, Ecuador, the Philippines, and Brazil"),
        fruit("fruit-mango", name: "Mango", asset: "MemoryFruitMango", shape: "oval", colors: "yellow, orange, green, or red", taste: "very sweet and juicy", smell: "rich tropical smell", foundIn: "India, Mexico, Thailand, and Pakistan"),
        fruit("fruit-orange", name: "Orange", asset: "MemoryFruitOrange", shape: "round", colors: "orange", taste: "sweet and tangy", smell: "bright citrus smell", foundIn: "Brazil, India, China, and Spain"),
        fruit("fruit-grape", name: "Grape", asset: "MemoryFruitGrape", shape: "small round bunches", colors: "green, red, or purple", taste: "sweet and juicy", smell: "light fruity smell", foundIn: "Italy, China, the United States, and India"),
        fruit("fruit-watermelon", name: "Watermelon", asset: "MemoryFruitWatermelon", shape: "large oval", colors: "green outside and red inside", taste: "sweet and watery", smell: "fresh melon smell", foundIn: "India, China, Turkey, and Brazil"),
        fruit("fruit-pineapple", name: "Pineapple", asset: "MemoryFruitPineapple", shape: "oval with spiky crown", colors: "gold and green", taste: "sweet and tangy", smell: "strong tropical smell", foundIn: "Costa Rica, India, the Philippines, and Thailand"),
        fruit("fruit-strawberry", name: "Strawberry", asset: "MemoryFruitStrawberry", shape: "heart-shaped", colors: "red with tiny seeds", taste: "sweet and a little tart", smell: "sweet berry smell", foundIn: "United States, Mexico, Spain, and India")
    ]

    static let waterCycle: [MemoryAnimal] = [
        waterCycleConcept("water-cycle-evaporation", name: "Evaporation", asset: "MemoryWaterCycleEvaporation", action: "warm water goes up", whereSeen: "above warm ponds, lakes, and puddles", everydayWords: "Warmth helps liquid water change into invisible water vapor", cycleStep: "Water rises into the air"),
        waterCycleConcept("water-cycle-condensation", name: "Condensation", asset: "MemoryWaterCycleCondensation", action: "tiny drops make a cloud", whereSeen: "inside cool clouds", everydayWords: "Vapor cools and gathers as tiny drops", cycleStep: "Drops gather together"),
        waterCycleConcept("water-cycle-precipitation", name: "Precipitation", asset: "MemoryWaterCyclePrecipitation", action: "rain falls down", whereSeen: "under heavy clouds", everydayWords: "Cloud drops get heavy and fall", cycleStep: "Rain returns to the ground"),
        waterCycleConcept("water-cycle-collection", name: "Collection", asset: "MemoryWaterCycleCollection", action: "water gathers again", whereSeen: "in ponds, lakes, rivers, and puddles", everydayWords: "Fallen water gathers in low places", cycleStep: "Water waits for the sun again"),
        waterCycleConcept("water-cycle-sun-heat", name: "Sun Heat", asset: "MemoryWaterCycleSunHeat", action: "the sun warms water", whereSeen: "where sunlight touches water", everydayWords: "Warm sunlight starts the cycle", cycleStep: "Heat helps water rise"),
        waterCycleConcept("water-cycle-vapor", name: "Vapor", asset: "MemoryWaterCycleVapor", action: "water is in the air", whereSeen: "above warm water", everydayWords: "Water vapor is an invisible gas", cycleStep: "Vapor moves upward"),
        waterCycleConcept("water-cycle-cloud", name: "Cloud", asset: "MemoryWaterCycleCloud", action: "drops gather together", whereSeen: "up in the sky", everydayWords: "A cloud holds many tiny drops", cycleStep: "Clouds can grow heavy"),
        waterCycleConcept("water-cycle-pond", name: "Pond", asset: "MemoryWaterCyclePond", action: "water waits here", whereSeen: "on the ground after rain", everydayWords: "A pond can collect rain water", cycleStep: "Collected water can rise again")
    ]

    static let waterCycleImageAssetPlan: [MemoryImageAssetPlan] = [
        importedImagePlan("water-cycle-evaporation", asset: "MemoryWaterCycleEvaporation", prompt: "warm sun over pond with upward arrows for invisible vapor", notes: "arrows represent invisible water vapor, not rising liquid drops", sourceName: "Codex CLI image generation water cycle prompt family", license: "Project-owned"),
        importedImagePlan("water-cycle-condensation", asset: "MemoryWaterCycleCondensation", prompt: "vapor dots gathering into a cloud", notes: "cloud and gathered drops should be visually central", sourceName: "Codex CLI image generation water cycle prompt family", license: "Project-owned"),
        importedImagePlan("water-cycle-precipitation", asset: "MemoryWaterCyclePrecipitation", prompt: "rain falling from a cloud into a pond", notes: "falling rain should be distinct from vapor", sourceName: "Codex CLI image generation water cycle prompt family", license: "Project-owned"),
        importedImagePlan("water-cycle-collection", asset: "MemoryWaterCycleCollection", prompt: "rain water collecting in pond or lake", notes: "pond should read as the destination for rain", sourceName: "Codex CLI image generation water cycle prompt family", license: "Project-owned"),
        importedImagePlan("water-cycle-sun-heat", asset: "MemoryWaterCycleSunHeat", prompt: "sun warming water", notes: "sun rays should clearly touch water", sourceName: "Codex CLI image generation water cycle prompt family", license: "Project-owned"),
        importedImagePlan("water-cycle-vapor", asset: "MemoryWaterCycleVapor", prompt: "upward arrows above a pond represent invisible water vapor", notes: "vapor is invisible; arrows are a picture model, not visible gas", sourceName: "Codex CLI image generation water cycle prompt family", license: "Project-owned"),
        importedImagePlan("water-cycle-cloud", asset: "MemoryWaterCycleCloud", prompt: "cloud with tiny gathered drops", notes: "cloud should be clear without needing text", sourceName: "Codex CLI image generation water cycle prompt family", license: "Project-owned"),
        importedImagePlan("water-cycle-pond", asset: "MemoryWaterCyclePond", prompt: "pond holding collected water after rain", notes: "pond should be large and high contrast", sourceName: "Codex CLI image generation water cycle prompt family", license: "Project-owned")
    ]

    static let allAnimalsById: [String: MemoryAnimal] = {
        Dictionary(uniqueKeysWithValues: allDeckAnimals.map { ($0.id, $0) })
    }()

    static let imageAssetProvenance: [MemoryImageAssetProvenance] = [
        nasaPlanetImageProvenance(assetName: "MemoryPlanetMercury", cardId: "planet-mercury", sourceID: "PIA15160", sourceTitle: "Mercury Globe: 0°N, 0°E", sourceUrl: "https://science.nasa.gov/photojournal/mercury-globe-0n-0e/", creator: "NASA/Johns Hopkins University Applied Physics Laboratory/Carnegie Institution of Washington", originalFileName: "PIA15160.jpg", originalSha256: "f223680df8f972b9cf373d79c4b2d602e650e84c64f4d44e886d2638935f42ee", derivativeSha256: "808fde1384ddb7ee38aac5f544b068b3a08b6986d57d3fad59c84c980e4c8f67", processingNote: "MESSENGER images assembled as an orthographic global mosaic by the source team."),
        nasaPlanetImageProvenance(assetName: "MemoryPlanetVenus", cardId: "planet-venus", sourceID: "PIA23791", sourceTitle: "Venus from Mariner 10", sourceUrl: "https://science.nasa.gov/photojournal/venus-from-mariner-10/", creator: "NASA/JPL-Caltech; source processing by Kevin M. Gill", originalFileName: "PIA23791_fig2.jpg", originalSha256: "9deaf7392cd41dcd77f2e6fc61a12641af3a2dc1a52ecfd652388a65bd225dbc", derivativeSha256: "af60c16a58a1187955dc7df4bad594668add4a8819c5963e39fb98323f832e50", processingNote: "False-color composite of Mariner 10 orange- and ultraviolet-filter observations, processed by the source team to show the cloud deck."),
        nasaPlanetImageProvenance(assetName: "MemoryPlanetEarth", cardId: "planet-earth", sourceID: "PIA18033", sourceTitle: "Earth", sourceUrl: "https://science.nasa.gov/photojournal/earth/", creator: "NASA", originalFileName: "PIA18033.jpg", originalSha256: "54b1a898b080cd85418269075e50c44026fefda9d5163cbf808a61efdb1dc699", derivativeSha256: "66116c2b894b2298973f9714b961036aafd94a0e7bf85c04f04ed837f05cc0b1", processingNote: "Blue Marble montage made by the source team from Suomi NPP VIIRS observations."),
        nasaPlanetImageProvenance(assetName: "MemoryPlanetMars", cardId: "planet-mars", sourceID: "PIA00407", sourceTitle: "Global Color Views of Mars", sourceUrl: "https://science.nasa.gov/photojournal/global-color-views-of-mars/", creator: "NASA/JPL/USGS", originalFileName: "PIA00407.jpg", originalSha256: "9c047fa4e7b5c54cec28cd50993e88d15926f881060110bf79fd8aba75bb30e7", derivativeSha256: "4beea0b1044f7b7cefbf4d08b25c846d2d0c18e1b16b1842e0243a45a2fe0e55", processingNote: "Near-natural-color orthographic mosaic assembled by the source team from Viking Orbiter observations."),
        nasaPlanetImageProvenance(assetName: "MemoryPlanetJupiter", cardId: "planet-jupiter", sourceID: "PIA02873", sourceTitle: "High Resolution Globe of Jupiter", sourceUrl: "https://science.nasa.gov/photojournal/pj-high-resolution-globe-of-jupiter/", creator: "NASA/JPL/University of Arizona", originalFileName: "PIA02873.jpg", originalSha256: "6cb0665dd83b64eeccafc7586913d467f725189bfd25f27deed1a3ffd920ac29", derivativeSha256: "416111a08228577c49bee0635aea896f21e64de6e94c6d2a73aa676b058abc9e", processingNote: "True-color simulated globe projected by the source team from four Cassini spacecraft images."),
        nasaPlanetImageProvenance(assetName: "MemoryPlanetSaturn", cardId: "planet-saturn", sourceID: "PIA11141", sourceTitle: "Saturn … Four Years On", sourceUrl: "https://science.nasa.gov/photojournal/saturn-four-years-on", creator: "NASA/JPL/Space Science Institute", originalFileName: "PIA11141.jpg", originalSha256: "ad45e75b0d86b3bc664a438b3429eeae4f56fed079d14fbb5a2ad0bca0bd29e7", derivativeSha256: "43f63737ec0198609a2fba339d1dc4798046bbbb90bb02cca8c32cf53427bbb5", processingNote: "Natural-color panorama assembled by the source team from 30 Cassini images."),
        nasaPlanetImageProvenance(assetName: "MemoryPlanetUranus", cardId: "planet-uranus", sourceID: "PIA18182", sourceTitle: "Uranus as seen by NASA's Voyager 2", sourceUrl: "https://science.nasa.gov/resource/uranus-as-seen-by-nasas-voyager-2/", creator: "NASA/JPL", originalFileName: "PIA18182.jpg", originalSha256: "4e2200e4f2167be5e02f1f1c9f1fef6278e93b42431b51f0b914e7ee7b8f961a", derivativeSha256: "6ef015fba22d014bafc7bf07e59ee3e67aeab91d86f0b04c9c32d3e8a62fbca3", processingNote: "Full-disk Voyager 2 spacecraft observation."),
        nasaPlanetImageProvenance(assetName: "MemoryPlanetNeptune", cardId: "planet-neptune", sourceID: "PIA01492", sourceTitle: "Neptune Full Disk View", sourceUrl: "https://science.nasa.gov/resource/neptune-full-disk-view/", creator: "NASA/JPL", originalFileName: "PIA01492.jpg", originalSha256: "651145ae8387c51e9f55f99d900b6a8a011d52b979075e2010d81e4b55e687db", derivativeSha256: "e4c4f48c171cb66d2507b174202a31f927f83a364495366f433fb6f1705e650a", processingNote: "Full-disk view produced by the source team from Voyager 2 green- and orange-filter observations."),
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
        generatedVehicleGalleryProvenance(assetName: "MemoryVehiclePartEngine", cardId: "vehicle-part-engine", originalSha256: "aea3a6b95aa59e24613d0bafeceee427d4eb42885c75c72671e451c35753a255", derivativeSha256: "446e501529749e22f569ccbddb630be1008f8214ceffe781f02b85f87e35eb8c"),
        generatedVehicleGalleryProvenance(assetName: "MemoryVehiclePartTransmission", cardId: "vehicle-part-transmission", originalSha256: "4410d2cf3c872367cc96fec009954410770cc12bc98455c4f0fd8a308ba3e5c2", derivativeSha256: "1ce3e87b484c8d554835b08f6fe22043b08706de7f578f3193fef4f2d9166d41"),
        generatedVehicleGalleryProvenance(assetName: "MemoryVehiclePartBrakes", cardId: "vehicle-part-brakes", originalSha256: "f9371fe70acce19728f300d7965d92528d97af51f9f0ec277be175cc13689ed2", derivativeSha256: "74d012b8ee7ecab1215445bf121c95014c2c9cf05e64d2707bfaf9062ab9b808"),
        generatedVehicleGalleryProvenance(assetName: "MemoryVehiclePartWheelAxle", cardId: "vehicle-part-wheel-axle", originalSha256: "00328af234f2a78cac6ab1118029502c8e9f32cd1e24a0ea666fa67f91cad9ca", derivativeSha256: "06239769382e31958ad0db423cb72288773f0eb65c4d860478a2619501f6b7eb"),
        generatedVehicleGalleryProvenance(assetName: "MemoryVehiclePartSteering", cardId: "vehicle-part-steering", originalSha256: "b129a4e41b7a4219ca9635c3a30d9077b211c2a388f06fbe2dd06b1447b627af", derivativeSha256: "4f46c4657dd37d75bf0374a2273a7c31d27c4406be42920dc67b20986e784aff"),
        generatedVehicleGalleryProvenance(assetName: "MemoryVehiclePartSuspension", cardId: "vehicle-part-suspension", originalSha256: "97c714823000102b47ac7bcfad214787eb16cf6f8d0220f553ba712a4c09689a", derivativeSha256: "26f48b6c188946b49989c92942f2045e811b3e190d00c78bf3ed3ad40fc451cb"),
        generatedVehicleGalleryProvenance(assetName: "MemoryVehicleMobileCrane", cardId: "mobile-crane", originalSha256: "62eeb5f4d86c5c560bc48a80a152e0a57ffcb57d99e142198cc113263eefcfa9", derivativeSha256: "33d851bb675d2d167bae9143b41b95c774bc568a8960b712fee3dc366f57e3f9"),
        generatedVehicleGalleryProvenance(assetName: "MemoryVehicleCrawlerCrane", cardId: "crawler-crane", originalSha256: "81064adcc68bc8e11780ceaa777e4040c693a360e3a70f43b5407d856e781a52", derivativeSha256: "79bc879e37ccc08ac855cfdb00631eb81f9339dad90a254c45f85ed6398643be"),
        generatedVehicleGalleryProvenance(assetName: "MemoryVehicleWheelLoader", cardId: "wheel-loader", originalSha256: "3bcd9f62245ff65ca4a9db59ad8dafe6d967816c0483f3510f2d34f4cfd81c88", derivativeSha256: "b902cb50b6a1ced2477e866d3f1c9edd044949cae1c0c9368a3e711d86db0c49"),
        generatedVehicleGalleryProvenance(assetName: "MemoryVehicleSkidSteerLoader", cardId: "skid-steer-loader", originalSha256: "33eb127a647875257cf810d2960696108187b5586fbbcb357bc25163f053a75d", derivativeSha256: "72973215aadb7d832f1c619bf1a2e82e52adff1743e8b52aae7dc823a28f7298"),
        generatedVehicleGalleryProvenance(assetName: "MemoryVehicleBackhoeLoader", cardId: "backhoe-loader", originalSha256: "4116485eee3a3aa7335ea2d2d6014269809fcf61777e59a1bf712e04a8b57d9c", derivativeSha256: "39f001b529db95740f4465ff9331538e74db091438e7c0f15348f105af63166d"),
        generatedVehicleGalleryProvenance(assetName: "MemoryVehicleDumpTruck", cardId: "dump-truck", originalSha256: "7c678f353ca5fd881a9a9b9a55579c70480d7988aeb3184b7455d5858b25e918", derivativeSha256: "2cb53d0b4184f2b3a83a887575438b57b195c9a3a391ca32ce3b3479999c4f31"),
        generatedVehicleGalleryProvenance(assetName: "MemoryVehicleConcreteMixerTruck", cardId: "concrete-mixer-truck", originalSha256: "1766819aa137c61e7378fa9404cd6ad4cb329ad5f3d035eaa2cb0f9648da48c2", derivativeSha256: "ecb2c8b66ed4177491ac02c9911c32389f8d35d973b9426fbbe5db4386b88267"),
        generatedVehicleGalleryProvenance(assetName: "MemoryVehicleGarbageTruck", cardId: "garbage-truck", originalSha256: "e2998cf9cdeae8e0df5d96c897b5380f9b24d313b65e52fadd50415f567bf358", derivativeSha256: "0e72e170ca7ad4685a1a4714bff6e19a6c506f9e936ad033ad582de017da8d3b"),
        generatedVehicleGalleryProvenance(assetName: "MemoryVehicleTowTruck", cardId: "tow-truck", originalSha256: "2010a1ec742c45a1f6fbd4249b71d98c998d236b2a0a0bb78864e91daab4ebc4", derivativeSha256: "c91332da97f6d69e882585cb633b3678cb3acd77ecb1c91838cf17c6be3f15be"),
        generatedVehicleGalleryProvenance(assetName: "MemoryVehicleMiningHaulTruck", cardId: "mining-haul-truck", originalSha256: "31ba31e95878063756823a9fe40366fca8103f43a6f0193be435e0ead9de8b62", derivativeSha256: "b25592d1339eb1928d273b3a878b908b34c55869a3b8c6958f469d8e8acaf901"),
        generatedVehicleGalleryProvenance(assetName: "MemoryVehicleExcavator", cardId: "excavator", originalSha256: "26fe2dc8218d5fb12061ebc68ee3a8af9a197af852e0b2dbacfb223d25ad5482", derivativeSha256: "cb2b46f657542a23ea3563f7ba5a2d8165f2c4f2b3ff6d543e552fc8761b22e5"),
        generatedVehicleGalleryProvenance(assetName: "MemoryVehicleBulldozer", cardId: "bulldozer", originalSha256: "b5a7195437fb46f57d2ed4f6491d6a5558f747303f6117d2b81a2e2b4c2d43ca", derivativeSha256: "6e799650562d610aefb1542d69c30a1252af33a4b3db53759d5c95af1c1a2242"),
        generatedVehicleGalleryProvenance(assetName: "MemoryVehicleFireEngine", cardId: "fire-engine", originalSha256: "cdf900423899cd46586895870dee9d8e7e25340ba69fdedceea83f67b5aca630", derivativeSha256: "f05bb04e6fc832e401fb1a36b5ec003732edef5d04c40cbfbadc5341481b285d"),
        generatedVehicleGalleryProvenance(assetName: "MemoryVehicleAmbulance", cardId: "ambulance", originalSha256: "2a44a6e3e520e0e5247c2125616bc869804a74054039dc7ad31d1b9bbbd29dcf", derivativeSha256: "29d4cb0e23d53ddf12c28b0b267b9c3ff207bb0430698a28e17d07ea5fe98a1e"),
        generatedVehicleGalleryProvenance(assetName: "MemoryVehiclePoliceCar", cardId: "police-car", originalSha256: "efbfa5d6027ae379381de001448eafd3ee1e2e8ff1274cddf5cbf4c473e45636", derivativeSha256: "71b84bf0b62318ea6aea25c9601d2ffeee7b00d2c97268a201c9d16ae79cbc5b"),
        generatedVehicleGalleryProvenance(assetName: "MemoryVehicleRescueHelicopter", cardId: "rescue-helicopter", originalSha256: "c66ebfd5e24af069ff6e2690b8a8ab4d5c5f4930d9c9f74bb4d2ded5ffc0dd79", derivativeSha256: "1dfc6991e391b4ac4daaf73bc2b7db44c1f23b557c1a266d2313be2c34cd84ce"),
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
    ] + countryLearningAssetProvenance + memoryAdventureIllustrationProvenance

    // BEGIN GENERATED MEMORY ADVENTURE PROVENANCE
    // Generated from verified files; visual review status is explicitly recorded.
    private static let memoryAdventureIllustrationProvenance: [MemoryImageAssetProvenance] = [
        MemoryImageAssetProvenance(
            assetName: "CompareCampApple",
            cardId: "fruit-apple",
            sourceName: "Existing Compare Camp built-in ImageGen artwork",
            sourceUrl: "",
            creator: "OpenAI ImageGen for ganesh47/mather",
            creditLine: "Existing Compare Camp artwork reused for Mather Memory Adventures.",
            license: "Project-owned generated artwork; no third-party source material",
            licenseUrl: "",
            retrievedAt: "2026-10-02",
            originalFileName: "CompareCampApple.png",
            originalSha256: "a8beec68b01d36c930c87fa528d56785444042b2644542a0bde7660ed11a2d41",
            derivativeFileName: "CompareCampApple.png",
            derivativeSha256: "a8beec68b01d36c930c87fa528d56785444042b2644542a0bde7660ed11a2d41",
            derivativeChanges: "Reused existing Compare Camp generated PNG unchanged; original creation documented in wiki/Specs/Compare-Camp-Generated-Asset-Provenance.md.",
            licenseAllowsReuse: true,
            noThirdPartyRestrictionFound: true,
            noLogoOrEndorsementRisk: true,
            noPeopleOrPrivacyRisk: true,
            childCardLegibilityChecked: true
        ),
        MemoryImageAssetProvenance(
            assetName: "CompareCampFlamingo",
            cardId: "bird-a12",
            sourceName: "Existing Compare Camp built-in ImageGen artwork",
            sourceUrl: "",
            creator: "OpenAI ImageGen for ganesh47/mather",
            creditLine: "Existing Compare Camp artwork reused for Mather Memory Adventures.",
            license: "Project-owned generated artwork; no third-party source material",
            licenseUrl: "",
            retrievedAt: "2026-10-02",
            originalFileName: "CompareCampFlamingo.png",
            originalSha256: "436f2dec42f4764e3229dbcdcdf00a88a38afe90602493e81bf0c59f7f8f9705",
            derivativeFileName: "CompareCampFlamingo.png",
            derivativeSha256: "436f2dec42f4764e3229dbcdcdf00a88a38afe90602493e81bf0c59f7f8f9705",
            derivativeChanges: "Reused existing Compare Camp generated PNG unchanged; original creation documented in wiki/Specs/Compare-Camp-Generated-Asset-Provenance.md.",
            licenseAllowsReuse: true,
            noThirdPartyRestrictionFound: true,
            noLogoOrEndorsementRisk: true,
            noPeopleOrPrivacyRisk: true,
            childCardLegibilityChecked: true
        ),
        MemoryImageAssetProvenance(
            assetName: "CompareCampMacaw",
            cardId: "bird-a01",
            sourceName: "Existing Compare Camp built-in ImageGen artwork",
            sourceUrl: "",
            creator: "OpenAI ImageGen for ganesh47/mather",
            creditLine: "Existing Compare Camp artwork reused for Mather Memory Adventures.",
            license: "Project-owned generated artwork; no third-party source material",
            licenseUrl: "",
            retrievedAt: "2026-10-02",
            originalFileName: "CompareCampMacaw.png",
            originalSha256: "886ac375f662132c614848030d787a8a33c534188ef69ceb38f18151d5e090ed",
            derivativeFileName: "CompareCampMacaw.png",
            derivativeSha256: "886ac375f662132c614848030d787a8a33c534188ef69ceb38f18151d5e090ed",
            derivativeChanges: "Reused existing Compare Camp generated PNG unchanged; original creation documented in wiki/Specs/Compare-Camp-Generated-Asset-Provenance.md.",
            licenseAllowsReuse: true,
            noThirdPartyRestrictionFound: true,
            noLogoOrEndorsementRisk: true,
            noPeopleOrPrivacyRisk: true,
            childCardLegibilityChecked: true
        ),
        MemoryImageAssetProvenance(
            assetName: "CompareCampPeafowl",
            cardId: "bird-b11",
            sourceName: "Existing Compare Camp built-in ImageGen artwork",
            sourceUrl: "",
            creator: "OpenAI ImageGen for ganesh47/mather",
            creditLine: "Existing Compare Camp artwork reused for Mather Memory Adventures.",
            license: "Project-owned generated artwork; no third-party source material",
            licenseUrl: "",
            retrievedAt: "2026-10-02",
            originalFileName: "CompareCampPeafowl.png",
            originalSha256: "768b8729b240a971b8e0638c8b9aed9abbc855ef83cfd3b9adc2d38576c46766",
            derivativeFileName: "CompareCampPeafowl.png",
            derivativeSha256: "768b8729b240a971b8e0638c8b9aed9abbc855ef83cfd3b9adc2d38576c46766",
            derivativeChanges: "Reused existing Compare Camp generated PNG unchanged; original creation documented in wiki/Specs/Compare-Camp-Generated-Asset-Provenance.md.",
            licenseAllowsReuse: true,
            noThirdPartyRestrictionFound: true,
            noLogoOrEndorsementRisk: true,
            noPeopleOrPrivacyRisk: true,
            childCardLegibilityChecked: true
        ),
        MemoryImageAssetProvenance(
            assetName: "CompareCampPuffin",
            cardId: "bird-b16",
            sourceName: "Existing Compare Camp built-in ImageGen artwork",
            sourceUrl: "",
            creator: "OpenAI ImageGen for ganesh47/mather",
            creditLine: "Existing Compare Camp artwork reused for Mather Memory Adventures.",
            license: "Project-owned generated artwork; no third-party source material",
            licenseUrl: "",
            retrievedAt: "2026-10-02",
            originalFileName: "CompareCampPuffin.png",
            originalSha256: "0a2ae4a56a555573fde0da42882034466aaac43f9ab5b397cc981008181dfa5c",
            derivativeFileName: "CompareCampPuffin.png",
            derivativeSha256: "0a2ae4a56a555573fde0da42882034466aaac43f9ab5b397cc981008181dfa5c",
            derivativeChanges: "Reused existing Compare Camp generated PNG unchanged; original creation documented in wiki/Specs/Compare-Camp-Generated-Asset-Provenance.md.",
            licenseAllowsReuse: true,
            noThirdPartyRestrictionFound: true,
            noLogoOrEndorsementRisk: true,
            noPeopleOrPrivacyRisk: true,
            childCardLegibilityChecked: true
        ),
        MemoryImageAssetProvenance(
            assetName: "CompareCampSheep",
            cardId: "sheep",
            sourceName: "Existing Compare Camp built-in ImageGen artwork",
            sourceUrl: "",
            creator: "OpenAI ImageGen for ganesh47/mather",
            creditLine: "Existing Compare Camp artwork reused for Mather Memory Adventures.",
            license: "Project-owned generated artwork; no third-party source material",
            licenseUrl: "",
            retrievedAt: "2026-10-02",
            originalFileName: "CompareCampSheep.png",
            originalSha256: "2eb5f97ab00331a1325be4ca300b6a7232b0b7949f2cf83fd9115d6574031c75",
            derivativeFileName: "CompareCampSheep.png",
            derivativeSha256: "2eb5f97ab00331a1325be4ca300b6a7232b0b7949f2cf83fd9115d6574031c75",
            derivativeChanges: "Reused existing Compare Camp generated PNG unchanged; original creation documented in wiki/Specs/Compare-Camp-Generated-Asset-Provenance.md.",
            licenseAllowsReuse: true,
            noThirdPartyRestrictionFound: true,
            noLogoOrEndorsementRisk: true,
            noPeopleOrPrivacyRisk: true,
            childCardLegibilityChecked: true
        ),
        MemoryImageAssetProvenance(
            assetName: "MemoryAnimalCamel",
            cardId: "camel",
            sourceName: "Built-in ImageGen storybook artwork",
            sourceUrl: "",
            creator: "OpenAI ImageGen for ganesh47/mather",
            creditLine: "Storybook artwork generated for Mather Memory Adventures.",
            license: "Project-owned generated artwork; no third-party source material",
            licenseUrl: "",
            retrievedAt: "2026-10-02",
            originalFileName: "exec-66313161-fad2-4992-aaad-72b8ac4ea0c1.png",
            originalSha256: "0779372146a0fa254de89ed383ba96a216aa6bd99acba7f7156f155ffcb1489f",
            derivativeFileName: "MemoryAnimalCamel.png",
            derivativeSha256: "0779372146a0fa254de89ed383ba96a216aa6bd99acba7f7156f155ffcb1489f",
            derivativeChanges: "Copied original generated PNG unchanged into the app asset catalog.",
            licenseAllowsReuse: true,
            noThirdPartyRestrictionFound: true,
            noLogoOrEndorsementRisk: true,
            noPeopleOrPrivacyRisk: true,
            childCardLegibilityChecked: true
        ),
        MemoryImageAssetProvenance(
            assetName: "MemoryAnimalCat",
            cardId: "cat",
            sourceName: "Built-in ImageGen storybook artwork",
            sourceUrl: "",
            creator: "OpenAI ImageGen for ganesh47/mather",
            creditLine: "Storybook artwork generated for Mather Memory Adventures.",
            license: "Project-owned generated artwork; no third-party source material",
            licenseUrl: "",
            retrievedAt: "2026-10-02",
            originalFileName: "exec-7841c189-5cf7-423f-80f8-47304d55e142.png",
            originalSha256: "50d27b0d1ac50dcf58520316151e6f142f381a5272fc39e0a33ebc6329053284",
            derivativeFileName: "MemoryAnimalCat.png",
            derivativeSha256: "50d27b0d1ac50dcf58520316151e6f142f381a5272fc39e0a33ebc6329053284",
            derivativeChanges: "Copied original generated PNG unchanged into the app asset catalog.",
            licenseAllowsReuse: true,
            noThirdPartyRestrictionFound: true,
            noLogoOrEndorsementRisk: true,
            noPeopleOrPrivacyRisk: true,
            childCardLegibilityChecked: true
        ),
        MemoryImageAssetProvenance(
            assetName: "MemoryAnimalCow",
            cardId: "cow",
            sourceName: "Built-in ImageGen storybook artwork",
            sourceUrl: "",
            creator: "OpenAI ImageGen for ganesh47/mather",
            creditLine: "Storybook artwork generated for Mather Memory Adventures.",
            license: "Project-owned generated artwork; no third-party source material",
            licenseUrl: "",
            retrievedAt: "2026-10-02",
            originalFileName: "exec-38629f69-cca8-4cfd-91a2-03e108bedc64.png",
            originalSha256: "234495b4597689f4b17d36e719b969c94a20b5ba62471b68c2977b661115b12b",
            derivativeFileName: "MemoryAnimalCow.png",
            derivativeSha256: "234495b4597689f4b17d36e719b969c94a20b5ba62471b68c2977b661115b12b",
            derivativeChanges: "Copied original generated PNG unchanged into the app asset catalog.",
            licenseAllowsReuse: true,
            noThirdPartyRestrictionFound: true,
            noLogoOrEndorsementRisk: true,
            noPeopleOrPrivacyRisk: true,
            childCardLegibilityChecked: true
        ),
        MemoryImageAssetProvenance(
            assetName: "MemoryAnimalDog",
            cardId: "dog",
            sourceName: "Built-in ImageGen storybook artwork",
            sourceUrl: "",
            creator: "OpenAI ImageGen for ganesh47/mather",
            creditLine: "Storybook artwork generated for Mather Memory Adventures.",
            license: "Project-owned generated artwork; no third-party source material",
            licenseUrl: "",
            retrievedAt: "2026-10-02",
            originalFileName: "exec-da08cf80-96e3-4c54-9689-2e1d97f337e4.png",
            originalSha256: "5dbc1d590ccb0bf2ac5164611b8043c6922d98ffd9856313a9655a6923b6b3c4",
            derivativeFileName: "MemoryAnimalDog.png",
            derivativeSha256: "5dbc1d590ccb0bf2ac5164611b8043c6922d98ffd9856313a9655a6923b6b3c4",
            derivativeChanges: "Copied original generated PNG unchanged into the app asset catalog.",
            licenseAllowsReuse: true,
            noThirdPartyRestrictionFound: true,
            noLogoOrEndorsementRisk: true,
            noPeopleOrPrivacyRisk: true,
            childCardLegibilityChecked: true
        ),
        MemoryImageAssetProvenance(
            assetName: "MemoryAnimalDonkey",
            cardId: "donkey",
            sourceName: "Donkey cartoon 04 — Wikimedia Commons raster preview",
            sourceUrl: "https://commons.wikimedia.org/wiki/File:Donkey_cartoon_04.svg",
            creator: "LadyofHats",
            creditLine: "Donkey illustration by LadyofHats, public domain via Wikimedia Commons.",
            license: "Public domain — released by author",
            licenseUrl: "https://commons.wikimedia.org/wiki/File:Donkey_cartoon_04.svg#file",
            retrievedAt: "2026-10-02",
            originalFileName: "Donkey_cartoon_04.png",
            originalSha256: "a339fd2973ee1f8eb732212ef117ee3ee291043bdc5775fc058ff881fdc30629",
            derivativeFileName: "MemoryAnimalDonkey.png",
            derivativeSha256: "a339fd2973ee1f8eb732212ef117ee3ee291043bdc5775fc058ff881fdc30629",
            derivativeChanges: "Downloaded Wikimedia 960px raster preview unchanged; copied into asset catalog.",
            licenseAllowsReuse: true,
            noThirdPartyRestrictionFound: true,
            noLogoOrEndorsementRisk: true,
            noPeopleOrPrivacyRisk: true,
            childCardLegibilityChecked: true
        ),
        MemoryImageAssetProvenance(
            assetName: "MemoryAnimalDuck",
            cardId: "duck",
            sourceName: "Built-in ImageGen storybook artwork",
            sourceUrl: "",
            creator: "OpenAI ImageGen for ganesh47/mather",
            creditLine: "Storybook artwork generated for Mather Memory Adventures.",
            license: "Project-owned generated artwork; no third-party source material",
            licenseUrl: "",
            retrievedAt: "2026-10-02",
            originalFileName: "exec-769a8e07-9e08-44f7-a00d-05aea1640378.png",
            originalSha256: "6ec95d57ac0af705d9984b4ae0f52d824432b174ca398d053de15b0e3864a4c4",
            derivativeFileName: "MemoryAnimalDuck.png",
            derivativeSha256: "6ec95d57ac0af705d9984b4ae0f52d824432b174ca398d053de15b0e3864a4c4",
            derivativeChanges: "Copied original generated PNG unchanged into the app asset catalog.",
            licenseAllowsReuse: true,
            noThirdPartyRestrictionFound: true,
            noLogoOrEndorsementRisk: true,
            noPeopleOrPrivacyRisk: true,
            childCardLegibilityChecked: true
        ),
        MemoryImageAssetProvenance(
            assetName: "MemoryAnimalFrog",
            cardId: "frog",
            sourceName: "Built-in ImageGen storybook artwork",
            sourceUrl: "",
            creator: "OpenAI ImageGen for ganesh47/mather",
            creditLine: "Storybook artwork generated for Mather Memory Adventures.",
            license: "Project-owned generated artwork; no third-party source material",
            licenseUrl: "",
            retrievedAt: "2026-10-02",
            originalFileName: "exec-d3aa9c2a-125a-4c3b-88ee-9d071dc30bf9.png",
            originalSha256: "dd300a2d9b50afba6783da4ab5805ba67aaa8329aef706d0eaef07bd31193c9d",
            derivativeFileName: "MemoryAnimalFrog.png",
            derivativeSha256: "dd300a2d9b50afba6783da4ab5805ba67aaa8329aef706d0eaef07bd31193c9d",
            derivativeChanges: "Copied original generated PNG unchanged into the app asset catalog.",
            licenseAllowsReuse: true,
            noThirdPartyRestrictionFound: true,
            noLogoOrEndorsementRisk: true,
            noPeopleOrPrivacyRisk: true,
            childCardLegibilityChecked: true
        ),
        MemoryImageAssetProvenance(
            assetName: "MemoryAnimalGoat",
            cardId: "goat",
            sourceName: "Built-in ImageGen storybook artwork",
            sourceUrl: "",
            creator: "OpenAI ImageGen for ganesh47/mather",
            creditLine: "Storybook artwork generated for Mather Memory Adventures.",
            license: "Project-owned generated artwork; no third-party source material",
            licenseUrl: "",
            retrievedAt: "2026-10-02",
            originalFileName: "exec-c17b8e83-2113-4d6a-ae5b-a89e5b71e2a3.png",
            originalSha256: "9045fa037196e961a9650de3020bc6cd0633cf691bfc8d2a4e07f55adb79c823",
            derivativeFileName: "MemoryAnimalGoat.png",
            derivativeSha256: "9045fa037196e961a9650de3020bc6cd0633cf691bfc8d2a4e07f55adb79c823",
            derivativeChanges: "Copied original generated PNG unchanged into the app asset catalog.",
            licenseAllowsReuse: true,
            noThirdPartyRestrictionFound: true,
            noLogoOrEndorsementRisk: true,
            noPeopleOrPrivacyRisk: true,
            childCardLegibilityChecked: true
        ),
        MemoryImageAssetProvenance(
            assetName: "MemoryAnimalGoldfish",
            cardId: "goldfish",
            sourceName: "Built-in ImageGen storybook artwork",
            sourceUrl: "",
            creator: "OpenAI ImageGen for ganesh47/mather",
            creditLine: "Storybook artwork generated for Mather Memory Adventures.",
            license: "Project-owned generated artwork; no third-party source material",
            licenseUrl: "",
            retrievedAt: "2026-10-02",
            originalFileName: "exec-d346d563-a99e-44c4-a942-85a707e9ca10.png",
            originalSha256: "6569f92a7348fd3e78120df44f7421bcba02e424835f9d5d947e71ad71da5303",
            derivativeFileName: "MemoryAnimalGoldfish.png",
            derivativeSha256: "6569f92a7348fd3e78120df44f7421bcba02e424835f9d5d947e71ad71da5303",
            derivativeChanges: "Copied original generated PNG unchanged into the app asset catalog.",
            licenseAllowsReuse: true,
            noThirdPartyRestrictionFound: true,
            noLogoOrEndorsementRisk: true,
            noPeopleOrPrivacyRisk: true,
            childCardLegibilityChecked: true
        ),
        MemoryImageAssetProvenance(
            assetName: "MemoryAnimalHorse",
            cardId: "horse",
            sourceName: "Built-in ImageGen storybook artwork",
            sourceUrl: "",
            creator: "OpenAI ImageGen for ganesh47/mather",
            creditLine: "Storybook artwork generated for Mather Memory Adventures.",
            license: "Project-owned generated artwork; no third-party source material",
            licenseUrl: "",
            retrievedAt: "2026-10-02",
            originalFileName: "exec-c76471e9-f2cd-490d-bae6-68b662610105.png",
            originalSha256: "395262823051df90711aa5045dbdd5e4f2c53b2130e9c69a1f52ff4df8ebc204",
            derivativeFileName: "MemoryAnimalHorse.png",
            derivativeSha256: "395262823051df90711aa5045dbdd5e4f2c53b2130e9c69a1f52ff4df8ebc204",
            derivativeChanges: "Copied original generated PNG unchanged into the app asset catalog.",
            licenseAllowsReuse: true,
            noThirdPartyRestrictionFound: true,
            noLogoOrEndorsementRisk: true,
            noPeopleOrPrivacyRisk: true,
            childCardLegibilityChecked: true
        ),
        MemoryImageAssetProvenance(
            assetName: "MemoryAnimalLlama",
            cardId: "llama",
            sourceName: "Built-in ImageGen storybook artwork",
            sourceUrl: "",
            creator: "OpenAI ImageGen for ganesh47/mather",
            creditLine: "Storybook artwork generated for Mather Memory Adventures.",
            license: "Project-owned generated artwork; no third-party source material",
            licenseUrl: "",
            retrievedAt: "2026-10-02",
            originalFileName: "exec-1e6f8954-58c5-459f-8e7d-efe9fdc44919.png",
            originalSha256: "9cb4e3c7c791a933881ac08c96f541af89cfd8af31d02e9f745a0cb1b5050e1e",
            derivativeFileName: "MemoryAnimalLlama.png",
            derivativeSha256: "9cb4e3c7c791a933881ac08c96f541af89cfd8af31d02e9f745a0cb1b5050e1e",
            derivativeChanges: "Copied original generated PNG unchanged into the app asset catalog.",
            licenseAllowsReuse: true,
            noThirdPartyRestrictionFound: true,
            noLogoOrEndorsementRisk: true,
            noPeopleOrPrivacyRisk: true,
            childCardLegibilityChecked: true
        ),
        MemoryImageAssetProvenance(
            assetName: "MemoryAnimalMouse",
            cardId: "mouse",
            sourceName: "Built-in ImageGen storybook artwork",
            sourceUrl: "",
            creator: "OpenAI ImageGen for ganesh47/mather",
            creditLine: "Storybook artwork generated for Mather Memory Adventures.",
            license: "Project-owned generated artwork; no third-party source material",
            licenseUrl: "",
            retrievedAt: "2026-10-02",
            originalFileName: "exec-dc8bfda7-6551-4e59-b8a7-9eef5c9b0b7c.png",
            originalSha256: "de07fe2add60fe9db92c7b125202b73ca733e27c13898b3f5a35f0efbfc9910a",
            derivativeFileName: "MemoryAnimalMouse.png",
            derivativeSha256: "de07fe2add60fe9db92c7b125202b73ca733e27c13898b3f5a35f0efbfc9910a",
            derivativeChanges: "Copied original generated PNG unchanged into the app asset catalog.",
            licenseAllowsReuse: true,
            noThirdPartyRestrictionFound: true,
            noLogoOrEndorsementRisk: true,
            noPeopleOrPrivacyRisk: true,
            childCardLegibilityChecked: true
        ),
        MemoryImageAssetProvenance(
            assetName: "MemoryAnimalOx",
            cardId: "ox",
            sourceName: "Built-in ImageGen storybook artwork",
            sourceUrl: "",
            creator: "OpenAI ImageGen for ganesh47/mather",
            creditLine: "Storybook artwork generated for Mather Memory Adventures.",
            license: "Project-owned generated artwork; no third-party source material",
            licenseUrl: "",
            retrievedAt: "2026-10-02",
            originalFileName: "exec-e15da289-92d4-4e3e-973f-465c90a8dfd1.png",
            originalSha256: "4202f6e19f7905a04d27af7167e13b6493fa8b2e8b3c7e1a707d1132824104a5",
            derivativeFileName: "MemoryAnimalOx.png",
            derivativeSha256: "4202f6e19f7905a04d27af7167e13b6493fa8b2e8b3c7e1a707d1132824104a5",
            derivativeChanges: "Copied original generated PNG unchanged into the app asset catalog.",
            licenseAllowsReuse: true,
            noThirdPartyRestrictionFound: true,
            noLogoOrEndorsementRisk: true,
            noPeopleOrPrivacyRisk: true,
            childCardLegibilityChecked: true
        ),
        MemoryImageAssetProvenance(
            assetName: "MemoryAnimalPig",
            cardId: "pig",
            sourceName: "Built-in ImageGen storybook artwork",
            sourceUrl: "",
            creator: "OpenAI ImageGen for ganesh47/mather",
            creditLine: "Storybook artwork generated for Mather Memory Adventures.",
            license: "Project-owned generated artwork; no third-party source material",
            licenseUrl: "",
            retrievedAt: "2026-10-02",
            originalFileName: "exec-8308d490-6cfc-443f-b8f8-db73ea2c785e.png",
            originalSha256: "c8ecfee28b29b8df6345df513fd7d86db9fa48e8408cc261ec0a93aa609054fa",
            derivativeFileName: "MemoryAnimalPig.png",
            derivativeSha256: "c8ecfee28b29b8df6345df513fd7d86db9fa48e8408cc261ec0a93aa609054fa",
            derivativeChanges: "Copied original generated PNG unchanged into the app asset catalog.",
            licenseAllowsReuse: true,
            noThirdPartyRestrictionFound: true,
            noLogoOrEndorsementRisk: true,
            noPeopleOrPrivacyRisk: true,
            childCardLegibilityChecked: true
        ),
        MemoryImageAssetProvenance(
            assetName: "MemoryAnimalRabbit",
            cardId: "rabbit",
            sourceName: "Built-in ImageGen storybook artwork",
            sourceUrl: "",
            creator: "OpenAI ImageGen for ganesh47/mather",
            creditLine: "Storybook artwork generated for Mather Memory Adventures.",
            license: "Project-owned generated artwork; no third-party source material",
            licenseUrl: "",
            retrievedAt: "2026-10-02",
            originalFileName: "exec-d32d7760-e420-4fae-af1f-dd289a4949c0.png",
            originalSha256: "4130ff0a46764cb2d9c7604b146f9c6e962f12f1577e0a4e45656bef14fa0f73",
            derivativeFileName: "MemoryAnimalRabbit.png",
            derivativeSha256: "4130ff0a46764cb2d9c7604b146f9c6e962f12f1577e0a4e45656bef14fa0f73",
            derivativeChanges: "Copied original generated PNG unchanged into the app asset catalog.",
            licenseAllowsReuse: true,
            noThirdPartyRestrictionFound: true,
            noLogoOrEndorsementRisk: true,
            noPeopleOrPrivacyRisk: true,
            childCardLegibilityChecked: true
        ),
        MemoryImageAssetProvenance(
            assetName: "MemoryAnimalRooster",
            cardId: "rooster",
            sourceName: "Built-in ImageGen storybook artwork",
            sourceUrl: "",
            creator: "OpenAI ImageGen for ganesh47/mather",
            creditLine: "Storybook artwork generated for Mather Memory Adventures.",
            license: "Project-owned generated artwork; no third-party source material",
            licenseUrl: "",
            retrievedAt: "2026-10-02",
            originalFileName: "exec-e6f639f4-0e54-4ed8-a7f3-29ea322ad0f0.png",
            originalSha256: "61c4a0ad38d80943ca80f146846092501fd5fc212fffde3cb7f93099b81b9da7",
            derivativeFileName: "MemoryAnimalRooster.png",
            derivativeSha256: "61c4a0ad38d80943ca80f146846092501fd5fc212fffde3cb7f93099b81b9da7",
            derivativeChanges: "Copied original generated PNG unchanged into the app asset catalog.",
            licenseAllowsReuse: true,
            noThirdPartyRestrictionFound: true,
            noLogoOrEndorsementRisk: true,
            noPeopleOrPrivacyRisk: true,
            childCardLegibilityChecked: true
        ),
        MemoryImageAssetProvenance(
            assetName: "MemoryAnimalTurkey",
            cardId: "turkey",
            sourceName: "Built-in ImageGen storybook artwork",
            sourceUrl: "",
            creator: "OpenAI ImageGen for ganesh47/mather",
            creditLine: "Storybook artwork generated for Mather Memory Adventures.",
            license: "Project-owned generated artwork; no third-party source material",
            licenseUrl: "",
            retrievedAt: "2026-10-02",
            originalFileName: "exec-6a805cbb-2993-4f48-abb9-346684b24f9e.png",
            originalSha256: "f76a05a39c0d5cbd883be113443601459dbbf19a22ba5dd8f33b5ab54edd6650",
            derivativeFileName: "MemoryAnimalTurkey.png",
            derivativeSha256: "f76a05a39c0d5cbd883be113443601459dbbf19a22ba5dd8f33b5ab54edd6650",
            derivativeChanges: "Copied original generated PNG unchanged into the app asset catalog.",
            licenseAllowsReuse: true,
            noThirdPartyRestrictionFound: true,
            noLogoOrEndorsementRisk: true,
            noPeopleOrPrivacyRisk: true,
            childCardLegibilityChecked: true
        ),
        MemoryImageAssetProvenance(
            assetName: "MemoryBirdCleanA02",
            cardId: "bird-a02",
            sourceName: "Built-in ImageGen storybook artwork",
            sourceUrl: "",
            creator: "OpenAI ImageGen for ganesh47/mather",
            creditLine: "Storybook artwork generated for Mather Memory Adventures.",
            license: "Project-owned generated artwork; no third-party source material",
            licenseUrl: "",
            retrievedAt: "2026-10-02",
            originalFileName: "exec-b0f8e1a6-1b50-4b6d-8597-9cdbc4e9d01b.png",
            originalSha256: "8fd41703e8e34e2a21ca7d8e4ae4f93ac3afff57df56a027e846ae326bd8dfc6",
            derivativeFileName: "MemoryBirdCleanA02.png",
            derivativeSha256: "8fd41703e8e34e2a21ca7d8e4ae4f93ac3afff57df56a027e846ae326bd8dfc6",
            derivativeChanges: "Copied original generated PNG unchanged into the app asset catalog.",
            licenseAllowsReuse: true,
            noThirdPartyRestrictionFound: true,
            noLogoOrEndorsementRisk: true,
            noPeopleOrPrivacyRisk: true,
            childCardLegibilityChecked: true
        ),
        MemoryImageAssetProvenance(
            assetName: "MemoryBirdCleanA03",
            cardId: "bird-a03",
            sourceName: "Built-in ImageGen storybook artwork",
            sourceUrl: "",
            creator: "OpenAI ImageGen for ganesh47/mather",
            creditLine: "Storybook artwork generated for Mather Memory Adventures.",
            license: "Project-owned generated artwork; no third-party source material",
            licenseUrl: "",
            retrievedAt: "2026-10-02",
            originalFileName: "exec-707838c0-f77f-4b37-b573-3820fe3be3a0.png",
            originalSha256: "9cc0c1aa14b923a935b736118340105a805c5c271d2752e3ea660403afb67055",
            derivativeFileName: "MemoryBirdCleanA03.png",
            derivativeSha256: "9cc0c1aa14b923a935b736118340105a805c5c271d2752e3ea660403afb67055",
            derivativeChanges: "Copied original generated PNG unchanged into the app asset catalog.",
            licenseAllowsReuse: true,
            noThirdPartyRestrictionFound: true,
            noLogoOrEndorsementRisk: true,
            noPeopleOrPrivacyRisk: true,
            childCardLegibilityChecked: true
        ),
        MemoryImageAssetProvenance(
            assetName: "MemoryBirdCleanA04",
            cardId: "bird-a04",
            sourceName: "Built-in ImageGen storybook artwork",
            sourceUrl: "",
            creator: "OpenAI ImageGen for ganesh47/mather",
            creditLine: "Storybook artwork generated for Mather Memory Adventures.",
            license: "Project-owned generated artwork; no third-party source material",
            licenseUrl: "",
            retrievedAt: "2026-10-02",
            originalFileName: "exec-7f2d5445-a844-4c7b-9854-0292dc4f9379.png",
            originalSha256: "61501f713a85704c4a829547a57e1425a02d4e3f4109b10f8080734fc8c8a0e9",
            derivativeFileName: "MemoryBirdCleanA04.png",
            derivativeSha256: "61501f713a85704c4a829547a57e1425a02d4e3f4109b10f8080734fc8c8a0e9",
            derivativeChanges: "Copied original generated PNG unchanged into the app asset catalog.",
            licenseAllowsReuse: true,
            noThirdPartyRestrictionFound: true,
            noLogoOrEndorsementRisk: true,
            noPeopleOrPrivacyRisk: true,
            childCardLegibilityChecked: true
        ),
        MemoryImageAssetProvenance(
            assetName: "MemoryBirdCleanA05",
            cardId: "bird-a05",
            sourceName: "Built-in ImageGen storybook artwork",
            sourceUrl: "",
            creator: "OpenAI ImageGen for ganesh47/mather",
            creditLine: "Storybook artwork generated for Mather Memory Adventures.",
            license: "Project-owned generated artwork; no third-party source material",
            licenseUrl: "",
            retrievedAt: "2026-10-02",
            originalFileName: "exec-a1cfe76c-815a-4e40-83e8-2699afae652e.png",
            originalSha256: "4ef69464cf89f750574ee3548b96b1cdc804f90801b2c11c9cbf05d3191495ec",
            derivativeFileName: "MemoryBirdCleanA05.png",
            derivativeSha256: "4ef69464cf89f750574ee3548b96b1cdc804f90801b2c11c9cbf05d3191495ec",
            derivativeChanges: "Copied original generated PNG unchanged into the app asset catalog.",
            licenseAllowsReuse: true,
            noThirdPartyRestrictionFound: true,
            noLogoOrEndorsementRisk: true,
            noPeopleOrPrivacyRisk: true,
            childCardLegibilityChecked: true
        ),
        MemoryImageAssetProvenance(
            assetName: "MemoryBirdCleanA06",
            cardId: "bird-a06",
            sourceName: "Built-in ImageGen storybook artwork",
            sourceUrl: "",
            creator: "OpenAI ImageGen for ganesh47/mather",
            creditLine: "Storybook artwork generated for Mather Memory Adventures.",
            license: "Project-owned generated artwork; no third-party source material",
            licenseUrl: "",
            retrievedAt: "2026-10-02",
            originalFileName: "exec-c7cbff86-e282-454f-becd-453e20d3ea61.png",
            originalSha256: "61ddac32d6c891e7e7601d121b9d920ce95916ec86d657c32d7b278a492fed2e",
            derivativeFileName: "MemoryBirdCleanA06.png",
            derivativeSha256: "61ddac32d6c891e7e7601d121b9d920ce95916ec86d657c32d7b278a492fed2e",
            derivativeChanges: "Copied original generated PNG unchanged into the app asset catalog.",
            licenseAllowsReuse: true,
            noThirdPartyRestrictionFound: true,
            noLogoOrEndorsementRisk: true,
            noPeopleOrPrivacyRisk: true,
            childCardLegibilityChecked: true
        ),
        MemoryImageAssetProvenance(
            assetName: "MemoryBirdCleanA07",
            cardId: "bird-a07",
            sourceName: "Built-in ImageGen storybook artwork",
            sourceUrl: "",
            creator: "OpenAI ImageGen for ganesh47/mather",
            creditLine: "Storybook artwork generated for Mather Memory Adventures.",
            license: "Project-owned generated artwork; no third-party source material",
            licenseUrl: "",
            retrievedAt: "2026-10-02",
            originalFileName: "exec-155bc0a2-1630-4fb9-8161-a53c090c3c11.png",
            originalSha256: "c2fcbc02e912e709d65389bc946d2963cc63976c137bc85b9cb50525a94569f3",
            derivativeFileName: "MemoryBirdCleanA07.png",
            derivativeSha256: "c2fcbc02e912e709d65389bc946d2963cc63976c137bc85b9cb50525a94569f3",
            derivativeChanges: "Copied original generated PNG unchanged into the app asset catalog.",
            licenseAllowsReuse: true,
            noThirdPartyRestrictionFound: true,
            noLogoOrEndorsementRisk: true,
            noPeopleOrPrivacyRisk: true,
            childCardLegibilityChecked: true
        ),
        MemoryImageAssetProvenance(
            assetName: "MemoryBirdCleanA08",
            cardId: "bird-a08",
            sourceName: "Built-in ImageGen storybook artwork",
            sourceUrl: "",
            creator: "OpenAI ImageGen for ganesh47/mather",
            creditLine: "Storybook artwork generated for Mather Memory Adventures.",
            license: "Project-owned generated artwork; no third-party source material",
            licenseUrl: "",
            retrievedAt: "2026-10-02",
            originalFileName: "exec-e7f43c62-f6da-4955-acc8-c3d4ccfc65e2.png",
            originalSha256: "62c043f0381aff77a0b75f046af95de79eb95c8d4a63e3c0b0dd52eb95e34d93",
            derivativeFileName: "MemoryBirdCleanA08.png",
            derivativeSha256: "62c043f0381aff77a0b75f046af95de79eb95c8d4a63e3c0b0dd52eb95e34d93",
            derivativeChanges: "Copied original generated PNG unchanged into the app asset catalog.",
            licenseAllowsReuse: true,
            noThirdPartyRestrictionFound: true,
            noLogoOrEndorsementRisk: true,
            noPeopleOrPrivacyRisk: true,
            childCardLegibilityChecked: true
        ),
        MemoryImageAssetProvenance(
            assetName: "MemoryBirdCleanA09",
            cardId: "bird-a09",
            sourceName: "Built-in ImageGen storybook artwork",
            sourceUrl: "",
            creator: "OpenAI ImageGen for ganesh47/mather",
            creditLine: "Storybook artwork generated for Mather Memory Adventures.",
            license: "Project-owned generated artwork; no third-party source material",
            licenseUrl: "",
            retrievedAt: "2026-10-02",
            originalFileName: "exec-58ff6e8e-996e-4ae2-a5c9-091b0b2fbdce.png",
            originalSha256: "a6fb79b8fee3674e5f954ae38fa73da6b551f46dec5a1c375595fc9e6151be4c",
            derivativeFileName: "MemoryBirdCleanA09.png",
            derivativeSha256: "a6fb79b8fee3674e5f954ae38fa73da6b551f46dec5a1c375595fc9e6151be4c",
            derivativeChanges: "Copied original generated PNG unchanged into the app asset catalog.",
            licenseAllowsReuse: true,
            noThirdPartyRestrictionFound: true,
            noLogoOrEndorsementRisk: true,
            noPeopleOrPrivacyRisk: true,
            childCardLegibilityChecked: true
        ),
        MemoryImageAssetProvenance(
            assetName: "MemoryBirdCleanA10",
            cardId: "bird-a10",
            sourceName: "Built-in ImageGen storybook artwork",
            sourceUrl: "",
            creator: "OpenAI ImageGen for ganesh47/mather",
            creditLine: "Storybook artwork generated for Mather Memory Adventures.",
            license: "Project-owned generated artwork; no third-party source material",
            licenseUrl: "",
            retrievedAt: "2026-10-02",
            originalFileName: "exec-ed7605b6-e70a-4915-bd1c-fd814fd585d6.png",
            originalSha256: "0f4b236d724254d725e9a87f58e5e85a289174020ebe3e6327eefa937939107d",
            derivativeFileName: "MemoryBirdCleanA10.png",
            derivativeSha256: "0f4b236d724254d725e9a87f58e5e85a289174020ebe3e6327eefa937939107d",
            derivativeChanges: "Copied original generated PNG unchanged into the app asset catalog.",
            licenseAllowsReuse: true,
            noThirdPartyRestrictionFound: true,
            noLogoOrEndorsementRisk: true,
            noPeopleOrPrivacyRisk: true,
            childCardLegibilityChecked: true
        ),
        MemoryImageAssetProvenance(
            assetName: "MemoryBirdCleanA11",
            cardId: "bird-a11",
            sourceName: "Built-in ImageGen storybook artwork",
            sourceUrl: "",
            creator: "OpenAI ImageGen for ganesh47/mather",
            creditLine: "Storybook artwork generated for Mather Memory Adventures.",
            license: "Project-owned generated artwork; no third-party source material",
            licenseUrl: "",
            retrievedAt: "2026-10-02",
            originalFileName: "exec-055fa30a-a31b-4211-bd57-8d2a94bc18fe.png",
            originalSha256: "6c1217e168f125f9a637adac76a845a8aac8003d4fd84b566a2d19e05dabf3d6",
            derivativeFileName: "MemoryBirdCleanA11.png",
            derivativeSha256: "6c1217e168f125f9a637adac76a845a8aac8003d4fd84b566a2d19e05dabf3d6",
            derivativeChanges: "Copied original generated PNG unchanged into the app asset catalog.",
            licenseAllowsReuse: true,
            noThirdPartyRestrictionFound: true,
            noLogoOrEndorsementRisk: true,
            noPeopleOrPrivacyRisk: true,
            childCardLegibilityChecked: true
        ),
        MemoryImageAssetProvenance(
            assetName: "MemoryBirdCleanA13",
            cardId: "bird-a13",
            sourceName: "Built-in ImageGen storybook artwork",
            sourceUrl: "",
            creator: "OpenAI ImageGen for ganesh47/mather",
            creditLine: "Storybook artwork generated for Mather Memory Adventures.",
            license: "Project-owned generated artwork; no third-party source material",
            licenseUrl: "",
            retrievedAt: "2026-10-02",
            originalFileName: "exec-c0449f46-7e97-47fa-ab7d-83fe44457d0b.png",
            originalSha256: "bf1b4fff120c7c2ba925fbb9bbc34d7a373cc7e6e6c991a7217f9b0c2bd31772",
            derivativeFileName: "MemoryBirdCleanA13.png",
            derivativeSha256: "bf1b4fff120c7c2ba925fbb9bbc34d7a373cc7e6e6c991a7217f9b0c2bd31772",
            derivativeChanges: "Copied original generated PNG unchanged into the app asset catalog.",
            licenseAllowsReuse: true,
            noThirdPartyRestrictionFound: true,
            noLogoOrEndorsementRisk: true,
            noPeopleOrPrivacyRisk: true,
            childCardLegibilityChecked: true
        ),
        MemoryImageAssetProvenance(
            assetName: "MemoryBirdCleanA14",
            cardId: "bird-a14",
            sourceName: "Built-in ImageGen storybook artwork",
            sourceUrl: "",
            creator: "OpenAI ImageGen for ganesh47/mather",
            creditLine: "Storybook artwork generated for Mather Memory Adventures.",
            license: "Project-owned generated artwork; no third-party source material",
            licenseUrl: "",
            retrievedAt: "2026-10-02",
            originalFileName: "exec-59790727-c9c7-4a0a-aa17-06d8d3021ea8.png",
            originalSha256: "fa64ec0d489cd93653281d1cb904728b577583376fa2d97f10253849c9691974",
            derivativeFileName: "MemoryBirdCleanA14.png",
            derivativeSha256: "fa64ec0d489cd93653281d1cb904728b577583376fa2d97f10253849c9691974",
            derivativeChanges: "Copied original generated PNG unchanged into the app asset catalog.",
            licenseAllowsReuse: true,
            noThirdPartyRestrictionFound: true,
            noLogoOrEndorsementRisk: true,
            noPeopleOrPrivacyRisk: true,
            childCardLegibilityChecked: true
        ),
        MemoryImageAssetProvenance(
            assetName: "MemoryBirdCleanA15",
            cardId: "bird-a15",
            sourceName: "Built-in ImageGen storybook artwork",
            sourceUrl: "",
            creator: "OpenAI ImageGen for ganesh47/mather",
            creditLine: "Storybook artwork generated for Mather Memory Adventures.",
            license: "Project-owned generated artwork; no third-party source material",
            licenseUrl: "",
            retrievedAt: "2026-10-02",
            originalFileName: "exec-c0fc376d-d835-4fd4-8358-7cb7c4534010.png",
            originalSha256: "1c8c26fbc46143aecbe672f94eede5126ea880111a1a60c7f8be2d7bc001f1f4",
            derivativeFileName: "MemoryBirdCleanA15.png",
            derivativeSha256: "1c8c26fbc46143aecbe672f94eede5126ea880111a1a60c7f8be2d7bc001f1f4",
            derivativeChanges: "Copied original generated PNG unchanged into the app asset catalog.",
            licenseAllowsReuse: true,
            noThirdPartyRestrictionFound: true,
            noLogoOrEndorsementRisk: true,
            noPeopleOrPrivacyRisk: true,
            childCardLegibilityChecked: true
        ),
        MemoryImageAssetProvenance(
            assetName: "MemoryBirdCleanA16",
            cardId: "bird-a16",
            sourceName: "Built-in ImageGen storybook artwork",
            sourceUrl: "",
            creator: "OpenAI ImageGen for ganesh47/mather",
            creditLine: "Storybook artwork generated for Mather Memory Adventures.",
            license: "Project-owned generated artwork; no third-party source material",
            licenseUrl: "",
            retrievedAt: "2026-10-02",
            originalFileName: "exec-7ba32b14-d284-43bd-a8e5-9e220a485dc0.png",
            originalSha256: "e86622ce74b8290e3ad4eee790cb41a026ba4a35629ca84e9dfd99b06550bc50",
            derivativeFileName: "MemoryBirdCleanA16.png",
            derivativeSha256: "e86622ce74b8290e3ad4eee790cb41a026ba4a35629ca84e9dfd99b06550bc50",
            derivativeChanges: "Copied original generated PNG unchanged into the app asset catalog.",
            licenseAllowsReuse: true,
            noThirdPartyRestrictionFound: true,
            noLogoOrEndorsementRisk: true,
            noPeopleOrPrivacyRisk: true,
            childCardLegibilityChecked: true
        ),
        MemoryImageAssetProvenance(
            assetName: "MemoryBirdCleanA17",
            cardId: "bird-a17",
            sourceName: "Built-in ImageGen storybook artwork",
            sourceUrl: "",
            creator: "OpenAI ImageGen for ganesh47/mather",
            creditLine: "Storybook artwork generated for Mather Memory Adventures.",
            license: "Project-owned generated artwork; no third-party source material",
            licenseUrl: "",
            retrievedAt: "2026-10-02",
            originalFileName: "exec-2bc827bc-b83d-4315-8289-a0420c05c245.png",
            originalSha256: "981ddfb3e082d71b061373e5f17906a626e98c99bacc54e968afdcc697c728d9",
            derivativeFileName: "MemoryBirdCleanA17.png",
            derivativeSha256: "981ddfb3e082d71b061373e5f17906a626e98c99bacc54e968afdcc697c728d9",
            derivativeChanges: "Copied original generated PNG unchanged into the app asset catalog.",
            licenseAllowsReuse: true,
            noThirdPartyRestrictionFound: true,
            noLogoOrEndorsementRisk: true,
            noPeopleOrPrivacyRisk: true,
            childCardLegibilityChecked: true
        ),
        MemoryImageAssetProvenance(
            assetName: "MemoryBirdCleanA18",
            cardId: "bird-a18",
            sourceName: "Built-in ImageGen storybook artwork",
            sourceUrl: "",
            creator: "OpenAI ImageGen for ganesh47/mather",
            creditLine: "Storybook artwork generated for Mather Memory Adventures.",
            license: "Project-owned generated artwork; no third-party source material",
            licenseUrl: "",
            retrievedAt: "2026-10-02",
            originalFileName: "exec-714d72d0-d4d6-421a-9526-e2d2a07fb995.png",
            originalSha256: "c301b5ae80b426d0618577d1dd40e21a9a06c25183b6fbec0fbc12a4b79a5735",
            derivativeFileName: "MemoryBirdCleanA18.png",
            derivativeSha256: "c301b5ae80b426d0618577d1dd40e21a9a06c25183b6fbec0fbc12a4b79a5735",
            derivativeChanges: "Copied original generated PNG unchanged into the app asset catalog.",
            licenseAllowsReuse: true,
            noThirdPartyRestrictionFound: true,
            noLogoOrEndorsementRisk: true,
            noPeopleOrPrivacyRisk: true,
            childCardLegibilityChecked: true
        ),
        MemoryImageAssetProvenance(
            assetName: "MemoryBirdCleanB01",
            cardId: "bird-b01",
            sourceName: "Built-in ImageGen storybook artwork",
            sourceUrl: "",
            creator: "OpenAI ImageGen for ganesh47/mather",
            creditLine: "Storybook artwork generated for Mather Memory Adventures.",
            license: "Project-owned generated artwork; no third-party source material",
            licenseUrl: "",
            retrievedAt: "2026-10-02",
            originalFileName: "exec-6ad9d82f-7483-49de-a37c-0ec44e5590d4.png",
            originalSha256: "13bbc95f853409076271676122f48bfcc11dbf87edac3dd8b7d1c14e722d4adb",
            derivativeFileName: "MemoryBirdCleanB01.png",
            derivativeSha256: "13bbc95f853409076271676122f48bfcc11dbf87edac3dd8b7d1c14e722d4adb",
            derivativeChanges: "Copied original generated PNG unchanged into the app asset catalog.",
            licenseAllowsReuse: true,
            noThirdPartyRestrictionFound: true,
            noLogoOrEndorsementRisk: true,
            noPeopleOrPrivacyRisk: true,
            childCardLegibilityChecked: true
        ),
        MemoryImageAssetProvenance(
            assetName: "MemoryBirdCleanB02",
            cardId: "bird-b02",
            sourceName: "Built-in ImageGen storybook artwork",
            sourceUrl: "",
            creator: "OpenAI ImageGen for ganesh47/mather",
            creditLine: "Storybook artwork generated for Mather Memory Adventures.",
            license: "Project-owned generated artwork; no third-party source material",
            licenseUrl: "",
            retrievedAt: "2026-10-02",
            originalFileName: "exec-e92d8df2-c1f6-4a15-904d-5d53d31a4ae5.png",
            originalSha256: "20bba52f0c21c1bdd8058ec76e5dcea07de8ef53f6cafe8fb84ee776c200fdd3",
            derivativeFileName: "MemoryBirdCleanB02.png",
            derivativeSha256: "20bba52f0c21c1bdd8058ec76e5dcea07de8ef53f6cafe8fb84ee776c200fdd3",
            derivativeChanges: "Copied original generated PNG unchanged into the app asset catalog.",
            licenseAllowsReuse: true,
            noThirdPartyRestrictionFound: true,
            noLogoOrEndorsementRisk: true,
            noPeopleOrPrivacyRisk: true,
            childCardLegibilityChecked: true
        ),
        MemoryImageAssetProvenance(
            assetName: "MemoryBirdCleanB03",
            cardId: "bird-b03",
            sourceName: "Built-in ImageGen storybook artwork",
            sourceUrl: "",
            creator: "OpenAI ImageGen for ganesh47/mather",
            creditLine: "Storybook artwork generated for Mather Memory Adventures.",
            license: "Project-owned generated artwork; no third-party source material",
            licenseUrl: "",
            retrievedAt: "2026-10-02",
            originalFileName: "exec-2a3011b6-0687-43d5-819c-aa72299a4409.png",
            originalSha256: "f166c86fa89d85d1dc2cc3e7ed03e559d0281ac88ef80ee0a43311a6680c7ddb",
            derivativeFileName: "MemoryBirdCleanB03.png",
            derivativeSha256: "f166c86fa89d85d1dc2cc3e7ed03e559d0281ac88ef80ee0a43311a6680c7ddb",
            derivativeChanges: "Copied original generated PNG unchanged into the app asset catalog.",
            licenseAllowsReuse: true,
            noThirdPartyRestrictionFound: true,
            noLogoOrEndorsementRisk: true,
            noPeopleOrPrivacyRisk: true,
            childCardLegibilityChecked: true
        ),
        MemoryImageAssetProvenance(
            assetName: "MemoryBirdCleanB04",
            cardId: "bird-b04",
            sourceName: "Built-in ImageGen storybook artwork",
            sourceUrl: "",
            creator: "OpenAI ImageGen for ganesh47/mather",
            creditLine: "Storybook artwork generated for Mather Memory Adventures.",
            license: "Project-owned generated artwork; no third-party source material",
            licenseUrl: "",
            retrievedAt: "2026-10-02",
            originalFileName: "exec-844a0c79-e268-4c36-989f-c7d65ab32520.png",
            originalSha256: "2336ea416e9be6eaf6bc60cfb58fd38df2dd8c886976f0289304fda34b67b245",
            derivativeFileName: "MemoryBirdCleanB04.png",
            derivativeSha256: "2336ea416e9be6eaf6bc60cfb58fd38df2dd8c886976f0289304fda34b67b245",
            derivativeChanges: "Copied original generated PNG unchanged into the app asset catalog.",
            licenseAllowsReuse: true,
            noThirdPartyRestrictionFound: true,
            noLogoOrEndorsementRisk: true,
            noPeopleOrPrivacyRisk: true,
            childCardLegibilityChecked: true
        ),
        MemoryImageAssetProvenance(
            assetName: "MemoryBirdCleanB05",
            cardId: "bird-b05",
            sourceName: "Built-in ImageGen storybook artwork",
            sourceUrl: "",
            creator: "OpenAI ImageGen for ganesh47/mather",
            creditLine: "Storybook artwork generated for Mather Memory Adventures.",
            license: "Project-owned generated artwork; no third-party source material",
            licenseUrl: "",
            retrievedAt: "2026-10-02",
            originalFileName: "exec-a3f82913-20c0-4cf3-bea2-fe91c333aab2.png",
            originalSha256: "f340757246ce350d7fa049bc469e5316aa2b6b7530a8b2686c102a2653eded0e",
            derivativeFileName: "MemoryBirdCleanB05.png",
            derivativeSha256: "f340757246ce350d7fa049bc469e5316aa2b6b7530a8b2686c102a2653eded0e",
            derivativeChanges: "Copied original generated PNG unchanged into the app asset catalog.",
            licenseAllowsReuse: true,
            noThirdPartyRestrictionFound: true,
            noLogoOrEndorsementRisk: true,
            noPeopleOrPrivacyRisk: true,
            childCardLegibilityChecked: true
        ),
        MemoryImageAssetProvenance(
            assetName: "MemoryBirdCleanB06",
            cardId: "bird-b06",
            sourceName: "Built-in ImageGen storybook artwork",
            sourceUrl: "",
            creator: "OpenAI ImageGen for ganesh47/mather",
            creditLine: "Storybook artwork generated for Mather Memory Adventures.",
            license: "Project-owned generated artwork; no third-party source material",
            licenseUrl: "",
            retrievedAt: "2026-10-02",
            originalFileName: "exec-2d421b44-6bf7-437f-857e-774f1d08bb75.png",
            originalSha256: "c8457011dada88b3c58e68cd19ff25a4e44e7f9382df2c8933cda0b3d851d1c8",
            derivativeFileName: "MemoryBirdCleanB06.png",
            derivativeSha256: "c8457011dada88b3c58e68cd19ff25a4e44e7f9382df2c8933cda0b3d851d1c8",
            derivativeChanges: "Copied original generated PNG unchanged into the app asset catalog.",
            licenseAllowsReuse: true,
            noThirdPartyRestrictionFound: true,
            noLogoOrEndorsementRisk: true,
            noPeopleOrPrivacyRisk: true,
            childCardLegibilityChecked: true
        ),
        MemoryImageAssetProvenance(
            assetName: "MemoryBirdCleanB07",
            cardId: "bird-b07",
            sourceName: "Built-in ImageGen storybook artwork",
            sourceUrl: "",
            creator: "OpenAI ImageGen for ganesh47/mather",
            creditLine: "Storybook artwork generated for Mather Memory Adventures.",
            license: "Project-owned generated artwork; no third-party source material",
            licenseUrl: "",
            retrievedAt: "2026-10-02",
            originalFileName: "exec-0036f12d-4070-475a-b28c-567c46900e01.png",
            originalSha256: "04ce2d4b1bd7dd335da8b949a6296511eedd06b3a10b2bc132503d54509f33ee",
            derivativeFileName: "MemoryBirdCleanB07.png",
            derivativeSha256: "04ce2d4b1bd7dd335da8b949a6296511eedd06b3a10b2bc132503d54509f33ee",
            derivativeChanges: "Copied original generated PNG unchanged into the app asset catalog.",
            licenseAllowsReuse: true,
            noThirdPartyRestrictionFound: true,
            noLogoOrEndorsementRisk: true,
            noPeopleOrPrivacyRisk: true,
            childCardLegibilityChecked: true
        ),
        MemoryImageAssetProvenance(
            assetName: "MemoryBirdCleanB08",
            cardId: "bird-b08",
            sourceName: "Built-in ImageGen storybook artwork",
            sourceUrl: "",
            creator: "OpenAI ImageGen for ganesh47/mather",
            creditLine: "Storybook artwork generated for Mather Memory Adventures.",
            license: "Project-owned generated artwork; no third-party source material",
            licenseUrl: "",
            retrievedAt: "2026-10-02",
            originalFileName: "exec-3022a631-00c1-45ec-a8e2-373eae399fc7.png",
            originalSha256: "5c3428673a8fb80c82adc8bffbe27888502a9a09f901f91dc271692bfd6b1cc6",
            derivativeFileName: "MemoryBirdCleanB08.png",
            derivativeSha256: "5c3428673a8fb80c82adc8bffbe27888502a9a09f901f91dc271692bfd6b1cc6",
            derivativeChanges: "Copied original generated PNG unchanged into the app asset catalog.",
            licenseAllowsReuse: true,
            noThirdPartyRestrictionFound: true,
            noLogoOrEndorsementRisk: true,
            noPeopleOrPrivacyRisk: true,
            childCardLegibilityChecked: true
        ),
        MemoryImageAssetProvenance(
            assetName: "MemoryBirdCleanB09",
            cardId: "bird-b09",
            sourceName: "Built-in ImageGen storybook artwork",
            sourceUrl: "",
            creator: "OpenAI ImageGen for ganesh47/mather",
            creditLine: "Storybook artwork generated for Mather Memory Adventures.",
            license: "Project-owned generated artwork; no third-party source material",
            licenseUrl: "",
            retrievedAt: "2026-10-02",
            originalFileName: "exec-68fc644a-0f94-4b39-9fac-8019a629a0a8.png",
            originalSha256: "8cc0517986fce60d0ccd45918d08d01dbc145fa98805905d1a407da86c7faceb",
            derivativeFileName: "MemoryBirdCleanB09.png",
            derivativeSha256: "8cc0517986fce60d0ccd45918d08d01dbc145fa98805905d1a407da86c7faceb",
            derivativeChanges: "Copied original generated PNG unchanged into the app asset catalog.",
            licenseAllowsReuse: true,
            noThirdPartyRestrictionFound: true,
            noLogoOrEndorsementRisk: true,
            noPeopleOrPrivacyRisk: true,
            childCardLegibilityChecked: true
        ),
        MemoryImageAssetProvenance(
            assetName: "MemoryBirdCleanB10",
            cardId: "bird-b10",
            sourceName: "Built-in ImageGen storybook artwork",
            sourceUrl: "",
            creator: "OpenAI ImageGen for ganesh47/mather",
            creditLine: "Storybook artwork generated for Mather Memory Adventures.",
            license: "Project-owned generated artwork; no third-party source material",
            licenseUrl: "",
            retrievedAt: "2026-10-02",
            originalFileName: "exec-ed139892-13e0-448d-b6f8-46e9365e3cff.png",
            originalSha256: "a65f03c59920a02941e3302be5692ea0be245c8c7b77cc443b2283f1724adf37",
            derivativeFileName: "MemoryBirdCleanB10.png",
            derivativeSha256: "a65f03c59920a02941e3302be5692ea0be245c8c7b77cc443b2283f1724adf37",
            derivativeChanges: "Copied original generated PNG unchanged into the app asset catalog.",
            licenseAllowsReuse: true,
            noThirdPartyRestrictionFound: true,
            noLogoOrEndorsementRisk: true,
            noPeopleOrPrivacyRisk: true,
            childCardLegibilityChecked: true
        ),
        MemoryImageAssetProvenance(
            assetName: "MemoryBirdCleanB12",
            cardId: "bird-b12",
            sourceName: "Built-in ImageGen storybook artwork",
            sourceUrl: "",
            creator: "OpenAI ImageGen for ganesh47/mather",
            creditLine: "Storybook artwork generated for Mather Memory Adventures.",
            license: "Project-owned generated artwork; no third-party source material",
            licenseUrl: "",
            retrievedAt: "2026-10-02",
            originalFileName: "exec-6a837f29-f26c-4b6c-b541-975aa06aea4c.png",
            originalSha256: "62ce10c4e7c1815a656560da2f6b053959b7fff3066d658c647e83841be497ee",
            derivativeFileName: "MemoryBirdCleanB12.png",
            derivativeSha256: "62ce10c4e7c1815a656560da2f6b053959b7fff3066d658c647e83841be497ee",
            derivativeChanges: "Copied original generated PNG unchanged into the app asset catalog.",
            licenseAllowsReuse: true,
            noThirdPartyRestrictionFound: true,
            noLogoOrEndorsementRisk: true,
            noPeopleOrPrivacyRisk: true,
            childCardLegibilityChecked: true
        ),
        MemoryImageAssetProvenance(
            assetName: "MemoryBirdCleanB13",
            cardId: "bird-b13",
            sourceName: "Built-in ImageGen storybook artwork",
            sourceUrl: "",
            creator: "OpenAI ImageGen for ganesh47/mather",
            creditLine: "Storybook artwork generated for Mather Memory Adventures.",
            license: "Project-owned generated artwork; no third-party source material",
            licenseUrl: "",
            retrievedAt: "2026-10-02",
            originalFileName: "exec-a51fb976-9313-4332-ad6a-d416b7409eb1.png",
            originalSha256: "3d39893be279e9a2c608f01de00be5e6f7c5d53ae3011ab4643f4d939cd79a9e",
            derivativeFileName: "MemoryBirdCleanB13.png",
            derivativeSha256: "3d39893be279e9a2c608f01de00be5e6f7c5d53ae3011ab4643f4d939cd79a9e",
            derivativeChanges: "Copied original generated PNG unchanged into the app asset catalog.",
            licenseAllowsReuse: true,
            noThirdPartyRestrictionFound: true,
            noLogoOrEndorsementRisk: true,
            noPeopleOrPrivacyRisk: true,
            childCardLegibilityChecked: true
        ),
        MemoryImageAssetProvenance(
            assetName: "MemoryBirdCleanB14",
            cardId: "bird-b14",
            sourceName: "Built-in ImageGen storybook artwork",
            sourceUrl: "",
            creator: "OpenAI ImageGen for ganesh47/mather",
            creditLine: "Storybook artwork generated for Mather Memory Adventures.",
            license: "Project-owned generated artwork; no third-party source material",
            licenseUrl: "",
            retrievedAt: "2026-10-02",
            originalFileName: "exec-c91987c2-3946-4c9a-820d-8c4537c926c3.png",
            originalSha256: "52d7085881ebbbae2a8a06cd3421b42c53b65599e777846f0fbdc3ce73651260",
            derivativeFileName: "MemoryBirdCleanB14.png",
            derivativeSha256: "52d7085881ebbbae2a8a06cd3421b42c53b65599e777846f0fbdc3ce73651260",
            derivativeChanges: "Copied original generated PNG unchanged into the app asset catalog.",
            licenseAllowsReuse: true,
            noThirdPartyRestrictionFound: true,
            noLogoOrEndorsementRisk: true,
            noPeopleOrPrivacyRisk: true,
            childCardLegibilityChecked: true
        ),
        MemoryImageAssetProvenance(
            assetName: "MemoryBirdCleanB15",
            cardId: "bird-b15",
            sourceName: "Built-in ImageGen storybook artwork",
            sourceUrl: "",
            creator: "OpenAI ImageGen for ganesh47/mather",
            creditLine: "Storybook artwork generated for Mather Memory Adventures.",
            license: "Project-owned generated artwork; no third-party source material",
            licenseUrl: "",
            retrievedAt: "2026-10-02",
            originalFileName: "exec-4119a2a2-1d54-4aad-8290-e7e336f266cc.png",
            originalSha256: "ad955ec16c56131caa8287be10f4333259ed4b3177ca9f9bf145f1cb6e15d018",
            derivativeFileName: "MemoryBirdCleanB15.png",
            derivativeSha256: "ad955ec16c56131caa8287be10f4333259ed4b3177ca9f9bf145f1cb6e15d018",
            derivativeChanges: "Copied original generated PNG unchanged into the app asset catalog.",
            licenseAllowsReuse: true,
            noThirdPartyRestrictionFound: true,
            noLogoOrEndorsementRisk: true,
            noPeopleOrPrivacyRisk: true,
            childCardLegibilityChecked: true
        ),
        MemoryImageAssetProvenance(
            assetName: "MemoryBirdCleanB17",
            cardId: "bird-b17",
            sourceName: "Built-in ImageGen storybook artwork",
            sourceUrl: "",
            creator: "OpenAI ImageGen for ganesh47/mather",
            creditLine: "Storybook artwork generated for Mather Memory Adventures.",
            license: "Project-owned generated artwork; no third-party source material",
            licenseUrl: "",
            retrievedAt: "2026-10-02",
            originalFileName: "exec-8c23c096-30a9-4a2b-a55f-12c7c19988e3.png",
            originalSha256: "1d631ff92a7271e15933ae87654ac0ee4b1c03b2b861920ff5058ac84cde4279",
            derivativeFileName: "MemoryBirdCleanB17.png",
            derivativeSha256: "1d631ff92a7271e15933ae87654ac0ee4b1c03b2b861920ff5058ac84cde4279",
            derivativeChanges: "Copied original generated PNG unchanged into the app asset catalog.",
            licenseAllowsReuse: true,
            noThirdPartyRestrictionFound: true,
            noLogoOrEndorsementRisk: true,
            noPeopleOrPrivacyRisk: true,
            childCardLegibilityChecked: true
        ),
        MemoryImageAssetProvenance(
            assetName: "MemoryBirdCleanB18",
            cardId: "bird-b18",
            sourceName: "Built-in ImageGen storybook artwork",
            sourceUrl: "",
            creator: "OpenAI ImageGen for ganesh47/mather",
            creditLine: "Storybook artwork generated for Mather Memory Adventures.",
            license: "Project-owned generated artwork; no third-party source material",
            licenseUrl: "",
            retrievedAt: "2026-10-02",
            originalFileName: "exec-de616f47-a1d7-4c85-b0bf-7bfc2893f40e.png",
            originalSha256: "78574148ad70ca3b321dbf6b9e81ed1e8fb6858ad2c0b5d968ab7fb697a2380c",
            derivativeFileName: "MemoryBirdCleanB18.png",
            derivativeSha256: "78574148ad70ca3b321dbf6b9e81ed1e8fb6858ad2c0b5d968ab7fb697a2380c",
            derivativeChanges: "Copied original generated PNG unchanged into the app asset catalog.",
            licenseAllowsReuse: true,
            noThirdPartyRestrictionFound: true,
            noLogoOrEndorsementRisk: true,
            noPeopleOrPrivacyRisk: true,
            childCardLegibilityChecked: true
        ),
        MemoryImageAssetProvenance(
            assetName: "MemoryFishAngelfishStorybook",
            cardId: "fish-angelfish",
            sourceName: "Built-in ImageGen storybook artwork",
            sourceUrl: "",
            creator: "OpenAI ImageGen for ganesh47/mather",
            creditLine: "Storybook artwork generated for Mather Memory Adventures.",
            license: "Project-owned generated artwork; no third-party source material",
            licenseUrl: "",
            retrievedAt: "2026-10-02",
            originalFileName: "exec-b39d272d-bd46-4f3e-9af4-27339a3c1fc2.png",
            originalSha256: "cfb6616b2f9675e42457162166788bd21cf011e319988530ede4e26e2362dfde",
            derivativeFileName: "MemoryFishAngelfishStorybook.png",
            derivativeSha256: "cfb6616b2f9675e42457162166788bd21cf011e319988530ede4e26e2362dfde",
            derivativeChanges: "Copied original generated PNG unchanged into the app asset catalog.",
            licenseAllowsReuse: true,
            noThirdPartyRestrictionFound: true,
            noLogoOrEndorsementRisk: true,
            noPeopleOrPrivacyRisk: true,
            childCardLegibilityChecked: true
        ),
        MemoryImageAssetProvenance(
            assetName: "MemoryFishBettaStorybook",
            cardId: "fish-betta",
            sourceName: "Built-in ImageGen storybook artwork",
            sourceUrl: "",
            creator: "OpenAI ImageGen for ganesh47/mather",
            creditLine: "Storybook artwork generated for Mather Memory Adventures.",
            license: "Project-owned generated artwork; no third-party source material",
            licenseUrl: "",
            retrievedAt: "2026-10-02",
            originalFileName: "exec-ed0bdbe7-f507-41c5-a7ea-5f1c8fcc4058.png",
            originalSha256: "cf88eec002f9e9864b459722f36955067d4591323719e4d376547dcb1687de0e",
            derivativeFileName: "MemoryFishBettaStorybook.png",
            derivativeSha256: "cf88eec002f9e9864b459722f36955067d4591323719e4d376547dcb1687de0e",
            derivativeChanges: "Copied original generated PNG unchanged into the app asset catalog.",
            licenseAllowsReuse: true,
            noThirdPartyRestrictionFound: true,
            noLogoOrEndorsementRisk: true,
            noPeopleOrPrivacyRisk: true,
            childCardLegibilityChecked: true
        ),
        MemoryImageAssetProvenance(
            assetName: "MemoryFishCatfishStorybook",
            cardId: "fish-catfish",
            sourceName: "Built-in ImageGen storybook artwork",
            sourceUrl: "",
            creator: "OpenAI ImageGen for ganesh47/mather",
            creditLine: "Storybook artwork generated for Mather Memory Adventures.",
            license: "Project-owned generated artwork; no third-party source material",
            licenseUrl: "",
            retrievedAt: "2026-10-02",
            originalFileName: "exec-5ff46900-f886-4f70-b42f-42c52e6bd9de.png",
            originalSha256: "84bd6d82a019400c000d6118e1a4b08cb0094846369fb938d422da260b14c089",
            derivativeFileName: "MemoryFishCatfishStorybook.png",
            derivativeSha256: "84bd6d82a019400c000d6118e1a4b08cb0094846369fb938d422da260b14c089",
            derivativeChanges: "Copied original generated PNG unchanged into the app asset catalog.",
            licenseAllowsReuse: true,
            noThirdPartyRestrictionFound: true,
            noLogoOrEndorsementRisk: true,
            noPeopleOrPrivacyRisk: true,
            childCardLegibilityChecked: true
        ),
        MemoryImageAssetProvenance(
            assetName: "MemoryFishClownfishStorybook",
            cardId: "fish-clownfish",
            sourceName: "Built-in ImageGen storybook artwork",
            sourceUrl: "",
            creator: "OpenAI ImageGen for ganesh47/mather",
            creditLine: "Storybook artwork generated for Mather Memory Adventures.",
            license: "Project-owned generated artwork; no third-party source material",
            licenseUrl: "",
            retrievedAt: "2026-10-02",
            originalFileName: "exec-80692ba4-f187-4de8-8822-4f394c22ad11.png",
            originalSha256: "2c1a4fb546df0bb96aa740fb9c9adb0db491722cc42ec9f85ceb3763b1aeeb84",
            derivativeFileName: "MemoryFishClownfishStorybook.png",
            derivativeSha256: "2c1a4fb546df0bb96aa740fb9c9adb0db491722cc42ec9f85ceb3763b1aeeb84",
            derivativeChanges: "Copied original generated PNG unchanged into the app asset catalog.",
            licenseAllowsReuse: true,
            noThirdPartyRestrictionFound: true,
            noLogoOrEndorsementRisk: true,
            noPeopleOrPrivacyRisk: true,
            childCardLegibilityChecked: true
        ),
        MemoryImageAssetProvenance(
            assetName: "MemoryFishGoldfishStorybook",
            cardId: "fish-goldfish",
            sourceName: "Built-in ImageGen storybook artwork",
            sourceUrl: "",
            creator: "OpenAI ImageGen for ganesh47/mather",
            creditLine: "Storybook artwork generated for Mather Memory Adventures.",
            license: "Project-owned generated artwork; no third-party source material",
            licenseUrl: "",
            retrievedAt: "2026-10-02",
            originalFileName: "exec-861e5543-bd88-4541-a6b6-ae7bee692e9f.png",
            originalSha256: "6f4a1408cd8edf21c544ec89447f99ed996683ad083f0f4e172811e55b22cf88",
            derivativeFileName: "MemoryFishGoldfishStorybook.png",
            derivativeSha256: "6f4a1408cd8edf21c544ec89447f99ed996683ad083f0f4e172811e55b22cf88",
            derivativeChanges: "Copied original generated PNG unchanged into the app asset catalog.",
            licenseAllowsReuse: true,
            noThirdPartyRestrictionFound: true,
            noLogoOrEndorsementRisk: true,
            noPeopleOrPrivacyRisk: true,
            childCardLegibilityChecked: true
        ),
        MemoryImageAssetProvenance(
            assetName: "MemoryFishSeahorseStorybook",
            cardId: "fish-seahorse",
            sourceName: "Built-in ImageGen storybook artwork",
            sourceUrl: "",
            creator: "OpenAI ImageGen for ganesh47/mather",
            creditLine: "Storybook artwork generated for Mather Memory Adventures.",
            license: "Project-owned generated artwork; no third-party source material",
            licenseUrl: "",
            retrievedAt: "2026-10-02",
            originalFileName: "exec-d2875add-644f-454f-b2fc-42f8c0f49d60.png",
            originalSha256: "9bf30e35a370e5dae349075a46ed44cdb3dc9b94dca6cc9ab95bc655f0af1da0",
            derivativeFileName: "MemoryFishSeahorseStorybook.png",
            derivativeSha256: "9bf30e35a370e5dae349075a46ed44cdb3dc9b94dca6cc9ab95bc655f0af1da0",
            derivativeChanges: "Copied original generated PNG unchanged into the app asset catalog.",
            licenseAllowsReuse: true,
            noThirdPartyRestrictionFound: true,
            noLogoOrEndorsementRisk: true,
            noPeopleOrPrivacyRisk: true,
            childCardLegibilityChecked: true
        ),
        MemoryImageAssetProvenance(
            assetName: "MemoryFishSwordtailStorybook",
            cardId: "fish-swordtail",
            sourceName: "Built-in ImageGen storybook artwork",
            sourceUrl: "",
            creator: "OpenAI ImageGen for ganesh47/mather",
            creditLine: "Storybook artwork generated for Mather Memory Adventures.",
            license: "Project-owned generated artwork; no third-party source material",
            licenseUrl: "",
            retrievedAt: "2026-10-02",
            originalFileName: "exec-50e7aedd-6731-4446-bdd5-ae945c7774b9.png",
            originalSha256: "381af15061cf090d0b8aac4284b3153361743697446c7a4c689b337ed7f3b48a",
            derivativeFileName: "MemoryFishSwordtailStorybook.png",
            derivativeSha256: "381af15061cf090d0b8aac4284b3153361743697446c7a4c689b337ed7f3b48a",
            derivativeChanges: "Copied original generated PNG unchanged into the app asset catalog.",
            licenseAllowsReuse: true,
            noThirdPartyRestrictionFound: true,
            noLogoOrEndorsementRisk: true,
            noPeopleOrPrivacyRisk: true,
            childCardLegibilityChecked: true
        ),
        MemoryImageAssetProvenance(
            assetName: "MemoryFishTunaStorybook",
            cardId: "fish-tuna",
            sourceName: "Built-in ImageGen storybook artwork",
            sourceUrl: "",
            creator: "OpenAI ImageGen for ganesh47/mather",
            creditLine: "Storybook artwork generated for Mather Memory Adventures.",
            license: "Project-owned generated artwork; no third-party source material",
            licenseUrl: "",
            retrievedAt: "2026-10-02",
            originalFileName: "exec-deed6afc-f45f-4193-a9cf-dc18596dae44.png",
            originalSha256: "357c1e03abf02899fb91bb3352a34ac9a33b4e6fa1d77b029f40eb16c2b9fb25",
            derivativeFileName: "MemoryFishTunaStorybook.png",
            derivativeSha256: "357c1e03abf02899fb91bb3352a34ac9a33b4e6fa1d77b029f40eb16c2b9fb25",
            derivativeChanges: "Copied original generated PNG unchanged into the app asset catalog.",
            licenseAllowsReuse: true,
            noThirdPartyRestrictionFound: true,
            noLogoOrEndorsementRisk: true,
            noPeopleOrPrivacyRisk: true,
            childCardLegibilityChecked: true
        ),
        MemoryImageAssetProvenance(
            assetName: "MemoryFruitBanana",
            cardId: "fruit-banana",
            sourceName: "Built-in ImageGen storybook artwork",
            sourceUrl: "",
            creator: "OpenAI ImageGen for ganesh47/mather",
            creditLine: "Storybook artwork generated for Mather Memory Adventures.",
            license: "Project-owned generated artwork; no third-party source material",
            licenseUrl: "",
            retrievedAt: "2026-10-02",
            originalFileName: "exec-d364d296-b1c4-4c30-96b7-e66cb6c9b661.png",
            originalSha256: "3d7a6b84425b60b5d2e358c8779f2af8dec7f5a3603ba67bdb087cb6884359df",
            derivativeFileName: "MemoryFruitBanana.png",
            derivativeSha256: "3d7a6b84425b60b5d2e358c8779f2af8dec7f5a3603ba67bdb087cb6884359df",
            derivativeChanges: "Copied original generated PNG unchanged into the app asset catalog.",
            licenseAllowsReuse: true,
            noThirdPartyRestrictionFound: true,
            noLogoOrEndorsementRisk: true,
            noPeopleOrPrivacyRisk: true,
            childCardLegibilityChecked: true
        ),
        MemoryImageAssetProvenance(
            assetName: "MemoryFruitGrape",
            cardId: "fruit-grape",
            sourceName: "Built-in ImageGen storybook artwork",
            sourceUrl: "",
            creator: "OpenAI ImageGen for ganesh47/mather",
            creditLine: "Storybook artwork generated for Mather Memory Adventures.",
            license: "Project-owned generated artwork; no third-party source material",
            licenseUrl: "",
            retrievedAt: "2026-10-02",
            originalFileName: "exec-5146eae1-e771-40f1-b0cc-ab5e576001eb.png",
            originalSha256: "be587dd0d69c2250b71e1d156699e19019edbf0ec2801716c212914f34f8b6b9",
            derivativeFileName: "MemoryFruitGrape.png",
            derivativeSha256: "be587dd0d69c2250b71e1d156699e19019edbf0ec2801716c212914f34f8b6b9",
            derivativeChanges: "Copied original generated PNG unchanged into the app asset catalog.",
            licenseAllowsReuse: true,
            noThirdPartyRestrictionFound: true,
            noLogoOrEndorsementRisk: true,
            noPeopleOrPrivacyRisk: true,
            childCardLegibilityChecked: true
        ),
        MemoryImageAssetProvenance(
            assetName: "MemoryFruitMango",
            cardId: "fruit-mango",
            sourceName: "Built-in ImageGen storybook artwork",
            sourceUrl: "",
            creator: "OpenAI ImageGen for ganesh47/mather",
            creditLine: "Storybook artwork generated for Mather Memory Adventures.",
            license: "Project-owned generated artwork; no third-party source material",
            licenseUrl: "",
            retrievedAt: "2026-10-02",
            originalFileName: "exec-7267ac4a-2344-48fd-9d96-be5230550049.png",
            originalSha256: "b060feb0d1bf317690978a399c92664ecadf9813de533533d9f3f83e009a473e",
            derivativeFileName: "MemoryFruitMango.png",
            derivativeSha256: "b060feb0d1bf317690978a399c92664ecadf9813de533533d9f3f83e009a473e",
            derivativeChanges: "Copied original generated PNG unchanged into the app asset catalog.",
            licenseAllowsReuse: true,
            noThirdPartyRestrictionFound: true,
            noLogoOrEndorsementRisk: true,
            noPeopleOrPrivacyRisk: true,
            childCardLegibilityChecked: true
        ),
        MemoryImageAssetProvenance(
            assetName: "MemoryFruitOrange",
            cardId: "fruit-orange",
            sourceName: "Built-in ImageGen storybook artwork",
            sourceUrl: "",
            creator: "OpenAI ImageGen for ganesh47/mather",
            creditLine: "Storybook artwork generated for Mather Memory Adventures.",
            license: "Project-owned generated artwork; no third-party source material",
            licenseUrl: "",
            retrievedAt: "2026-10-02",
            originalFileName: "exec-ca23ed1c-ab41-4e95-8e63-a709e49a3725.png",
            originalSha256: "c4531d754e7f07fb7c70289cd5057d4cb46243b273a704c148d3deef7c1d593c",
            derivativeFileName: "MemoryFruitOrange.png",
            derivativeSha256: "c4531d754e7f07fb7c70289cd5057d4cb46243b273a704c148d3deef7c1d593c",
            derivativeChanges: "Copied original generated PNG unchanged into the app asset catalog.",
            licenseAllowsReuse: true,
            noThirdPartyRestrictionFound: true,
            noLogoOrEndorsementRisk: true,
            noPeopleOrPrivacyRisk: true,
            childCardLegibilityChecked: true
        ),
        MemoryImageAssetProvenance(
            assetName: "MemoryFruitPineapple",
            cardId: "fruit-pineapple",
            sourceName: "Built-in ImageGen storybook artwork",
            sourceUrl: "",
            creator: "OpenAI ImageGen for ganesh47/mather",
            creditLine: "Storybook artwork generated for Mather Memory Adventures.",
            license: "Project-owned generated artwork; no third-party source material",
            licenseUrl: "",
            retrievedAt: "2026-10-02",
            originalFileName: "exec-748ec912-2273-4378-ac4b-e69ad8e5356b.png",
            originalSha256: "22d2a2773e86649fa108d9284e54c7f8744d46e1ddcf463f67551444d9c5e06b",
            derivativeFileName: "MemoryFruitPineapple.png",
            derivativeSha256: "22d2a2773e86649fa108d9284e54c7f8744d46e1ddcf463f67551444d9c5e06b",
            derivativeChanges: "Copied original generated PNG unchanged into the app asset catalog.",
            licenseAllowsReuse: true,
            noThirdPartyRestrictionFound: true,
            noLogoOrEndorsementRisk: true,
            noPeopleOrPrivacyRisk: true,
            childCardLegibilityChecked: true
        ),
        MemoryImageAssetProvenance(
            assetName: "MemoryFruitStrawberry",
            cardId: "fruit-strawberry",
            sourceName: "Built-in ImageGen storybook artwork",
            sourceUrl: "",
            creator: "OpenAI ImageGen for ganesh47/mather",
            creditLine: "Storybook artwork generated for Mather Memory Adventures.",
            license: "Project-owned generated artwork; no third-party source material",
            licenseUrl: "",
            retrievedAt: "2026-10-02",
            originalFileName: "exec-5048d6b7-9c0c-4c15-87f4-4bd1748a5af5.png",
            originalSha256: "52baab7fe02c50c2c0749097f13bbced3e636a6866efb0b4897e43a469e552ee",
            derivativeFileName: "MemoryFruitStrawberry.png",
            derivativeSha256: "52baab7fe02c50c2c0749097f13bbced3e636a6866efb0b4897e43a469e552ee",
            derivativeChanges: "Copied original generated PNG unchanged into the app asset catalog.",
            licenseAllowsReuse: true,
            noThirdPartyRestrictionFound: true,
            noLogoOrEndorsementRisk: true,
            noPeopleOrPrivacyRisk: true,
            childCardLegibilityChecked: true
        ),
        MemoryImageAssetProvenance(
            assetName: "MemoryFruitWatermelon",
            cardId: "fruit-watermelon",
            sourceName: "Built-in ImageGen storybook artwork",
            sourceUrl: "",
            creator: "OpenAI ImageGen for ganesh47/mather",
            creditLine: "Storybook artwork generated for Mather Memory Adventures.",
            license: "Project-owned generated artwork; no third-party source material",
            licenseUrl: "",
            retrievedAt: "2026-10-02",
            originalFileName: "exec-24d10758-7e71-444f-8a6f-a393b19ff3bd.png",
            originalSha256: "877fa1d9264b1adb759e8c200804eb0566b3ed7ca23f4dbad66cdf6d9053cb9f",
            derivativeFileName: "MemoryFruitWatermelon.png",
            derivativeSha256: "877fa1d9264b1adb759e8c200804eb0566b3ed7ca23f4dbad66cdf6d9053cb9f",
            derivativeChanges: "Copied original generated PNG unchanged into the app asset catalog.",
            licenseAllowsReuse: true,
            noThirdPartyRestrictionFound: true,
            noLogoOrEndorsementRisk: true,
            noPeopleOrPrivacyRisk: true,
            childCardLegibilityChecked: true
        )
    ]
    // END GENERATED MEMORY ADVENTURE PROVENANCE

    private static let countryLearningAssetProvenance: [MemoryImageAssetProvenance] = [
        generatedCountryCurrencyProvenance(assetName: "MemoryCurrencyIndia", cardId: "country-flag-india", sha256: "57647dd883dd954e92bc8f8bd913785ea70b876a32cab96f32416c6866fd4106"),
        generatedCountryCurrencyProvenance(assetName: "MemoryCurrencyJapan", cardId: "country-flag-japan", sha256: "b2c455845aed399efb094d680c8aa1677b0bfb40cb111708dff197fe69385d38"),
        generatedCountryCurrencyProvenance(assetName: "MemoryCurrencyFrance", cardId: "country-flag-france", sha256: "5b4ed712647515a8fc16a999050627f75eff3dcc0913f8770a11c03adb2b17b6"),
        generatedCountryCurrencyProvenance(assetName: "MemoryCurrencyEgypt", cardId: "country-flag-egypt", sha256: "d1f63820ad4b3ebbc26733c9e9bbbf33a610e9b61b14bfe40020ccb83a49795e"),
        generatedCountryCurrencyProvenance(assetName: "MemoryCurrencyBrazil", cardId: "country-flag-brazil", sha256: "dd17cdf8f84d1d5857c8b02298060ae3f7bd0654349ce7267af81dc040ec2b99"),
        generatedCountryCurrencyProvenance(assetName: "MemoryCurrencyAustralia", cardId: "country-flag-australia", sha256: "664db5d2afe22bf56036838c228bb26a128fba2d34ee7fe5fe02188638b4d810"),
        generatedCountryCurrencyProvenance(assetName: "MemoryCurrencyCanada", cardId: "country-flag-canada", sha256: "641a1f7fdea182a62c280d70ebfa3e65dcec4f9ce6c9a1579211047e10e0653f"),
        generatedCountryCurrencyProvenance(assetName: "MemoryCurrencyKenya", cardId: "country-flag-kenya", sha256: "d6ec919da4033391ef2423810c4d45820ea35a17a016ca8c4be862f02789607f"),
        generatedCountryCurrencyProvenance(assetName: "MemoryCurrencyUnitedStates", cardId: "country-flag-united-states", sha256: "99637fe4464553aa4d7d4e73ae96734be316c94681e36d97eff52944d2c1dd34"),
        generatedCountryCurrencyProvenance(assetName: "MemoryCurrencyUnitedKingdom", cardId: "country-flag-united-kingdom", sha256: "3488c917fe0b902d4a464ba760cbc2db2e58ffbe5bd833bc952e82a98a547fb2"),
        generatedCountryCurrencyProvenance(assetName: "MemoryCurrencyChina", cardId: "country-flag-china", sha256: "c5b6fb3a93271fad61aba30c472445c36f2ee4f213b0376b257763a18c8e1bb3"),
        generatedCountryCurrencyProvenance(assetName: "MemoryCurrencyGermany", cardId: "country-flag-germany", sha256: "ba9d05aeec0a28e9537308a3bdb800e52aafd89f2f3c7a89c513d21e28894a4f"),
        generatedCountryCurrencyProvenance(assetName: "MemoryCurrencyMexico", cardId: "country-flag-mexico", sha256: "1c727db0bd233355a1a7693a17ab7115a49e1f0c9afbd3f015a8790b334e5c79"),
        generatedCountryCurrencyProvenance(assetName: "MemoryCurrencySouthAfrica", cardId: "country-flag-south-africa", sha256: "7986f932277b2c95400dc864af8b6a621b9c9d7f25e7e433e6e2060e03a96f08"),
        generatedCountryCurrencyProvenance(assetName: "MemoryCurrencyItaly", cardId: "country-flag-italy", sha256: "caf9762b23b03abb60fbdb7a9157051a7b21a0b823dd853b287459309740de50"),
        generatedCountryCurrencyProvenance(assetName: "MemoryCurrencySaudiArabia", cardId: "country-flag-saudi-arabia", sha256: "ec96fb8a6ed8bc9dd4831bd76b6540d849aa96eedd214fde10cca1164b86f230"),
        generatedCountryMonumentProvenance(assetName: "MemoryMonumentIndia", cardId: "country-flag-india", originalSha256: "0a9c65cf9c2a09647151062e22b14557829dfa68c0dbb585ffb9600cd6a05efd", derivativeSha256: "f24674b66b8662c6d19969ea497fa79565b17e99e8bd42d6615309d479a2fa4f"),
        generatedCountryMonumentProvenance(assetName: "MemoryMonumentJapan", cardId: "country-flag-japan", originalSha256: "4daef6779074dd1b7abec08ca03028458d4f34188f22138aa8d20e96ccbf69aa", derivativeSha256: "8a202c8356a98e66a0bc8d683d68d2cf1eed14d4c37487185f8034e7530d98a6"),
        generatedCountryMonumentProvenance(assetName: "MemoryMonumentFrance", cardId: "country-flag-france", originalSha256: "e0ca89da31b9e289ed286b73fe2284ca55ace30a450c2d45e432586b79a3e113", derivativeSha256: "a5456fe7bb361a373f24ca821b996214b05a330ab0cdec4c1b349c2383c4e4d0"),
        generatedCountryMonumentProvenance(assetName: "MemoryMonumentEgypt", cardId: "country-flag-egypt", originalSha256: "b3d1cab88b912b5c74790cc1db2f6fed728ae77458e10736558b76ded8712f8e", derivativeSha256: "ef8a5845a7db747a38aa97c0649e2866b67c51bc29c5a6f289823023851023dc"),
        generatedCountryMonumentProvenance(assetName: "MemoryMonumentBrazil", cardId: "country-flag-brazil", originalSha256: "845a857bdce9e0779be878016a35645deb69ce9a020b6ea9a9174e0f2aa56285", derivativeSha256: "244724a36a95c1e72fb18686ccb5671da4c80cc141c2f5951257682c0084e7ce"),
        generatedCountryMonumentProvenance(assetName: "MemoryMonumentAustralia", cardId: "country-flag-australia", originalSha256: "77a21cc26c16ef9eec9dfe34ac91bbeb624b76b660393fc2ca91f1923443915a", derivativeSha256: "7e83aa825f2216b0d9eec764b241a5c3e4b3146477b5a16796cf63399086d18e"),
        generatedCountryMonumentProvenance(assetName: "MemoryMonumentCanada", cardId: "country-flag-canada", originalSha256: "c6f00b579393de91cca8984337285bd4c7b71738e54cf3702cef01351f175059", derivativeSha256: "d6b0f78ed0667aaae2eb8e7c79665f71caa3474a6d0e8abee16b607bba8c0715"),
        generatedCountryMonumentProvenance(assetName: "MemoryMonumentKenya", cardId: "country-flag-kenya", originalSha256: "b3e5ec104ca93d2132fd3bcc759ab5128a1c97de6d0495d6f82ee6d71102660f", derivativeSha256: "a2b91ab657332d683e60bf1d1633f7e09f902c4cc43e1f067de2c7578f21e09d"),
        generatedCountryMonumentProvenance(assetName: "MemoryMonumentUnitedStates", cardId: "country-flag-united-states", originalSha256: "ff59f032ccda9ac0a1cfc834ac693e24d85e3f438277821cbef8ebbd13e4b69b", derivativeSha256: "8772aaf09f90152be465e7e4ce92f6c18ef24ffea7d64ea38b3b141b7a92ca66"),
        generatedCountryMonumentProvenance(assetName: "MemoryMonumentUnitedKingdom", cardId: "country-flag-united-kingdom", originalSha256: "e1c2446c9bd26e5f2962c8950b5b11eea2342768cdd6fb3f02f158097bfea813", derivativeSha256: "c72e977354a4d649fe4b207879b9556d672c07a43e2860674940a54c4ecc2996"),
        generatedCountryMonumentProvenance(assetName: "MemoryMonumentChina", cardId: "country-flag-china", originalSha256: "6189da1ffda315b824052cadce0e0798454a7d809b097fddb7c69f17bc60d518", derivativeSha256: "1f9d69cd024b6b468b73844412a3f8ffdd94a934e893f08a1c3d6e7df415741c"),
        generatedCountryMonumentProvenance(assetName: "MemoryMonumentGermany", cardId: "country-flag-germany", originalSha256: "1a58b18d1cfd7a5708d3f90e5312aee9a0e668ee3707c3ded2700577fda99e40", derivativeSha256: "878c4e626b13e61aa302324cdb654cd8e2d6c894276581889982eb2b7c25f7ec"),
        generatedCountryMonumentProvenance(assetName: "MemoryMonumentMexico", cardId: "country-flag-mexico", originalSha256: "7ce0cf3765db78147d313e1a0c7b994b6ba2000e0bbe09321d2beb1ac160f7b7", derivativeSha256: "cbf55ef021bd71987a4f3de5c4666613fcad055b1005197875aaae1e08c3c072"),
        generatedCountryMonumentProvenance(assetName: "MemoryMonumentSouthAfrica", cardId: "country-flag-south-africa", originalSha256: "1ef5fabd10905080388a3996cad8f739c24cce6d61b9d51122ea4a5b473f879b", derivativeSha256: "a15ccd95081e50bd210a68f4dc070387ec279e533b0e803d606db2b66451c669"),
        generatedCountryMonumentProvenance(assetName: "MemoryMonumentItaly", cardId: "country-flag-italy", originalSha256: "b7668db9d0a760f310b137f2daf5d630d9595bd3a637b1f47d801e14d7c10a03", derivativeSha256: "5a3c049b35a6db22bc7264103c7e710fe65568f51029010e1279fc42d7560ade"),
        generatedCountryMonumentProvenance(assetName: "MemoryMonumentSaudiArabia", cardId: "country-flag-saudi-arabia", originalSha256: "4b7a51bc36b7298ac80ea664235e1f578cc38d6ded817921dda89c3c2646be7f", derivativeSha256: "49b7fe697baffb87a4ab6f62cc7a8449273e6b57087347de49a3404847e7cb29")
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

    private static func nasaPlanetImageProvenance(
        assetName: String,
        cardId: String,
        sourceID: String,
        sourceTitle: String,
        sourceUrl: String,
        creator: String,
        originalFileName: String,
        originalSha256: String,
        derivativeSha256: String,
        processingNote: String
    ) -> MemoryImageAssetProvenance {
        MemoryImageAssetProvenance(
            assetName: assetName,
            cardId: cardId,
            sourceName: "NASA Science — \(sourceID)",
            sourceUrl: sourceUrl,
            creator: creator,
            creditLine: "\(sourceTitle) (\(sourceID)). Credit: \(creator)",
            license: "NASA content used for educational and informational purposes under the NASA Media Usage Guidelines",
            licenseUrl: "https://www.nasa.gov/nasa-brand-center/images-and-media/",
            retrievedAt: "2026-08-09",
            originalFileName: originalFileName,
            originalSha256: originalSha256,
            derivativeFileName: "\(assetName).png",
            derivativeSha256: derivativeSha256,
            derivativeChanges: "\(processingNote) Mather preserved aspect ratio, trimmed only empty black margin where needed, downscaled the NASA-hosted source, converted it to PNG, and padded the square canvas with black; no planetary content was added or removed.",
            licenseAllowsReuse: true,
            noThirdPartyRestrictionFound: true,
            noLogoOrEndorsementRisk: true,
            noPeopleOrPrivacyRisk: true,
            childCardLegibilityChecked: true
        )
    }

    private static func generatedIssue352ImageProvenance(assetName: String, cardId: String, sha256: String) -> MemoryImageAssetProvenance {
        MemoryImageAssetProvenance(
            assetName: assetName,
            cardId: cardId,
            sourceName: "Project-owned deterministic drawing",
            sourceUrl: "",
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
            sourceUrl: "",
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

    private static func generatedVehicleGalleryProvenance(
        assetName: String,
        cardId: String,
        originalSha256: String,
        derivativeSha256: String
    ) -> MemoryImageAssetProvenance {
        MemoryImageAssetProvenance(
            assetName: assetName,
            cardId: cardId,
            sourceName: "OpenAI built-in image generation",
            sourceUrl: "",
            creator: "OpenAI Codex for ganesh47/mather",
            creditLine: "Project-owned artwork created for the Mather vehicle Memory Gallery",
            license: "Project-owned; no third-party source material",
            licenseUrl: "",
            retrievedAt: "2026-08-08",
            originalFileName: "\(assetName)-chroma-source.png",
            originalSha256: originalSha256,
            derivativeFileName: "\(assetName).png",
            derivativeSha256: derivativeSha256,
            derivativeChanges: "Generated with OpenAI built-in image generation using a child-friendly educational vehicle prompt; chroma-key background removed locally and resized to a 512x512 transparent PNG.",
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
            sourceUrl: "",
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

    private static func generatedCountryCurrencyProvenance(assetName: String, cardId: String, sha256: String) -> MemoryImageAssetProvenance {
        MemoryImageAssetProvenance(
            assetName: assetName,
            cardId: cardId,
            sourceName: "Project-owned deterministic educational currency drawing",
            sourceUrl: "",
            creator: "OpenAI Codex for ganesh47/mather",
            creditLine: "Project-owned artwork created for the Mather country Memory Gallery",
            license: "Project-owned; no third-party source files or copied banknote artwork",
            licenseUrl: "",
            retrievedAt: "2026-08-09",
            originalFileName: "\(assetName).png",
            originalSha256: sha256,
            derivativeFileName: "\(assetName).png",
            derivativeSha256: sha256,
            derivativeChanges: "Generated directly as a playful 512x512 transparent learning card with scripts/generate_country_currency_assets.py. It contains no denomination, portrait, serial number, seal, or security feature and is not a banknote reproduction.",
            licenseAllowsReuse: true,
            noThirdPartyRestrictionFound: true,
            noLogoOrEndorsementRisk: true,
            noPeopleOrPrivacyRisk: true,
            childCardLegibilityChecked: true
        )
    }

    private static func generatedCountryMonumentProvenance(
        assetName: String,
        cardId: String,
        originalSha256: String,
        derivativeSha256: String
    ) -> MemoryImageAssetProvenance {
        MemoryImageAssetProvenance(
            assetName: assetName,
            cardId: cardId,
            sourceName: "OpenAI built-in image generation",
            sourceUrl: "",
            creator: "OpenAI Codex for ganesh47/mather",
            creditLine: "Project-owned artwork created for the Mather country Memory Gallery",
            license: "Project-owned; no third-party source material",
            licenseUrl: "",
            retrievedAt: "2026-08-09",
            originalFileName: "\(assetName)-generated-original.png",
            originalSha256: originalSha256,
            derivativeFileName: "\(assetName).png",
            derivativeSha256: derivativeSha256,
            derivativeChanges: "Generated with OpenAI built-in image generation using the shared child-friendly country-monument prompt family, then resized from 1254x1254 to a 512x512 PNG for the app asset catalog.",
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
            sourceUrl: "",
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

    /// Short, spoken discoveries invite observation and pretend play after a match.
    private static func discoveryFacts(for id: String, look: String? = nil, play: String? = nil) -> [MemoryFactCard] {
        let discoveries: [String: (String, String)] = [
            "cow": ("Find the cow’s broad nose and sturdy legs.", "Say a gentle moo. Can you make a slow cow walk with your fingers?"),
            "dog": ("Look at the dog’s ears, paws, and tail.", "Give a happy pretend bark and wag an imaginary tail."),
            "cat": ("Find the cat’s whiskers and pointed ears.", "Stretch like a cat, then tiptoe quietly in place."),
            "sheep": ("Look for the sheep’s fluffy fleece.", "Pretend your arms are fluffy wool. Say a gentle baa."),
            "pig": ("Find the pig’s round snout and curly tail.", "Make a funny oink, then draw a curly tail in the air."),
            "horse": ("Find the horse’s mane and long legs.", "Tap your fingers like hooves: clip-clop, clip-clop!"),
            "rabbit": ("Find the rabbit’s long ears and little tail.", "Make two rabbit ears with your fingers."),
            "duck": ("Look at the duck’s flat bill and webbed feet.", "Waddle your fingers and make a quiet quack."),
            "rooster": ("Find the rooster’s red comb and curved tail feathers.", "Stretch tall and greet the morning with a rooster call."),
            "goat": ("Look for the goat’s horns and little beard.", "Balance like a goat with both feet safely on the floor."),
            "turkey": ("Find the turkey’s fan-shaped tail.", "Spread your fingers like a feather fan and gobble softly."),
            "goldfish": ("Look for the goldfish’s flowing fins and tail.", "Wave one hand like a swishy fish tail."),
            "mouse": ("Find the mouse’s rounded ears and long tail.", "Scurry two fingers across your palm."),
            "frog": ("Look for the frog’s big back legs.", "Make a tiny frog hop with your hand."),
            "camel": ("Find the camel’s hump and long legs.", "Walk your fingers slowly across a pretend desert."),
            "llama": ("Find the llama’s long neck and tall ears.", "Stretch your neck tall and make a soft humming sound."),
            "donkey": ("Look at the donkey’s long ears.", "Make donkey ears with your hands and say hee-haw."),
            "ox": ("Find the ox’s horns and strong shoulders.", "Pretend to pull a tiny cart with your fingers."),
            "fish-clownfish": ("Find the white bands on its orange body.", "Wiggle your hand between pretend coral branches."),
            "fish-goldfish": ("Look at its golden body and flowing tail.", "Swish your hand gently from side to side."),
            "fish-betta": ("Look at its wide, flowing fins.", "Fan your fingers out like a betta’s fins."),
            "fish-angelfish": ("Find the tall fins and flat body.", "Hold your hand flat and glide it through pretend water."),
            "fish-catfish": ("Find the whisker-like feelers beside its mouth.", "Wiggle your fingers beside your cheeks like feelers."),
            "fish-swordtail": ("Find the long point on the bottom of its tail.", "Trace that tail shape in the air with one finger."),
            "fish-tuna": ("Look at its sleek body and forked tail.", "Make your hand a speedy fish swimming through the air."),
            "fish-seahorse": ("Find its curled tail and upright body.", "Curl one finger into a little seahorse tail.")
        ]
        let entry = discoveries[id]
        guard let observation = look ?? entry?.0, let activity = play ?? entry?.1 else { return [] }
        return [MemoryFactCard(title: "Look closely", value: observation), MemoryFactCard(title: "Try it", value: activity)]
    }

    private static func domesticAnimal(_ id: String, name: String, asset: String, habitat: String, colors: String, sound: String?, movement: String) -> MemoryAnimal {
        MemoryAnimal(
            id: id,
            name: name,
            picture: .asset(asset),
            metadata: MemoryCardMetadata(
                deck: .domesticAnimals,
                category: "animal",
                kind: "animal",
                habitat: habitat,
                colors: colors,
                movement: movement,
                sound: sound,
                factCards: [
                    MemoryFactCard(title: "Kind", value: "animal"),
                    MemoryFactCard(title: "Home", value: habitat),
                    MemoryFactCard(title: "Moves", value: movement),
                    MemoryFactCard(title: "Colors", value: colors)
                ] + (sound.map { [MemoryFactCard(title: "Sound", value: $0)] } ?? [])
                    + discoveryFacts(for: id)
            )
        )
    }

    private static func bird(_ id: String, name: String, asset: String, home: String, lifespan: String, weight: String, size: String, colors: String) -> MemoryAnimal {
        // A visual descriptor does not establish a species or its measurements.
        let descriptiveBirdIDs: Set<String> = ["bird-a11", "bird-a13", "bird-a15", "bird-a17", "bird-b04", "bird-b06", "bird-b09", "bird-b12"]
        let canonicalNames = [
            "bird-a05": "Blue-and-gold Macaw", "bird-b01": "Blue-and-gold Macaw",
            "bird-a03": "Yellow-crested Cockatoo", "bird-b07": "Yellow-crested Cockatoo",
            "bird-a11": "Black Cockatoo", "bird-b17": "Black Cockatoo",
            "bird-a18": "Ibis", "bird-b13": "Ibis",
            "bird-a15": "Songbird", "bird-b12": "Songbird"
        ]
        let storybook = id == "bird-b09"
        let descriptive = descriptiveBirdIDs.contains(id)
        let birdHome = storybook ? "A make-believe storybook world" : (descriptive ? "Varies by species" : home)
        let birdLifespan = storybook ? "Imaginary bird" : (descriptive ? "Varies by species" : lifespan)
        let birdWeight = storybook ? "Imaginary bird" : (descriptive ? "Varies by species" : weight)
        let birdSize = storybook ? "Imaginary bird" : (descriptive ? "Varies by species" : size)
        return MemoryAnimal(
            id: id,
            name: name,
            canonicalName: canonicalNames[id] ?? name,
            picture: .asset(asset),
            metadata: MemoryCardMetadata(
                deck: .birds,
                category: "bird",
                kind: storybook ? "storybook bird" : "bird",
                habitat: birdHome,
                lifespan: birdLifespan,
                weight: birdWeight,
                size: birdSize,
                colors: colors,
                movement: storybook ? "soars in our imagination" : "flies with wings",
                factCards: [
                    MemoryFactCard(title: "Name", value: name),
                    MemoryFactCard(title: "Home", value: birdHome),
                    MemoryFactCard(title: "Lifespan", value: birdLifespan),
                    MemoryFactCard(title: "Weight", value: birdWeight),
                    MemoryFactCard(title: "Size", value: birdSize),
                    MemoryFactCard(title: "Colors", value: colors)
                ] + (storybook ? [MemoryFactCard(title: "Story", value: "A make-believe bird from our storybook")] : [])
                    + discoveryFacts(for: id, look: "Spot its \(colors) feathers and the shape of its beak.", play: "Spread your arms like wings. Can you glide slowly?")
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
                sound: sound,
                factCards: [
                    MemoryFactCard(title: "Kind", value: "vehicle"),
                    MemoryFactCard(title: "Use", value: use),
                    MemoryFactCard(title: "Moves", value: movement),
                    MemoryFactCard(title: "Colors", value: colors)
                ] + (sound.map { [MemoryFactCard(title: "Sound", value: $0)] } ?? [])
                    + discoveryFacts(for: id, look: "Find the \(colors) colors and the parts that help it move.", play: "Make a pretend \(name.lowercased()) journey with your hands. Where will you go?")
            )
        )
    }

    private static func vehiclePart(_ id: String, name: String, asset: String, foundIn: String, job: String, howItWorks: String, remember: String) -> MemoryAnimal {
        MemoryAnimal(
            id: id,
            name: name,
            picture: .asset(asset),
            metadata: MemoryCardMetadata(
                deck: .vehicles,
                category: "vehicle part",
                kind: "vehicle part",
                habitat: foundIn,
                use: job,
                movement: howItWorks,
                factCards: [
                    MemoryFactCard(title: "Part", value: name),
                    MemoryFactCard(title: "Found In", value: foundIn),
                    MemoryFactCard(title: "Job", value: job),
                    MemoryFactCard(title: "How It Works", value: howItWorks),
                    MemoryFactCard(title: "Remember", value: remember)
                ]
            )
        )
    }

    private static func advancedVehicle(_ id: String, name: String, asset: String, group: String, job: String, keyPart: String, howItWorks: String, safetyFact: String) -> MemoryAnimal {
        MemoryAnimal(
            id: id,
            name: name,
            picture: .asset(asset),
            metadata: MemoryCardMetadata(
                deck: .vehicles,
                category: group,
                kind: group,
                use: job,
                movement: howItWorks,
                factCards: [
                    MemoryFactCard(title: "Vehicle", value: name),
                    MemoryFactCard(title: "Group", value: group),
                    MemoryFactCard(title: "Job", value: job),
                    MemoryFactCard(title: "Key Part", value: keyPart),
                    MemoryFactCard(title: "How It Works", value: howItWorks),
                    MemoryFactCard(title: "Safety Fact", value: safetyFact)
                ] + discoveryFacts(for: id, look: "Find the \(keyPart). It helps this machine do its job.", play: "Use your hands to show how this machine moves. Stay in your play space.")
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
                ] + discoveryFacts(for: id, look: "Look for \(colors) on this planet picture.", play: "Draw a big loop in the air, like a planet going around the Sun.")
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
                ] + discoveryFacts(for: id)
            )
        )
    }

    private static func fruit(_ id: String, name: String, asset: String, shape: String, colors: String, taste: String, smell: String, foundIn: String) -> MemoryAnimal {
        MemoryAnimal(
            id: id,
            name: name,
            picture: .asset(asset),
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
                ] + discoveryFacts(for: id, look: "Find its \(shape) shape and \(colors) colors.", play: "Make this fruit’s shape with your hands. What would you put in a pretend picnic?")
            )
        )
    }

    private static func countryCapital(
        _ id: String,
        country: String,
        capital: String,
        capitalDetail: String? = nil,
        continent: String,
        language: String,
        currency: String,
        currencySymbol: String,
        mapShape: String,
        monument: String,
        assetSuffix: String
    ) -> MemoryAnimal {
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
                    MemoryFactCard(title: "Capital", value: capitalDetail ?? capital),
                    MemoryFactCard(title: "Language", value: language),
                    MemoryFactCard(title: "Currency", value: currency),
                    MemoryFactCard(title: "Currency Symbol", value: currencySymbol),
                    MemoryFactCard(title: "Continent", value: continent),
                    MemoryFactCard(title: "Map Shape", value: mapShape),
                    MemoryFactCard(title: "Monument", value: monument)
                ]
            ),
            learningArtwork: countryLearningArtwork(assetSuffix: assetSuffix, monument: monument)
        )
    }

    private static func flagCountry(
        _ id: String,
        country: String,
        picture: MemoryPicture,
        isoAlpha2: String,
        continent: String,
        capital: String,
        language: String,
        currency: String,
        currencySymbol: String,
        colors: String,
        monument: String,
        assetSuffix: String
    ) -> MemoryAnimal {
        MemoryAnimal(
            id: id,
            name: country,
            canonicalName: country,
            picture: picture,
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
                    MemoryFactCard(title: "Language", value: language),
                    MemoryFactCard(title: "Currency", value: currency),
                    MemoryFactCard(title: "Currency Symbol", value: currencySymbol),
                    MemoryFactCard(title: "Continent", value: continent),
                    MemoryFactCard(title: "Colors", value: colors),
                    MemoryFactCard(title: "Monument", value: monument)
                ]
            ),
            learningArtwork: countryLearningArtwork(assetSuffix: assetSuffix, monument: monument)
        )
    }

    private static func countryLearningArtwork(assetSuffix: String, monument: String) -> [MemoryLearningArtwork] {
        [
            MemoryLearningArtwork(title: "Money clue", assetName: "MemoryCurrency\(assetSuffix)"),
            MemoryLearningArtwork(title: monument, assetName: "MemoryMonument\(assetSuffix)")
        ]
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
            canonicalName: "\(prompt). Missing part \(match)",
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
