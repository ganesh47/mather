import SwiftUI

struct SplitView: View {
    let target: Int
    let leftCount: Int
    let onAdjust: (Int) -> Void
    let onSubmit: () -> Void
    var theme: any SliceTheme = ClassicTheme()
    /// When true, the split is pre-set and not user-adjustable.
    /// Hides the drag affordance and shows a "collected" badge.
    var isLocked: Bool = false

    @State private var showDragHint = false

    private var rightCount: Int { target - leftCount }
    private var splitHeading: String { "Split \(target) \(theme.counterNoun)" }

    var body: some View {
        CardSurface {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(splitHeading)
                        .font(.title.weight(.black))
                        .foregroundStyle(MatherTheme.softBlue)
                        .lineLimit(2)
                        .minimumScaleFactor(0.78)
                    Text("Drag or tap to choose two parts")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)
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
                        },
                    including: isLocked ? .none : .all
                )

                if isLocked {
                    // Show a read-only badge so it's clear tapping won't change the split.
                    Label("From your walk", systemImage: "figure.walk")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(MatherTheme.accent.opacity(0.8))
                        .frame(maxWidth: .infinity, alignment: .center)
                } else {
                    // Swipe affordance — left/right chevrons hint at the drag gesture.
                    // Tap on each bucket also adjusts the split (no reading required).
                    HStack(spacing: 10) {
                        Image(systemName: "chevron.left")
                        Text("Drag to split")
                            .font(.caption.weight(.black))
                        Image(systemName: "chevron.right")
                    }
                    .font(.footnote.weight(.bold))
                    .foregroundStyle(MatherTheme.softBlue.opacity(0.72))
                    .frame(maxWidth: .infinity)
                    .offset(x: showDragHint ? 14 : -14)
                    .animation(.easeInOut(duration: 0.55).repeatCount(3, autoreverses: true), value: showDragHint)
                    .onAppear { showDragHint = true }
                    .accessibilityIdentifier("split-view-drag-hint")
                }

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
        .accessibilityLabel("\(count) of \(target)")
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

    // Lay out filled dots in rows of 5. Very large story targets can otherwise
    // create 7+ rows per bucket on phone screens; cap the visual scaffold at
    // 20 slots and keep the exact amount in the large numeric label above.
    private func dotRows(count: Int, capacity: Int) -> [[Bool]] {
        let total = min(max(capacity, 1), 20)
        var rows: [[Bool]] = []
        var remaining = total
        var filled = min(count, total)
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
