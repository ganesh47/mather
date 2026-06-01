import Testing
@testable import Mather

struct FactoryCardsViewTests {
    @Test
    func firstLookGateIsRequiredForEachNewCardUntilRoundCompletes() {
        #expect(FactoryCardsView.shouldRequireFirstLook(forAdvancedIndex: 1, totalSteps: 3))
        #expect(FactoryCardsView.shouldRequireFirstLook(forAdvancedIndex: 2, totalSteps: 3))
        #expect(!FactoryCardsView.shouldRequireFirstLook(forAdvancedIndex: 3, totalSteps: 3))
    }
}
