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
}
