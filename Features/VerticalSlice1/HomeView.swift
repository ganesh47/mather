import SwiftUI

struct HomeView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Bindable var appModel: AppModel

    var body: some View {
        ZStack {
            MatherTheme.background.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 20) {
                    Text("Mather")
                        .font(.system(size: 48, weight: .black, design: .rounded))
                        .foregroundStyle(MatherTheme.ink)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    makeAndBreakCard

                    HStack(alignment: .top, spacing: ResponsiveLayout.isWide(horizontalSizeClass) ? 20 : 14) {
                        labsCard
                        gamesCard
                    }

                    HStack(spacing: 14) {
                        Button("Parent Summary") {
                            appModel.engine.showParentSummary()
                        }
                        .buttonStyle(SecondaryTileButtonStyle(fill: MatherTheme.warm.opacity(0.65)))

                        Button("Settings") {
                            appModel.engine.showSettings()
                        }
                        .buttonStyle(SecondaryTileButtonStyle(fill: MatherTheme.softBlue.opacity(0.55)))
                    }

                    Spacer(minLength: 0)
                }
                .padding(ResponsiveLayout.contentPadding(for: horizontalSizeClass))
                .frame(maxWidth: ResponsiveLayout.contentMaxWidth(for: horizontalSizeClass))
                .frame(maxWidth: .infinity)
            }
        }
    }

    // MARK: - Make & Break card

    private var makeAndBreakCard: some View {
        Button {
            appModel.pickProfileThenRun { appModel.engine.showSessionConfig() }
        } label: {
            VStack(spacing: 0) {
                ZStack {
                    LinearGradient(
                        colors: [MatherTheme.warm, MatherTheme.accent],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )

                    HStack(spacing: 16) {
                        // Mini ten-frame preview
                        VStack(spacing: 5) {
                            ForEach(0..<2, id: \.self) { row in
                                HStack(spacing: 5) {
                                    ForEach(0..<5, id: \.self) { col in
                                        let idx = row * 5 + col
                                        Circle()
                                            .fill(idx < 7 ? Color.white : Color.white.opacity(0.3))
                                            .frame(width: 18, height: 18)
                                    }
                                }
                            }
                        }

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Make & Break")
                                .font(.title3.weight(.black))
                                .foregroundStyle(.white)
                            Text("Targets")
                                .font(.system(size: 36, weight: .black, design: .rounded))
                                .foregroundStyle(.white)
                        }
                        .layoutPriority(1)

                        Spacer()
                    }
                    .padding(20)
                }
                .frame(height: 110)
                .clipShape(
                    UnevenRoundedRectangle(
                        topLeadingRadius: 20, bottomLeadingRadius: 0,
                        bottomTrailingRadius: 0, topTrailingRadius: 20,
                        style: .continuous
                    )
                )

                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Ready to play?")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.secondary)
                        Text("Tap to start a session")
                            .font(.headline.weight(.bold))
                            .foregroundStyle(MatherTheme.ink)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    Spacer()
                    Image(systemName: "play.circle.fill")
                        .font(.system(size: 44))
                        .foregroundStyle(MatherTheme.accent)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .background(MatherTheme.card)
                .clipShape(
                    UnevenRoundedRectangle(
                        topLeadingRadius: 0, bottomLeadingRadius: 20,
                        bottomTrailingRadius: 20, topTrailingRadius: 0,
                        style: .continuous
                    )
                )
            }
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .strokeBorder(.white.opacity(colorScheme == .dark ? 0.08 : 0), lineWidth: 1)
            )
            .shadow(
                color: colorScheme == .dark ? MatherTheme.coral.opacity(0.12) : .black.opacity(0.08),
                radius: colorScheme == .dark ? 18 : 12,
                y: colorScheme == .dark ? 8 : 5
            )
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity)
        .accessibilityIdentifier("Play")
    }

    private var lockedActivityCard: some View {
        CardSurface {
            VStack(alignment: .leading, spacing: 14) {
                Text("Make & Break")
                    .font(.title2.weight(.bold))
                Text("Enable the activity in Settings before handing the iPad to your child.")
                    .font(.headline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    // MARK: - Labs and Games cards

    private var labsCard: some View {
        explorerEntryCard(
            title: "Labs",
            subtitle: "Subject streams",
            detail: "Numbers · Geometry · Physics",
            emoji: "🔬",
            symbolName: "sparkles.rectangle.stack.fill",
            gradient: [MatherTheme.softBlue, MatherTheme.coral.opacity(0.8)],
            accent: MatherTheme.softBlue,
            accessibilityIdentifier: "ExplorerLab"
        ) {
            appModel.engine.showLab()
        }
    }

    private var gamesCard: some View {
        explorerEntryCard(
            title: "Games",
            subtitle: "One-tap play",
            detail: "Launch games directly",
            emoji: "🎮",
            symbolName: "gamecontroller.fill",
            gradient: [MatherTheme.warm, MatherTheme.accent.opacity(0.85)],
            accent: MatherTheme.warm,
            accessibilityIdentifier: "GamesEntry"
        ) {
            appModel.engine.showLabGames()
        }
    }

    private func explorerEntryCard(
        title: String,
        subtitle: String,
        detail: String,
        emoji: String,
        symbolName: String,
        gradient: [Color],
        accent: Color,
        accessibilityIdentifier: String,
        action: @escaping () -> Void
    ) -> some View {
        HomeExplorerEntryCard(
            title: title,
            subtitle: subtitle,
            detail: detail,
            emoji: emoji,
            symbolName: symbolName,
            gradient: gradient,
            accent: accent,
            accessibilityIdentifier: accessibilityIdentifier,
            isDark: colorScheme == .dark,
            action: action
        )
    }

}

private struct HomeExplorerEntryCard: View {
    let title: String
    let subtitle: String
    let detail: String
    let emoji: String
    let symbolName: String
    let gradient: [Color]
    let accent: Color
    let accessibilityIdentifier: String
    let isDark: Bool
    let action: () -> Void

    private var destinationLabel: String {
        title == "Labs" ? "Open subject picker" : "Open game launcher"
    }

    private var accessibilityCopy: String {
        title == "Labs" ? "Open Labs subject streams" : "Open Games direct launcher"
    }

    var body: some View {
        Button(action: action) {
            VStack(spacing: 0) {
                header
                footer
            }
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .strokeBorder(.white.opacity(isDark ? 0.08 : 0), lineWidth: 1)
            )
            .shadow(
                color: isDark ? accent.opacity(0.12) : .black.opacity(0.08),
                radius: isDark ? 18 : 12,
                y: isDark ? 8 : 5
            )
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity)
        .accessibilityIdentifier(accessibilityIdentifier)
        .accessibilityLabel(accessibilityCopy)
    }

    private var header: some View {
        ZStack {
            LinearGradient(colors: gradient, startPoint: .topLeading, endPoint: .bottomTrailing)

            HStack(spacing: 12) {
                Text(emoji)
                    .font(.system(size: 42))

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.title3.weight(.black))
                        .foregroundStyle(.white)
                    Text(subtitle)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.85))
                }
                .layoutPriority(1)

                Spacer(minLength: 0)
            }
            .padding(18)
        }
        .frame(height: 104)
        .clipShape(
            UnevenRoundedRectangle(
                topLeadingRadius: 20, bottomLeadingRadius: 0,
                bottomTrailingRadius: 0, topTrailingRadius: 20,
                style: .continuous
            )
        )
    }

    private var footer: some View {
        HStack(spacing: 10) {
            VStack(alignment: .leading, spacing: 2) {
                Text(detail)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                Text(destinationLabel)
                    .font(.headline.weight(.bold))
                    .foregroundStyle(MatherTheme.ink)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
            Image(systemName: symbolName)
                .font(.system(size: 32, weight: .black))
                .foregroundStyle(accent)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(MatherTheme.card)
        .clipShape(
            UnevenRoundedRectangle(
                topLeadingRadius: 0, bottomLeadingRadius: 20,
                bottomTrailingRadius: 20, topTrailingRadius: 0,
                style: .continuous
            )
        )
    }
}
