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

                    childLauncherGrid

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

    // MARK: - Child launcher

    private var childLauncherGrid: some View {
        LazyVGrid(columns: childLauncherColumns, spacing: ResponsiveLayout.isWide(horizontalSizeClass) ? 20 : 14) {
            childLauncherTile(
                title: "Targets",
                icon: "circle.grid.2x2.fill",
                gradient: [MatherTheme.warm, MatherTheme.accent],
                accessibilityIdentifier: "Play"
            ) {
                appModel.pickProfileThenRun { appModel.engine.showSessionConfig() }
            }
            childLauncherTile(
                title: "Labs",
                icon: "sparkles.rectangle.stack.fill",
                gradient: [MatherTheme.softBlue, MatherTheme.coral.opacity(0.8)],
                accessibilityIdentifier: "ExplorerLab"
            ) {
                appModel.engine.showLab()
            }
            childLauncherTile(
                title: "Games",
                icon: "gamecontroller.fill",
                gradient: [MatherTheme.warm, MatherTheme.accent.opacity(0.85)],
                accessibilityIdentifier: "GamesEntry"
            ) {
                appModel.engine.showLabGames()
            }
        }
    }

    private var childLauncherColumns: [GridItem] {
        let spacing: CGFloat = ResponsiveLayout.isWide(horizontalSizeClass) ? 20 : 12
        return Array(repeating: GridItem(.flexible(minimum: 88), spacing: spacing), count: 3)
    }

    private func childLauncherTile(
        title: String,
        icon: String,
        gradient: [Color],
        accessibilityIdentifier: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            VStack(spacing: 14) {
                Image(systemName: icon)
                    .font(.system(size: 42, weight: .black, design: .rounded))
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(.white)
                    .frame(width: 76, height: 76)
                    .background(Circle().fill(.white.opacity(0.18)))
                Text(title)
                    .font(.system(size: 26, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
            }
            .frame(maxWidth: .infinity)
            .frame(height: ResponsiveLayout.isWide(horizontalSizeClass) ? 190 : 156)
            .padding(.horizontal, 12)
            .background(
                LinearGradient(colors: gradient, startPoint: .topLeading, endPoint: .bottomTrailing)
            )
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .strokeBorder(.white.opacity(colorScheme == .dark ? 0.08 : 0), lineWidth: 1)
            )
            .shadow(
                color: colorScheme == .dark ? gradient.first?.opacity(0.12) ?? .clear : .black.opacity(0.08),
                radius: colorScheme == .dark ? 18 : 12,
                y: colorScheme == .dark ? 8 : 5
            )
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier(accessibilityIdentifier)
        .accessibilityLabel(title)
    }
}
