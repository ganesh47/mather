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
            VStack(alignment: .leading, spacing: 18) {
                Text(theme.transferPrompt(decompositionA: problem.decompositionA, decompositionB: problem.decompositionB))
                    .font(.headline.weight(.bold))
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityIdentifier("transfer-instruction")

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

                ViewThatFits {
                    HStack(spacing: 12) {
                        transferBucket(
                            title: "Left side of the equation",
                            targetCount: problem.decompositionA,
                            count: leftCount,
                            fill: MatherTheme.warm,
                            side: .left
                        )
                        transferBucket(
                            title: "Right side of the equation",
                            targetCount: problem.decompositionB,
                            count: rightCount,
                            fill: MatherTheme.accent,
                            side: .right
                        )
                    }
                    VStack(spacing: 12) {
                        transferBucket(
                            title: "Left side of the equation",
                            targetCount: problem.decompositionA,
                            count: leftCount,
                            fill: MatherTheme.warm,
                            side: .left
                        )
                        transferBucket(
                            title: "Right side of the equation",
                            targetCount: problem.decompositionB,
                            count: rightCount,
                            fill: MatherTheme.accent,
                            side: .right
                        )
                    }
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
        VStack(spacing: 10) {
            Text(title)
                .font(.headline.weight(.bold))
                .foregroundStyle(MatherTheme.ink)
                .multilineTextAlignment(.center)
            Text("\(targetCount)")
                .font(.system(size: 40, weight: .black, design: .rounded))
                .foregroundStyle(fill)
            Text("Put \(targetCount) counters here.")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.secondary)

            let rows = dotRows(count: count, capacity: problem.target)
            VStack(spacing: 6) {
                ForEach(rows.indices, id: \.self) { rowIndex in
                    HStack(spacing: 6) {
                        ForEach(rows[rowIndex].indices, id: \.self) { dotIndex in
                            let isFilled = rows[rowIndex][dotIndex]
                            CounterView(
                                index: dotIndex + rowIndex * 5,
                                filled: isFilled,
                                theme: theme,
                                overrideColor: fill
                            )
                            .frame(minWidth: 18, minHeight: 18)
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .padding(.horizontal, 12)
            .background(fill.opacity(0.12))
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .accessibilityIdentifier("transfer-\(side == .left ? "left" : "right")-group")
            .onTapGesture { onAdjust(1, side) }

            HStack(spacing: 10) {
                Button {
                    onAdjust(-1, side)
                } label: {
                    Image(systemName: "minus.circle.fill")
                        .font(.title.weight(.bold))
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Remove from \(side == .left ? "left" : "right") group")
                .accessibilityIdentifier("transfer-\(side == .left ? "left" : "right")-minus")

                Button {
                    onAdjust(1, side)
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title.weight(.bold))
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Add to \(side == .left ? "left" : "right") group")
                .accessibilityIdentifier("transfer-\(side == .left ? "left" : "right")-plus")
            }
            .foregroundStyle(fill)
        }
        .frame(maxWidth: .infinity)
    }

    private func dotRows(count: Int, capacity: Int) -> [[Bool]] {
        let total = max(capacity, 1)
        var rows: [[Bool]] = []
        var remaining = total
        var filled = count
        while remaining > 0 {
            let rowSize = min(remaining, 5)
            let row = (0..<rowSize).map { _ -> Bool in
                let result = filled > 0
                if result { filled -= 1 }
                return result
            }
            rows.append(row)
            remaining -= rowSize
        }
        return rows
    }
}
