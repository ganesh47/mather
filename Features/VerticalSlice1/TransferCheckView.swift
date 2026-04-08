import SwiftUI

struct TransferCheckView: View {
    let problem: SliceProblem
    let leftCount: Int
    let rightCount: Int
    let onAdjust: (Int, TransferSide) -> Void
    let onSubmit: () -> Void
    var theme: any SliceTheme = ClassicTheme()

    var body: some View {
        CardSurface {
            VStack(alignment: .leading, spacing: 14) {
                HStack(spacing: 10) {
                    equationPill(value: problem.decompositionA, fill: MatherTheme.warm)
                    Text("+")
                        .font(.title.weight(.black))
                        .foregroundStyle(.secondary)
                    equationPill(value: problem.decompositionB, fill: MatherTheme.accent)
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

                Button("Check the same equation") {
                    onSubmit()
                }
                .buttonStyle(PrimaryActionButtonStyle())
            }
        }
    }

    private func equationPill(value: Int, fill: Color) -> some View {
        Text("\(value)")
            .font(.system(size: 28, weight: .black, design: .rounded))
            .foregroundStyle(fill)
            .frame(minWidth: 58, minHeight: 58)
            .background(fill.opacity(0.14))
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private func transferBucket(title: String, targetCount: Int, count: Int, fill: Color, side: TransferSide) -> some View {
        VStack(spacing: 8) {
            HStack {
                Text(title)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(MatherTheme.ink)
                Spacer()
                Text("\(targetCount)")
                    .font(.system(size: 22, weight: .black, design: .rounded))
                    .foregroundStyle(fill)
            }

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
        .frame(maxWidth: .infinity)
    }
}
