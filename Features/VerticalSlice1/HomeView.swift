import SwiftUI

struct HomeView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Bindable var appModel: AppModel

    var body: some View {
        ZStack {
            MatherTheme.background.ignoresSafeArea()
            VStack(spacing: 20) {
                // App wordmark — large, rounded, ink coloured
                Text("Mather")
                    .font(.system(size: 48, weight: .black, design: .rounded))
                    .foregroundStyle(MatherTheme.ink)
                    .frame(maxWidth: .infinity, alignment: .leading)

                if appModel.featureFlags.verticalSlice1Enabled {
                    activeActivityCard
                } else {
                    lockedActivityCard
                }

                if appModel.featureFlags.roomQuestEnabled {
                    Button("Start Room Quest") {
                        appModel.engine.showRoomQuest()
                    }
                    .buttonStyle(SecondaryTileButtonStyle(fill: MatherTheme.accent.opacity(0.65)))
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

                Spacer()
            }
            .padding(24)
        }
    }

    // Active state: colourful hero card — number is the visual centrepiece
    private var activeActivityCard: some View {
        Button {
            appModel.engine.showSessionConfig()
        } label: {
            VStack(spacing: 0) {
                // Colourful header strip — draws the child's eye immediately
                ZStack {
                    LinearGradient(
                        colors: [MatherTheme.warm, MatherTheme.accent],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )

                    HStack(spacing: 16) {
                        // Mini ten-frame preview — the activity's visual identity
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
                            Text("to 10")
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

                // Play CTA strip
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
            .shadow(color: colorScheme == .dark ? MatherTheme.coral.opacity(0.12) : .black.opacity(0.08), radius: colorScheme == .dark ? 18 : 12, y: colorScheme == .dark ? 8 : 5)
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("Play")
    }

    private var lockedActivityCard: some View {
        CardSurface {
            VStack(alignment: .leading, spacing: 14) {
                Text("Make & Break to 10")
                    .font(.title2.weight(.bold))
                Text("Enable the activity in Settings before handing the iPad to your child.")
                    .font(.headline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                Button("Open Settings") {
                    appModel.engine.showSettings()
                }
                .buttonStyle(PrimaryActionButtonStyle())
            }
        }
    }
}
