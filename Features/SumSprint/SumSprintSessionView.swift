import SwiftUI

struct SumSprintSessionView: View {
    @Bindable var appModel: AppModel

    private var engine: SumSprintEngine { appModel.sumSprintEngine }

    var body: some View {
        ZStack {
            MatherTheme.background.ignoresSafeArea()

            VStack(spacing: 0) {
                header
                    .padding(.horizontal, 20)
                    .padding(.top, 12)

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
                            .transition(.asymmetric(
                                insertion: .move(edge: .trailing).combined(with: .opacity),
                                removal: .move(edge: .leading).combined(with: .opacity)
                            ))
                            .id(engine.currentCardIndex)
                        }
                    }
                    .padding(.vertical, 16)
                }
            }

            // Correct feedback overlay
            if engine.showCorrectFeedback {
                feedbackOverlay(correct: true)
            }

            // Incorrect feedback overlay
            if engine.showIncorrectFeedback {
                feedbackOverlay(correct: false)
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

    // MARK: - Feedback overlay

    private func feedbackOverlay(correct: Bool) -> some View {
        ZStack {
            Color.black.opacity(0.12).ignoresSafeArea()
            Text(correct ? "✓" : "✗")
                .font(.system(size: 80, weight: .black))
                .foregroundStyle(correct ? MatherTheme.accent : MatherTheme.danger)
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
