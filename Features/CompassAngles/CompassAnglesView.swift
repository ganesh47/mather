import SwiftUI

// Compass Angles — ages 7–9
// The child takes a few small careful steps, then physically turns their body.
// Step sensing uses StepCountService with manual fallback; turn sensing keeps the
// existing body-relative yaw snap math from MotionService.

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

// MARK: - Level/state config

enum BodyTurnDirection {
    case left
    case right
    case around
}

enum CompassWalkDirection: String, CaseIterable {
    case forward
    case left
    case right

    var title: String {
        switch self {
        case .forward: "forward"
        case .left: "to your left"
        case .right: "to your right"
        }
    }

    var symbol: String {
        switch self {
        case .forward: "arrow.up"
        case .left: "arrow.left"
        case .right: "arrow.right"
        }
    }
}

enum CompassWalkTurnPhase: Equatable {
    case ready
    case walking
    case turning
    case success
}

struct CompassWalkTurnLevel: Equatable, Identifiable {
    let id: Int
    let walkDirection: CompassWalkDirection
    let steps: Int
    let targetDeg: Double          // positive = turn right, negative = turn left

    var instruction: String {
        "Walk \(steps) small steps \(walkDirection.title), then \(turnPhrase)."
    }

    var walkHint: String {
        "Walk \(steps) small careful steps \(walkDirection.title)."
    }

    var turnHint: String {
        switch CompassAnglesView.turnDirection(for: targetDeg) {
        case .right: "Then turn right \(Int(targetDeg.magnitude))°."
        case .left: "Then turn left \(Int(targetDeg.magnitude))°."
        case .around: "Then turn around \(Int(targetDeg.magnitude))°."
        }
    }

    var shortHint: String { "\(walkHint) \(turnHint)" }

    private var turnPhrase: String {
        switch CompassAnglesView.turnDirection(for: targetDeg) {
        case .right: "turn right \(Int(targetDeg.magnitude)) degrees"
        case .left: "turn left \(Int(targetDeg.magnitude)) degrees"
        case .around: "turn around \(Int(targetDeg.magnitude)) degrees"
        }
    }
}

struct CompassWalkTurnState: Equatable {
    let level: CompassWalkTurnLevel
    private(set) var phase: CompassWalkTurnPhase = .ready
    private(set) var stepProgress: StepWalkProgress

    init(level: CompassWalkTurnLevel, phase: CompassWalkTurnPhase = .ready) {
        self.level = level
        self.phase = phase
        self.stepProgress = StepWalkProgress(requiredSteps: level.steps)
    }

    var isWalkComplete: Bool { stepProgress.isComplete }

    mutating func startWalking() {
        phase = .walking
        stepProgress = StepWalkProgress(requiredSteps: level.steps)
    }

    mutating func applyCountedSteps(_ steps: Int) {
        guard phase == .walking else { return }
        stepProgress.setCountedSteps(steps)
        if stepProgress.isComplete { phase = .turning }
    }

    mutating func startTurningIfWalkComplete() {
        guard stepProgress.isComplete else { return }
        phase = .turning
    }

    mutating func applyYaw(_ yaw: Double, tolerance: Double = 10) {
        guard phase == .turning else { return }
        if CompassMath.isInSnapZone(yaw: yaw, target: level.targetDeg, tolerance: tolerance) {
            phase = .success
        }
    }
}

let compassWalkTurnLevels: [CompassWalkTurnLevel] = [
    CompassWalkTurnLevel(id: 1, walkDirection: .forward, steps: 3, targetDeg: 90),
    CompassWalkTurnLevel(id: 2, walkDirection: .right, steps: 2, targetDeg: 180),
    CompassWalkTurnLevel(id: 3, walkDirection: .forward, steps: 4, targetDeg: 45),
    CompassWalkTurnLevel(id: 4, walkDirection: .left, steps: 2, targetDeg: -90),
    CompassWalkTurnLevel(id: 5, walkDirection: .forward, steps: 3, targetDeg: 270)
]

// MARK: - Main view

struct CompassAnglesView: View {
    @Bindable var appModel: AppModel

    @State private var levelIndex: Int = 0
    @State private var phase: CompassWalkTurnPhase = .ready
    @State private var wonCount: Int = 0
    @State private var sessionStart: Date = .now
    @State private var showDegreeLabel: Bool = false
    @State private var showTurnFallback: Bool = false

    private var level: CompassWalkTurnLevel { compassWalkTurnLevels[levelIndex % compassWalkTurnLevels.count] }
    private var currentYaw: Double { appModel.motionService.relativeYaw }
    private var stepService: StepCountService { appModel.stepCountService }
    private var turnMatched: Bool { phase == .success }

    var body: some View {
        ZStack {
            MatherTheme.background.ignoresSafeArea()
            VStack(spacing: 0) {
                headerBar
                GeometryReader { geo in
                    ZStack {
                        compassCanvas(size: geo.size)
                        if showDegreeLabel { degreeLabel }
                        if phase == .ready { setupOverlay }
                    }
                }
                .onChange(of: appModel.motionService.relativeYaw) { _, yaw in
                    checkSnap(yaw: yaw)
                }
                .onChange(of: stepService.countedSteps) { _, _ in
                    checkWalkProgress()
                }
                bottomBar
            }
        }
        .onAppear {
            sessionStart = .now
            appModel.motionService.startUpdates()
        }
        .onDisappear {
            appModel.stepCountService.stop()
            appModel.motionService.stopRelativeYawTracking()
            appModel.motionService.stopUpdates()
            guard wonCount > 0 else { return }
            appModel.gameSessionStore.save(
                gameName: "Compass Walk",
                startedAt: sessionStart,
                scoreValue: wonCount,
                scoreLabel: "walk-turn levels completed"
            )
        }
    }

    // MARK: - Header

    private var headerBar: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Compass Walk")
                    .font(.title2.weight(.black))
                    .foregroundStyle(MatherTheme.ink)
                Text(level.shortHint)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                Text("Clear space • small steps • no running")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(MatherTheme.cardSubtitle)
            }
            Spacer()
            Button { appModel.engine.showHome() } label: {
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

    // MARK: - Setup overlay

    private var setupOverlay: some View {
        VStack(spacing: 16) {
            Image(systemName: "figure.walk")
                .font(.system(size: 48))
                .foregroundStyle(MatherTheme.softBlue)
            Text("Make a safe space first")
                .font(.headline.weight(.semibold))
                .foregroundStyle(MatherTheme.ink)
                .multilineTextAlignment(.center)
            Text("Take small careful steps. Keep the iPad steady. No running, jumping, stairs, or bumps.")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(MatherTheme.cardSubtitle)
                .multilineTextAlignment(.center)
            Text(level.instruction)
                .font(.title3.weight(.black))
                .foregroundStyle(MatherTheme.ink)
                .multilineTextAlignment(.center)
            Button("START") { beginWalkPhase() }
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
        .padding(24)
    }

    // MARK: - Compass canvas

    private func compassCanvas(size: CGSize) -> some View {
        let radius = min(size.width, size.height) * 0.38

        return Canvas { ctx, canvasSize in
            let cx = canvasSize.width / 2
            let cy = canvasSize.height / 2

            let ringRect = CGRect(x: cx - radius, y: cy - radius, width: radius * 2, height: radius * 2)
            ctx.stroke(Circle().path(in: ringRect), with: .color(MatherTheme.ink.opacity(0.15)), lineWidth: 2)

            for deg in stride(from: 0.0, to: 360.0, by: 30.0) {
                let isMajor = deg.truncatingRemainder(dividingBy: 90) == 0
                let rad = deg * .pi / 180
                let inner = radius * (isMajor ? 0.82 : 0.88)
                let ix = cx + inner * sin(rad)
                let iy = cy - inner * cos(rad)
                let ox = cx + radius * sin(rad)
                let oy = cy - radius * cos(rad)
                var tick = Path()
                tick.move(to: CGPoint(x: ix, y: iy))
                tick.addLine(to: CGPoint(x: ox, y: oy))
                ctx.stroke(tick, with: .color(MatherTheme.ink.opacity(isMajor ? 0.5 : 0.2)), lineWidth: isMajor ? 2 : 1)
            }

            let targetRad = level.targetDeg * .pi / 180
            var targetArc = Path()
            targetArc.addArc(center: CGPoint(x: cx, y: cy),
                             radius: radius * 0.65,
                             startAngle: .radians(-.pi / 2),
                             endAngle: .radians(-.pi / 2 + targetRad),
                             clockwise: level.targetDeg < 0)
            ctx.stroke(targetArc,
                       with: .color(MatherTheme.softBlue.opacity(phase == .turning || phase == .success ? 0.55 : 0.22)),
                       style: StrokeStyle(lineWidth: 4, lineCap: .round, dash: [8, 6]))

            let tdx = cx + radius * 0.65 * sin(targetRad)
            let tdy = cy - radius * 0.65 * cos(targetRad)
            let tdr: CGFloat = 10
            ctx.fill(Circle().path(in: CGRect(x: tdx - tdr, y: tdy - tdr, width: tdr * 2, height: tdr * 2)),
                     with: .color(MatherTheme.softBlue))

            let yawRad = currentYaw * .pi / 180
            let needleTipX = cx + radius * 0.8 * sin(yawRad)
            let needleTipY = cy - radius * 0.8 * cos(yawRad)
            let tailX = cx - radius * 0.3 * sin(yawRad)
            let tailY = cy + radius * 0.3 * cos(yawRad)
            var needle = Path()
            needle.move(to: CGPoint(x: tailX, y: tailY))
            needle.addLine(to: CGPoint(x: needleTipX, y: needleTipY))
            let needleColor: Color = turnMatched ? MatherTheme.accent : MatherTheme.coral
            ctx.stroke(needle, with: .color(needleColor.opacity(phase == .walking ? 0.35 : 1)), lineWidth: 4)

            let cr: CGFloat = 8
            ctx.fill(Circle().path(in: CGRect(x: cx - cr, y: cy - cr, width: cr * 2, height: cr * 2)), with: .color(MatherTheme.ink))

            let northLabel = ctx.resolve(Text("N").font(.system(size: 16, weight: .bold)).foregroundStyle(MatherTheme.ink.opacity(0.4)))
            ctx.draw(northLabel, at: CGPoint(x: cx, y: cy - radius * 0.92))
        }
    }

    // MARK: - Degree label

    private var degreeLabel: some View {
        VStack(spacing: 4) {
            Text("\(Int(CompassMath.angularDistance(currentYaw, 0).rounded()))°")
                .font(.system(size: 64, weight: .black, design: .rounded))
                .foregroundStyle(turnMatched ? MatherTheme.accent : MatherTheme.ink)
            if turnMatched {
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
        .animation(.spring(response: 0.3), value: turnMatched)
    }

    // MARK: - Bottom bar

    private var bottomBar: some View {
        VStack(spacing: 8) {
            phaseCueCard

            if phase == .success {
                Button(action: advanceLevel) {
                    Text(wonCount >= compassWalkTurnLevels.count ? "All done!" : "Next walk →")
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

            Text("Clear space, small steps, no running")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.tertiary)
                .padding(.bottom, 16)
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: phase)
    }

    private var phaseCueCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                Image(systemName: phaseIcon)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(MatherTheme.softBlue)
                    .frame(width: 34, height: 34)
                    .background(MatherTheme.softBlue.opacity(0.12), in: Circle())

                VStack(alignment: .leading, spacing: 2) {
                    Text(phaseTitle)
                        .font(.subheadline.weight(.black))
                        .foregroundStyle(MatherTheme.ink)
                    Text(phaseSubtitle)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(MatherTheme.cardSubtitle)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 0)
            }

            if phase == .walking {
                stepProgressView
            }
            if phase == .turning, showTurnFallback {
                turnFallbackButton
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(MatherTheme.card.opacity(0.92), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .padding(.horizontal, 24)
    }

    private var turnFallbackButton: some View {
        HStack {
            Text("Sensor unavailable")
                .font(.caption.weight(.semibold))
                .foregroundStyle(MatherTheme.cardSubtitle)
            Spacer()
            Button("I'm facing \(Int(level.targetDeg.magnitude))°") {
                phase = .success
                wonCount += 1
                showTurnFallback = false
                appModel.hapticsService.success(enabled: appModel.featureFlags.hapticsEnabled)
                appModel.speechService.speak(
                    "Great! You walked carefully, then turned \(Int(level.targetDeg.magnitude)) degrees.",
                    enabled: appModel.featureFlags.audioEnabled
                )
            }
            .font(.caption.weight(.black))
            .foregroundStyle(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(MatherTheme.accent, in: Capsule())
        }
    }

    private var stepProgressView: some View {
        VStack(alignment: .leading, spacing: 8) {
            ProgressView(value: stepService.progress.fractionComplete)
                .tint(MatherTheme.accent)
            HStack {
                Text("\(min(stepService.countedSteps, level.steps)) / \(level.steps) small steps")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(MatherTheme.ink)
                Spacer()
                if case .manualFallback(let reason) = stepService.mode {
                    Button("I took a step") {
                        stepService.addManualStep()
                        checkWalkProgress()
                    }
                    .font(.caption.weight(.black))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(MatherTheme.accent, in: Capsule())
                    .accessibilityHint(reason)
                } else {
                    Button("Use tap count") {
                        stepService.useManualFallback()
                    }
                    .font(.caption.weight(.black))
                    .foregroundStyle(MatherTheme.softBlue)
                }
            }
            if case .manualFallback(let reason) = stepService.mode {
                Text(reason)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(MatherTheme.cardSubtitle)
            }
        }
    }

    private var phaseIcon: String {
        switch phase {
        case .ready: "figure.walk"
        case .walking: level.walkDirection.symbol
        case .turning: Self.turnCueSymbol(for: level.targetDeg)
        case .success: "checkmark.circle.fill"
        }
    }

    private var phaseTitle: String {
        switch phase {
        case .ready: "Ready: check your space"
        case .walking: "Step phase"
        case .turning: "Turn phase"
        case .success: "Walk + turn complete!"
        }
    }

    private var phaseSubtitle: String {
        switch phase {
        case .ready: level.instruction
        case .walking: level.walkHint
        case .turning: Self.bodyRelativeHint(for: level.targetDeg)
        case .success: "Nice careful movement."
        }
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
            return "Now turn your body to the right until the red pointer touches the blue dot."
        case .left:
            return "Now turn your body to the left until the red pointer touches the blue dot."
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

    private func beginWalkPhase() {
        phase = .walking
        showDegreeLabel = false
        appModel.motionService.stopRelativeYawTracking()
        stepService.start(requiredSteps: level.steps)
        appModel.speechService.speak(
            "Clear space. Walk \(level.steps) small careful steps \(level.walkDirection.title). No running.",
            enabled: appModel.featureFlags.audioEnabled
        )
    }

    private func checkWalkProgress() {
        guard phase == .walking, stepService.isComplete else { return }
        phase = .turning
        showDegreeLabel = true
        showTurnFallback = false
        stepService.stop()
        appModel.motionService.startRelativeYawTracking()
        appModel.hapticsService.success(enabled: appModel.featureFlags.hapticsEnabled)
        appModel.speechService.speak(level.turnHint, enabled: appModel.featureFlags.audioEnabled)
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(3))
            if phase == .turning, !appModel.motionService.relativeYawResponsive {
                showTurnFallback = true
            }
        }
    }

    private func checkSnap(yaw: Double) {
        guard phase == .turning else { return }
        showDegreeLabel = true
        if CompassMath.isInSnapZone(yaw: yaw, target: level.targetDeg) {
            phase = .success
            wonCount += 1
            appModel.hapticsService.success(enabled: appModel.featureFlags.hapticsEnabled)
            appModel.speechService.speak(
                "Perfect! You walked carefully, then turned \(Int(level.targetDeg.magnitude)) degrees.",
                enabled: appModel.featureFlags.audioEnabled
            )
        }
    }

    private func advanceLevel() {
        if wonCount >= compassWalkTurnLevels.count {
            appModel.engine.showHome()
            return
        }
        levelIndex += 1
        phase = .ready
        showDegreeLabel = false
        showTurnFallback = false
        stepService.stop()
        appModel.motionService.stopRelativeYawTracking()
    }
}
