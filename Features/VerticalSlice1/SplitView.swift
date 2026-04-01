import SwiftUI

struct SplitView: View {
    let target: Int
    let leftCount: Int
    let onAdjust: (Int) -> Void
    let onSubmit: () -> Void

    private var rightCount: Int { target - leftCount }

    var body: some View {
        CardSurface {
            VStack(alignment: .leading, spacing: 18) {
                Text("Break \(target)")
                    .font(.largeTitle.weight(.black))
                Text("Move counters between the two buckets.")
                    .font(.headline)
                    .foregroundStyle(.secondary)

                ViewThatFits {
                    HStack(spacing: 16) {
                        bucket(title: "Left", count: leftCount, capacity: target, fill: MatherTheme.softBlue, delta: 1)
                        bucket(title: "Right", count: rightCount, capacity: target, fill: MatherTheme.warm.opacity(0.9), delta: -1)
                    }
                    VStack(spacing: 16) {
                        bucket(title: "Left", count: leftCount, capacity: target, fill: MatherTheme.softBlue, delta: 1)
                        bucket(title: "Right", count: rightCount, capacity: target, fill: MatherTheme.warm.opacity(0.9), delta: -1)
                    }
                }
                .gesture(
                    DragGesture(minimumDistance: 30)
                        .onEnded { value in
                            if value.translation.width < 0 {
                                onAdjust(-1)
                            } else {
                                onAdjust(1)
                            }
                        }
                )

                HStack(spacing: 16) {
                    Button("Move Left") { onAdjust(1) }
                        .buttonStyle(SecondaryTileButtonStyle(fill: MatherTheme.softBlue.opacity(0.8)))
                    Button("Move Right") { onAdjust(-1) }
                        .buttonStyle(SecondaryTileButtonStyle(fill: MatherTheme.warm.opacity(0.8)))
                }

                Button("Use this break") {
                    onSubmit()
                }
                .buttonStyle(PrimaryActionButtonStyle())
            }
        }
    }

    private func bucket(title: String, count: Int, capacity: Int, fill: Color, delta: Int) -> some View {
        VStack(spacing: 12) {
            Text(title)
                .font(.title2.weight(.bold))
            Text("\(count)")
                .font(.system(size: 44, weight: .black, design: .rounded))
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(fill.opacity(0.25))
                .overlay {
                    LazyVGrid(
                        columns: Array(repeating: GridItem(.flexible(), spacing: 6), count: 5),
                        spacing: 6
                    ) {
                        ForEach(0..<capacity, id: \.self) { index in
                            Circle()
                                .fill(index < count ? fill : fill.opacity(0.15))
                                .overlay {
                                    Circle().stroke(fill.opacity(0.4), lineWidth: 1.5)
                                }
                                .aspectRatio(1, contentMode: .fit)
                        }
                    }
                    .padding(12)
                }
                .frame(maxWidth: .infinity, minHeight: 100)
                .onTapGesture {
                    onAdjust(delta)
                }
        }
        .frame(maxWidth: .infinity)
    }
}
