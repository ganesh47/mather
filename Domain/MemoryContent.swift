import Foundation

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

struct MemoryLearningArtwork: Equatable, Hashable {
    let title: String
    let assetName: String
}

enum MemoryDeckKind: String, CaseIterable, Equatable, Hashable {
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
        Dictionary(uniqueKeysWithValues: allDeckAnimals.map { ($0.id, $0) })
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
    ] + countryLearningAssetProvenance

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
                ]
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
