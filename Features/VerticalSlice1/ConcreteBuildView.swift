import SwiftUI

struct ConcreteBuildView: View {
    let target: Int
    let concreteCount: Int
    let onAdjust: (Int) -> Void
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
                            .onTapGesture {
                                onAdjust((index + 1) - concreteCount)
                            }
                    }
                }

                HStack(spacing: 12) {
                    Button {
                        onAdjust(-1)
                    } label: {
                        Label("Remove", systemImage: "minus.circle.fill")
                    }
                    .buttonStyle(SecondaryTileButtonStyle(fill: MatherTheme.softBlue.opacity(0.55)))

                    Button {
                        onAdjust(1)
                    } label: {
                        Label("Add", systemImage: "plus.circle.fill")
                    }
                    .buttonStyle(SecondaryTileButtonStyle(fill: MatherTheme.warm.opacity(0.7)))
                }

                Button("That is \(target)") {
                    onSubmit()
                }
                .buttonStyle(PrimaryActionButtonStyle())
            }
        }
    }

    @ViewBuilder
    private func counterCell(index: Int) -> some View {
        let filled = index < concreteCount
        // Two-tone subitizing: first row (0–4) is warm amber, second row (5–9) is
        // vivid green. A child sees "5 amber + 2 green" for 7 without counting.
        let isFirstRow = index < 5
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
