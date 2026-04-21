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
    @Test func longestCurrentLabelsHaveFallbackHeadroom() {
        let labels = (MemoryDeck.domesticAnimals + MemoryDeck.birds + MemoryDeck.vehicles).map(\.name)
        let longestLabel = labels.max { $0.count < $1.count }
        #expect(longestLabel == "Blackbird")
        #expect(longestLabel?.count == 9)
        #expect(MemoryView.labelMinimumScaleFactor(for: .hard) >= 0.68)
    }
}
