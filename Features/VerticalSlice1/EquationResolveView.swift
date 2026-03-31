import SwiftUI

struct EquationResolveView: View {
    let target: Int
    let leftInput: String
    let rightInput: String
    let onAppend: (Int, EquationSide) -> Void
    let onClear: (EquationSide) -> Void
    let onSubmit: () -> Void

    @State private var selectedSide: EquationSide = .left

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 12), count: 3)

    var body: some View {
        CardSurface {
            VStack(alignment: .leading, spacing: 18) {
                Text("Write it")
                    .font(.largeTitle.weight(.black))
                Text("Show the same split as an equation that equals \(target).")
                    .font(.headline)
                    .foregroundStyle(.secondary)

                HStack(spacing: 12) {
                    entryCard(title: "Part 1", value: leftInput, side: .left)
                    Text("+").font(.largeTitle.weight(.black))
                    entryCard(title: "Part 2", value: rightInput, side: .right)
                    Text("=").font(.largeTitle.weight(.black))
                    Text("\(target)")
                        .font(.system(size: 42, weight: .black, design: .rounded))
                }

                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(0...10, id: \.self) { digit in
                        Button("\(digit)") {
                            onAppend(digit, selectedSide)
                        }
                        .buttonStyle(SecondaryTileButtonStyle(fill: selectedSide == .left ? MatherTheme.softBlue.opacity(0.75) : MatherTheme.warm.opacity(0.75)))
                    }
                }

                HStack(spacing: 16) {
                    Button("Clear left") { onClear(.left) }
                        .buttonStyle(SecondaryTileButtonStyle(fill: MatherTheme.softBlue.opacity(0.6)))
                    Button("Clear right") { onClear(.right) }
                        .buttonStyle(SecondaryTileButtonStyle(fill: MatherTheme.warm.opacity(0.6)))
                }

                Button("Check equation") {
                    onSubmit()
                }
                .buttonStyle(PrimaryActionButtonStyle())
            }
        }
    }

    private func entryCard(title: String, value: String, side: EquationSide) -> some View {
        Button {
            selectedSide = side
        } label: {
            VStack(spacing: 8) {
                Text(title)
                    .font(.headline)
                Text(value.isEmpty ? "?" : value)
                    .font(.system(size: 40, weight: .black, design: .rounded))
                    .frame(maxWidth: .infinity, minHeight: 84)
                    .background(selectedSide == side ? MatherTheme.accent.opacity(0.18) : MatherTheme.softBlue.opacity(0.25))
                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            }
        }
        .buttonStyle(.plain)
    }
}
