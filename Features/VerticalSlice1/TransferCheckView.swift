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

                // Each circle is directly tappable — tapping circle at index i sets
                // the count to i+1, matching the ten-frame interaction in ConcreteBuildView.
                // Less/More buttons removed: direct tap is simpler and more intuitive.
                LazyVGrid(
                    columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 5),
                    spacing: 10
                ) {
                    ForEach(0..<problem.target, id: \.self) { index in
                        Circle()
                            .fill(index < transferCount ? MatherTheme.accent : MatherTheme.softBlue.opacity(0.25))
                            .frame(minHeight: 52)
                            .onTapGesture {
                                onAdjust((index + 1) - transferCount)
                            }
                    }
                }

                Button("I rebuilt it") {
                    onSubmit()
                }
                .buttonStyle(PrimaryActionButtonStyle())
            }
        }
    }
}
