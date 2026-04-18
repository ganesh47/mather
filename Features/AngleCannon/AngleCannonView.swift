import SwiftUI

/// Angle Cannon — children tilt the iPad to aim a cannon at a target,
/// learn that the angle determines where a projectile lands, and see
/// the degree label only AFTER a successful hit.
///
/// Age range: 7–9. CPA level: Concrete/Pictorial → Abstract.
/// Sensor: neutral-relative roll tilt (backward tilt = higher launch angle).
/// Three targets in a round (15°, 30°/45°/60°, 75°), randomly ordered.
/// Hit tolerance is 15° for level 1, 10° for level 2.
struct AngleCannonView: View {

    @Bindable var appModel: AppModel

    // MARK: - Local state

    @State private var neutralRoll: Double? = nil
    /// Current aim angle in degrees [10, 80]. Snaps to multiples of 15°.
    @State private var currentAngleDeg: Double = 45
    /// Non-nil once FIRE is tapped; freezes the arc on screen.
    @State private var firedAngleDeg: Double? = nil
    @State private var hitTarget = false
    @State private var targetAngleDeg: Double = 45
    @State private var roundsWon = 0
    @State private var level: Int = 1   // 1 or 2

    // MARK: - Constants

    private let snapDeg: Double = 15
    private let maxTiltRadians: Double = .pi / 4
    private let angleRange: ClosedRange<Double> = 10...80
    /// Available target angles — the arc must make a meaningful shape at each.
    private let targetPool: [Double] = [15, 30, 45, 60, 75]

    private var hitTolerance: Double { level == 1 ? 15 : 10 }

    // MARK: - Body

    var body: some View {
        GeometryReader { geo in
            ZStack {
                MatherTheme.background.ignoresSafeArea()
                VStack(spacing: 0) {
                    header
                        .padding(.horizontal, 20)
                        .padding(.top, 14)

                    // Playing field
                    canvasView(size: geo.size)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)

                    controlRow
                        .padding(.horizontal, 20)
                        .padding(.bottom, 20)
                }
            }
        }
        .onChange(of: appModel.motionService.tiltRoll) { _, roll in
            guard neutralRoll != nil, firedAngleDeg == nil else { return }
            let delta = roll - neutralRoll!
            // Tilt right (positive delta) → higher angle.
            let raw = 45.0 + delta / maxTiltRadians * 35.0
            let clamped = max(angleRange.lowerBound, min(raw, angleRange.upperBound))
            // Snap to nearest 15°
            currentAngleDeg = (clamped / snapDeg).rounded() * snapDeg
        }
        .onAppear {
            appModel.motionService.startUpdates()
            pickTarget()
        }
        .onDisappear {
            appModel.motionService.stopUpdates()
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Angle Cannon")
                    .font(.title2.weight(.black))
                    .foregroundStyle(MatherTheme.ink)
                Text("Level \(level) · Hit \(roundsWon) of 3")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(MatherTheme.cardSubtitle)
            }
            Spacer()
            Button("Done") {
                appModel.engine.showHome()
                appModel.motionService.stopUpdates()
            }
            .font(.headline.weight(.semibold))
            .foregroundStyle(.white)
            .frame(minWidth: 88, minHeight: 44)
            .background(
                MatherTheme.ink.opacity(0.65),
                in: RoundedRectangle(cornerRadius: 12, style: .continuous)
            )
            .accessibilityIdentifier("angle-cannon-done-button")
        }
    }

    // MARK: - Canvas

    private func canvasView(size: CGSize) -> some View {
        Canvas { ctx, canvasSize in
            let cannon = cannonOrigin(in: canvasSize)
            let target = Self.targetPosition(
                angleDeg: targetAngleDeg,
                cannon: cannon,
                canvasSize: canvasSize
            )

            // Ground
            var ground = Path()
            ground.move(to: CGPoint(x: 0, y: canvasSize.height * 0.92))
            ground.addLine(to: CGPoint(x: canvasSize.width, y: canvasSize.height * 0.92))
            ctx.stroke(ground, with: .color(MatherTheme.ink.opacity(0.15)), lineWidth: 2)

            // Fired arc (solid amber)
            if let fired = firedAngleDeg {
                let firedPts = Self.arcPoints(angleDeg: fired, cannon: cannon, size: canvasSize)
                if firedPts.count >= 2 {
                    var arcPath = Path()
                    arcPath.move(to: firedPts[0])
                    for pt in firedPts.dropFirst() { arcPath.addLine(to: pt) }
                    ctx.stroke(arcPath,
                               with: .color(hitTarget ? MatherTheme.accent : MatherTheme.warm),
                               style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))
                }
            }

            // Preview arc (dotted, current aim)
            if firedAngleDeg == nil, neutralRoll != nil {
                let pts = Self.arcPoints(angleDeg: currentAngleDeg, cannon: cannon, size: canvasSize)
                if pts.count >= 2 {
                    var previewPath = Path()
                    previewPath.move(to: pts[0])
                    for pt in pts.dropFirst() { previewPath.addLine(to: pt) }
                    ctx.stroke(previewPath,
                               with: .color(MatherTheme.ink.opacity(0.3)),
                               style: StrokeStyle(lineWidth: 2.5, lineCap: .round,
                                                  dash: [8, 10]))
                }
            }

            // Target: outer ring + inner dot
            ctx.stroke(Circle().path(in: CGRect(
                x: target.x - 24, y: target.y - 24, width: 48, height: 48
            )), with: .color(MatherTheme.coral), lineWidth: 3)
            ctx.fill(Circle().path(in: CGRect(
                x: target.x - 10, y: target.y - 10, width: 20, height: 20
            )), with: .color(hitTarget ? MatherTheme.accent : MatherTheme.coral))

            // Cannon body
            drawCannon(ctx: ctx, at: cannon, angleDeg: firedAngleDeg ?? currentAngleDeg)

            // "Tap to aim" callout when no neutral set
            if neutralRoll == nil {
                let calloutRect = CGRect(x: cannon.x + 20, y: cannon.y - 60, width: 160, height: 40)
                ctx.fill(
                    RoundedRectangle(cornerRadius: 8).path(in: calloutRect),
                    with: .color(MatherTheme.warm.opacity(0.15))
                )
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            if neutralRoll == nil {
                neutralRoll = appModel.motionService.tiltRoll
            }
        }
        .overlay(degreeLabel, alignment: .center)
        .overlay(tapToAimLabel, alignment: .bottomLeading)
        .accessibilityIdentifier("angle-cannon-canvas")
    }

    @ViewBuilder
    private var degreeLabel: some View {
        if hitTarget, let fired = firedAngleDeg {
            VStack(spacing: 2) {
                Text("\(Int(fired))°")
                    .font(.system(size: 52, weight: .black, design: .rounded))
                    .foregroundStyle(MatherTheme.accent)
                Text("degrees!")
                    .font(.title3.weight(.bold))
                    .foregroundStyle(MatherTheme.accent)
            }
            .padding(16)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .transition(.scale(scale: 0.6).combined(with: .opacity))
        }
    }

    @ViewBuilder
    private var tapToAimLabel: some View {
        if neutralRoll == nil {
            HStack(spacing: 6) {
                Image(systemName: "hand.tap.fill")
                    .foregroundStyle(MatherTheme.coral)
                Text("Tap to aim")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(MatherTheme.cardSubtitle)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            .padding(.horizontal, 20)
            .padding(.bottom, 8)
        }
    }

    // MARK: - Controls

    private var controlRow: some View {
        HStack {
            // Current angle indicator (visible while aiming)
            if neutralRoll != nil && firedAngleDeg == nil {
                VStack(spacing: 2) {
                    Text("\(Int(currentAngleDeg))°")
                        .font(.system(size: 32, weight: .black, design: .rounded))
                        .foregroundStyle(MatherTheme.ink)
                    Text("aim angle")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                }
                .frame(minWidth: 80)
                .accessibilityIdentifier("angle-cannon-angle-label")
            }

            Spacer()

            if hitTarget {
                Button("Next") {
                    advanceRound()
                }
                .font(.headline.weight(.black))
                .foregroundStyle(.white)
                .frame(minWidth: 120, minHeight: 60)
                .background(MatherTheme.accent, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                .accessibilityIdentifier("angle-cannon-next-button")
            } else if firedAngleDeg == nil {
                Button("FIRE!") {
                    fire()
                }
                .font(.system(size: 22, weight: .black, design: .rounded))
                .foregroundStyle(.white)
                .frame(minWidth: 120, minHeight: 60)
                .background(
                    neutralRoll != nil ? MatherTheme.coral : MatherTheme.coral.opacity(0.4),
                    in: RoundedRectangle(cornerRadius: 16, style: .continuous)
                )
                .disabled(neutralRoll == nil)
                .accessibilityIdentifier("angle-cannon-fire-button")
            } else if !hitTarget {
                Button("Try Again") {
                    resetShot()
                }
                .font(.headline.weight(.semibold))
                .foregroundStyle(.white)
                .frame(minWidth: 120, minHeight: 60)
                .background(MatherTheme.ink.opacity(0.7), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                .accessibilityIdentifier("angle-cannon-retry-button")
            }
        }
    }

    // MARK: - Physics helpers (static so tests can call them)

    /// Parabolic arc through screen coordinates.
    /// Cannon at `cannon`; angle above horizontal in degrees.
    nonisolated static func arcPoints(
        angleDeg: Double,
        cannon: CGPoint,
        size: CGSize,
        velocity: Double = 480,
        gravity: Double = 900
    ) -> [CGPoint] {
        let a = angleDeg * .pi / 180
        let vx = velocity * cos(a)
        let vy = velocity * sin(a)
        var pts: [CGPoint] = []
        var t = 0.0
        while t <= 2.5 {
            let x = cannon.x + vx * t
            // Screen y: cannon.y is near bottom, moving up = y decreasing.
            // vy*t moves up (decreasing screen-y), gravity moves it down (increasing screen-y).
            let y = cannon.y - vy * t + 0.5 * gravity * t * t
            guard x < size.width + 60, y < size.height + 40 else { break }
            pts.append(CGPoint(x: x, y: y))
            t += 0.025
        }
        return pts
    }

    /// Position of the target: on the arc at t=0.8s.
    nonisolated static func targetPosition(
        angleDeg: Double,
        cannon: CGPoint,
        canvasSize: CGSize,
        velocity: Double = 480,
        gravity: Double = 900
    ) -> CGPoint {
        let t = 0.8
        let a = angleDeg * .pi / 180
        let x = cannon.x + velocity * cos(a) * t
        let y = cannon.y - (velocity * sin(a) * t - 0.5 * gravity * t * t)
        // Clamp to visible area
        let cx = max(80, min(x, canvasSize.width - 80))
        let cy = max(60, min(y, canvasSize.height * 0.85))
        return CGPoint(x: cx, y: cy)
    }

    /// True if fired angle is within tolerance of target angle.
    nonisolated static func isHit(firedDeg: Double, targetDeg: Double, toleranceDeg: Double) -> Bool {
        abs(firedDeg - targetDeg) <= toleranceDeg
    }

    // MARK: - Layout helpers

    private func cannonOrigin(in size: CGSize) -> CGPoint {
        CGPoint(x: size.width * 0.12, y: size.height * 0.88)
    }

    private func drawCannon(ctx: GraphicsContext, at origin: CGPoint, angleDeg: Double) {
        let a = angleDeg * .pi / 180
        let barrelLen: CGFloat = 56
        let tipX = origin.x + barrelLen * cos(a)
        let tipY = origin.y - barrelLen * sin(a)

        // Barrel
        var barrel = Path()
        barrel.move(to: origin)
        barrel.addLine(to: CGPoint(x: tipX, y: tipY))
        ctx.stroke(barrel,
                   with: .color(MatherTheme.ink.opacity(0.85)),
                   style: StrokeStyle(lineWidth: 10, lineCap: .round))

        // Wheels (two circles)
        let wheelR: CGFloat = 14
        ctx.fill(
            Circle().path(in: CGRect(x: origin.x - wheelR * 1.4 - wheelR,
                                     y: origin.y - wheelR / 2,
                                     width: wheelR * 2, height: wheelR * 2)),
            with: .color(MatherTheme.ink.opacity(0.7))
        )
        ctx.fill(
            Circle().path(in: CGRect(x: origin.x - wheelR / 2,
                                     y: origin.y - wheelR / 2,
                                     width: wheelR * 2, height: wheelR * 2)),
            with: .color(MatherTheme.ink.opacity(0.7))
        )
    }

    // MARK: - Actions

    private func fire() {
        guard neutralRoll != nil else { return }
        firedAngleDeg = currentAngleDeg
        let hit = Self.isHit(firedDeg: currentAngleDeg, targetDeg: targetAngleDeg,
                             toleranceDeg: hitTolerance)
        hitTarget = hit
        if hit {
            appModel.hapticsService.balanceLock(enabled: appModel.featureFlags.hapticsEnabled)
            appModel.speechService.speak(
                "\(Int(currentAngleDeg)) degrees — you hit it!",
                enabled: appModel.featureFlags.audioEnabled
            )
            roundsWon += 1
        } else {
            appModel.hapticsService.failure(enabled: appModel.featureFlags.hapticsEnabled)
        }
    }

    private func resetShot() {
        firedAngleDeg = nil
        hitTarget = false
        neutralRoll = nil   // re-calibrate neutral on next tap
    }

    private func advanceRound() {
        if roundsWon >= 3 {
            if level == 1 {
                level = 2
                roundsWon = 0
            } else {
                appModel.engine.showHome()
                return
            }
        }
        resetShot()
        pickTarget()
    }

    private func pickTarget() {
        // Pick a random target, different from current
        var candidates = targetPool.filter { abs($0 - targetAngleDeg) > 5 }
        if candidates.isEmpty { candidates = targetPool }
        targetAngleDeg = candidates.randomElement() ?? 45
        currentAngleDeg = 45
    }
}
