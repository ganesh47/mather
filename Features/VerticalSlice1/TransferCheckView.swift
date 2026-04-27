import SwiftUI

struct TransferCheckView: View {
    @Environment(\.colorScheme) private var colorScheme
    let problem: SliceProblem
    let leftCount: Int
    let rightCount: Int
    let onAdjust: (Int, TransferSide) -> Void
    let onSubmit: () -> Void
    var theme: any SliceTheme = ClassicTheme()

    private var equationCopy: TransferEquationCopy {
        TransferEquationCopy(problem: problem)
    }

    var body: some View {
        CardSurface {
            VStack(alignment: .leading, spacing: 14) {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Show it again")
                        .font(.title.weight(.bold))
                        .foregroundStyle(MatherTheme.ink)

                    equationRecap

                    Text(equationCopy.instruction)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(MatherTheme.cardSubtitle)
                        .fixedSize(horizontal: false, vertical: true)
                }

                ViewThatFits {
                    HStack(spacing: 12) {
                        transferBucket(
                            title: "Left side",
                            targetCount: problem.decompositionA,
                            count: leftCount,
                            fill: MatherTheme.warm,
                            side: .left
                        )
                        transferBucket(
                            title: "Right side",
                            targetCount: problem.decompositionB,
                            count: rightCount,
                            fill: MatherTheme.accent,
                            side: .right
                        )
                    }

                    VStack(spacing: 12) {
                        transferBucket(
                            title: "Left side",
                            targetCount: problem.decompositionA,
                            count: leftCount,
                            fill: MatherTheme.warm,
                            side: .left
                        )
                        transferBucket(
                            title: "Right side",
                            targetCount: problem.decompositionB,
                            count: rightCount,
                            fill: MatherTheme.accent,
                            side: .right
                        )
                    }
                }

                Button("Check my equation") {
                    onSubmit()
                }
                .buttonStyle(PrimaryActionButtonStyle())
            }
        }
    }

    private var equationRecap: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Rebuild your equation")
                .font(.caption.weight(.bold))
                .foregroundStyle(MatherTheme.cardSubtitle)
                .textCase(.uppercase)
                .tracking(1.1)

            ViewThatFits {
                HStack(spacing: 10) {
                    equationNumber("\(problem.decompositionA)", fill: MatherTheme.warm, label: "left part")
                    equationOperator("+")
                    equationNumber("\(problem.decompositionB)", fill: MatherTheme.accent, label: "right part")
                    equationOperator("=")
                    equationNumber("\(problem.target)", fill: MatherTheme.softBlue, label: "target")
                }

                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 10) {
                        equationNumber("\(problem.decompositionA)", fill: MatherTheme.warm, label: "left part")
                        equationOperator("+")
                        equationNumber("\(problem.decompositionB)", fill: MatherTheme.accent, label: "right part")
                    }
                    HStack(spacing: 10) {
                        equationOperator("=")
                        equationNumber("\(problem.target)", fill: MatherTheme.softBlue, label: "target")
                    }
                }
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel(equationCopy.recap)
            .accessibilityIdentifier("transfer-equation-recap")
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(MatherTheme.panel.opacity(colorScheme == .dark ? 0.98 : 0.72))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .strokeBorder(colorScheme == .dark ? MatherTheme.panelDeep.opacity(0.78) : MatherTheme.panelDeep.opacity(0.42), lineWidth: 1)
        )
    }

    private func equationNumber(_ value: String, fill: Color, label: String) -> some View {
        Text(value)
            .font(.system(size: 28, weight: .black, design: .rounded))
            .foregroundStyle(MatherTheme.ink)
            .frame(minWidth: 54, minHeight: 48)
            .background(fill.opacity(colorScheme == .dark ? 0.28 : 0.20))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(fill.opacity(colorScheme == .dark ? 0.55 : 0.38), lineWidth: 1.5)
            )
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .accessibilityLabel("\(label) \(value)")
    }

    private func equationOperator(_ symbol: String) -> some View {
        Text(symbol)
            .font(.title2.weight(.black))
            .foregroundStyle(MatherTheme.ink.opacity(0.78))
            .accessibilityLabel(symbol == "+" ? "plus" : "equals")
    }

    private func transferBucket(title: String, targetCount: Int, count: Int, fill: Color, side: TransferSide) -> some View {
        let sideName = side == .left ? "left" : "right"
        let bucketBackground = colorScheme == .dark ? MatherTheme.panel.opacity(0.96) : MatherTheme.card
        let bucketBorder = colorScheme == .dark ? MatherTheme.panelDeep.opacity(0.78) : fill.opacity(0.24)

        return VStack(alignment: .leading, spacing: 10) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.headline.weight(.bold))
                    .foregroundStyle(MatherTheme.ink)
                Text("Make \(targetCount) here")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(MatherTheme.cardSubtitle)
            }

            LazyVGrid(
                columns: Array(repeating: GridItem(.flexible(), spacing: 6), count: 5),
                spacing: 6
            ) {
                ForEach(0..<problem.target, id: \.self) { idx in
                    counterButton(index: idx, count: count, fill: fill, side: side)
                }
            }
            .accessibilityIdentifier("transfer-\(sideName)-group")

            Text("\(count) of \(targetCount)")
                .font(.caption.weight(.bold))
                .foregroundStyle(count == targetCount ? MatherTheme.accent : MatherTheme.cardSubtitle)
                .accessibilityIdentifier("transfer-\(sideName)-count")
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(bucketBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .strokeBorder(bucketBorder, lineWidth: 1)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .strokeBorder(.white.opacity(colorScheme == .dark ? 0.06 : 0), lineWidth: 1)
        )
    }

    private func counterButton(index idx: Int, count: Int, fill: Color, side: TransferSide) -> some View {
        let sideName = side == .left ? "left" : "right"
        let tap = TransferCounterTap(index: idx, currentCount: count)
        let nextCount = tap.nextCount
        let delta = tap.delta

        return Button {
            guard delta != 0 else { return }
            onAdjust(delta, side)
        } label: {
            CounterView(
                index: idx,
                filled: idx < count,
                theme: theme,
                overrideColor: fill
            )
            .frame(maxWidth: 44, maxHeight: 44)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Set \(sideName) side to \(nextCount)")
        .accessibilityValue(idx < count ? "filled" : "empty")
        .accessibilityIdentifier("transfer-\(sideName)-counter-\(idx)")
    }
}

struct TransferCounterTap: Equatable {
    let index: Int
    let currentCount: Int

    var nextCount: Int {
        index < currentCount ? index : index + 1
    }

    var delta: Int {
        nextCount - currentCount
    }
}

struct TransferEquationCopy: Equatable {
    let left: Int
    let right: Int
    let target: Int

    init(problem: SliceProblem) {
        left = problem.decompositionA
        right = problem.decompositionB
        target = problem.target
    }

    var recap: String {
        "Rebuild your equation: \(left) + \(right) = \(target)"
    }

    var instruction: String {
        "Tap counters to make \(left) on the left and \(right) on the right."
    }
}
