import SwiftUI
import UIKit

@MainActor
struct AngleArcadeTVView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.resetFocus) private var resetFocus
    @Namespace private var primaryFocusScope
    @State private var flightTask: Task<Void, Never>?
    @State private var flightProgress = 0.0
    @State private var isFlying = false
    @State private var narration = TVNarrationController()
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
                    firedShot: firedShot,
                    flightProgress: flightProgress,
                    isFlying: isFlying
                )
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("Target: \(target.title)")
                .accessibilityValue(isFlying ? "Shot in flight" : firedShot.map(resultDescription) ?? "Aim preview: \(resultDescription(prediction))")
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
            narration.presentPrompt(targetPrompt)
        }
        .onMoveCommand(perform: handleMoveCommand)
        .onChange(of: focusedAction) { _, action in
            narration.focus(action == nil ? nil : actionGuidance)
        }
        .onPlayPauseCommand {
            narration.presentPrompt(isFlying ? actionGuidance : firedShot.map(feedbackMessage) ?? targetPrompt)
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active {
                focusedAction = .fire
                resetFocus(in: primaryFocusScope)
            } else {
                // tvOS can discard actual focus while the binding still says Fire.
                focusedAction = nil
                cancelFlight()
                narration.stop()
            }
        }
        .onDisappear { cancelFlight(); narration.stop() }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Angle Arcade")
        .accessibilityHint("Use left and right for angle, up and down for power, then press select to fire. Press Play Pause to repeat the instructions.")
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
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .center, spacing: 20) {
                metricTile(title: "Angle", value: "\(Int(angle))°", symbolName: "arrow.left.and.right", identifier: "angle-arcade-angle") { direction in
                    adjustAngle(direction == .increment ? 1 : -1)
                }
                metricTile(title: "Power", value: "\(Int(power))", symbolName: "arrow.up.and.down", identifier: "angle-arcade-power") { direction in
                    adjustPower(direction == .increment ? 1 : -1)
                }
                resultTile
                Spacer(minLength: 0)
                Button(action: primaryAction) {
                    Label(primaryLabel, systemImage: primarySymbol)
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .frame(width: 240, height: 92)
                }
                .buttonStyle(.borderedProminent)
                .focused($focusedAction, equals: .fire)
                .prefersDefaultFocus(true, in: primaryFocusScope)
                .accessibilityIdentifier("angle-arcade-fire-replay-button")
                .accessibilityLabel(primaryLabel)
                .accessibilityHint(actionGuidance)
            }
            Text(visibleGuidance)
                .font(.system(size: 23, weight: .semibold, design: .rounded))
                .foregroundStyle(.white.opacity(0.82))
        }
        .focusScope(primaryFocusScope)
    }

    private var primaryLabel: String {
        if isFlying { return "Flying…" }
        guard let shot = firedShot else { return "Fire" }
        return shot.hit ? "Next target" : "Try again"
    }

    private var primarySymbol: String {
        if isFlying { return "paperplane.fill" }
        guard let shot = firedShot else { return "paperplane.fill" }
        return shot.hit ? "arrow.right" : "arrow.clockwise"
    }

    private var visibleGuidance: String {
        if isFlying { return "Watch your shot!" }
        if let shot = firedShot {
            return shot.hit ? "Great aim! Select → next target" : "\(correction(for: shot))  •  Arrows → adjust  •  Select → try again"
        }
        return "← → Angle   •   ↑ ↓ Power   •   Select → fire   •   Play/Pause → hear help"
    }

    private var resultTile: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("\(hitCount) \(hitCount == 1 ? "hit" : "hits")")
                .accessibilityIdentifier("angle-arcade-hit-count")
                .font(.system(size: 21, weight: .semibold, design: .rounded))
                .foregroundStyle(.white.opacity(0.72))
            Text(isFlying ? "Flying…" : firedShot.map(resultDescription) ?? "Ready")
                .font(.system(size: 30, weight: .bold, design: .rounded))
                .foregroundStyle(firedShot?.hit == false && !isFlying ? Color(red: 1.0, green: 0.68, blue: 0.44) : .white)
                .accessibilityIdentifier("angle-arcade-result")
            Text("Target \(targetIndex + 1) of \(targets.count)")
                .font(.system(size: 21, weight: .semibold, design: .rounded))
                .foregroundStyle(.white.opacity(0.72))
                .accessibilityIdentifier("angle-arcade-target-progress")
        }
        .padding(.horizontal, 22)
        .padding(.vertical, 14)
        .frame(width: 240, height: 122, alignment: .leading)
        .background(Color.white.opacity(0.09), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private func metricTile(title: String, value: String, symbolName: String, identifier: String, adjustment: @escaping (AccessibilityAdjustmentDirection) -> Void) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Label(title, systemImage: symbolName)
                .font(.system(size: 22, weight: .semibold, design: .rounded))
                .foregroundStyle(.white.opacity(0.72))
            Text(value)
                .font(.system(size: 34, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
        }
        .padding(.horizontal, 22)
        .padding(.vertical, 14)
        .frame(width: 180, height: 122, alignment: .leading)
        .background(Color.white.opacity(0.09), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier(identifier)
        .accessibilityLabel(title)
        .accessibilityValue(value)
        .accessibilityAdjustableAction(adjustment)
    }

    private var aimDescription: String {
        "Angle \(Int(angle)) degrees. Power \(Int(power))."
    }

    private var targetPrompt: String {
        "Aim for the \(target.title). Left and right change angle. Up and down change power. \(aimDescription) Select fires. Play Pause repeats help."
    }

    private var actionGuidance: String {
        if isFlying { return "Watch your shot. Wait for it to land." }
        guard let shot = firedShot else { return "Press select to launch. \(aimDescription)" }
        return shot.hit ? "Press select for the next target." : "Use the arrows to adjust, or press select to aim again."
    }

    private func resultDescription(_ shot: AngleArcadeShot) -> String {
        switch shot.outcome {
        case .hit: "Great aim!"
        case .short: "Too short"
        case .above: "Too high"
        case .below: "Too low"
        }
    }

    private func correction(for shot: AngleArcadeShot) -> String {
        if shot.hit { return "Great aim!" }
        let lowerPower = shot.outcome == .above
        if lowerPower && shot.power > AngleArcadeModel.powerRange.lowerBound {
            return "Try less power ↓"
        }
        if !lowerPower && shot.power < AngleArcadeModel.powerRange.upperBound {
            return "Try more power ↑"
        }
        // At a power limit, offer an angle change that reduces the miss instead.
        let candidates = [-1, 1].filter {
            AngleArcadeModel.adjustedAngle(shot.angle, direction: $0) != shot.angle
        }
        let direction = candidates.min { first, second in
            missScore(AngleArcadeModel.shot(angle: AngleArcadeModel.adjustedAngle(shot.angle, direction: first), power: shot.power, target: shot.target))
                < missScore(AngleArcadeModel.shot(angle: AngleArcadeModel.adjustedAngle(shot.angle, direction: second), power: shot.power, target: shot.target))
        } ?? 1
        return direction < 0 ? "Try a lower angle ←" : "Try a higher angle →"
    }

    private func missScore(_ shot: AngleArcadeShot) -> Double {
        if shot.hit { return 0 }
        return shot.outcome == .short ? hypot(shot.target.distance - shot.landingX, shot.target.height) : abs(shot.verticalDelta)
    }

    private func feedbackMessage(_ shot: AngleArcadeShot) -> String {
        if shot.hit { return "You hit the \(target.title)! Press select for the next target." }
        let hint = correction(for: shot)
            .replacingOccurrences(of: " ↑", with: ". Press up.")
            .replacingOccurrences(of: " ↓", with: ". Press down.")
            .replacingOccurrences(of: " ←", with: ". Press left.")
            .replacingOccurrences(of: " →", with: ". Press right.")
        return "\(resultDescription(shot)). \(hint) Then select to fire."
    }

    private func primaryAction() {
        guard !isFlying else { return }
        if let shot = firedShot {
            if shot.hit {
                targetIndex = AngleArcadeModel.nextTargetIndex(after: targetIndex, targetCount: targets.count)
                angle = target.recommendedAngle
                power = target.startingPower
            }
            firedShot = nil
            flightProgress = 0
            narration.presentPrompt(targetPrompt)
            return
        }

        let shot = prediction
        firedShot = shot
        flightProgress = 0
        isFlying = true
        narration.stop()
        flightTask = Task { @MainActor in
            // Reduce Motion presents a still trajectory before announcing the result.
            let steps = reduceMotion ? 1 : 40
            if reduceMotion { flightProgress = 1 }
            for step in 1...steps {
                do { try await Task.sleep(for: .milliseconds(reduceMotion ? 300 : 30)) }
                catch { return }
                guard !Task.isCancelled else { return }
                flightProgress = Double(step) / Double(steps)
            }
            isFlying = false
            flightTask = nil
            if shot.hit { hitCount += 1 }
            let message = feedbackMessage(shot)
            narration.announce(message)
            if UIAccessibility.isVoiceOverRunning {
                UIAccessibility.post(notification: .announcement, argument: message)
            }
        }
    }

    private func cancelFlight() {
        flightTask?.cancel()
        flightTask = nil
        if isFlying { firedShot = nil; flightProgress = 0 }
        isFlying = false
    }

    private func prepareAdjustment() -> Bool {
        guard !isFlying, firedShot?.hit != true else { return false }
        firedShot = nil
        flightProgress = 0
        return true
    }

    private func adjustAngle(_ direction: Int) {
        guard prepareAdjustment() else { return }
        angle = AngleArcadeModel.adjustedAngle(angle, direction: direction)
        narration.focus(aimDescription)
    }

    private func adjustPower(_ direction: Int) {
        guard prepareAdjustment() else { return }
        power = AngleArcadeModel.adjustedPower(power, direction: direction)
        narration.focus(aimDescription)
    }

    private func handleMoveCommand(_ direction: MoveCommandDirection) {
        switch direction {
        case .left: adjustAngle(-1)
        case .right: adjustAngle(1)
        case .up: adjustPower(1)
        case .down: adjustPower(-1)
        @unknown default: return
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
    let flightProgress: Double
    let isFlying: Bool

    var body: some View {
        Canvas { context, size in
            let origin = CGPoint(x: size.width * 0.11, y: size.height * 0.83)
            let scale = fieldScale(for: size)

            drawGround(context: context, size: size)
            drawArc(prediction.path, origin: origin, scale: scale, size: size, context: context, color: Color(red: 1.0, green: 0.53, blue: 0.42), dashed: true)

            if let firedShot {
                drawArc(visiblePath(for: firedShot), origin: origin, scale: scale, size: size, context: context, color: !isFlying && firedShot.hit ? Color(red: 0.30, green: 0.92, blue: 0.70) : Color(red: 1.0, green: 0.76, blue: 0.30), dashed: false)
            }

            drawTarget(context: context, origin: origin, scale: scale, target: target)
            drawCannon(context: context, origin: origin, angle: firedShot?.angle ?? prediction.angle)
            drawProjectile(context: context, origin: origin, scale: scale, shot: firedShot)
        }
    }

    private func fieldScale(for size: CGSize) -> CGFloat {
        let points = (firedShot ?? prediction).path
        let width = max(680, points.map(\.x).max() ?? 680)
        let height = max(230, points.map(\.y).max() ?? 230, target.height + target.radius)
        return min((size.width * 0.76) / width, (size.height * 0.64) / height)
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
        let hit = firedShot?.hit == true && !isFlying
        let outer = CGRect(x: center.x - radius, y: center.y - radius, width: radius * 2, height: radius * 2)
        context.fill(Circle().path(in: outer.insetBy(dx: -10, dy: -10)), with: .color(Color(red: 1.0, green: 0.76, blue: 0.30).opacity(0.16)))
        context.stroke(Circle().path(in: outer), with: .color(hit ? Color(red: 0.30, green: 0.92, blue: 0.70) : Color(red: 1.0, green: 0.76, blue: 0.30)), lineWidth: hit ? 8 : 5)
        context.stroke(Circle().path(in: outer.insetBy(dx: radius * 0.38, dy: radius * 0.38)), with: .color(.white.opacity(0.74)), lineWidth: 3)

        let label = context.resolve(Text(target.title).font(.system(size: 24, weight: .bold, design: .rounded)).foregroundStyle(.white.opacity(0.86)))
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

    private func visiblePath(for shot: AngleArcadeShot) -> [CGPoint] {
        let count = max(1, Int(Double(shot.path.count - 1) * flightProgress) + 1)
        return Array(shot.path.prefix(count))
    }

    private func drawProjectile(context: GraphicsContext, origin: CGPoint, scale: CGFloat, shot: AngleArcadeShot?) {
        guard let shot, let last = visiblePath(for: shot).last else { return }
        let point = screenPoint(last, origin: origin, scale: scale)
        let rect = CGRect(x: point.x - 11, y: point.y - 11, width: 22, height: 22)
        context.fill(Circle().path(in: rect), with: .color(!isFlying && shot.hit ? Color(red: 0.30, green: 0.92, blue: 0.70) : Color(red: 1.0, green: 0.76, blue: 0.30)))
        context.stroke(Circle().path(in: rect.insetBy(dx: -5, dy: -5)), with: .color(.white.opacity(0.54)), lineWidth: 2)
    }
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        AngleArcadeTVView()
    }
}
