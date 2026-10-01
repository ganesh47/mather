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
}
