import SwiftUI
import UIKit

// Two-Finger Protractor — ages 7–9
// Place two fingers anywhere on the canvas. The angle between the two arms
// from the canvas centre (fixed pivot) to each finger is computed and displayed.
// When the measured angle is within ±5° of the target the snap zone turns green.
// Ghost wedge drawn at targetAngle; filled amber wedge at measuredAngle.

// MARK: - Angle math helpers (pure — testable)

enum ProtractorMath {
    /// Angle in degrees (0–180) between the two arms from a FIXED pivot to t1 and t2.
    /// Uses the atan2-subtraction formula: the angular sweep from pivot→t1 to pivot→t2.
    /// Returns a value in [0, 180].
    static func angleDegrees(t1: CGPoint, t2: CGPoint, pivot: CGPoint) -> Double {
        let a1 = atan2(t1.y - pivot.y, t1.x - pivot.x)
        let a2 = atan2(t2.y - pivot.y, t2.x - pivot.x)
        var diff = abs(a2 - a1) * 180 / .pi
        if diff > 180 { diff = 360 - diff }
        return diff
    }

    static func isInSnapZone(measured: Double, target: Double, tolerance: Double = 5) -> Bool {
        abs(measured - target) <= tolerance
    }

    static func matchTransition(previouslyMatched: Bool,
                                measured: Double,
                                target: Double,
                                tolerance: Double = 5) -> (matched: Bool, newlyMatched: Bool) {
        let matched = isInSnapZone(measured: measured, target: target, tolerance: tolerance)
        return (matched, matched && !previouslyMatched)
    }
}

// MARK: - UIKit multi-touch view

/// Exposes simultaneous two-touch positions via a callback.
final class MultiTouchView: UIView {
    var onTouchesChanged: ((_ t1: CGPoint?, _ t2: CGPoint?) -> Void)?

    private var activeTouches: [UITouch: CGPoint] = [:]

    override init(frame: CGRect) {
        super.init(frame: frame)
        isMultipleTouchEnabled = true
        backgroundColor = .clear
    }

    required init?(coder: NSCoder) { fatalError() }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        for t in touches { activeTouches[t] = t.location(in: self) }
        emit()
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        for t in touches { activeTouches[t] = t.location(in: self) }
        emit()
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        for t in touches { activeTouches.removeValue(forKey: t) }
        emit()
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        for t in touches { activeTouches.removeValue(forKey: t) }
        emit()
    }

    private func emit() {
        let pts = Array(activeTouches.values)
        onTouchesChanged?(pts.count > 0 ? pts[0] : nil,
                          pts.count > 1 ? pts[1] : nil)
    }
}

// MARK: - SwiftUI wrapper

struct MultiTouchCanvas: UIViewRepresentable {
    var onTouchesChanged: (_ t1: CGPoint?, _ t2: CGPoint?) -> Void

    func makeUIView(context: Context) -> MultiTouchView {
        let v = MultiTouchView()
        v.onTouchesChanged = onTouchesChanged
        return v
    }

    func updateUIView(_ uiView: MultiTouchView, context: Context) {
        uiView.onTouchesChanged = onTouchesChanged
    }
}

// MARK: - Level config

enum ProtractorSceneKind: String, CaseIterable {
    case doorGate
    case clockRamp
    case triangleRoof
    case roadBend
    case trailSwitchback
}

struct ProtractorLevel {
    let targetAngle: Double       // degrees
    let sceneName: String         // spoken description
    let mission: String           // visible real-world reason
    let sceneKind: ProtractorSceneKind
    let snapTolerance: Double     // degrees
}

let levels: [ProtractorLevel] = [
    ProtractorLevel(targetAngle: 90,  sceneName: "a right angle — like opening a gate", mission: "Open the garden gate to a square corner.", sceneKind: .doorGate, snapTolerance: 5),
    ProtractorLevel(targetAngle: 45,  sceneName: "a half-right angle — like a ramp", mission: "Set the ramp so the marble can roll.", sceneKind: .clockRamp, snapTolerance: 5),
    ProtractorLevel(targetAngle: 60,  sceneName: "a triangle corner — like a tent roof", mission: "Raise the tent roof to a strong triangle.", sceneKind: .triangleRoof, snapTolerance: 5),
    ProtractorLevel(targetAngle: 120, sceneName: "a wide turn — like a bridge road", mission: "Bend the bridge road into a gentle turn.", sceneKind: .roadBend, snapTolerance: 5),
    ProtractorLevel(targetAngle: 30,  sceneName: "a sharp turn — like a hill trail", mission: "Trace the switchback trail on the hill map.", sceneKind: .trailSwitchback, snapTolerance: 4),
]

// MARK: - Main view

struct TwoFingerProtractorView: View {
    @Bindable var appModel: AppModel

    @State private var touch1: CGPoint? = nil
    @State private var touch2: CGPoint? = nil
    @State private var measuredAngle: Double = 0
    @State private var matched: Bool = false
    @State private var levelIndex: Int = 0
    @State private var wonCount: Int = 0
    @State private var sessionStart: Date = .now
    @State private var showDegreeLabel: Bool = false
    @State private var canvasSize: CGSize = .zero

    private var level: ProtractorLevel { levels[levelIndex % levels.count] }

    var body: some View {
        ZStack {
            MatherTheme.background.ignoresSafeArea()
            VStack(spacing: 0) {
                headerBar
                GeometryReader { geo in
                    ZStack {
                        // Multi-touch capture layer (full area)
                        MultiTouchCanvas { t1, t2 in
                            touch1 = t1
                            touch2 = t2
                            canvasSize = geo.size
                            updateAngle(canvasSize: geo.size)
                        }

                        // Wedge drawing canvas
                        Canvas { ctx, size in
                            drawScene(ctx: ctx, size: size)
                        }
                        .allowsHitTesting(false)

                        // Degree reveal label — shown only on snap
                        if showDegreeLabel {
                            degreeLabel
                                .transition(.scale.combined(with: .opacity))
                        }

                        // Hint when no fingers
                        if touch1 == nil {
                            hintOverlay
                        }
                    }
                }
                bottomBar
            }
        }
        .animation(.easeInOut(duration: 0.2), value: showDegreeLabel)
        .animation(.easeInOut(duration: 0.15), value: matched)
        .onAppear { sessionStart = .now }
        .onDisappear {
            guard wonCount > 0 else { return }
            appModel.gameSessionStore.save(
                gameName: "Protractor",
                startedAt: sessionStart,
                scoreValue: wonCount,
                scoreLabel: "angles matched"
            )
        }
    }

    // MARK: - Header

    private var headerBar: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Two-Finger Protractor")
                    .font(.title2.weight(.black))
                    .foregroundStyle(MatherTheme.ink)
                Text(level.mission)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
            Spacer()
            Button {
                appModel.engine.showHome()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 30))
                    .foregroundStyle(.secondary)
            }
            .accessibilityLabel("Done")
        }
        .padding(.horizontal, 24)
        .padding(.top, 20)
        .padding(.bottom, 8)
    }

    // MARK: - Bottom bar

    private var bottomBar: some View {
        VStack(spacing: 8) {
            if matched {
                Button(action: advanceLevel) {
                    Text(wonCount >= levels.count ? "All done!" : "Next angle →")
                        .font(.headline.weight(.bold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(MatherTheme.accent)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
                .padding(.horizontal, 24)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
            Text("Place two fingers to measure an angle")
                .font(.caption)
                .foregroundStyle(.tertiary)
                .padding(.bottom, 16)
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: matched)
    }

    // MARK: - Degree label

    private var degreeLabel: some View {
        VStack(spacing: 4) {
            Text("\(Int(measuredAngle.rounded()))°")
                .font(.system(size: 64, weight: .black, design: .rounded))
                .foregroundStyle(matched ? MatherTheme.accent : MatherTheme.ink)
            if matched {
                Text("That's \(Int(level.targetAngle))°!")
                    .font(.headline.weight(.bold))
                    .foregroundStyle(MatherTheme.accent)
            }
        }
        .padding(20)
        .background(MatherTheme.card.opacity(0.92))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: .black.opacity(0.08), radius: 12, y: 4)
    }

    private var hintOverlay: some View {
        VStack(spacing: 12) {
            Image(systemName: "hand.draw.fill")
                .font(.system(size: 44))
                .foregroundStyle(MatherTheme.softBlue)
            Text(level.mission)
                .font(.headline.weight(.black))
                .foregroundStyle(MatherTheme.ink)
                .multilineTextAlignment(.center)
            Text("Use two fingers to make \(Int(level.targetAngle))°")
                .font(.title3.weight(.black))
                .foregroundStyle(MatherTheme.accent)
        }
        .padding(24)
        .background(MatherTheme.card.opacity(0.9))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    // MARK: - Canvas drawing

    private func drawScene(ctx: GraphicsContext, size: CGSize) {
        drawRealWorldScene(ctx: ctx, size: size)
        let pivot = CGPoint(x: size.width / 2, y: size.height / 2)
        guard let p1 = touch1, let p2 = touch2 else {
            // Draw ghost wedge centred in canvas showing target angle
            drawGhostWedge(ctx: ctx, size: size)
            return
        }
        let armLen: CGFloat = min(size.width, size.height) * 0.4

        // Ghost wedge at target angle (always visible)
        drawTargetWedge(ctx: ctx, pivot: pivot, targetDeg: level.targetAngle, armLen: armLen, t1: p1, t2: p2)

        // Live filled wedge at measured angle — use atan2 angles from fixed pivot
        let fillColor: Color = matched ? MatherTheme.accent : MatherTheme.warm
        let a1 = atan2(p1.y - pivot.y, p1.x - pivot.x)
        let a2 = atan2(p2.y - pivot.y, p2.x - pivot.x)
        drawWedgeFromAngles(ctx: ctx, pivot: pivot, a1: a1, a2: a2, armLen: armLen,
                            color: fillColor, alpha: 0.35)

        // Arms from pivot toward each finger
        let ep1 = extendPoint(from: pivot, toward: p1, length: armLen)
        let ep2 = extendPoint(from: pivot, toward: p2, length: armLen)
        var arm1 = Path()
        arm1.move(to: pivot)
        arm1.addLine(to: ep1)
        ctx.stroke(arm1, with: .color(fillColor), lineWidth: 3)

        var arm2 = Path()
        arm2.move(to: pivot)
        arm2.addLine(to: ep2)
        ctx.stroke(arm2, with: .color(fillColor), lineWidth: 3)

        // Pivot dot
        let pivotR: CGFloat = 10
        ctx.fill(Circle().path(in: CGRect(x: pivot.x - pivotR, y: pivot.y - pivotR,
                                          width: pivotR*2, height: pivotR*2)),
                 with: .color(fillColor))

        // Finger dots
        let dotR: CGFloat = 16
        ctx.fill(Circle().path(in: CGRect(x: p1.x - dotR, y: p1.y - dotR, width: dotR*2, height: dotR*2)),
                 with: .color(fillColor.opacity(0.7)))
        ctx.fill(Circle().path(in: CGRect(x: p2.x - dotR, y: p2.y - dotR, width: dotR*2, height: dotR*2)),
                 with: .color(fillColor.opacity(0.7)))
    }


    private func drawRealWorldScene(ctx: GraphicsContext, size: CGSize) {
        let center = CGPoint(x: size.width / 2, y: size.height / 2)
        let accent = matched ? MatherTheme.accent : MatherTheme.softBlue
        switch level.sceneKind {
        case .doorGate:
            let wall = CGRect(x: center.x - 120, y: center.y - 90, width: 240, height: 180)
            ctx.stroke(RoundedRectangle(cornerRadius: 18).path(in: wall), with: .color(MatherTheme.ink.opacity(0.14)), lineWidth: 5)
            var gate = Path(); gate.move(to: center); gate.addLine(to: CGPoint(x: center.x + 120, y: center.y))
            gate.move(to: center); gate.addLine(to: CGPoint(x: center.x, y: center.y - 120))
            ctx.stroke(gate, with: .color(accent.opacity(0.45)), style: StrokeStyle(lineWidth: 10, lineCap: .round))
        case .clockRamp:
            ctx.stroke(Circle().path(in: CGRect(x: center.x - 110, y: center.y - 110, width: 220, height: 220)), with: .color(MatherTheme.ink.opacity(0.10)), lineWidth: 6)
            var ramp = Path(); ramp.move(to: CGPoint(x: center.x - 115, y: center.y + 70)); ramp.addLine(to: CGPoint(x: center.x + 115, y: center.y - 40))
            ctx.stroke(ramp, with: .color(accent.opacity(0.45)), style: StrokeStyle(lineWidth: 12, lineCap: .round))
        case .triangleRoof:
            var roof = Path(); roof.move(to: CGPoint(x: center.x - 130, y: center.y + 80)); roof.addLine(to: CGPoint(x: center.x, y: center.y - 115)); roof.addLine(to: CGPoint(x: center.x + 130, y: center.y + 80))
            ctx.stroke(roof, with: .color(accent.opacity(0.45)), style: StrokeStyle(lineWidth: 10, lineCap: .round, lineJoin: .round))
        case .roadBend:
            var road = Path(); road.move(to: CGPoint(x: center.x - 150, y: center.y + 80)); road.addQuadCurve(to: CGPoint(x: center.x + 150, y: center.y - 70), control: CGPoint(x: center.x - 10, y: center.y + 130))
            ctx.stroke(road, with: .color(accent.opacity(0.40)), style: StrokeStyle(lineWidth: 34, lineCap: .round))
            ctx.stroke(road, with: .color(.white.opacity(0.7)), style: StrokeStyle(lineWidth: 3, dash: [12, 10]))
        case .trailSwitchback:
            for i in 0..<5 {
                let inset = CGFloat(i) * 24
                ctx.stroke(Ellipse().path(in: CGRect(x: center.x - 160 + inset, y: center.y - 115 + inset * 0.45, width: 320 - inset * 2, height: 210 - inset)), with: .color(MatherTheme.ink.opacity(0.07)), lineWidth: 2)
            }
            var trail = Path(); trail.move(to: CGPoint(x: center.x - 130, y: center.y + 80)); trail.addLine(to: CGPoint(x: center.x - 10, y: center.y - 10)); trail.addLine(to: CGPoint(x: center.x + 115, y: center.y - 55))
            ctx.stroke(trail, with: .color(accent.opacity(0.48)), style: StrokeStyle(lineWidth: 10, lineCap: .round, lineJoin: .round))
        }
    }

    private func drawGhostWedge(ctx: GraphicsContext, size: CGSize) {        let pivot = CGPoint(x: size.width / 2, y: size.height * 0.55)
        let armLen: CGFloat = 100
        let targetRad = level.targetAngle * .pi / 180
        let baseAngle: Double = -.pi / 2   // arms open upward
        let a1 = baseAngle - targetRad / 2
        let a2 = baseAngle + targetRad / 2

        var wedge = Path()
        wedge.move(to: pivot)
        wedge.addArc(center: pivot, radius: armLen,
                     startAngle: .radians(a1), endAngle: .radians(a2), clockwise: false)
        wedge.closeSubpath()
        ctx.fill(wedge, with: .color(Color.gray.opacity(0.15)))
        ctx.stroke(wedge, with: .color(Color.gray.opacity(0.4)), lineWidth: 2)

        // Target angle label inside ghost
        var label = ctx.resolve(Text("\(Int(level.targetAngle))°").font(.system(size: 20, weight: .bold)).foregroundStyle(Color.gray.opacity(0.5)))
        let midAngle = (a1 + a2) / 2
        let labelPos = CGPoint(x: pivot.x + cos(midAngle) * armLen * 0.55,
                               y: pivot.y + sin(midAngle) * armLen * 0.55)
        ctx.draw(label, at: labelPos)
    }

    private func drawTargetWedge(ctx: GraphicsContext, pivot: CGPoint, targetDeg: Double,
                                 armLen: CGFloat, t1: CGPoint, t2: CGPoint) {
        // Orient the ghost wedge bisecting the current live angle direction
        let bisector: Double
        let a1 = atan2(t1.y - pivot.y, t1.x - pivot.x)
        let a2 = atan2(t2.y - pivot.y, t2.x - pivot.x)
        bisector = (a1 + a2) / 2   // rough bisector; good enough for visual hint

        let targetRad = targetDeg * .pi / 180
        let ga1 = bisector - targetRad / 2
        let ga2 = bisector + targetRad / 2

        var wedge = Path()
        wedge.move(to: pivot)
        wedge.addArc(center: pivot, radius: armLen * 0.85,
                     startAngle: .radians(ga1), endAngle: .radians(ga2), clockwise: false)
        wedge.closeSubpath()
        ctx.fill(wedge, with: .color(Color.gray.opacity(0.12)))
        ctx.stroke(wedge, with: .color(Color.gray.opacity(0.35)),
                   style: StrokeStyle(lineWidth: 2, dash: [6, 4]))
    }

    private func drawWedgeFromAngles(ctx: GraphicsContext, pivot: CGPoint,
                                     a1: Double, a2: Double,
                                     armLen: CGFloat, color: Color, alpha: Double) {
        var wedge = Path()
        wedge.move(to: pivot)
        wedge.addArc(center: pivot, radius: armLen,
                     startAngle: .radians(a1), endAngle: .radians(a2),
                     clockwise: a2 < a1)
        wedge.closeSubpath()
        ctx.fill(wedge, with: .color(color.opacity(alpha)))
    }

    private func extendPoint(from origin: CGPoint, toward target: CGPoint, length: CGFloat) -> CGPoint {
        let dx = target.x - origin.x
        let dy = target.y - origin.y
        let dist = sqrt(dx * dx + dy * dy)
        guard dist > 0 else { return target }
        return CGPoint(x: origin.x + dx / dist * length,
                       y: origin.y + dy / dist * length)
    }

    // MARK: - Logic

    private func updateAngle(canvasSize: CGSize) {
        guard let p1 = touch1, let p2 = touch2 else {
            measuredAngle = 0
            showDegreeLabel = false
            return
        }
        let pivot = CGPoint(x: canvasSize.width / 2, y: canvasSize.height / 2)
        let angle = ProtractorMath.angleDegrees(t1: p1, t2: p2, pivot: pivot)
        measuredAngle = angle
        showDegreeLabel = true

        let transition = ProtractorMath.matchTransition(previouslyMatched: matched,
                                                        measured: angle,
                                                        target: level.targetAngle,
                                                        tolerance: level.snapTolerance)
        matched = transition.matched

        if transition.newlyMatched {
            wonCount += 1
            appModel.hapticsService.success(enabled: appModel.featureFlags.hapticsEnabled)
            appModel.speechService.speak(
                "That's \(Int(level.targetAngle)) degrees! \(level.sceneName).",
                enabled: appModel.featureFlags.audioEnabled
            )
        }
    }

    private func advanceLevel() {
        if wonCount >= levels.count {
            appModel.engine.showHome()
            return
        }
        levelIndex += 1
        matched = false
        showDegreeLabel = false
        touch1 = nil
        touch2 = nil
        measuredAngle = 0
        appModel.speechService.speak(
            "Now make \(Int(level.targetAngle)) degrees.",
            enabled: appModel.featureFlags.audioEnabled
        )
    }
}
