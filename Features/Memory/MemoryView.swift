import SwiftUI

// MARK: - Data model

enum MemoryPicture {
    case emoji(String)
    case tropicalBird(MemoryBirdSprite)
}

struct MemoryAnimal: Identifiable {
    let id: String
    let name: String
    let canonicalName: String
    let picture: MemoryPicture
    let artStyleOverride: MemoryArtStyle?

    init(
        id: String,
        name: String,
        canonicalName: String? = nil,
        picture: MemoryPicture,
        artStyleOverride: MemoryArtStyle? = nil
    ) {
        self.id = id
        self.name = name
        self.canonicalName = canonicalName ?? name
        self.picture = picture
        self.artStyleOverride = artStyleOverride
    }

    var selectionKey: String {
        canonicalName
            .folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
            .lowercased()
    }

    var emoji: String? {
        guard case let .emoji(value) = picture else { return nil }
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

enum BirdArchetype {
    case macaw
    case toucan
    case cockatoo
    case lorikeet
    case kingfisher
    case hummingbird
    case paradise
    case hornbill
    case parakeet
    case songbird
    case wader
    case pigeon
    case duck
    case pheasant
    case roller
    case turaco
    case peafowl
    case seabird
    case runner
}

struct MemoryBirdSprite {
    let setID: String
    let archetype: BirdArchetype
    let primaryColor: Color
    let secondaryColor: Color
    let wingColor: Color
    let accentColor: Color
    let beakColor: Color
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
        MemoryAnimal(id: "cow", name: "Cow", picture: .emoji("🐄")),
        MemoryAnimal(id: "dog", name: "Dog", picture: .emoji("🐕")),
        MemoryAnimal(id: "cat", name: "Cat", picture: .emoji("🐈")),
        MemoryAnimal(id: "sheep", name: "Sheep", picture: .emoji("🐑")),
        MemoryAnimal(id: "pig", name: "Pig", picture: .emoji("🐖")),
        MemoryAnimal(id: "horse", name: "Horse", picture: .emoji("🐎")),
        MemoryAnimal(id: "rabbit", name: "Rabbit", picture: .emoji("🐇")),
        MemoryAnimal(id: "duck", name: "Duck", picture: .emoji("🦆")),
        MemoryAnimal(id: "rooster", name: "Rooster", picture: .emoji("🐓")),
        MemoryAnimal(id: "goat", name: "Goat", picture: .emoji("🐐")),
        MemoryAnimal(id: "turkey", name: "Turkey", picture: .emoji("🦃")),
        MemoryAnimal(id: "goldfish", name: "Goldfish", picture: .emoji("🐟")),
        MemoryAnimal(id: "mouse", name: "Mouse", picture: .emoji("🐁")),
        MemoryAnimal(id: "frog", name: "Frog", picture: .emoji("🐸")),
        MemoryAnimal(id: "camel", name: "Camel", picture: .emoji("🐪")),
        MemoryAnimal(id: "llama", name: "Llama", picture: .emoji("🦙")),
        MemoryAnimal(id: "donkey", name: "Donkey", picture: .emoji("🫏")),
        MemoryAnimal(id: "ox", name: "Ox", picture: .emoji("🐂")),
    ]

    static let birds: [MemoryAnimal] = [
        tropicalBird("01", "Scarlet Macaw", archetype: .macaw, primary: rgb(0.88, 0.20, 0.24), secondary: rgb(0.98, 0.83, 0.24), wing: rgb(0.16, 0.45, 0.93), accent: rgb(1.0, 0.95, 0.84), beak: rgb(0.12, 0.12, 0.18), top: rgb(1.0, 0.83, 0.57), bottom: rgb(0.99, 0.49, 0.44), ornament: "sun.max.fill", ornamentColor: rgb(0.88, 0.28, 0.24)),
        tropicalBird("02", "Keel-billed Toucan", label: "Keel-billed Toucan", archetype: .toucan, primary: rgb(0.12, 0.14, 0.20), secondary: rgb(0.99, 0.97, 0.90), wing: rgb(0.21, 0.72, 0.48), accent: rgb(0.96, 0.80, 0.16), beak: rgb(0.96, 0.75, 0.18), top: rgb(0.58, 0.92, 0.78), bottom: rgb(0.17, 0.70, 0.55), ornament: "leaf.fill", ornamentColor: rgb(0.11, 0.51, 0.32)),
        tropicalBird("03", "Sulphur-crested Cockatoo", label: "Sulphur Cockatoo", archetype: .cockatoo, primary: rgb(0.98, 0.98, 0.95), secondary: rgb(0.94, 0.90, 0.78), wing: rgb(0.82, 0.84, 0.88), accent: rgb(0.99, 0.83, 0.19), beak: rgb(0.27, 0.27, 0.31), top: rgb(1.0, 0.94, 0.69), bottom: rgb(0.99, 0.82, 0.33), ornament: "sparkles", ornamentColor: rgb(0.97, 0.74, 0.18)),
        tropicalBird("04", "Rainbow Lorikeet", archetype: .lorikeet, primary: rgb(0.10, 0.63, 0.34), secondary: rgb(0.16, 0.35, 0.90), wing: rgb(0.95, 0.27, 0.26), accent: rgb(0.98, 0.84, 0.17), beak: rgb(0.95, 0.45, 0.18), top: rgb(0.65, 0.90, 1.0), bottom: rgb(0.35, 0.70, 0.98), ornament: "rainbow", ornamentColor: rgb(0.94, 0.27, 0.38)),
        tropicalBird("05", "Kingfisher", archetype: .kingfisher, primary: rgb(0.13, 0.55, 0.95), secondary: rgb(0.95, 0.55, 0.17), wing: rgb(0.06, 0.34, 0.78), accent: rgb(0.98, 0.93, 0.78), beak: rgb(0.19, 0.19, 0.22), top: rgb(0.70, 0.90, 1.0), bottom: rgb(0.34, 0.66, 0.97), ornament: "drop.fill", ornamentColor: rgb(0.12, 0.54, 0.88)),
        tropicalBird("06", "Hummingbird", archetype: .hummingbird, primary: rgb(0.15, 0.80, 0.52), secondary: rgb(0.74, 0.27, 0.89), wing: rgb(0.13, 0.44, 0.87), accent: rgb(1.0, 0.91, 0.38), beak: rgb(0.09, 0.10, 0.14), top: rgb(0.76, 0.98, 0.88), bottom: rgb(0.36, 0.90, 0.66), ornament: "bolt.heart.fill", ornamentColor: rgb(0.73, 0.30, 0.92)),
        tropicalBird("07", "Bird-of-Paradise", label: "Paradise Bird", archetype: .paradise, primary: rgb(0.96, 0.58, 0.15), secondary: rgb(0.25, 0.16, 0.15), wing: rgb(0.91, 0.38, 0.16), accent: rgb(0.99, 0.90, 0.34), beak: rgb(0.16, 0.14, 0.13), top: rgb(1.0, 0.89, 0.64), bottom: rgb(0.99, 0.69, 0.31), ornament: "sparkler", ornamentColor: rgb(0.94, 0.47, 0.12)),
        tropicalBird("08", "Hornbill", archetype: .hornbill, primary: rgb(0.12, 0.12, 0.16), secondary: rgb(0.98, 0.96, 0.88), wing: rgb(0.20, 0.20, 0.23), accent: rgb(0.90, 0.23, 0.18), beak: rgb(0.99, 0.80, 0.20), top: rgb(1.0, 0.91, 0.66), bottom: rgb(0.98, 0.72, 0.28), ornament: "crown.fill", ornamentColor: rgb(0.84, 0.21, 0.17)),
        tropicalBird("09", "Parakeet", archetype: .parakeet, primary: rgb(0.36, 0.84, 0.25), secondary: rgb(0.98, 0.96, 0.55), wing: rgb(0.15, 0.68, 0.29), accent: rgb(0.19, 0.48, 0.88), beak: rgb(0.94, 0.51, 0.22), top: rgb(0.84, 1.0, 0.74), bottom: rgb(0.58, 0.91, 0.39), ornament: "leaf.circle.fill", ornamentColor: rgb(0.15, 0.56, 0.23)),
        tropicalBird("10", "Flamingo", archetype: .wader, primary: rgb(0.98, 0.60, 0.76), secondary: rgb(0.99, 0.79, 0.86), wing: rgb(0.97, 0.42, 0.63), accent: rgb(0.98, 0.98, 0.98), beak: rgb(0.11, 0.11, 0.14), top: rgb(1.0, 0.86, 0.91), bottom: rgb(0.98, 0.63, 0.77), ornament: "heart.fill", ornamentColor: rgb(0.95, 0.36, 0.58)),
        tropicalBird("11", "Hyacinth Macaw", archetype: .macaw, primary: rgb(0.17, 0.29, 0.86), secondary: rgb(0.28, 0.50, 0.98), wing: rgb(0.12, 0.19, 0.61), accent: rgb(0.99, 0.84, 0.15), beak: rgb(0.12, 0.12, 0.16), top: rgb(0.74, 0.84, 1.0), bottom: rgb(0.42, 0.58, 0.98), ornament: "moon.stars.fill", ornamentColor: rgb(0.23, 0.34, 0.89)),
        tropicalBird("12", "Sun Conure", archetype: .parakeet, primary: rgb(0.98, 0.74, 0.14), secondary: rgb(0.97, 0.39, 0.19), wing: rgb(0.13, 0.58, 0.95), accent: rgb(1.0, 0.95, 0.84), beak: rgb(0.18, 0.18, 0.20), top: rgb(1.0, 0.91, 0.63), bottom: rgb(0.99, 0.63, 0.20), ornament: "sun.max.fill", ornamentColor: rgb(0.94, 0.49, 0.16)),
        tropicalBird("13", "Palm Cockatoo", archetype: .cockatoo, primary: rgb(0.21, 0.23, 0.28), secondary: rgb(0.31, 0.35, 0.43), wing: rgb(0.12, 0.13, 0.18), accent: rgb(0.87, 0.23, 0.21), beak: rgb(0.54, 0.56, 0.61), top: rgb(0.74, 0.77, 0.88), bottom: rgb(0.37, 0.42, 0.56), ornament: "flame.fill", ornamentColor: rgb(0.86, 0.24, 0.20)),
        tropicalBird("14", "Eclectus Parrot", archetype: .parakeet, primary: rgb(0.15, 0.72, 0.31), secondary: rgb(0.93, 0.18, 0.24), wing: rgb(0.12, 0.58, 0.29), accent: rgb(0.31, 0.39, 0.95), beak: rgb(0.95, 0.59, 0.20), top: rgb(0.79, 0.97, 0.75), bottom: rgb(0.48, 0.87, 0.35), ornament: "circle.grid.2x2.fill", ornamentColor: rgb(0.29, 0.38, 0.92)),
        tropicalBird("15", "Toco Toucan", archetype: .toucan, primary: rgb(0.10, 0.11, 0.15), secondary: rgb(0.99, 0.98, 0.92), wing: rgb(0.20, 0.23, 0.27), accent: rgb(0.98, 0.62, 0.19), beak: rgb(0.98, 0.70, 0.18), top: rgb(1.0, 0.91, 0.71), bottom: rgb(0.99, 0.75, 0.27), ornament: "sun.haze.fill", ornamentColor: rgb(0.96, 0.54, 0.18)),
        tropicalBird("16", "Bee Hummingbird", label: "Bee Hummingbird", archetype: .hummingbird, primary: rgb(0.22, 0.77, 0.54), secondary: rgb(0.92, 0.78, 0.24), wing: rgb(0.29, 0.52, 0.93), accent: rgb(1.0, 0.96, 0.84), beak: rgb(0.12, 0.12, 0.14), top: rgb(0.88, 0.99, 0.80), bottom: rgb(0.58, 0.91, 0.44), ornament: "ladybug.fill", ornamentColor: rgb(0.94, 0.66, 0.14)),
        tropicalBird("17", "Resplendent Quetzal", label: "Quetzal", archetype: .paradise, primary: rgb(0.14, 0.72, 0.44), secondary: rgb(0.95, 0.17, 0.22), wing: rgb(0.10, 0.47, 0.28), accent: rgb(0.35, 0.87, 0.82), beak: rgb(0.94, 0.86, 0.19), top: rgb(0.77, 1.0, 0.84), bottom: rgb(0.40, 0.89, 0.53), ornament: "sparkles", ornamentColor: rgb(0.25, 0.74, 0.57)),
        tropicalBird("18", "Hoopoe", archetype: .turaco, primary: rgb(0.91, 0.56, 0.27), secondary: rgb(0.96, 0.83, 0.60), wing: rgb(0.16, 0.16, 0.18), accent: rgb(0.94, 0.46, 0.20), beak: rgb(0.16, 0.15, 0.16), top: rgb(1.0, 0.89, 0.72), bottom: rgb(0.97, 0.69, 0.40), ornament: "burst.fill", ornamentColor: rgb(0.93, 0.45, 0.20)),
        tropicalBird("19", "Bali Myna", archetype: .songbird, primary: rgb(0.98, 0.98, 0.96), secondary: rgb(0.85, 0.89, 0.94), wing: rgb(0.29, 0.36, 0.52), accent: rgb(0.28, 0.72, 0.98), beak: rgb(0.97, 0.83, 0.19), top: rgb(0.89, 0.96, 1.0), bottom: rgb(0.67, 0.84, 0.98), ornament: "cloud.sun.fill", ornamentColor: rgb(0.26, 0.70, 0.97)),
        tropicalBird("20", "Scarlet Ibis", label: "Scarlet Ibis", archetype: .wader, primary: rgb(0.95, 0.29, 0.32), secondary: rgb(0.98, 0.63, 0.57), wing: rgb(0.86, 0.18, 0.24), accent: rgb(1.0, 0.88, 0.82), beak: rgb(0.16, 0.15, 0.16), top: rgb(1.0, 0.83, 0.79), bottom: rgb(0.98, 0.50, 0.45), ornament: "flame.fill", ornamentColor: rgb(0.90, 0.25, 0.21)),
        tropicalBird("21", "Blue-and-yellow Macaw", label: "Blue-Yellow Macaw", archetype: .macaw, primary: rgb(0.19, 0.43, 0.93), secondary: rgb(0.98, 0.84, 0.23), wing: rgb(0.13, 0.26, 0.76), accent: rgb(0.98, 0.98, 0.95), beak: rgb(0.12, 0.12, 0.16), top: rgb(0.82, 0.90, 1.0), bottom: rgb(0.46, 0.62, 0.98), ornament: "moonphase.waxing.crescent", ornamentColor: rgb(0.98, 0.74, 0.22)),
        tropicalBird("22", "Roseate Spoonbill", label: "Roseate Spoonbill", archetype: .wader, primary: rgb(0.98, 0.58, 0.75), secondary: rgb(0.99, 0.78, 0.86), wing: rgb(0.96, 0.40, 0.61), accent: rgb(0.99, 0.94, 0.95), beak: rgb(0.29, 0.31, 0.38), top: rgb(1.0, 0.88, 0.94), bottom: rgb(0.98, 0.66, 0.79), ornament: "heart.circle.fill", ornamentColor: rgb(0.95, 0.43, 0.62)),
        tropicalBird("23", "Mandarin Duck", label: "Mandarin Duck", archetype: .duck, primary: rgb(0.93, 0.44, 0.18), secondary: rgb(0.99, 0.92, 0.80), wing: rgb(0.26, 0.36, 0.90), accent: rgb(0.26, 0.74, 0.39), beak: rgb(0.90, 0.23, 0.18), top: rgb(1.0, 0.89, 0.72), bottom: rgb(0.98, 0.69, 0.41), ornament: "drop.circle.fill", ornamentColor: rgb(0.26, 0.43, 0.88)),
        tropicalBird("24", "Victoria Crowned Pigeon", label: "Victoria Pigeon", archetype: .pigeon, primary: rgb(0.34, 0.53, 0.92), secondary: rgb(0.58, 0.73, 0.99), wing: rgb(0.24, 0.38, 0.79), accent: rgb(0.98, 0.98, 0.97), beak: rgb(0.20, 0.22, 0.26), top: rgb(0.81, 0.90, 1.0), bottom: rgb(0.50, 0.67, 0.98), ornament: "crown.fill", ornamentColor: rgb(0.26, 0.42, 0.88)),
        tropicalBird("25", "Green-winged Macaw", label: "Green-winged Macaw", archetype: .macaw, primary: rgb(0.92, 0.22, 0.22), secondary: rgb(0.17, 0.63, 0.31), wing: rgb(0.20, 0.43, 0.92), accent: rgb(1.0, 0.95, 0.82), beak: rgb(0.12, 0.12, 0.15), top: rgb(1.0, 0.84, 0.74), bottom: rgb(0.99, 0.55, 0.41), ornament: "leaf.fill", ornamentColor: rgb(0.18, 0.64, 0.31)),
        tropicalBird("26", "White Cockatoo", label: "White Cockatoo", archetype: .cockatoo, primary: rgb(0.99, 0.99, 0.97), secondary: rgb(0.90, 0.93, 0.97), wing: rgb(0.82, 0.86, 0.92), accent: rgb(0.99, 0.90, 0.41), beak: rgb(0.23, 0.23, 0.28), top: rgb(0.94, 0.97, 1.0), bottom: rgb(0.78, 0.86, 0.98), ornament: "snowflake", ornamentColor: rgb(0.66, 0.74, 0.92)),
        tropicalBird("27", "Gouldian Finch", label: "Gouldian Finch", archetype: .songbird, primary: rgb(0.35, 0.84, 0.35), secondary: rgb(0.96, 0.88, 0.20), wing: rgb(0.72, 0.22, 0.88), accent: rgb(0.14, 0.15, 0.18), beak: rgb(0.95, 0.44, 0.17), top: rgb(0.88, 0.99, 0.78), bottom: rgb(0.56, 0.92, 0.46), ornament: "circle.hexagongrid.fill", ornamentColor: rgb(0.74, 0.25, 0.88)),
        tropicalBird("28", "Golden Pheasant", label: "Golden Pheasant", archetype: .pheasant, primary: rgb(0.97, 0.77, 0.18), secondary: rgb(0.88, 0.22, 0.18), wing: rgb(0.20, 0.61, 0.28), accent: rgb(0.99, 0.93, 0.77), beak: rgb(0.21, 0.17, 0.12), top: rgb(1.0, 0.92, 0.66), bottom: rgb(0.98, 0.71, 0.25), ornament: "sparkler", ornamentColor: rgb(0.90, 0.28, 0.18)),
        tropicalBird("29", "Lilac-breasted Roller", label: "Lilac Roller", archetype: .roller, primary: rgb(0.35, 0.79, 0.95), secondary: rgb(0.79, 0.54, 0.97), wing: rgb(0.17, 0.57, 0.86), accent: rgb(0.98, 0.85, 0.20), beak: rgb(0.12, 0.12, 0.15), top: rgb(0.86, 0.94, 1.0), bottom: rgb(0.57, 0.76, 0.99), ornament: "camera.macro", ornamentColor: rgb(0.77, 0.51, 0.97)),
        tropicalBird("30", "Turaco", archetype: .turaco, primary: rgb(0.16, 0.71, 0.41), secondary: rgb(0.95, 0.21, 0.23), wing: rgb(0.13, 0.54, 0.30), accent: rgb(0.98, 0.97, 0.97), beak: rgb(0.92, 0.78, 0.21), top: rgb(0.83, 0.99, 0.79), bottom: rgb(0.52, 0.91, 0.49), ornament: "feather.fill", ornamentColor: rgb(0.91, 0.23, 0.22)),
        tropicalBird("31", "Scarlet Ibis", label: "Scarlet Ibis", archetype: .wader, primary: rgb(0.86, 0.17, 0.26), secondary: rgb(0.98, 0.50, 0.49), wing: rgb(0.72, 0.10, 0.19), accent: rgb(0.99, 0.90, 0.88), beak: rgb(0.18, 0.17, 0.20), top: rgb(0.99, 0.79, 0.77), bottom: rgb(0.96, 0.40, 0.42), ornament: "sunset.fill", ornamentColor: rgb(0.85, 0.18, 0.24)),
        tropicalBird("32", "Major Mitchell’s Cockatoo", label: "Mitchell's Cockatoo", archetype: .cockatoo, primary: rgb(0.99, 0.96, 0.96), secondary: rgb(0.96, 0.74, 0.84), wing: rgb(0.86, 0.88, 0.92), accent: rgb(0.97, 0.40, 0.56), beak: rgb(0.25, 0.25, 0.30), top: rgb(1.0, 0.89, 0.94), bottom: rgb(0.99, 0.70, 0.79), ornament: "sparkles", ornamentColor: rgb(0.96, 0.45, 0.57)),
        tropicalBird("33", "Indian Peafowl", label: "Peafowl", archetype: .peafowl, primary: rgb(0.16, 0.58, 0.93), secondary: rgb(0.18, 0.77, 0.47), wing: rgb(0.14, 0.37, 0.83), accent: rgb(0.97, 0.79, 0.18), beak: rgb(0.13, 0.13, 0.16), top: rgb(0.80, 0.93, 1.0), bottom: rgb(0.48, 0.79, 0.99), ornament: "eye.fill", ornamentColor: rgb(0.97, 0.80, 0.19)),
        tropicalBird("34", "Crimson Rosella", label: "Crimson Rosella", archetype: .parakeet, primary: rgb(0.93, 0.22, 0.27), secondary: rgb(0.23, 0.57, 0.96), wing: rgb(0.17, 0.41, 0.82), accent: rgb(0.99, 0.92, 0.81), beak: rgb(0.97, 0.96, 0.94), top: rgb(1.0, 0.84, 0.79), bottom: rgb(0.99, 0.58, 0.51), ornament: "flame.fill", ornamentColor: rgb(0.90, 0.23, 0.25)),
        tropicalBird("35", "Nicobar Pigeon", label: "Nicobar Pigeon", archetype: .pigeon, primary: rgb(0.17, 0.70, 0.59), secondary: rgb(0.33, 0.84, 0.89), wing: rgb(0.44, 0.34, 0.78), accent: rgb(0.83, 0.58, 0.27), beak: rgb(0.18, 0.20, 0.25), top: rgb(0.80, 0.99, 0.92), bottom: rgb(0.43, 0.91, 0.72), ornament: "circle.grid.cross.fill", ornamentColor: rgb(0.44, 0.36, 0.79)),
        tropicalBird("36", "Black Palm Cockatoo", label: "Black Palm Cockatoo", archetype: .cockatoo, primary: rgb(0.11, 0.12, 0.16), secondary: rgb(0.26, 0.29, 0.35), wing: rgb(0.08, 0.09, 0.12), accent: rgb(0.90, 0.29, 0.28), beak: rgb(0.56, 0.58, 0.65), top: rgb(0.69, 0.73, 0.86), bottom: rgb(0.34, 0.39, 0.53), ornament: "smoke.fill", ornamentColor: rgb(0.87, 0.30, 0.28)),
        tropicalBird("37", "Andean Cock-of-the-rock", label: "Cock-of-the-rock", archetype: .runner, primary: rgb(0.98, 0.47, 0.17), secondary: rgb(0.99, 0.76, 0.42), wing: rgb(0.24, 0.18, 0.17), accent: rgb(1.0, 0.94, 0.84), beak: rgb(0.22, 0.17, 0.13), top: rgb(1.0, 0.89, 0.66), bottom: rgb(0.99, 0.66, 0.24), ornament: "mountain.2.fill", ornamentColor: rgb(0.90, 0.42, 0.18)),
        tropicalBird("38", "Atlantic Puffin", label: "Puffin", archetype: .seabird, primary: rgb(0.13, 0.14, 0.18), secondary: rgb(0.98, 0.97, 0.94), wing: rgb(0.16, 0.16, 0.20), accent: rgb(0.96, 0.52, 0.15), beak: rgb(0.97, 0.60, 0.18), top: rgb(0.82, 0.92, 1.0), bottom: rgb(0.54, 0.74, 0.99), ornament: "waveform.path.ecg", ornamentColor: rgb(0.96, 0.50, 0.17)),
        tropicalBird("39", "Red-legged Seriema", label: "Seriema", archetype: .runner, primary: rgb(0.83, 0.73, 0.58), secondary: rgb(0.95, 0.89, 0.74), wing: rgb(0.63, 0.54, 0.43), accent: rgb(0.93, 0.25, 0.20), beak: rgb(0.97, 0.62, 0.17), top: rgb(0.99, 0.92, 0.77), bottom: rgb(0.95, 0.79, 0.48), ornament: "hare.fill", ornamentColor: rgb(0.89, 0.32, 0.20)),
        tropicalBird("40", "Rainbow Bee-eater", label: "Bee-eater", archetype: .songbird, primary: rgb(0.17, 0.73, 0.51), secondary: rgb(0.97, 0.80, 0.20), wing: rgb(0.29, 0.47, 0.94), accent: rgb(0.95, 0.28, 0.55), beak: rgb(0.11, 0.11, 0.14), top: rgb(0.84, 0.99, 0.85), bottom: rgb(0.56, 0.93, 0.54), ornament: "rainbow", ornamentColor: rgb(0.93, 0.29, 0.56)),
    ]

    static let vehicles: [MemoryAnimal] = [
        MemoryAnimal(id: "car", name: "Car", picture: .emoji("🚗")),
        MemoryAnimal(id: "bus", name: "Bus", picture: .emoji("🚌")),
        MemoryAnimal(id: "train", name: "Train", picture: .emoji("🚂")),
        MemoryAnimal(id: "plane", name: "Plane", picture: .emoji("✈️")),
        MemoryAnimal(id: "boat", name: "Boat", picture: .emoji("⛵")),
        MemoryAnimal(id: "bike", name: "Bike", picture: .emoji("🚲")),
        MemoryAnimal(id: "truck", name: "Truck", picture: .emoji("🚚")),
        MemoryAnimal(id: "tractor", name: "Tractor", picture: .emoji("🚜")),
        MemoryAnimal(id: "helicopter", name: "Copter", picture: .emoji("🚁")),
        MemoryAnimal(id: "rocket", name: "Rocket", picture: .emoji("🚀")),
        MemoryAnimal(id: "scooter", name: "Scooter", picture: .emoji("🛵")),
        MemoryAnimal(id: "taxi", name: "Taxi", picture: .emoji("🚕")),
    ]

    static let allAnimalsById: [String: MemoryAnimal] = {
        Dictionary(uniqueKeysWithValues: (domesticAnimals + birds + vehicles).map { ($0.id, $0) })
    }()

    private static func tropicalBird(
        _ setID: String,
        _ canonicalName: String,
        label: String? = nil,
        archetype: BirdArchetype,
        primary: Color,
        secondary: Color,
        wing: Color,
        accent: Color,
        beak: Color,
        top: Color,
        bottom: Color,
        ornament: String,
        ornamentColor: Color
    ) -> MemoryAnimal {
        let sprite = MemoryBirdSprite(
            setID: setID,
            archetype: archetype,
            primaryColor: primary,
            secondaryColor: secondary,
            wingColor: wing,
            accentColor: accent,
            beakColor: beak,
            topColor: top,
            bottomColor: bottom,
            badgeColor: accent.opacity(0.92),
            badgeHighlight: Color.white.opacity(0.94),
            ornament: ornament,
            ornamentColor: ornamentColor
        )

        return MemoryAnimal(
            id: "bird-\(setID)",
            name: label ?? canonicalName,
            canonicalName: canonicalName,
            picture: .tropicalBird(sprite),
            artStyleOverride: MemoryArtStyle(
                topColor: top,
                bottomColor: bottom,
                badgeColor: accent.opacity(0.9),
                badgeHighlight: Color.white.opacity(0.94),
                ornament: ornament,
                ornamentColor: ornamentColor
            )
        )
    }

    private static func rgb(_ red: Double, _ green: Double, _ blue: Double) -> Color {
        Color(red: red, green: green, blue: blue)
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

// MARK: - Main view

struct MemoryView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Bindable var appModel: AppModel

    @State private var deck: [MemoryAnimal] = MemoryDeck.domesticAnimals
    @State private var difficulty: MemoryDifficulty = .easy
    @State private var cards: [MemoryCard] = []
    @State private var firstSelected: MemoryCard? = nil
    @State private var matchedPairs: Int = 0
    @State private var roundsPlayed: Int = 0
    @State private var mismatchIds: Set<UUID> = []
    @State private var isProcessingMismatch: Bool = false
    @State private var showRoundComplete: Bool = false
    @State private var deckSelection: DeckSelection = .domestic
    @State private var recentPairHistory: [String] = []

    enum DeckSelection: CaseIterable {
        case domestic, birds, vehicles

        var label: String {
            switch self {
            case .domestic: return "🐄 Animals"
            case .birds: return "🦜 Birds"
            case .vehicles: return "🚗 Vehicles"
            }
        }

        var menuLabel: String {
            switch self {
            case .domestic: return "Animals"
            case .birds: return "Birds"
            case .vehicles: return "Vehicles"
            }
        }

        var animals: [MemoryAnimal] {
            switch self {
            case .domestic: return MemoryDeck.domesticAnimals
            case .birds: return MemoryDeck.birds
            case .vehicles: return MemoryDeck.vehicles
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

            if showRoundComplete {
                roundCompleteOverlay
            }
        }
        .onAppear { dealRound() }
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
        let columns = Array(repeating: GridItem(.flexible(), spacing: 14), count: difficulty.columns)
        return LazyVGrid(columns: columns, spacing: 14) {
            ForEach(cards) { card in
                cardView(card)
                    .onTapGesture { handleTap(card) }
            }
        }
    }

    @ViewBuilder
    private func cardView(_ card: MemoryCard) -> some View {
        let isMismatch = mismatchIds.contains(card.id)
        let isFlipped = difficulty.faceDown && !card.isSelected && !card.isMatched

        ZStack {
            if isFlipped {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [MatherTheme.accent.opacity(0.7), MatherTheme.softBlue.opacity(0.7)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                Text("?")
                    .font(.system(size: 40, weight: .black, design: .rounded))
                    .foregroundStyle(.white.opacity(0.6))
            } else {
                cardFace(card)
            }
        }
        .frame(height: cardHeight)
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(
                    card.isSelected ? MatherTheme.accent : (card.isMatched ? Color.green : Color.clear),
                    lineWidth: card.isSelected ? 3 : 2
                )
        )
        .scaleEffect(card.isMatched ? 0.92 : 1.0)
        .opacity(card.isMatched ? 0.45 : 1.0)
        .rotationEffect(isMismatch ? .degrees(-3) : .zero)
        .animation(.spring(response: 0.25, dampingFraction: 0.6), value: card.isSelected)
        .animation(.easeOut(duration: 0.3), value: card.isMatched)
        .animation(isMismatch ? .easeInOut(duration: 0.08).repeatCount(3, autoreverses: true) : .default, value: isMismatch)
    }

    @ViewBuilder
    private func cardFace(_ card: MemoryCard) -> some View {
        let animal = animal(for: card)
        let artStyle = Self.artStyle(for: animal.id)

        switch card.content {
        case .picture(let pictureAnimal):
            ZStack {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: card.isMatched ? [Color.green.opacity(0.24), Color.green.opacity(0.10)] : [artStyle.topColor, artStyle.bottomColor],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

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
                    .fill(
                        LinearGradient(
                            colors: [artStyle.badgeHighlight, artStyle.badgeColor],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: cardHeight * 0.62, height: cardHeight * 0.62)
                    .shadow(color: artStyle.badgeColor.opacity(0.25), radius: 10, y: 6)

                Circle()
                    .strokeBorder(Color.white.opacity(colorScheme == .dark ? 0.16 : 0.55), lineWidth: 3)
                    .frame(width: cardHeight * 0.62, height: cardHeight * 0.62)

                pictureView(for: pictureAnimal)
                    .frame(width: cardHeight * 0.60, height: cardHeight * 0.60)
            }

        case .label(let labelAnimal):
            ZStack {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: card.isMatched ? [Color.green.opacity(0.18), Color.green.opacity(0.08)] : [artStyle.topColor.opacity(0.30), artStyle.bottomColor.opacity(0.18)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                VStack(spacing: 10) {
                    HStack(spacing: 6) {
                        Image(systemName: artStyle.ornament)
                            .font(.caption.weight(.black))
                        Text("Match the picture")
                            .font(.caption2.weight(.bold))
                    }
                    .foregroundStyle(artStyle.ornamentColor)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.white.opacity(colorScheme == .dark ? 0.08 : 0.45), in: Capsule())

                    Text(labelAnimal.name)
                        .font(.system(size: Self.labelFontSize(for: difficulty), weight: .black, design: .rounded))
                        .foregroundStyle(MatherTheme.ink)
                        .lineLimit(1)
                        .minimumScaleFactor(Self.labelMinimumScaleFactor(for: difficulty))
                        .allowsTightening(true)
                        .truncationMode(.tail)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, Self.labelHorizontalPadding(for: difficulty))
                        .padding(.vertical, 8)
                        .frame(maxWidth: .infinity)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 10)
            }
        }
    }

    @ViewBuilder
    private func pictureView(for animal: MemoryAnimal) -> some View {
        switch animal.picture {
        case .emoji(let emoji):
            Text(emoji)
                .font(.system(size: emojiSize))
                .shadow(color: .black.opacity(0.10), radius: 3, y: 2)
        case .tropicalBird(let sprite):
            BirdSpriteView(sprite: sprite)
                .padding(difficulty == .hard ? 4 : 2)
        }
    }

    private func animal(for card: MemoryCard) -> MemoryAnimal {
        switch card.content {
        case .picture(let animal), .label(let animal):
            return animal
        }
    }

    static func labelFontSize(for difficulty: MemoryDifficulty) -> CGFloat {
        switch difficulty {
        case .easy: return 22
        case .medium: return 20
        case .hard: return 17
        }
    }

    static func labelMinimumScaleFactor(for difficulty: MemoryDifficulty) -> CGFloat {
        switch difficulty {
        case .easy: return 0.82
        case .medium: return 0.74
        case .hard: return 0.50
        }
    }

    static func labelHorizontalPadding(for difficulty: MemoryDifficulty) -> CGFloat {
        switch difficulty {
        case .easy: return 10
        case .medium: return 8
        case .hard: return 4
        }
    }

    static func artStyle(for pairId: String) -> MemoryArtStyle {
        if let customStyle = MemoryDeck.allAnimalsById[pairId]?.artStyleOverride {
            return customStyle
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

    private var cardHeight: CGFloat {
        switch difficulty {
        case .easy: return 140
        case .medium: return 130
        case .hard: return 110
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
        ZStack {
            Color.black.opacity(0.35)
                .ignoresSafeArea()
                .onTapGesture { nextRound() }

            VStack(spacing: 20) {
                Text("🎉")
                    .font(.system(size: 72))
                Text("All matched!")
                    .font(.system(size: 36, weight: .black, design: .rounded))
                    .foregroundStyle(MatherTheme.ink)
                Text("Round \(roundsPlayed) complete")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(MatherTheme.cardSubtitle)

                Button("Next Round") {
                    nextRound()
                }
                .buttonStyle(PrimaryActionButtonStyle())
                .frame(maxWidth: 240)
            }
            .padding(36)
            .background(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(MatherTheme.card)
                    .shadow(color: .black.opacity(0.18), radius: 24, y: 8)
            )
        }
        .transition(.opacity.combined(with: .scale(scale: 0.95)))
    }

    static func preferredRoundAnimals(from deck: [MemoryAnimal], pairCount: Int, recentPairHistory: [String]) -> [MemoryAnimal] {
        let recentSet = Set(recentPairHistory)
        let freshPool = uniqueSelectionPool(from: deck.filter { !recentSet.contains($0.id) })
        let fullPool = uniqueSelectionPool(from: deck)
        let primaryPool = freshPool.count >= pairCount ? freshPool : fullPool

        var chosen: [MemoryAnimal] = []
        var seenKeys: Set<String> = []

        for animal in primaryPool.shuffled() where seenKeys.insert(animal.selectionKey).inserted {
            chosen.append(animal)
            if chosen.count == pairCount {
                return chosen
            }
        }

        for animal in fullPool.shuffled() where seenKeys.insert(animal.selectionKey).inserted {
            chosen.append(animal)
            if chosen.count == pairCount {
                break
            }
        }

        return chosen
    }

    static func updatedRecentPairHistory(previous: [String], newRoundAnimals: [MemoryAnimal], pairCount: Int) -> [String] {
        let historyWindow = max(pairCount * 2, pairCount)
        let combined = previous + newRoundAnimals.map(\.id)
        return Array(combined.suffix(historyWindow))
    }

    private static func uniqueSelectionPool(from animals: [MemoryAnimal]) -> [MemoryAnimal] {
        var seen: Set<String> = []
        return animals.filter { seen.insert($0.selectionKey).inserted }
    }

    private func dealRound() {
        let roundAnimals = Self.preferredRoundAnimals(from: deck, pairCount: totalPairs, recentPairHistory: recentPairHistory)
        var newCards: [MemoryCard] = []
        for animal in roundAnimals {
            newCards.append(MemoryCard(pairId: animal.id, content: .picture(animal)))
            newCards.append(MemoryCard(pairId: animal.id, content: .label(animal)))
        }
        recentPairHistory = Self.updatedRecentPairHistory(previous: recentPairHistory, newRoundAnimals: roundAnimals, pairCount: totalPairs)
        cards = newCards.shuffled()
        firstSelected = nil
        matchedPairs = 0
        mismatchIds = []
        isProcessingMismatch = false
        showRoundComplete = false
    }

    private func handleTap(_ card: MemoryCard) {
        guard !card.isMatched, !isProcessingMismatch else { return }
        guard !card.isSelected else { return }

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
        withAnimation(.easeOut(duration: 0.2)) {
            showRoundComplete = false
        }
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(250))
            dealRound()
        }
    }
}

private struct BirdSpriteView: View {
    let sprite: MemoryBirdSprite

    var body: some View {
        GeometryReader { geo in
            let size = min(geo.size.width, geo.size.height)
            let bodyWidth = bodyWidthRatio * size
            let bodyHeight = bodyHeightRatio * size
            let headSize = headSizeRatio * size
            let tailWidth = tailWidthRatio * size
            let tailHeight = tailHeightRatio * size
            let legHeight = legHeightRatio * size
            let beakWidth = beakWidthRatio * size
            let beakHeight = beakHeightRatio * size
            let wingWidth = wingWidthRatio * size
            let wingHeight = wingHeightRatio * size

            ZStack {
                tailView(size: size, tailWidth: tailWidth, tailHeight: tailHeight)
                    .offset(x: tailOffsetX * size, y: tailOffsetY * size)

                if legHeight > 0 {
                    HStack(spacing: size * 0.08) {
                        Capsule()
                            .fill(sprite.secondaryColor.opacity(0.85))
                            .frame(width: size * 0.035, height: legHeight)
                        Capsule()
                            .fill(sprite.secondaryColor.opacity(0.85))
                            .frame(width: size * 0.035, height: legHeight)
                    }
                    .offset(x: 0, y: legOffsetY * size)
                }

                Ellipse()
                    .fill(sprite.primaryColor)
                    .frame(width: bodyWidth, height: bodyHeight)
                    .offset(x: bodyOffsetX * size, y: bodyOffsetY * size)

                Ellipse()
                    .fill(sprite.secondaryColor.opacity(0.88))
                    .frame(width: bodyWidth * bellyWidthRatio, height: bodyHeight * bellyHeightRatio)
                    .offset(x: bellyOffsetX * size, y: bellyOffsetY * size)

                Ellipse()
                    .fill(sprite.wingColor)
                    .frame(width: wingWidth, height: wingHeight)
                    .rotationEffect(.degrees(wingRotation))
                    .offset(x: wingOffsetX * size, y: wingOffsetY * size)

                Circle()
                    .fill(sprite.primaryColor)
                    .frame(width: headSize, height: headSize)
                    .offset(x: headOffsetX * size, y: headOffsetY * size)

                Circle()
                    .fill(Color.white.opacity(0.82))
                    .frame(width: headSize * 0.16, height: headSize * 0.16)
                    .offset(x: (headOffsetX + eyeOffsetX) * size, y: (headOffsetY + eyeOffsetY) * size)

                Circle()
                    .fill(Color.black.opacity(0.82))
                    .frame(width: headSize * 0.09, height: headSize * 0.09)
                    .offset(x: (headOffsetX + eyeOffsetX) * size, y: (headOffsetY + eyeOffsetY) * size)

                Triangle()
                    .fill(sprite.beakColor)
                    .frame(width: beakWidth, height: beakHeight)
                    .rotationEffect(.degrees(beakRotation))
                    .offset(x: beakOffsetX * size, y: beakOffsetY * size)

                crestView(size: size)
                    .offset(x: crestOffsetX * size, y: crestOffsetY * size)

                badgeView(size: size)
                    .offset(x: badgeOffsetX * size, y: badgeOffsetY * size)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private var bodyWidthRatio: CGFloat {
        switch sprite.archetype {
        case .hummingbird: return 0.36
        case .wader: return 0.34
        case .runner: return 0.40
        case .peafowl: return 0.34
        case .seabird: return 0.42
        default: return 0.46
        }
    }

    private var bodyHeightRatio: CGFloat {
        switch sprite.archetype {
        case .hummingbird: return 0.28
        case .wader: return 0.34
        case .runner: return 0.34
        case .seabird: return 0.34
        default: return 0.38
        }
    }

    private var bodyOffsetX: CGFloat {
        switch sprite.archetype {
        case .toucan, .hornbill: return -0.04
        case .wader: return 0.00
        default: return -0.02
        }
    }

    private var bodyOffsetY: CGFloat {
        switch sprite.archetype {
        case .wader: return 0.08
        case .runner: return 0.06
        case .hummingbird: return -0.02
        default: return 0.04
        }
    }

    private var bellyWidthRatio: CGFloat {
        switch sprite.archetype {
        case .toucan, .hornbill, .seabird: return 0.56
        case .wader: return 0.52
        default: return 0.48
        }
    }

    private var bellyHeightRatio: CGFloat {
        switch sprite.archetype {
        case .wader: return 0.48
        default: return 0.52
        }
    }

    private var bellyOffsetX: CGFloat { 0.02 }
    private var bellyOffsetY: CGFloat {
        switch sprite.archetype {
        case .hummingbird: return 0.04
        case .wader: return 0.12
        default: return 0.08
        }
    }

    private var wingWidthRatio: CGFloat {
        switch sprite.archetype {
        case .hummingbird: return 0.34
        case .peafowl: return 0.30
        case .wader: return 0.26
        default: return 0.32
        }
    }

    private var wingHeightRatio: CGFloat {
        switch sprite.archetype {
        case .hummingbird: return 0.18
        case .wader: return 0.20
        default: return 0.22
        }
    }

    private var wingRotation: Double {
        switch sprite.archetype {
        case .hummingbird: return -42
        case .wader: return -18
        case .runner: return -6
        default: return -22
        }
    }

    private var wingOffsetX: CGFloat {
        switch sprite.archetype {
        case .toucan, .hornbill: return -0.04
        case .hummingbird: return -0.02
        default: return -0.06
        }
    }

    private var wingOffsetY: CGFloat {
        switch sprite.archetype {
        case .hummingbird: return -0.06
        default: return 0.02
        }
    }

    private var headSizeRatio: CGFloat {
        switch sprite.archetype {
        case .toucan, .hornbill: return 0.22
        case .hummingbird: return 0.18
        case .wader: return 0.18
        default: return 0.20
        }
    }

    private var headOffsetX: CGFloat {
        switch sprite.archetype {
        case .toucan, .hornbill: return 0.16
        case .wader: return 0.12
        case .runner: return 0.10
        default: return 0.12
        }
    }

    private var headOffsetY: CGFloat {
        switch sprite.archetype {
        case .wader: return -0.10
        case .hummingbird: return -0.12
        case .runner: return -0.12
        default: return -0.08
        }
    }

    private var eyeOffsetX: CGFloat { 0.03 }
    private var eyeOffsetY: CGFloat { -0.01 }

    private var beakWidthRatio: CGFloat {
        switch sprite.archetype {
        case .toucan: return 0.30
        case .hornbill: return 0.28
        case .hummingbird: return 0.22
        case .kingfisher: return 0.18
        case .wader: return 0.22
        case .seabird: return 0.18
        default: return 0.14
        }
    }

    private var beakHeightRatio: CGFloat {
        switch sprite.archetype {
        case .toucan, .hornbill: return 0.14
        case .hummingbird, .kingfisher, .wader: return 0.08
        default: return 0.10
        }
    }

    private var beakRotation: Double {
        switch sprite.archetype {
        case .wader: return 24
        case .runner: return 10
        default: return 90
        }
    }

    private var beakOffsetX: CGFloat {
        switch sprite.archetype {
        case .toucan: return 0.32
        case .hornbill: return 0.30
        case .hummingbird: return 0.25
        case .kingfisher: return 0.22
        case .wader: return 0.22
        case .runner: return 0.20
        default: return 0.22
        }
    }

    private var beakOffsetY: CGFloat {
        switch sprite.archetype {
        case .wader: return -0.12
        case .hummingbird: return -0.12
        case .runner: return -0.12
        default: return -0.08
        }
    }

    private var tailWidthRatio: CGFloat {
        switch sprite.archetype {
        case .paradise: return 0.28
        case .pheasant: return 0.24
        case .peafowl: return 0.44
        case .macaw: return 0.18
        case .wader: return 0.16
        default: return 0.18
        }
    }

    private var tailHeightRatio: CGFloat {
        switch sprite.archetype {
        case .paradise: return 0.44
        case .pheasant: return 0.34
        case .peafowl: return 0.36
        case .macaw: return 0.30
        default: return 0.22
        }
    }

    private var tailOffsetX: CGFloat {
        switch sprite.archetype {
        case .paradise: return -0.28
        case .pheasant: return -0.24
        case .peafowl: return -0.18
        default: return -0.22
        }
    }

    private var tailOffsetY: CGFloat {
        switch sprite.archetype {
        case .paradise: return 0.06
        case .pheasant: return 0.02
        case .peafowl: return -0.02
        default: return 0.08
        }
    }

    private var legHeightRatio: CGFloat {
        switch sprite.archetype {
        case .wader: return 0.26
        case .runner: return 0.22
        default: return 0.10
        }
    }

    private var legOffsetY: CGFloat {
        switch sprite.archetype {
        case .wader: return 0.28
        case .runner: return 0.22
        default: return 0.24
        }
    }

    private var crestOffsetX: CGFloat {
        switch sprite.archetype {
        case .cockatoo: return 0.10
        case .pigeon: return 0.10
        case .turaco, .runner: return 0.08
        case .peafowl: return 0.10
        default: return 0.08
        }
    }

    private var crestOffsetY: CGFloat {
        switch sprite.archetype {
        case .cockatoo: return -0.24
        case .pigeon: return -0.22
        case .turaco, .runner: return -0.22
        case .peafowl: return -0.22
        default: return -0.18
        }
    }

    private var badgeOffsetX: CGFloat {
        switch sprite.archetype {
        case .wader, .runner: return 0.18
        default: return 0.12
        }
    }

    private var badgeOffsetY: CGFloat {
        switch sprite.archetype {
        case .wader, .runner: return 0.30
        default: return 0.24
        }
    }

    @ViewBuilder
    private func crestView(size: CGFloat) -> some View {
        switch sprite.archetype {
        case .cockatoo:
            HStack(spacing: size * 0.01) {
                ForEach(0..<4, id: \.self) { index in
                    Capsule()
                        .fill(sprite.accentColor)
                        .frame(width: size * 0.035, height: size * (0.12 + CGFloat(index) * 0.01))
                        .rotationEffect(.degrees(Double(-28 + (index * 16))))
                }
            }
        case .pigeon:
            HStack(spacing: size * 0.01) {
                ForEach(0..<5, id: \.self) { _ in
                    Circle()
                        .fill(sprite.accentColor)
                        .frame(width: size * 0.04, height: size * 0.04)
                }
            }
        case .turaco, .runner:
            HStack(spacing: size * 0.01) {
                ForEach(0..<3, id: \.self) { index in
                    Triangle()
                        .fill(sprite.accentColor)
                        .frame(width: size * 0.06, height: size * 0.10)
                        .rotationEffect(.degrees(Double(-14 + (index * 14))))
                }
            }
        case .peafowl:
            HStack(spacing: size * 0.008) {
                ForEach(0..<3, id: \.self) { _ in
                    Capsule()
                        .fill(sprite.accentColor)
                        .frame(width: size * 0.024, height: size * 0.10)
                }
            }
        default:
            EmptyView()
        }
    }

    @ViewBuilder
    private func tailView(size: CGFloat, tailWidth: CGFloat, tailHeight: CGFloat) -> some View {
        switch sprite.archetype {
        case .peafowl:
            ZStack {
                ForEach(0..<5, id: \.self) { index in
                    Capsule()
                        .fill((index % 2 == 0 ? sprite.secondaryColor : sprite.wingColor).opacity(0.92))
                        .frame(width: size * 0.08, height: tailHeight)
                        .rotationEffect(.degrees(Double(-40 + index * 20)))
                        .offset(y: -size * 0.06)
                }
            }
        case .paradise:
            ZStack {
                Capsule()
                    .fill(sprite.secondaryColor)
                    .frame(width: size * 0.06, height: tailHeight)
                    .rotationEffect(.degrees(-30))
                Capsule()
                    .fill(sprite.accentColor)
                    .frame(width: size * 0.05, height: tailHeight * 0.94)
                    .rotationEffect(.degrees(-52))
            }
        case .pheasant:
            Capsule()
                .fill(sprite.secondaryColor)
                .frame(width: tailWidth, height: tailHeight)
                .rotationEffect(.degrees(-34))
        default:
            Triangle()
                .fill(sprite.secondaryColor)
                .frame(width: tailWidth, height: tailHeight)
                .rotationEffect(.degrees(-70))
        }
    }

    private func badgeView(size: CGFloat) -> some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [sprite.badgeHighlight, sprite.badgeColor],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: size * 0.20, height: size * 0.20)
            Text(sprite.setID)
                .font(.system(size: size * 0.08, weight: .black, design: .rounded))
                .foregroundStyle(Color.black.opacity(0.78))
        }
        .overlay(Circle().strokeBorder(Color.white.opacity(0.55), lineWidth: 2))
    }
}

private struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        Path { path in
            path.move(to: CGPoint(x: rect.midX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
            path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
            path.closeSubpath()
        }
    }
}
