import SwiftUI

/// Symmetry Fold — children tilt the iPad to fold the right half of a shape
/// onto the left half along a vertical axis of symmetry.
///
/// UX improvements over v1:
///  • 5 shapes (heart → star → hexagon → diamond → triangle) with
///    progressively reduced guide opacity (0.28 → 0 on final level).
///  • Hold-to-lock mechanic: child must hold ≥ 0.85 fold for 0.8 s — shown
///    as a circular progress ring.  Prevents accidental solves and creates
///    a satisfying "snap" moment.
///  • Bilateral success: full shape glows on lock, not just the right half.
///  • Level progress dots size-animate to show the active level clearly.
///  • Optional timed challenge unlocked after each normal success, while the
///    default lesson flow stays unchanged.
///
/// Age range: 5–7. CPA level: Pictorial → Abstract.
/// Sensor: neutral-relative roll tilt (left tilt folds right half onto left).
struct SymmetryFoldView: View {

    @Bindable var appModel: AppModel

    // MARK: - Local state

    @State private var neutralRoll: Double? = nil
    /// 0 = shape open; 1 = right half fully folded onto left.
    @State private var foldAngle: Double = 0
    @State private var success = false
    @State private var currentLevel: Int = 1   // 1–5
    /// 0–1 progress filled by holding the shape in the folded zone.
    @State private var holdProgress: Double = 0
    @State private var holdTask: Task<Void, Never>? = nil
    @State private var playMode: PlayMode = .lesson
    @State private var challengeTimeRemaining: Double = Self.challengeDuration
    @State private var challengeTask: Task<Void, Never>? = nil
    @State private var challengeTimedOut = false

    // MARK: - Level config

    private struct LevelConfig {
        let symbolName: String
        let color: Color
        let guideOpacity: Double
        let title: String
        let shapeName: String
        let speechPrompt: String
    }

    private enum PlayMode {
        case lesson
        case timedChallenge
    }

    private let levels: [LevelConfig] = [
        LevelConfig(
            symbolName: "heart.fill",
            color: MatherTheme.coral,
            guideOpacity: 0.28,
            title: "Fold the heart",
            shapeName: "heart",
            speechPrompt: "Tilt left to fold the heart in half!"
        ),
        LevelConfig(
            symbolName: "star.fill",
            color: MatherTheme.warm,
            guideOpacity: 0.28,
            title: "Fold the star",
            shapeName: "star",
            speechPrompt: "Tilt left to fold the star!"
        ),
        LevelConfig(
            symbolName: "hexagon.fill",
            color: MatherTheme.accent,
            guideOpacity: 0.18,
            title: "Fold the hexagon",
            shapeName: "hexagon",
            speechPrompt: "Tilt left to fold the hexagon. Lighter guide this time!"
        ),
        LevelConfig(
            symbolName: "diamond.fill",
            color: MatherTheme.softBlue,
            guideOpacity: 0.10,
            title: "Fold the diamond",
            shapeName: "diamond",
            speechPrompt: "Tiny guide now — use what you remember!"
        ),
        LevelConfig(
            symbolName: "triangle.fill",
            color: MatherTheme.warm,
            guideOpacity: 0.0,
            title: "No guide — you've got this!",
            shapeName: "triangle",
            speechPrompt: "No guide! You know where the fold goes. Tilt left!"
        ),
    ]

    private var config: LevelConfig {
        levels[min(currentLevel - 1, levels.count - 1)]
    }

    private var challengeLabelText: String {
        if neutralRoll == nil {
            return challengeTimedOut
                ? "Timed challenge • tap to retry"
                : "Timed challenge • tap when ready"
        }
        return "Timed challenge • \(Self.challengeCountdownText(for: challengeTimeRemaining))"
    }

    private var primarySuccessActionTitle: String {
        currentLevel < levels.count ? "Next shape" : "Finish"
    }

    private var successBodyText: String {
        switch playMode {
        case .lesson:
            return currentLevel < levels.count
                ? "Keep the lesson going, or try a timed challenge for this shape."
                : "Lesson complete. You can finish now, or try one timed challenge."
        case .timedChallenge:
            return currentLevel < levels.count
                ? "Timed challenge cleared. Ready for the next shape?"
                : "Timed challenge cleared. All done!"
        }
    }

    // MARK: - Constants

    private let maxTiltRadians: Double = .pi / 4
    private static let holdDuration: Double = 0.8
    private static let challengeDuration: Double = 8.0

    // MARK: - Body

    var body: some View {
        ZStack {
            MatherTheme.background.ignoresSafeArea()
            VStack(spacing: 0) {
                header
                    .padding(.horizontal, 24)
                    .padding(.top, 16)

                Spacer()

                foldScene
                    .padding(.horizontal, 24)

                Spacer()

                bottomBar
                    .padding(.horizontal, 24)
                    .padding(.bottom, 20)
            }
        }
        .onChange(of: appModel.motionService.tiltRoll) { _, roll in
            guard let neutral = neutralRoll, !success else { return }
            let delta = roll - neutral
            let newFold = max(0.0, min(-delta / maxTiltRadians, 1.0))
            foldAngle = newFold
            updateHoldProgress(for: newFold)
        }
        .onAppear {
            appModel.motionService.startUpdates()
        }
        .onDisappear {
            holdTask?.cancel()
            challengeTask?.cancel()
            appModel.motionService.stopUpdates()
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel(config.title)
    }

    // MARK: - Header

    private var header: some View {
        HStack(alignment: .top, spacing: 16) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Symmetry Fold")
                    .font(.title2.weight(.black))
                    .foregroundStyle(MatherTheme.ink)
                Text(config.title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(MatherTheme.cardSubtitle)
                if playMode == .timedChallenge {
                    Text(challengeLabelText)
                        .font(.caption.weight(.bold))
                        .foregroundStyle(config.color)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(config.color.opacity(0.12), in: Capsule())
                }
            }
            Spacer(minLength: 12)
            Button("Done") {
                stopAllTasks()
                appModel.motionService.stopUpdates()
                appModel.engine.showHome()
            }
            .font(.headline.weight(.semibold))
            .foregroundStyle(.white)
            .frame(minWidth: 88, minHeight: 44)
            .background(
                MatherTheme.ink.opacity(0.65),
                in: RoundedRectangle(cornerRadius: 12, style: .continuous)
            )
            .accessibilityIdentifier("symmetry-fold-done-button")
        }
    }

    // MARK: - Fold scene

    private var foldScene: some View {
        GeometryReader { geo in
            let size = min(geo.size.width * 0.8, geo.size.height * 0.8, 280.0)
            ZStack {
                // Ghost left-half guide (fades with each level)
                if config.guideOpacity > 0 {
                    ghostHalf(size: size)
                }

                // Dashed fold line
                foldLine(size: size)

                // Foldable right half — 3D-rotates as child tilts
                foldableRightHalf(size: size)
                    .rotation3DEffect(
                        .degrees(foldAngle * -180),
                        axis: (x: 0, y: 1, z: 0),
                        anchor: UnitPoint(x: 0.5, y: 0.5),
                        perspective: 0.35
                    )
                    .animation(
                        .interpolatingSpring(stiffness: 200, damping: 24),
                        value: foldAngle
                    )

                // Hold-to-lock circular progress ring
                if holdProgress > 0 && !success {
                    Circle()
                        .trim(from: 0, to: holdProgress)
                        .stroke(
                            config.color,
                            style: StrokeStyle(lineWidth: 7, lineCap: .round)
                        )
                        .frame(width: size + 28, height: size + 28)
                        .rotationEffect(.degrees(-90))
                        .animation(.linear(duration: 0.05), value: holdProgress)
                }

                // Success: bilateral flash — full shape glows
                if success {
                    Image(systemName: config.symbolName)
                        .resizable()
                        .scaledToFit()
                        .foregroundStyle(config.color)
                        .frame(width: size, height: size)
                        .transition(.scale(scale: 0.7).combined(with: .opacity))
                }

                // Success overlay card
                if success {
                    successOverlay
                        .transition(.scale(scale: 0.85).combined(with: .opacity))
                        .zIndex(10)
                }

                // Tap-to-start prompt
                if neutralRoll == nil && !success {
                    tapPrompt(size: size)
                        .transition(.opacity)
                }
            }
            .animation(.easeOut(duration: 0.2), value: neutralRoll != nil)
            .animation(.spring(response: 0.4, dampingFraction: 0.55), value: success)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .contentShape(Rectangle())
            .onTapGesture {
                handleSceneTap()
            }
            .accessibilityIdentifier("symmetry-fold-scene")
        }
        .frame(maxWidth: .infinity)
        .frame(height: 320)
    }

    // MARK: - Scene sub-views

    private func ghostHalf(size: CGFloat) -> some View {
        Image(systemName: config.symbolName)
            .resizable()
            .scaledToFit()
            .foregroundStyle(config.color.opacity(config.guideOpacity))
            .frame(width: size, height: size)
            .mask(
                HStack(spacing: 0) {
                    Color.black.frame(width: size / 2)
                    Color.clear.frame(width: size / 2)
                }
            )
    }

    private func foldLine(size: CGFloat) -> some View {
        Canvas { ctx, canvasSize in
            var path = Path()
            var y: CGFloat = 0
            let x = canvasSize.width / 2
            while y < canvasSize.height {
                path.move(to: CGPoint(x: x, y: y))
                path.addLine(to: CGPoint(x: x, y: min(y + 10, canvasSize.height)))
                y += 18
            }
            ctx.stroke(
                path,
                with: .color(MatherTheme.ink.opacity(0.3)),
                style: StrokeStyle(lineWidth: 2, lineCap: .round)
            )
        }
        .frame(width: size, height: size)
    }

    private func foldableRightHalf(size: CGFloat) -> some View {
        Image(systemName: config.symbolName)
            .resizable()
            .scaledToFit()
            .foregroundStyle(config.color)
            .frame(width: size, height: size)
            .mask(
                HStack(spacing: 0) {
                    Color.clear.frame(width: size / 2)
                    Color.black.frame(width: size / 2)
                }
            )
    }

    private func tapPrompt(size: CGFloat) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.ultraThinMaterial)
                .frame(width: size * 0.72, height: 122)
            VStack(spacing: 8) {
                Image(systemName: playMode == .timedChallenge ? "timer" : "hand.tap.fill")
                    .font(.system(size: 28))
                    .foregroundStyle(config.color)
                Text(Self.tapPromptTitle(isTimedChallenge: playMode == .timedChallenge, didTimeout: challengeTimedOut))
                    .font(.headline.weight(.bold))
                    .foregroundStyle(MatherTheme.ink)
                Text(Self.tapPromptMessage(isTimedChallenge: playMode == .timedChallenge, didTimeout: challengeTimedOut))
                    .font(.subheadline.weight(.semibold))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(MatherTheme.cardSubtitle)
                    .padding(.horizontal, 12)
            }
        }
    }

    private var successOverlay: some View {
        VStack(spacing: 12) {
            Text(playMode == .timedChallenge ? "⏱️✨" : "✨")
                .font(.system(size: 44))
            Text(playMode == .timedChallenge ? "Timed challenge cleared!" : Self.successTitle(for: config.shapeName))
                .font(.title2.weight(.black))
                .foregroundStyle(MatherTheme.accent)
                .multilineTextAlignment(.center)
            Text(successBodyText)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(MatherTheme.cardSubtitle)
                .multilineTextAlignment(.center)
            VStack(spacing: 10) {
                overlayButton(title: primarySuccessActionTitle, fill: MatherTheme.accent, foreground: .white) {
                    advanceLevel()
                }
                if playMode == .lesson {
                    overlayButton(title: "Try timed challenge", fill: config.color.opacity(0.14), foreground: MatherTheme.ink) {
                        startTimedChallenge()
                    }
                }
            }
            .padding(.top, 4)
        }
        .padding(24)
        .frame(maxWidth: 320)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private func overlayButton(title: String, fill: Color, foreground: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.headline.weight(.bold))
                .foregroundStyle(foreground)
                .frame(maxWidth: .infinity, minHeight: 52)
                .background(fill, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Bottom bar

    private var bottomBar: some View {
        VStack(spacing: 12) {
            // Contextual tilt hint
            if !success && neutralRoll != nil {
                HStack(spacing: 8) {
                    Image(systemName: playMode == .timedChallenge ? "timer" : "gyroscope")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(config.color.opacity(0.8))
                    if holdProgress > 0 {
                        Text("Hold steady…")
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(config.color)
                    } else if playMode == .timedChallenge {
                        Text(Self.challengeCountdownText(for: challengeTimeRemaining))
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(config.color)
                    } else {
                        Text("Tilt left to fold")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(MatherTheme.cardSubtitle)
                    }
                }
                .animation(.easeInOut(duration: 0.2), value: holdProgress > 0)
            }

            // Level progress dots (5) — active dot is slightly larger
            HStack(spacing: 8) {
                ForEach(1...levels.count, id: \.self) { lvl in
                    let isActive = lvl == currentLevel
                    let isPast   = lvl < currentLevel
                    Circle()
                        .fill(
                            isPast   ? MatherTheme.accent :
                            isActive ? config.color :
                            config.color.opacity(0.2)
                        )
                        .frame(
                            width:  isActive ? 13 : 10,
                            height: isActive ? 13 : 10
                        )
                        .animation(
                            .spring(response: 0.3, dampingFraction: 0.6),
                            value: currentLevel
                        )
                }
            }
        }
    }

    // MARK: - Hold-to-lock

    private func updateHoldProgress(for fold: Double) {
        if fold >= 0.85 && !success {
            // Start hold timer if not already running
            if holdTask == nil {
                let startDate = Date()
                holdTask = Task { @MainActor in
                    while !Task.isCancelled && !success {
                        let elapsed = Date().timeIntervalSince(startDate)
                        holdProgress = min(elapsed / Self.holdDuration, 1.0)
                        if holdProgress >= 1.0 {
                            handleSuccess()
                            break
                        }
                        try? await Task.sleep(nanoseconds: 16_000_000)   // ~60 fps
                    }
                }
            }
        } else {
            // Fold dropped — cancel and reset ring
            holdTask?.cancel()
            holdTask = nil
            holdProgress = 0
        }
    }

    // MARK: - Actions

    private func handleSceneTap() {
        guard neutralRoll == nil, !success else { return }
        withAnimation(.easeOut(duration: 0.15)) {
            neutralRoll = appModel.motionService.tiltRoll
        }
        challengeTimedOut = false
        if playMode == .timedChallenge {
            startChallengeTimer()
        }
        appModel.speechService.speak(
            currentSpeechPrompt,
            enabled: appModel.featureFlags.audioEnabled
        )
    }

    private var currentSpeechPrompt: String {
        switch playMode {
        case .lesson:
            return config.speechPrompt
        case .timedChallenge:
            return "Timed challenge. Tap when ready, then tilt left to fold the \(config.shapeName) before the timer ends!"
        }
    }

    private func handleSuccess() {
        success = true
        holdTask?.cancel()
        holdTask = nil
        challengeTask?.cancel()
        challengeTask = nil
        holdProgress = 0
        challengeTimedOut = false
        appModel.hapticsService.balanceLock(enabled: appModel.featureFlags.hapticsEnabled)
        appModel.speechService.speak(
            playMode == .timedChallenge
                ? "You beat the timer and folded the \(config.shapeName)!"
                : Self.successSpeech(for: config.shapeName),
            enabled: appModel.featureFlags.audioEnabled
        )
    }

    private func startTimedChallenge() {
        playMode = .timedChallenge
        resetAttemptForCurrentMode()
        appModel.speechService.speak(
            "Timed challenge unlocked. Tap when you are ready to start the timer.",
            enabled: appModel.featureFlags.audioEnabled
        )
    }

    private func startChallengeTimer() {
        challengeTask?.cancel()
        challengeTimeRemaining = Self.challengeDuration
        let deadline = Date().addingTimeInterval(Self.challengeDuration)
        challengeTask = Task { @MainActor in
            while !Task.isCancelled && !success && neutralRoll != nil {
                let remaining = max(0, deadline.timeIntervalSinceNow)
                challengeTimeRemaining = remaining
                if remaining <= 0 {
                    handleChallengeTimeout()
                    break
                }
                try? await Task.sleep(nanoseconds: 50_000_000)
            }
        }
    }

    private func handleChallengeTimeout() {
        guard playMode == .timedChallenge else { return }
        appModel.speechService.speak(
            "Time's up. Tap to try that timed challenge again.",
            enabled: appModel.featureFlags.audioEnabled
        )
        resetAttemptForCurrentMode(markTimedOut: true)
    }

    private func resetAttemptForCurrentMode(markTimedOut: Bool = false) {
        holdTask?.cancel()
        holdTask = nil
        challengeTask?.cancel()
        challengeTask = nil
        foldAngle = 0
        success = false
        neutralRoll = nil
        holdProgress = 0
        challengeTimedOut = markTimedOut
        challengeTimeRemaining = markTimedOut ? 0 : Self.challengeDuration
    }

    private func stopAllTasks() {
        holdTask?.cancel()
        holdTask = nil
        challengeTask?.cancel()
        challengeTask = nil
    }

    nonisolated static func successTitle(for shapeName: String) -> String {
        "\(shapeName.capitalized) is symmetric!"
    }

    nonisolated static func successSpeech(for shapeName: String) -> String {
        "Perfectly folded! You made a symmetric \(shapeName)."
    }

    nonisolated static func challengeCountdownText(for secondsRemaining: Double) -> String {
        "\(max(0, Int(ceil(secondsRemaining))))s left"
    }

    nonisolated static func tapPromptTitle(isTimedChallenge: Bool, didTimeout: Bool) -> String {
        guard isTimedChallenge else { return "Tap to start" }
        return didTimeout ? "Time's up" : "Start timed challenge"
    }

    nonisolated static func tapPromptMessage(isTimedChallenge: Bool, didTimeout: Bool) -> String {
        guard isTimedChallenge else { return "Then tilt left to fold" }
        return didTimeout
            ? "Tap to retry this shape with a fresh timer"
            : "Tap when ready. The timer starts after your tap."
    }

    private func advanceLevel() {
        playMode = .lesson
        stopAllTasks()
        if currentLevel < levels.count {
            currentLevel += 1
            resetAttemptForCurrentMode()
        } else {
            appModel.engine.showHome()
        }
    }
}
