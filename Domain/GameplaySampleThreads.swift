import Foundation

enum GameplaySampleThreads {
    static let countries: GameplayThreadDefinition = GameplayThreadDefinition(
        id: "sample-countries-gameplay-thread",
        title: "Countries Quest",
        category: GameplayCategory(id: "geography", title: "Geography", subtitle: "Countries and clues"),
        propertyTypes: [
            GameplayPropertyType(id: "capital", displayName: "Capital", prompt: "Find the capital."),
            GameplayPropertyType(id: "continent", displayName: "Continent", prompt: "Find the continent."),
            GameplayPropertyType(id: "currency", displayName: "Currency", prompt: "Find the money clue.")
        ],
        entities: [
            GameplayEntity(id: "country-india", name: "India", summary: "A large country in Asia.", visualKey: "🇮🇳", properties: [
                GameplayProperty(id: "country-india-capital", typeID: "capital", value: "New Delhi", explanation: "New Delhi is India’s capital city."),
                GameplayProperty(id: "country-india-continent", typeID: "continent", value: "Asia"),
                GameplayProperty(id: "country-india-currency", typeID: "currency", value: "Indian rupee")
            ]),
            GameplayEntity(id: "country-japan", name: "Japan", summary: "An island country in Asia.", visualKey: "🇯🇵", properties: [
                GameplayProperty(id: "country-japan-capital", typeID: "capital", value: "Tokyo"),
                GameplayProperty(id: "country-japan-continent", typeID: "continent", value: "Asia"),
                GameplayProperty(id: "country-japan-currency", typeID: "currency", value: "Yen")
            ]),
            GameplayEntity(id: "country-france", name: "France", summary: "A country in Europe.", visualKey: "🇫🇷", properties: [
                GameplayProperty(id: "country-france-capital", typeID: "capital", value: "Paris"),
                GameplayProperty(id: "country-france-continent", typeID: "continent", value: "Europe"),
                GameplayProperty(id: "country-france-currency", typeID: "currency", value: "Euro")
            ]),
            GameplayEntity(id: "country-brazil", name: "Brazil", summary: "A big country in South America.", visualKey: "🇧🇷", properties: [
                GameplayProperty(id: "country-brazil-capital", typeID: "capital", value: "Brasília"),
                GameplayProperty(id: "country-brazil-continent", typeID: "continent", value: "South America"),
                GameplayProperty(id: "country-brazil-currency", typeID: "currency", value: "Brazilian real")
            ])
        ],
        stages: [
            GameplayStageDefinition(id: "flashcards", kind: .flashcards, title: "Look + Learn", prompt: "Meet each country.", maximumItemCount: 4),
            GameplayStageDefinition(id: "easy-memory", kind: .easyMemory, title: "Easy Memory", prompt: "Match countries to clues.", propertyTypeIDs: ["capital"], maximumItemCount: 4),
            GameplayStageDefinition(id: "flip-memory", kind: .flipMemory, title: "Flip Memory", prompt: "Flip and remember each match.", propertyTypeIDs: ["continent"], maximumItemCount: 4),
            GameplayStageDefinition(id: "bond-blast", kind: .bondBlast, title: "Bond Blast", prompt: "Connect every country to its fact.", propertyTypeIDs: ["capital", "currency"], maximumItemCount: 6),
            GameplayStageDefinition(id: "multiple-choice", kind: .multipleChoice, title: "Quiz", prompt: "Pick the best answer.", propertyTypeIDs: ["capital"], maximumItemCount: 4)
        ]
    )
}
