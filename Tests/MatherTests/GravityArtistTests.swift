import Testing
import CoreGraphics
@testable import Mather

@Suite("GravityArtist")
struct GravityArtistTests {

    private let cannon = CGPoint(x: 60, y: 500)
    private let groundY: Double = 500
    private let canvasW: Double = 800

    // MARK: - arcPoints

    @Test func arcPointsNotEmpty() {
        let pts = GravityArtistPhysics.arcPoints(
            angleDeg: 45, velocity: 350,
            cannonOrigin: cannon, canvasHeight: groundY)
        #expect(!pts.isEmpty)
    }

    @Test func arcStartsAtCannon() {
        let pts = GravityArtistPhysics.arcPoints(
            angleDeg: 45, velocity: 350,
            cannonOrigin: cannon, canvasHeight: groundY)
        guard let first = pts.first else { return }
        #expect(abs(first.x - cannon.x) < 1)
        #expect(abs(first.y - cannon.y) < 1)
    }

    @Test func arcMovesRightward() {
        let pts = GravityArtistPhysics.arcPoints(
            angleDeg: 30, velocity: 350,
            cannonOrigin: cannon, canvasHeight: groundY)
        guard let first = pts.first, let last = pts.last else { return }
        #expect(last.x > first.x)
    }

    @Test func arcReachesGround() {
        // Last point should be at or near groundY
        let pts = GravityArtistPhysics.arcPoints(
            angleDeg: 45, velocity: 350,
            cannonOrigin: cannon, canvasHeight: groundY)
        guard let last = pts.last else { return }
        #expect(last.y <= groundY + 20)   // within one dt step
    }

    @Test func steepAngleLandsCloser() {
        // Higher angle → shorter range (for same power, angles > 45° land shorter)
        let x80 = GravityArtistPhysics.landingX(
            angleDeg: 80, velocity: 350, cannonOrigin: cannon, canvasHeight: groundY)
        let x45 = GravityArtistPhysics.landingX(
            angleDeg: 45, velocity: 350, cannonOrigin: cannon, canvasHeight: groundY)
        #expect(x80 < x45)
    }

    @Test func shallowAngleLandsCloserThan45() {
        let x10 = GravityArtistPhysics.landingX(
            angleDeg: 10, velocity: 350, cannonOrigin: cannon, canvasHeight: groundY)
        let x45 = GravityArtistPhysics.landingX(
            angleDeg: 45, velocity: 350, cannonOrigin: cannon, canvasHeight: groundY)
        #expect(x10 < x45)
    }

    @Test func higherPowerLandsFarther() {
        let xLow = GravityArtistPhysics.landingX(
            angleDeg: 45, velocity: 200, cannonOrigin: cannon, canvasHeight: groundY)
        let xHigh = GravityArtistPhysics.landingX(
            angleDeg: 45, velocity: 500, cannonOrigin: cannon, canvasHeight: groundY)
        #expect(xHigh > xLow)
    }

    // MARK: - isHit

    @Test func exactHitDetected() {
        #expect(GravityArtistPhysics.isHit(firedLandingX: 400, targetX: 400, hitRadius: 50))
    }

    @Test func hitAtEdgeOfRadius() {
        #expect(GravityArtistPhysics.isHit(firedLandingX: 450, targetX: 400, hitRadius: 50))
        #expect(GravityArtistPhysics.isHit(firedLandingX: 350, targetX: 400, hitRadius: 50))
    }

    @Test func missJustOutsideRadius() {
        #expect(!GravityArtistPhysics.isHit(firedLandingX: 451, targetX: 400, hitRadius: 50))
        #expect(!GravityArtistPhysics.isHit(firedLandingX: 349, targetX: 400, hitRadius: 50))
    }

    @Test func missWide() {
        #expect(!GravityArtistPhysics.isHit(firedLandingX: 600, targetX: 400, hitRadius: 50))
    }

    // MARK: - velocityForPower mapping

    @Test func velocityMappingCoversAllPowers() {
        #expect(GravityArtistPhysics.velocityForPower[1] != nil)
        #expect(GravityArtistPhysics.velocityForPower[2] != nil)
        #expect(GravityArtistPhysics.velocityForPower[3] != nil)
    }

    @Test func velocityIncreasesWithPower() {
        let v1 = GravityArtistPhysics.velocityForPower[1]!
        let v2 = GravityArtistPhysics.velocityForPower[2]!
        let v3 = GravityArtistPhysics.velocityForPower[3]!
        #expect(v1 < v2)
        #expect(v2 < v3)
    }

    // MARK: - targetX

    @Test func targetXWithinCanvas() {
        let tx = GravityArtistPhysics.targetX(
            angleDeg: 45, velocity: 350,
            cannonOrigin: cannon, canvasWidth: canvasW, canvasHeight: groundY)
        #expect(tx > cannon.x)
        #expect(tx < canvasW)
    }

    @Test func launchArcUsesLockedPowerAfterPowerSelectionChanges() {
        var state = GravityArtistRoundState()
        state.selectPower(1)
        let locked = state.lockPrediction(angleDeg: 45)

        state.selectPower(3)
        let fired = state.fireLockedPrediction()

        #expect(locked.power == 1)
        #expect(fired == locked)
        #expect(state.selectedPower == 1)
    }

    @Test func powerSelectionIsMutableAgainAfterNewRoundStarts() {
        var state = GravityArtistRoundState()
        _ = state.lockPrediction(angleDeg: 45)
        #expect(state.phase == .predicted)

        state.startNewRound(targetAngle: 55)
        state.selectPower(3)

        #expect(state.phase == .aim)
        #expect(state.selectedPower == 3)
        #expect(state.targetAngle == 55)
        #expect(state.predictedLaunch == nil)
        #expect(state.firedLaunch == nil)
    }

    @Test func geometryDependentArcRecomputesForResizedCanvasFromSameLaunch() {
        let launch = GravityArtistLaunch(angleDeg: 45, power: 2)
        let compact = CGSize(width: 600, height: 400)
        let expanded = CGSize(width: 900, height: 700)

        let compactArc = GravityArtistPhysics.arcPoints(launch: launch, canvasSize: compact)
        let expandedArc = GravityArtistPhysics.arcPoints(launch: launch, canvasSize: expanded)

        #expect(compactArc.first == GravityArtistPhysics.cannonOrigin(in: compact))
        #expect(expandedArc.first == GravityArtistPhysics.cannonOrigin(in: expanded))
        #expect(compactArc.last?.y ?? 0 <= GravityArtistPhysics.groundY(in: compact) + 20)
        #expect(expandedArc.last?.y ?? 0 <= GravityArtistPhysics.groundY(in: expanded) + 20)
        #expect(compactArc.first != expandedArc.first)
    }

    @Test func targetXRecomputesWithinResizedCanvasForSameTarget() {
        let targetAngle = 55.0
        let power = 2
        let compact = CGSize(width: 420, height: 320)
        let expanded = CGSize(width: 840, height: 640)

        let compactX = GravityArtistPhysics.targetX(angleDeg: targetAngle, power: power, canvasSize: compact)
        let expandedX = GravityArtistPhysics.targetX(angleDeg: targetAngle, power: power, canvasSize: expanded)

        #expect(compactX >= GravityArtistPhysics.cannonOrigin(in: compact).x + 40)
        #expect(compactX <= compact.width - 40)
        #expect(expandedX >= GravityArtistPhysics.cannonOrigin(in: expanded).x + 40)
        #expect(expandedX <= expanded.width - 40)
        #expect(expandedX != compactX)
    }
}

@Suite("GravitySensorPhysics")
struct GravitySensorPhysicsTests {
    @Test func normalizedVectorPointsDownAtNeutral() {
        let vector = GravitySensorPhysics.normalizedVector(roll: 0, neutralRoll: 0)
        #expect(abs(vector.dx) < 0.001)
        #expect(abs(vector.dy - 1) < 0.001)
    }

    @Test func normalizedVectorRespondsToRollDirection() {
        let right = GravitySensorPhysics.normalizedVector(roll: .pi / 6, neutralRoll: 0)
        let left = GravitySensorPhysics.normalizedVector(roll: -.pi / 6, neutralRoll: 0)
        #expect(right.dx > 0)
        #expect(left.dx < 0)
        #expect(abs(right.dy - left.dy) < 0.001)
    }

    @Test func pebblePositionClampsToTrayBounds() {
        let bounds = CGRect(x: 0, y: 0, width: 100, height: 100)
        let pos = GravitySensorPhysics.pebblePosition(origin: CGPoint(x: 50, y: 50), vector: CGVector(dx: 4, dy: 4), distance: 100, bounds: bounds)
        #expect(pos.x == 100)
        #expect(pos.y == 100)
    }
}
