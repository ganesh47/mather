import CoreGraphics
import Foundation

struct AngleArcadeTarget: Equatable, Identifiable {
    let id: String
    let title: String
    let distance: Double
    let height: Double
    let radius: Double
    let recommendedAngle: Double
    let recommendedPower: Double

    static let defaultTargets: [AngleArcadeTarget] = [
        .init(
            id: "garden-ledger",
            title: "Garden ledge",
            distance: 390,
            height: 64,
            radius: 30,
            recommendedAngle: 35,
            recommendedPower: 77
        ),
        .init(
            id: "moon-dock",
            title: "Moon dock",
            distance: 520,
            height: 110,
            radius: 32,
            recommendedAngle: 45,
            recommendedPower: 85
        ),
        .init(
            id: "bell-tower",
            title: "Bell tower",
            distance: 610,
            height: 170,
            radius: 36,
            recommendedAngle: 55,
            recommendedPower: 94
        )
    ]
}

struct AngleArcadeShot: Equatable {
    let angle: Double
    let power: Double
    let target: AngleArcadeTarget
    let path: [CGPoint]
    let landingX: Double
    let heightAtTarget: Double
    let verticalDelta: Double
    let hit: Bool
}

enum AngleArcadeModel {
    static let angleRange: ClosedRange<Double> = 20...75
    static let powerRange: ClosedRange<Double> = 40...100
    static let angleStep: Double = 5
    static let powerStep: Double = 5
    static let gravity: Double = 98
    static let velocityScale: Double = 3

    static func adjustedAngle(_ angle: Double, direction: Int) -> Double {
        clamp(angle + Double(direction) * angleStep, to: angleRange)
    }

    static func adjustedPower(_ power: Double, direction: Int) -> Double {
        clamp(power + Double(direction) * powerStep, to: powerRange)
    }

    static func shot(
        angle: Double,
        power: Double,
        target: AngleArcadeTarget,
        sampleCount: Int = 80
    ) -> AngleArcadeShot {
        let safeAngle = clamp(angle, to: angleRange)
        let safePower = clamp(power, to: powerRange)
        let radians = safeAngle * .pi / 180
        let velocity = safePower * velocityScale
        let vx = max(1, velocity * cos(radians))
        let vy = velocity * sin(radians)
        let landingTime = max(0, (2 * vy) / gravity)
        let landingX = vx * landingTime
        let targetTime = target.distance / vx
        let heightAtTarget = height(at: targetTime, verticalVelocity: vy)
        let verticalDelta = heightAtTarget - target.height
        let hit = abs(verticalDelta) <= target.radius
        let count = max(2, sampleCount)
        let path = (0..<count).map { index in
            let progress = Double(index) / Double(count - 1)
            let t = landingTime * progress
            return CGPoint(x: vx * t, y: height(at: t, verticalVelocity: vy))
        }

        return AngleArcadeShot(
            angle: safeAngle,
            power: safePower,
            target: target,
            path: path,
            landingX: landingX,
            heightAtTarget: heightAtTarget,
            verticalDelta: verticalDelta,
            hit: hit
        )
    }

    static func nextTargetIndex(after index: Int, targetCount: Int) -> Int {
        guard targetCount > 0 else { return 0 }
        return (index + 1) % targetCount
    }

    private static func height(at time: Double, verticalVelocity: Double) -> Double {
        verticalVelocity * time - 0.5 * gravity * time * time
    }

    private static func clamp(_ value: Double, to range: ClosedRange<Double>) -> Double {
        min(max(value, range.lowerBound), range.upperBound)
    }
}
