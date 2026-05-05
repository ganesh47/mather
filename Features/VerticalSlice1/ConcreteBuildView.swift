import SwiftUI

struct ConcreteBuildView: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
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
    private var currentCount: Int { warmCount + accentCount }
    private var representation: GroupedNumberRepresentation {
        GroupedNumberRepresentation(target)
    }

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

                if target <= 20 {
                    tapCounterGrid
                } else {
                    groupedBuildControls
                }


                // Number-bond display: live A + B = target as circles are tapped.
                // Numerals and symbols only — no words, consistent with the no-reading principle.
                // Connects the concrete ten-frame action to the abstract equation (CPA bridge).
                HStack(spacing: 8) {
                    Text(equationPartText(warmCount))
                        .font(.system(size: 36, weight: .black, design: .rounded))
                        .foregroundStyle(warmCount == 0 ? .secondary : MatherTheme.warm)
                        .accessibilityIdentifier("warm-count-label")
                        .contentTransition(.numericText())
                        .animation(.spring(response: 0.3), value: warmCount)
                    Text("+")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundStyle(.secondary)
                    Text(equationPartText(accentCount))
                        .font(.system(size: 36, weight: .black, design: .rounded))
                        .foregroundStyle(accentCount == 0 ? .secondary : MatherTheme.accent)
                        .accessibilityIdentifier("accent-count-label")
                        .contentTransition(.numericText())
                        .animation(.spring(response: 0.3), value: accentCount)
                    Text("= \(target)")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .center)

                Button(currentCount == target ? "That is \(target)" : "Make \(target)") {
                    onSubmit()
                }
                .buttonStyle(PrimaryActionButtonStyle())
                .disabled(currentCount != target)
                .opacity(currentCount == target ? 1 : 0.58)
            }
        }
    }

    private var visibleCounterSlotCount: Int {
        if target <= 10 { return 10 }
        return min(max(target, 1), 20)
    }

    private var tapCounterGrid: some View {
        LazyVGrid(columns: columns, spacing: 10) {
            ForEach(0..<visibleCounterSlotCount, id: \.self) { index in
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
        .frame(maxWidth: ResponsiveLayout.concreteGridMaxWidth(for: horizontalSizeClass))
        .frame(maxWidth: .infinity)
    }

    private var groupedBuildControls: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                GroupedNumberView(value: currentCount, fill: MatherTheme.warm)
                    .accessibilityIdentifier("concrete-current-grouped-representation")
                Image(systemName: "arrow.right")
                    .font(.title3.weight(.black))
                    .foregroundStyle(.secondary)
                GroupedNumberView(value: target, fill: MatherTheme.accent)
                    .accessibilityIdentifier("concrete-target-grouped-representation")
            }
            .frame(maxWidth: .infinity)

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 96), spacing: 10)], spacing: 10) {
                ForEach(representation.suggestedSteps, id: \.self) { step in
                    groupedStepButton(step: -step)
                    groupedStepButton(step: step)
                }
            }
            .frame(maxWidth: .infinity)
        }
    }

    private func equationPartText(_ value: Int) -> String {
        value == 0 ? "?" : "\(value)"
    }

    private func groupedStepButton(step: Int) -> some View {
        let canApply = step < 0 ? currentCount > 0 : currentCount < target
        let clampedStep = step < 0 ? max(step, -currentCount) : min(step, target - currentCount)

        return Button {
            onAdjust(clampedStep, .warm)
        } label: {
            Label("\(step > 0 ? "+" : "-")\(abs(step))", systemImage: step > 0 ? "plus.circle.fill" : "minus.circle.fill")
                .font(.headline.weight(.black))
                .frame(minWidth: 88, minHeight: 80)
        }
        .buttonStyle(.plain)
        .foregroundStyle(canApply ? MatherTheme.warm : MatherTheme.warm.opacity(0.28))
        .disabled(!canApply)
        .accessibilityLabel(step > 0 ? "Add \(step)" : "Remove \(abs(step))")
        .accessibilityIdentifier("concrete-step-\(step > 0 ? "plus" : "minus")-\(abs(step))")
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
        CounterView(
            index: index,
            filled: filled,
            theme: theme,
            overrideColor: target <= 10 ? MatherTheme.warm : nil
        )
    }
}
