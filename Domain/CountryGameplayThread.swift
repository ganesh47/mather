import Foundation

enum CountryGameplayThread {
    static let thread = GameplayThreadDefinition(
        id: "countries",
        title: "Country Cards",
        category: GameplayCategory(
            id: "geography",
            title: "Geography",
            subtitle: "Countries, flags, capitals, maps, languages, and money"
        ),
        propertyTypes: [
            GameplayPropertyType(id: "capital", displayName: "Capital", prompt: "Which capital city belongs to this country?"),
            GameplayPropertyType(id: "currency", displayName: "Currency", prompt: "Which money is used here?"),
            GameplayPropertyType(id: "flag", displayName: "Flag", prompt: "Which flag belongs to this country?"),
            GameplayPropertyType(id: "map-shape", displayName: "Map Shape", prompt: "Which map-shape clue fits this country?"),
            GameplayPropertyType(id: "continent", displayName: "Continent", prompt: "Which continent is this country on?"),
            GameplayPropertyType(id: "language", displayName: "Language", prompt: "Which language clue fits this country?"),
            GameplayPropertyType(id: "clue", displayName: "Clue", prompt: "Which clue is this country known for?")
        ],
        entities: [
            country(
                id: "country-india",
                name: "India",
                flagEmoji: "🇮🇳",
                flagAsset: "MemoryFlagIndia",
                summary: "India is a large country in Asia, home of the Taj Mahal.",
                capital: "New Delhi",
                currency: "Indian rupee",
                mapShape: "wide triangle-like peninsula",
                continent: "Asia",
                language: "Hindi and English",
                knownFor: "home of the Taj Mahal"
            ),
            country(
                id: "country-japan",
                name: "Japan",
                flagEmoji: "🇯🇵",
                flagAsset: "MemoryFlagJapan",
                summary: "Japan is a long island chain in Asia.",
                capital: "Tokyo",
                currency: "yen",
                mapShape: "long island chain",
                continent: "Asia",
                language: "Japanese",
                knownFor: "known for cherry blossoms and bullet trains"
            ),
            country(
                id: "country-france",
                name: "France",
                flagEmoji: "🇫🇷",
                flagAsset: "MemoryFlagFrance",
                summary: "France is a European country with a hexagon-like outline.",
                capital: "Paris",
                currency: "euro",
                mapShape: "hexagon-like outline",
                continent: "Europe",
                language: "French",
                knownFor: "home of the Eiffel Tower"
            ),
            country(
                id: "country-egypt",
                name: "Egypt",
                flagEmoji: "🇪🇬",
                flagAsset: "MemoryFlagEgypt",
                summary: "Egypt is in Africa and is home of the Great Pyramids.",
                capital: "Cairo",
                currency: "Egyptian pound",
                mapShape: "square-like shape with Sinai corner",
                continent: "Africa",
                language: "Arabic",
                knownFor: "home of the Great Pyramids"
            ),
            country(
                id: "country-brazil",
                name: "Brazil",
                flagEmoji: "🇧🇷",
                flagAsset: "MemoryFlagBrazil",
                summary: "Brazil is a large South American country with the Amazon rainforest.",
                capital: "Brasília",
                currency: "Brazilian real",
                mapShape: "large east-bulging outline",
                continent: "South America",
                language: "Portuguese",
                knownFor: "home of the Amazon rainforest"
            ),
            country(
                id: "country-australia",
                name: "Australia",
                flagEmoji: "🇦🇺",
                flagAsset: "MemoryFlagAustralia",
                summary: "Australia is a big island continent with kangaroos and koalas.",
                capital: "Canberra",
                currency: "Australian dollar",
                mapShape: "big island continent",
                continent: "Australia",
                language: "English",
                knownFor: "home of kangaroos and koalas"
            ),
            country(
                id: "country-canada",
                name: "Canada",
                flagEmoji: "🇨🇦",
                flagAsset: "MemoryFlagCanada",
                summary: "Canada is a very wide northern country in North America.",
                capital: "Ottawa",
                currency: "Canadian dollar",
                mapShape: "very wide northern outline",
                continent: "North America",
                language: "English and French",
                knownFor: "known for maple leaves and snowy winters"
            ),
            country(
                id: "country-kenya",
                name: "Kenya",
                flagEmoji: "🇰🇪",
                flagAsset: "MemoryFlagKenya",
                summary: "Kenya is in east Africa by the Indian Ocean.",
                capital: "Nairobi",
                currency: "Kenyan shilling",
                mapShape: "east Africa shape by the Indian Ocean",
                continent: "Africa",
                language: "Swahili and English",
                knownFor: "known for savannas and wildlife parks"
            ),
            country(
                id: "country-united-states",
                name: "United States",
                flagEmoji: "🇺🇸",
                summary: "The United States is a wide country in North America between two oceans.",
                capital: "Washington, D.C.",
                currency: "United States dollar",
                mapShape: "wide country between the Atlantic and Pacific Oceans",
                continent: "North America",
                language: "English",
                knownFor: "known for national parks, jazz music, and space rockets"
            ),
            country(
                id: "country-united-kingdom",
                name: "United Kingdom",
                flagEmoji: "🇬🇧",
                summary: "The United Kingdom is an island country in Europe.",
                capital: "London",
                currency: "pound sterling",
                mapShape: "island group in northwest Europe",
                continent: "Europe",
                language: "English",
                knownFor: "known for castles, Big Ben, and rainy weather"
            ),
            country(
                id: "country-china",
                name: "China",
                flagEmoji: "🇨🇳",
                summary: "China is a very large country in east Asia.",
                capital: "Beijing",
                currency: "Chinese yuan",
                mapShape: "large east Asia outline",
                continent: "Asia",
                language: "Mandarin Chinese",
                knownFor: "home of the Great Wall"
            ),
            country(
                id: "country-germany",
                name: "Germany",
                flagEmoji: "🇩🇪",
                summary: "Germany is a country in central Europe with forests, rivers, and busy cities.",
                capital: "Berlin",
                currency: "euro",
                mapShape: "central Europe outline",
                continent: "Europe",
                language: "German",
                knownFor: "known for inventions, forests, and castles"
            ),
            country(
                id: "country-mexico",
                name: "Mexico",
                flagEmoji: "🇲🇽",
                summary: "Mexico is in North America and has deserts, mountains, beaches, and ancient pyramids.",
                capital: "Mexico City",
                currency: "Mexican peso",
                mapShape: "long country south of the United States",
                continent: "North America",
                language: "Spanish",
                knownFor: "known for ancient pyramids, mariachi music, and monarch butterflies"
            ),
            country(
                id: "country-south-africa",
                name: "South Africa",
                flagEmoji: "🇿🇦",
                summary: "South Africa sits at the southern tip of Africa where two oceans meet.",
                capital: "Pretoria",
                currency: "South African rand",
                mapShape: "southern tip of Africa",
                continent: "Africa",
                language: "Zulu, Xhosa, Afrikaans, English, and more",
                knownFor: "known for Table Mountain, wildlife, and many languages"
            ),
            country(
                id: "country-italy",
                name: "Italy",
                flagEmoji: "🇮🇹",
                summary: "Italy is a boot-shaped country in southern Europe.",
                capital: "Rome",
                currency: "euro",
                mapShape: "boot-shaped peninsula",
                continent: "Europe",
                language: "Italian",
                knownFor: "home of the Colosseum, pasta, and volcanoes"
            ),
            country(
                id: "country-saudi-arabia",
                name: "Saudi Arabia",
                flagEmoji: "🇸🇦",
                summary: "Saudi Arabia is a large desert country on the Arabian Peninsula in Asia.",
                capital: "Riyadh",
                currency: "Saudi riyal",
                mapShape: "large Arabian Peninsula outline",
                continent: "Asia",
                language: "Arabic",
                knownFor: "known for deserts, date palms, and the Red Sea coast"
            )
        ],
        stages: [
            GameplayStageDefinition(id: "flashcards", kind: .flashcards, title: "Look + Learn", prompt: "Meet each country, flag, capital, map clue, language, and money.", maximumItemCount: 8),
            GameplayStageDefinition(id: "easy-memory", kind: .easyMemory, title: "Easy Memory", prompt: "Start with one focused round matching each flag to its country name.", propertyTypeIDs: ["flag"], maximumItemCount: 8),
            GameplayStageDefinition(id: "flip-memory", kind: .flipMemory, title: "Flip Memory", prompt: "Flip and remember flags, capitals, and currencies.", propertyTypeIDs: ["flag", "capital", "currency"], maximumItemCount: 8),
            GameplayStageDefinition(id: "bond-blast", kind: .bondBlast, title: "Bond Blast", prompt: "Connect each country to mixed facts.", propertyTypeIDs: ["capital", "currency", "continent", "language", "map-shape"], maximumItemCount: 10),
            GameplayStageDefinition(id: "multiple-choice", kind: .multipleChoice, title: "Quiz", prompt: "Pick the best country fact.", propertyTypeIDs: ["capital", "currency", "flag", "map-shape", "continent", "language"], maximumItemCount: 12)
        ]
    )

    private static func country(
        id: String,
        name: String,
        flagEmoji: String,
        flagAsset: String? = nil,
        summary: String,
        capital: String,
        currency: String,
        mapShape: String,
        continent: String,
        language: String,
        knownFor: String
    ) -> GameplayEntity {
        GameplayEntity(
            id: id,
            name: name,
            summary: summary,
            visualKey: flagEmoji,
            visualAssetName: flagAsset,
            properties: [
                property(entityID: id, typeID: "capital", value: capital, explanation: "The capital of \(name) is \(capital).", visualKey: "🏛️"),
                property(entityID: id, typeID: "currency", value: currency, explanation: "\(name) uses \(currency).", visualKey: "💰"),
                property(entityID: id, typeID: "flag", value: "\(name) flag", explanation: "This is the flag of \(name).", visualKey: flagEmoji, visualAssetName: flagAsset),
                property(entityID: id, typeID: "map-shape", value: mapShape, explanation: "A map clue for \(name): \(mapShape).", visualKey: "🗺️", visualShapeKey: id),
                property(entityID: id, typeID: "continent", value: continent, explanation: "\(name) is in \(continent).", visualKey: "🌍"),
                property(entityID: id, typeID: "language", value: language, explanation: "A language clue for \(name): \(language).", visualKey: "🗣️"),
                property(entityID: id, typeID: "clue", value: knownFor, explanation: "\(name) is \(knownFor).", visualKey: "✨")
            ]
        )
    }

    private static func property(
        entityID: String,
        typeID: String,
        value: String,
        explanation: String,
        visualKey: String? = nil,
        visualAssetName: String? = nil,
        visualShapeKey: String? = nil
    ) -> GameplayProperty {
        GameplayProperty(
            id: "\(entityID)-\(typeID)",
            typeID: typeID,
            value: value,
            explanation: explanation,
            visualKey: visualKey,
            visualAssetName: visualAssetName,
            visualShapeKey: visualShapeKey
        )
    }
}
