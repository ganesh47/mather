import Foundation
import Testing
@testable import Mather

/// Tests for SymmetryFoldView's fold-angle computation logic.
/// The view's motion handling is pure: given a neutralRoll and a tiltRoll,
/// foldAngle = clamp(-delta / (pi/4), 0, 1). These tests verify that mapping.
struct SymmetryFoldTests {

    // MARK: - Neutral roll tests

    @Test
    func neutralRollProducesZeroFoldAngle() {
        // At the neutral position (delta = 0), the shape should be fully open.
        #expect(SymmetryFoldView.foldAngle(tiltRoll: 0.5, neutralRoll: 0.5) == 0.0)
        #expect(SymmetryFoldView.foldAngle(tiltRoll: -0.3, neutralRoll: -0.3) == 0.0)
        #expect(SymmetryFoldView.foldAngle(tiltRoll: 0.0, neutralRoll: 0.0) == 0.0)
    }

    // MARK: - Left tilt increases fold angle

    @Test
    func leftTiltIncreasesFoldAngle() {
        // Left tilt = roll decreases from neutral (negative delta).
        // neutral = 0; tiltRoll = -pi/8 (left, half of max) → foldAngle = 0.5
        let angle = SymmetryFoldView.foldAngle(tiltRoll: -.pi / 8, neutralRoll: 0)
        #expect(angle > 0.0)
        #expect(angle < 1.0)
        #expect(abs(angle - 0.5) < 0.01, "Half-max tilt should give ~0.5 fold angle")
    }

    @Test
    func rightTiltProducesZeroFoldAngle() {
        // Right tilt = roll increases from neutral (positive delta) → clamps to 0.
        let angle = SymmetryFoldView.foldAngle(tiltRoll: .pi / 8, neutralRoll: 0)
        #expect(angle == 0.0, "Right tilt should not fold the shape")
    }

    // MARK: - Clamping

    @Test
    func foldAngleClampedToZeroOneRange() {
        // Beyond max tilt: should clamp to 1.0, not exceed it.
        let beyondMax = SymmetryFoldView.foldAngle(tiltRoll: -.pi, neutralRoll: 0)
        #expect(beyondMax == 1.0, "Extreme left tilt should clamp fold angle to 1.0")

        // Beyond right: should clamp to 0.0.
        let beyondRight = SymmetryFoldView.foldAngle(tiltRoll: .pi, neutralRoll: 0)
        #expect(beyondRight == 0.0, "Extreme right tilt should clamp fold angle to 0.0")
    }

    @Test
    func fullMaxTiltProducesFullyFoldedAngle() {
        // Exactly pi/4 left of neutral = foldAngle exactly 1.0.
        let angle = SymmetryFoldView.foldAngle(tiltRoll: -.pi / 4, neutralRoll: 0)
        #expect(abs(angle - 1.0) < 0.001, "Max left tilt (pi/4) should produce fold angle 1.0")
    }

    // MARK: - Neutral offset independence

    @Test
    func foldAngleIndependentOfAbsoluteDeviceRoll() {
        // The fold angle should be the same for any absolute device roll,
        // as long as the DELTA from neutral is the same.
        let delta = -Double.pi / 6
        let neutral1 = 0.0
        let neutral2 = 0.5
        let neutral3 = -0.8

        let a1 = SymmetryFoldView.foldAngle(tiltRoll: neutral1 + delta, neutralRoll: neutral1)
        let a2 = SymmetryFoldView.foldAngle(tiltRoll: neutral2 + delta, neutralRoll: neutral2)
        let a3 = SymmetryFoldView.foldAngle(tiltRoll: neutral3 + delta, neutralRoll: neutral3)

        #expect(abs(a1 - a2) < 0.001, "Same delta must produce the same fold angle regardless of neutral")
        #expect(abs(a2 - a3) < 0.001, "Same delta must produce the same fold angle regardless of neutral")
    }

    // MARK: - Success threshold

    @Test
    func foldAngleAt95PercentTriggerSuccess() {
        // 95% of max tilt = delta = -0.95 * pi/4
        let roll = -0.95 * .pi / 4
        let angle = SymmetryFoldView.foldAngle(tiltRoll: roll, neutralRoll: 0)
        #expect(angle >= 0.95, "95% tilt should produce fold angle >= 0.95")
    }

    @Test
    func foldAngleBelowThresholdDoesNotTriggerSuccess() {
        // 80% of max tilt should NOT reach the success threshold.
        let roll = -0.80 * .pi / 4
        let angle = SymmetryFoldView.foldAngle(tiltRoll: roll, neutralRoll: 0)
        #expect(angle < 0.95, "80% tilt should produce fold angle < 0.95")
    }

    @Test
    func successTitleUsesShapeName() {
        #expect(SymmetryFoldView.successTitle(for: "heart") == "Heart is symmetric!")
        #expect(SymmetryFoldView.successTitle(for: "hexagon") == "Hexagon is symmetric!")
    }

    @Test
    func successSpeechNamesLineOfSymmetry() {
        #expect(
            SymmetryFoldView.successSpeech(for: "butterfly")
                == "Perfectly folded! The line of symmetry makes both sides of the butterfly match."
        )
    }

    @Test
    func creativeContentPackUsesDistinctBilateralMotifs() {
        #expect(SymmetryFoldView.creativeLevelNames == ["heart", "butterfly", "flower", "kite", "leaf", "badge"])
        #expect(Set(SymmetryFoldView.creativeLevelNames).count == SymmetryFoldView.creativeLevelNames.count)
    }

    @Test
    func coachingCopySupportsDirectionAndNearMatch() {
        #expect(SymmetryFoldView.nearMatchHint == "Almost there — line up both halves")
        #expect(SymmetryFoldView.wrongDirectionHint == "Other way — tilt left")
        #expect(SymmetryFoldView.wrongDirectionSpeech(for: "kite") == "Try the other way. Tilt left to fold the kite.")
    }

    @Test
    func mirrorMissionLabelCountsEarnedBadges() {
        #expect(SymmetryFoldView.mirrorMissionLabel(currentLevel: 1, totalLevels: 6) == "Mirror mission • 0/6 badges")
        #expect(SymmetryFoldView.mirrorMissionLabel(currentLevel: 4, totalLevels: 6) == "Mirror mission • 3/6 badges")
        #expect(SymmetryFoldView.mirrorMissionLabel(currentLevel: 99, totalLevels: 6) == "Mirror mission • 6/6 badges")
    }

    @Test
    func challengeCountdownRoundsUpAndClamps() {
        #expect(SymmetryFoldView.challengeCountdownText(for: 7.01) == "8s left")
        #expect(SymmetryFoldView.challengeCountdownText(for: 0.2) == "1s left")
        #expect(SymmetryFoldView.challengeCountdownText(for: -1) == "0s left")
    }

    @Test
    func timedChallengePromptExplainsDelayedTimerStart() {
        #expect(SymmetryFoldView.tapPromptTitle(isTimedChallenge: true, didTimeout: false) == "Start timed challenge")
        #expect(
            SymmetryFoldView.tapPromptMessage(isTimedChallenge: true, didTimeout: false)
                == "Tap when ready. The timer starts after your tap."
        )
    }

    @Test
    func timedChallengeRetryPromptChangesAfterTimeout() {
        #expect(SymmetryFoldView.tapPromptTitle(isTimedChallenge: true, didTimeout: true) == "Time's up")
        #expect(
            SymmetryFoldView.tapPromptMessage(isTimedChallenge: true, didTimeout: true)
                == "Tap to retry this shape with a fresh timer"
        )
    }
}
