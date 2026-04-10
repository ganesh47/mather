import SwiftUI

/// Parent setup screen shown before the room phase begins.
/// Displays the spot quantities and safety reminder; parent taps "Ready" when spots are placed.
struct RoomSetupView: View {
    @Bindable var engine: RoomQuestEngine

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Set up the room")
                        .font(.largeTitle.weight(.black))
                    Text("Place the two spot-cards in one room, within line of sight of the iPad.")
                        .font(.subheadline)
                        .foregroundStyle(MatherTheme.cardSubtitle)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                if let p = engine.problem {
                    HStack(spacing: 16) {
                        spotCard(
                            colour: MatherTheme.warm,
                            label: "Red spot",
                            quantity: p.decompositionA
                        )
                        spotCard(
                            colour: MatherTheme.accent,
                            label: "Blue spot",
                            quantity: p.decompositionB
                        )
                    }

                    CardSurface {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Target: \(p.target)")
                                .font(.title2.weight(.bold))
                            Text("Place \(p.decompositionA) red tokens at the red card and \(p.decompositionB) blue tokens at the blue card.")
                                .font(.body)
                        }
                    }
                }

                CardSurface {
                    VStack(alignment: .leading, spacing: 10) {
                        Label("Safety reminder", systemImage: "exclamationmark.triangle")
                            .font(.headline.weight(.semibold))
                            .foregroundStyle(MatherTheme.coral)
                        Text("Place cards away from stairs, windows, balconies, and the kitchen.")
                            .font(.subheadline)
                            .foregroundStyle(MatherTheme.cardSubtitle)
                        Text("Both spots must be in the same room as this iPad.")
                            .font(.subheadline)
                            .foregroundStyle(MatherTheme.cardSubtitle)
                    }
                }

                Button("Ready — spots are set!") {
                    engine.markSetupComplete()
                }
                .buttonStyle(PrimaryActionButtonStyle())
            }
            .padding(24)
        }
    }

    private func spotCard(colour: Color, label: String, quantity: Int) -> some View {
        VStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 16)
                .fill(colour)
                .frame(height: 80)
            Text("\(quantity)")
                .font(.system(size: 48, weight: .black, design: .rounded))
            Text(label)
                .font(.caption.weight(.semibold))
                .foregroundStyle(MatherTheme.cardSubtitle)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
    }
}
