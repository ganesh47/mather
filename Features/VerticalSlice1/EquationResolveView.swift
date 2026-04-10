import SwiftUI

struct EquationResolveView: View {
    @Environment(\.colorScheme) private var colorScheme
    let target: Int
    let leftInput: String
    let rightInput: String
    let onAppend: (Int, EquationSide) -> Void
    let onClear: (EquationSide) -> Void
    let onSubmit: () -> Void
    var showsInlineSubmit = true
    var theme: any SliceTheme = ClassicTheme()

    @State private var selectedSide: EquationSide = .left

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 12), count: 3)

    var body: some View {
        CardSurface {
            VStack(alignment: .leading, spacing: 18) {
                Text("Write it")
                    .font(.largeTitle.weight(.black))
                Text(theme.abstractPrompt())
                    .font(.headline)
                    .foregroundStyle(.secondary)

                ViewThatFits {
                    HStack(spacing: 12) {
                        entryCard(title: "Part 1", value: leftInput, side: .left)
                        Text("+").font(.largeTitle.weight(.black))
                        entryCard(title: "Part 2", value: rightInput, side: .right)
                        Text("=").font(.largeTitle.weight(.black))
                        Text("\(target)")
                            .font(.system(size: 42, weight: .black, design: .rounded))
                    }
                    VStack(spacing: 10) {
                        HStack(spacing: 12) {
                            entryCard(title: "Part 1", value: leftInput, side: .left)
                            Text("+").font(.title.weight(.black))
                            entryCard(title: "Part 2", value: rightInput, side: .right)
                        }
                        HStack(spacing: 12) {
                            Text("=").font(.title.weight(.black))
                            Text("\(target)")
                                .font(.system(size: 36, weight: .black, design: .rounded))
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }

                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(0...10, id: \.self) { digit in
                        Button("\(digit)") {
                            onAppend(digit, selectedSide)
                        }
                        .buttonStyle(SecondaryTileButtonStyle(fill: selectedSide == .left ? MatherTheme.softBlue.opacity(0.75) : MatherTheme.warm.opacity(0.75)))
                    }
                }

                if showsInlineSubmit {
                    Button("Check equation") {
                        onSubmit()
                    }
                    .buttonStyle(PrimaryActionButtonStyle())
                }
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
                ZStack(alignment: .topTrailing) {
                    Text(value.isEmpty ? "?" : value)
                        .font(.system(size: 40, weight: .black, design: .rounded))
                        .frame(maxWidth: .infinity, minHeight: 84)
                        .background(selectedSide == side ? MatherTheme.accent.opacity(colorScheme == .dark ? 0.28 : 0.18) : MatherTheme.softBlue.opacity(colorScheme == .dark ? 0.32 : 0.25))
                        .overlay(
                            RoundedRectangle(cornerRadius: 20, style: .continuous)
                                .strokeBorder(
                                    selectedSide == side
                                        ? .white.opacity(colorScheme == .dark ? 0.12 : 0)
                                        : MatherTheme.panelDeep.opacity(colorScheme == .dark ? 0.65 : 0),
                                    lineWidth: 1
                                )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                    // Inline clear — always reachable, no scrolling needed
                    if !value.isEmpty {
                        Button {
                            onClear(side)
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(.secondary)
                                .font(.title3)
                        }
                        .buttonStyle(.plain)
                        .padding(8)
                    }
                }
            }
        }
        .buttonStyle(.plain)
    }
}
