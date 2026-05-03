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

    // MARK: - Compass cue helpers

    @Test func turnDirectionMapsRightLeftAndAround() {
        #expect(CompassAnglesView.turnDirection(for: 90) == .right)
        #expect(CompassAnglesView.turnDirection(for: -90) == .left)
        #expect(CompassAnglesView.turnDirection(for: 180) == .around)
    }

    @Test func bodyRelativeHintUsesChildPerspectiveLanguage() {
        #expect(CompassAnglesView.bodyRelativeHint(for: 90).contains("right"))
        #expect(CompassAnglesView.bodyRelativeHint(for: -90).contains("left"))
        #expect(CompassAnglesView.bodyRelativeHint(for: 180).contains("Keep turning"))
    }

}

@Suite("Compass Walk + Turn sequencing")
struct CompassWalkTurnTests {
    @Test func levelsIncludeStepAndTurnInstructions() {
        #expect(compassWalkTurnLevels.count >= 5)
        #expect(compassWalkTurnLevels.allSatisfy { $0.steps > 0 })
        #expect(compassWalkTurnLevels.first?.instruction.contains("small steps") == true)
        #expect(compassWalkTurnLevels.first?.instruction.contains("turn") == true)
    }

    @Test func stepProgressCompletesAtRequiredThreshold() {
        var progress = StepWalkProgress(requiredSteps: 3)
        #expect(progress.remainingSteps == 3)
        #expect(!progress.isComplete)
        progress.setCountedSteps(2)
        #expect(!progress.isComplete)
        #expect(progress.remainingSteps == 1)
        progress.setCountedSteps(3)
        #expect(progress.isComplete)
        #expect(progress.fractionComplete == 1)
    }

    @Test func manualStepFallbackCanCompleteWalk() {
        var progress = StepWalkProgress(requiredSteps: 2)
        progress.addManualStep()
        #expect(!progress.isComplete)
        progress.addManualStep()
        #expect(progress.isComplete)
    }

    @Test func stateMovesFromWalkToTurnAfterSteps() {
        let level = CompassWalkTurnLevel(id: 99, walkDirection: .forward, steps: 3, targetDeg: 90)
        var state = CompassWalkTurnState(level: level)
        #expect(state.phase == .ready)
        state.startWalking()
        #expect(state.phase == .walking)
        state.applyCountedSteps(2)
        #expect(state.phase == .walking)
        state.applyCountedSteps(3)
        #expect(state.phase == .turning)
    }

    @Test func stateCompletesOnlyAfterTurnSnap() {
        let level = CompassWalkTurnLevel(id: 100, walkDirection: .left, steps: 2, targetDeg: -90)
        var state = CompassWalkTurnState(level: level)
        state.startWalking()
        state.applyCountedSteps(2)
        state.applyYaw(-75)
        #expect(state.phase == .turning)
        state.applyYaw(-84)
        #expect(state.phase == .success)
    }

    @Test func yawBeforeWalkCompletionDoesNotWin() {
        let level = CompassWalkTurnLevel(id: 101, walkDirection: .right, steps: 4, targetDeg: 180)
        var state = CompassWalkTurnState(level: level)
        state.startWalking()
        state.applyYaw(180)
        #expect(state.phase == .walking)
    }

    @MainActor
    @Test func stepCountServiceManualFallbackStateIsTestableWithoutHardware() {
        let service = StepCountService()
        service.start(requiredSteps: 3)
        service.useManualFallback(reason: "testing fallback")
        service.addManualStep()
        service.addManualStep()
        #expect(service.countedSteps == 2)
        #expect(!service.isComplete)
        service.addManualStep()
        #expect(service.isComplete)
        service.stop()
        #expect(service.mode == .idle)
    }
}
