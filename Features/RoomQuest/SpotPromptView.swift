import SwiftUI

/// Per-spot screen shown on the iPad during the room phase.
/// Large colour fill and spoken prompt — child needs no reading ability.
/// Pause button is always visible in the top-trailing corner.
struct SpotPromptView: View {
    @Bindable var engine: RoomQuestEngine
    let spotIndex: Int

    private var spotColour: Color {
        spotIndex == 0 ? MatherTheme.warm : MatherTheme.accent
    }

    private var spotLabel: String {
        spotIndex == 0 ? "Red spot" : "Blue spot"
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

                if let p = engine.problem {
                    let quantity = spotIndex == 0 ? p.decompositionA : p.decompositionB
                    Text("\(quantity)")
                        .font(.system(size: 120, weight: .black, design: .rounded))
                        .foregroundStyle(.white.opacity(0.9))
                    Text(quantity == 1 ? "token" : "tokens")
                        .font(.title.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.8))
                }

                Spacer()

                Button("Got them!") {
                    engine.markSpotVisited(index: spotIndex)
                }
                .buttonStyle(RoomQuestPrimaryButtonStyle())
                .padding(.horizontal, 40)
                .padding(.bottom, 40)
            }

            // Pause button — always accessible, no unlock required
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
