import SwiftUI

struct ConcreteBuildView: View {
    let target: Int
    let warmCount: Int
    let accentCount: Int
    let onAdjust: (Int, ConcreteGroup) -> Void
    let onSubmit: () -> Void
    var theme: any SliceTheme = ClassicTheme()

    // For issue #222 recovery the concrete stage must genuinely support 1...20.
    // We keep 5 columns so the child still sees familiar subitizing-friendly rows,
    // but expand the surface to 4 rows when needed.
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 10), count: 5)

    var body: some View {
        CardSurface {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .firstTextBaseline, spacing: 10) {
                    Text("Make")
                        .font(.title.weight(.bold))
                        .foregroundStyle(.secondary)
                    Text("\(target)")
                        .font(.system(size: 44, weight: .black, design: .rounded))
                        .foregroundStyle(MatherTheme.accent)
                }

                // Color.clear with aspectRatio is the reliable SwiftUI idiom for
                // square grid cells — it constrains height = width without fighting
                // the grid's flexible column width calculation.
                // Cells are capped at 72pt so on wide screens (iPad) they don't grow
                // to 130pt+ — "bigger circles" feedback and scrolling are eliminated.
                LazyVGrid(columns: columns, spacing: 10) {
                    ForEach(0..<min(max(target, 1), 20), id: \.self) { index in
                        counterCell(index: index)
                            .frame(maxWidth: 72, maxHeight: 72)
                            .accessibilityIdentifier("counter-cell-\(index)")
                            .accessibilityLabel("Counter \(index + 1)")
                            .contentShape(Rectangle())
                            .onTapGesture {
                                guard let tap = Self.tapAction(
                                    for: index,
                                    target: target,
                                    warmCount: warmCount,
                                    accentCount: accentCount
                                ) else { return }
                                onAdjust(tap.delta, tap.group)
                            }
                    }
                }
                .frame(maxWidth: 400)
                .frame(maxWidth: .infinity)


                // Number-bond display: live A + B = target as circles are tapped.
                // Numerals and symbols only — no words, consistent with the no-reading principle.
                // Connects the concrete ten-frame action to the abstract equation (CPA bridge).
                HStack(spacing: 8) {
                    Text("\(warmCount)")
                        .font(.system(size: 36, weight: .black, design: .rounded))
                        .foregroundStyle(MatherTheme.warm)
                        .accessibilityIdentifier("warm-count-label")
                        .contentTransition(.numericText())
                        .animation(.spring(response: 0.3), value: warmCount)
                    Text("+")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundStyle(.secondary)
                    Text("\(accentCount)")
                        .font(.system(size: 36, weight: .black, design: .rounded))
                        .foregroundStyle(MatherTheme.accent)
                        .accessibilityIdentifier("accent-count-label")
                        .contentTransition(.numericText())
                        .animation(.spring(response: 0.3), value: accentCount)
                    Text("= \(warmCount + accentCount)")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
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

    nonisolated static func tapAction(
        for index: Int,
        target: Int,
        warmCount: Int,
        accentCount: Int
    ) -> (delta: Int, group: ConcreteGroup)? {
        let isWarm = index < 10
        let group: ConcreteGroup = isWarm ? .warm : .accent
        let groupCount = isWarm ? warmCount : accentCount
        let groupCapacity = isWarm ? min(target, 10) : max(target - 10, 0)
        let slotIndex = index % 10

        guard isWarm || warmCount >= min(target, 10) else { return nil }
        guard slotIndex < groupCapacity else { return nil }

        if slotIndex == groupCount, groupCount < groupCapacity {
            return (1, group)
        }

        if groupCount > 0, slotIndex == groupCount - 1 {
            return (-1, group)
        }

        return nil
    }

    @ViewBuilder
    private func counterCell(index: Int) -> some View {
        let isFirstRow = index < 10
        let rowIndex = index % 10
        let filled = isFirstRow ? rowIndex < warmCount : rowIndex < accentCount
        CounterView(index: index, filled: filled, theme: theme)
    }
}
