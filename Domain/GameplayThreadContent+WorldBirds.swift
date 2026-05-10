import Foundation

extension GameplayThreadCatalog {
    static let worldBirds: GameplayThreadDefinition = GameplayThreadDefinition(
        id: "world-birds",
        title: "World Birds",
        category: GameplayCategory(
            id: "geography-world",
            title: "Geography + World",
            subtitle: "Bird homes, colors, size, weight, and lifespan around the world"
        ),
        propertyTypes: [
            GameplayPropertyType(id: "name", displayName: "Name", prompt: "Find the bird name."),
            GameplayPropertyType(id: "home", displayName: "Home", prompt: "Find where this bird lives."),
            GameplayPropertyType(id: "colors", displayName: "Colors", prompt: "Find the bird colors."),
            GameplayPropertyType(id: "size", displayName: "Size", prompt: "Find the bird size."),
            GameplayPropertyType(id: "lifespan", displayName: "Lifespan", prompt: "Find how long this bird can live."),
            GameplayPropertyType(id: "weight", displayName: "Weight", prompt: "Find the bird weight.")
        ],
        entities: MemoryDeck.birds.prefix(12).map { memoryBird in
            worldBirdEntity(from: memoryBird)
        },
        stages: [
            GameplayStageDefinition(id: "world-birds-flashcards", kind: .flashcards, title: "Bird Cards", prompt: "Meet colorful birds from different world habitats.", maximumItemCount: 12),
            GameplayStageDefinition(id: "world-birds-easy-memory", kind: .easyMemory, title: "Bird Match", prompt: "Start with one focused round matching each bird picture to its name.", propertyTypeIDs: ["name"], maximumItemCount: 8),
            GameplayStageDefinition(id: "world-birds-bond-blast", kind: .bondBlast, title: "Bird Blast", prompt: "Connect each bird with its home, colors, size, lifespan, and weight.", propertyTypeIDs: ["home", "colors", "size", "lifespan", "weight"], maximumItemCount: 12),
        ],
        progressionPolicy: GameplayProgressionPolicy(minimumAccuracyToAdvance: 0.70, retryMissedItemsFirst: true)
    )

    static func worldBirdEntity(from memoryBird: MemoryAnimal) -> GameplayEntity {
        let metadata = memoryBird.metadata
        let safeID = "world-bird-\(memoryBird.id)"
        return GameplayEntity(
            id: safeID,
            name: memoryBird.name,
            summary: "A bird from \(metadata.habitat ?? "a world habitat") with \(metadata.colors ?? "colorful feathers").",
            visualKey: memoryBird.emoji,
            visualAssetName: memoryBird.imageAssetName,
            properties: [
                GameplayProperty(id: "\(safeID)-name", typeID: "name", value: memoryBird.name, explanation: "\(memoryBird.name) is this bird's name.", visualKey: memoryBird.emoji, visualAssetName: memoryBird.imageAssetName),
                memoryProperty(entityID: safeID, typeID: "home", value: metadata.habitat, fallback: "bird habitat", explanationPrefix: "This bird lives in"),
                memoryProperty(entityID: safeID, typeID: "colors", value: metadata.colors, fallback: "bird colors", explanationPrefix: "Look for"),
                memoryProperty(entityID: safeID, typeID: "size", value: metadata.size, fallback: "bird size", explanationPrefix: "Its size is"),
                memoryProperty(entityID: safeID, typeID: "lifespan", value: metadata.lifespan, fallback: "bird lifespan", explanationPrefix: "It can live about"),
                memoryProperty(entityID: safeID, typeID: "weight", value: metadata.weight, fallback: "bird weight", explanationPrefix: "It can weigh about")
            ]
        )
    }
}
