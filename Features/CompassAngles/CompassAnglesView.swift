import SwiftUI

// Compass Angles — ages 7–9
// The child holds the iPad and physically turns their body.
// CMDeviceMotion.attitude relative yaw tracks the rotation angle.
// No magnetometer: pure gyroscope relative rotation — no permission needed.
// A compass rose shows the live heading; a blue target dot shows the goal.
// When the child turns to within ±10° of the target angle the activity snaps.

// MARK: - Snap math helpers (pure — testable)

enum CompassMath {
    /// Normalise a relative-yaw value to [−180, +180].
    static func normalise(_ yaw: Double) -> Double {
        var y = yaw.truncatingRemainder(dividingBy: 360)
        if y > 180 { y -= 360 }
        if y < -180 { y += 360 }
        return y
    }

    /// True when the live heading is within `tolerance` degrees of the target.
    static func isInSnapZone(yaw: Double, target: Double, tolerance: Double = 10) -> Bool {
        let diff = abs(normalise(yaw - target))
        return diff <= tolerance
    }

    /// Angular distance (0–180) between two headings.
    static func angularDistance(_ a: Double, _ b: Double) -> Double {
        abs(normalise(a - b))
    }
}

// MARK: - Level config

private struct CompassLevel {
    let targetDeg: Double          // positive = turn right, negative = turn left
    let instruction: String        // spoken
    let directionHint: String      // shown in UI
}

enum BodyTurnDirection {
    case left
    case right
    case around
}

private let levels: [CompassLevel] = [
    CompassLevel(targetDeg: 90,  instruction: "Turn 90 degrees to the right",       directionHint: "Turn right 90°"),
    CompassLevel(targetDeg: 180, instruction: "Turn all the way around, 180 degrees", directionHint: "Turn 180°"),
    CompassLevel(targetDeg: 45,  instruction: "Turn 45 degrees to the right",       directionHint: "Turn right 45°"),
    CompassLevel(targetDeg: -90, instruction: "Turn 90 degrees to the left",        directionHint: "Turn left 90°"),
    CompassLevel(targetDeg: 270, instruction: "Turn 270 degrees, three-quarters around", directionHint: "Turn 270°"),
]

// MARK: - Main view

struct CompassAnglesView: View {
    @Bindable var appModel: AppModel

    @State private var levelIndex: Int = 0
    @State private var matched: Bool = false
    @State private var wonCount: Int = 0
    @State private var sessionStart: Date = .now
    @State private var showDegreeLabel: Bool = false

    private var level: CompassLevel { levels[levelIndex % levels.count] }
    private var currentYaw: Double { appModel.motionService.relativeYaw }

    var body: some View {
        ZStack {
            MatherTheme.background.ignoresSafeArea()
            VStack(spacing: 0) {
                headerBar
                GeometryReader { geo in
                    ZStack {
                        compassCanvas(size: geo.size)
                        if showDegreeLabel { degreeLabel }
                        if !appModel.motionService.trackingRelativeYaw { setupOverlay }
                    }
                }
                .onChange(of: appModel.motionService.relativeYaw) { _, yaw in
                    checkSnap(yaw: yaw)
                }
                bottomBar
            }
        }
        .onAppear {
            sessionStart = .now
            appModel.motionService.startUpdates()
        }
        .onDisappear {
            appModel.motionService.stopRelativeYawTracking()
            appModel.motionService.stopUpdates()
            guard wonCount > 0 else { return }
            appModel.gameSessionStore.save(
                gameName: "Compass Walk",
                startedAt: sessionStart,
                scoreValue: wonCount,
                scoreLabel: "turns completed"
            )
        }
    }

    // MARK: - Header

    private var headerBar: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Compass Angles")
                    .font(.title2.weight(.black))
                    .foregroundStyle(MatherTheme.ink)
                Text(level.directionHint)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
                Text(Self.bodyRelativeHint(for: level.targetDeg))
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(MatherTheme.cardSubtitle)
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

    // MARK: - Setup overlay (before tracking starts)

    private var setupOverlay: some View {
        VStack(spacing: 16) {
            Image(systemName: "arrow.turn.up.right")
                .font(.system(size: 48))
                .foregroundStyle(MatherTheme.softBlue)
            Text("Hold iPad flat, then tap START")
                .font(.headline.weight(.semibold))
                .foregroundStyle(MatherTheme.ink)
                .multilineTextAlignment(.center)
            Text("Turn your body until the red pointer reaches the blue target.")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(MatherTheme.cardSubtitle)
                .multilineTextAlignment(.center)
            Button("START") {
                appModel.motionService.startRelativeYawTracking()
                appModel.speechService.speak(level.instruction,
                                             enabled: appModel.featureFlags.audioEnabled)
            }
            .font(.headline.weight(.bold))
            .foregroundStyle(.white)
            .padding(.horizontal, 32)
            .padding(.vertical, 16)
            .background(MatherTheme.accent)
            .clipShape(Capsule())
        }
        .padding(28)
        .background(MatherTheme.card.opacity(0.95))
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
    }

    // MARK: - Compass canvas

    private func compassCanvas(size: CGSize) -> some View {
        let centre = CGPoint(x: size.width / 2, y: size.height / 2)
        let radius = min(size.width, size.height) * 0.38

        return Canvas { ctx, canvasSize in
            let cx = canvasSize.width / 2
            let cy = canvasSize.height / 2

            // Outer ring
            let ringRect = CGRect(x: cx - radius, y: cy - radius,
                                   width: radius * 2, height: radius * 2)
            ctx.stroke(Circle().path(in: ringRect),
                       with: .color(MatherTheme.ink.opacity(0.15)), lineWidth: 2)

            // Tick marks for every 30°
            for deg in stride(from: 0.0, to: 360.0, by: 30.0) {
                let isMajor = deg.truncatingRemainder(dividingBy: 90) == 0
                let rad = deg * .pi / 180
                let inner = radius * (isMajor ? 0.82 : 0.88)
                let outer = radius
                let ix = cx + inner * sin(rad)
                let iy = cy - inner * cos(rad)
                let ox = cx + outer * sin(rad)
                let oy = cy - outer * cos(rad)
                var tick = Path()
                tick.move(to: CGPoint(x: ix, y: iy))
                tick.addLine(to: CGPoint(x: ox, y: oy))
                ctx.stroke(tick, with: .color(MatherTheme.ink.opacity(isMajor ? 0.5 : 0.2)),
                           lineWidth: isMajor ? 2 : 1)
            }

            // Target arc sweep (blue dotted)
            let targetRad = level.targetDeg * .pi / 180
            let arcStartAngle: Double = -.pi / 2   // 12-o'clock
            let arcEndAngle = arcStartAngle + targetRad
            var targetArc = Path()
            targetArc.addArc(center: CGPoint(x: cx, y: cy),
                             radius: radius * 0.65,
                             startAngle: .radians(arcStartAngle),
                             endAngle: .radians(arcEndAngle),
                             clockwise: level.targetDeg < 0)
            ctx.stroke(targetArc,
                       with: .color(MatherTheme.softBlue.opacity(0.5)),
                       style: StrokeStyle(lineWidth: 4, lineCap: .round, dash: [8, 6]))

            // Target dot
            let tdx = cx + radius * 0.65 * sin(targetRad)
            let tdy = cy - radius * 0.65 * cos(targetRad)
            let tdr: CGFloat = 10
            ctx.fill(Circle().path(in: CGRect(x: tdx - tdr, y: tdy - tdr,
                                               width: tdr*2, height: tdr*2)),
                     with: .color(MatherTheme.softBlue))

            // Live rotation needle (red, from centre to edge, rotates with yaw)
            let yawRad = currentYaw * .pi / 180
            let needleTipX = cx + radius * 0.8 * sin(yawRad)
            let needleTipY = cy - radius * 0.8 * cos(yawRad)
            let tailX = cx - radius * 0.3 * sin(yawRad)
            let tailY = cy + radius * 0.3 * cos(yawRad)
            var needle = Path()
            needle.move(to: CGPoint(x: tailX, y: tailY))
            needle.addLine(to: CGPoint(x: needleTipX, y: needleTipY))
            let needleColor: Color = matched ? MatherTheme.accent : MatherTheme.coral
            ctx.stroke(needle, with: .color(needleColor), lineWidth: 4)

            // Centre dot
            let cr: CGFloat = 8
            ctx.fill(Circle().path(in: CGRect(x: cx - cr, y: cy - cr, width: cr*2, height: cr*2)),
                     with: .color(MatherTheme.ink))

            // North label (always at top)
            let northLabel = ctx.resolve(
                Text("N").font(.system(size: 16, weight: .bold)).foregroundStyle(MatherTheme.ink.opacity(0.4))
            )
            ctx.draw(northLabel, at: CGPoint(x: cx, y: cy - radius * 0.92))
        }
    }

    // MARK: - Degree label

    private var degreeLabel: some View {
        VStack(spacing: 4) {
            Text("\(Int(CompassMath.angularDistance(currentYaw, 0).rounded()))°")
                .font(.system(size: 64, weight: .black, design: .rounded))
                .foregroundStyle(matched ? MatherTheme.accent : MatherTheme.ink)
            if matched {
                Text("You turned \(Int(level.targetDeg.magnitude))°!")
                    .font(.headline.weight(.bold))
                    .foregroundStyle(MatherTheme.accent)
            }
        }
        .padding(20)
        .background(MatherTheme.card.opacity(0.92))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: .black.opacity(0.08), radius: 12, y: 4)
        .transition(.scale.combined(with: .opacity))
        .animation(.spring(response: 0.3), value: matched)
    }

    // MARK: - Bottom bar

    private var bottomBar: some View {
        VStack(spacing: 8) {
            turnCueCard

            if matched {
                Button(action: advanceLevel) {
                    Text(wonCount >= levels.count ? "All done!" : "Next turn →")
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
            Text("Turn your whole body to match the angle")
                .font(.caption)
                .foregroundStyle(.tertiary)
                .padding(.bottom, 16)
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: matched)
    }

    private var turnCueCard: some View {
        HStack(spacing: 12) {
            Image(systemName: Self.turnCueSymbol(for: level.targetDeg))
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(MatherTheme.softBlue)
                .frame(width: 34, height: 34)
                .background(MatherTheme.softBlue.opacity(0.12), in: Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(Self.turnCueTitle(for: level.targetDeg))
                    .font(.subheadline.weight(.black))
                    .foregroundStyle(MatherTheme.ink)
                Text(Self.bodyRelativeHint(for: level.targetDeg))
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(MatherTheme.cardSubtitle)
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(MatherTheme.card.opacity(0.92), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .padding(.horizontal, 24)
    }

    nonisolated static func turnDirection(for targetDeg: Double) -> BodyTurnDirection {
        let normalized = CompassMath.normalise(targetDeg)
        if abs(abs(normalized) - 180) < 0.01 || abs(normalized) < 0.01 {
            return .around
        }
        return normalized > 0 ? .right : .left
    }

    nonisolated static func bodyRelativeHint(for targetDeg: Double) -> String {
        switch turnDirection(for: targetDeg) {
        case .right:
            return "Move your body to the right until the red pointer touches the blue dot."
        case .left:
            return "Move your body to the left until the red pointer touches the blue dot."
        case .around:
            return "Keep turning your body until the red pointer reaches the blue dot."
        }
    }

    nonisolated static func turnCueTitle(for targetDeg: Double) -> String {
        switch turnDirection(for: targetDeg) {
        case .right: return "Your right"
        case .left: return "Your left"
        case .around: return "Keep turning"
        }
    }

    nonisolated static func turnCueSymbol(for targetDeg: Double) -> String {
        switch turnDirection(for: targetDeg) {
        case .right: return "arrow.turn.up.right"
        case .left: return "arrow.turn.up.left"
        case .around: return "arrow.clockwise"
        }
    }

    // MARK: - Logic

    private func checkSnap(yaw: Double) {
        guard !matched else { return }
        showDegreeLabel = true
        if CompassMath.isInSnapZone(yaw: yaw, target: level.targetDeg) {
            matched = true
            wonCount += 1
            appModel.hapticsService.success(enabled: appModel.featureFlags.hapticsEnabled)
            appModel.speechService.speak(
                "Perfect! You turned \(Int(level.targetDeg.magnitude)) degrees.",
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
        // Re-zero for the next turn
        appModel.motionService.startRelativeYawTracking()
        appModel.speechService.speak(level.instruction, enabled: appModel.featureFlags.audioEnabled)
    }
}
