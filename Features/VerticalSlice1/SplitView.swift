import SwiftUI

struct SplitView: View {
    let target: Int
    let leftCount: Int
    let onAdjust: (Int) -> Void
    let onSubmit: () -> Void

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

                HStack(spacing: 12) {
                    Button("Move Left") { onAdjust(1) }
                        .buttonStyle(SecondaryTileButtonStyle(fill: MatherTheme.warm.opacity(0.55)))
                    Button("Move Right") { onAdjust(-1) }
                        .buttonStyle(SecondaryTileButtonStyle(fill: MatherTheme.softBlue.opacity(0.55)))
                }

                Button("Use this break") {
                    onSubmit()
                }
                .buttonStyle(PrimaryActionButtonStyle())
            }
        }
    }

    private func bucket(count: Int, fill: Color, delta: Int) -> some View {
        VStack(spacing: 10) {
            Text("\(count)")
                .font(.system(size: 52, weight: .black, design: .rounded))
                .foregroundStyle(fill)
                .contentTransition(.numericText())
                .animation(.spring(response: 0.3), value: count)

            // Dots laid out in rows of 5 — mirrors the ten-frame structure
            // so the child can subitize each group at a glance.
            let rows = dotRows(count: count, capacity: target)
            VStack(spacing: 6) {
                ForEach(rows.indices, id: \.self) { rowIndex in
                    HStack(spacing: 6) {
                        ForEach(rows[rowIndex].indices, id: \.self) { dotIndex in
                            let isFilled = rows[rowIndex][dotIndex]
                            Circle()
                                .fill(isFilled ? fill : fill.opacity(0.15))
                                .overlay(
                                    Circle().strokeBorder(fill.opacity(isFilled ? 0.2 : 0.35), lineWidth: 1.5)
                                )
                                .frame(minWidth: 28, minHeight: 28)
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
        .frame(maxWidth: .infinity)
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
