import SwiftUI

struct FlashCardView: View {
    let card: SumSprintCard
    let onAppend: (Int) -> Void
    let onDelete: () -> Void
    let onSubmit: () -> Void

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        CardSurface {
            VStack(spacing: 24) {
                dotClusterRow
                equationFrame
                numpad
            }
        }
    }

    // MARK: - Dot clusters (pictorial aid)

    private var dotClusterRow: some View {
        HStack(spacing: 16) {
            DotCluster(count: card.fact.addendA, color: MatherTheme.warm)
            Text("+")
                .font(.title.weight(.black))
                .foregroundStyle(MatherTheme.ink)
            DotCluster(count: card.fact.addendB, color: MatherTheme.accent)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Equation frame

    private var equationFrame: some View {
        HStack(spacing: 12) {
            Text("\(card.fact.addendA)")
                .font(.system(size: 48, weight: .black, design: .rounded))
                .foregroundStyle(MatherTheme.warm)
            Text("+")
                .font(.system(size: 36, weight: .black, design: .rounded))
                .foregroundStyle(MatherTheme.ink)
            Text("\(card.fact.addendB)")
                .font(.system(size: 48, weight: .black, design: .rounded))
                .foregroundStyle(MatherTheme.accent)
            Text("=")
                .font(.system(size: 36, weight: .black, design: .rounded))
                .foregroundStyle(MatherTheme.ink)
            answerSlot
        }
        .frame(maxWidth: .infinity)
    }

    private var answerSlot: some View {
        let isEmpty = card.typedAnswer.isEmpty
        return Text(isEmpty ? "?" : card.typedAnswer)
            .font(.system(size: 48, weight: .black, design: .rounded))
            .foregroundStyle(isEmpty ? MatherTheme.ink.opacity(0.35) : MatherTheme.ink)
            .frame(minWidth: 64, minHeight: 64)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(MatherTheme.softBlue.opacity(colorScheme == .dark ? 0.32 : 0.22))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(
                        isEmpty
                            ? MatherTheme.panelDeep.opacity(0.4)
                            : MatherTheme.accent.opacity(0.7),
                        lineWidth: 2
                    )
            )
    }

    // MARK: - Numpad

    private var numpad: some View {
        let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 3)
        return VStack(spacing: 8) {
            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(1...9, id: \.self) { digit in
                    numpadButton(label: "\(digit)") { onAppend(digit) }
                }
            }
            LazyVGrid(columns: columns, spacing: 8) {
                numpadButton(label: "⌫", color: MatherTheme.danger.opacity(0.18)) { onDelete() }
                numpadButton(label: "0") { onAppend(0) }
                numpadButton(label: "✓", color: MatherTheme.accent.opacity(0.85), labelColor: .white) { onSubmit() }
            }
        }
    }

    private func numpadButton(
        label: String,
        color: Color = MatherTheme.softBlue.opacity(0.55),
        labelColor: Color = MatherTheme.ink,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Text(label)
                .font(.title3.weight(.bold))
                .foregroundStyle(labelColor)
                .frame(maxWidth: .infinity, minHeight: 80)
                .background(color)
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .strokeBorder(
                            colorScheme == .dark ? .white.opacity(0.08) : .clear,
                            lineWidth: 1
                        )
                )
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
        .accessibilityLabel(label)
    }
}

// MARK: - DotCluster

private struct DotCluster: View {
    let count: Int
    let color: Color

    private let dotsPerRow = 5

    var body: some View {
        let rows = Int(ceil(Double(count) / Double(dotsPerRow)))
        VStack(spacing: 4) {
            ForEach(0..<rows, id: \.self) { row in
                HStack(spacing: 4) {
                    let start = row * dotsPerRow
                    let end = min(start + dotsPerRow, count)
                    ForEach(start..<end, id: \.self) { _ in
                        Circle()
                            .fill(color)
                            .frame(width: 14, height: 14)
                    }
                    // Pad row to 5 dots wide so alignment is consistent
                    if (end - start) < dotsPerRow && row < rows - 1 {
                        ForEach(0..<(dotsPerRow - (end - start)), id: \.self) { _ in
                            Circle()
                                .fill(Color.clear)
                                .frame(width: 14, height: 14)
                        }
                    }
                }
            }
        }
        .padding(8)
        .background(color.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
}
