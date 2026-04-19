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

                    statsRow

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
            Text(celebrationEmoji)
                .font(.system(size: 72))

            Text(celebrationTitle)
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

            // Difficulty badge
            Text(summary.difficulty.emoji + " " + summary.difficulty.label)
                .font(.caption.weight(.bold))
                .foregroundStyle(summary.difficulty.timerColor)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(summary.difficulty.timerColor.opacity(0.12), in: Capsule())
        }
    }

    private var celebrationEmoji: String {
        if summary.difficulty == .sprint && summary.timeoutCount == 0 { return "🏆" }
        if summary.peakStreak >= 5 { return "⭐️" }
        return "🎉"
    }

    private var celebrationTitle: String {
        if summary.difficulty == .sprint && summary.timeoutCount == 0 { return "Perfect Sprint!" }
        if summary.peakStreak >= 5 { return "Amazing streak!" }
        return "Great practice!"
    }

    // MARK: - Stats row

    private var statsRow: some View {
        HStack(spacing: 12) {
            statTile(
                value: "\(summary.correctCount)/\(summary.cards.count)",
                label: "Correct",
                icon: "checkmark.circle.fill",
                color: MatherTheme.accent
            )

            if summary.difficulty != .relaxed && summary.timeoutCount > 0 {
                statTile(
                    value: "\(summary.timeoutCount)",
                    label: "Timed out",
                    icon: "clock.badge.xmark.fill",
                    color: MatherTheme.warm
                )
            }

            if let fastest = summary.fastestCardSeconds {
                statTile(
                    value: String(format: "%.1fs", fastest),
                    label: "Fastest",
                    icon: "bolt.fill",
                    color: MatherTheme.warm
                )
            }
        }
    }

    private func statTile(value: String, label: String, icon: String, color: Color) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 22))
                .foregroundStyle(color)
            Text(value)
                .font(.system(size: 20, weight: .black, design: .rounded))
                .foregroundStyle(MatherTheme.ink)
            Text(label)
                .font(.caption.weight(.semibold))
                .foregroundStyle(MatherTheme.cardSubtitle)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(MatherTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
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
            if card.timedOut {
                Image(systemName: "clock.badge.xmark.fill")
                    .foregroundStyle(MatherTheme.warm)
            } else {
                Image(systemName: wasCorrect ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .foregroundStyle(wasCorrect ? MatherTheme.accent : MatherTheme.danger)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(
                    card.timedOut    ? MatherTheme.warm.opacity(0.1)   :
                    wasCorrect       ? MatherTheme.accent.opacity(0.1) :
                    MatherTheme.danger.opacity(0.1)
                )
        )
    }

    // MARK: - Buttons

    private var buttonStack: some View {
        VStack(spacing: 12) {
            Button("Play again") { onPlayAgain() }
                .buttonStyle(PrimaryActionButtonStyle())

            Button("Done") { onDone() }
                .buttonStyle(SecondaryTileButtonStyle(fill: MatherTheme.softBlue.opacity(0.55)))
        }
    }
}
