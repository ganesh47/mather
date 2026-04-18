import SwiftUI

// Gravity Artist — ages 8–10
// Two-phase activity: first PREDICT the arc (tap PREDICT to freeze your guess),
// then FIRE and compare where the ball actually lands.
// Tilt controls the launch angle; a power selector (1/2/3) changes initial velocity.
// Landing the ball within the hit radius of a target earns a star and reveals
// the angle label — the abstract CPA step.

// MARK: - Physics helpers (pure — testable)

enum GravityArtistPhysics {
    static let gravity: Double = 900   // pt/s²

    static let velocityForPower: [Int: Double] = [1: 200, 2: 350, 3: 500]

    /// Parabolic arc points from cannon origin.
    /// `angleDeg` is the launch angle above horizontal (0–80°).
    /// `velocity` is initial speed (pt/s).
    /// `canvasHeight` terminates the arc when the ball hits the ground.
    nonisolated static func arcPoints(
        angleDeg: Double,
        velocity: Double,
        cannonOrigin: CGPoint,
        canvasHeight: Double,
        dt: Double = 0.02
    ) -> [CGPoint] {
        let rad = angleDeg * .pi / 180
        let vx = velocity * cos(rad)
        let vy = velocity * sin(rad)   // positive = upward in math coords
        var pts: [CGPoint] = []
        var t = 0.0
        while t < 10 {
            let x = cannonOrigin.x + vx * t
            // screen y increases downward: y_screen = cannon.y - vy*t + 0.5*g*t²
            let y = cannonOrigin.y - vy * t + 0.5 * gravity * t * t
            if y > canvasHeight { break }
            pts.append(CGPoint(x: x, y: y))
            t += dt
        }
        return pts
    }

    /// Landing x-coordinate (last point's x before the arc hits the ground).
    nonisolated static func landingX(
        angleDeg: Double,
        velocity: Double,
        cannonOrigin: CGPoint,
        canvasHeight: Double
    ) -> Double {
        let pts = arcPoints(angleDeg: angleDeg, velocity: velocity,
                            cannonOrigin: cannonOrigin, canvasHeight: canvasHeight)
        return pts.last?.x ?? cannonOrigin.x
    }

    /// True when the fired arc's landing x is within `hitRadius` of the target x.
    nonisolated static func isHit(
        firedLandingX: Double,
        targetX: Double,
        hitRadius: Double
    ) -> Bool {
        abs(firedLandingX - targetX) <= hitRadius
    }

    /// Target x on the ground for a given angle and power at a given canvas size.
    /// Places the target realistically within the right half of the canvas.
    nonisolated static func targetX(
        angleDeg: Double,
        velocity: Double,
        cannonOrigin: CGPoint,
        canvasWidth: Double,
        canvasHeight: Double
    ) -> Double {
        let x = landingX(angleDeg: angleDeg, velocity: velocity,
                         cannonOrigin: cannonOrigin, canvasHeight: canvasHeight)
        // Clamp to drawable area with 40pt margin
        return max(cannonOrigin.x + 40, min(x, canvasWidth - 40))
    }
}

// MARK: - View

struct GravityArtistView: View {
    @Bindable var appModel: AppModel

    // Tilt
    @State private var neutralRoll: Double? = nil
    @State private var currentAngle: Double = 45       // degrees, 5–80

    // Power
    @State private var selectedPower: Int = 2           // 1/2/3

    // Game state
    @State private var predictedArcPoints: [CGPoint]? = nil
    @State private var firedArcPoints: [CGPoint]? = nil
    @State private var targetX: Double = 0
    @State private var hitTarget: Bool = false
    @State private var roundsPlayed: Int = 0
    @State private var phase: GamePhase = .aim

    // Canvas geometry captured from GeometryReader
    @State private var canvasSize: CGSize = .zero

    private enum GamePhase { case aim, predicted, fired }

    private let hitRadius: Double = 50   // pt — generous for ages 8–10

    var body: some View {
        ZStack {
            MatherTheme.background.ignoresSafeArea()
            VStack(spacing: 0) {
                headerBar
                GeometryReader { geo in
                    ZStack(alignment: .topLeading) {
                        arcCanvas(size: geo.size)
                        powerSelector
                            .padding(16)
                        if hitTarget {
                            angleLabelOverlay
                        }
                    }
                    .onAppear {
                        canvasSize = geo.size
                        setupNewRound(size: geo.size)
                    }
                }
                bottomBar
            }
        }
        .onChange(of: appModel.motionService.tiltRoll) { _, roll in
            guard phase == .aim else { return }
            if neutralRoll == nil { neutralRoll = roll }
            let delta = roll - neutralRoll!
            let raw = 45 + delta / (.pi / 4) * 35
            currentAngle = max(5, min(raw, 80))
        }
        .onAppear { appModel.motionService.startUpdates() }
        .onDisappear { appModel.motionService.stopUpdates() }
    }

    // MARK: - Header

    private var headerBar: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Gravity Artist")
                    .font(.title2.weight(.black))
                    .foregroundStyle(MatherTheme.ink)
                Text(phaseHint)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
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

    private var phaseHint: String {
        switch phase {
        case .aim:       return "Tilt to aim, then PREDICT"
        case .predicted: return "Prediction locked — now FIRE!"
        case .fired:     return hitTarget ? "You hit it! \(Int(currentAngle.rounded()))°" : "Close! Try again."
        }
    }

    // MARK: - Arc canvas

    private func arcCanvas(size: CGSize) -> some View {
        Canvas { ctx, canvasSize in
            let cannon = cannonOrigin(in: canvasSize)
            let groundY = canvasSize.height * 0.88

            // Ground line
            var ground = Path()
            ground.move(to: CGPoint(x: 0, y: groundY))
            ground.addLine(to: CGPoint(x: canvasSize.width, y: groundY))
            ctx.stroke(ground, with: .color(MatherTheme.ink.opacity(0.15)), lineWidth: 2)

            // Target marker
            let ty = groundY
            let tx = targetX
            drawTarget(ctx: ctx, x: tx, y: ty)

            // Predicted arc (dotted amber) — drawn behind fired arc
            if let predicted = predictedArcPoints, predicted.count >= 2 {
                var path = Path()
                path.move(to: predicted[0])
                for pt in predicted.dropFirst() { path.addLine(to: pt) }
                ctx.stroke(path, with: .color(MatherTheme.warm.opacity(0.6)),
                           style: StrokeStyle(lineWidth: 3, lineCap: .round, dash: [8, 6]))
            }

            // Fired arc (solid accent/red)
            if let fired = firedArcPoints, fired.count >= 2 {
                var path = Path()
                path.move(to: fired[0])
                for pt in fired.dropFirst() { path.addLine(to: pt) }
                ctx.stroke(path, with: .color(hitTarget ? MatherTheme.accent : MatherTheme.coral),
                           style: StrokeStyle(lineWidth: 3, lineCap: .round))
            }

            // Live preview arc when aiming (faint, solid)
            if phase == .aim {
                let liveVelocity = GravityArtistPhysics.velocityForPower[selectedPower] ?? 350
                let livePts = GravityArtistPhysics.arcPoints(
                    angleDeg: currentAngle, velocity: liveVelocity,
                    cannonOrigin: cannon, canvasHeight: groundY)
                if livePts.count >= 2 {
                    var lp = Path()
                    lp.move(to: livePts[0])
                    for pt in livePts.dropFirst() { lp.addLine(to: pt) }
                    ctx.stroke(lp, with: .color(MatherTheme.ink.opacity(0.2)),
                               style: StrokeStyle(lineWidth: 2, lineCap: .round, dash: [4, 4]))
                }
            }

            // Cannon
            drawCannon(ctx: ctx, origin: cannon, angleDeg: currentAngle)
        }
    }

    private func drawTarget(ctx: GraphicsContext, x: Double, y: Double) {
        let r: CGFloat = 20
        // Outer ring
        ctx.fill(Circle().path(in: CGRect(x: x - r, y: y - r, width: r*2, height: r*2)),
                 with: .color(MatherTheme.coral.opacity(0.3)))
        ctx.stroke(Circle().path(in: CGRect(x: x - r, y: y - r, width: r*2, height: r*2)),
                   with: .color(MatherTheme.coral), lineWidth: 2)
        // Inner dot
        let ri: CGFloat = 6
        ctx.fill(Circle().path(in: CGRect(x: x - ri, y: y - ri, width: ri*2, height: ri*2)),
                 with: .color(MatherTheme.coral))
    }

    private func drawCannon(ctx: GraphicsContext, origin: CGPoint, angleDeg: Double) {
        let barrelLen: CGFloat = 40
        let rad = angleDeg * .pi / 180
        let tip = CGPoint(x: origin.x + barrelLen * cos(rad),
                          y: origin.y - barrelLen * sin(rad))   // screen y down

        // Barrel
        var barrel = Path()
        barrel.move(to: origin)
        barrel.addLine(to: tip)
        ctx.stroke(barrel, with: .color(MatherTheme.ink), lineWidth: 8)

        // Wheel
        let wr: CGFloat = 14
        ctx.fill(Circle().path(in: CGRect(x: origin.x - wr, y: origin.y - wr,
                                          width: wr*2, height: wr*2)),
                 with: .color(MatherTheme.ink.opacity(0.8)))
    }

    // MARK: - Power selector

    private var powerSelector: some View {
        VStack(spacing: 6) {
            ForEach([3, 2, 1], id: \.self) { p in
                Button {
                    selectedPower = p
                } label: {
                    let size: CGFloat = p == 1 ? 18 : p == 2 ? 26 : 34
                    Image(systemName: "circle.fill")
                        .font(.system(size: size))
                        .foregroundStyle(selectedPower == p ? MatherTheme.accent : MatherTheme.ink.opacity(0.3))
                }
                .frame(width: 44, height: 44)
            }
        }
        .padding(10)
        .background(MatherTheme.card.opacity(0.85))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    // MARK: - Angle label overlay (shown on hit)

    private var angleLabelOverlay: some View {
        VStack(spacing: 4) {
            Text("\(Int(currentAngle.rounded()))°")
                .font(.system(size: 64, weight: .black, design: .rounded))
                .foregroundStyle(MatherTheme.accent)
            Text("Launch angle")
                .font(.headline.weight(.semibold))
                .foregroundStyle(.secondary)
        }
        .padding(20)
        .background(MatherTheme.card.opacity(0.92))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: .black.opacity(0.08), radius: 12, y: 4)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        .transition(.scale.combined(with: .opacity))
        .animation(.spring(response: 0.3), value: hitTarget)
    }

    // MARK: - Bottom bar

    private var bottomBar: some View {
        VStack(spacing: 10) {
            HStack(spacing: 16) {
                switch phase {
                case .aim:
                    Button("PREDICT") {
                        handlePredict()
                    }
                    .font(.headline.weight(.bold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(MatherTheme.warm)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

                case .predicted:
                    Button("FIRE!") {
                        handleFire()
                    }
                    .font(.headline.weight(.bold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(MatherTheme.coral)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

                case .fired:
                    Button("Try Again") {
                        handleNextRound()
                    }
                    .font(.headline.weight(.bold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(MatherTheme.softBlue)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
            }
            .padding(.horizontal, 24)

            Text("Tilt to change angle • Tap dot to change power")
                .font(.caption)
                .foregroundStyle(.tertiary)
                .padding(.bottom, 16)
        }
    }

    // MARK: - Actions

    private func handlePredict() {
        guard canvasSize != .zero else { return }
        let cannon = cannonOrigin(in: canvasSize)
        let groundY = canvasSize.height * 0.88
        let v = GravityArtistPhysics.velocityForPower[selectedPower] ?? 350
        predictedArcPoints = GravityArtistPhysics.arcPoints(
            angleDeg: currentAngle, velocity: v,
            cannonOrigin: cannon, canvasHeight: groundY)
        phase = .predicted
        appModel.speechService.speak(
            "Prediction locked. Now fire!",
            enabled: appModel.featureFlags.audioEnabled
        )
    }

    private func handleFire() {
        guard canvasSize != .zero else { return }
        let cannon = cannonOrigin(in: canvasSize)
        let groundY = canvasSize.height * 0.88
        let v = GravityArtistPhysics.velocityForPower[selectedPower] ?? 350
        let fired = GravityArtistPhysics.arcPoints(
            angleDeg: currentAngle, velocity: v,
            cannonOrigin: cannon, canvasHeight: groundY)
        firedArcPoints = fired
        let landX = fired.last?.x ?? cannon.x
        hitTarget = GravityArtistPhysics.isHit(firedLandingX: landX, targetX: targetX, hitRadius: hitRadius)
        phase = .fired
        roundsPlayed += 1

        if hitTarget {
            appModel.hapticsService.success(enabled: appModel.featureFlags.hapticsEnabled)
            appModel.speechService.speak(
                "Bull's eye! The launch angle was \(Int(currentAngle.rounded())) degrees.",
                enabled: appModel.featureFlags.audioEnabled
            )
        } else {
            appModel.hapticsService.failure(enabled: appModel.featureFlags.hapticsEnabled)
            appModel.speechService.speak(
                "So close! Try again.",
                enabled: appModel.featureFlags.audioEnabled
            )
        }
    }

    private func handleNextRound() {
        guard canvasSize != .zero else { return }
        setupNewRound(size: canvasSize)
    }

    private func setupNewRound(size: CGSize) {
        let cannon = cannonOrigin(in: size)
        let groundY = size.height * 0.88
        // Randomise target angle and power to keep rounds varied
        let angles = [20.0, 30.0, 45.0, 55.0, 65.0]
        let targetAngle = angles.randomElement() ?? 45
        let v = GravityArtistPhysics.velocityForPower[selectedPower] ?? 350
        targetX = GravityArtistPhysics.targetX(
            angleDeg: targetAngle, velocity: v,
            cannonOrigin: cannon, canvasWidth: size.width, canvasHeight: groundY)
        predictedArcPoints = nil
        firedArcPoints = nil
        hitTarget = false
        phase = .aim
        neutralRoll = nil
        currentAngle = 45
    }

    // MARK: - Helpers

    private func cannonOrigin(in size: CGSize) -> CGPoint {
        CGPoint(x: size.width * 0.12, y: size.height * 0.88)
    }
}
