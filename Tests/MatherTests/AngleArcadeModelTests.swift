import Foundation
import Testing
@testable import Mather

struct AngleArcadeModelTests {
    @Test
    func defaultTargetsProvideAtLeastThreePositions() {
        let targets = AngleArcadeTarget.defaultTargets
        #expect(targets.count >= 3)
        #expect(Set(targets.map(\.id)).count == targets.count)
        #expect(Set(targets.map(\.distance)).count >= 3)
        #expect(targets.allSatisfy { $0.radius > 0 })
    }

    @Test
    func dPadAngleControlStepsAndClamps() {
        #expect(AngleArcadeModel.adjustedAngle(45, direction: 1) == 50)
        #expect(AngleArcadeModel.adjustedAngle(45, direction: -1) == 40)
        #expect(AngleArcadeModel.adjustedAngle(74, direction: 1) == 75)
        #expect(AngleArcadeModel.adjustedAngle(21, direction: -1) == 20)
    }

    @Test
    func dPadPowerControlStepsAndClamps() {
        #expect(AngleArcadeModel.adjustedPower(80, direction: 1) == 85)
        #expect(AngleArcadeModel.adjustedPower(80, direction: -1) == 75)
        #expect(AngleArcadeModel.adjustedPower(98, direction: 1) == 100)
        #expect(AngleArcadeModel.adjustedPower(42, direction: -1) == 40)
    }

    @Test
    func recommendedLaunchesHitAllDefaultTargets() {
        for target in AngleArcadeTarget.defaultTargets {
            let shot = AngleArcadeModel.shot(
                angle: target.recommendedAngle,
                power: target.recommendedPower,
                target: target
            )
            #expect(shot.hit, "\(target.id) should be hittable by its recommended launch")
            #expect(abs(shot.verticalDelta) <= target.radius)
            #expect(!shot.path.isEmpty)
            #expect(shot.outcome == .hit)
            #expect(abs(Double(shot.path.last!.x) - target.distance) < 0.000001)
            #expect(abs(Double(shot.path.last!.y) - shot.heightAtTarget) < 0.000001)
            #expect(shot.flightDuration > 0)
        }
    }

    @Test
    func challengeStartsMissAndAreSolvableWithinTwoPowerSteps() {
        for target in AngleArcadeTarget.defaultTargets {
            let initial = AngleArcadeModel.shot(
                angle: target.recommendedAngle,
                power: target.startingPower,
                target: target
            )
            #expect(!initial.hit, "\(target.id) must invite an adjustment")
            var power = target.startingPower
            var solved = false
            for _ in 0..<2 {
                power = AngleArcadeModel.adjustedPower(power, direction: 1)
                solved = solved || AngleArcadeModel.shot(
                    angle: target.recommendedAngle, power: power, target: target
                ).hit
            }
            #expect(solved, "\(target.id) must have a small, achievable correction")
        }
    }

    @Test
    func landingIsDeterministicForSameAnglePowerAndTarget() {
        let target = AngleArcadeTarget.defaultTargets[1]
        let first = AngleArcadeModel.shot(angle: 45, power: 85, target: target)
        let second = AngleArcadeModel.shot(angle: 45, power: 85, target: target)

        #expect(first == second)
        #expect(abs(first.landingX - 663.52) < 0.1)
        #expect(abs(first.heightAtTarget - 112.48) < 0.1)
    }

    @Test
    func missReportsSignedVerticalDelta() {
        let target = AngleArcadeTarget.defaultTargets[1]
        let lowShot = AngleArcadeModel.shot(angle: 25, power: 55, target: target)
        let highShot = AngleArcadeModel.shot(angle: 65, power: 100, target: target)

        #expect(!lowShot.hit)
        #expect(lowShot.outcome == .short)
        #expect(lowShot.verticalDelta < 0)
        #expect(!highShot.hit)
        #expect(highShot.outcome == .above)
        #expect(highShot.verticalDelta > 0)
    }

    @Test
    func shortShotStopsAtGroundAndNeverHitsAnUnreachedTarget() {
        let target = AngleArcadeTarget(
            id: "unreachable", title: "Far target", distance: 900, height: 20,
            radius: 100, recommendedAngle: 20, recommendedPower: 40
        )
        let shot = AngleArcadeModel.shot(angle: 20, power: 40, target: target)
        #expect(shot.outcome == .short)
        #expect(!shot.hit)
        #expect(shot.heightAtTarget == 0)
        #expect(shot.landingX < target.distance)
        #expect(abs(Double(shot.path.last!.x) - shot.landingX) < 0.000001)
        #expect(abs(Double(shot.path.last!.y)) < 0.000001)
        #expect(shot.path.allSatisfy { $0.y >= 0 })
    }

    @Test
    func reachedTargetsDistinguishAboveBelowAndInclusiveHitBoundary() {
        let probe = AngleArcadeModel.shot(
            angle: 45, power: 85, target: AngleArcadeTarget.defaultTargets[1]
        )
        func target(height: Double, radius: Double = 10) -> AngleArcadeTarget {
            AngleArcadeTarget(
                id: "test", title: "Test", distance: probe.target.distance,
                height: height, radius: radius, recommendedAngle: 45, recommendedPower: 85
            )
        }
        let below = AngleArcadeModel.shot(
            angle: 45, power: 85, target: target(height: probe.heightAtTarget + 20)
        )
        let above = AngleArcadeModel.shot(
            angle: 45, power: 85, target: target(height: probe.heightAtTarget - 20)
        )
        let boundary = AngleArcadeModel.shot(
            angle: 45, power: 85, target: target(height: probe.heightAtTarget + 10)
        )
        #expect(below.outcome == .below)
        #expect(above.outcome == .above)
        #expect(boundary.outcome == .hit)
        #expect(abs(boundary.verticalDelta) == boundary.target.radius)
        #expect(below.flightDuration > boundary.flightDuration)
    }

    @Test
    func shotClampsControlsAndAlwaysProducesUsablePath() {
        let shot = AngleArcadeModel.shot(
            angle: 0, power: 200, target: AngleArcadeTarget.defaultTargets[0], sampleCount: 0
        )
        #expect(shot.angle == AngleArcadeModel.angleRange.lowerBound)
        #expect(shot.power == AngleArcadeModel.powerRange.upperBound)
        #expect(shot.path.count == 2)
        #expect(shot.path.first!.x == 0)
        #expect(shot.path.first!.y == 0)
        #expect(shot.flightDuration > 0)
    }

    @Test
    func targetCycleWrapsDeterministically() {
        let count = AngleArcadeTarget.defaultTargets.count
        #expect(AngleArcadeModel.nextTargetIndex(after: 0, targetCount: count) == 1)
        #expect(AngleArcadeModel.nextTargetIndex(after: count - 1, targetCount: count) == 0)
        #expect(AngleArcadeModel.nextTargetIndex(after: 4, targetCount: 0) == 0)
    }

    @Test func thinObstacleCollisionDoesNotDependOnRenderingSamples() {
        let target = AngleArcadeTarget.defaultTargets[0]
        let fence = AngleArcadeObstacle(id: "thin", title: "Fence", rect: .init(x: 100, y: 0, width: 1, height: 200))
        let sparse = AngleArcadeModel.shot(angle: 35, power: 77, target: target, sampleCount: 2, obstacles: [fence])
        let detailed = AngleArcadeModel.shot(angle: 35, power: 77, target: target, sampleCount: 120, obstacles: [fence])
        #expect(sparse.outcome == .blocked)
        #expect(sparse.obstacleID == "thin")
        #expect(abs(Double(sparse.path.last!.x) - 100) < 0.000001)
        #expect(sparse.flightDuration == detailed.flightDuration)
        #expect(sparse.path.last == detailed.path.last)
    }

    @Test func earliestObstacleWinsAndRadiusExtendsSweptContact() {
        let target = AngleArcadeTarget.defaultTargets[0]
        let first = AngleArcadeObstacle(id: "first", title: "First", rect: .init(x: 100, y: 0, width: 10, height: 200))
        let later = AngleArcadeObstacle(id: "later", title: "Later", rect: .init(x: 200, y: 0, width: 10, height: 200))
        let shot = AngleArcadeModel.shot(angle: 35, power: 77, target: target, obstacles: [later, first], projectileRadius: 8)
        #expect(shot.obstacleID == "first")
        #expect(abs(Double(shot.path.last!.x) - 92) < 0.000001)
        #expect(shot.path.allSatisfy { $0.x <= 92.000001 })
    }

    @Test func targetHitPrecedesObstaclesBeyondImpactAndInvalidGravityFallsBack() {
        let target = AngleArcadeTarget.defaultTargets[0]
        let beyond = AngleArcadeObstacle(id: "beyond", title: "Beyond", rect: .init(x: 500, y: 0, width: 10, height: 400))
        let shot = AngleArcadeModel.shot(angle: 35, power: 77, target: target, gravity: 0, obstacles: [beyond])
        #expect(shot.hit)
        #expect(shot.obstacleID == nil)
        #expect(shot.gravity == AngleArcadeModel.gravity)
        #expect(abs(Double(shot.path.last!.x) - target.distance) < 0.000001)
    }

    @Test func sweptCircleStopsAtFirstContactBeforeCenterPlaneAndLaterObstacle() {
        let target = AngleArcadeTarget.defaultTargets[0]
        let later = AngleArcadeObstacle(id: "later", title: "Later", rect: .init(x: 380, y: 0, width: 1, height: 400))
        let sparse = AngleArcadeModel.shot(
            angle: 35, power: 77, target: target, sampleCount: 2,
            obstacles: [later], projectileRadius: 8, sweptTargetCollision: true
        )
        let detailed = AngleArcadeModel.shot(
            angle: 35, power: 77, target: target, sampleCount: 120,
            obstacles: [later], projectileRadius: 8, sweptTargetCollision: true
        )
        #expect(sparse.hit)
        #expect(sparse.obstacleID == nil)
        let endpoint = sparse.path.last!
        #expect(endpoint.x < target.distance)
        #expect(abs(hypot(Double(endpoint.x) - target.distance, Double(endpoint.y) - target.height) - 38) < 0.000001)
        #expect(sparse.flightDuration == detailed.flightDuration)
        #expect(sparse.path.last == detailed.path.last)
    }

    @Test func sweptCircleDetectsGrazingContactAndRejectsNearbyOutsidePath() {
        let vx = 85.0 * 3 / sqrt(2)
        let vy = vx
        let time = 1.0
        let pointX = vx * time
        let pointY = vy * time - 49 * time * time
        let tangentY = vy - 98 * time
        let norm = hypot(vx, tangentY)
        let radius = 15.0
        func target(offset: Double) -> AngleArcadeTarget {
            .init(id: "graze", title: "Graze", distance: pointX - radius * tangentY / norm,
                  height: pointY + radius * vx / norm + offset, radius: radius,
                  recommendedAngle: 45, recommendedPower: 85)
        }
        let tangent = AngleArcadeModel.shot(angle: 45, power: 85, target: target(offset: 0), sampleCount: 2, sweptTargetCollision: true)
        let inside = AngleArcadeModel.shot(angle: 45, power: 85, target: target(offset: -0.1), sampleCount: 2, sweptTargetCollision: true)
        let outside = AngleArcadeModel.shot(angle: 45, power: 85, target: target(offset: 0.1), sampleCount: 120, sweptTargetCollision: true)
        #expect(tangent.hit)
        #expect(abs(tangent.flightDuration - time) < 0.000001)
        #expect(inside.hit)
        #expect(!outside.hit)
    }
}
