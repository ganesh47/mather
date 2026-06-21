import Testing
import CoreGraphics
@testable import Mather

// ProtractorMath.angleDegrees(t1:t2:pivot:) measures the interior angle at `pivot`
// between the arms pivot→t1 and pivot→t2 using the atan2-subtraction formula.
// Result is always in [0, 180].

@Suite("TwoFingerProtractor")
struct TwoFingerProtractorTests {

    private let center = CGPoint(x: 200, y: 200)

    // MARK: - angleDegrees

    @Test func angle90DegreesOrthogonalArms() {
        // t1 directly right of pivot, t2 directly below — 90° between them
        let t1 = CGPoint(x: center.x + 100, y: center.y)        // 0°
        let t2 = CGPoint(x: center.x, y: center.y + 100)        // 270° (or -90°)
        let result = ProtractorMath.angleDegrees(t1: t1, t2: t2, pivot: center)
        #expect(abs(result - 90) < 1)
    }

    @Test func angle45Degrees() {
        // t1 at 0° (right), t2 at 45° (up-right)
        let t1 = CGPoint(x: center.x + 100, y: center.y)
        let t2 = CGPoint(x: center.x + 71, y: center.y - 71)    // ~45°
        let result = ProtractorMath.angleDegrees(t1: t1, t2: t2, pivot: center)
        #expect(abs(result - 45) < 1)
    }

    @Test func angle60Degrees() {
        let t1 = CGPoint(x: center.x + 100, y: center.y)
        let t2 = CGPoint(x: center.x + 50, y: center.y - 87)    // ~60°
        let result = ProtractorMath.angleDegrees(t1: t1, t2: t2, pivot: center)
        #expect(abs(result - 60) < 1.5)
    }

    @Test func angle120Degrees() {
        // t1 at 0°, t2 at 120° (120° apart)
        let r: Double = 100
        let t1 = CGPoint(x: center.x + r, y: center.y)
        let t2 = CGPoint(x: center.x + r * cos(120 * .pi / 180),
                         y: center.y + r * sin(120 * .pi / 180))
        let result = ProtractorMath.angleDegrees(t1: t1, t2: t2, pivot: center)
        #expect(abs(result - 120) < 1.5)
    }

    @Test func angle30Degrees() {
        let r: Double = 100
        let t1 = CGPoint(x: center.x + r, y: center.y)
        let t2 = CGPoint(x: center.x + r * cos(30 * .pi / 180),
                         y: center.y - r * sin(30 * .pi / 180))
        let result = ProtractorMath.angleDegrees(t1: t1, t2: t2, pivot: center)
        #expect(abs(result - 30) < 1)
    }

    @Test func angle180DegreesOppositeArms() {
        // t1 right, t2 left — straight line through pivot
        let t1 = CGPoint(x: center.x + 100, y: center.y)
        let t2 = CGPoint(x: center.x - 100, y: center.y)
        let result = ProtractorMath.angleDegrees(t1: t1, t2: t2, pivot: center)
        #expect(abs(result - 180) < 1)
    }

    @Test func angle0DegreesParallelArms() {
        // t1 and t2 in the same direction from pivot → 0°
        let t1 = CGPoint(x: center.x + 100, y: center.y)
        let t2 = CGPoint(x: center.x + 50, y: center.y)
        let result = ProtractorMath.angleDegrees(t1: t1, t2: t2, pivot: center)
        #expect(abs(result - 0) < 1)
    }

    @Test func angleSymmetricAroundPivot() {
        // Symmetric: t1 at angle +45°, t2 at angle -45° → 90° between them
        let r: Double = 100
        let t1 = CGPoint(x: center.x + r * cos(45 * .pi / 180),
                         y: center.y - r * sin(45 * .pi / 180))
        let t2 = CGPoint(x: center.x + r * cos(-45 * .pi / 180),
                         y: center.y - r * sin(-45 * .pi / 180))
        let result = ProtractorMath.angleDegrees(t1: t1, t2: t2, pivot: center)
        #expect(abs(result - 90) < 1)
    }

    @Test func angleAlwaysInZeroTo180Range() {
        let pairs: [(CGPoint, CGPoint)] = [
            (CGPoint(x: center.x + 100, y: center.y), CGPoint(x: center.x, y: center.y + 100)),
            (CGPoint(x: center.x - 100, y: center.y), CGPoint(x: center.x, y: center.y - 100)),
            (CGPoint(x: center.x + 80, y: center.y + 60), CGPoint(x: center.x - 60, y: center.y + 80)),
        ]
        for (t1, t2) in pairs {
            let result = ProtractorMath.angleDegrees(t1: t1, t2: t2, pivot: center)
            #expect(result >= 0 && result <= 180.1)
        }
    }

    @Test func angleWrapsAcrossZeroDegreesToUseInteriorAngle() {
        let r: Double = 100
        let t1 = CGPoint(x: center.x + r * cos(350 * .pi / 180),
                         y: center.y + r * sin(350 * .pi / 180))
        let t2 = CGPoint(x: center.x + r * cos(10 * .pi / 180),
                         y: center.y + r * sin(10 * .pi / 180))

        let result = ProtractorMath.angleDegrees(t1: t1, t2: t2, pivot: center)

        #expect(abs(result - 20) < 1)
    }

    // MARK: - Snap zone

    @Test func snapZoneWithinTolerance() {
        #expect(ProtractorMath.isInSnapZone(measured: 87, target: 90, tolerance: 5))
        #expect(ProtractorMath.isInSnapZone(measured: 93, target: 90, tolerance: 5))
        #expect(ProtractorMath.isInSnapZone(measured: 90, target: 90, tolerance: 5))
        #expect(ProtractorMath.isInSnapZone(measured: 85, target: 90, tolerance: 5))
        #expect(ProtractorMath.isInSnapZone(measured: 95, target: 90, tolerance: 5))
    }

    @Test func snapZoneOutsideTolerance() {
        #expect(!ProtractorMath.isInSnapZone(measured: 84, target: 90, tolerance: 5))
        #expect(!ProtractorMath.isInSnapZone(measured: 96, target: 90, tolerance: 5))
        #expect(!ProtractorMath.isInSnapZone(measured: 60, target: 90, tolerance: 5))
    }

    @Test func snapZoneExactBoundary() {
        #expect(ProtractorMath.isInSnapZone(measured: 85, target: 90, tolerance: 5))
        #expect(ProtractorMath.isInSnapZone(measured: 95, target: 90, tolerance: 5))
        #expect(!ProtractorMath.isInSnapZone(measured: 84.9, target: 90, tolerance: 5))
    }

    @Test func snapZoneWorksForAllTargets() {
        #expect(ProtractorMath.isInSnapZone(measured: 44, target: 45, tolerance: 5))
        #expect(ProtractorMath.isInSnapZone(measured: 62, target: 60, tolerance: 5))
        #expect(!ProtractorMath.isInSnapZone(measured: 30, target: 45, tolerance: 5))
        #expect(ProtractorMath.isInSnapZone(measured: 118, target: 120, tolerance: 5))
        #expect(!ProtractorMath.isInSnapZone(measured: 114, target: 120, tolerance: 5))
    }

    @Test func snapZoneTighterTolerance() {
        // 4° tolerance used in level 5
        #expect(ProtractorMath.isInSnapZone(measured: 86, target: 90, tolerance: 4))
        #expect(!ProtractorMath.isInSnapZone(measured: 85, target: 90, tolerance: 4))
    }

    @Test func matchTransitionClearsStickySuccessWhenAngleDriftsOut() {
        let entered = ProtractorMath.matchTransition(previouslyMatched: false,
                                                     measured: 90,
                                                     target: 90,
                                                     tolerance: 5)
        #expect(entered.matched)
        #expect(entered.newlyMatched)

        let drifted = ProtractorMath.matchTransition(previouslyMatched: true,
                                                     measured: 104,
                                                     target: 90,
                                                     tolerance: 5)
        #expect(!drifted.matched)
        #expect(!drifted.newlyMatched)
    }

    @Test func matchTransitionDoesNotRecountWhileStillMatched() {
        let stillMatched = ProtractorMath.matchTransition(previouslyMatched: true,
                                                         measured: 91,
                                                         target: 90,
                                                         tolerance: 5)
        #expect(stillMatched.matched)
        #expect(!stillMatched.newlyMatched)
    }
}

@Suite("ProtractorScenes")
struct ProtractorSceneTests {
    @Test func scenesConnectEveryTargetToAVisibleContext() {
        #expect(protractorLevels.count >= 5)
        #expect(Set(protractorLevels.map(\.sceneKind)).count == protractorLevels.count)
        for level in protractorLevels {
            #expect(!level.sceneName.isEmpty)
            #expect(!level.mission.isEmpty)
            #expect(!level.mission.localizedCaseInsensitiveContains("hurry"))
            #expect(level.targetAngle > 0 && level.targetAngle <= 180)
            #expect(level.snapTolerance > 0 && level.snapTolerance <= 5)
        }
    }
}

@Suite("AngleMatchPrelude")
struct AngleMatchPreludeTests {
    @Test func preludeBuildsVisualAndValueCardsFromProtractorLevels() {
        let state = AngleMatchState.prelude(from: protractorLevels, pairCount: 3)

        #expect(state.pairs.count == 3)
        #expect(state.cards.count == 6)
        #expect(Set(state.pairs.map(\.id)).count == 3)
        #expect(Set(state.cards.map(\.id)).count == 6)
        #expect(state.pairs.map(\.targetAngle) == Array(protractorLevels.prefix(3).map(\.targetAngle)))

        for pair in state.pairs {
            let pairCards = state.cards.filter { $0.pairID == pair.id }
            #expect(pairCards.count == 2)
            #expect(pairCards.contains { $0.side == .visual })
            #expect(pairCards.contains { $0.side == .value })
            #expect(!pair.mission.isEmpty)
            #expect(!pair.sceneName.isEmpty)
            #expect(pair.valueLabel == "\(Int(pair.targetAngle))°")
        }
    }

    @Test func correctVisualAndValueSelectionMarksThePairMatched() {
        var state = AngleMatchState.prelude(from: protractorLevels, pairCount: 2)
        let pair = state.pairs[0]
        let visual = state.cards.first { $0.pairID == pair.id && $0.side == .visual }!
        let value = state.cards.first { $0.pairID == pair.id && $0.side == .value }!

        #expect(state.select(cardID: visual.id) == .selected)
        #expect(state.select(cardID: value.id) == .matched(pairID: pair.id, completed: false))

        let matchedCards = state.cards.filter { $0.pairID == pair.id }
        #expect(matchedCards.allSatisfy { $0.isMatched })
        #expect(state.completedLevelIndex == pair.levelIndex)
        #expect(!state.isComplete)
    }

    @Test func mismatchClearsSelectionWithoutMatchingCards() {
        var state = AngleMatchState.prelude(from: protractorLevels, pairCount: 2)
        let firstVisual = state.cards.first { $0.pairID == state.pairs[0].id && $0.side == .visual }!
        let secondValue = state.cards.first { $0.pairID == state.pairs[1].id && $0.side == .value }!

        #expect(state.select(cardID: firstVisual.id) == .selected)
        #expect(state.select(cardID: secondValue.id) == .mismatched)

        #expect(state.selectedCardID == nil)
        #expect(!state.cards.contains { $0.isMatched })
        #expect(!state.isComplete)
    }

    @Test func completionHappensOnlyAfterAllPairsMatch() {
        var state = AngleMatchState.prelude(from: protractorLevels, pairCount: 2)
        let pairs = state.pairs

        for (index, pair) in pairs.enumerated() {
            let visual = state.cards.first { $0.pairID == pair.id && $0.side == .visual }!
            let value = state.cards.first { $0.pairID == pair.id && $0.side == .value }!
            #expect(state.select(cardID: visual.id) == .selected)
            let expectedCompleted = index == pairs.count - 1
            #expect(state.select(cardID: value.id) == .matched(pairID: pair.id, completed: expectedCompleted))
        }

        #expect(state.isComplete)
        #expect(state.completedLevelIndex == state.pairs.last?.levelIndex)
    }

    @Test func selectingMatchedCardIsIgnoredAndPreservesCompletedPair() {
        var state = AngleMatchState.prelude(from: protractorLevels, pairCount: 2)
        let pair = state.pairs[0]
        let visual = state.cards.first { $0.pairID == pair.id && $0.side == .visual }!
        let value = state.cards.first { $0.pairID == pair.id && $0.side == .value }!

        #expect(state.select(cardID: visual.id) == .selected)
        #expect(state.select(cardID: value.id) == .matched(pairID: pair.id, completed: false))

        #expect(state.select(cardID: visual.id) == .ignored)
        #expect(state.completedLevelIndex == pair.levelIndex)
        #expect(state.cards.filter { $0.pairID == pair.id }.allSatisfy { $0.isMatched })
    }

    @Test func childFacingAngleMatchCopyAvoidsPressureWords() {
        let state = AngleMatchState.prelude(from: protractorLevels, pairCount: 3)
        let blockedWords = ["hurry", "timer", "score", "wrong", "beat"]

        for pair in state.pairs {
            let copy = "\(pair.mission) \(pair.sceneName) \(pair.valueLabel)"
            for blockedWord in blockedWords {
                #expect(!copy.localizedCaseInsensitiveContains(blockedWord))
            }
        }
    }
}
