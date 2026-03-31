import SwiftUI

enum MatherTheme {
    static let background = Color(red: 0.97, green: 0.95, blue: 0.89)
    static let card = Color.white
    static let ink = Color(red: 0.14, green: 0.16, blue: 0.18)
    static let accent = Color(red: 0.14, green: 0.48, blue: 0.35)
    static let warm = Color(red: 0.97, green: 0.68, blue: 0.31)
    static let danger = Color(red: 0.79, green: 0.33, blue: 0.28)
    static let softBlue = Color(red: 0.64, green: 0.82, blue: 0.97)
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
            .font(.title2.weight(.bold))
            .foregroundStyle(MatherTheme.ink)
            .frame(maxWidth: .infinity, minHeight: 88)
            .background(configuration.isPressed ? fill.opacity(0.8) : fill)
            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
    }
}
