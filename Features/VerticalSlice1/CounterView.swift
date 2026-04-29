import SwiftUI

/// A single counter cell in the 2×5 ten-frame grid.
///
/// Renders as a filled/empty circle (ClassicTheme) or a local generated theme asset
/// with SF Symbol fallback depending on the active theme's `counterKind`.
/// The 2×5 grid structure is preserved regardless of theme — subitising
/// depends on spatial arrangement, not object shape (Clements, 2002).
///
/// Row colouring: index 0-4 → warm amber (first row), index 5-9 → vivid
/// accent (second row). Two-tone structure lets the child instantly see
/// "5 + N" without counting.
struct CounterView: View {
    let index: Int      // 0-based position in the ten-frame (0–9)
    let filled: Bool
    let theme: any SliceTheme
    /// When set, overrides the default index-based warm/accent two-tone colouring.
    /// Used by SplitView buckets where each bucket has its own fixed palette colour.
    var overrideColor: Color? = nil

    private var isFirstRow: Bool { index < 5 }

    private var filledColor: Color {
        overrideColor ?? (isFirstRow ? MatherTheme.warm : MatherTheme.accent)
    }

    var body: some View {
        Color.clear
            .aspectRatio(1, contentMode: .fit)
            .overlay(counterShape)
    }

    @ViewBuilder
    private var counterShape: some View {
        switch theme.counterKind {
        case .circle:
            circleCounter
        case .themedSymbol(let symbolName, let assetName):
            themedCounter(symbolName: symbolName, assetName: assetName)
        }
    }

    private var circleCounter: some View {
        let base = overrideColor ?? (isFirstRow ? MatherTheme.warm : MatherTheme.accent)
        let bgOpacity: Double = isFirstRow ? 0.12 : 0.10
        let strokeOpacity: Double = isFirstRow ? 0.55 : 0.45
        let bgColor: Color = base.opacity(filled ? 0 : bgOpacity)
        let strokeColor: Color = base.opacity(filled ? 0 : strokeOpacity)

        return Circle()
            .fill(filled ? base : bgColor)
            .overlay(
                Circle()
                    .strokeBorder(filled ? base.opacity(0.3) : strokeColor, lineWidth: 2.5)
            )
            .shadow(color: filled ? base.opacity(0.35) : .clear, radius: 4, y: 2)
    }

    @ViewBuilder
    private func themedCounter(symbolName: String, assetName: String?) -> some View {
        if filled {
            ZStack {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(filledColor.opacity(0.12))

                if let assetName {
                    Image(assetName)
                        .resizable()
                        .renderingMode(.original)
                        .scaledToFit()
                        .padding(4)
                } else {
                    Image(systemName: symbolName)
                        .resizable()
                        .scaledToFit()
                        .foregroundStyle(filledColor)
                        .padding(6)
                }
            }
        } else {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .strokeBorder(
                    Color.secondary.opacity(0.3),
                    style: StrokeStyle(lineWidth: 1.5, dash: [4])
                )
                .padding(4)
        }
    }
}
