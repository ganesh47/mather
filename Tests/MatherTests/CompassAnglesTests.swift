import Testing
@testable import Mather

@Suite("CompassAngles")
struct CompassAnglesTests {

    // MARK: - CompassMath.normalise

    @Test func normalisePositiveWithinRange() {
        #expect(abs(CompassMath.normalise(90) - 90) < 0.01)
        #expect(abs(CompassMath.normalise(180) - 180) < 0.01)
        #expect(abs(CompassMath.normalise(-90) - (-90)) < 0.01)
    }

    @Test func normalisePositiveOverflow() {
        // 270° normalises to -90° (equivalent turn to the left)
        let result = CompassMath.normalise(270)
        #expect(abs(result - (-90)) < 0.01)
    }

    @Test func normalise360WrapsToZero() {
        #expect(abs(CompassMath.normalise(360)) < 0.01)
    }

    @Test func normalise540WrapsTo180() {
        #expect(abs(CompassMath.normalise(540) - 180) < 0.01)
    }

    @Test func normaliseNegativeUnderflow() {
        // -270° normalises to +90°
        let result = CompassMath.normalise(-270)
        #expect(abs(result - 90) < 0.01)
    }

    // MARK: - CompassMath.isInSnapZone

    @Test func snapZoneAtExactTarget() {
        #expect(CompassMath.isInSnapZone(yaw: 90, target: 90))
    }

    @Test func snapZoneWithinTolerance() {
        #expect(CompassMath.isInSnapZone(yaw: 83, target: 90, tolerance: 10))
        #expect(CompassMath.isInSnapZone(yaw: 97, target: 90, tolerance: 10))
    }

    @Test func snapZoneAtExactBoundary() {
        #expect(CompassMath.isInSnapZone(yaw: 80, target: 90, tolerance: 10))
        #expect(CompassMath.isInSnapZone(yaw: 100, target: 90, tolerance: 10))
    }

    @Test func snapZoneOutsideTolerance() {
        #expect(!CompassMath.isInSnapZone(yaw: 79, target: 90, tolerance: 10))
        #expect(!CompassMath.isInSnapZone(yaw: 101, target: 90, tolerance: 10))
    }

    @Test func snapZoneNegativeTarget() {
        // Left turn target: -90°
        #expect(CompassMath.isInSnapZone(yaw: -85, target: -90, tolerance: 10))
        #expect(!CompassMath.isInSnapZone(yaw: -79, target: -90, tolerance: 10))
    }

    @Test func snapZoneWrapsCorrectly() {
        // yaw = 175, target = -175 → difference = 350° → normalised = -10° → within 10°
        #expect(CompassMath.isInSnapZone(yaw: 175, target: -175, tolerance: 10))
    }

    @Test func snapZone180Target() {
        #expect(CompassMath.isInSnapZone(yaw: 185, target: 180, tolerance: 10))
        #expect(CompassMath.isInSnapZone(yaw: 175, target: 180, tolerance: 10))
        #expect(!CompassMath.isInSnapZone(yaw: 169, target: 180, tolerance: 10))
    }

    // MARK: - CompassMath.angularDistance

    @Test func angularDistanceAlwaysPositive() {
        #expect(CompassMath.angularDistance(90, 0) >= 0)
        #expect(CompassMath.angularDistance(-90, 0) >= 0)
        #expect(CompassMath.angularDistance(0, 90) >= 0)
    }

    @Test func angularDistanceIsSymmetric() {
        #expect(abs(CompassMath.angularDistance(90, 30) - CompassMath.angularDistance(30, 90)) < 0.01)
    }

    @Test func angularDistance90Degrees() {
        #expect(abs(CompassMath.angularDistance(90, 0) - 90) < 0.01)
    }

    @Test func angularDistance180Degrees() {
        #expect(abs(CompassMath.angularDistance(180, 0) - 180) < 0.01)
    }

    @Test func angularDistanceAcrossWrap() {
        // From 170° to -170° is 20° the short way
        #expect(abs(CompassMath.angularDistance(170, -170) - 20) < 0.01)
    }

    @Test func angularDistanceMaxIs180() {
        // Opposite headings: maximum angular distance is 180
        for pair in [(0.0, 180.0), (90.0, 270.0), (45.0, 225.0)] {
            let d = CompassMath.angularDistance(pair.0, pair.1)
            #expect(d <= 180.01)
        }
    }
}
