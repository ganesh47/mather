import SwiftUI

/// Symmetry Fold — children tilt the iPad to fold the right half of a shape
/// onto the left half along a vertical axis of symmetry.
///
/// When both halves overlap perfectly the shape "snaps" closed and the child
/// discovers that the two halves are mirror images — the definition of
/// reflective symmetry.
///
/// Age range: 5–7. CPA level: Pictorial → Abstract.
/// Sensor: neutral-relative roll tilt (left tilt folds right half onto left).
/// Three levels of increasing abstraction:
///   1. Heart with fold guide (dashed left-half ghost)
///   2. Star with lighter fold guide
///   3. Hexagon shape, no guide
struct SymmetryFoldView: View {

    @Bindable var appModel: AppModel

    // MARK: - Local state

    /// Roll value at the moment the child taps "ready". All subsequent tilt
    /// is computed as a delta from this neutral, matching the Gravity Split
    /// neutral-relative pattern to prevent accidental solves.
    @State private var neutralRoll: Double? = nil
    /// 0 = shape is fully open; 1 = right half is folded flat onto left half.
    @State private var foldAngle: Double = 0
    @State private var success = false
    @State private var currentLevel: Int = 1   // 1, 2, 3

    // MARK: - Level config

    private struct LevelConfig {
        let symbolName: String
        let color: Color
        let showGuide: Bool
        let title: String
        let accessibilityLabel: String
    }

    private let levels: [LevelConfig] = [
        LevelConfig(
            symbolName: "heart.fill",
            color: MatherTheme.coral,
            showGuide: true,
            title: "Fold the heart",
            accessibilityLabel: "Heart shape. Tilt left to fold."
        ),
        LevelConfig(
            symbolName: "star.fill",
            color: MatherTheme.warm,
            showGuide: true,
            title: "Fold the star",
            accessibilityLabel: "Star shape. Tilt left to fold."
        ),
        LevelConfig(
            symbolName: "hexagon.fill",
            color: MatherTheme.accent,
            showGuide: false,
            title: "Fold it!",
            accessibilityLabel: "Hexagon shape. Tilt left to fold."
        ),
    ]

    private var config: LevelConfig {
        levels[min(currentLevel - 1, levels.count - 1)]
    }

    // MARK: - Constants

    /// Full 45° tilt maps to fully folded.
    private let maxTiltRadians: Double = .pi / 4

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
            // Left tilt → roll decreases from neutral → negative delta → foldAngle increases.
            let delta = roll - neutral
            foldAngle = max(0.0, min(-delta / maxTiltRadians, 1.0))
            if foldAngle >= 0.95 {
                handleSuccess()
            }
        }
        .onAppear {
            appModel.motionService.startUpdates()
        }
        .onDisappear {
            appModel.motionService.stopUpdates()
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel(config.accessibilityLabel)
    }

    // MARK: - Header

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Symmetry Fold")
                    .font(.title2.weight(.black))
                    .foregroundStyle(MatherTheme.ink)
                Text(config.title)
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
            .accessibilityIdentifier("symmetry-fold-done-button")
        }
    }

    // MARK: - Fold scene

    private var foldScene: some View {
        GeometryReader { geo in
            let size = min(geo.size.width * 0.8, geo.size.height * 0.8, 280.0)
            ZStack {
                // Ghost left-half (visible guide only on levels 1 and 2)
                if config.showGuide {
                    ghostHalf(size: size)
                }

                // Dashed vertical fold line
                foldLine(size: size)

                // Foldable right half
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

                // Success overlay
                if success {
                    successOverlay(size: size)
                        .transition(.scale(scale: 0.7).combined(with: .opacity))
                }

                // "Tap to start" prompt
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
                if neutralRoll == nil && !success {
                    withAnimation(.easeOut(duration: 0.15)) {
                        neutralRoll = appModel.motionService.tiltRoll
                    }
                } else if success {
                    advanceLevel()
                }
            }
            .accessibilityIdentifier("symmetry-fold-scene")
        }
        .frame(maxWidth: .infinity)
        .frame(height: 300)
    }

    private func ghostHalf(size: CGFloat) -> some View {
        Image(systemName: config.symbolName)
            .resizable()
            .scaledToFit()
            .foregroundStyle(config.color.opacity(0.18))
            .frame(width: size, height: size)
            // Mask: show only the left half
            .mask(
                HStack(spacing: 0) {
                    Color.black.frame(width: size / 2)
                    Color.clear.frame(width: size / 2)
                }
            )
    }

    private func foldLine(size: CGFloat) -> some View {
        // Dashed vertical line
        Canvas { ctx, canvasSize in
            var path = Path()
            var y: CGFloat = 0
            let x = canvasSize.width / 2
            while y < canvasSize.height {
                path.move(to: CGPoint(x: x, y: y))
                path.addLine(to: CGPoint(x: x, y: min(y + 10, canvasSize.height)))
                y += 18
            }
            ctx.stroke(path, with: .color(MatherTheme.ink.opacity(0.3)),
                       style: StrokeStyle(lineWidth: 2, lineCap: .round))
        }
        .frame(width: size, height: size)
    }

    private func foldableRightHalf(size: CGFloat) -> some View {
        Image(systemName: config.symbolName)
            .resizable()
            .scaledToFit()
            .foregroundStyle(success ? MatherTheme.accent : config.color)
            .frame(width: size, height: size)
            // Mask: show only the right half
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
                .frame(width: size * 0.7, height: 110)
            VStack(spacing: 8) {
                Image(systemName: "hand.tap.fill")
                    .font(.system(size: 28))
                    .foregroundStyle(config.color)
                Text("Tap to start")
                    .font(.headline.weight(.bold))
                    .foregroundStyle(MatherTheme.ink)
                Text("Then tilt left to fold")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(MatherTheme.cardSubtitle)
            }
        }
    }

    private func successOverlay(size: CGFloat) -> some View {
        VStack(spacing: 6) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 56))
                .foregroundStyle(MatherTheme.accent)
            Text("Symmetric!")
                .font(.title2.weight(.black))
                .foregroundStyle(MatherTheme.accent)
            if currentLevel < 3 {
                Text("Tap for the next shape")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(MatherTheme.cardSubtitle)
            } else {
                Text("All done! Tap to finish.")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(MatherTheme.cardSubtitle)
            }
        }
        .padding(20)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    // MARK: - Bottom bar

    private var bottomBar: some View {
        VStack(spacing: 12) {
            if !success && neutralRoll != nil {
                HStack(spacing: 8) {
                    Image(systemName: "gyroscope")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(config.color.opacity(0.8))
                    Text("Tilt left to fold")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(MatherTheme.cardSubtitle)
                }
            }

            // Level progress dots
            HStack(spacing: 8) {
                ForEach(1...3, id: \.self) { lvl in
                    Circle()
                        .fill(lvl <= currentLevel
                              ? config.color
                              : config.color.opacity(0.2))
                        .frame(width: 10, height: 10)
                        .animation(.easeInOut(duration: 0.25), value: currentLevel)
                }
            }
        }
    }

    // MARK: - Actions

    private func handleSuccess() {
        success = true
        appModel.hapticsService.balanceLock(enabled: appModel.featureFlags.hapticsEnabled)
        appModel.speechService.speak(
            "Perfectly folded! Both sides match — it's symmetric!",
            enabled: appModel.featureFlags.audioEnabled
        )
    }

    private func advanceLevel() {
        if currentLevel < 3 {
            currentLevel += 1
            foldAngle = 0
            success = false
            neutralRoll = nil
        } else {
            appModel.engine.showHome()
        }
    }
}
