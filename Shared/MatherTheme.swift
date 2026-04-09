import SwiftUI

enum MatherTheme {
    // MARK: - Semantic color tokens
    // Each name maps to a named color set in App/Assets.xcassets with both
    // Any (light) and Dark appearance variants. SwiftUI resolves the correct
    // variant automatically from @Environment(\.colorScheme).

    /// App/screen background — cream in light, warm near-black in dark
    static let background   = Color("MatherBackground")
    /// CardSurface fill — white in light, warm dark grey in dark
    static let card         = Color("MatherCard")
    /// Primary text — near-black in light, warm off-white in dark
    static let ink          = Color("MatherInk")
    /// Secondary text on CardSurface — ink at 65% light / 70% dark opacity
    static let cardSubtitle = Color("MatherCardSubtitle")
    /// Primary action, success — vivid emerald, slightly lighter in dark
    static let accent       = Color("MatherAccent")
    /// Counters row 1, warm states — vivid amber, slightly lighter in dark
    static let warm         = Color("MatherWarm")
    /// Destructive actions — red, slightly lighter in dark
    static let danger       = Color("MatherDanger")
    /// Info, secondary buttons — sky blue, slightly lighter in dark
    static let softBlue     = Color("MatherSoftBlue")
    /// Celebration — coral, slightly lighter in dark
    static let coral        = Color("MatherCoral")
    /// VS1 panel surface — warm cream panel in light, warm dark panel in dark
    static let panel        = Color("MatherPanel")
    /// VS1 panel border/stroke — amber-cream in light, warm dark border in dark
    static let panelDeep    = Color("MatherPanelDeep")
}

struct CardSurface<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        content
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(MatherTheme.card)
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            .shadow(color: Color("MatherCardShadow"), radius: 10, y: 4)
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
