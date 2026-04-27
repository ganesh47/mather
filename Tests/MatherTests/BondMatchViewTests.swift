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


    @Test func dragReleaseResolutionOnlyMatchesWhenDroppedOnCorrectRow() {
        let state = BondMatchState(target: 6, pairs: BondMatchState.makePairs(for: 6))
        let pair = state.pairs[0] // 1 + 5
        let correct = BondMatchView.dragReleaseResolution(
            pair: pair,
            translation: CGSize(width: 120, height: 0),
            state: state,
            shuffledRightValues: state.pairs.map(\.right),
            cardSize: 88,
            cardSpacing: 12
        )
        #expect(correct == .match(pair.id))
    }

    @Test func dragReleaseResolutionDoesNotAutoMatchWrongLandingRow() {
        let state = BondMatchState(target: 6, pairs: BondMatchState.makePairs(for: 6))
        let pair = state.pairs[0] // wants 5
        let shuffled = [4, 5, 3]
        let wrongDrop = BondMatchView.dragReleaseResolution(
            pair: pair,
            translation: CGSize(width: 120, height: 0),
            state: state,
            shuffledRightValues: shuffled,
            cardSize: 88,
            cardSpacing: 12
        )
        #expect(wrongDrop == .mismatch(4))
    }

    @Test func lowTargetsKeepAllUniquePairs() {
        let pairs = BondMatchState.makePairs(for: 20)

        #expect(pairs.count == 10)
        #expect(pairs.map(\.left) == Array(1...10))
        #expect(pairs.allSatisfy { $0.left + $0.right == 20 })
    }

    @Test func highTargetsUseSmallExactPairSample() {
        let pairs = BondMatchState.makePairs(for: 1000)

        #expect(pairs.count <= BondMatchState.highTargetPairLimit)
        #expect(!pairs.isEmpty)
        #expect(pairs.allSatisfy { $0.left <= $0.right })
        #expect(pairs.allSatisfy { $0.left + $0.right == 1000 })
    }
}
