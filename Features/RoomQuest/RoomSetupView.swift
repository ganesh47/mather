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
                    Text("Place the two station markers in one room, then scan or confirm each one.")
                        .font(.subheadline)
                        .foregroundStyle(MatherTheme.cardSubtitle)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                if let p = engine.problem {
                    HStack(spacing: 16) {
                        ForEach(engine.stations) { station in
                            stationCard(for: station)
                        }
                    }

                    CardSurface {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Target: \(p.target)")
                                .font(.title2.weight(.bold))
                            Text("Place \(p.decompositionA) tokens at Red Rocket and \(p.decompositionB) tokens at Blue Bubble.")
                                .font(.body)
                        }
                    }
                }

                CardSurface {
                    VStack(alignment: .leading, spacing: 10) {
                        Label("Scan-friendly setup", systemImage: "camera.viewfinder")
                            .font(.headline.weight(.semibold))
                            .foregroundStyle(MatherTheme.softBlue)
                        Text("In alpha, parent can confirm a station manually if scanning is awkward.")
                            .font(.subheadline)
                            .foregroundStyle(MatherTheme.cardSubtitle)
                        Text("Both stations must stay in the same room as this iPad.")
                            .font(.subheadline)
                            .foregroundStyle(MatherTheme.cardSubtitle)
                    }
                }

                CardSurface {
                    VStack(alignment: .leading, spacing: 10) {
                        Label("Safety reminder", systemImage: "exclamationmark.triangle")
                            .font(.headline.weight(.semibold))
                            .foregroundStyle(MatherTheme.coral)
                        Text("Place stations away from stairs, windows, balconies, and the kitchen.")
                            .font(.subheadline)
                            .foregroundStyle(MatherTheme.cardSubtitle)
                        Text("Keep markers easy to see, but do not make the child walk while staring at the screen.")
                            .font(.subheadline)
                            .foregroundStyle(MatherTheme.cardSubtitle)
                    }
                }

                Button("Ready — stations are set!") {
                    engine.markSetupComplete()
                }
                .buttonStyle(PrimaryActionButtonStyle())
                .disabled(!engine.allStationsRegistered)
                .opacity(engine.allStationsRegistered ? 1 : 0.55)
            }
            .padding(24)
        }
    }

    private func stationCard(for station: RoomQuestStation) -> some View {
        let colour = station.role == .redRocket ? MatherTheme.warm : MatherTheme.accent

        return VStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 16)
                .fill(colour)
                .frame(height: 80)
                .overlay {
                    Text(station.role.icon)
                        .font(.system(size: 40))
                }
            Text("\(station.quantity)")
                .font(.system(size: 48, weight: .black, design: .rounded))
            Text(station.role.title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(MatherTheme.cardSubtitle)
            Button(station.isRegistered ? "Marker ready" : "Scan or confirm") {
                engine.registerStation(station.role)
            }
            .buttonStyle(SecondaryTileButtonStyle(fill: colour.opacity(0.18)))
            .foregroundStyle(colour)
            .accessibilityIdentifier("room-station-register-\(station.role.rawValue)")
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .accessibilityIdentifier("room-station-card-\(station.role.rawValue)")
    }
}
