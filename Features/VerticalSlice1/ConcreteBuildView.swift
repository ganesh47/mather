import SwiftUI

struct ConcreteBuildView: View {
    let target: Int
    let concreteCount: Int
    let onAdjust: (Int) -> Void
    let onSubmit: () -> Void

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 12), count: 5)

    var body: some View {
        CardSurface {
            VStack(alignment: .leading, spacing: 18) {
                Text("Make \(target)")
                    .font(.largeTitle.weight(.black))
                Text("Tap a counter or use the buttons to build the target.")
                    .font(.headline)
                    .foregroundStyle(.secondary)

                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(0..<10, id: \.self) { index in
                        Circle()
                            .fill(index < concreteCount ? MatherTheme.accent : MatherTheme.softBlue.opacity(0.3))
                            .frame(minHeight: 82)
                            .overlay {
                                Circle().stroke(Color.white, lineWidth: 3)
                            }
                            .onTapGesture {
                                let tapped = index + 1
                                onAdjust(tapped - concreteCount)
                            }
                    }
                }

                HStack(spacing: 16) {
                    Button {
                        onAdjust(-1)
                    } label: {
                        Label("Remove", systemImage: "minus.circle.fill")
                    }
                    .buttonStyle(SecondaryTileButtonStyle(fill: MatherTheme.softBlue.opacity(0.7)))

                    Button {
                        onAdjust(1)
                    } label: {
                        Label("Add", systemImage: "plus.circle.fill")
                    }
                    .buttonStyle(SecondaryTileButtonStyle(fill: MatherTheme.warm.opacity(0.8)))
                }

                Button("That is \(target)") {
                    onSubmit()
                }
                .buttonStyle(PrimaryActionButtonStyle())
            }
        }
    }
}
