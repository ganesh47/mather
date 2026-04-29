import Foundation
import Testing
@testable import Mather

/// Tests for AngleCannonView's pure physics/geometry helper functions.
/// The static helpers are tested directly — no SwiftUI dependency needed.
struct AngleCannonTests {

    private let cannon = CGPoint(x: 100, y: 500)
    private let canvasSize = CGSize(width: 900, height: 600)

    // MARK: - Arc point generation

    @Test
    func arcPointsNotEmpty() {
        let pts = AngleCannonView.arcPoints(
            angleDeg: 45, cannon: cannon, size: canvasSize
        )
        #expect(!pts.isEmpty, "Arc should produce at least one point")
    }

    @Test
    func arcStartsAtCannonOrigin() {
        let pts = AngleCannonView.arcPoints(
            angleDeg: 45, cannon: cannon, size: canvasSize
        )
        guard let first = pts.first else { return }
        #expect(abs(first.x - cannon.x) < 5, "Arc x-start should be near cannon origin")
        #expect(abs(first.y - cannon.y) < 5, "Arc y-start should be near cannon origin")
    }

    @Test
    func arcMovesRightward() {
        let pts = AngleCannonView.arcPoints(
            angleDeg: 45, cannon: cannon, size: canvasSize
        )
        guard pts.count >= 2 else { return }
        // Projectile always moves right (positive x velocity)
        #expect(pts.last!.x > pts.first!.x, "Projectile x should increase over time")
    }

    @Test
    func arcGoesUpThenCurvesDown() {
        // At 45° the projectile should rise then fall — so peak y is above the start.
        let pts = AngleCannonView.arcPoints(
            angleDeg: 45, cannon: cannon, size: canvasSize
        )
        guard pts.count > 3 else { return }
        let minY = pts.map(\.y).min() ?? cannon.y
        #expect(minY < cannon.y, "Projectile should rise above cannon origin (screen y decreases going up)")
    }

    // MARK: - Target position

    @Test
    func targetPositionWithinCanvasBounds() {
        for angle in [15.0, 30.0, 45.0, 60.0, 75.0] {
            let pos = AngleCannonView.targetPosition(
                angleDeg: angle,
                cannon: cannon,
                canvasSize: canvasSize
            )
            #expect(pos.x >= 0 && pos.x <= canvasSize.width,
                    "Target x should be within canvas for angle \(angle)°")
            #expect(pos.y >= 0 && pos.y <= canvasSize.height,
                    "Target y should be within canvas for angle \(angle)°")
        }
    }

    @Test
    func higherAngleTargetIsHigherOnScreen() {
        // 60° target should be higher up (lower y) than 30° target.
        let low = AngleCannonView.targetPosition(angleDeg: 30, cannon: cannon, canvasSize: canvasSize)
        let high = AngleCannonView.targetPosition(angleDeg: 60, cannon: cannon, canvasSize: canvasSize)
        #expect(high.y <= low.y, "Higher launch angle should produce a higher target on screen")
    }

    // MARK: - Hit detection

    @Test
    func hitDetectionWithinTolerance() {
        #expect(
            AngleCannonView.isHit(firedDeg: 43, targetDeg: 45, toleranceDeg: 15),
            "2° off target should be a hit with 15° tolerance"
        )
        #expect(
            AngleCannonView.isHit(firedDeg: 45, targetDeg: 45, toleranceDeg: 10),
            "Exact match should always be a hit"
        )
        #expect(
            AngleCannonView.isHit(firedDeg: 35, targetDeg: 45, toleranceDeg: 15),
            "10° off target should be a hit with 15° tolerance"
        )
    }

    @Test
    func hitDetectionOutsideTolerance() {
        #expect(
            !AngleCannonView.isHit(firedDeg: 25, targetDeg: 45, toleranceDeg: 15),
            "20° off target should be a miss with 15° tolerance"
        )
        #expect(
            AngleCannonView.isHit(firedDeg: 35, targetDeg: 45, toleranceDeg: 10),
            "10° off target should count as a hit when tolerance is inclusive"
        )
        #expect(
            !AngleCannonView.isHit(firedDeg: 34, targetDeg: 45, toleranceDeg: 10),
            "11° off target should be a miss with 10° tolerance (Level 2)"
        )
    }

    @Test
    func hitDetectionIsSymmetric() {
        // Firing 12° low is the same as 12° high for |angle difference|.
        let below = AngleCannonView.isHit(firedDeg: 33, targetDeg: 45, toleranceDeg: 15)
        let above = AngleCannonView.isHit(firedDeg: 57, targetDeg: 45, toleranceDeg: 15)
        #expect(below == above, "Hit detection should be symmetric around target angle")
    }

    // MARK: - Angle snapping

    /// Verify the snap formula used in the view (nearest multiple of 15°).
    @Test
    func angleSnapsToNearest15() {
        let snapDeg = 15.0
        let cases: [(input: Double, expected: Double)] = [
            (47, 45),
            (50, 45),  // equidistant — rounds to 45 (down)
            (53, 60),
            (14, 15),
            (7,  0),   // below minimum but snap formula gives 0; view clamps to 10
            (78, 75),
        ]
        for (input, expected) in cases {
            let snapped = (input / snapDeg).rounded() * snapDeg
            #expect(snapped == expected, "Angle \(input)° should snap to \(expected)°, got \(snapped)°")
        }
    }
}

@Suite("AngleCannonScenario")
struct AngleCannonScenarioTests {
    @Test func scenariosAreShortSafeAndMappedToTargets() {
        let scenarios = AngleCannonScenario.defaultScenarios
        #expect(scenarios.count >= 4)
        for scenario in scenarios {
            #expect(!scenario.id.isEmpty)
            #expect(!scenario.missionSpeech.isEmpty)
            #expect(scenario.missionSpeech.count <= 80)
            #expect(!scenario.successSpeech.localizedCaseInsensitiveContains("fail"))
            #expect([15.0, 30, 45, 60, 75].contains(scenario.targetAngleDeg))
        }
    }

    @Test func projectilePointInterpolatesDeterministically() {
        let points = [CGPoint(x: 0, y: 0), CGPoint(x: 10, y: 10), CGPoint(x: 20, y: 0)]
        #expect(AngleCannonView.projectilePoint(on: points, progress: 0) == CGPoint(x: 0, y: 0))
        #expect(AngleCannonView.projectilePoint(on: points, progress: 0.5) == CGPoint(x: 10, y: 10))
        #expect(AngleCannonView.projectilePoint(on: points, progress: 1) == CGPoint(x: 20, y: 0))
    }
}
