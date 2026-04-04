import SwiftUI

/// A single counter cell in the 2×5 ten-frame grid.
///
/// Renders as a filled/empty circle (ClassicTheme) or a car SF Symbol
/// (VehicleTheme) depending on the active theme's `counterKind`.
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

    private var isFirstRow: Bool { index < 5 }

    private var filledColor: Color {
        isFirstRow ? MatherTheme.warm : MatherTheme.accent
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
        case .vehicle(let symbolName):
            vehicleCounter(symbolName: symbolName)
        }
    }

    private var circleCounter: some View {
        let fillColor: Color = filled ? filledColor : .clear
        let bgColor: Color = isFirstRow
            ? MatherTheme.warm.opacity(filled ? 0 : 0.12)
            : MatherTheme.accent.opacity(filled ? 0 : 0.10)
        let strokeColor: Color = isFirstRow
            ? MatherTheme.warm.opacity(filled ? 0 : 0.55)
            : MatherTheme.accent.opacity(filled ? 0 : 0.45)

        return Circle()
            .fill(filled ? fillColor : bgColor)
            .overlay(
                Circle()
                    .strokeBorder(filled ? fillColor.opacity(0.3) : strokeColor, lineWidth: 2.5)
            )
            .shadow(color: filled ? fillColor.opacity(0.35) : .clear, radius: 4, y: 2)
    }

    @ViewBuilder
    private func vehicleCounter(symbolName: String) -> some View {
        let color: Color = filled ? filledColor : Color.secondary.opacity(0.25)
        Image(systemName: symbolName)
            .resizable()
            .scaledToFit()
            .foregroundStyle(color)
            .padding(6)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(filled ? filledColor.opacity(0.12) : Color.secondary.opacity(0.07))
            )
    }
}
