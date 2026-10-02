import CoreGraphics
import Foundation

enum AngleArcadeWorld: String, CaseIterable, Codable, Identifiable {
    case garden, builder, moon

    var id: String { rawValue }
    var title: String {
        switch self {
        case .garden: "Garden"
        case .builder: "Builder"
        case .moon: "Moon"
        }
    }
    var subtitle: String {
        switch self {
        case .garden: "Grow with your aim"
        case .builder: "Turn and build"
        case .moon: "Try a lighter world"
        }
    }
    var symbolName: String {
        switch self {
        case .garden: "leaf.fill"
        case .builder: "house.fill"
        case .moon: "moon.stars.fill"
        }
    }
}

struct AngleArcadeAim: Equatable, Codable {
    let angle: Double
    let power: Double
}

struct AngleArcadeLevel: Identifiable, Equatable {
    enum Kind: Equatable { case launch, rotation }

    let id: String
    let world: AngleArcadeWorld
    let title: String
    let prompt: String
    let successExplanation: String
    let kind: Kind
    let startingAngle: Double
    let startingPower: Double
    let allowsAngle: Bool
    let allowsPower: Bool
    let target: AngleArcadeTarget?
    let gravity: Double
    let rotationTarget: Double?
    let referenceAngle: Double?
    let guided: Bool
    let authoredSolution: AngleArcadeAim
    let bounds: CGRect
    let obstacles: [AngleArcadeObstacle]
    let projectileSymbol: String
    let comparisonGravity: Double?

    var angleRange: ClosedRange<Double> { kind == .rotation ? 0...120 : AngleArcadeModel.angleRange }
    var angleStep: Double { kind == .rotation ? 15 : AngleArcadeModel.angleStep }
    var projectileRadius: Double { 8 }
    var rotationTolerance: Double { 5 }

    func shot(angle: Double, power: Double, gravity override: Double? = nil, sampleCount: Int = 80) -> AngleArcadeShot? {
        guard let target, kind == .launch else { return nil }
        return AngleArcadeModel.shot(
            angle: angle, power: power, target: target, sampleCount: sampleCount, gravity: override ?? gravity,
            obstacles: obstacles, projectileRadius: projectileRadius, sweptTargetCollision: true
        )
    }

    func succeeds(angle: Double, power: Double) -> Bool {
        if kind == .rotation {
            guard let rotationTarget else { return false }
            return abs(angle - rotationTarget) <= rotationTolerance
        }
        return shot(angle: angle, power: power, sampleCount: 2)?.hit == true
    }
}

enum AngleArcadeCampaign {
    static let levels: [AngleArcadeLevel] = [
        launch("garden-guided", world: .garden, title: "First flower",
               prompt: "Send a seed to the basket. Your first shot is ready. Fire!",
               success: "Your angle helped the seed travel up and into the basket.",
               start: .init(angle: 35, power: 75), solution: .init(angle: 35, power: 75),
               distance: 360, height: 65, radius: 28, angle: false, power: false, guided: true),
        launch("garden-raised", world: .garden, title: "Raised basket",
               prompt: "The basket is higher. Lift the cannon angle, then fire.",
               success: "A higher angle lifted the seed higher. The power stayed the same.",
               start: .init(angle: 35, power: 75), solution: .init(angle: 45, power: 75),
               distance: 360, height: 128, radius: 18, angle: true, power: false),
        launch("garden-fence", world: .garden, title: "Over the fence",
               prompt: "Lift your angle and add power to reach the basket over the fence.",
               success: "You used angle and power together to clear the fence.",
               start: .init(angle: 35, power: 70), solution: .init(angle: 45, power: 80),
               distance: 440, height: 110, radius: 22, angle: true, power: true,
               obstacles: [.init(id: "garden-fence", title: "Fence", rect: CGRect(x: 202, y: 0, width: 16, height: 112))]),
        rotation("builder-corner", title: "Turn the corner",
                 prompt: "Turn the square until its corner matches the glowing corner.",
                 success: "You turned the square. Its corner stayed a square corner.", start: 15, solution: 45),
        rotation("builder-quarter-turn", title: "Quarter-turn gate",
                 prompt: "Turn the gate to match the arrow. A quarter turn opens it.",
                 success: "A quarter turn moves the gate from flat to upright.", start: 0, solution: 90),
        rotation("builder-transfer", title: "Another corner",
                 prompt: "Turn this square to match the new glowing corner.",
                 success: "The square turned a different way, but its corner stayed the same.", start: 90, solution: 30),
        launch("moon-earth", world: .moon, title: "Earth launch",
               prompt: "Try a launch on Earth. Add power to reach the landing pad.",
               success: "You found the power for Earth. Keep that shot in mind.",
               start: .init(angle: 45, power: 70), solution: .init(angle: 45, power: 80),
               distance: 430, height: 115, radius: 22, angle: false, power: true),
        launch("moon-compare", world: .moon, title: "Same shot, Moon",
               prompt: "The same shot goes higher here. Try less power for this Moon pad.",
               success: "The Moon pulls less in our game. Less power reached the same pad.",
               start: .init(angle: 45, power: 80), solution: .init(angle: 45, power: 70),
               distance: 430, height: 115, radius: 22, angle: false, power: true,
               gravity: 74, comparisonGravity: 98),
        launch("moon-transfer", world: .moon, title: "Moon rock hop",
               prompt: "Lift your angle and add power to reach the pad over the Moon rock.",
               success: "You used your angle and power on the Moon to clear a new obstacle.",
               start: .init(angle: 40, power: 70), solution: .init(angle: 50, power: 80),
               distance: 530, height: 195, radius: 22, angle: true, power: true,
               gravity: 74,
               obstacles: [.init(id: "moon-rock", title: "Moon rock", rect: CGRect(x: 252, y: 0, width: 16, height: 140))])
    ]

    static func levels(in world: AngleArcadeWorld) -> [AngleArcadeLevel] {
        levels.filter { $0.world == world }
    }

    static func level(id: String) -> AngleArcadeLevel? { levels.first { $0.id == id } }

    private static func launch(
        _ id: String, world: AngleArcadeWorld, title: String, prompt: String, success: String,
        start: AngleArcadeAim, solution: AngleArcadeAim, distance: Double, height: Double, radius: Double,
        angle: Bool, power: Bool, guided: Bool = false, gravity: Double = 98,
        comparisonGravity: Double? = nil, obstacles: [AngleArcadeObstacle] = []
    ) -> AngleArcadeLevel {
        AngleArcadeLevel(
            id: id, world: world, title: title, prompt: prompt, successExplanation: success, kind: .launch,
            startingAngle: start.angle, startingPower: start.power, allowsAngle: angle, allowsPower: power,
            target: .init(id: id, title: world == .garden ? "Basket" : "Landing pad", distance: distance,
                          height: height, radius: radius, recommendedAngle: solution.angle, recommendedPower: solution.power),
            gravity: gravity, rotationTarget: nil, referenceAngle: nil, guided: guided,
            authoredSolution: solution,
            bounds: launchBounds(id: id, world: world),
            obstacles: obstacles, projectileSymbol: world == .garden ? "leaf.fill" : "paperplane.fill",
            comparisonGravity: comparisonGravity
        )
    }

    private static func launchBounds(id: String, world: AngleArcadeWorld) -> CGRect {
        let size: CGSize
        switch id {
        case "garden-guided": size = CGSize(width: 460, height: 200)
        case "garden-raised": size = CGSize(width: 650, height: 350)
        case "moon-earth": size = CGSize(width: 1100, height: 350)
        case "moon-compare": size = CGSize(width: 1350, height: 430)
        default: size = CGSize(width: world == .moon ? 1350 : 1100, height: world == .moon ? 700 : 550)
        }
        // Include the physical ball below the launch baseline and leave label room.
        return CGRect(origin: CGPoint(x: -25, y: -25), size: size)
    }

    private static func rotation(_ id: String, title: String, prompt: String, success: String, start: Double, solution: Double) -> AngleArcadeLevel {
        AngleArcadeLevel(
            id: id, world: .builder, title: title, prompt: prompt, successExplanation: success, kind: .rotation,
            startingAngle: start, startingPower: 75, allowsAngle: true, allowsPower: false,
            target: nil, gravity: 98, rotationTarget: solution, referenceAngle: 90, guided: false,
            authoredSolution: .init(angle: solution, power: 75), bounds: CGRect(x: 0, y: 0, width: 800, height: 500),
            obstacles: [], projectileSymbol: "square", comparisonGravity: nil
        )
    }
}
