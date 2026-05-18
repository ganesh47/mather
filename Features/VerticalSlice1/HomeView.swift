import SwiftUI

struct HomeView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Bindable var appModel: AppModel

    @State private var pendingParentUnlock: ParentUnlockRequest?
    @State private var pendingParentAction: ParentHomeAction?

    var body: some View {
        ZStack {
            MatherTheme.background.ignoresSafeArea()
            GeometryReader { proxy in
                ScrollView {
                    VStack(spacing: ResponsiveLayout.isWide(horizontalSizeClass) ? 20 : 14) {
                        Text("Mather")
                            .font(.system(size: ResponsiveLayout.isWide(horizontalSizeClass) ? 48 : 44, weight: .black, design: .rounded))
                            .foregroundStyle(MatherTheme.ink)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        childLauncherGrid

                        childQuickStartBand

                        parentControlsBand
                    }
                    .padding(ResponsiveLayout.contentPadding(for: horizontalSizeClass))
                    .frame(maxWidth: ResponsiveLayout.contentMaxWidth(for: horizontalSizeClass))
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: proxy.size.height, alignment: .top)
                }
            }
        }
        .sheet(item: $pendingParentUnlock) { request in
            ParentUnlockSheet(
                request: request,
                onCancel: { clearParentUnlock() },
                onUnlock: { unlockPendingParentAction() }
            )
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
                requestParentAction(.sessionSetup)
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

    private var childQuickStartBand: some View {
        Button {
            requestParentAction(.sessionSetup)
        } label: {
            HStack(spacing: 14) {
                Image(systemName: "play.circle.fill")
                    .font(.system(size: 34, weight: .black))
                    .foregroundStyle(MatherTheme.accent)
                    .frame(width: 52, height: 52)
                    .background(MatherTheme.accent.opacity(0.12), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Next up")
                        .font(.headline.weight(.black))
                        .foregroundStyle(MatherTheme.ink)
                    Text("Start a short Targets round")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(MatherTheme.cardSubtitle)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 0)

                Image(systemName: "chevron.right.circle.fill")
                    .font(.title2.weight(.black))
                    .foregroundStyle(MatherTheme.accent)
                    .accessibilityHidden(true)
            }
            .padding(16)
            .frame(maxWidth: .infinity, minHeight: 92, alignment: .leading)
            .background(MatherTheme.card.opacity(0.88), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .strokeBorder(MatherTheme.accent.opacity(0.16), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("home-child-next-up")
        .accessibilityLabel("Next up, start a short Targets round")
    }

    private var parentControlsBand: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Parent controls", systemImage: "person.2.fill")
                .font(.subheadline.weight(.black))
                .foregroundStyle(MatherTheme.cardSubtitle)

            HStack(spacing: 10) {
                parentControlButton(
                    title: "Parent Summary",
                    icon: "chart.bar.fill",
                    tint: MatherTheme.warm
                ) {
                    requestParentAction(.parentSummary)
                }

                parentControlButton(
                    title: "Settings",
                    icon: "gearshape.fill",
                    tint: MatherTheme.softBlue
                ) {
                    requestParentAction(.settings)
                }
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(MatherTheme.panel.opacity(0.58), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("home-parent-controls")
    }

    private func parentControlButton(title: String, icon: String, tint: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Label(title, systemImage: icon)
                .font(.subheadline.weight(.black))
                .foregroundStyle(MatherTheme.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.82)
                .frame(maxWidth: .infinity, minHeight: 52)
                .background(tint.opacity(0.18), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
    }

    private func requestParentAction(_ action: ParentHomeAction) {
        if appModel.featureFlags.testModeEnabled || !action.requiresParentUnlock {
            runParentAction(action)
            return
        }
        pendingParentAction = action
        pendingParentUnlock = action.unlockRequest
    }

    private func unlockPendingParentAction() {
        guard let action = pendingParentAction else {
            clearParentUnlock()
            return
        }
        clearParentUnlock()
        runParentAction(action)
    }

    private func clearParentUnlock() {
        pendingParentUnlock = nil
        pendingParentAction = nil
    }

    private func runParentAction(_ action: ParentHomeAction) {
        switch action {
        case .sessionSetup:
            appModel.pickProfileThenRun { appModel.engine.showSessionConfig() }
        case .parentSummary:
            appModel.engine.showParentSummary()
        case .settings:
            appModel.engine.showSettings()
        }
    }
}

private enum ParentHomeAction {
    case sessionSetup
    case parentSummary
    case settings

    var requiresParentUnlock: Bool {
        switch self {
        case .sessionSetup:
            return false
        case .parentSummary, .settings:
            return true
        }
    }

    var unlockRequest: ParentUnlockRequest {
        switch self {
        case .sessionSetup:
            return ParentUnlockRequest(
                id: "session-setup",
                title: "Session setup",
                detail: "A parent unlock is required before changing session setup.",
                unlockLabel: "Hold to open session setup"
            )
        case .parentSummary:
            return ParentUnlockRequest(
                id: "parent-summary",
                title: "Parent Summary",
                detail: "A parent unlock is required before opening progress and history.",
                unlockLabel: "Hold to open Parent Summary"
            )
        case .settings:
            return ParentUnlockRequest(
                id: "settings",
                title: "Settings",
                detail: "A parent unlock is required before changing app settings.",
                unlockLabel: "Hold to open Settings"
            )
        }
    }
}
