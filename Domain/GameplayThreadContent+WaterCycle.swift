import Foundation

enum GameplayThreadCatalog {
    static let waterCycle: GameplayThreadDefinition = GameplayThreadDefinition(
        id: "water-cycle",
        title: "Water Cycle",
        category: GameplayCategory(
            id: "physics",
            title: "Physics",
            subtitle: "Water moves up, gathers, falls, and collects again."
        ),
        propertyTypes: waterCyclePropertyTypes,
        entities: waterCycleEntities,
        stages: waterCycleStages,
        progressionPolicy: GameplayProgressionPolicy(minimumAccuracyToAdvance: 0.75)
    )

    private static let waterCyclePropertyTypes: [GameplayPropertyType] = [
        GameplayPropertyType(id: "order", displayName: "Order", prompt: "Which step comes here in the cycle?"),
        GameplayPropertyType(id: "simpleExplanation", displayName: "Simple Explanation", prompt: "Say the step in kid-friendly words."),
        GameplayPropertyType(id: "cause", displayName: "Cause", prompt: "What makes this step happen?"),
        GameplayPropertyType(id: "whatHappens", displayName: "What Happens", prompt: "What changes during this step?"),
        GameplayPropertyType(id: "visualClue", displayName: "Visual Clue", prompt: "What can you look for in the picture?")
    ]

    private static let waterCycleEntities: [GameplayEntity] = [
        GameplayEntity(
            id: "water-cycle-evaporation",
            name: "Evaporation",
            summary: "Warm water changes into vapor and rises into the air.",
            visualKey: "☀️💧⬆️",
            visualAssetName: "MemoryWaterCycleEvaporation",
            properties: properties(
                for: "water-cycle-evaporation",
                order: "1 of 4",
                simpleExplanation: "Water goes up as vapor.",
                cause: "The sun warms ponds, lakes, rivers, puddles, and wet ground.",
                whatHappens: "Liquid water changes into tiny vapor particles that float upward.",
                visualClue: "Look for mist or rising drops above warm water."
            )
        ),
        GameplayEntity(
            id: "water-cycle-condensation",
            name: "Condensation",
            summary: "Vapor cools and gathers into tiny drops that make clouds.",
            visualKey: "☁️💧",
            visualAssetName: "MemoryWaterCycleCondensation",
            properties: properties(
                for: "water-cycle-condensation",
                order: "2 of 4",
                simpleExplanation: "Tiny water drops gather into clouds.",
                cause: "Rising water vapor reaches cooler air high above the ground.",
                whatHappens: "Vapor changes back into liquid droplets and bunches together.",
                visualClue: "Look for small drops packed inside a cloud."
            )
        ),
        GameplayEntity(
            id: "water-cycle-precipitation",
            name: "Precipitation",
            summary: "Cloud drops get heavy enough to fall as rain, snow, sleet, or hail.",
            visualKey: "🌧️⬇️",
            visualAssetName: "MemoryWaterCyclePrecipitation",
            properties: properties(
                for: "water-cycle-precipitation",
                order: "3 of 4",
                simpleExplanation: "Water falls from clouds.",
                cause: "Cloud drops grow too heavy for the air to hold.",
                whatHappens: "Water falls back toward Earth as rain, snow, sleet, or hail.",
                visualClue: "Look for rain streaks falling under a dark cloud."
            )
        ),
        GameplayEntity(
            id: "water-cycle-collection",
            name: "Collection",
            summary: "Fallen water gathers in places like ponds, lakes, rivers, puddles, and the ground.",
            visualKey: "🏞️💧",
            visualAssetName: "MemoryWaterCycleCollection",
            properties: properties(
                for: "water-cycle-collection",
                order: "4 of 4",
                simpleExplanation: "Water gathers again on Earth.",
                cause: "Gravity pulls fallen water into low places and into the ground.",
                whatHappens: "Water waits in ponds, lakes, rivers, puddles, oceans, snow, ice, or soil until it can rise again.",
                visualClue: "Look for water collecting in a pond, river, puddle, or lake."
            )
        )
    ]

    private static let waterCycleStages: [GameplayStageDefinition] = [
        GameplayStageDefinition(
            id: "water-cycle-flashcards",
            kind: .flashcards,
            title: "Look + Learn",
            prompt: "Meet each water cycle step in order.",
            maximumItemCount: 4
        ),
        GameplayStageDefinition(
            id: "water-cycle-easy-memory",
            kind: .easyMemory,
            title: "Order Match",
            prompt: "Can you put the water cycle in order? Match each step to its number clue.",
            propertyTypeIDs: ["order"],
            maximumItemCount: 4
        ),
        GameplayStageDefinition(
            id: "water-cycle-flip-memory",
            kind: .flipMemory,
            title: "What Happens?",
            prompt: "Flip and remember what changes in each step.",
            propertyTypeIDs: ["whatHappens"],
            maximumItemCount: 4
        ),
        GameplayStageDefinition(
            id: "water-cycle-bond-blast",
            kind: .bondBlast,
            title: "Cause + Clue Blast",
            prompt: "Connect steps to causes and picture clues.",
            propertyTypeIDs: ["cause", "visualClue"],
            maximumItemCount: 8
        ),
        GameplayStageDefinition(
            id: "water-cycle-multiple-choice",
            kind: .multipleChoice,
            title: "Cycle Quiz",
            prompt: "Pick the best explanation for each water cycle step.",
            propertyTypeIDs: ["simpleExplanation"],
            maximumItemCount: 4
        )
    ]

    private static func properties(
        for entityID: String,
        order: String,
        simpleExplanation: String,
        cause: String,
        whatHappens: String,
        visualClue: String
    ) -> [GameplayProperty] {
        [
            GameplayProperty(id: "\(entityID)-order", typeID: "order", value: order, explanation: "Cycle order clue for \(entityID)."),
            GameplayProperty(id: "\(entityID)-simpleExplanation", typeID: "simpleExplanation", value: simpleExplanation),
            GameplayProperty(id: "\(entityID)-cause", typeID: "cause", value: cause),
            GameplayProperty(id: "\(entityID)-whatHappens", typeID: "whatHappens", value: whatHappens),
            GameplayProperty(id: "\(entityID)-visualClue", typeID: "visualClue", value: visualClue)
        ]
    }
}
