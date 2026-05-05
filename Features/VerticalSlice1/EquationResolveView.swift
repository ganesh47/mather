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

    @SceneStorage("equationResolveSelectedSide") private var selectedSideRaw = EquationSide.left.rawValue

    private var selectedSide: EquationSide {
        get { EquationSide(rawValue: selectedSideRaw) ?? .left }
        nonmutating set { selectedSideRaw = newValue.rawValue }
    }

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 4)

    var body: some View {
        CardSurface {
            VStack(alignment: .leading, spacing: 12) {
                Text("Write it")
                    .font(.title.weight(.black))
                Text(theme.abstractPrompt())
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                    .minimumScaleFactor(0.85)

                ViewThatFits {
                    HStack(spacing: 10) {
                        entryCard(title: "Part 1", value: leftInput, side: .left)
                        Text("+").font(.title.weight(.black))
                        entryCard(title: "Part 2", value: rightInput, side: .right)
                        Text("=").font(.title.weight(.black))
                        Text("\(target)")
                            .font(.system(size: 32, weight: .black, design: .rounded))
                    }
                    VStack(spacing: 8) {
                        HStack(spacing: 10) {
                            entryCard(title: "Part 1", value: leftInput, side: .left)
                            Text("+").font(.title2.weight(.black))
                            entryCard(title: "Part 2", value: rightInput, side: .right)
                        }
                        HStack(spacing: 10) {
                            Text("=").font(.title2.weight(.black))
                            Text("\(target)")
                                .font(.system(size: 34, weight: .black, design: .rounded))
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }

                LazyVGrid(columns: columns, spacing: 8) {
                    ForEach(0...10, id: \.self) { digit in
                        keypadButton(digit)
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

    private func keypadButton(_ digit: Int) -> some View {
        Button("\(digit)") {
            onAppend(digit, selectedSide)
        }
        .font(.title3.weight(.bold))
        .foregroundStyle(MatherTheme.ink)
        .frame(maxWidth: .infinity, minHeight: 56)
        .background(selectedSide == .left ? MatherTheme.softBlue.opacity(0.75) : MatherTheme.warm.opacity(0.75))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(
                    colorScheme == .dark ? .white.opacity(0.08) : .clear,
                    lineWidth: 1
                )
        )
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .accessibilityIdentifier("equation-digit-\(digit)")
    }

    private func entryCard(title: String, value: String, side: EquationSide) -> some View {
        Button {
            selectedSide = side
        } label: {
            VStack(spacing: 6) {
                Text(title)
                    .font(.subheadline.weight(.bold))
                ZStack(alignment: .topTrailing) {
                    VStack(spacing: 4) {
                        Text(value.isEmpty ? "?" : value)
                            .font(.system(size: 30, weight: .black, design: .rounded))
                            .frame(maxWidth: .infinity, minHeight: 60)
                            .background(selectedSide == side ? MatherTheme.accent.opacity(colorScheme == .dark ? 0.30 : 0.20) : MatherTheme.softBlue.opacity(colorScheme == .dark ? 0.32 : 0.25))
                            .overlay(
                                RoundedRectangle(cornerRadius: 18, style: .continuous)
                                    .strokeBorder(
                                        selectedSide == side
                                            ? MatherTheme.accent.opacity(colorScheme == .dark ? 0.95 : 0.78)
                                            : MatherTheme.panelDeep.opacity(colorScheme == .dark ? 0.65 : 0),
                                        lineWidth: selectedSide == side ? 3 : 1
                                    )
                            )
                            .overlay(alignment: .bottom) {
                                if selectedSide == side {
                                    Capsule()
                                        .fill(MatherTheme.accent)
                                        .frame(width: 34, height: 4)
                                        .offset(y: -6)
                                }
                            }
                            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))

                        if selectedSide == side {
                            Label("typing here", systemImage: "arrow.up")
                                .font(.caption2.weight(.black))
                                .foregroundStyle(MatherTheme.accent)
                                .accessibilityIdentifier("equation-active-side-indicator")
                        }
                    }
                    if !value.isEmpty {
                        Button {
                            onClear(side)
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(.secondary)
                                .font(.footnote.weight(.bold))
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
