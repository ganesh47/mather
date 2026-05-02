import SwiftUI

/// Symmetry Fold — children tilt the iPad to fold the right half of a shape
/// onto the left half along a vertical axis of symmetry.
///
/// UX improvements over v1:
///  • Creative bilateral motifs (heart → butterfly → flower → kite → leaf → badge) with
///    progressively reduced guide opacity (0.30 → 0 on final level).
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
    @State private var currentLevel: Int = 1   // 1–6
    /// 0–1 progress filled by holding the shape in the folded zone.
    @State private var holdProgress: Double = 0
    @State private var holdTask: Task<Void, Never>? = nil
    @State private var playMode: PlayMode = .lesson
    @State private var challengeTimeRemaining: Double = Self.challengeDuration
    @State private var sessionStart: Date = .now
    @State private var challengeTask: Task<Void, Never>? = nil
    @State private var challengeTimedOut = false
    @State private var wrongDirectionCue = false
    @State private var lastWrongDirectionPrompt: Date = .distantPast

    // MARK: - Level config

    fileprivate enum Motif: String, CaseIterable {
        case heart
        case butterfly
        case flower
        case kite
        case leaf
        case badge
    }

    private struct LevelConfig {
        let motif: Motif
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

    private let levels: [LevelConfig] = Self.creativeLevels

    private static let creativeLevels: [LevelConfig] = [
        LevelConfig(
            motif: .heart,
            color: MatherTheme.coral,
            guideOpacity: 0.30,
            title: "Fold the heart",
            shapeName: "heart",
            speechPrompt: "Tilt left to fold the heart in half. Make both sides match!"
        ),
        LevelConfig(
            motif: .butterfly,
            color: MatherTheme.warm,
            guideOpacity: 0.26,
            title: "Fold the butterfly",
            shapeName: "butterfly",
            speechPrompt: "Tilt left to close the butterfly wings. Match both sides!"
        ),
        LevelConfig(
            motif: .flower,
            color: MatherTheme.accent,
            guideOpacity: 0.20,
            title: "Fold the flower",
            shapeName: "flower",
            speechPrompt: "Tilt left to fold the flower on its middle line."
        ),
        LevelConfig(
            motif: .kite,
            color: MatherTheme.softBlue,
            guideOpacity: 0.14,
            title: "Fold the kite",
            shapeName: "kite",
            speechPrompt: "Tiny guide now. Tilt left and make the kite halves match."
        ),
        LevelConfig(
            motif: .leaf,
            color: MatherTheme.accent,
            guideOpacity: 0.08,
            title: "Fold the leaf",
            shapeName: "leaf",
            speechPrompt: "Use the center vein as the fold line. Tilt left!"
        ),
        LevelConfig(
            motif: .badge,
            color: MatherTheme.coral,
            guideOpacity: 0.0,
            title: "No guide — fold the badge",
            shapeName: "badge",
            speechPrompt: "No guide! Find the line of symmetry and tilt left."
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
                ? "Keep collecting mirror badges, or try the timer challenge for this shape."
                : "Mirror mission complete. You can finish now, or try one timed challenge."
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
            updateWrongDirectionCue(delta: delta)
            updateHoldProgress(for: newFold)
        }
        .onAppear {
            sessionStart = .now
            appModel.motionService.startUpdates()
        }
        .onDisappear {
            holdTask?.cancel()
            challengeTask?.cancel()
            appModel.motionService.stopUpdates()
            guard currentLevel > 1 else { return }
            appModel.gameSessionStore.save(
                gameName: "Symmetry Fold",
                startedAt: sessionStart,
                scoreValue: currentLevel - 1,
                scoreLabel: "levels"
            )
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
            Button {
                stopAllTasks()
                appModel.motionService.stopUpdates()
                appModel.engine.showHome()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 34, weight: .black))
                    .foregroundStyle(config.color)
                    .frame(width: 56, height: 56)
                    .background(config.color.opacity(0.12), in: Circle())
            }
            .accessibilityLabel("Done")
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
                    SymmetryMotifView(motif: config.motif, color: config.color)
                        .frame(width: size, height: size)
                        .shadow(color: config.color.opacity(0.35), radius: 18)
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
        SymmetryMotifView(motif: config.motif, color: config.color.opacity(config.guideOpacity))
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
            let isTeachingMoment = foldAngle >= 0.72 || success
            ctx.stroke(
                path,
                with: .color((isTeachingMoment ? config.color : MatherTheme.ink).opacity(isTeachingMoment ? 0.62 : 0.3)),
                style: StrokeStyle(lineWidth: isTeachingMoment ? 3 : 2, lineCap: .round)
            )
        }
        .frame(width: size, height: size)
    }

    private func foldableRightHalf(size: CGFloat) -> some View {
        SymmetryMotifView(motif: config.motif, color: config.color)
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
            Text("Line of symmetry: both sides match.")
                .font(.headline.weight(.black))
                .foregroundStyle(MatherTheme.ink)
                .multilineTextAlignment(.center)
            Text("Mirror badge earned: \(config.shapeName.capitalized) ✨")
                .font(.headline.weight(.black))
                .foregroundStyle(config.color)
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
                    } else if wrongDirectionCue {
                        Text(Self.wrongDirectionHint)
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(MatherTheme.danger)
                    } else if foldAngle >= 0.72 {
                        Text(Self.nearMatchHint)
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(config.color)
                    } else if playMode == .timedChallenge {
                        Text(Self.challengeCountdownText(for: challengeTimeRemaining))
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(config.color)
                    } else {
                        Text("Tilt left to match the mirror")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(MatherTheme.cardSubtitle)
                    }
                }
                .animation(.easeInOut(duration: 0.2), value: holdProgress > 0)
                .animation(.easeInOut(duration: 0.2), value: wrongDirectionCue)
            }

            Text(Self.mirrorMissionLabel(currentLevel: currentLevel, totalLevels: levels.count))
                .font(.caption.weight(.black))
                .foregroundStyle(config.color)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(config.color.opacity(0.12), in: Capsule())

            // Level progress dots — active dot is slightly larger
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

    private func updateWrongDirectionCue(delta: Double) {
        guard delta > 0.12, foldAngle < 0.08 else {
            wrongDirectionCue = false
            return
        }

        wrongDirectionCue = true
        if Date().timeIntervalSince(lastWrongDirectionPrompt) >= 3.0 {
            lastWrongDirectionPrompt = .now
            appModel.speechService.speak(
                Self.wrongDirectionSpeech(for: config.shapeName),
                enabled: appModel.featureFlags.audioEnabled
            )
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
        wrongDirectionCue = false
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
        "Perfectly folded! The line of symmetry makes both sides of the \(shapeName) match."
    }

    nonisolated static var nearMatchHint: String {
        "Almost there — line up both halves"
    }

    nonisolated static var wrongDirectionHint: String {
        "Other way — tilt left"
    }

    nonisolated static func wrongDirectionSpeech(for shapeName: String) -> String {
        "Try the other way. Tilt left to fold the \(shapeName)."
    }

    nonisolated static let creativeLevelNames = ["heart", "butterfly", "flower", "kite", "leaf", "badge"]

    nonisolated static func mirrorMissionLabel(currentLevel: Int, totalLevels: Int) -> String {
        let collected = max(0, min(currentLevel - 1, totalLevels))
        return "Mirror mission • \(collected)/\(totalLevels) badges"
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


private struct SymmetryMotifView: View {
    let motif: SymmetryFoldView.Motif
    let color: Color

    var body: some View {
        ZStack {
            switch motif {
            case .heart:
                Image(systemName: "heart.fill")
                    .resizable()
                    .scaledToFit()
                    .foregroundStyle(color)
                    .padding(8)
            case .butterfly:
                butterfly
            case .flower:
                flower
            case .kite:
                kite
            case .leaf:
                leaf
            case .badge:
                badge
            }
        }
        .accessibilityHidden(true)
    }

    private var butterfly: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            ZStack {
                Capsule()
                    .fill(color.opacity(0.95))
                    .frame(width: w * 0.12, height: h * 0.62)
                wing(x: -w * 0.18, y: -h * 0.11, rotation: -26, width: w * 0.36, height: h * 0.38)
                wing(x: -w * 0.18, y: h * 0.16, rotation: 24, width: w * 0.32, height: h * 0.30)
                wing(x: w * 0.18, y: -h * 0.11, rotation: 26, width: w * 0.36, height: h * 0.38)
                wing(x: w * 0.18, y: h * 0.16, rotation: -24, width: w * 0.32, height: h * 0.30)
                Circle().fill(.white.opacity(0.58)).frame(width: w * 0.07, height: w * 0.07).offset(x: -w * 0.22, y: -h * 0.11)
                Circle().fill(.white.opacity(0.58)).frame(width: w * 0.07, height: w * 0.07).offset(x: w * 0.22, y: -h * 0.11)
            }
            .frame(width: w, height: h)
        }
    }

    private func wing(x: CGFloat, y: CGFloat, rotation: Double, width: CGFloat, height: CGFloat) -> some View {
        Ellipse()
            .fill(color)
            .frame(width: width, height: height)
            .rotationEffect(.degrees(rotation))
            .offset(x: x, y: y)
    }

    private var flower: some View {
        GeometryReader { geo in
            let side = min(geo.size.width, geo.size.height)
            ZStack {
                ForEach(0..<8, id: \.self) { index in
                    Capsule()
                        .fill(color.opacity(index.isMultiple(of: 2) ? 0.95 : 0.72))
                        .frame(width: side * 0.18, height: side * 0.42)
                        .offset(y: -side * 0.22)
                        .rotationEffect(.degrees(Double(index) * 45))
                }
                Circle()
                    .fill(MatherTheme.warm)
                    .frame(width: side * 0.25, height: side * 0.25)
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
    }

    private var kite: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            ZStack {
                DiamondShape()
                    .fill(color)
                    .frame(width: w * 0.62, height: h * 0.76)
                Path { path in
                    path.move(to: CGPoint(x: w / 2, y: h * 0.12))
                    path.addLine(to: CGPoint(x: w / 2, y: h * 0.88))
                    path.move(to: CGPoint(x: w * 0.19, y: h * 0.5))
                    path.addLine(to: CGPoint(x: w * 0.81, y: h * 0.5))
                }
                .stroke(.white.opacity(0.55), style: StrokeStyle(lineWidth: max(3, w * 0.025), lineCap: .round))
                Circle().fill(.white.opacity(0.5)).frame(width: w * 0.12, height: w * 0.12)
            }
        }
    }

    private var leaf: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            ZStack {
                LeafShape()
                    .fill(color)
                    .frame(width: w * 0.58, height: h * 0.82)
                Capsule()
                    .fill(.white.opacity(0.55))
                    .frame(width: max(4, w * 0.025), height: h * 0.65)
                ForEach([-1.0, 1.0], id: \.self) { side in
                    ForEach(0..<3, id: \.self) { index in
                        Capsule()
                            .fill(.white.opacity(0.38))
                            .frame(width: w * 0.18, height: max(3, h * 0.018))
                            .rotationEffect(.degrees(side * Double(index == 0 ? 32 : index == 1 ? 18 : -8)))
                            .offset(x: side * w * 0.09, y: CGFloat(index - 1) * h * 0.14)
                    }
                }
            }
        }
    }

    private var badge: some View {
        GeometryReader { geo in
            let side = min(geo.size.width, geo.size.height)
            ZStack {
                Circle()
                    .fill(color)
                    .frame(width: side * 0.72, height: side * 0.72)
                Circle()
                    .stroke(.white.opacity(0.55), lineWidth: side * 0.045)
                    .frame(width: side * 0.52, height: side * 0.52)
                Image(systemName: "sparkles")
                    .resizable()
                    .scaledToFit()
                    .foregroundStyle(.white.opacity(0.72))
                    .frame(width: side * 0.28, height: side * 0.28)
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
    }
}

private struct DiamondShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.midY))
        path.closeSubpath()
        return path
    }
}

private struct LeafShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addCurve(
            to: CGPoint(x: rect.midX, y: rect.maxY),
            control1: CGPoint(x: rect.maxX, y: rect.minY + rect.height * 0.18),
            control2: CGPoint(x: rect.maxX, y: rect.minY + rect.height * 0.72)
        )
        path.addCurve(
            to: CGPoint(x: rect.midX, y: rect.minY),
            control1: CGPoint(x: rect.minX, y: rect.minY + rect.height * 0.72),
            control2: CGPoint(x: rect.minX, y: rect.minY + rect.height * 0.18)
        )
        return path
    }
}
