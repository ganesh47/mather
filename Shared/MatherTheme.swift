import SwiftUI

enum MatherTheme {
    static let background = Color(red: 0.97, green: 0.95, blue: 0.89)
    static let card = Color.white
    static let ink = Color(red: 0.14, green: 0.16, blue: 0.18)
    // Vivid emerald — was a muted forest green; children need high-contrast, saturated colours
    static let accent = Color(red: 0.09, green: 0.71, blue: 0.44)
    // Vivid amber — was too muted; this reads clearly on pale cream background
    static let warm = Color(red: 1.0, green: 0.62, blue: 0.07)
    static let danger = Color(red: 0.88, green: 0.23, blue: 0.20)
    // Rich sky blue — was too pale (0.64/0.82/0.97 barely distinguishable from white)
    static let softBlue = Color(red: 0.22, green: 0.67, blue: 0.97)
    // Coral — celebration and transfer stage; distinct from green and amber
    static let coral = Color(red: 0.98, green: 0.38, blue: 0.33)
}

struct CardSurface<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        content
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(MatherTheme.card)
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            .shadow(color: .black.opacity(0.06), radius: 10, y: 4)
    }
}

struct PrimaryActionButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.title3.weight(.bold))
            .foregroundStyle(.white)
            .padding(.vertical, 20)
            .frame(maxWidth: .infinity)
            .background(configuration.isPressed ? MatherTheme.accent.opacity(0.8) : MatherTheme.accent)
            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

struct SecondaryTileButtonStyle: ButtonStyle {
    var fill: Color = MatherTheme.softBlue

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline.weight(.bold))
            .foregroundStyle(MatherTheme.ink)
            .frame(maxWidth: .infinity, minHeight: 88)
            .background(configuration.isPressed ? fill.opacity(0.8) : fill)
            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
    }
}
