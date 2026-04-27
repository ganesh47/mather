import SwiftUI

struct SumSprintSessionView: View {
    @Bindable var appModel: AppModel
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    private var engine: SumSprintEngine { appModel.sumSprintEngine }

    var body: some View {
        ZStack {
            MatherTheme.background.ignoresSafeArea()

            VStack(spacing: 0) {
                header
                    .padding(.horizontal, ResponsiveLayout.contentPadding(for: horizontalSizeClass))
                    .padding(.top, 12)
                    .frame(maxWidth: ResponsiveLayout.sumSprintSessionMaxWidth(for: horizontalSizeClass))
                    .frame(maxWidth: .infinity)

                ScrollView {
                    VStack(spacing: 20) {
                        if let card = engine.cards.indices.contains(engine.currentCardIndex)
                            ? engine.cards[engine.currentCardIndex] : nil {
                            FlashCardView(
                                card: card,
                                onAppend: { engine.appendDigit($0) },
                                onDelete: { engine.deleteLastDigit() },
                                onSubmit: { engine.submitAnswer() }
                            )
                            .padding(.horizontal, 20)
                            .frame(maxWidth: ResponsiveLayout.sumSprintSessionMaxWidth(for: horizontalSizeClass))
                            .frame(maxWidth: .infinity)
                            .transition(.asymmetric(
                                insertion: .move(edge: .trailing).combined(with: .opacity),
                                removal: .move(edge: .leading).combined(with: .opacity)
                            ))
                            .id(engine.currentCardIndex)
                        }
                    }
                    .frame(maxWidth: ResponsiveLayout.sumSprintSessionMaxWidth(for: horizontalSizeClass))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                }
            }

            // Countdown ring — top-right corner, only when timed mode active
            if engine.difficulty != .relaxed {
                VStack {
                    HStack {
                        Spacer()
                        countdownRing
                            .padding(.top, 12)
                            .padding(.trailing, ResponsiveLayout.contentPadding(for: horizontalSizeClass))
                    }
                    Spacer()
                }
                .allowsHitTesting(false)
            }

            // Correct feedback overlay
            if engine.showCorrectFeedback {
                feedbackOverlay(symbol: "✓", color: MatherTheme.accent)
            }

            // Incorrect feedback overlay
            if engine.showIncorrectFeedback {
                feedbackOverlay(symbol: "✗", color: MatherTheme.danger)
            }

            // Timeout feedback overlay
            if engine.showTimeoutFeedback {
                feedbackOverlay(symbol: "⏰", color: MatherTheme.warm)
            }
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: engine.currentCardIndex)
    }

    // MARK: - Header

    private var header: some View {
        VStack(spacing: 8) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(engine.progressLabel)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(MatherTheme.ink.opacity(0.6))

                    if engine.currentStreak > 0 {
                        Text("\(engine.currentStreak) in a row!")
                            .font(.headline.weight(.black))
                            .foregroundStyle(MatherTheme.accent)
                            .transition(.scale.combined(with: .opacity))
                    }
                }
                Spacer()
                // Space reserved for countdown ring in timed modes
                if engine.difficulty != .relaxed {
                    Color.clear.frame(width: 64, height: 1)
                }
                Button {
                    engine.exitToHome()
                } label: {
                    Image(systemName: "house.fill")
                        .font(.title3)
                        .foregroundStyle(MatherTheme.ink.opacity(0.55))
                        .frame(width: 44, height: 44)
                }
                .accessibilityLabel("Go home")
            }

            ProgressView(value: Double(engine.currentCardIndex), total: Double(max(engine.cards.count, 1)))
                .tint(MatherTheme.accent)
                .frame(maxWidth: .infinity)
        }
        .animation(.spring(response: 0.3), value: engine.currentStreak)
    }

    // MARK: - Countdown ring

    private var countdownRing: some View {
        let total = engine.difficulty.secondsPerCard ?? 1
        let remaining = engine.cardTimeRemaining
        let fraction = remaining / total

        // Color shifts green → amber → red as time runs low
        let ringColor: Color = fraction > 0.4
            ? engine.difficulty.timerColor
            : fraction > 0.2
                ? MatherTheme.warm
                : MatherTheme.danger

        return ZStack {
            // Background track
            Circle()
                .stroke(ringColor.opacity(0.18), lineWidth: 5)
            // Depleting arc
            Circle()
                .trim(from: 0, to: fraction)
                .stroke(ringColor, style: StrokeStyle(lineWidth: 5, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.linear(duration: 0.1), value: fraction)
            // Seconds label
            Text("\(max(0, Int(remaining.rounded(.up))))")
                .font(.system(size: 17, weight: .black, design: .rounded))
                .foregroundStyle(ringColor)
                .contentTransition(.numericText())
                .animation(.linear(duration: 0.1), value: Int(remaining.rounded(.up)))
        }
        .frame(width: 54, height: 54)
    }

    // MARK: - Feedback overlay

    private func feedbackOverlay(symbol: String, color: Color) -> some View {
        ZStack {
            Color.black.opacity(0.12).ignoresSafeArea()
            Text(symbol)
                .font(.system(size: 80, weight: .black))
                .foregroundStyle(color)
                .transition(.scale.combined(with: .opacity))
        }
        .allowsHitTesting(false)
    }
}

// MARK: - Progress label helper

@MainActor
private extension SumSprintEngine {
    var progressLabel: String {
        guard !cards.isEmpty else { return "" }
        return "Card \(currentCardIndex + 1) of \(cards.count)"
    }
}
