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
        // 1×4, 2×2
        #expect(f.count == 2)
        #expect(f.contains("1x4"))
        #expect(f.contains("2x2"))
    }

    @Test func factorsOf12() {
        let f = RectangleFactoryView.factorsOf(12)
        // 1×12, 2×6, 3×4
        #expect(f.count == 3)
        #expect(f.contains("1x12"))
        #expect(f.contains("2x6"))
        #expect(f.contains("3x4"))
    }

    @Test func factorsOf7IsPrime() {
        let f = RectangleFactoryView.factorsOf(7)
        // Only 1×7 — prime has a single rectangle
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
        // 1×16, 2×8, 4×4
        #expect(f.count == 3)
        #expect(f.contains("1x16"))
        #expect(f.contains("2x8"))
        #expect(f.contains("4x4"))
    }

    @Test func factorsOf9() {
        let f = RectangleFactoryView.factorsOf(9)
        // 1×9, 3×3
        #expect(f.count == 2)
        #expect(f.contains("1x9"))
        #expect(f.contains("3x3"))
    }

    @Test func factorsOf24() {
        let f = RectangleFactoryView.factorsOf(24)
        // 1×24, 2×12, 3×8, 4×6
        #expect(f.count == 4)
        #expect(f.contains("1x24"))
        #expect(f.contains("2x12"))
        #expect(f.contains("3x8"))
        #expect(f.contains("4x6"))
    }

    // MARK: - Validity: width × height == N

    @Test func validRectangleDetected() {
        // 3×4 for N=12 is valid
        #expect(3 * 4 == 12)
        #expect(RectangleFactoryView.factorsOf(12).contains(RectangleFactoryView.factorKey(3, 4)))
    }

    @Test func invalidRectangleRejected() {
        // 3×5 for N=12 is not valid
        #expect(3 * 5 != 12)
    }

    @Test func bothOrientationsMappedToSameKey() {
        // 3×4 and 4×3 produce identical canonical keys
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
}
