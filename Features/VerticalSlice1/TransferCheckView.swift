import SwiftUI

struct TransferCheckView: View {
    let problem: SliceProblem
    let transferCount: Int
    let onAdjust: (Int) -> Void
    let onSubmit: () -> Void

    var body: some View {
        CardSurface {
            VStack(alignment: .leading, spacing: 18) {
                Text("Show it again")
                    .font(.largeTitle.weight(.black))
                Text("\(problem.decompositionA) + \(problem.decompositionB) = \(problem.target)")
                    .font(.title.weight(.bold))
                Text("Now rebuild the whole number with counters.")
                    .font(.headline)
                    .foregroundStyle(.secondary)

                LazyVGrid(
                    columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 5),
                    spacing: 10
                ) {
                    ForEach(0..<problem.target, id: \.self) { index in
                        Circle()
                            .fill(index < transferCount ? MatherTheme.accent : MatherTheme.softBlue.opacity(0.25))
                            .frame(minHeight: 80)
                    }
                }

                HStack(spacing: 16) {
                    Button("Less") { onAdjust(-1) }
                        .buttonStyle(SecondaryTileButtonStyle(fill: MatherTheme.softBlue.opacity(0.7)))
                    Button("More") { onAdjust(1) }
                        .buttonStyle(SecondaryTileButtonStyle(fill: MatherTheme.warm.opacity(0.8)))
                }

                Button("I rebuilt it") {
                    onSubmit()
                }
                .buttonStyle(PrimaryActionButtonStyle())
            }
        }
    }
}
