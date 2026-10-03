import SwiftUI

/// TV presentation only. Geometry and every flight sample come from the campaign engine.
/// This view owns no clock, input, or completion callback.
@MainActor
struct AngleArcadeTVScene: View {
    let engine: AngleArcadeEngine
    let flightProgress: Double
    let reduceMotion: Bool

    private var moonSky: Bool { engine.currentWorld == .moon && engine.level.gravity < 98 }
    private var ink: Color { moonSky ? Color(red: 0.91, green: 0.95, blue: 1) : Color(red: 0.10, green: 0.24, blue: 0.29) }
    private var coral: Color { moonSky ? Color(red: 1, green: 0.73, blue: 0.32) : Color(red: 0.91, green: 0.24, blue: 0.15) }
    private var blue: Color { moonSky ? Color(red: 0.48, green: 0.85, blue: 1) : Color(red: 0.08, green: 0.39, blue: 0.65) }
    private let successGreen = Color(red: 0.10, green: 0.58, blue: 0.34)

    var body: some View {
        Canvas { context, size in
            drawWorld(context: context, size: size)
            if engine.level.kind == .rotation {
                drawRotation(context: context, size: size)
            } else {
                drawLaunch(context: context, size: size)
            }
        }
        .background(background)
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .overlay(alignment: .topLeading) {
            if engine.level.kind == .launch && engine.previousShot != nil {
                Label(engine.level.comparisonGravity != nil ? "Earth path" : "Last try", systemImage: "point.topleft.down.to.point.bottomright.curvepath")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(ink.opacity(0.85))
                    .padding(18)
            }
        }
        .overlay {
            GeometryReader { geometry in
                if geometry.size.width >= 600 && engine.phase == .result && engine.success {
                    Text(degreeDiscovery)
                        .font(.system(size: 40, weight: .heavy, design: .rounded))
                        .foregroundStyle(Color(red: 0.10, green: 0.24, blue: 0.29))
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(.white.opacity(0.93), in: Capsule())
                        .padding(18)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                        .accessibilityLabel(degreeDiscovery.replacingOccurrences(of: "°", with: " degrees"))
                        .accessibilityIdentifier("angle-arcade-degree-reveal")
                }
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel(engine.level.title)
        .accessibilityValue(sceneDescription)
        .accessibilityIdentifier("angle-arcade-scene")
    }

    private var degreeDiscovery: String {
        let label = engine.level.kind == .launch ? "Launch" : engine.level.id == "builder-quarter-turn" ? "Turned" : "Direction"
        return "\(label) \(Int(engine.angle))°"
    }

    // Keep the shared scene's accessibility contract; decoration does not describe a result.
    private var sceneDescription: String {
        if engine.phase == .flying { return "Watch the delivery fly." }
        if engine.phase == .result { return engine.feedback }
        if engine.level.kind == .rotation {
            return engine.level.id == "builder-quarter-turn" ? "Turn the gate around its hinge to match the dotted gate. \(engine.hint)" : "The whole square turns. Its corner stays the same. Match the dotted square. \(engine.hint)"
        }
        return "The shaded wedge shows the launch angle. \(engine.hint)"
    }

    private var background: LinearGradient {
        let colors: [Color]
        switch engine.currentWorld {
        case .garden:
            colors = [Color(red: 0.69, green: 0.89, blue: 0.96), Color(red: 0.96, green: 0.98, blue: 0.81)]
        case .builder:
            colors = [Color(red: 0.88, green: 0.94, blue: 0.98), Color(red: 1, green: 0.93, blue: 0.78)]
        case .moon:
            colors = moonSky
                ? [Color(red: 0.12, green: 0.17, blue: 0.34), Color(red: 0.28, green: 0.32, blue: 0.51)]
                : [Color(red: 0.67, green: 0.86, blue: 0.98), Color(red: 0.92, green: 0.97, blue: 0.94)]
        }
        return LinearGradient(colors: colors, startPoint: .top, endPoint: .bottom)
    }

    private func drawWorld(context: GraphicsContext, size: CGSize) {
        // Background scenery uses screen space and stays behind all mathematical geometry.
        if moonSky {
            for index in 0..<18 {
                let x = size.width * (0.05 + Double((index * 7) % 19) / 21)
                let y = size.height * (0.09 + Double((index * 5) % 11) / 23)
                let side: CGFloat = index.isMultiple(of: 3) ? 3 : 2
                context.fill(Circle().path(in: CGRect(x: x, y: y, width: side, height: side)), with: .color(.white.opacity(0.44)))
            }
            let planet = CGRect(x: size.width * 0.84, y: size.height * 0.14, width: 94, height: 94)
            context.fill(Circle().path(in: planet), with: .color(Color(red: 0.35, green: 0.67, blue: 0.85).opacity(0.70)))
            var continent = Path()
            continent.move(to: CGPoint(x: planet.midX - 28, y: planet.midY - 22))
            continent.addLines([CGPoint(x: planet.midX + 3, y: planet.midY - 33), CGPoint(x: planet.midX + 27, y: planet.midY - 8), CGPoint(x: planet.midX + 8, y: planet.midY + 5), CGPoint(x: planet.midX - 10, y: planet.midY + 28)])
            context.stroke(continent, with: .color(Color(red: 0.67, green: 0.86, blue: 0.72).opacity(0.60)), style: StrokeStyle(lineWidth: 14, lineCap: .round))
        } else if engine.currentWorld == .builder {
            for x in stride(from: CGFloat(30), through: size.width, by: 48) {
                drawPath([CGPoint(x: x, y: 0), CGPoint(x: x, y: size.height)], context: context, color: blue.opacity(0.06), width: 1)
            }
            for y in stride(from: CGFloat(24), through: size.height, by: 48) {
                drawPath([CGPoint(x: 0, y: y), CGPoint(x: size.width, y: y)], context: context, color: blue.opacity(0.06), width: 1)
            }
            let shelfY = size.height * 0.77
            for side in [0.11, 0.85] {
                let x = size.width * side
                context.fill(RoundedRectangle(cornerRadius: 6).path(in: CGRect(x: x - 58, y: shelfY, width: 116, height: 12)), with: .color(blue.opacity(0.14)))
                for index in 0..<3 {
                    let block = CGRect(x: x - 48 + CGFloat(index) * 34, y: shelfY - CGFloat(27 + index * 9), width: 26, height: CGFloat(27 + index * 9))
                    context.fill(RoundedRectangle(cornerRadius: 4).path(in: block), with: .color((index == 1 ? coral : blue).opacity(0.14)))
                }
            }
        } else {
            for cloud in [CGPoint(x: size.width * 0.15, y: size.height * 0.18), CGPoint(x: size.width * 0.65, y: size.height * 0.10), CGPoint(x: size.width * 0.89, y: size.height * 0.30)] {
                context.fill(Capsule().path(in: CGRect(x: cloud.x - 62, y: cloud.y, width: 124, height: 24)), with: .color(.white.opacity(0.36)))
                context.fill(Circle().path(in: CGRect(x: cloud.x - 33, y: cloud.y - 22, width: 48, height: 48)), with: .color(.white.opacity(0.36)))
            }
            var hills = Path()
            hills.move(to: CGPoint(x: 0, y: size.height * 0.82))
            hills.addQuadCurve(to: CGPoint(x: size.width * 0.48, y: size.height * 0.82), control: CGPoint(x: size.width * 0.18, y: size.height * 0.52))
            hills.addQuadCurve(to: CGPoint(x: size.width, y: size.height * 0.82), control: CGPoint(x: size.width * 0.80, y: size.height * 0.56))
            hills.addLine(to: CGPoint(x: size.width, y: size.height)); hills.addLine(to: CGPoint(x: 0, y: size.height)); hills.closeSubpath()
            context.fill(hills, with: .color(Color(red: 0.36, green: 0.64, blue: 0.44).opacity(0.13)))
        }
    }

    private func drawLaunch(context: GraphicsContext, size: CGSize) {
        let bounds = engine.level.bounds
        // Exact shared-scene transform. The camera never changes with aim or outcome.
        let scale = min((size.width * 0.84) / bounds.width, (size.height * 0.70) / bounds.height)
        let origin = CGPoint(x: (size.width - bounds.width * scale) / 2 - bounds.minX * scale, y: size.height * 0.85 + bounds.minY * scale)
        func point(_ value: CGPoint) -> CGPoint {
            CGPoint(x: origin.x + value.x * scale, y: origin.y - value.y * scale)
        }
        let ground = CGRect(x: 0, y: origin.y, width: size.width, height: size.height - origin.y)
        context.fill(Path(ground), with: .color(moonSky ? Color(red: 0.42, green: 0.45, blue: 0.59) : Color(red: 0.38, green: 0.65, blue: 0.36)))
        drawGroundDetails(context: context, ground: ground)
        drawPath([CGPoint(x: 0, y: origin.y), CGPoint(x: size.width, y: origin.y)], context: context, color: ink.opacity(0.20), width: 2)

        for obstacle in engine.level.obstacles {
            let top = point(CGPoint(x: obstacle.rect.minX, y: obstacle.rect.maxY))
            let rect = CGRect(x: top.x, y: top.y, width: obstacle.rect.width * scale, height: obstacle.rect.height * scale)
            drawObstacle(obstacle, rect: rect, context: context)
        }
        if let previous = engine.previousShot {
            drawPath(previous.path.map(point), context: context, color: blue.opacity(moonSky ? 0.65 : 0.48), width: 3, dashed: true)
        }
        if let preview = engine.preview, engine.phase == .aiming {
            let count = engine.showsFullPreview ? preview.path.count : max(2, preview.path.count / 4)
            let points = Array(preview.path.prefix(count)).map(point)
            drawPath(points, context: context, color: .white.opacity(0.75), width: 7, dashed: true)
            drawPath(points, context: context, color: coral.opacity(0.90), width: 4, dashed: true)
        }

        let wedgeRadius = min(82, size.height * 0.18)
        drawWedge(center: origin, radius: wedgeRadius, angle: engine.angle, context: context, color: coral.opacity(0.38))
        drawRay(center: origin, radius: wedgeRadius + 12, angle: 0, context: context, color: ink.opacity(0.65), width: 3)
        drawVehicle(origin: origin, barrelLength: wedgeRadius, context: context)

        if let shot = engine.shot {
            let progress = engine.phase == .result ? 1 : min(max(flightProgress, 0), 1)
            let count = max(1, Int(Double(shot.path.count - 1) * progress) + 1)
            let points = Array(shot.path.prefix(count)).map(point)
            let won = engine.phase == .result && engine.success
            drawPath(points, context: context, color: .white.opacity(0.65), width: 8)
            drawPath(points, context: context, color: won ? successGreen : coral, width: 5)
            if !reduceMotion && engine.phase == .flying {
                drawFlightAccents(points: points, origin: origin, context: context)
            }
            if let ball = points.last {
                let radius = engine.level.projectileRadius * scale
                let ballRect = CGRect(x: ball.x - radius, y: ball.y - radius, width: radius * 2, height: radius * 2)
                context.fill(Circle().path(in: ballRect), with: .color(coral))
                context.stroke(Circle().path(in: ballRect.insetBy(dx: 1, dy: 1)), with: .color(.white), lineWidth: 2)
                drawSymbol(engine.level.projectileSymbol, at: ball, size: radius * 1.4, context: context, color: .white)
                if engine.phase == .result { drawContact(at: ball, won: won, context: context) }
            }
        }
        if let target = engine.level.target {
            let center = point(CGPoint(x: target.distance, y: target.height))
            let radius = target.radius * scale
            let rect = CGRect(x: center.x - radius, y: center.y - radius, width: radius * 2, height: radius * 2)
            context.fill(Circle().path(in: rect), with: .color(.white.opacity(0.82)))
            context.stroke(Circle().path(in: rect), with: .color(engine.success && engine.phase == .result ? successGreen : blue), lineWidth: 3)
            drawSymbol(engine.currentWorld == .garden ? "basket.fill" : "flag.fill", at: CGPoint(x: center.x, y: center.y - radius - 30), size: 34, context: context, color: blue)
            drawLabel("Deliver here", at: CGPoint(x: center.x, y: center.y - radius - 64), size: 23, context: context, color: ink)
        }
    }

    private func drawGroundDetails(context: GraphicsContext, ground: CGRect) {
        // Decorative plants/craters stay in the floor, away from the launch geometry.
        for fraction in [0.06, 0.15, 0.84, 0.94] {
            let x = ground.width * fraction
            if moonSky {
                let crater = CGRect(x: x - 36, y: ground.minY + 28, width: 72, height: 18)
                context.fill(Ellipse().path(in: crater), with: .color(Color.black.opacity(0.15)))
                context.stroke(Ellipse().path(in: crater), with: .color(.white.opacity(0.15)), lineWidth: 2)
            } else {
                drawSymbol("leaf.fill", at: CGPoint(x: x, y: ground.minY + 27), size: 25, context: context, color: Color(red: 0.19, green: 0.46, blue: 0.27).opacity(0.55))
                if engine.currentWorld == .garden {
                    drawSymbol("camera.macro", at: CGPoint(x: x + 14, y: ground.minY + 17), size: 22, context: context, color: Color(red: 1, green: 0.91, blue: 0.57).opacity(0.75))
                }
            }
        }
    }

    private func drawObstacle(_ obstacle: AngleArcadeObstacle, rect: CGRect, context: GraphicsContext) {
        // The silhouette is the exact collision rectangle. All texture stays inside it.
        context.fill(Path(rect), with: .color(engine.currentWorld == .moon ? Color(red: 0.65, green: 0.65, blue: 0.75) : Color(red: 0.63, green: 0.34, blue: 0.13)))
        context.stroke(Path(rect.insetBy(dx: 1, dy: 1)), with: .color(moonSky ? .white.opacity(0.75) : ink.opacity(0.80)), lineWidth: 2)
        for fraction in [0.18, 0.43, 0.68, 0.88] {
            let y = rect.minY + rect.height * fraction
            drawPath([CGPoint(x: rect.minX + 2, y: y), CGPoint(x: rect.maxX - 2, y: y - 3)], context: context, color: .white.opacity(0.38), width: 1)
        }
        drawLabel(obstacle.title, at: CGPoint(x: rect.midX, y: rect.maxY + 58), size: 18, context: context, color: ink)
    }

    private func drawVehicle(origin: CGPoint, barrelLength: CGFloat, context: GraphicsContext) {
        let chassis = Color(red: 0.08, green: 0.35, blue: 0.58)
        let wheel = Color(red: 0.11, green: 0.20, blue: 0.28)
        context.fill(Ellipse().path(in: CGRect(x: origin.x - 63, y: origin.y + 41, width: 126, height: 14)), with: .color(.black.opacity(0.16)))
        for offset in [-34.0, 34.0] {
            let tire = CGRect(x: origin.x + offset - 16, y: origin.y + 22, width: 32, height: 32)
            context.fill(Circle().path(in: tire), with: .color(wheel))
            context.fill(Circle().path(in: tire.insetBy(dx: 9, dy: 9)), with: .color(Color(red: 0.74, green: 0.86, blue: 0.90)))
        }
        context.fill(RoundedRectangle(cornerRadius: 12).path(in: CGRect(x: origin.x - 54, y: origin.y + 5, width: 108, height: 30)), with: .color(chassis))
        context.fill(RoundedRectangle(cornerRadius: 7).path(in: CGRect(x: origin.x - 46, y: origin.y - 5, width: 28, height: 23)), with: .color(Color(red: 0.36, green: 0.67, blue: 0.84)))
        drawSymbol(engine.currentWorld == .garden ? "leaf.fill" : "star.fill", at: CGPoint(x: origin.x + 9, y: origin.y + 20), size: 15, context: context, color: .white.opacity(0.90))
        context.fill(Circle().path(in: CGRect(x: origin.x + 44, y: origin.y + 10, width: 8, height: 8)), with: .color(Color(red: 1, green: 0.91, blue: 0.60)))

        // Recoil is visual only and never changes the launch origin or angle wedge.
        let kick = !reduceMotion && engine.phase == .flying && flightProgress < 0.18
            ? sin(max(0, flightProgress) / 0.18 * .pi) * 8 : 0
        var turret = context
        turret.translateBy(x: origin.x, y: origin.y)
        turret.rotate(by: .degrees(-engine.angle))
        let tube = CGRect(x: -10 - kick, y: -10, width: barrelLength + 17, height: 20)
        turret.fill(RoundedRectangle(cornerRadius: 7).path(in: tube), with: .color(chassis))
        turret.fill(RoundedRectangle(cornerRadius: 5).path(in: tube.insetBy(dx: 3, dy: 4)), with: .color(coral))
        turret.fill(RoundedRectangle(cornerRadius: 3).path(in: CGRect(x: tube.maxX - 9, y: -13, width: 10, height: 26)), with: .color(chassis))
        drawRay(center: origin, radius: barrelLength, angle: engine.angle, context: context, color: .white.opacity(0.85), width: 2)
        context.fill(Circle().path(in: CGRect(x: origin.x - 14, y: origin.y - 14, width: 28, height: 28)), with: .color(chassis))
        context.fill(Circle().path(in: CGRect(x: origin.x - 6, y: origin.y - 6, width: 12, height: 12)), with: .color(.white))
    }

    private func drawFlightAccents(points: [CGPoint], origin: CGPoint, context: GraphicsContext) {
        // The trail uses existing engine samples only; it never extends the flight path.
        let tail = Array(points.dropLast().suffix(6))
        for (index, point) in tail.enumerated() {
            let radius = CGFloat(index + 1) * 0.45 + 1
            context.fill(Circle().path(in: CGRect(x: point.x - radius, y: point.y - radius, width: radius * 2, height: radius * 2)), with: .color(.white.opacity(Double(index + 1) / 9)))
        }
        if flightProgress < 0.18 {
            let spread = CGFloat(max(0, flightProgress) / 0.18)
            for index in 0..<7 {
                let radians = Double(index) * .pi / 3.5
                let center = CGPoint(x: origin.x + cos(radians) * (12 + spread * 26), y: origin.y + 30 + sin(radians) * (5 + spread * 9))
                let radius = 3 * (1 - spread)
                context.fill(Circle().path(in: CGRect(x: center.x - radius, y: center.y - radius, width: radius * 2, height: radius * 2)), with: .color(.white.opacity(0.65 * (1 - Double(spread)))))
            }
        }
    }

    private func drawContact(at point: CGPoint, won: Bool, context: GraphicsContext) {
        // Static outcome marks also work with Reduce Motion. A miss never gets reward rays.
        let radius: CGFloat = won ? 22 : 16
        context.stroke(Circle().path(in: CGRect(x: point.x - radius, y: point.y - radius, width: radius * 2, height: radius * 2)), with: .color(won ? successGreen : coral.opacity(0.80)), style: StrokeStyle(lineWidth: 2, dash: won ? [] : [3, 4]))
        if won {
            for index in 0..<8 {
                let radians = Double(index) * .pi / 4
                drawPath([CGPoint(x: point.x + cos(radians) * 26, y: point.y + sin(radians) * 26), CGPoint(x: point.x + cos(radians) * 33, y: point.y + sin(radians) * 33)], context: context, color: moonSky ? .yellow : successGreen, width: 3)
            }
        }
    }

    private func drawRotation(context: GraphicsContext, size: CGSize) {
        // Exact shared-scene hinge and square size; both square arms rotate together.
        let center = CGPoint(x: size.width * 0.46, y: size.height * 0.62)
        let radius = min(size.width * 0.23, size.height * 0.31)
        let targetAngle = engine.level.rotationTarget ?? 90
        let currentColor = engine.phase == .result && engine.success ? successGreen : coral
        if engine.level.id == "builder-quarter-turn" {
            drawWedge(center: center, radius: radius, angle: targetAngle, context: context, color: blue.opacity(0.12))
            drawRay(center: center, radius: radius, angle: targetAngle, context: context, color: blue, width: 7, dashed: true)
            drawWedge(center: center, radius: radius * 0.72, angle: engine.angle, context: context, color: coral.opacity(0.32))
            drawRay(center: center, radius: radius, angle: 0, context: context, color: ink.opacity(0.55), width: 4)
            drawRay(center: center, radius: radius, angle: engine.angle, context: context, color: currentColor, width: 14)
            for fraction in [0.25, 0.50, 0.75] {
                let radians = engine.angle * .pi / 180
                let bolt = CGPoint(x: center.x + radius * fraction * cos(radians), y: center.y - radius * fraction * sin(radians))
                context.fill(Circle().path(in: CGRect(x: bolt.x - 3, y: bolt.y - 3, width: 6, height: 6)), with: .color(.white.opacity(0.90)))
            }
        } else {
            drawSquareCorner(center: center, radius: radius, orientation: targetAngle, context: context, color: blue, dashed: true)
            drawSquareCorner(center: center, radius: radius, orientation: engine.angle, context: context, color: currentColor, dashed: false)
        }
        context.fill(Circle().path(in: CGRect(x: center.x - 22, y: center.y - 22, width: 44, height: 44)), with: .color(blue))
        context.fill(Circle().path(in: CGRect(x: center.x - 10, y: center.y - 10, width: 20, height: 20)), with: .color(.white))
        if engine.phase != .result || !engine.success {
            drawLabel("Match the dotted shape", at: CGPoint(x: center.x, y: max(34, center.y - radius * 1.50 - 30)), size: 26, context: context, color: blue)
        }
        if engine.level.id == "builder-quarter-turn" {
            let targetTip = CGPoint(x: center.x + radius * cos(targetAngle * .pi / 180), y: center.y - radius * sin(targetAngle * .pi / 180))
            drawSymbol("door.left.hand.open", at: targetTip, size: 36, context: context, color: blue)
        } else {
            drawLabel(engine.phase == .result && engine.success ? "Square corner: 90°. New direction." : "Same square corner. New direction.", at: CGPoint(x: size.width * 0.50, y: size.height * 0.92), size: 22, context: context, color: ink.opacity(0.80))
        }
    }

    private func drawSquareCorner(center: CGPoint, radius: CGFloat, orientation: Double, context: GraphicsContext, color: Color, dashed: Bool) {
        let radians = orientation * .pi / 180
        let u = CGPoint(x: cos(radians), y: -sin(radians))
        let v = CGPoint(x: cos(radians + .pi / 2), y: -sin(radians + .pi / 2))
        func corner(_ a: CGFloat, _ b: CGFloat) -> CGPoint {
            CGPoint(x: center.x + u.x * a + v.x * b, y: center.y + u.y * a + v.y * b)
        }
        let first = corner(radius, 0), second = corner(0, radius), opposite = corner(radius, radius)
        var square = Path(); square.move(to: center)
        square.addLines([first, opposite, second]); square.closeSubpath()
        if !dashed { context.fill(square, with: .color(color.opacity(0.18))) }
        context.stroke(square, with: .color(color.opacity(dashed ? 0.90 : 0.55)), style: StrokeStyle(lineWidth: 3, dash: dashed ? [9, 8] : []))
        drawPath([first, center, second], context: context, color: color, width: dashed ? 7 : 12, dashed: dashed)
        if !dashed {
            let mark = radius * 0.19
            drawPath([corner(mark, 0), corner(mark, mark), corner(0, mark)], context: context, color: ink.opacity(0.85), width: 3)
            for point in [first, second, opposite] {
                context.fill(Circle().path(in: CGRect(x: point.x - 4, y: point.y - 4, width: 8, height: 8)), with: .color(.white.opacity(0.90)))
            }
        }
    }

    private func drawWedge(center: CGPoint, radius: CGFloat, angle: Double, context: GraphicsContext, color: Color) {
        var wedge = Path(); wedge.move(to: center)
        wedge.addArc(center: center, radius: radius, startAngle: .degrees(0), endAngle: .degrees(-angle), clockwise: true)
        wedge.closeSubpath()
        context.fill(wedge, with: .color(color))
        context.stroke(wedge, with: .color(ink.opacity(0.38)), lineWidth: 1.5)
    }

    private func drawRay(center: CGPoint, radius: CGFloat, angle: Double, context: GraphicsContext, color: Color, width: CGFloat, dashed: Bool = false) {
        let tip = CGPoint(x: center.x + radius * cos(angle * .pi / 180), y: center.y - radius * sin(angle * .pi / 180))
        drawPath([center, tip], context: context, color: color, width: width, dashed: dashed)
    }

    private func drawPath(_ points: [CGPoint], context: GraphicsContext, color: Color, width: CGFloat, dashed: Bool = false) {
        guard let first = points.first, points.count > 1 else { return }
        var path = Path(); path.move(to: first)
        for point in points.dropFirst() { path.addLine(to: point) }
        context.stroke(path, with: .color(color), style: StrokeStyle(lineWidth: width, lineCap: .round, lineJoin: .round, dash: dashed ? [9, 8] : []))
    }

    private func drawSymbol(_ symbol: String, at point: CGPoint, size: CGFloat, context: GraphicsContext, color: Color) {
        let image = context.resolve(Text(Image(systemName: symbol)).font(.system(size: size, weight: .bold)).foregroundStyle(color))
        context.draw(image, at: point)
    }

    private func drawLabel(_ text: String, at point: CGPoint, size: CGFloat, context: GraphicsContext, color: Color) {
        let label = context.resolve(Text(text).font(.system(size: size, weight: .bold, design: .rounded)).foregroundStyle(color))
        context.draw(label, at: point)
    }
}
