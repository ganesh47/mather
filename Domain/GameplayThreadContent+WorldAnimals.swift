import Foundation

extension GameplayThreadCatalog {
    static let worldAnimals: GameplayThreadDefinition = GameplayThreadDefinition(
        id: "world-animals",
        title: "World Animals",
        category: GameplayCategory(
            id: "geography-world",
            title: "Geography + World",
            subtitle: "Animal names, homes, food clues, sounds, movements, colors, and kinds around the world"
        ),
        propertyTypes: [
            GameplayPropertyType(id: "name", displayName: "Name", prompt: "Find the animal name."),
            GameplayPropertyType(id: "habitat", displayName: "Home", prompt: "Find where this animal can live."),
            GameplayPropertyType(id: "diet", displayName: "Food", prompt: "Find what this animal mostly eats."),
            GameplayPropertyType(id: "movement", displayName: "Moves", prompt: "Find how this animal moves."),
            GameplayPropertyType(id: "sound", displayName: "Sound", prompt: "Find the animal sound."),
            GameplayPropertyType(id: "colors", displayName: "Colors", prompt: "Find the animal colors."),
            GameplayPropertyType(id: "kind", displayName: "Kind", prompt: "Find the animal kind.")
        ],
        entities: MemoryDeck.domesticAnimals.prefix(12).map { memoryAnimal in
            worldAnimalEntity(from: memoryAnimal)
        },
        stages: [
            GameplayStageDefinition(id: "world-animals-flashcards", kind: .flashcards, title: "Animal Cards", prompt: "Meet animals, names, homes, and food clues.", maximumItemCount: 12),
            GameplayStageDefinition(id: "world-animals-name-match", kind: .easyMemory, title: "Name Match", prompt: "Start by matching each animal picture to its name.", propertyTypeIDs: ["name"], maximumItemCount: 8),
            GameplayStageDefinition(id: "world-animals-habitat-match", kind: .flipMemory, title: "Habitat Match", prompt: "Remember which home clue belongs with each animal.", propertyTypeIDs: ["habitat"], maximumItemCount: 8),
            GameplayStageDefinition(id: "world-animals-diet-quiz", kind: .multipleChoice, title: "Food Quiz", prompt: "Pick whether each animal mostly eats plants, meat, or both.", propertyTypeIDs: ["diet"], maximumItemCount: 8),
            GameplayStageDefinition(id: "world-animals-bond-blast", kind: .bondBlast, title: "Animal Blast", prompt: "Connect each animal with its name, home, food clue, movement, sound, colors, and kind.", propertyTypeIDs: ["name", "habitat", "diet", "movement", "sound", "colors", "kind"], maximumItemCount: 12),
        ],
        progressionPolicy: GameplayProgressionPolicy(minimumAccuracyToAdvance: 0.70, retryMissedItemsFirst: true)
    )

    static func worldAnimalEntity(from memoryAnimal: MemoryAnimal) -> GameplayEntity {
        let metadata = memoryAnimal.metadata
        let safeID = "world-animal-\(memoryAnimal.id)"
        return GameplayEntity(
            id: safeID,
            name: memoryAnimal.name,
            summary: "A \(metadata.kind) that lives in \(metadata.habitat ?? "animal places") and \(metadata.movement ?? "moves in its own way").",
            visualKey: memoryAnimal.emoji,
            visualAssetName: memoryAnimal.imageAssetName,
            properties: [
                GameplayProperty(id: "\(safeID)-name", typeID: "name", value: memoryAnimal.name, explanation: "\(memoryAnimal.name) is this animal's name.", visualKey: memoryAnimal.emoji, visualAssetName: memoryAnimal.imageAssetName),
                memoryProperty(entityID: safeID, typeID: "habitat", value: metadata.habitat, fallback: "animal homes", explanationPrefix: "This animal can live in"),
                GameplayProperty(id: "\(safeID)-diet", typeID: "diet", value: worldAnimalDiet(for: memoryAnimal.id), explanation: "\(memoryAnimal.name) \(worldAnimalDietExplanation(for: memoryAnimal.id))."),
                memoryProperty(entityID: safeID, typeID: "movement", value: metadata.movement, fallback: "moves in its own way", explanationPrefix: "This animal"),
                memoryProperty(entityID: safeID, typeID: "sound", value: metadata.sound, fallback: "quiet animal clue", explanationPrefix: "Listen for"),
                memoryProperty(entityID: safeID, typeID: "colors", value: metadata.colors, fallback: "animal colors", explanationPrefix: "Look for"),
                GameplayProperty(id: "\(safeID)-kind", typeID: "kind", value: metadata.kind.capitalized, explanation: "This card is a \(metadata.kind).")
            ]
        )
    }

    static func memoryProperty(entityID: String, typeID: String, value: String?, fallback: String, explanationPrefix: String) -> GameplayProperty {
        let displayValue = value?.isEmpty == false ? value! : fallback
        return GameplayProperty(
            id: "\(entityID)-\(typeID)",
            typeID: typeID,
            value: displayValue,
            explanation: "\(explanationPrefix) \(displayValue)."
        )
    }

    static func worldAnimalDiet(for id: String) -> String {
        switch id {
        case "cat":
            return "Carnivore: mostly eats meat"
        case "dog", "pig", "duck", "rooster", "turkey", "goldfish":
            return "Omnivore: eats plants and animals"
        default:
            return "Herbivore: mostly eats plants"
        }
    }

    static func worldAnimalDietExplanation(for id: String) -> String {
        switch id {
        case "cat":
            return "is a carnivore, so it mostly eats meat"
        case "dog", "pig", "duck", "rooster", "turkey", "goldfish":
            return "is an omnivore, so it can eat plants and animals"
        default:
            return "is a herbivore, so it mostly eats plants"
        }
    }
}
