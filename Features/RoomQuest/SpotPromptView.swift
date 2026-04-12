import SwiftUI

/// Per-spot screen shown on the iPad during the room phase.
/// Large colour fill and spoken prompt — child needs no reading ability.
/// Pause button is always visible in the top-trailing corner.
struct SpotPromptView: View {
    @Bindable var engine: RoomQuestEngine
    let spotIndex: Int

    private var station: RoomQuestStation? {
        engine.currentStation
    }

    private var spotColour: Color {
        station?.role == .redRocket ? MatherTheme.warm : MatherTheme.accent
    }

    private var spotLabel: String {
        station?.role.title ?? (spotIndex == 0 ? "Red Rocket" : "Blue Bubble")
    }

    var body: some View {
        ZStack(alignment: .topTrailing) {
            spotColour
                .ignoresSafeArea()

            VStack(spacing: 32) {
                Spacer()

                Text(spotLabel)
                    .font(.system(size: 48, weight: .black, design: .rounded))
                    .foregroundStyle(.white)

                Text(station?.role.icon ?? "✨")
                    .font(.system(size: 72))

                if let station {
                    Text(station.role.scanPrompt)
                        .font(.title3.weight(.bold))
                        .foregroundStyle(.white.opacity(0.92))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 28)

                    Text("Then collect \(station.quantity) \(station.quantity == 1 ? "token" : "tokens").")
                        .font(.title.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.84))
                }

                CardSurface {
                    VStack(alignment: .leading, spacing: 10) {
                        Label("Need a fallback?", systemImage: "hand.tap.fill")
                            .font(.headline.weight(.semibold))
                            .foregroundStyle(MatherTheme.ink)
                        Text("If the marker is hard to scan, the child can keep going with one big confirmation button.")
                            .font(.subheadline)
                            .foregroundStyle(MatherTheme.cardSubtitle)
                    }
                }
                .padding(.horizontal, 24)

                Spacer()

                Button(station?.role.fallbackButtonTitle ?? "I found it") {
                    engine.markSpotVisited(index: spotIndex)
                }
                .buttonStyle(RoomQuestPrimaryButtonStyle())
                .padding(.horizontal, 40)

                Button {
                    engine.markSpotVisited(index: spotIndex)
                } label: {
                    Label("Scan marker later, keep going now", systemImage: "camera.viewfinder")
                }
                .buttonStyle(.plain)
                .font(.headline.weight(.bold))
                .foregroundStyle(.white.opacity(0.9))
                .padding(.bottom, 40)
            }

            Button {
                engine.pauseSession()
            } label: {
                Label("Pause", systemImage: "pause.circle.fill")
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(.white)
            }
            .padding(24)
            .accessibilityIdentifier("room-pause-button")
        }
    }
}

/// Primary button style for room phase — large, white fill on coloured background.
private struct RoomQuestPrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.title.weight(.black))
            .foregroundStyle(MatherTheme.ink)
            .frame(maxWidth: .infinity)
            .frame(minHeight: 80)
            .background(.white.opacity(configuration.isPressed ? 0.8 : 1))
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
    }
}
