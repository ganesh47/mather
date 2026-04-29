import Testing
@testable import Mather

@Suite("MemoryTextFit")
struct MemoryTextFitTests {

    @MainActor
    @Test func labelFontSizeStepsDownAsGridGetsTighter() {
        #expect(MemoryView.labelFontSize(for: .easy) > MemoryView.labelFontSize(for: .medium))
        #expect(MemoryView.labelFontSize(for: .medium) > MemoryView.labelFontSize(for: .hard))
    }

    @MainActor
    @Test func labelPaddingShrinksForDenserLayouts() {
        #expect(MemoryView.labelHorizontalPadding(for: .easy) > MemoryView.labelHorizontalPadding(for: .medium))
        #expect(MemoryView.labelHorizontalPadding(for: .medium) > MemoryView.labelHorizontalPadding(for: .hard))
    }

    @MainActor
    @Test func minimumScaleFactorGetsMorePermissiveInHardMode() {
        #expect(MemoryView.labelMinimumScaleFactor(for: .easy) > MemoryView.labelMinimumScaleFactor(for: .medium))
        #expect(MemoryView.labelMinimumScaleFactor(for: .medium) > MemoryView.labelMinimumScaleFactor(for: .hard))
    }


    @MainActor
    @Test func birdLabelsStayWithinReasonableFallbackRange() {
        let labels = (MemoryDeck.domesticAnimals + MemoryDeck.birds + MemoryDeck.vehicles + MemoryDeck.planets + MemoryDeck.fishes + MemoryDeck.countries + MemoryDeck.countryFlags + MemoryDeck.indiaStates + MemoryDeck.waterCycle).map(\.name)
        let longestLabel = labels.max { $0.count < $1.count }
        #expect(longestLabel == "Thiruvananthapuram")
        #expect(longestLabel?.count == 18)
        #expect(MemoryDeck.waterCycle.map(\.name).contains("Condensation"))
        #expect(MemoryDeck.waterCycle.map(\.name).contains("Precipitation"))
        #expect(MemoryView.labelMinimumScaleFactor(for: .hard) >= 0.58)

        let longestBirdFact = MemoryDeck.birds
            .flatMap(\.detailCards)
            .map(\.value)
            .max { $0.count < $1.count }
        #expect(longestBirdFact == "Woodland streams in Africa and Asia")
        #expect(longestBirdFact?.count == 35)
    }
}
