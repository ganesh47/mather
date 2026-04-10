import SwiftUI

struct TransferCheckView: View {
    @Environment(\.colorScheme) private var colorScheme
    let problem: SliceProblem
    let leftCount: Int
    let rightCount: Int
    let onAdjust: (Int, TransferSide) -> Void
    let onSubmit: () -> Void
    var theme: any SliceTheme = ClassicTheme()

    var body: some View {
        CardSurface {
            VStack(alignment: .leading, spacing: 14) {
                // Show only the target — decomposition values are not revealed up front.
                HStack(spacing: 10) {
                    questionPill(fill: MatherTheme.warm)
                    Text("+")
                        .font(.title.weight(.black))
                        .foregroundStyle(.secondary)
                    questionPill(fill: MatherTheme.accent)
                    Text("=")
                        .font(.title.weight(.black))
                        .foregroundStyle(.secondary)
                    Text("\(problem.target)")
                        .font(.system(size: 34, weight: .black, design: .rounded))
                        .foregroundStyle(MatherTheme.ink)
                }
                .accessibilityIdentifier("transfer-equation")

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

                Button("Check it!") {
                    onSubmit()
                }
                .buttonStyle(PrimaryActionButtonStyle())
            }
        }
    }

    private func questionPill(fill: Color) -> some View {
        Text("?")
            .font(.system(size: 28, weight: .black, design: .rounded))
            .foregroundStyle(fill.opacity(0.6))
            .frame(minWidth: 58, minHeight: 58)
            .background(fill.opacity(0.10))
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private func transferBucket(title: String, targetCount: Int, count: Int, fill: Color, side: TransferSide) -> some View {
        let bucketBackground = colorScheme == .dark ? MatherTheme.panel.opacity(0.94) : MatherTheme.card
        let bucketBorder = colorScheme == .dark ? MatherTheme.panelDeep.opacity(0.78) : fill.opacity(0.18)

        return VStack(spacing: 8) {
            Text(title)
                .font(.caption.weight(.bold))
                .foregroundStyle(MatherTheme.ink)
                .frame(maxWidth: .infinity, alignment: .leading)

            LazyVGrid(
                columns: Array(repeating: GridItem(.flexible(), spacing: 6), count: 5),
                spacing: 6
            ) {
                ForEach(0..<problem.target, id: \.self) { idx in
                    CounterView(
                        index: idx,
                        filled: idx < count,
                        theme: theme,
                        overrideColor: fill
                    )
                    .frame(maxWidth: 44, maxHeight: 44)
                    .accessibilityIdentifier("transfer-\(side == .left ? "left" : "right")-cell-\(idx)")
                }
            }
            .accessibilityIdentifier("transfer-\(side == .left ? "left" : "right")-group")

            HStack(spacing: 10) {
                Button {
                    onAdjust(-1, side)
                } label: {
                    Image(systemName: "minus.circle.fill")
                        .font(.title.weight(.bold))
                        .frame(minWidth: 44, minHeight: 44)
                        .background(fill.opacity(0.15))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Remove from \(side == .left ? "left" : "right") group")
                .accessibilityIdentifier("transfer-\(side == .left ? "left" : "right")-minus")

                Button {
                    onAdjust(1, side)
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title.weight(.bold))
                        .frame(minWidth: 44, minHeight: 44)
                        .background(fill.opacity(0.15))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Add to \(side == .left ? "left" : "right") group")
                .accessibilityIdentifier("transfer-\(side == .left ? "left" : "right")-plus")
            }
            .foregroundStyle(fill)
        }
        .padding(12)
        .frame(maxWidth: .infinity)
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
}
