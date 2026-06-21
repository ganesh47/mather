import Testing
@testable import Mather

@Suite("RectangleFactory")
struct RectangleFactoryTests {

    // MARK: - factorKey

    @Test func factorKeyAlwaysSmallerFirst() {
        #expect(RectangleFactoryView.factorKey(4, 3) == "3x4")
        #expect(RectangleFactoryView.factorKey(3, 4) == "3x4")
        #expect(RectangleFactoryView.factorKey(1, 12) == "1x12")
        #expect(RectangleFactoryView.factorKey(12, 1) == "1x12")
    }

    @Test func factorKeySquareIsSymmetric() {
        #expect(RectangleFactoryView.factorKey(3, 3) == "3x3")
    }

    // MARK: - factorsOf

    @Test func factorsOf4() {
        let f = RectangleFactoryView.factorsOf(4)
        #expect(f.count == 2)
        #expect(f.contains("1x4"))
        #expect(f.contains("2x2"))
    }

    @Test func factorsOf12() {
        let f = RectangleFactoryView.factorsOf(12)
        #expect(f.count == 3)
        #expect(f.contains("1x12"))
        #expect(f.contains("2x6"))
        #expect(f.contains("3x4"))
    }

    @Test func factorsOf7IsPrime() {
        let f = RectangleFactoryView.factorsOf(7)
        #expect(f.count == 1)
        #expect(f.contains("1x7"))
    }

    @Test func factorsOf11IsPrime() {
        let f = RectangleFactoryView.factorsOf(11)
        #expect(f.count == 1)
        #expect(f.contains("1x11"))
    }

    @Test func factorsOf16() {
        let f = RectangleFactoryView.factorsOf(16)
        #expect(f.count == 3)
        #expect(f.contains("1x16"))
        #expect(f.contains("2x8"))
        #expect(f.contains("4x4"))
    }

    @Test func factorsOf9() {
        let f = RectangleFactoryView.factorsOf(9)
        #expect(f.count == 2)
        #expect(f.contains("1x9"))
        #expect(f.contains("3x3"))
    }

    @Test func factorsOf24() {
        let f = RectangleFactoryView.factorsOf(24)
        #expect(f.count == 4)
        #expect(f.contains("1x24"))
        #expect(f.contains("2x12"))
        #expect(f.contains("3x8"))
        #expect(f.contains("4x6"))
    }

    // MARK: - playable grid

    @Test func playableGridForFourSupportsTwoByTwo() {
        let grid = RectangleFactoryView.playableGrid(for: 4)
        #expect(grid.columns == 4)
        #expect(grid.rows == 2)
    }

    @Test func playableGridForTwentyFourSupportsAllFactorPairs() {
        let grid = RectangleFactoryView.playableGrid(for: 24)
        #expect(grid.columns == 24)
        #expect(grid.rows == 4)
    }

    @Test func smartStartAvoidsAlreadySolvedRectangle() {
        let start = RectangleFactoryView.smartStartDimensions(for: 24)
        #expect(start.width * start.height != 24)
        #expect(start.width <= RectangleFactoryView.playableGrid(for: 24).columns)
        #expect(start.height <= RectangleFactoryView.playableGrid(for: 24).rows)
    }

    // MARK: - Validity

    @Test func validRectangleDetected() {
        #expect(3 * 4 == 12)
        #expect(RectangleFactoryView.factorsOf(12).contains(RectangleFactoryView.factorKey(3, 4)))
    }

    @Test func invalidRectangleRejected() {
        #expect(3 * 5 != 12)
    }

    @Test func bothOrientationsMappedToSameKey() {
        let k1 = RectangleFactoryView.factorKey(3, 4)
        let k2 = RectangleFactoryView.factorKey(4, 3)
        #expect(k1 == k2)
    }

    // MARK: - N sequence contains expected values

    @Test func nSequenceIncludesPrimes() {
        let seq = [4, 6, 9, 12, 7, 11, 16, 18, 13, 24]
        let primes = seq.filter { n in RectangleFactoryView.factorsOf(n).count == 1 }
        #expect(primes.contains(7))
        #expect(primes.contains(11))
        #expect(primes.contains(13))
    }

    @Test func nSequenceIncludesComposites() {
        let seq = [4, 6, 9, 12, 7, 11, 16, 18, 13, 24]
        let composites = seq.filter { n in RectangleFactoryView.factorsOf(n).count > 1 }
        #expect(composites.count >= 6)
    }

    @MainActor
    @Test func completedTargetCountIncludesSolvedCurrentTarget() {
        #expect(RectangleFactoryView.completedTargetCount(sequenceIndex: 0, allFoundForCurrentTarget: false) == 0)
        #expect(RectangleFactoryView.completedTargetCount(sequenceIndex: 0, allFoundForCurrentTarget: true) == 1)
        #expect(RectangleFactoryView.completedTargetCount(sequenceIndex: 9, allFoundForCurrentTarget: true) == 10)
    }

    // MARK: - Completion helpers

    @Test func completionStyleMarksPrimeTargets() {
        #expect(RectangleFactoryView.completionStyle(for: 7) == .prime)
        #expect(RectangleFactoryView.completionStyle(for: 12) == .standard)
    }

    @Test func completionTitleHighlightsPrimeDiscovery() {
        #expect(RectangleFactoryView.completionTitle(for: 11) == "Prime discovery!")
        #expect(RectangleFactoryView.completionTitle(for: 16) == "All rectangles found!")
    }

    @Test func completionSpeechDifferentiatesPrimeAndComposite() {
        #expect(RectangleFactoryView.completionSpeech(for: 13) == "13 is prime. Only one factory box works!")
        #expect(RectangleFactoryView.completionSpeech(for: 12) == "Factory complete! You found all 3 rectangles for 12!")
    }

    @Test func factoryStoryCopyStaysShortAndMathSpecific() {
        #expect(RectangleFactoryView.missionText(for: 4) == "Factory order: pack 4 dots with no gaps")
        #expect(RectangleFactoryView.openingSpeech(for: 4) == "Factory order! Can you pack 4 dots into a perfect rectangle?")
        #expect(RectangleFactoryView.discoverySpeech(width: 2, height: 3, target: 6) == "Nice packing! 3 rows of 2 makes 6.")
        #expect(RectangleFactoryView.transitionSpeech(from: 4, to: 6) == "Order 4 shipped! Next factory order: 6 dots.")
    }

    @Test func instructionTextExplainsDragAndExactDotGoal() {
        let text = RectangleFactoryView.instructionText(for: 4)
        #expect(text.contains("Drag the corner handle"))
        #expect(text.contains("rows × columns"))
        #expect(text.contains("exactly 4 dots"))
        #expect(!text.contains("blue"))
    }

    @Test func factorPairGuideStartsWithSimpleRowsBeforeAbstraction() {
        #expect(RectangleFactoryView.factorPairGuideText(for: 4) == "Start with 1 row of 4. Then try 2 rows of 2.")
        #expect(RectangleFactoryView.factorPairGuideText(for: 7) == "Start with 1 row of 7. That is the only perfect rectangle.")
    }

    @Test func selectionEquationUsesVisualRowsAndColumns() {
        #expect(RectangleFactoryView.targetGoalTitle == "Goal")
        #expect(RectangleFactoryView.targetGoalValue(for: 4) == "4 dots")
        #expect(RectangleFactoryView.selectionTitle == "Selected")
        #expect(RectangleFactoryView.selectionEquationText(rows: 2, columns: 3) == "2 rows × 3 columns = 6 dots")
        #expect(RectangleFactoryView.selectionEquationText(rows: 1, columns: 1) == "1 row × 1 column = 1 dot")
    }

    @Test func selectionFeedbackPreventsTargetFrameMismatch() {
        #expect(RectangleFactoryView.selectionFeedbackText(rows: 2, columns: 3, target: 4) == "Selected 6 dots; 2 too many.")
        #expect(RectangleFactoryView.selectionFeedbackText(rows: 1, columns: 3, target: 4) == "Selected 3 dots; need 1 more.")
        #expect(RectangleFactoryView.selectionFeedbackText(rows: 2, columns: 2, target: 4) == "Perfect: selected exactly 4 dots.")
    }

    @Test func solvedStatusCopyMakesSuccessAndNextActionClear() {
        #expect(RectangleFactoryView.solvedStatusTitle == "Perfect fit!")
        #expect(RectangleFactoryView.solvedStatusSubtitle(for: 4, allFound: false) == "Lift your finger to ship this 4-dot rectangle.")
        #expect(RectangleFactoryView.solvedStatusSubtitle(for: 4, allFound: true) == "All 4-dot rectangles are packed. Use the next button below.")
    }

    @Test func resetAndHandleAccessibilityCopyIsDiscoverable() {
        #expect(RectangleFactoryView.resetButtonTitle == "Reset frame")
        #expect(RectangleFactoryView.resetButtonAccessibilityLabel == "Reset rectangle frame")
        #expect(RectangleFactoryView.resizeHandleAccessibilityLabel == "Resize corner handle")
        #expect(RectangleFactoryView.resizeHandleAccessibilityHint(for: 9) == "Drag until the rectangle covers exactly 9 dots.")
    }

    @Test func advanceButtonTitleReflectsSequenceEnd() {
        #expect(RectangleFactoryView.advanceButtonTitle(hasNext: true) == "Next Number →")
        #expect(RectangleFactoryView.advanceButtonTitle(hasNext: false) == "All done! 🎉")
        #expect(RectangleFactoryView.advanceButtonAccessibilityLabel(hasNext: true) == "Next number")
        #expect(RectangleFactoryView.advanceButtonAccessibilityLabel(hasNext: false) == "All done")
    }
}
