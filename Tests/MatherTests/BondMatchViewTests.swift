import Foundation
import Testing
@testable import Mather

struct BondMatchViewTests {
    @Test func hidesUnmatchedRightValuesUntilSelection() {
        let state = BondMatchState(target: 6, pairs: BondMatchState.makePairs(for: 6))
        let right = state.pairs[0].right
        #expect(BondMatchView.visibleRightValue(selectedPairId: nil, rightValue: right, state: state) == nil)
    }

    @Test func revealsRightValuesAfterSelection() {
        let state = BondMatchState(target: 6, pairs: BondMatchState.makePairs(for: 6))
        let selected = state.pairs[0].id
        let right = state.pairs[1].right
        #expect(BondMatchView.visibleRightValue(selectedPairId: selected, rightValue: right, state: state) == right)
    }

    @Test func matchedRightValuesStayVisibleWithoutSelection() {
        var state = BondMatchState(target: 6, pairs: BondMatchState.makePairs(for: 6))
        state.pairs[0].isMatched = true
        let right = state.pairs[0].right
        #expect(BondMatchView.visibleRightValue(selectedPairId: nil, rightValue: right, state: state) == right)
    }
}
