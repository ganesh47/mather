import Foundation

/// Declarative iOS content. Its endpoint and schema are independent of the TV feed.
struct IOSLearningCatalog: Codable, Equatable {
    let schemaVersion: Int
    let contentVersion: Int
    let decks: [MemoryGalleryContentPack.Deck]
    let threads: [GameplayThreadDefinition]
    let assets: [MemoryGalleryContentPack.Asset]

    static var bundled: Self {
        Self(schemaVersion: 1, contentVersion: 1,
             decks: MemoryDeckKind.allCases.map { .init(kind: $0, cards: MemoryDeck.animals(for: $0)) },
             threads: GameplayThreadID.allCases.map { GameplayThreadCatalog.thread(for: $0) }, assets: [])
    }

    func cards(for kind: MemoryDeckKind) -> [MemoryAnimal] {
        decks.first { $0.kind == kind }?.cards ?? MemoryDeck.animals(for: kind)
    }

    func thread(for id: GameplayThreadID) -> GameplayThreadDefinition {
        threads.first { $0.id == id.rawValue } ?? GameplayThreadCatalog.thread(for: id)
    }

    func validate() throws {
        try MemoryGalleryContentPack(schemaVersion: schemaVersion, contentVersion: contentVersion,
            decks: decks, assets: assets).validate(requiredKinds: Set(MemoryDeckKind.allCases))
        func require(_ condition: Bool, _ reason: String) throws {
            guard condition else { throw MemoryGalleryContentPack.ValidationError.invalidPack(reason) }
        }
        func validID(_ value: String) -> Bool {
            !value.isEmpty && value.count <= 100 && value.unicodeScalars.allSatisfy {
                CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-_").contains($0)
            }
        }
        func validText(_ value: String) -> Bool { !value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && value.count <= 1000 }
        let requiredThreads = Set(GameplayThreadID.allCases.map(\.rawValue))
        try require(threads.count == requiredThreads.count && Set(threads.map(\.id)) == requiredThreads, "Expected every iOS topic exactly once")
        let bundledEntities = GameplayThreadID.allCases.flatMap { GameplayThreadCatalog.thread(for: $0).entities }
        let bundledAssets = Set(MemoryDeck.allDeckAnimals.compactMap(\.imageAssetName)
            + MemoryDeck.allDeckAnimals.flatMap(\.learningArtwork).map(\.assetName)
            + bundledEntities.compactMap(\.visualAssetName)
            + bundledEntities.flatMap(\.properties).compactMap(\.visualAssetName))
        let knownAssets = bundledAssets.union(assets.map(\.id))
        let shapeKeys = Set(CountryGameplayThread.thread.entities.compactMap(\.visualShapeKey)
            + CountryGameplayThread.thread.entities.flatMap(\.properties).compactMap(\.visualShapeKey))
        func validateVisual(asset: String?, shape: String?, visual: String?) throws {
            if let asset { try require(knownAssets.contains(asset), "Unknown topic artwork") }
            if let shape { try require(shapeKeys.contains(shape), "Unknown map shape") }
            if let visual { try require(validText(visual), "Invalid visual label") }
        }
        for thread in threads {
            try require(validText(thread.title) && validID(thread.category.id) && validText(thread.category.title), "Invalid topic title")
            try require((1...24).contains(thread.propertyTypes.count), "Invalid property type count")
            let typeIDs = Set(thread.propertyTypes.map(\.id))
            try require(typeIDs.count == thread.propertyTypes.count && thread.propertyTypes.allSatisfy {
                validID($0.id) && validText($0.displayName) && validText($0.prompt)
            }, "Invalid or duplicate property types")
            try require((2...250).contains(thread.entities.count), "Invalid topic size")
            try require(Set(thread.entities.map(\.id)).count == thread.entities.count, "Duplicate topic entities")
            var propertyIDs = Set<String>()
            for entity in thread.entities {
                try require(validID(entity.id) && validText(entity.name) && entity.summary.count <= 1000, "Invalid topic entity")
                try validateVisual(asset: entity.visualAssetName, shape: entity.visualShapeKey, visual: entity.visualKey)
                try require((1...24).contains(entity.properties.count), "Invalid property count")
                for property in entity.properties {
                    try require(validID(property.id) && propertyIDs.insert(property.id).inserted && typeIDs.contains(property.typeID)
                        && validText(property.value) && property.explanation.count <= 1000, "Invalid topic property")
                    try validateVisual(asset: property.visualAssetName, shape: property.visualShapeKey, visual: property.visualKey)
                }
            }
            try require((1...12).contains(thread.stages.count) && Set(thread.stages.map(\.id)).count == thread.stages.count, "Invalid topic stages")
            for stage in thread.stages {
                try require(validID(stage.id) && validText(stage.title) && validText(stage.prompt)
                    && (1...100).contains(stage.maximumItemCount) && Set(stage.propertyTypeIDs).isSubset(of: typeIDs), "Invalid topic stage")
            }
        }
    }
}
