import SwiftUI

struct AngleArcadeTVView: View {
    @FocusState private var focusedAction: AngleArcadeAction?
    @State private var angle: Double = AngleArcadeTarget.defaultTargets[0].recommendedAngle
    @State private var power: Double = AngleArcadeTarget.defaultTargets[0].recommendedPower
    @State private var targetIndex = 0
    @State private var firedShot: AngleArcadeShot?
    @State private var hitCount = 0

    private let targets = AngleArcadeTarget.defaultTargets

    private var target: AngleArcadeTarget {
        targets[targetIndex]
    }

    private var prediction: AngleArcadeShot {
        AngleArcadeModel.shot(angle: angle, power: power, target: target)
    }

    var body: some View {
        ZStack {
            MatherTVBackdrop()

            VStack(alignment: .leading, spacing: 28) {
                header

                AngleArcadeFieldView(
                    target: target,
                    prediction: prediction,
                    firedShot: firedShot
                )
                .frame(maxWidth: .infinity)
                .frame(height: 520)
                .background(Color.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 30, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 30, style: .continuous)
                        .stroke(Color.white.opacity(0.14), lineWidth: 2)
                )

                controls
            }
            .frame(maxWidth: 1680, maxHeight: .infinity, alignment: .topLeading)
            .padding(.horizontal, 90)
            .padding(.vertical, 66)
        }
        .onAppear {
            focusedAction = .fire
        }
        .onMoveCommand(perform: handleMoveCommand)
        .onPlayPauseCommand(perform: primaryAction)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Angle Arcade")
        .accessibilityHint("Use left and right for angle, up and down for power, then press select to fire or replay.")
    }

    private var header: some View {
        HStack(alignment: .top, spacing: 24) {
            VStack(alignment: .leading, spacing: 10) {
                Text("Angle Arcade")
                    .font(.system(size: 70, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)

                Text(target.title)
                    .font(.system(size: 30, weight: .semibold, design: .rounded))
                    .foregroundStyle(Color(red: 0.55, green: 0.88, blue: 1.0))
            }

            Spacer(minLength: 0)

            HStack(spacing: 10) {
                ForEach(targets.indices, id: \.self) { index in
                    Circle()
                        .fill(index == targetIndex ? Color(red: 1.0, green: 0.76, blue: 0.30) : Color.white.opacity(0.28))
                        .frame(width: 20, height: 20)
                        .accessibilityHidden(true)
                }
            }
            .padding(.top, 20)
        }
    }

    private var controls: some View {
        HStack(alignment: .center, spacing: 20) {
            metricTile(title: "Angle", value: "\(Int(angle))°", symbolName: "arrow.left.and.right")
            metricTile(title: "Power", value: "\(Int(power))", symbolName: "arrow.up.and.down")
            resultTile

            Spacer(minLength: 0)

            Button {
                primaryAction()
            } label: {
                Label(firedShot == nil ? "Fire" : "Replay", systemImage: firedShot == nil ? "paperplane.fill" : "arrow.clockwise")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .frame(width: 220, height: 92)
            }
            .buttonStyle(.borderedProminent)
            .focused($focusedAction, equals: .fire)
            .accessibilityIdentifier("angle-arcade-fire-replay-button")
        }
    }

    private var resultTile: some View {
        let shot = firedShot
        return VStack(alignment: .leading, spacing: 8) {
            Text("Round")
                .font(.system(size: 17, weight: .semibold, design: .rounded))
                .foregroundStyle(.white.opacity(0.62))

            Text(shot == nil ? "\(hitCount) hits" : (shot?.hit == true ? "Hit" : "Miss"))
                .font(.system(size: 30, weight: .bold, design: .rounded))
                .foregroundStyle(shot?.hit == false ? Color(red: 1.0, green: 0.58, blue: 0.38) : .white)

            Text(shot == nil ? "Target \(targetIndex + 1) of \(targets.count)" : "\(Int(abs(shot?.verticalDelta ?? 0))) off")
                .font(.system(size: 17, weight: .semibold, design: .rounded))
                .foregroundStyle(.white.opacity(0.62))
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 14)
        .frame(width: 132, height: 104, alignment: .leading)
        .background(Color.white.opacity(0.09), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private func metricTile(title: String, value: String, symbolName: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(title, systemImage: symbolName)
                .font(.system(size: 17, weight: .semibold, design: .rounded))
                .foregroundStyle(.white.opacity(0.62))

            Text(value)
                .font(.system(size: 31, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 14)
        .frame(width: 132, height: 104, alignment: .leading)
        .background(Color.white.opacity(0.09), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private func primaryAction() {
        if let shot = firedShot {
            if shot.hit {
                targetIndex = AngleArcadeModel.nextTargetIndex(after: targetIndex, targetCount: targets.count)
                let nextTarget = targets[targetIndex]
                angle = nextTarget.recommendedAngle
                power = nextTarget.recommendedPower
            }
            firedShot = nil
            return
        }

        let shot = prediction
        firedShot = shot
        if shot.hit {
            hitCount += 1
        }
    }

    private func handleMoveCommand(_ direction: MoveCommandDirection) {
        guard firedShot == nil else { return }
        switch direction {
        case .left:
            angle = AngleArcadeModel.adjustedAngle(angle, direction: -1)
        case .right:
            angle = AngleArcadeModel.adjustedAngle(angle, direction: 1)
        case .up:
            power = AngleArcadeModel.adjustedPower(power, direction: 1)
        case .down:
            power = AngleArcadeModel.adjustedPower(power, direction: -1)
        @unknown default:
            break
        }
    }
}

private enum AngleArcadeAction: Hashable {
    case fire
}

private struct AngleArcadeFieldView: View {
    let target: AngleArcadeTarget
    let prediction: AngleArcadeShot
    let firedShot: AngleArcadeShot?

    var body: some View {
        Canvas { context, size in
            let origin = CGPoint(x: size.width * 0.11, y: size.height * 0.83)
            let scale = fieldScale(for: size)

            drawGround(context: context, size: size)
            drawArc(prediction.path, origin: origin, scale: scale, size: size, context: context, color: Color(red: 1.0, green: 0.53, blue: 0.42), dashed: true)

            if let firedShot {
                drawArc(firedShot.path, origin: origin, scale: scale, size: size, context: context, color: firedShot.hit ? Color(red: 0.30, green: 0.92, blue: 0.70) : Color(red: 1.0, green: 0.76, blue: 0.30), dashed: false)
            }

            drawTarget(context: context, origin: origin, scale: scale, target: target)
            drawCannon(context: context, origin: origin, angle: firedShot?.angle ?? prediction.angle)
            drawProjectile(context: context, origin: origin, scale: scale, shot: firedShot)
        }
    }

    private func fieldScale(for size: CGSize) -> CGFloat {
        min((size.width * 0.76) / 680, (size.height * 0.58) / 230)
    }

    private func screenPoint(_ point: CGPoint, origin: CGPoint, scale: CGFloat) -> CGPoint {
        CGPoint(x: origin.x + point.x * scale, y: origin.y - point.y * scale)
    }

    private func drawGround(context: GraphicsContext, size: CGSize) {
        var ground = Path()
        ground.move(to: CGPoint(x: 0, y: size.height * 0.83))
        ground.addLine(to: CGPoint(x: size.width, y: size.height * 0.83))
        context.stroke(ground, with: .color(.white.opacity(0.18)), lineWidth: 2)

        let hill = CGRect(x: size.width * 0.58, y: size.height * 0.67, width: size.width * 0.34, height: size.height * 0.22)
        context.fill(Ellipse().path(in: hill), with: .color(Color(red: 0.22, green: 0.56, blue: 0.50).opacity(0.18)))
    }

    private func drawArc(
        _ points: [CGPoint],
        origin: CGPoint,
        scale: CGFloat,
        size: CGSize,
        context: GraphicsContext,
        color: Color,
        dashed: Bool
    ) {
        let mapped = points.map { screenPoint($0, origin: origin, scale: scale) }
            .filter { $0.x <= size.width + 20 && $0.y >= -20 && $0.y <= size.height + 20 }
        guard mapped.count > 1 else { return }

        var path = Path()
        path.move(to: mapped[0])
        for point in mapped.dropFirst() {
            path.addLine(to: point)
        }
        context.stroke(
            path,
            with: .color(color.opacity(dashed ? 0.74 : 0.95)),
            style: StrokeStyle(lineWidth: dashed ? 4 : 6, lineCap: .round, lineJoin: .round, dash: dashed ? [12, 10] : [])
        )
    }

    private func drawTarget(context: GraphicsContext, origin: CGPoint, scale: CGFloat, target: AngleArcadeTarget) {
        let center = screenPoint(CGPoint(x: target.distance, y: target.height), origin: origin, scale: scale)
        let radius = max(24, CGFloat(target.radius) * scale)
        let outer = CGRect(x: center.x - radius, y: center.y - radius, width: radius * 2, height: radius * 2)
        context.fill(Circle().path(in: outer.insetBy(dx: -10, dy: -10)), with: .color(Color(red: 1.0, green: 0.76, blue: 0.30).opacity(0.16)))
        context.stroke(Circle().path(in: outer), with: .color(Color(red: 1.0, green: 0.76, blue: 0.30)), lineWidth: 5)
        context.stroke(Circle().path(in: outer.insetBy(dx: radius * 0.38, dy: radius * 0.38)), with: .color(.white.opacity(0.74)), lineWidth: 3)

        let label = context.resolve(Text(target.title).font(.system(size: 19, weight: .bold, design: .rounded)).foregroundStyle(.white.opacity(0.86)))
        context.draw(label, at: CGPoint(x: center.x, y: center.y - radius - 20), anchor: .center)
    }

    private func drawCannon(context: GraphicsContext, origin: CGPoint, angle: Double) {
        let radians = angle * .pi / 180
        let barrelLength: CGFloat = 58
        let tip = CGPoint(
            x: origin.x + barrelLength * CGFloat(cos(radians)),
            y: origin.y - barrelLength * CGFloat(sin(radians))
        )

        var barrel = Path()
        barrel.move(to: origin)
        barrel.addLine(to: tip)
        context.stroke(barrel, with: .color(.white.opacity(0.96)), style: StrokeStyle(lineWidth: 16, lineCap: .round))
        context.stroke(barrel, with: .color(Color(red: 1.0, green: 0.53, blue: 0.42)), style: StrokeStyle(lineWidth: 8, lineCap: .round))

        let body = CGRect(x: origin.x - 44, y: origin.y - 18, width: 82, height: 34)
        context.fill(RoundedRectangle(cornerRadius: 15).path(in: body), with: .color(Color(red: 1.0, green: 0.76, blue: 0.30)))
        context.fill(Circle().path(in: CGRect(x: origin.x - 36, y: origin.y + 4, width: 28, height: 28)), with: .color(Color(red: 0.05, green: 0.08, blue: 0.13)))
        context.fill(Circle().path(in: CGRect(x: origin.x + 10, y: origin.y + 4, width: 28, height: 28)), with: .color(Color(red: 0.05, green: 0.08, blue: 0.13)))
    }

    private func drawProjectile(context: GraphicsContext, origin: CGPoint, scale: CGFloat, shot: AngleArcadeShot?) {
        guard let shot, let last = shot.path.last else { return }
        let point = screenPoint(last, origin: origin, scale: scale)
        let rect = CGRect(x: point.x - 11, y: point.y - 11, width: 22, height: 22)
        context.fill(Circle().path(in: rect), with: .color(shot.hit ? Color(red: 0.30, green: 0.92, blue: 0.70) : Color(red: 1.0, green: 0.76, blue: 0.30)))
        context.stroke(Circle().path(in: rect.insetBy(dx: -5, dy: -5)), with: .color(.white.opacity(0.54)), lineWidth: 2)
    }
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        AngleArcadeTVView()
    }
}
