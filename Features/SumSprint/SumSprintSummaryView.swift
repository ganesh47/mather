import SwiftUI

struct SumSprintSummaryView: View {
    let summary: SumSprintSessionSummary
    let onPlayAgain: () -> Void
    let onDone: () -> Void

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [MatherTheme.warm.opacity(0.25), MatherTheme.accent.opacity(0.18)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 28) {
                    Spacer(minLength: 20)

                    celebrationBlock

                    factsPracticedGrid

                    buttonStack
                }
                .padding(24)
            }
        }
    }

    // MARK: - Celebration

    private var celebrationBlock: some View {
        VStack(spacing: 12) {
            Text(summary.peakStreak >= 5 ? "⭐️" : "🎉")
                .font(.system(size: 72))

            Text(summary.peakStreak >= 5 ? "Amazing streak!" : "Great practice!")
                .font(.system(size: 32, weight: .black, design: .rounded))
                .foregroundStyle(MatherTheme.ink)
                .multilineTextAlignment(.center)

            if summary.peakStreak > 0 {
                Text("\(summary.peakStreak) in a row!")
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(MatherTheme.accent)
            }

            Text("\(summary.correctCount) of \(summary.cards.count) correct")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(MatherTheme.ink.opacity(0.6))
        }
    }

    // MARK: - Facts practiced grid

    private var factsPracticedGrid: some View {
        CardSurface {
            VStack(alignment: .leading, spacing: 12) {
                Text("Facts practiced")
                    .font(.headline.weight(.bold))
                    .foregroundStyle(MatherTheme.ink.opacity(0.7))

                let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 2)
                LazyVGrid(columns: columns, spacing: 8) {
                    ForEach(summary.cards) { card in
                        factPill(card: card)
                    }
                }
            }
        }
    }

    private func factPill(card: SumSprintCard) -> some View {
        let wasCorrect: Bool = {
            if case .correct = card.result { return true }
            return false
        }()

        return HStack(spacing: 6) {
            Text("\(card.fact.addendA) + \(card.fact.addendB) = \(card.fact.sum)")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(MatherTheme.ink)
            Spacer()
            Image(systemName: wasCorrect ? "checkmark.circle.fill" : "xmark.circle.fill")
                .foregroundStyle(wasCorrect ? MatherTheme.accent : MatherTheme.danger)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(wasCorrect
                    ? MatherTheme.accent.opacity(0.1)
                    : MatherTheme.danger.opacity(0.1))
        )
    }

    // MARK: - Buttons

    private var buttonStack: some View {
        VStack(spacing: 12) {
            Button("Play again") {
                onPlayAgain()
            }
            .buttonStyle(PrimaryActionButtonStyle())

            Button("Done") {
                onDone()
            }
            .buttonStyle(SecondaryTileButtonStyle(fill: MatherTheme.softBlue.opacity(0.55)))
        }
    }
}
