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
                        bucket(title: "Left", count: leftCount, fill: MatherTheme.softBlue)
                        bucket(title: "Right", count: rightCount, fill: MatherTheme.warm.opacity(0.9))
                    }
                    VStack(spacing: 16) {
                        bucket(title: "Left", count: leftCount, fill: MatherTheme.softBlue)
                        bucket(title: "Right", count: rightCount, fill: MatherTheme.warm.opacity(0.9))
                    }
                }

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

    private func bucket(title: String, count: Int, fill: Color) -> some View {
        VStack(spacing: 12) {
            Text(title)
                .font(.title2.weight(.bold))
            Text("\(count)")
                .font(.system(size: 44, weight: .black, design: .rounded))
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(fill)
                .frame(maxWidth: .infinity, minHeight: 120)
                .overlay {
                    Text(String(repeating: "● ", count: max(count, 1)))
                        .lineLimit(3)
                        .minimumScaleFactor(0.5)
                        .padding()
                }
        }
        .frame(maxWidth: .infinity)
    }
}
