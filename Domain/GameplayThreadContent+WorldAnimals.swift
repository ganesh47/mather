import Foundation

extension GameplayThreadCatalog {
    static let worldAnimals: GameplayThreadDefinition = GameplayThreadDefinition(
        id: "world-animals",
        title: "World Animals",
        category: GameplayCategory(
            id: "geography-world",
            title: "Geography + World",
            subtitle: "Animal homes, sounds, movements, colors, and kinds around the world"
        ),
        propertyTypes: [
            GameplayPropertyType(id: "name", displayName: "Name", prompt: "Find the animal name."),
            GameplayPropertyType(id: "habitat", displayName: "Home", prompt: "Find where this animal can live."),
            GameplayPropertyType(id: "movement", displayName: "Moves", prompt: "Find how this animal moves."),
            GameplayPropertyType(id: "sound", displayName: "Sound", prompt: "Find the animal sound."),
            GameplayPropertyType(id: "colors", displayName: "Colors", prompt: "Find the animal colors."),
            GameplayPropertyType(id: "kind", displayName: "Kind", prompt: "Find the animal kind.")
        ],
        entities: MemoryDeck.domesticAnimals.prefix(12).map { memoryAnimal in
            worldAnimalEntity(from: memoryAnimal)
        },
        stages: [
            GameplayStageDefinition(id: "world-animals-flashcards", kind: .flashcards, title: "Animal Cards", prompt: "Meet animals and notice where they live.", maximumItemCount: 12),
            GameplayStageDefinition(id: "world-animals-easy-memory", kind: .easyMemory, title: "Animal Match", prompt: "Match animals to names, homes, sounds, and moves.", propertyTypeIDs: ["name", "habitat", "movement", "sound"], maximumItemCount: 8),
            GameplayStageDefinition(id: "world-animals-bond-blast", kind: .bondBlast, title: "Animal Blast", prompt: "Connect each animal with its home, movement, sound, colors, and kind.", propertyTypeIDs: ["habitat", "movement", "sound", "colors", "kind"], maximumItemCount: 12),
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
}
