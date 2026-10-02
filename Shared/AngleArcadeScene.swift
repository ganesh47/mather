import SwiftUI

/// The same geometric picture on iPad and TV; only the platform controls differ.
@MainActor
struct AngleArcadeScene: View {
    let engine: AngleArcadeEngine
    let flightProgress: Double

    private let ink = Color(red: 0.12, green: 0.25, blue: 0.29)
    private let coral = Color(red: 0.93, green: 0.30, blue: 0.20)
    private let blue = Color(red: 0.15, green: 0.49, blue: 0.75)

    var body: some View {
        Canvas { context, size in
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
                    .foregroundStyle(ink.opacity(0.68))
                    .padding(18)
            }
        }
        .overlay(alignment: .topTrailing) {
            if engine.phase == .result && engine.success {
                Text(degreeDiscovery)
                    .font(.system(size: 40, weight: .heavy, design: .rounded))
                    .foregroundStyle(ink)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(.white.opacity(0.93), in: Capsule())
                    .padding(18)
                    .accessibilityLabel(degreeDiscovery.replacingOccurrences(of: "°", with: " degrees"))
                    .accessibilityIdentifier("angle-arcade-degree-reveal")
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

    private var background: some View {
        LinearGradient(colors: engine.level.gravity < 98
            ? [Color(red: 0.80, green: 0.85, blue: 0.98), Color(red: 0.94, green: 0.93, blue: 1)]
            : [Color(red: 0.78, green: 0.94, blue: 0.97), Color(red: 0.97, green: 0.98, blue: 0.88)], startPoint: .top, endPoint: .bottom)
    }

    private var sceneDescription: String {
        if engine.phase == .flying { return "Watch the delivery fly." }
        if engine.phase == .result { return engine.feedback }
        if engine.level.kind == .rotation {
            return engine.level.id == "builder-quarter-turn" ? "Turn the gate around its hinge to match the dotted gate. \(engine.hint)" : "The whole square turns. Its corner stays the same. Match the dotted square. \(engine.hint)"
        }
        return "The shaded wedge shows the launch angle. \(engine.hint)"
    }

    private func drawLaunch(context: GraphicsContext, size: CGSize) {
        let bounds = engine.level.bounds
        // Authored bounds stay fixed throughout an attempt: the target never moves when aiming.
        let scale = min((size.width * 0.84) / bounds.width, (size.height * 0.70) / bounds.height)
        let origin = CGPoint(x: (size.width - bounds.width * scale) / 2 - bounds.minX * scale, y: size.height * 0.85 + bounds.minY * scale)
        func point(_ value: CGPoint) -> CGPoint {
            CGPoint(x: origin.x + value.x * scale, y: origin.y - value.y * scale)
        }
        let ground = CGRect(x: 0, y: origin.y, width: size.width, height: size.height - origin.y)
        context.fill(Path(ground), with: .color(engine.level.gravity < 98 ? Color(red: 0.65, green: 0.68, blue: 0.81) : Color(red: 0.43, green: 0.70, blue: 0.40)))

        for obstacle in engine.level.obstacles {
            let top = point(CGPoint(x: obstacle.rect.minX, y: obstacle.rect.maxY))
            let rect = CGRect(x: top.x, y: top.y, width: obstacle.rect.width * scale, height: obstacle.rect.height * scale)
            // The outer silhouette matches the model's rectangle exactly. Surface
            // details stay inside it so a blocked shot visibly contacts the obstacle.
            context.fill(Path(rect), with: .color(engine.currentWorld == .moon
                ? Color(red: 0.45, green: 0.47, blue: 0.60)
                : Color(red: 0.68, green: 0.42, blue: 0.23)))
            context.stroke(Path(rect.insetBy(dx: 1, dy: 1)), with: .color(ink.opacity(0.35)), lineWidth: 2)
            if engine.currentWorld == .moon {
                var facet = Path()
                facet.move(to: CGPoint(x: rect.minX + rect.width * 0.20, y: rect.minY + rect.height * 0.12))
                facet.addLine(to: CGPoint(x: rect.minX + rect.width * 0.80, y: rect.minY + rect.height * 0.36))
                facet.addLine(to: CGPoint(x: rect.minX + rect.width * 0.30, y: rect.minY + rect.height * 0.62))
                facet.addLine(to: CGPoint(x: rect.minX + rect.width * 0.70, y: rect.minY + rect.height * 0.88))
                context.stroke(facet, with: .color(.white.opacity(0.30)), lineWidth: 1)
            } else {
                var grain = Path()
                grain.move(to: CGPoint(x: rect.midX, y: rect.minY + 3))
                grain.addLine(to: CGPoint(x: rect.midX, y: rect.maxY - 3))
                context.stroke(grain, with: .color(.white.opacity(0.26)), lineWidth: 1)
            }
        }

        if let previous = engine.previousShot {
            drawPath(previous.path.map(point), context: context, color: blue.opacity(0.35), dashed: true, width: 3)
        }
        if let preview = engine.preview, engine.phase == .aiming {
            let count = engine.showsFullPreview ? preview.path.count : max(2, preview.path.count / 4)
            drawPath(Array(preview.path.prefix(count)).map(point), context: context, color: coral.opacity(0.70), dashed: true, width: 4)
        }
        if let shot = engine.shot {
            let count = max(1, Int(Double(shot.path.count - 1) * flightProgress) + 1)
            let points = Array(shot.path.prefix(count)).map(point)
            let finished = engine.phase == .result
            drawPath(points, context: context, color: finished && engine.success ? Color(red: 0.12, green: 0.58, blue: 0.35) : coral, dashed: false, width: 5)
            if let ball = points.last {
                let radius = engine.level.projectileRadius * scale
                let ballRect = CGRect(x: ball.x - radius, y: ball.y - radius, width: radius * 2, height: radius * 2)
                context.fill(Circle().path(in: ballRect), with: .color(coral))
                drawSymbol(engine.level.projectileSymbol, at: ball, size: radius * 1.6, context: context, color: .white)
            }
        }

        if let target = engine.level.target {
            let center = point(CGPoint(x: target.distance, y: target.height))
            let radius = target.radius * scale
            let rect = CGRect(x: center.x - radius, y: center.y - radius, width: radius * 2, height: radius * 2)
            context.fill(Circle().path(in: rect), with: .color(.white.opacity(0.60)))
            context.stroke(Circle().path(in: rect), with: .color(engine.success && engine.phase == .result ? .green : blue), lineWidth: 3)
            drawSymbol(engine.currentWorld == .garden ? "basket.fill" : "flag.fill", at: CGPoint(x: center.x, y: center.y - radius - 30), size: 28, context: context, color: blue)
            let label = context.resolve(Text("Deliver here").font(.system(size: max(16, min(23, size.height * 0.05)), weight: .bold, design: .rounded)).foregroundStyle(ink))
            context.draw(label, at: CGPoint(x: center.x, y: center.y - radius - 60))
        }

        let wedgeRadius = min(82, size.height * 0.18)
        drawWedge(center: origin, radius: wedgeRadius, angle: engine.angle, context: context, color: coral.opacity(0.22))
        drawRay(center: origin, radius: wedgeRadius + 12, angle: 0, context: context, color: ink.opacity(0.40), width: 3)
        drawRay(center: origin, radius: wedgeRadius, angle: engine.angle, context: context, color: coral, width: 8)
        let base = CGRect(x: origin.x - 30, y: origin.y - 11, width: 60, height: 28)
        context.fill(RoundedRectangle(cornerRadius: 10).path(in: base), with: .color(ink))
        for offset in [-18.0, 18.0] {
            context.fill(Circle().path(in: CGRect(x: origin.x + offset - 9, y: origin.y + 6, width: 18, height: 18)), with: .color(ink))
        }
    }

    private func drawRotation(context: GraphicsContext, size: CGSize) {
        let center = CGPoint(x: size.width * 0.46, y: size.height * 0.62)
        let radius = min(size.width * 0.23, size.height * 0.31)
        let targetAngle = engine.level.rotationTarget ?? 90
        if engine.level.id == "builder-quarter-turn" {
            // The gate turns around its hinge. Its turn is measured from the fixed ground ray.
            drawWedge(center: center, radius: radius, angle: targetAngle, context: context, color: blue.opacity(0.12))
            drawRay(center: center, radius: radius, angle: targetAngle, context: context, color: blue.opacity(0.75), width: 6, dashed: true)
            drawWedge(center: center, radius: radius * 0.72, angle: engine.angle, context: context, color: coral.opacity(0.30))
            drawRay(center: center, radius: radius, angle: 0, context: context, color: ink.opacity(0.45), width: 4)
            drawRay(center: center, radius: radius, angle: engine.angle, context: context, color: coral, width: 14)
        } else {
            // Rotate BOTH arms together: the square's internal corner always stays 90 degrees.
            drawSquareCorner(center: center, radius: radius, orientation: targetAngle, context: context, color: blue.opacity(0.75), dashed: true)
            drawSquareCorner(center: center, radius: radius, orientation: engine.angle, context: context, color: coral, dashed: false)
        }
        context.fill(Circle().path(in: CGRect(x: center.x - 11, y: center.y - 11, width: 22, height: 22)), with: .color(ink))
        let targetTip = CGPoint(x: center.x + radius * cos(targetAngle * .pi / 180), y: center.y - radius * sin(targetAngle * .pi / 180))
        let label = context.resolve(Text("Match the dotted shape").font(.system(size: max(18, min(26, size.height * 0.06)), weight: .bold, design: .rounded)).foregroundStyle(blue))
        context.draw(label, at: CGPoint(x: center.x, y: max(34, center.y - radius * 1.50 - 30)))
        if engine.level.id == "builder-quarter-turn" {
            drawSymbol("door.left.hand.open", at: targetTip, size: 36, context: context, color: blue)
        } else {
            let reference = context.resolve(Text(engine.phase == .result && engine.success ? "Square corner: 90°. New direction." : "Same square corner. New direction.").font(.system(size: max(16, min(22, size.height * 0.05)), weight: .semibold, design: .rounded)).foregroundStyle(ink.opacity(0.70)))
            context.draw(reference, at: CGPoint(x: size.width * 0.50, y: size.height * 0.92))
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
        square.addLine(to: first); square.addLine(to: opposite); square.addLine(to: second); square.closeSubpath()
        if !dashed { context.fill(square, with: .color(color.opacity(0.12))) }
        context.stroke(square, with: .color(color.opacity(dashed ? 0.8 : 0.5)), style: StrokeStyle(lineWidth: 3, dash: dashed ? [9, 8] : []))
        drawPath([first, center, second], context: context, color: color, dashed: dashed, width: dashed ? 6 : 10)
        if !dashed {
            let mark = radius * 0.19
            drawPath([corner(mark, 0), corner(mark, mark), corner(0, mark)], context: context, color: ink.opacity(0.7), dashed: false, width: 3)
        }
    }

    private func drawWedge(center: CGPoint, radius: CGFloat, angle: Double, context: GraphicsContext, color: Color) {
        var wedge = Path()
        wedge.move(to: center)
        wedge.addArc(center: center, radius: radius, startAngle: .degrees(0), endAngle: .degrees(-angle), clockwise: true)
        wedge.closeSubpath()
        context.fill(wedge, with: .color(color))
    }

    private func drawRay(center: CGPoint, radius: CGFloat, angle: Double, context: GraphicsContext, color: Color, width: CGFloat, dashed: Bool = false) {
        let tip = CGPoint(x: center.x + radius * cos(angle * .pi / 180), y: center.y - radius * sin(angle * .pi / 180))
        drawPath([center, tip], context: context, color: color, dashed: dashed, width: width)
    }

    private func drawPath(_ points: [CGPoint], context: GraphicsContext, color: Color, dashed: Bool, width: CGFloat) {
        guard let first = points.first, points.count > 1 else { return }
        var path = Path(); path.move(to: first)
        for point in points.dropFirst() { path.addLine(to: point) }
        context.stroke(path, with: .color(color), style: StrokeStyle(lineWidth: width, lineCap: .round, lineJoin: .round, dash: dashed ? [9, 8] : []))
    }

    private func drawSymbol(_ symbol: String, at point: CGPoint, size: CGFloat, context: GraphicsContext, color: Color) {
        let image = context.resolve(Text(Image(systemName: symbol)).font(.system(size: size, weight: .bold)).foregroundStyle(color))
        context.draw(image, at: point)
    }
}

/// Every completed mission adds a visible part to a creation; shared by world cards and the finale.
struct AngleArcadeWorldArtwork: View {
    let world: AngleArcadeWorld
    var completedCount: Int = 3

    var body: some View {
        GeometryReader { geometry in
            let side = min(geometry.size.width, geometry.size.height)
            ZStack {
                RoundedRectangle(cornerRadius: side * 0.12)
                    .fill(Color.white.opacity(0.16))
                switch world {
                case .garden:
                    HStack(alignment: .bottom, spacing: side * 0.03) {
                        ForEach(0..<3) { index in
                            VStack(spacing: 0) {
                                Image(systemName: index < completedCount ? "camera.macro" : "leaf")
                                    .font(.system(size: side * 0.22, weight: .bold))
                                    .foregroundStyle(index == 1 ? Color.orange : Color(red: 0.96, green: 0.38, blue: 0.48))
                                Capsule().fill(Color.green).frame(width: side * 0.025, height: side * (index == 1 ? 0.24 : 0.17))
                            }
                            .opacity(index < completedCount ? 1 : 0.38)
                        }
                    }
                    .offset(y: side * 0.06)
                case .builder:
                    VStack(spacing: 0) {
                        TriangleRoof().fill(.orange).frame(width: side * 0.64, height: side * 0.27).opacity(completedCount >= 2 ? 1 : 0.28)
                        ZStack {
                            RoundedRectangle(cornerRadius: 5).fill(Color(red: 0.31, green: 0.65, blue: 0.78)).opacity(completedCount >= 1 ? 1 : 0.28)
                            Image(systemName: "door.left.hand.open").font(.system(size: side * 0.25)).foregroundStyle(.white).opacity(completedCount >= 3 ? 1 : 0.28)
                        }.frame(width: side * 0.48, height: side * 0.35)
                    }
                case .moon:
                    ZStack {
                        Capsule().fill(Color(red: 0.65, green: 0.83, blue: 0.96)).overlay(Capsule().stroke(Color(red: 0.16, green: 0.39, blue: 0.58), lineWidth: side * 0.012)).frame(width: side * 0.27, height: side * 0.48).opacity(completedCount >= 1 ? 1 : 0.28)
                        Image(systemName: "triangle.fill").font(.system(size: side * 0.20)).foregroundStyle(.orange).offset(y: -side * 0.28).opacity(completedCount >= 2 ? 1 : 0.28)
                        HStack(spacing: side * 0.04) {
                            Image(systemName: "triangle.fill").rotationEffect(.degrees(-90))
                            Image(systemName: "circle.fill").foregroundStyle(.blue)
                            Image(systemName: "triangle.fill").rotationEffect(.degrees(90))
                        }.font(.system(size: side * 0.15)).foregroundStyle(.orange).opacity(completedCount >= 3 ? 1 : 0.28)
                    }
                }
            }
        }
        .accessibilityHidden(true)
    }
}

private struct TriangleRoof: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path(); path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY)); path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY)); path.closeSubpath()
        return path
    }
}
