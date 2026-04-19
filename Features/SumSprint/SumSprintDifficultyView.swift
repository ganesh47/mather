import SwiftUI

/// Pre-session screen where the child (or parent) picks a difficulty tier.
///
/// Relaxed → Standard → Sprint ramp up time pressure and card count.
/// The selection is passed straight to SumSprintEngine.selectDifficulty(_:)
/// which kicks off the session immediately.
struct SumSprintDifficultyView: View {

    let engine: SumSprintEngine
    let onExit: () -> Void

    @State private var selectedDifficulty: SumSprintDifficulty? = nil
    @State private var hovered: SumSprintDifficulty? = nil

    var body: some View {
        ZStack {
            MatherTheme.background.ignoresSafeArea()

            VStack(spacing: 0) {
                header
                    .padding(.horizontal, 24)
                    .padding(.top, 24)

                Spacer(minLength: 20)

                difficultyCards
                    .padding(.horizontal, 24)

                Spacer()
            }
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Sum Sprint")
                    .font(.system(size: 34, weight: .black, design: .rounded))
                    .foregroundStyle(MatherTheme.ink)
                Text("Choose your challenge")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(MatherTheme.cardSubtitle)
            }
            Spacer()
            Button("Done") { onExit() }
                .font(.headline.weight(.semibold))
                .foregroundStyle(.white)
                .frame(minWidth: 88, minHeight: 44)
                .background(
                    MatherTheme.ink.opacity(0.65),
                    in: RoundedRectangle(cornerRadius: 12, style: .continuous)
                )
        }
    }

    // MARK: - Difficulty cards

    private var difficultyCards: some View {
        VStack(spacing: 14) {
            ForEach(SumSprintDifficulty.allCases, id: \.self) { diff in
                difficultyCard(diff)
            }
        }
    }

    private func difficultyCard(_ diff: SumSprintDifficulty) -> some View {
        Button {
            selectedDifficulty = diff
            engine.selectDifficulty(diff)
        } label: {
            HStack(spacing: 16) {
                // Big emoji indicator
                Text(diff.emoji)
                    .font(.system(size: 44))
                    .frame(width: 56)

                VStack(alignment: .leading, spacing: 5) {
                    HStack(spacing: 8) {
                        Text(diff.label)
                            .font(.title2.weight(.black))
                            .foregroundStyle(MatherTheme.ink)
                        timerBadge(diff)
                    }
                    Text(diff.description)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(MatherTheme.cardSubtitle)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer()

                Image(systemName: "chevron.right.circle.fill")
                    .font(.system(size: 26))
                    .foregroundStyle(diff.timerColor.opacity(0.7))
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 20)
            .frame(maxWidth: .infinity, minHeight: 96)
            .background(diff.timerColor.opacity(0.10))
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .strokeBorder(diff.timerColor.opacity(0.3), lineWidth: 1.5)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(diff.label): \(diff.description)")
    }

    /// Small pill showing seconds-per-card or "No timer".
    private func timerBadge(_ diff: SumSprintDifficulty) -> some View {
        let label: String = {
            if let secs = diff.secondsPerCard {
                return "\(Int(secs))s"
            } else {
                return "∞"
            }
        }()

        return Text(label)
            .font(.caption.weight(.bold))
            .foregroundStyle(diff.timerColor)
            .padding(.horizontal, 7)
            .padding(.vertical, 3)
            .background(diff.timerColor.opacity(0.15), in: Capsule())
    }
}
