import Foundation

enum GameplayThreadID: String, Codable, CaseIterable, Hashable {
    case countries
    case fruits
    case waterCycle = "water-cycle"
    case shapes
    case electronics
    case worldAnimals = "world-animals"
    case worldBirds = "world-birds"
}

extension GameplayThreadCatalog {
    static func thread(for id: GameplayThreadID) -> GameplayThreadDefinition {
        switch id {
        case .countries:
            return CountryGameplayThread.thread
        case .fruits:
            return fruits
        case .waterCycle:
            return waterCycle
        case .shapes:
            return shapes
        case .electronics:
            return electronics
        case .worldAnimals:
            return worldAnimals
        case .worldBirds:
            return worldBirds
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
            GameplayPropertyType(id: "grow-climate", displayName: "Grow Climate", prompt: "Find the warm, cool, or snowy-place clue."),
            GameplayPropertyType(id: "origin", displayName: "Origin Clue", prompt: "Find a place people first grew this fruit."),
            GameplayPropertyType(id: "flavor", displayName: "Flavor Friend", prompt: "Find the flavor it reminds you of."),
            GameplayPropertyType(id: "category", displayName: "Fruit Type", prompt: "Find the fruit family clue.")
        ],
        entities: [
            GameplayEntity(id: "fruit-apple", name: "Apple", summary: "A crunchy fruit that can be red, green, or yellow.", visualKey: "🍎", properties: [
                GameplayProperty(id: "fruit-apple-name", typeID: "name", value: "Apple", explanation: "Apple is the fruit's name.", visualKey: "🍎"),
                GameplayProperty(id: "fruit-apple-color", typeID: "color", value: "Red, green, or yellow", explanation: "Apples can wear different colored skins."),
                GameplayProperty(id: "fruit-apple-taste", typeID: "taste", value: "Sweet and crisp", explanation: "An apple often tastes sweet and makes a crisp crunch."),
                GameplayProperty(id: "fruit-apple-seed-skin", typeID: "seed-skin", value: "Thin skin with small seeds inside", explanation: "Apple seeds hide in the core, and the skin is safe to eat after washing."),
                GameplayProperty(id: "fruit-apple-grows-on", typeID: "grows-on", value: "Tree", explanation: "Apples grow on apple trees."),
                GameplayProperty(id: "fruit-apple-grow-climate", typeID: "grow-climate", value: "Cool orchards", explanation: "Apples grow well in places with warm days and cool nights."),
                GameplayProperty(id: "fruit-apple-origin", typeID: "origin", value: "Central Asia", explanation: "Many apple ancestors came from Central Asia long ago."),
                GameplayProperty(id: "fruit-apple-flavor", typeID: "flavor", value: "Cinnamon pie", explanation: "Apple flavor often reminds people of cinnamon, pie, or fresh juice."),
                GameplayProperty(id: "fruit-apple-category", typeID: "category", value: "Orchard fruit", explanation: "Orchards are places where many fruit trees grow.")
            ]),
            GameplayEntity(id: "fruit-banana", name: "Banana", summary: "A soft yellow fruit with a peel you remove.", visualKey: "🍌", properties: [
                GameplayProperty(id: "fruit-banana-name", typeID: "name", value: "Banana", explanation: "Banana is the fruit's name.", visualKey: "🍌"),
                GameplayProperty(id: "fruit-banana-color", typeID: "color", value: "Yellow", explanation: "Ripe bananas usually have yellow peels."),
                GameplayProperty(id: "fruit-banana-taste", typeID: "taste", value: "Sweet and soft", explanation: "Bananas taste sweet and feel soft when ripe."),
                GameplayProperty(id: "fruit-banana-seed-skin", typeID: "seed-skin", value: "Thick peel with tiny soft seeds", explanation: "The peel protects the banana. The tiny seeds are usually too small to notice."),
                GameplayProperty(id: "fruit-banana-grows-on", typeID: "grows-on", value: "Large banana plant", explanation: "Bananas grow in bunches on tall banana plants."),
                GameplayProperty(id: "fruit-banana-grow-climate", typeID: "grow-climate", value: "Warm tropical places", explanation: "Bananas like warm, rainy places with no snow."),
                GameplayProperty(id: "fruit-banana-origin", typeID: "origin", value: "Southeast Asia", explanation: "People first grew bananas in warm parts of Southeast Asia."),
                GameplayProperty(id: "fruit-banana-flavor", typeID: "flavor", value: "Creamy smoothie", explanation: "Banana flavor is sweet and creamy, like a smoothie."),
                GameplayProperty(id: "fruit-banana-category", typeID: "category", value: "Tropical fruit", explanation: "Tropical fruits grow well in warm places.")
            ]),
            GameplayEntity(id: "fruit-mango", name: "Mango", summary: "A juicy tropical fruit with one big seed.", visualKey: "🥭", properties: [
                GameplayProperty(id: "fruit-mango-name", typeID: "name", value: "Mango", explanation: "Mango is the fruit's name.", visualKey: "🥭"),
                GameplayProperty(id: "fruit-mango-color", typeID: "color", value: "Yellow, orange, green, or red", explanation: "Mango skin can show many sunny colors."),
                GameplayProperty(id: "fruit-mango-taste", typeID: "taste", value: "Very sweet and juicy", explanation: "A ripe mango is juicy and very sweet."),
                GameplayProperty(id: "fruit-mango-seed-skin", typeID: "seed-skin", value: "Thin skin with one big flat seed", explanation: "A mango has one large seed in the middle."),
                GameplayProperty(id: "fruit-mango-grows-on", typeID: "grows-on", value: "Tree", explanation: "Mangoes grow on mango trees."),
                GameplayProperty(id: "fruit-mango-grow-climate", typeID: "grow-climate", value: "Hot tropical places", explanation: "Mango trees love heat and sunshine."),
                GameplayProperty(id: "fruit-mango-origin", typeID: "origin", value: "South Asia", explanation: "Mangoes have been grown in South Asia for a very long time."),
                GameplayProperty(id: "fruit-mango-flavor", typeID: "flavor", value: "Honey sunshine", explanation: "Mango flavor can feel sweet like honey and bright like sunshine."),
                GameplayProperty(id: "fruit-mango-category", typeID: "category", value: "Tropical stone fruit", explanation: "A stone fruit has one big hard seed, or stone, inside.")
            ]),
            GameplayEntity(id: "fruit-orange", name: "Orange", summary: "A round citrus fruit with juicy sections.", visualKey: "🍊", properties: [
                GameplayProperty(id: "fruit-orange-name", typeID: "name", value: "Orange", explanation: "Orange is both the fruit name and a color.", visualKey: "🍊"),
                GameplayProperty(id: "fruit-orange-color", typeID: "color", value: "Orange", explanation: "Most ripe oranges have bright orange skin."),
                GameplayProperty(id: "fruit-orange-taste", typeID: "taste", value: "Sweet and tangy", explanation: "Tangy means it has a bright little zing."),
                GameplayProperty(id: "fruit-orange-seed-skin", typeID: "seed-skin", value: "Bumpy peel; some have seeds", explanation: "The peel comes off before eating the juicy parts."),
                GameplayProperty(id: "fruit-orange-grows-on", typeID: "grows-on", value: "Tree", explanation: "Oranges grow on citrus trees."),
                GameplayProperty(id: "fruit-orange-grow-climate", typeID: "grow-climate", value: "Warm citrus groves", explanation: "Oranges grow well in warm places with plenty of sun."),
                GameplayProperty(id: "fruit-orange-origin", typeID: "origin", value: "East and Southeast Asia", explanation: "Sweet oranges came from citrus grown in Asia long ago."),
                GameplayProperty(id: "fruit-orange-flavor", typeID: "flavor", value: "Sunny juice", explanation: "Orange flavor is juicy, bright, and a little zingy."),
                GameplayProperty(id: "fruit-orange-category", typeID: "category", value: "Citrus fruit", explanation: "Citrus fruits often smell fresh and taste tangy.")
            ]),
            GameplayEntity(id: "fruit-grape", name: "Grape", summary: "A small juicy fruit that grows in bunches.", visualKey: "🍇", properties: [
                GameplayProperty(id: "fruit-grape-name", typeID: "name", value: "Grape", explanation: "Grape is the fruit's name.", visualKey: "🍇"),
                GameplayProperty(id: "fruit-grape-color", typeID: "color", value: "Green, red, or purple", explanation: "Grapes can be green, red, or purple."),
                GameplayProperty(id: "fruit-grape-taste", typeID: "taste", value: "Sweet and juicy", explanation: "Grapes pop with sweet juice."),
                GameplayProperty(id: "fruit-grape-seed-skin", typeID: "seed-skin", value: "Thin skin; seeded or seedless", explanation: "Some grapes have tiny seeds, and some are grown seedless."),
                GameplayProperty(id: "fruit-grape-grows-on", typeID: "grows-on", value: "Vine", explanation: "Grapes grow in bunches on vines."),
                GameplayProperty(id: "fruit-grape-grow-climate", typeID: "grow-climate", value: "Sunny vineyards", explanation: "Grapes like sunny places and can grow in warm or mild climates."),
                GameplayProperty(id: "fruit-grape-origin", typeID: "origin", value: "Western Asia", explanation: "People have grown grapes around Western Asia and nearby regions since ancient times."),
                GameplayProperty(id: "fruit-grape-flavor", typeID: "flavor", value: "Juice pop", explanation: "Grape flavor is sweet, juicy, and pops in your mouth."),
                GameplayProperty(id: "fruit-grape-category", typeID: "category", value: "Vine fruit", explanation: "Vine fruits grow on long climbing stems.")
            ]),
            GameplayEntity(id: "fruit-watermelon", name: "Watermelon", summary: "A big melon with green rind and red juicy inside.", visualKey: "🍉", properties: [
                GameplayProperty(id: "fruit-watermelon-name", typeID: "name", value: "Watermelon", explanation: "Watermelon is the fruit's name.", visualKey: "🍉"),
                GameplayProperty(id: "fruit-watermelon-color", typeID: "color", value: "Green outside and red inside", explanation: "The rind is green, and the juicy middle is often red."),
                GameplayProperty(id: "fruit-watermelon-taste", typeID: "taste", value: "Sweet and watery", explanation: "Watermelon is full of sweet juice."),
                GameplayProperty(id: "fruit-watermelon-seed-skin", typeID: "seed-skin", value: "Hard rind with black or white seeds", explanation: "The rind protects the juicy fruit inside."),
                GameplayProperty(id: "fruit-watermelon-grows-on", typeID: "grows-on", value: "Vine on the ground", explanation: "Watermelons grow on vines that spread along the ground."),
                GameplayProperty(id: "fruit-watermelon-grow-climate", typeID: "grow-climate", value: "Hot sunny fields", explanation: "Watermelons grow best in warm fields with lots of sun."),
                GameplayProperty(id: "fruit-watermelon-origin", typeID: "origin", value: "Africa", explanation: "Watermelon ancestors grew in Africa."),
                GameplayProperty(id: "fruit-watermelon-flavor", typeID: "flavor", value: "Cool summer sip", explanation: "Watermelon flavor feels cool, sweet, and watery."),
                GameplayProperty(id: "fruit-watermelon-category", typeID: "category", value: "Melon", explanation: "Melons are large juicy fruits with rinds.")
            ]),
            GameplayEntity(id: "fruit-pineapple", name: "Pineapple", summary: "A tropical fruit with a spiky crown.", visualKey: "🍍", properties: [
                GameplayProperty(id: "fruit-pineapple-name", typeID: "name", value: "Pineapple", explanation: "Pineapple is the fruit's name.", visualKey: "🍍"),
                GameplayProperty(id: "fruit-pineapple-color", typeID: "color", value: "Gold and green", explanation: "Pineapple has golden fruit and green leaves."),
                GameplayProperty(id: "fruit-pineapple-taste", typeID: "taste", value: "Sweet and tangy", explanation: "Pineapple tastes sweet with a bright tang."),
                GameplayProperty(id: "fruit-pineapple-seed-skin", typeID: "seed-skin", value: "Tough spiky skin; tiny seeds", explanation: "The rough outside protects the sweet fruit."),
                GameplayProperty(id: "fruit-pineapple-grows-on", typeID: "grows-on", value: "Low plant", explanation: "Pineapples grow from low plants near the ground."),
                GameplayProperty(id: "fruit-pineapple-grow-climate", typeID: "grow-climate", value: "Warm tropical farms", explanation: "Pineapples like warm tropical places and do not like frost."),
                GameplayProperty(id: "fruit-pineapple-origin", typeID: "origin", value: "South America", explanation: "Pineapple ancestors came from South America."),
                GameplayProperty(id: "fruit-pineapple-flavor", typeID: "flavor", value: "Sweet tang sparkle", explanation: "Pineapple flavor is sweet with a tangy sparkle."),
                GameplayProperty(id: "fruit-pineapple-category", typeID: "category", value: "Tropical fruit", explanation: "Pineapples like warm tropical places." )
            ]),
            GameplayEntity(id: "fruit-strawberry", name: "Strawberry", summary: "A red berry-like fruit with tiny seeds on the outside.", visualKey: "🍓", properties: [
                GameplayProperty(id: "fruit-strawberry-name", typeID: "name", value: "Strawberry", explanation: "Strawberry is the fruit's name.", visualKey: "🍓"),
                GameplayProperty(id: "fruit-strawberry-color", typeID: "color", value: "Red", explanation: "Ripe strawberries are usually bright red."),
                GameplayProperty(id: "fruit-strawberry-taste", typeID: "taste", value: "Sweet and a little tart", explanation: "Tart means a tiny sour sparkle with the sweet taste."),
                GameplayProperty(id: "fruit-strawberry-seed-skin", typeID: "seed-skin", value: "Tiny seeds on the outside", explanation: "Strawberries carry many tiny seeds on their outside."),
                GameplayProperty(id: "fruit-strawberry-grows-on", typeID: "grows-on", value: "Low plant", explanation: "Strawberries grow on low plants close to the ground."),
                GameplayProperty(id: "fruit-strawberry-grow-climate", typeID: "grow-climate", value: "Cool-to-mild gardens", explanation: "Strawberries can grow in cooler gardens and mild farms."),
                GameplayProperty(id: "fruit-strawberry-origin", typeID: "origin", value: "Europe and the Americas", explanation: "Garden strawberries came from strawberry plants from Europe and the Americas."),
                GameplayProperty(id: "fruit-strawberry-flavor", typeID: "flavor", value: "Berry jam", explanation: "Strawberry flavor is sweet, a little tart, and jammy."),
                GameplayProperty(id: "fruit-strawberry-category", typeID: "category", value: "Berry-like fruit", explanation: "Kids often call it a berry because it is small, soft, and juicy.")
            ])
        ],
        stages: [
            GameplayStageDefinition(id: "fruit-flashcards", kind: .flashcards, title: "Look + Learn", prompt: "Meet each fruit and its clues.", maximumItemCount: 8),
            GameplayStageDefinition(id: "fruit-easy-memory", kind: .easyMemory, title: "Easy Memory", prompt: "Match fruits to taste and grow clues.", propertyTypeIDs: ["name", "taste", "grows-on", "grow-climate"], maximumItemCount: 6),
            GameplayStageDefinition(id: "fruit-flip-memory", kind: .flipMemory, title: "Flip Memory", prompt: "Remember fruit colors, origins, and flavors.", propertyTypeIDs: ["color", "taste", "flavor", "origin"], maximumItemCount: 6),
            GameplayStageDefinition(id: "fruit-bond-blast", kind: .bondBlast, title: "Bond Blast", prompt: "Connect fruit tastes, origins, climates, seeds, skins, and grow clues.", propertyTypeIDs: ["taste", "flavor", "seed-skin", "grows-on", "grow-climate", "origin", "category"], maximumItemCount: 8),
            GameplayStageDefinition(id: "fruit-quiz", kind: .multipleChoice, title: "Fruit Quiz", prompt: "Pick the best fruit property.", propertyTypeIDs: ["color", "taste", "flavor", "seed-skin", "grows-on", "grow-climate", "origin"], maximumItemCount: 6)
        ],
        progressionPolicy: GameplayProgressionPolicy(minimumAccuracyToAdvance: 0.72, retryMissedItemsFirst: true)
    )


    /// Kid-safe electronics cards for the Lab's first playable circuit activity.
    /// The facts stay elementary: pretend battery, bulb, wire, switch, open/closed loop, and gentle safety.
    static let electronics: GameplayThreadDefinition = GameplayThreadDefinition(
        id: "electronics",
        title: "Circuit Spark",
        category: GameplayCategory(
            id: "electronics",
            title: "Electronics",
            subtitle: "Pretend batteries, bulbs, wires, switches, open and closed circuits, and safety"
        ),
        propertyTypes: [
            GameplayPropertyType(id: "part", displayName: "Part", prompt: "Find the safe circuit part."),
            GameplayPropertyType(id: "job", displayName: "Job", prompt: "Find what this part does."),
            GameplayPropertyType(id: "rule", displayName: "Rule", prompt: "Find the safe circuit rule."),
        ],
        entities: [
            GameplayEntity(id: "electronics-battery", name: "Battery", summary: "A pretend game battery gives a tiny circuit its power.", visualKey: "🔋", properties: [
                GameplayProperty(id: "electronics-battery-part", typeID: "part", value: "Battery", explanation: "The battery is the safe pretend power part in this game.", visualKey: "🔋"),
                GameplayProperty(id: "electronics-battery-job", typeID: "job", value: "Gives power", explanation: "The pretend battery can help the light turn on."),
                GameplayProperty(id: "electronics-battery-rule", typeID: "rule", value: "Game batteries are pretend", explanation: "Batteries in this game are pretend and safe to play with on the screen."),
            ]),
            GameplayEntity(id: "electronics-bulb", name: "Bulb", summary: "A bulb or light turns on when the pretend circuit is closed.", visualKey: "💡", properties: [
                GameplayProperty(id: "electronics-bulb-part", typeID: "part", value: "Bulb or light", explanation: "The bulb is the light-making part.", visualKey: "💡"),
                GameplayProperty(id: "electronics-bulb-job", typeID: "job", value: "Makes light", explanation: "The light can shine when the path is complete."),
                GameplayProperty(id: "electronics-bulb-rule", typeID: "rule", value: "Light on in closed circuit", explanation: "The light turns on when the wire path makes a full loop."),
            ]),
            GameplayEntity(id: "electronics-wire", name: "Wire", summary: "A wire makes the path from the battery to the light and back.", visualKey: "➰", properties: [
                GameplayProperty(id: "electronics-wire-part", typeID: "part", value: "Wire", explanation: "A wire is the path part.", visualKey: "➰"),
                GameplayProperty(id: "electronics-wire-job", typeID: "job", value: "Makes a path", explanation: "A wire joins the battery, switch, and light."),
                GameplayProperty(id: "electronics-wire-rule", typeID: "rule", value: "Path must meet both ends", explanation: "The wire path needs to meet both ends of the pretend battery."),
            ]),
            GameplayEntity(id: "electronics-switch", name: "Switch", summary: "A switch opens or closes the pretend circuit path.", visualKey: "⏻", properties: [
                GameplayProperty(id: "electronics-switch-part", typeID: "part", value: "Switch", explanation: "The switch is the open-close part.", visualKey: "⏻"),
                GameplayProperty(id: "electronics-switch-job", typeID: "job", value: "Opens or closes", explanation: "A switch can connect the path or make a gap."),
                GameplayProperty(id: "electronics-switch-rule", typeID: "rule", value: "Closed switch can turn on", explanation: "When the switch closes, the path can be complete."),
            ]),
            GameplayEntity(id: "electronics-closed-circuit", name: "Closed Circuit", summary: "A closed circuit is a full loop from battery to light and back.", visualKey: "↻", properties: [
                GameplayProperty(id: "electronics-closed-circuit-part", typeID: "part", value: "Closed loop", explanation: "The wire path comes all the way back."),
                GameplayProperty(id: "electronics-closed-circuit-job", typeID: "job", value: "Lets power reach the light", explanation: "A full loop lets the pretend battery help the light."),
                GameplayProperty(id: "electronics-closed-circuit-rule", typeID: "rule", value: "Bulb on", explanation: "A complete path can turn the bulb on."),
            ]),
            GameplayEntity(id: "electronics-open-circuit", name: "Open Circuit", summary: "An open circuit has a gap, so the pretend light stays off.", visualKey: "⛔", properties: [
                GameplayProperty(id: "electronics-open-circuit-part", typeID: "part", value: "Broken path", explanation: "A gap breaks the circuit path."),
                GameplayProperty(id: "electronics-open-circuit-job", typeID: "job", value: "Keeps light off", explanation: "The pretend power cannot go around a path with a gap."),
                GameplayProperty(id: "electronics-open-circuit-rule", typeID: "rule", value: "Bulb off", explanation: "A broken path keeps the bulb off."),
            ]),
            GameplayEntity(id: "electronics-safe-circuit", name: "Safe Game Circuit", summary: "The circuits here are pretend screen circuits made for play.", visualKey: "✅", properties: [
                GameplayProperty(id: "electronics-safe-circuit-part", typeID: "part", value: "Pretend circuit", explanation: "This game uses pretend parts on the screen.", visualKey: "✅"),
                GameplayProperty(id: "electronics-safe-circuit-job", typeID: "job", value: "Safe to try here", explanation: "It is safe to tap and try the circuit parts in this game."),
                GameplayProperty(id: "electronics-safe-circuit-rule", typeID: "rule", value: "Screen play is safe", explanation: "Build circuits in the game, not with real plug points."),
            ]),
            GameplayEntity(id: "electronics-outlet-safety", name: "Outlet Safety", summary: "Plug points and outlets are grown-up only. Ask a grown-up and do not touch them.", visualKey: "🛑", properties: [
                GameplayProperty(id: "electronics-outlet-safety-part", typeID: "part", value: "Plug point or outlet", explanation: "A plug point or outlet is for grown-ups.", visualKey: "🛑"),
                GameplayProperty(id: "electronics-outlet-safety-job", typeID: "job", value: "Ask a grown-up", explanation: "Ask a grown-up before anything near a plug point or outlet."),
                GameplayProperty(id: "electronics-outlet-safety-rule", typeID: "rule", value: "Do not touch outlets", explanation: "Do not touch plug points or outlets. Use the safe pretend battery in this game."),
            ]),
        ],
        stages: [
            GameplayStageDefinition(id: "electronics-flashcards", kind: .flashcards, title: "Spark Cards", prompt: "Meet safe circuit parts, jobs, and rules.", maximumItemCount: 8),
            GameplayStageDefinition(id: "electronics-easy-memory", kind: .easyMemory, title: "Symbol Match", prompt: "Match each circuit symbol to its part name.", propertyTypeIDs: ["part"], maximumItemCount: 8),
            GameplayStageDefinition(id: "electronics-flip-memory", kind: .flipMemory, title: "Rule Flip", prompt: "Remember open, closed, and safety rules.", propertyTypeIDs: ["job", "rule"], maximumItemCount: 6),
            GameplayStageDefinition(id: "electronics-bond-blast", kind: .bondBlast, title: "Circuit Blast", prompt: "Connect safe parts, jobs, and rules.", propertyTypeIDs: ["part", "job", "rule"], maximumItemCount: 8),
            GameplayStageDefinition(id: "electronics-quiz", kind: .multipleChoice, title: "Spark Quiz", prompt: "Pick the best safe circuit clue.", propertyTypeIDs: ["job", "rule"], maximumItemCount: 6),
        ],
        progressionPolicy: GameplayProgressionPolicy(minimumAccuracyToAdvance: 0.70, retryMissedItemsFirst: true)
    )

}
