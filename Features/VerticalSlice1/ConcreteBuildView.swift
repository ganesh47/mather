import SwiftUI

struct ConcreteBuildView: View {
    let target: Int
    let warmCount: Int
    let accentCount: Int
    let onAdjust: (Int, ConcreteGroup) -> Void
    let onSubmit: () -> Void

    // Ten-frame is always 5 columns × 2 rows — invariant across device sizes.
    // The 2×5 structure is what enables subitizing: 7 is instantly seen as
    // "a full row of 5 + 2 more", not counted one-by-one.
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 10), count: 5)

    var body: some View {
        CardSurface {
            VStack(alignment: .leading, spacing: 20) {
                HStack(alignment: .firstTextBaseline, spacing: 10) {
                    Text("Make")
                        .font(.title.weight(.bold))
                        .foregroundStyle(.secondary)
                    Text("\(target)")
                        .font(.system(size: 56, weight: .black, design: .rounded))
                        .foregroundStyle(MatherTheme.accent)
                }

                // Color.clear with aspectRatio is the reliable SwiftUI idiom for
                // square grid cells — it constrains height = width without fighting
                // the grid's flexible column width calculation.
                LazyVGrid(columns: columns, spacing: 10) {
                    ForEach(0..<10, id: \.self) { index in
                        counterCell(index: index)
                            .accessibilityIdentifier("counter-cell-\(index)")
                            .accessibilityLabel("Counter \(index + 1)")
                            .onTapGesture {
                                let isWarm = index < 5
                                let rowIndex = index % 5
                                onAdjust(
                                    (rowIndex + 1) - (isWarm ? warmCount : accentCount),
                                    isWarm ? .warm : .accent
                                )
                            }
                    }
                }

                // Number-bond display: live A + B = target as circles are tapped.
                // Numerals and symbols only — no words, consistent with the no-reading principle.
                // Connects the concrete ten-frame action to the abstract equation (CPA bridge).
                HStack(spacing: 8) {
                    Text("\(warmCount)")
                        .font(.system(size: 44, weight: .black, design: .rounded))
                        .foregroundStyle(MatherTheme.warm)
                        .accessibilityIdentifier("warm-count-label")
                        .contentTransition(.numericText())
                        .animation(.spring(response: 0.3), value: warmCount)
                    Text("+")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundStyle(.secondary)
                    Text("\(accentCount)")
                        .font(.system(size: 44, weight: .black, design: .rounded))
                        .foregroundStyle(MatherTheme.accent)
                        .accessibilityIdentifier("accent-count-label")
                        .contentTransition(.numericText())
                        .animation(.spring(response: 0.3), value: accentCount)
                    Text("= \(warmCount + accentCount)")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .center)

                Button("That is \(target)") {
                    onSubmit()
                }
                .buttonStyle(PrimaryActionButtonStyle())
            }
        }
    }

    @ViewBuilder
    private func counterCell(index: Int) -> some View {
        let isFirstRow = index < 5
        let rowIndex = index % 5
        let filled = isFirstRow ? rowIndex < warmCount : rowIndex < accentCount
        let fillColor: Color = filled
            ? (isFirstRow ? MatherTheme.warm : MatherTheme.accent)
            : .clear
        let strokeColor: Color = isFirstRow
            ? MatherTheme.warm.opacity(filled ? 0.0 : 0.55)
            : MatherTheme.accent.opacity(filled ? 0.0 : 0.45)
        let bgColor: Color = isFirstRow
            ? MatherTheme.warm.opacity(filled ? 0.0 : 0.12)
            : MatherTheme.accent.opacity(filled ? 0.0 : 0.10)

        Color.clear
            .aspectRatio(1, contentMode: .fit)
            .overlay(
                Circle()
                    .fill(filled ? fillColor : bgColor)
                    .overlay(
                        Circle()
                            .strokeBorder(filled ? fillColor.opacity(0.3) : strokeColor, lineWidth: 2.5)
                    )
                    .shadow(color: filled ? fillColor.opacity(0.35) : .clear, radius: 4, y: 2)
            )
    }
}
