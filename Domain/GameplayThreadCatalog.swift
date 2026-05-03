import Foundation

enum GameplayThreadID: String, Codable, CaseIterable, Hashable {
    case countries
    case fruits
}

enum GameplayThreadCatalog {
    static func thread(for id: GameplayThreadID) -> GameplayThreadDefinition {
        switch id {
        case .countries:
            return GameplaySampleThreads.countries
        case .fruits:
            return fruits
        }
    }

    static let fruits: GameplayThreadDefinition = GameplayThreadDefinition(
        id: "fruits",
        title: "Fruit Cards",
        category: GameplayCategory(
            id: "chemistry",
            title: "Chemistry",
            subtitle: "Fruit properties: colors, tastes, seeds, skins, and where they grow"
        ),
        propertyTypes: [
            GameplayPropertyType(id: "name", displayName: "Name", prompt: "Find the fruit name."),
            GameplayPropertyType(id: "color", displayName: "Color", prompt: "Find the fruit color."),
            GameplayPropertyType(id: "taste", displayName: "Taste", prompt: "Find the taste clue."),
            GameplayPropertyType(id: "seed-skin", displayName: "Seed or Skin", prompt: "Find the seed or skin clue."),
            GameplayPropertyType(id: "grows-on", displayName: "Grows On", prompt: "Find where it grows."),
            GameplayPropertyType(id: "category", displayName: "Fruit Type", prompt: "Find the fruit family clue.")
        ],
        entities: [
            GameplayEntity(id: "fruit-apple", name: "Apple", summary: "A crunchy fruit that can be red, green, or yellow.", visualKey: "🍎", properties: [
                GameplayProperty(id: "fruit-apple-name", typeID: "name", value: "Apple", explanation: "Apple is the fruit's name.", visualKey: "🍎"),
                GameplayProperty(id: "fruit-apple-color", typeID: "color", value: "Red, green, or yellow", explanation: "Apples can wear different colored skins."),
                GameplayProperty(id: "fruit-apple-taste", typeID: "taste", value: "Sweet and crisp", explanation: "An apple often tastes sweet and makes a crisp crunch."),
                GameplayProperty(id: "fruit-apple-seed-skin", typeID: "seed-skin", value: "Thin skin with small seeds inside", explanation: "Apple seeds hide in the core, and the skin is safe to eat after washing."),
                GameplayProperty(id: "fruit-apple-grows-on", typeID: "grows-on", value: "Tree", explanation: "Apples grow on apple trees."),
                GameplayProperty(id: "fruit-apple-category", typeID: "category", value: "Orchard fruit", explanation: "Orchards are places where many fruit trees grow.")
            ]),
            GameplayEntity(id: "fruit-banana", name: "Banana", summary: "A soft yellow fruit with a peel you remove.", visualKey: "🍌", properties: [
                GameplayProperty(id: "fruit-banana-name", typeID: "name", value: "Banana", explanation: "Banana is the fruit's name.", visualKey: "🍌"),
                GameplayProperty(id: "fruit-banana-color", typeID: "color", value: "Yellow", explanation: "Ripe bananas usually have yellow peels."),
                GameplayProperty(id: "fruit-banana-taste", typeID: "taste", value: "Sweet and soft", explanation: "Bananas taste sweet and feel soft when ripe."),
                GameplayProperty(id: "fruit-banana-seed-skin", typeID: "seed-skin", value: "Thick peel with tiny soft seeds", explanation: "The peel protects the banana. The tiny seeds are usually too small to notice."),
                GameplayProperty(id: "fruit-banana-grows-on", typeID: "grows-on", value: "Large banana plant", explanation: "Bananas grow in bunches on tall banana plants."),
                GameplayProperty(id: "fruit-banana-category", typeID: "category", value: "Tropical fruit", explanation: "Tropical fruits grow well in warm places.")
            ]),
            GameplayEntity(id: "fruit-mango", name: "Mango", summary: "A juicy tropical fruit with one big seed.", visualKey: "🥭", properties: [
                GameplayProperty(id: "fruit-mango-name", typeID: "name", value: "Mango", explanation: "Mango is the fruit's name.", visualKey: "🥭"),
                GameplayProperty(id: "fruit-mango-color", typeID: "color", value: "Yellow, orange, green, or red", explanation: "Mango skin can show many sunny colors."),
                GameplayProperty(id: "fruit-mango-taste", typeID: "taste", value: "Very sweet and juicy", explanation: "A ripe mango is juicy and very sweet."),
                GameplayProperty(id: "fruit-mango-seed-skin", typeID: "seed-skin", value: "Thin skin with one big flat seed", explanation: "A mango has one large seed in the middle."),
                GameplayProperty(id: "fruit-mango-grows-on", typeID: "grows-on", value: "Tree", explanation: "Mangoes grow on mango trees."),
                GameplayProperty(id: "fruit-mango-category", typeID: "category", value: "Tropical stone fruit", explanation: "A stone fruit has one big hard seed, or stone, inside.")
            ]),
            GameplayEntity(id: "fruit-orange", name: "Orange", summary: "A round citrus fruit with juicy sections.", visualKey: "🍊", properties: [
                GameplayProperty(id: "fruit-orange-name", typeID: "name", value: "Orange", explanation: "Orange is both the fruit name and a color.", visualKey: "🍊"),
                GameplayProperty(id: "fruit-orange-color", typeID: "color", value: "Orange", explanation: "Most ripe oranges have bright orange skin."),
                GameplayProperty(id: "fruit-orange-taste", typeID: "taste", value: "Sweet and tangy", explanation: "Tangy means it has a bright little zing."),
                GameplayProperty(id: "fruit-orange-seed-skin", typeID: "seed-skin", value: "Bumpy peel; some have seeds", explanation: "The peel comes off before eating the juicy parts."),
                GameplayProperty(id: "fruit-orange-grows-on", typeID: "grows-on", value: "Tree", explanation: "Oranges grow on citrus trees."),
                GameplayProperty(id: "fruit-orange-category", typeID: "category", value: "Citrus fruit", explanation: "Citrus fruits often smell fresh and taste tangy.")
            ]),
            GameplayEntity(id: "fruit-grape", name: "Grape", summary: "A small juicy fruit that grows in bunches.", visualKey: "🍇", properties: [
                GameplayProperty(id: "fruit-grape-name", typeID: "name", value: "Grape", explanation: "Grape is the fruit's name.", visualKey: "🍇"),
                GameplayProperty(id: "fruit-grape-color", typeID: "color", value: "Green, red, or purple", explanation: "Grapes can be green, red, or purple."),
                GameplayProperty(id: "fruit-grape-taste", typeID: "taste", value: "Sweet and juicy", explanation: "Grapes pop with sweet juice."),
                GameplayProperty(id: "fruit-grape-seed-skin", typeID: "seed-skin", value: "Thin skin; seeded or seedless", explanation: "Some grapes have tiny seeds, and some are grown seedless."),
                GameplayProperty(id: "fruit-grape-grows-on", typeID: "grows-on", value: "Vine", explanation: "Grapes grow in bunches on vines."),
                GameplayProperty(id: "fruit-grape-category", typeID: "category", value: "Vine fruit", explanation: "Vine fruits grow on long climbing stems.")
            ]),
            GameplayEntity(id: "fruit-watermelon", name: "Watermelon", summary: "A big melon with green rind and red juicy inside.", visualKey: "🍉", properties: [
                GameplayProperty(id: "fruit-watermelon-name", typeID: "name", value: "Watermelon", explanation: "Watermelon is the fruit's name.", visualKey: "🍉"),
                GameplayProperty(id: "fruit-watermelon-color", typeID: "color", value: "Green outside and red inside", explanation: "The rind is green, and the juicy middle is often red."),
                GameplayProperty(id: "fruit-watermelon-taste", typeID: "taste", value: "Sweet and watery", explanation: "Watermelon is full of sweet juice."),
                GameplayProperty(id: "fruit-watermelon-seed-skin", typeID: "seed-skin", value: "Hard rind with black or white seeds", explanation: "The rind protects the juicy fruit inside."),
                GameplayProperty(id: "fruit-watermelon-grows-on", typeID: "grows-on", value: "Vine on the ground", explanation: "Watermelons grow on vines that spread along the ground."),
                GameplayProperty(id: "fruit-watermelon-category", typeID: "category", value: "Melon", explanation: "Melons are large juicy fruits with rinds.")
            ]),
            GameplayEntity(id: "fruit-pineapple", name: "Pineapple", summary: "A tropical fruit with a spiky crown.", visualKey: "🍍", properties: [
                GameplayProperty(id: "fruit-pineapple-name", typeID: "name", value: "Pineapple", explanation: "Pineapple is the fruit's name.", visualKey: "🍍"),
                GameplayProperty(id: "fruit-pineapple-color", typeID: "color", value: "Gold and green", explanation: "Pineapple has golden fruit and green leaves."),
                GameplayProperty(id: "fruit-pineapple-taste", typeID: "taste", value: "Sweet and tangy", explanation: "Pineapple tastes sweet with a bright tang."),
                GameplayProperty(id: "fruit-pineapple-seed-skin", typeID: "seed-skin", value: "Tough spiky skin; tiny seeds", explanation: "The rough outside protects the sweet fruit."),
                GameplayProperty(id: "fruit-pineapple-grows-on", typeID: "grows-on", value: "Low plant", explanation: "Pineapples grow from low plants near the ground."),
                GameplayProperty(id: "fruit-pineapple-category", typeID: "category", value: "Tropical fruit", explanation: "Pineapples like warm tropical places." )
            ]),
            GameplayEntity(id: "fruit-strawberry", name: "Strawberry", summary: "A red berry-like fruit with tiny seeds on the outside.", visualKey: "🍓", properties: [
                GameplayProperty(id: "fruit-strawberry-name", typeID: "name", value: "Strawberry", explanation: "Strawberry is the fruit's name.", visualKey: "🍓"),
                GameplayProperty(id: "fruit-strawberry-color", typeID: "color", value: "Red", explanation: "Ripe strawberries are usually bright red."),
                GameplayProperty(id: "fruit-strawberry-taste", typeID: "taste", value: "Sweet and a little tart", explanation: "Tart means a tiny sour sparkle with the sweet taste."),
                GameplayProperty(id: "fruit-strawberry-seed-skin", typeID: "seed-skin", value: "Tiny seeds on the outside", explanation: "Strawberries carry many tiny seeds on their outside."),
                GameplayProperty(id: "fruit-strawberry-grows-on", typeID: "grows-on", value: "Low plant", explanation: "Strawberries grow on low plants close to the ground."),
                GameplayProperty(id: "fruit-strawberry-category", typeID: "category", value: "Berry-like fruit", explanation: "Kids often call it a berry because it is small, soft, and juicy.")
            ])
        ],
        stages: [
            GameplayStageDefinition(id: "fruit-flashcards", kind: .flashcards, title: "Look + Learn", prompt: "Meet each fruit and its clues.", maximumItemCount: 8),
            GameplayStageDefinition(id: "fruit-easy-memory", kind: .easyMemory, title: "Easy Memory", prompt: "Match each fruit to a friendly clue.", propertyTypeIDs: ["name", "color"], maximumItemCount: 6),
            GameplayStageDefinition(id: "fruit-flip-memory", kind: .flipMemory, title: "Flip Memory", prompt: "Remember fruit colors and tastes.", propertyTypeIDs: ["color", "taste"], maximumItemCount: 6),
            GameplayStageDefinition(id: "fruit-bond-blast", kind: .bondBlast, title: "Bond Blast", prompt: "Connect fruit names, tastes, seeds, skins, and grow clues.", propertyTypeIDs: ["taste", "seed-skin", "grows-on", "category"], maximumItemCount: 8),
            GameplayStageDefinition(id: "fruit-quiz", kind: .multipleChoice, title: "Fruit Quiz", prompt: "Pick the best fruit property.", propertyTypeIDs: ["color", "taste", "seed-skin", "grows-on"], maximumItemCount: 6)
        ],
        progressionPolicy: GameplayProgressionPolicy(minimumAccuracyToAdvance: 0.72, retryMissedItemsFirst: true)
    )
}
