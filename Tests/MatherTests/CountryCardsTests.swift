import XCTest
@testable import Mather

final class CountryCardsTests: XCTestCase {
    func testStarterDeckCoversRequestedFlashcardFacts() {
        let countries = CountryCardsDeck.starterCountries

        XCTAssertEqual(countries.count, 6)
        XCTAssertTrue(countries.allSatisfy { !$0.name.isEmpty })
        XCTAssertTrue(countries.allSatisfy { !$0.capital.isEmpty })
        XCTAssertTrue(countries.allSatisfy { !$0.language.isEmpty })
        XCTAssertTrue(countries.allSatisfy { !$0.flagEmoji.isEmpty })
        XCTAssertTrue(countries.allSatisfy { !$0.currency.isEmpty })
        XCTAssertTrue(countries.allSatisfy { !$0.mapShape.isEmpty })
        XCTAssertTrue(countries.allSatisfy { CountryCardsDeck.continents.contains($0.continent) })
    }

    func testDeterministicFlashcardsIncludeEveryFacetForEveryCountry() {
        let flashcards = CountryCardsDeck.deterministicFlashcards

        XCTAssertEqual(flashcards.count, CountryCardsDeck.starterCountries.count * CountryCardFacet.allCases.count)
        XCTAssertEqual(flashcards.prefix(6).map(\.facet), CountryCardFacet.allCases)
        XCTAssertEqual(flashcards.first?.country.name, "India")
        XCTAssertEqual(flashcards.first { $0.country.id == "france" && $0.facet == .mapShape }?.answer, "hexagon")
        XCTAssertEqual(Set(flashcards.map(\.id)).count, flashcards.count)
    }

    func testContinentBucketGameOnlyAcceptsCorrectPlacements() {
        var game = CountryContinentBucketGame()

        XCTAssertFalse(game.place(countryID: "brazil", in: "Europe"))
        XCTAssertEqual(game.completionLabel, "0 / 6 countries sorted")
        XCTAssertTrue(game.place(countryID: "brazil", in: "South America"))
        XCTAssertEqual(game.completionLabel, "1 / 6 countries sorted")
        XCTAssertFalse(game.remainingCountries.contains { $0.id == "brazil" })
        XCTAssertEqual(game.continent(for: "japan"), "Asia")
    }
}
