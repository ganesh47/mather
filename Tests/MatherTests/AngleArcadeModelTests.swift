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
        #expect(lowShot.verticalDelta < 0)
        #expect(!highShot.hit)
        #expect(highShot.verticalDelta > 0)
    }

    @Test
    func targetCycleWrapsDeterministically() {
        let count = AngleArcadeTarget.defaultTargets.count
        #expect(AngleArcadeModel.nextTargetIndex(after: 0, targetCount: count) == 1)
        #expect(AngleArcadeModel.nextTargetIndex(after: count - 1, targetCount: count) == 0)
        #expect(AngleArcadeModel.nextTargetIndex(after: 4, targetCount: 0) == 0)
    }
}
