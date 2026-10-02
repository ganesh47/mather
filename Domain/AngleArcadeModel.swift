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

    var startingPower: Double {
        max(AngleArcadeModel.powerRange.lowerBound, recommendedPower - 10)
    }

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

enum AngleArcadeShotOutcome: Equatable {
    case hit
    case short
    case above
    case below
    case blocked
}

struct AngleArcadeObstacle: Equatable, Identifiable {
    let id: String
    let title: String
    let rect: CGRect
}

struct AngleArcadeShot: Equatable {
    let angle: Double
    let power: Double
    let target: AngleArcadeTarget
    let path: [CGPoint]
    let landingX: Double
    let heightAtTarget: Double
    let verticalDelta: Double
    let outcome: AngleArcadeShotOutcome
    let flightDuration: Double
    let obstacleID: String?
    let gravity: Double

    var hit: Bool { outcome == .hit }
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
        sampleCount: Int = 80,
        gravity: Double = AngleArcadeModel.gravity,
        obstacles: [AngleArcadeObstacle] = [],
        projectileRadius: Double = 0,
        sweptTargetCollision: Bool = false
    ) -> AngleArcadeShot {
        let safeAngle = clamp(angle, to: angleRange)
        let safePower = clamp(power, to: powerRange)
        let safeGravity = gravity.isFinite && gravity > 0 ? gravity : AngleArcadeModel.gravity
        let radians = safeAngle * .pi / 180
        let velocity = safePower * velocityScale
        let vx = max(1, velocity * cos(radians))
        let vy = velocity * sin(radians)
        let landingTime = max(0, (2 * vy) / safeGravity)
        let landingX = vx * landingTime
        let targetTime = target.distance / vx
        // Once the ball reaches the ground, its flight is over. Extrapolating
        // past landing would report an impossible height below the playfield.
        let reachesTarget = targetTime <= landingTime
        let heightAtTarget = max(0, height(at: min(targetTime, landingTime), verticalVelocity: vy, gravity: safeGravity))
        let verticalDelta = heightAtTarget - target.height
        let targetImpact = sweptTargetCollision ? firstTargetImpact(
            target, radius: target.radius + max(0, projectileRadius),
            vx: vx, vy: vy, gravity: safeGravity, until: landingTime
        ) : nil
        var outcome: AngleArcadeShotOutcome
        if targetImpact != nil {
            outcome = .hit
        } else if !reachesTarget {
            outcome = .short
        } else if !sweptTargetCollision && abs(verticalDelta) <= target.radius + max(0, projectileRadius) {
            outcome = .hit
        } else {
            outcome = verticalDelta > 0 ? .above : .below
        }
        var flightDuration = outcome == .hit ? targetImpact ?? targetTime : landingTime
        // Solve the swept projectile/rectangle intersection analytically. Hit
        // testing is independent of the number of samples used for rendering.
        var obstacleID: String?
        for obstacle in obstacles {
            if let impactTime = firstImpact(
                obstacle.rect.insetBy(dx: -max(0, projectileRadius), dy: -max(0, projectileRadius)),
                vx: vx, vy: vy, gravity: safeGravity, until: flightDuration
            ), impactTime <= flightDuration {
                flightDuration = impactTime
                outcome = .blocked
                obstacleID = obstacle.id
            }
        }
        let count = max(2, sampleCount)
        let path = (0..<count).map { index in
            let progress = Double(index) / Double(count - 1)
            let t = flightDuration * progress
            return CGPoint(x: vx * t, y: max(0, height(at: t, verticalVelocity: vy, gravity: safeGravity)))
        }

        return AngleArcadeShot(
            angle: safeAngle,
            power: safePower,
            target: target,
            path: path,
            landingX: landingX,
            heightAtTarget: heightAtTarget,
            verticalDelta: verticalDelta,
            outcome: outcome,
            flightDuration: flightDuration,
            obstacleID: obstacleID,
            gravity: safeGravity
        )
    }

    static func nextTargetIndex(after index: Int, targetCount: Int) -> Int {
        guard targetCount > 0 else { return 0 }
        return (index + 1) % targetCount
    }

    private static func height(at time: Double, verticalVelocity: Double, gravity: Double) -> Double {
        verticalVelocity * time - 0.5 * gravity * time * time
    }

    private static func firstImpact(_ rect: CGRect, vx: Double, vy: Double, gravity: Double, until end: Double) -> Double? {
        let first = max(0, Double(rect.minX) / vx)
        let last = min(end, Double(rect.maxX) / vx)
        guard first <= last else { return nil }
        var candidates = [first, last]
        for boundary in [Double(rect.minY), Double(rect.maxY)] {
            let discriminant = vy * vy - 2 * gravity * boundary
            if discriminant >= 0 {
                let root = sqrt(discriminant)
                candidates.append(contentsOf: [(vy - root) / gravity, (vy + root) / gravity])
            }
        }
        return candidates.filter { time in
            guard time >= first - 0.0000001, time <= last + 0.0000001 else { return false }
            let y = height(at: time, verticalVelocity: vy, gravity: gravity)
            return y >= Double(rect.minY) - 0.0000001 && y <= Double(rect.maxY) + 0.0000001
        }.min()
    }

    private static func firstTargetImpact(_ target: AngleArcadeTarget, radius: Double, vx: Double, vy: Double, gravity: Double, until end: Double) -> Double? {
        // Squared distance from the ballistic center to the target circle is a
        // quartic. Its first zero is contact; derivative roots partition it into
        // monotone intervals, so even a grazing touch cannot slip between samples.
        let coefficients = [
            0.25 * gravity * gravity,
            -gravity * vy,
            vx * vx + vy * vy + gravity * target.height,
            -2 * (vx * target.distance + vy * target.height),
            target.distance * target.distance + target.height * target.height - radius * radius
        ]
        if polynomial(coefficients, at: 0) <= 0 { return 0 }
        return polynomialRoots(coefficients, lower: 0, upper: end).first
    }

    private static func polynomial(_ coefficients: [Double], at x: Double) -> Double {
        coefficients.reduce(0) { $0 * x + $1 }
    }

    private static func polynomialRoots(_ coefficients: [Double], lower: Double, upper: Double) -> [Double] {
        let degree = coefficients.count - 1
        guard degree > 0, lower <= upper else { return [] }
        if degree == 1 {
            let root = -coefficients[1] / coefficients[0]
            return root >= lower && root <= upper ? [root] : []
        }
        let derivative = coefficients.dropLast().enumerated().map { Double(degree - $0.offset) * $0.element }
        let critical = polynomialRoots(derivative, lower: lower, upper: upper)
        let boundaries = [lower] + critical + [upper]
        var roots: [Double] = []
        for boundary in boundaries where abs(polynomial(coefficients, at: boundary)) < 0.000001 {
            roots.append(boundary)
        }
        for index in 0..<(boundaries.count - 1) {
            var left = boundaries[index]
            var right = boundaries[index + 1]
            var leftValue = polynomial(coefficients, at: left)
            let rightValue = polynomial(coefficients, at: right)
            guard (leftValue < 0) != (rightValue < 0) else { continue }
            for _ in 0..<48 {
                let middle = (left + right) / 2
                let value = polynomial(coefficients, at: middle)
                if (leftValue < 0) == (value < 0) {
                    left = middle
                    leftValue = value
                } else { right = middle }
            }
            roots.append((left + right) / 2)
        }
        return roots.sorted()
    }

    private static func clamp(_ value: Double, to range: ClosedRange<Double>) -> Double {
        min(max(value, range.lowerBound), range.upperBound)
    }
}
