import SwiftUI

// Gravity Sensor Lab — ages 8–10
// Tilt controls a screen-down gravity vector. The legacy predict/fire controls
// remain as a small comparison loop, but the first-read experience now teaches
// gravity direction with a tray, arrow, and rolling pebbles instead of another cannon.

// MARK: - Physics helpers (pure — testable)

enum GravitySensorPhysics {
    nonisolated static func normalizedVector(roll: Double, neutralRoll: Double = 0) -> CGVector {
        let delta = max(-Double.pi / 3, min(roll - neutralRoll, Double.pi / 3))
        let dx = sin(delta)
        let dy = cos(delta)
        let length = max(0.0001, sqrt(dx * dx + dy * dy))
        return CGVector(dx: dx / length, dy: dy / length)
    }

    nonisolated static func pebblePosition(origin: CGPoint, vector: CGVector, distance: Double, bounds: CGRect) -> CGPoint {
        let unclamped = CGPoint(x: origin.x + vector.dx * distance, y: origin.y + vector.dy * distance)
        return CGPoint(x: min(max(unclamped.x, bounds.minX), bounds.maxX),
                       y: min(max(unclamped.y, bounds.minY), bounds.maxY))
    }
}

enum GravityArtistPhysics {
    static let gravity: Double = 900   // pt/s²

    static let velocityForPower: [Int: Double] = [1: 200, 2: 350, 3: 500]

    nonisolated static func cannonOrigin(in size: CGSize) -> CGPoint {
        CGPoint(x: size.width * 0.12, y: size.height * 0.88)
    }

    nonisolated static func groundY(in size: CGSize) -> Double {
        size.height * 0.88
    }

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
        return Double(pts.last?.x ?? cannonOrigin.x)
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

    nonisolated static func arcPoints(launch: GravityArtistLaunch, canvasSize: CGSize) -> [CGPoint] {
        arcPoints(
            angleDeg: launch.angleDeg,
            velocity: launch.velocity,
            cannonOrigin: cannonOrigin(in: canvasSize),
            canvasHeight: groundY(in: canvasSize)
        )
    }

    nonisolated static func targetX(angleDeg: Double, power: Int, canvasSize: CGSize) -> Double {
        targetX(
            angleDeg: angleDeg,
            velocity: velocityForPower[power] ?? velocityForPower[2]!,
            cannonOrigin: cannonOrigin(in: canvasSize),
            canvasWidth: canvasSize.width,
            canvasHeight: groundY(in: canvasSize)
        )
    }
}

enum GravityArtistPhase: Equatable {
    case aim
    case predicted
    case fired
}

struct GravityArtistLaunch: Equatable {
    let angleDeg: Double
    let power: Int

    var velocity: Double {
        GravityArtistPhysics.velocityForPower[power] ?? GravityArtistPhysics.velocityForPower[2]!
    }
}

struct GravityArtistRoundState: Equatable {
    var selectedPower: Int = 2
    var targetAngle: Double = 45
    var targetPower: Int = 2
    var predictedLaunch: GravityArtistLaunch?
    var firedLaunch: GravityArtistLaunch?
    var phase: GravityArtistPhase = .aim

    mutating func selectPower(_ power: Int) {
        guard phase == .aim else { return }
        selectedPower = power
    }

    mutating func lockPrediction(angleDeg: Double) -> GravityArtistLaunch {
        let launch = GravityArtistLaunch(angleDeg: angleDeg, power: selectedPower)
        predictedLaunch = launch
        phase = .predicted
        return launch
    }

    mutating func fireLockedPrediction() -> GravityArtistLaunch? {
        guard let predictedLaunch else { return nil }
        firedLaunch = predictedLaunch
        phase = .fired
        return predictedLaunch
    }

    mutating func startNewRound(targetAngle: Double) {
        self.targetAngle = targetAngle
        targetPower = selectedPower
        predictedLaunch = nil
        firedLaunch = nil
        phase = .aim
    }
}

// MARK: - View

struct GravityArtistView: View {
    @Bindable var appModel: AppModel

    // Tilt
    @State private var neutralRoll: Double? = nil
    @State private var currentAngle: Double = 45       // degrees, 5–80

    // Game state
    @State private var roundState = GravityArtistRoundState()
    @State private var predictedArcPoints: [CGPoint]? = nil
    @State private var firedArcPoints: [CGPoint]? = nil
    @State private var targetX: Double = 0
    @State private var hitTarget: Bool = false
    @State private var roundsPlayed: Int = 0
    @State private var successStreak: Int = 0
    @State private var sessionStart: Date = .now

    // Canvas geometry captured from GeometryReader
    @State private var canvasSize: CGSize = .zero

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
                        handleCanvasSizeChange(geo.size)
                    }
                    .onChange(of: geo.size) { _, newSize in
                        handleCanvasSizeChange(newSize)
                    }
                }
                bottomBar
            }
        }
        .onChange(of: appModel.motionService.tiltRoll) { _, roll in
            guard roundState.phase == .aim else { return }
            if neutralRoll == nil { neutralRoll = roll }
            let delta = roll - neutralRoll!
            let raw = 45 + delta / (.pi / 4) * 35
            currentAngle = max(5, min(raw, 80))
        }
        .onAppear {
            sessionStart = .now
            appModel.motionService.startUpdates()
        }
        .onDisappear {
            appModel.motionService.stopUpdates()
            guard roundsPlayed > 0 else { return }
            appModel.gameSessionStore.save(
                gameName: "Gravity Artist",
                startedAt: sessionStart,
                scoreValue: roundsPlayed,
                scoreLabel: "rounds played"
            )
        }
    }

    // MARK: - Header

    private var headerBar: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Gravity Quest")
                    .font(.title2.weight(.black))
                    .foregroundStyle(MatherTheme.ink)
                Text(phaseHint)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
                HStack(spacing: 6) {
                    missionBadge("1 Predict", isActive: roundState.phase == .aim)
                    missionBadge("2 Simulate", isActive: roundState.phase == .predicted)
                    missionBadge("3 Learn", isActive: roundState.phase == .fired)
                }
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 4) {
                Text("⭐ \(successStreak)")
                    .font(.caption.weight(.black))
                    .foregroundStyle(MatherTheme.warm)
                Text("Round \(roundsPlayed + 1)")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(MatherTheme.cardSubtitle)
            }
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

    private func missionBadge(_ title: String, isActive: Bool) -> some View {
        Text(title)
            .font(.caption2.weight(.black))
            .foregroundStyle(isActive ? .white : MatherTheme.cardSubtitle)
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(isActive ? MatherTheme.accent : MatherTheme.panel.opacity(0.72), in: Capsule())
    }

    private var phaseHint: String {
        switch roundState.phase {
        case .aim:       return "Guess where the pebble will roll"
        case .predicted: return "Prediction locked — tilt, watch, and compare"
        case .fired:     return hitTarget ? "You predicted gravity!" : "New guess: what changed?"
        }
    }

    // MARK: - Arc canvas

    private func arcCanvas(size: CGSize) -> some View {
        Canvas { ctx, canvasSize in
            let cannon = GravityArtistPhysics.cannonOrigin(in: canvasSize)
            let groundY = GravityArtistPhysics.groundY(in: canvasSize)

            drawGravityTray(ctx: ctx, size: canvasSize)

            // Ground line for the small legacy compare loop
            var ground = Path()
            ground.move(to: CGPoint(x: 0, y: groundY))
            ground.addLine(to: CGPoint(x: canvasSize.width, y: groundY))
            ctx.stroke(ground, with: .color(MatherTheme.ink.opacity(0.10)), lineWidth: 2)

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
            if roundState.phase == .aim {
                let liveVelocity = GravityArtistPhysics.velocityForPower[roundState.selectedPower] ?? 350
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

    private func drawGravityTray(ctx: GraphicsContext, size: CGSize) {
        let tray = CGRect(x: size.width * 0.18, y: size.height * 0.13,
                          width: size.width * 0.64, height: size.height * 0.44)
        ctx.fill(RoundedRectangle(cornerRadius: 28).path(in: tray), with: .color(MatherTheme.softBlue.opacity(0.08)))
        ctx.fill(RoundedRectangle(cornerRadius: 28).path(in: tray.insetBy(dx: 6, dy: 6)), with: .color(MatherTheme.panelDeep.opacity(0.10)))
        ctx.stroke(RoundedRectangle(cornerRadius: 28).path(in: tray), with: .color(MatherTheme.softBlue.opacity(0.36)), lineWidth: 3)

        let neutral = neutralRoll ?? appModel.motionService.tiltRoll
        let vector = GravitySensorPhysics.normalizedVector(roll: appModel.motionService.tiltRoll, neutralRoll: neutral)
        let center = CGPoint(x: tray.midX, y: tray.midY)
        let arrowEnd = CGPoint(x: center.x + vector.dx * 90, y: center.y + vector.dy * 90)
        var arrow = Path(); arrow.move(to: center); arrow.addLine(to: arrowEnd)
        ctx.stroke(arrow, with: .color(MatherTheme.accent), style: StrokeStyle(lineWidth: 9, lineCap: .round))
        ctx.fill(Circle().path(in: CGRect(x: arrowEnd.x - 10, y: arrowEnd.y - 10, width: 20, height: 20)), with: .color(MatherTheme.accent))

        let pebbleBounds = tray.insetBy(dx: 34, dy: 34)
        for (index, offset) in [CGPoint(x: -48, y: -18), CGPoint(x: 0, y: 10), CGPoint(x: 44, y: -8)].enumerated() {
            let start = CGPoint(x: center.x + offset.x, y: center.y + offset.y)
            let pos = GravitySensorPhysics.pebblePosition(origin: start, vector: vector, distance: 54 + Double(index * 18), bounds: pebbleBounds)
            ctx.fill(Circle().path(in: CGRect(x: pos.x - 13, y: pos.y - 13, width: 26, height: 26)), with: .color(MatherTheme.warm.opacity(0.90)))
            ctx.fill(Circle().path(in: CGRect(x: pos.x - 4, y: pos.y - 4, width: 3, height: 3)), with: .color(MatherTheme.ink.opacity(0.55)))
            ctx.fill(Circle().path(in: CGRect(x: pos.x + 3, y: pos.y - 4, width: 3, height: 3)), with: .color(MatherTheme.ink.opacity(0.55)))
        }

        let label = ctx.resolve(Text("gravity pulls this way").font(.caption.bold()).foregroundStyle(MatherTheme.ink.opacity(0.70)))
        ctx.draw(label, at: CGPoint(x: tray.midX, y: tray.minY + 26))
    }

    // MARK: - Power selector

    private var powerSelector: some View {
        VStack(spacing: 6) {
            ForEach([3, 2, 1], id: \.self) { p in
                Button {
                    roundState.selectPower(p)
                } label: {
                    let size: CGFloat = p == 1 ? 18 : p == 2 ? 26 : 34
                    Image(systemName: "circle.fill")
                        .font(.system(size: size))
                        .foregroundStyle(roundState.selectedPower == p ? MatherTheme.accent : MatherTheme.ink.opacity(0.3))
                }
                .frame(width: 44, height: 44)
                .disabled(roundState.phase != .aim)
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
            conceptCard
            HStack(spacing: 16) {
                switch roundState.phase {
                case .aim:
                    crispActionButton(title: "PREDICT ROLL", fill: MatherTheme.warm) {
                        handlePredict()
                    }

                case .predicted:
                    crispActionButton(title: "OBSERVE", fill: MatherTheme.coral) {
                        handleFire()
                    }

                case .fired:
                    crispActionButton(title: "NEW ROLL", fill: MatherTheme.softBlue) {
                        handleNextRound()
                    }
                }
            }
            .padding(.horizontal, 24)

            Text("Tilt the device: the arrow shows screen-down gravity • no camera or location")
                .font(.caption)
                .foregroundStyle(.tertiary)
                .padding(.bottom, 16)
        }
    }

    private var conceptCard: some View {
        let contract = LabActivityID.gravityArtist.introConceptCard

        return HStack(alignment: .top, spacing: 10) {
            Image(systemName: roundState.phase == .fired ? (hitTarget ? "star.fill" : "lightbulb.fill") : "questionmark.bubble.fill")
                .font(.headline.weight(.black))
                .foregroundStyle(MatherTheme.warm)
            VStack(alignment: .leading, spacing: 3) {
                Text(contract?.title ?? "Gravity idea")
                    .font(.caption.weight(.black))
                    .foregroundStyle(MatherTheme.ink)
                Text(conceptCardText)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(MatherTheme.cardSubtitle)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(MatherTheme.card.opacity(0.86), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .padding(.horizontal, 24)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(contract?.accessibilityLabel ?? conceptCardText)
    }

    private var conceptCardText: String {
        let contract = LabActivityID.gravityArtist.introConceptCard
        switch roundState.phase {
        case .aim:
            return contract?.childPrompt ?? "Predict the path first."
        case .predicted:
            return "Now simulate: compare your dotted guess with the real roll."
        case .fired:
            return hitTarget ? (contract?.summaryPrompt ?? "Your prediction matched the simulation.") : "Learning: change angle or power, then test again."
        }
    }

    private func crispActionButton(title: String, fill: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 19, weight: .black, design: .rounded))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity, minHeight: 62)
                .background(fill, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(.white.opacity(0.65), lineWidth: 2)
                )
                .shadow(color: fill.opacity(0.24), radius: 6, y: 3)
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("gravity-crisp-action-button")
    }

    // MARK: - Actions

    private func handlePredict() {
        guard canvasSize != .zero else { return }
        let launch = roundState.lockPrediction(angleDeg: currentAngle)
        predictedArcPoints = GravityArtistPhysics.arcPoints(launch: launch, canvasSize: canvasSize)
        appModel.speechService.speak(
            "Prediction locked. Now fire!",
            enabled: appModel.featureFlags.audioEnabled
        )
    }

    private func handleFire() {
        guard canvasSize != .zero else { return }
        guard let launch = roundState.fireLockedPrediction() else { return }
        let fired = GravityArtistPhysics.arcPoints(launch: launch, canvasSize: canvasSize)
        firedArcPoints = fired
        let landX = fired.last?.x ?? GravityArtistPhysics.cannonOrigin(in: canvasSize).x
        hitTarget = GravityArtistPhysics.isHit(firedLandingX: landX, targetX: targetX, hitRadius: hitRadius)
        roundsPlayed += 1

        if hitTarget {
            successStreak += 1
            appModel.hapticsService.success(enabled: appModel.featureFlags.hapticsEnabled)
            appModel.speechService.speak(
                "Bull's eye! The launch angle was \(Int(launch.angleDeg.rounded())) degrees.",
                enabled: appModel.featureFlags.audioEnabled
            )
        } else {
            successStreak = 0
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
        // Randomise target angle and power to keep rounds varied
        let angles = [20.0, 30.0, 45.0, 55.0, 65.0]
        roundState.startNewRound(targetAngle: angles.randomElement() ?? 45)
        targetX = GravityArtistPhysics.targetX(
            angleDeg: roundState.targetAngle,
            power: roundState.targetPower,
            canvasSize: size
        )
        predictedArcPoints = nil
        firedArcPoints = nil
        hitTarget = false
        neutralRoll = nil
        currentAngle = 45
    }

    // MARK: - Helpers

    private func handleCanvasSizeChange(_ size: CGSize) {
        guard size != .zero else { return }
        let needsInitialRound = canvasSize == .zero
        canvasSize = size
        if needsInitialRound {
            setupNewRound(size: size)
        } else {
            refreshGeometryDependentState(size: size)
        }
    }

    private func refreshGeometryDependentState(size: CGSize) {
        targetX = GravityArtistPhysics.targetX(
            angleDeg: roundState.targetAngle,
            power: roundState.targetPower,
            canvasSize: size
        )

        if let predictedLaunch = roundState.predictedLaunch {
            predictedArcPoints = GravityArtistPhysics.arcPoints(launch: predictedLaunch, canvasSize: size)
        }

        if let firedLaunch = roundState.firedLaunch {
            let fired = GravityArtistPhysics.arcPoints(launch: firedLaunch, canvasSize: size)
            firedArcPoints = fired
            let landX = fired.last?.x ?? GravityArtistPhysics.cannonOrigin(in: size).x
            hitTarget = GravityArtistPhysics.isHit(firedLandingX: landX, targetX: targetX, hitRadius: hitRadius)
        }
    }

    private func cannonOrigin(in size: CGSize) -> CGPoint {
        GravityArtistPhysics.cannonOrigin(in: size)
    }
}
