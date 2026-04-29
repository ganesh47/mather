import SwiftUI

/// Angle Cannon — children tilt the iPad to aim a cannon at a target,
/// learn that the angle determines where a projectile lands, and see
/// the degree label only AFTER a successful hit.
///
/// UX improvements (v2):
/// - Auto-calibrate on appear (no tap-to-aim dead zone)
/// - neutralRoll NOT reset between shots — keeps aim between retries
/// - Preview arc is bright coral so the aim is unmissable
/// - "Too high / too low" directional speech on miss
/// - Three star icons replace the abstract "Hit X of 3" text
/// - Target rendered as a bouncing star emoji label for delight
/// - Miss shows a brief directional arrow hinting which way to adjust
///
/// Age range: 7–9. CPA level: Concrete/Pictorial → Abstract.
struct AngleCannonView: View {

    @Bindable var appModel: AppModel

    // MARK: - Local state

    @State private var neutralRoll: Double? = nil
    @State private var calibrating = false          // shows "Hold steady…" banner
    /// Current aim angle in degrees [10, 80]. Snaps to multiples of 15°.
    @State private var currentAngleDeg: Double = 45
    /// Non-nil once FIRE is tapped; freezes the arc on screen.
    @State private var firedAngleDeg: Double? = nil
    @State private var hitTarget = false
    @State private var targetAngleDeg: Double = 45
    @State private var roundsWon = 0
    @State private var level: Int = 1   // 1 or 2
    @State private var sessionStart: Date = .now
    /// Briefly true on FIRE to animate the cannon barrel kick
    @State private var firePulse = false
    @State private var hasFiredOnce = false
    @State private var projectileProgress: Double = 0
    @State private var projectileAnimating = false
    @State private var pendingHit: Bool? = nil

    // MARK: - Constants

    private let snapDeg: Double = 15
    private let maxTiltRadians: Double = .pi / 4
    private let angleRange: ClosedRange<Double> = 10...80
    private let targetPool: [Double] = [15, 30, 45, 60, 75]
    /// Target symbols — rendered at the landing position for delight
    private let scenarios = AngleCannonScenario.defaultScenarios
    @State private var scenario = AngleCannonScenario.defaultScenarios[0]

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

                    canvasView(size: geo.size)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)

                    controlRow
                        .padding(.horizontal, 20)
                        .padding(.bottom, 20)
                }

                // "Hold steady…" calibration banner
                if calibrating {
                    VStack(spacing: 6) {
                        Text("Hold steady…")
                            .font(.headline.weight(.black))
                            .foregroundStyle(MatherTheme.ink)
                        Text("Setting your aim baseline")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(MatherTheme.cardSubtitle)
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 14)
                    .background(.ultraThinMaterial,
                                in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .transition(.scale.combined(with: .opacity))
                }
            }
        }
        .onChange(of: appModel.motionService.tiltRoll) { _, roll in
            guard let neutral = neutralRoll, firedAngleDeg == nil else { return }
            let delta = roll - neutral
            let raw = 45.0 + delta / maxTiltRadians * 35.0
            let clamped = max(angleRange.lowerBound, min(raw, angleRange.upperBound))
            currentAngleDeg = (clamped / snapDeg).rounded() * snapDeg
        }
        .onAppear {
            sessionStart = .now
            appModel.motionService.startUpdates()
            pickTarget()
            autoCalibrateNeutral()
        }
        .onDisappear {
            appModel.motionService.stopUpdates()
            guard roundsWon > 0 else { return }
            appModel.gameSessionStore.save(
                gameName: "Angle Cannon",
                startedAt: sessionStart,
                scoreValue: roundsWon,
                scoreLabel: "targets hit"
            )
        }
    }

    // MARK: - Auto-calibration

    /// Records neutralRoll after a short delay so the child has time to settle.
    /// Shows a "Hold steady…" banner during the wait.
    private func autoCalibrateNeutral() {
        guard neutralRoll == nil else { return }
        calibrating = true
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(600))
            neutralRoll = appModel.motionService.tiltRoll
            withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                calibrating = false
            }
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Angle Cannon")
                    .font(.title2.weight(.black))
                    .foregroundStyle(MatherTheme.ink)
                HStack(spacing: 6) {
                    Text("Level \(level)")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(MatherTheme.cardSubtitle)
                    Text("·")
                        .foregroundStyle(MatherTheme.cardSubtitle)
                    // Stars progress — fills as rounds are won
                    HStack(spacing: 3) {
                        ForEach(0..<3, id: \.self) { i in
                            Image(systemName: i < roundsWon ? "star.fill" : "star")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(i < roundsWon ? MatherTheme.warm : MatherTheme.ink.opacity(0.25))
                                .scaleEffect(i < roundsWon ? 1.15 : 1.0)
                                .animation(.spring(response: 0.3, dampingFraction: 0.6), value: roundsWon)
                        }
                    }
                }
            }
            Spacer()
            Button {
                appModel.engine.showHome()
                appModel.motionService.stopUpdates()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 30, weight: .bold))
                    .foregroundStyle(MatherTheme.ink.opacity(0.35))
                    .frame(width: 44, height: 44)
            }
            .accessibilityLabel("Done")
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

            // Fired arc — green on hit, warm amber on miss
            if let fired = firedAngleDeg {
                let firedPts = Self.arcPoints(angleDeg: fired, cannon: cannon, size: canvasSize)
                if firedPts.count >= 2 {
                    var arcPath = Path()
                    arcPath.move(to: firedPts[0])
                    for pt in firedPts.dropFirst() { arcPath.addLine(to: pt) }
                    ctx.stroke(arcPath,
                               with: .color(hitTarget ? MatherTheme.accent : MatherTheme.warm),
                               style: StrokeStyle(lineWidth: 3.5, lineCap: .round, lineJoin: .round))
                }
            }

            // Live preview arc — bright coral, dashed, prominent
            if firedAngleDeg == nil, neutralRoll != nil {
                let pts = Self.arcPoints(angleDeg: currentAngleDeg, cannon: cannon, size: canvasSize)
                if pts.count >= 2 {
                    var previewPath = Path()
                    previewPath.move(to: pts[0])
                    for pt in pts.dropFirst() { previewPath.addLine(to: pt) }
                    ctx.stroke(previewPath,
                               with: .color(MatherTheme.coral.opacity(0.75)),
                               style: StrokeStyle(lineWidth: 3, lineCap: .round,
                                                  dash: [10, 8]))
                }
            }

            // Target halo + ring so the landing goal reads clearly before the first shot
            let targetRect = CGRect(x: target.x - 34, y: target.y - 34, width: 68, height: 68)
            ctx.fill(Circle().path(in: targetRect.insetBy(dx: -18, dy: -18)),
                     with: .color((hitTarget ? MatherTheme.accent : MatherTheme.warm).opacity(0.12)))
            ctx.stroke(Circle().path(in: targetRect),
                       with: .color(hitTarget ? MatherTheme.accent : MatherTheme.coral), lineWidth: 4)
            ctx.stroke(Circle().path(in: targetRect.insetBy(dx: 10, dy: 10)),
                       with: .color((hitTarget ? MatherTheme.accent : MatherTheme.warm).opacity(0.55)),
                       style: StrokeStyle(lineWidth: 2, dash: [5, 4]))

            // Cannon body — scales on firePulse via overlay scaleEffect
            drawCannon(ctx: ctx, at: cannon, angleDeg: firedAngleDeg ?? currentAngleDeg)
        }
        .contentShape(Rectangle())
        .overlay(canvasOverlays)
        .accessibilityIdentifier("angle-cannon-canvas")
    }

    @ViewBuilder
    private var canvasOverlays: some View {
        GeometryReader { geo in
            let canvasSize = geo.size
            let cannon = cannonOrigin(in: canvasSize)
            let target = Self.targetPosition(
                angleDeg: targetAngleDeg,
                cannon: cannon,
                canvasSize: canvasSize
            )

            // Target symbol (bounces before firing)
            Text(scenario.targetSymbol)
                .font(.system(size: 30))
                .position(target)
                .opacity(hitTarget ? 0 : 1)
                .scaleEffect(hitTarget ? 2.0 : 1.0)
                .animation(.spring(response: 0.4, dampingFraction: 0.5), value: hitTarget)

            if let fired = firedAngleDeg, projectileAnimating || projectileProgress < 1 {
                let pts = Self.arcPoints(angleDeg: fired, cannon: cannon, size: canvasSize)
                if let projectile = Self.projectilePoint(on: pts, progress: projectileProgress) {
                    Text(scenario.projectileSymbol)
                        .font(.system(size: 26))
                        .position(projectile)
                        .shadow(color: MatherTheme.warm.opacity(0.45), radius: 8)
                        .accessibilityIdentifier("angle-cannon-projectile")
                }
            }

            missionChip
                .position(x: canvasSize.width / 2, y: canvasSize.height * 0.10)

            // Hit celebration burst
            if hitTarget {
                Text("💥")
                    .font(.system(size: 48))
                    .position(target)
                    .transition(.scale(scale: 0.3).combined(with: .opacity))
            }

            // Degree label — revealed only on hit (CPA abstract reveal)
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
                .position(x: canvasSize.width / 2, y: canvasSize.height * 0.35)
                .transition(.scale(scale: 0.6).combined(with: .opacity))
            }

            if neutralRoll != nil, firedAngleDeg == nil, !hasFiredOnce {
                VStack(spacing: 10) {
                    Text("Tilt to aim at the glowing target")
                        .font(.headline.weight(.black))
                        .foregroundStyle(MatherTheme.ink)
                    Text("When the dotted path looks right, tap FIRE.")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(MatherTheme.cardSubtitle)
                    HStack(spacing: 12) {
                        Label("Aim", systemImage: "scope")
                        Label("Fire", systemImage: "hand.tap.fill")
                    }
                    .font(.caption.weight(.bold))
                    .foregroundStyle(MatherTheme.coral)
                }
                .padding(.horizontal, 18)
                .padding(.vertical, 14)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(MatherTheme.warm.opacity(0.35), lineWidth: 1.5))
                .position(x: canvasSize.width / 2, y: canvasSize.height * 0.18)
                .transition(.scale.combined(with: .opacity))
            }

            if firedAngleDeg == nil {
                VStack(spacing: 4) {
                    Text("Aim here")
                        .font(.caption.weight(.black))
                        .foregroundStyle(.white)
                    Image(systemName: "arrow.down")
                        .font(.caption.weight(.black))
                        .foregroundStyle(.white)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .background(MatherTheme.coral, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                .position(x: target.x, y: max(36, target.y - 56))
                .shadow(color: .black.opacity(0.08), radius: 6, y: 3)
            }

            // "Too high / Too low" miss hint
            if let fired = firedAngleDeg, !hitTarget, !projectileAnimating, pendingHit == nil {
                let tooHigh = fired > targetAngleDeg
                HStack(spacing: 6) {
                    Image(systemName: tooHigh ? "arrow.down.circle.fill" : "arrow.up.circle.fill")
                        .foregroundStyle(MatherTheme.warm)
                    Text(tooHigh ? "Too high — tilt less" : "Too low — tilt more")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(MatherTheme.ink)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                .position(x: canvasSize.width / 2, y: canvasSize.height * 0.55)
                .transition(.scale.combined(with: .opacity))
            }

            // Aim angle readout while aiming (shows during aim, not before)
            if neutralRoll != nil, firedAngleDeg == nil {
                Text("\(Int(currentAngleDeg))°")
                    .font(.system(size: 28, weight: .black, design: .rounded))
                    .foregroundStyle(MatherTheme.coral)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 10))
                    .position(x: cannon.x + 80, y: cannon.y - 50)
                    .animation(.none, value: currentAngleDeg)
            }
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.6), value: hitTarget)
        .animation(.easeOut(duration: 0.25), value: firedAngleDeg != nil)
    }

    // MARK: - Controls

    private var controlRow: some View {
        HStack {
            Spacer()

            if projectileAnimating {
                ProgressView("Watching the arc…")
                    .font(.headline.weight(.bold))
                    .frame(minWidth: 180, minHeight: 60)
            } else if hitTarget {
                Button("Next →") {
                    advanceRound()
                }
                .font(.headline.weight(.black))
                .foregroundStyle(.white)
                .frame(minWidth: 140, minHeight: 60)
                .background(MatherTheme.accent, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                .accessibilityIdentifier("angle-cannon-next-button")
            } else if firedAngleDeg == nil {
                Button("FIRE!") {
                    fire()
                }
                .font(.system(size: 22, weight: .black, design: .rounded))
                .foregroundStyle(.white)
                .frame(minWidth: 140, minHeight: 60)
                .background(
                    neutralRoll != nil ? MatherTheme.coral : MatherTheme.coral.opacity(0.35),
                    in: RoundedRectangle(cornerRadius: 16, style: .continuous)
                )
                .disabled(neutralRoll == nil)
                .scaleEffect(firePulse ? 0.92 : 1.0)
                .animation(.spring(response: 0.2, dampingFraction: 0.5), value: firePulse)
                .accessibilityIdentifier("angle-cannon-fire-button")
            } else if !hitTarget {
                Button("Try Again") {
                    resetShot()
                }
                .font(.headline.weight(.semibold))
                .foregroundStyle(.white)
                .frame(minWidth: 140, minHeight: 60)
                .background(MatherTheme.ink.opacity(0.7),
                            in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                .accessibilityIdentifier("angle-cannon-retry-button")
            }
        }
    }

    // MARK: - Physics helpers (static so tests can call them)

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
            let y = cannon.y - vy * t + 0.5 * gravity * t * t
            guard x < size.width + 60, y < size.height + 40 else { break }
            pts.append(CGPoint(x: x, y: y))
            t += 0.025
        }
        return pts
    }

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
        let cx = max(80, min(x, canvasSize.width - 80))
        let cy = max(60, min(y, canvasSize.height * 0.85))
        return CGPoint(x: cx, y: cy)
    }

    nonisolated static func isHit(firedDeg: Double, targetDeg: Double, toleranceDeg: Double) -> Bool {
        abs(firedDeg - targetDeg) <= toleranceDeg
    }

    nonisolated static func projectilePoint(on points: [CGPoint], progress: Double) -> CGPoint? {
        guard !points.isEmpty else { return nil }
        let clamped = max(0, min(progress, 1))
        let exactIndex = clamped * Double(points.count - 1)
        let lower = Int(floor(exactIndex))
        let upper = min(points.count - 1, lower + 1)
        guard lower != upper else { return points[lower] }
        let t = exactIndex - Double(lower)
        let a = points[lower]
        let b = points[upper]
        return CGPoint(x: a.x + (b.x - a.x) * t,
                       y: a.y + (b.y - a.y) * t)
    }

    // MARK: - Layout helpers

    private func cannonOrigin(in size: CGSize) -> CGPoint {
        CGPoint(x: size.width * 0.12, y: size.height * 0.88)
    }

    private func drawCannon(ctx: GraphicsContext, at origin: CGPoint, angleDeg: Double) {
        let a = angleDeg * .pi / 180
        let barrelLen: CGFloat = 64
        let tipX = origin.x + barrelLen * cos(a)
        let tipY = origin.y - barrelLen * sin(a)

        var barrel = Path()
        barrel.move(to: origin)
        barrel.addLine(to: CGPoint(x: tipX, y: tipY))
        ctx.stroke(barrel,
                   with: .color(MatherTheme.ink.opacity(0.9)),
                   style: StrokeStyle(lineWidth: 12, lineCap: .round))

        // Carriage
        let wheelR: CGFloat = 16
        ctx.fill(Circle().path(in: CGRect(x: origin.x - wheelR * 2.2,
                                          y: origin.y - wheelR * 0.6,
                                          width: wheelR * 2, height: wheelR * 2)),
                 with: .color(MatherTheme.ink.opacity(0.7)))
        ctx.fill(Circle().path(in: CGRect(x: origin.x - wheelR * 0.4,
                                          y: origin.y - wheelR * 0.6,
                                          width: wheelR * 2, height: wheelR * 2)),
                 with: .color(MatherTheme.ink.opacity(0.7)))

        // Muzzle flash ring when firing
        if firePulse {
            ctx.stroke(Circle().path(in: CGRect(x: tipX - 14, y: tipY - 14,
                                                 width: 28, height: 28)),
                       with: .color(MatherTheme.warm.opacity(0.8)), lineWidth: 3)
        }
    }

    // MARK: - Actions

    private func fire() {
        guard neutralRoll != nil else { return }

        // Kick animation
        firePulse = true
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(150))
            firePulse = false
        }

        hasFiredOnce = true
        firedAngleDeg = currentAngleDeg
        pendingHit = Self.isHit(firedDeg: currentAngleDeg, targetDeg: targetAngleDeg,
                                toleranceDeg: hitTolerance)
        hitTarget = false
        projectileAnimating = true
        projectileProgress = 0
        withAnimation(.linear(duration: 0.9)) { projectileProgress = 1 }
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(900))
            resolveShotFeedback()
        }
    }

    /// Reset shot state but KEEP neutralRoll so the child doesn't lose calibration.
    private func resetShot() {
        firedAngleDeg = nil
        hitTarget = false
        projectileProgress = 0
        projectileAnimating = false
        pendingHit = nil
        // Deliberately NOT resetting neutralRoll — keeps aim baseline between retries.
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
        // Re-calibrate neutral for each new target (fresh tilt reference)
        neutralRoll = nil
        autoCalibrateNeutral()
    }

    private func pickTarget() {
        var candidates = targetPool.filter { abs($0 - targetAngleDeg) > 5 }
        if candidates.isEmpty { candidates = targetPool }
        targetAngleDeg = candidates.randomElement() ?? 45
        scenario = scenarios.first(where: { $0.targetAngleDeg == targetAngleDeg }) ?? scenarios.randomElement() ?? AngleCannonScenario.defaultScenarios[0]
        currentAngleDeg = 45
    }

    private func resolveShotFeedback() {
        guard let hit = pendingHit else { return }
        projectileAnimating = false
        pendingHit = nil
        hitTarget = hit
        if hit {
            appModel.hapticsService.balanceLock(enabled: appModel.featureFlags.hapticsEnabled)
            appModel.speechService.speak(
                scenario.successSpeech,
                enabled: appModel.featureFlags.audioEnabled
            )
            roundsWon += 1
        } else {
            appModel.hapticsService.failure(enabled: appModel.featureFlags.hapticsEnabled)
            let tooHigh = currentAngleDeg > targetAngleDeg
            appModel.speechService.speak(
                tooHigh ? "Too high — tilt a little less next time!"
                        : "Too low — tilt a bit more!",
                enabled: appModel.featureFlags.audioEnabled
            )
        }
    }

    private var missionChip: some View {
        HStack(spacing: 8) {
            Text(scenario.environmentSymbol)
            Text(scenario.missionSpeech)
                .font(.caption.weight(.black))
                .foregroundStyle(MatherTheme.ink)
                .lineLimit(2)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(.ultraThinMaterial, in: Capsule())
        .overlay(Capsule().stroke(MatherTheme.softBlue.opacity(0.35), lineWidth: 1))
    }
}

struct AngleCannonScenario: Equatable {
    let id: String
    let targetAngleDeg: Double
    let environmentSymbol: String
    let targetSymbol: String
    let projectileSymbol: String
    let missionSpeech: String
    let successSpeech: String

    static let defaultScenarios: [AngleCannonScenario] = [
        .init(id: "seed-pod", targetAngleDeg: 30, environmentSymbol: "🌱", targetSymbol: "🌿", projectileSymbol: "🫘", missionSpeech: "Send the seed pod to the hill ledge.", successSpeech: "The seed pod landed on the ledge!"),
        .init(id: "moon-gate", targetAngleDeg: 45, environmentSymbol: "🌙", targetSymbol: "🏮", projectileSymbol: "✨", missionSpeech: "Launch the lantern to the moon gate.", successSpeech: "The lantern reached the moon gate!"),
        .init(id: "festival-bell", targetAngleDeg: 60, environmentSymbol: "🎪", targetSymbol: "🔔", projectileSymbol: "⭐️", missionSpeech: "Ring the festival bell.", successSpeech: "You rang the festival bell!"),
        .init(id: "treehouse", targetAngleDeg: 75, environmentSymbol: "🌳", targetSymbol: "🏠", projectileSymbol: "📦", missionSpeech: "Toss the package to the treehouse.", successSpeech: "Package delivered to the treehouse!")
    ]
}
