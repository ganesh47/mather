import Foundation

struct CountryCardFact: Identifiable, Equatable, Hashable {
    let id: String
    let name: String
    let capital: String
    let language: String
    let flagEmoji: String
    let currency: String
    let mapShape: String
    let continent: String
    let mapClue: String

    var accessibilitySummary: String {
        "\(name), capital \(capital), language \(language), flag \(flagEmoji), currency \(currency), shape \(mapShape), continent \(continent)."
    }
}

enum CountryCardFacet: String, CaseIterable, Identifiable, Equatable {
    case countryName = "Country"
    case capital = "Capital"
    case language = "Language"
    case flag = "Flag"
    case currency = "Currency"
    case mapShape = "Map shape"

    var id: String { rawValue }
}

struct CountryFlashcard: Identifiable, Equatable {
    let country: CountryCardFact
    let facet: CountryCardFacet

    var id: String { "\(country.id)-\(facet.id)" }

    var prompt: String {
        switch facet {
        case .countryName:
            return "Which country is this?"
        case .capital:
            return "Capital of \(country.name)"
        case .language:
            return "Language clue"
        case .flag:
            return "Flag flashcard"
        case .currency:
            return "Currency used"
        case .mapShape:
            return "Shape on the map"
        }
    }

    var answer: String {
        switch facet {
        case .countryName:
            return country.name
        case .capital:
            return country.capital
        case .language:
            return country.language
        case .flag:
            return "\(country.flagEmoji) \(country.name)"
        case .currency:
            return country.currency
        case .mapShape:
            return country.mapShape
        }
    }

    var detail: String {
        switch facet {
        case .countryName:
            return "Find \(country.name) in \(country.continent)."
        case .capital:
            return "\(country.capital) is the capital city."
        case .language:
            return "A common language: \(country.language)."
        case .flag:
            return "Look for the flag colors and symbol."
        case .currency:
            return "Money clue: \(country.currency)."
        case .mapShape:
            return country.mapClue
        }
    }
}

enum CountryCardsDeck {
    static let starterCountries: [CountryCardFact] = [
        CountryCardFact(id: "india", name: "India", capital: "New Delhi", language: "Hindi and English", flagEmoji: "🇮🇳", currency: "Indian rupee", mapShape: "diamond kite with a long south point", continent: "Asia", mapClue: "Look for the triangle-like peninsula pointing into the Indian Ocean."),
        CountryCardFact(id: "japan", name: "Japan", capital: "Tokyo", language: "Japanese", flagEmoji: "🇯🇵", currency: "Japanese yen", mapShape: "curved island chain", continent: "Asia", mapClue: "Look for a thin chain of islands east of Asia."),
        CountryCardFact(id: "france", name: "France", capital: "Paris", language: "French", flagEmoji: "🇫🇷", currency: "Euro", mapShape: "hexagon", continent: "Europe", mapClue: "France is often nicknamed the hexagon."),
        CountryCardFact(id: "egypt", name: "Egypt", capital: "Cairo", language: "Arabic", flagEmoji: "🇪🇬", currency: "Egyptian pound", mapShape: "square corner with Nile ribbon", continent: "Africa", mapClue: "Find the Nile River running north to the Mediterranean Sea."),
        CountryCardFact(id: "brazil", name: "Brazil", capital: "Brasília", language: "Portuguese", flagEmoji: "🇧🇷", currency: "Brazilian real", mapShape: "large east-bulging shield", continent: "South America", mapClue: "It is the biggest country in South America and reaches the Atlantic."),
        CountryCardFact(id: "australia", name: "Australia", capital: "Canberra", language: "English", flagEmoji: "🇦🇺", currency: "Australian dollar", mapShape: "wide island continent", continent: "Australia", mapClue: "It is the large island continent between the Indian and Pacific oceans.")
    ]

    static let continents: [String] = ["Africa", "Asia", "Australia", "Europe", "North America", "South America"]

    static var deterministicFlashcards: [CountryFlashcard] {
        starterCountries.flatMap { country in
            CountryCardFacet.allCases.map { facet in
                CountryFlashcard(country: country, facet: facet)
            }
        }
    }

    static func country(id: String) -> CountryCardFact? {
        starterCountries.first { $0.id == id }
    }
}

struct CountryContinentBucketGame: Equatable {
    private(set) var placedCountryIDs: Set<String> = []

    var remainingCountries: [CountryCardFact] {
        CountryCardsDeck.starterCountries.filter { !placedCountryIDs.contains($0.id) }
    }

    var completionLabel: String {
        "\(placedCountryIDs.count) / \(CountryCardsDeck.starterCountries.count) countries sorted"
    }

    func continent(for countryID: String) -> String? {
        CountryCardsDeck.country(id: countryID)?.continent
    }

    func isCorrectPlacement(countryID: String, continent: String) -> Bool {
        self.continent(for: countryID) == continent
    }

    mutating func place(countryID: String, in continent: String) -> Bool {
        guard isCorrectPlacement(countryID: countryID, continent: continent) else { return false }
        placedCountryIDs.insert(countryID)
        return true
    }
}
