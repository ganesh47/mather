import SwiftUI

struct SplitView: View {
    let target: Int
    let leftCount: Int
    let onAdjust: (Int) -> Void
    let onSubmit: () -> Void
    var theme: any SliceTheme = ClassicTheme()

    private var rightCount: Int { target - leftCount }

    var body: some View {
        CardSurface {
            VStack(alignment: .leading, spacing: 20) {
                HStack(alignment: .firstTextBaseline, spacing: 10) {
                    Text("Break")
                        .font(.title.weight(.bold))
                        .foregroundStyle(.secondary)
                    Text("\(target)")
                        .font(.system(size: 56, weight: .black, design: .rounded))
                        .foregroundStyle(MatherTheme.softBlue)
                }

                ViewThatFits {
                    HStack(spacing: 12) {
                        bucket(count: leftCount, fill: MatherTheme.warm, delta: 1)
                        bucket(count: rightCount, fill: MatherTheme.softBlue, delta: -1)
                    }
                    VStack(spacing: 12) {
                        bucket(count: leftCount, fill: MatherTheme.warm, delta: 1)
                        bucket(count: rightCount, fill: MatherTheme.softBlue, delta: -1)
                    }
                }
                .gesture(
                    DragGesture(minimumDistance: 30)
                        .onEnded { value in
                            onAdjust(value.translation.width < 0 ? -1 : 1)
                        }
                )

                // Swipe affordance — left/right chevrons hint at the drag gesture.
                // Tap on each bucket also adjusts the split (no reading required).
                HStack {
                    Image(systemName: "chevron.left")
                    Spacer()
                    Image(systemName: "chevron.right")
                }
                .font(.footnote.weight(.medium))
                .foregroundStyle(.secondary.opacity(0.45))
                .padding(.horizontal, 20)

                // Live equation — shows A + B = target as the child adjusts the split.
                // Bridges the pictorial buckets to the abstract equation (CPA framework).
                HStack(spacing: 8) {
                    Text("\(leftCount)")
                        .font(.system(size: 36, weight: .black, design: .rounded))
                        .foregroundStyle(MatherTheme.warm)
                        .contentTransition(.numericText())
                        .animation(.spring(response: 0.3), value: leftCount)
                    Text("+")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundStyle(.secondary)
                    Text("\(rightCount)")
                        .font(.system(size: 36, weight: .black, design: .rounded))
                        .foregroundStyle(MatherTheme.softBlue)
                        .contentTransition(.numericText())
                        .animation(.spring(response: 0.3), value: rightCount)
                    Text("= \(target)")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .center)

                Button("Use this break") {
                    onSubmit()
                }
                .buttonStyle(PrimaryActionButtonStyle())
            }
        }
    }

    private func bucket(count: Int, fill: Color, delta: Int) -> some View {
        let rows = dotRows(count: count, capacity: target)
        return VStack(spacing: 10) {
            Text("\(count)")
                .font(.system(size: 52, weight: .black, design: .rounded))
                .foregroundStyle(fill)
                .contentTransition(.numericText())
                .animation(.spring(response: 0.3), value: count)

            // Dots laid out in rows of 5 — mirrors the ten-frame structure
            // so the child can subitize each group at a glance.
            dotGrid(rows: rows, fill: fill, delta: delta)
        }
        .frame(maxWidth: .infinity)
    }

    @ViewBuilder
    private func dotGrid(rows: [[Bool]], fill: Color, delta: Int) -> some View {
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
                        .frame(maxWidth: 36, maxHeight: 36)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .padding(.horizontal, 12)
        .background(fill.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .onTapGesture { onAdjust(delta) }
    }

    // Lay out `count` filled dots and (capacity - count) empty dots in rows of 5.
    private func dotRows(count: Int, capacity: Int) -> [[Bool]] {
        let total = max(capacity, 1)
        var rows: [[Bool]] = []
        var remaining = total
        var filled = count
        while remaining > 0 {
            let rowSize = min(remaining, 5)
            let row = (0..<rowSize).map { i -> Bool in
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
