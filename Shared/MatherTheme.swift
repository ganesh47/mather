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
    @Environment(\.colorScheme) private var colorScheme
    @ViewBuilder let content: Content

    var body: some View {
        content
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(MatherTheme.card)
            .overlay(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .strokeBorder(
                        colorScheme == .dark
                            ? MatherTheme.panelDeep.opacity(0.75)
                            : MatherTheme.panelDeep.opacity(0.16),
                        lineWidth: 1
                    )
            )
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            .shadow(color: Color("MatherCardShadow"), radius: colorScheme == .dark ? 16 : 10, y: colorScheme == .dark ? 6 : 4)
    }
}

struct DarkModeCTAOverlay: View {
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        RoundedRectangle(cornerRadius: 22, style: .continuous)
            .strokeBorder(.white.opacity(colorScheme == .dark ? 0.16 : 0), lineWidth: 1)
            .overlay(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: colorScheme == .dark
                                ? [.white.opacity(0.10), .clear]
                                : [.white.opacity(0.12), .clear],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
            )
            .blendMode(.screen)
    }
}

struct PrimaryActionButtonStyle: ButtonStyle {
    @Environment(\.colorScheme) private var colorScheme
    var verticalPadding: CGFloat = 20
    var font: Font = .title3.weight(.bold)

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(font)
            .foregroundStyle(.white)
            .padding(.vertical, verticalPadding)
            .frame(maxWidth: .infinity)
            .background(configuration.isPressed ? MatherTheme.accent.opacity(0.84) : MatherTheme.accent)
            .overlay(DarkModeCTAOverlay())
            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
            .shadow(
                color: colorScheme == .dark ? MatherTheme.accent.opacity(0.28) : .clear,
                radius: colorScheme == .dark ? 14 : 0,
                y: colorScheme == .dark ? 6 : 0
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

struct SecondaryTileButtonStyle: ButtonStyle {
    @Environment(\.colorScheme) private var colorScheme
    var fill: Color = MatherTheme.softBlue
    var minHeight: CGFloat = 88
    var font: Font = .headline.weight(.bold)

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(font)
            .foregroundStyle(MatherTheme.ink)
            .frame(maxWidth: .infinity, minHeight: minHeight)
            .background(configuration.isPressed ? fill.opacity(0.8) : fill)
            .overlay(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .strokeBorder(
                        colorScheme == .dark ? .white.opacity(0.10) : .clear,
                        lineWidth: 1
                    )
            )
            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
            .shadow(
                color: colorScheme == .dark ? fill.opacity(0.16) : .clear,
                radius: colorScheme == .dark ? 10 : 0,
                y: colorScheme == .dark ? 4 : 0
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
    }
}
