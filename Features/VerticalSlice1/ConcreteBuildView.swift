import SwiftUI

struct ConcreteBuildView: View {
    let target: Int
    let concreteCount: Int
    let onAdjust: (Int) -> Void
    let onSubmit: () -> Void

    // Ten-frame is always 5 columns × 2 rows — this fixed 2×5 structure is
    // what enables subitizing (e.g. "7 = full row of 5 + 2 more").
    // Circle size scales with available space; the column count is invariant.
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 5)

    var body: some View {
        CardSurface {
            VStack(alignment: .leading, spacing: 18) {
                Text("Make \(target)")
                    .font(.largeTitle.weight(.black))
                Text("Tap a counter or use the buttons to build the target.")
                    .font(.headline)
                    .foregroundStyle(.secondary)

                // Always 10 slots visible: filled slots show as accent circles,
                // empty slots remain as faint outlines so the ten-frame structure
                // is always clear and subitizing is always possible.
                LazyVGrid(columns: columns, spacing: 8) {
                    ForEach(0..<10, id: \.self) { index in
                        Circle()
                            .fill(index < concreteCount ? MatherTheme.accent : MatherTheme.softBlue.opacity(0.15))
                            .overlay {
                                Circle().stroke(
                                    index < concreteCount ? Color.white : MatherTheme.softBlue.opacity(0.5),
                                    lineWidth: 2
                                )
                            }
                            .aspectRatio(1, contentMode: .fit)
                            .frame(minWidth: 44, minHeight: 44)
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
