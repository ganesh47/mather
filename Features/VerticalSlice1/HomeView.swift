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

                    if ResponsiveLayout.isWide(horizontalSizeClass) {
                        HStack(alignment: .top, spacing: 20) {
                            makeAndBreakCard
                            labCard
                        }
                    } else {
                        makeAndBreakCard
                        labCard
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
                            Text("1–20")
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
        .accessibilityIdentifier("Play")
    }

    private var lockedActivityCard: some View {
        CardSurface {
            VStack(alignment: .leading, spacing: 14) {
                Text("Make & Break 1–20")
                    .font(.title2.weight(.bold))
                Text("Enable the activity in Settings before handing the iPad to your child.")
                    .font(.headline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    // MARK: - Explorer Lab card

    private var labCard: some View {
        Button {
            appModel.engine.showLab()
        } label: {
            VStack(spacing: 0) {
                ZStack {
                    LinearGradient(
                        colors: [MatherTheme.softBlue, MatherTheme.coral.opacity(0.8)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )

                    HStack(spacing: 16) {
                        Text("🔬")
                            .font(.system(size: 48))

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Explorer Lab")
                                .font(.title3.weight(.black))
                                .foregroundStyle(.white)
                            Text("8 games inside")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.white.opacity(0.85))
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
                        Text("Physics · Geometry · Angles")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.secondary)
                        Text("Tap to explore all activities")
                            .font(.headline.weight(.bold))
                            .foregroundStyle(MatherTheme.ink)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    Spacer()
                    Image(systemName: "chevron.right.circle.fill")
                        .font(.system(size: 44))
                        .foregroundStyle(MatherTheme.softBlue)
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
                color: colorScheme == .dark ? MatherTheme.softBlue.opacity(0.12) : .black.opacity(0.08),
                radius: colorScheme == .dark ? 18 : 12,
                y: colorScheme == .dark ? 8 : 5
            )
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("ExplorerLab")
    }
}
