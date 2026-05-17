import SwiftUI

/// Shared card view for launching a lab activity.
///
/// Use `.grid` for the Games tab tile grid and `.detail` for the lane-detail
/// horizontal row. Both modes share the same visual tokens so a child sees a
/// consistent "launch this game" affordance wherever they encounter it.
struct GameActivityCard: View {
    enum LayoutMode {
        case grid
        case detail
    }

    let activity: LabActivity
    let tint: Color
    let canLaunch: Bool
    let layoutMode: LayoutMode
    let sensorCapabilities: DeviceSensorCapabilities
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            switch layoutMode {
            case .grid: gridBody
            case .detail: detailBody
            }
        }
        .buttonStyle(.plain)
        .disabled(!canLaunch)
        .accessibilityLabel("Launch \(activity.title). \(activity.tagline)")
        .accessibilityHint(
            canLaunch
            ? "Directly starts the game. \(sensorSummary)"
            : "This game needs a sensor that is not available on this device. Nothing is marked wrong."
        )
    }

    // MARK: - Grid layout (Games tab tile)

    private var gridBody: some View {
        VStack(spacing: 10) {
            gridIconBox
            Text(activity.title)
                .font(.headline.weight(.black))
                .foregroundStyle(canLaunch ? MatherTheme.ink : MatherTheme.ink.opacity(0.55))
                .lineLimit(2)
                .minimumScaleFactor(0.78)
                .multilineTextAlignment(.center)
        }
        .padding(14)
        .frame(maxWidth: .infinity, minHeight: 132, alignment: .center)
        .background(MatherTheme.card, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke((canLaunch ? tint : MatherTheme.cardSubtitle).opacity(0.16), lineWidth: 1)
        )
        .opacity(canLaunch ? 1 : 0.78)
    }

    private var gridIconBox: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [tint.opacity(0.18), MatherTheme.card.opacity(0.88)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            if let artworkKey = activity.id.electronicsArtworkKey {
                ElectronicsCircuitArtwork(key: artworkKey, tint: tint)
                    .padding(10)
            } else {
                Image(systemName: canLaunch ? "play.circle.fill" : "exclamationmark.triangle.fill")
                    .font(.title2.weight(.black))
                    .foregroundStyle(tint.opacity(canLaunch ? 1 : 0.45))
                Text(activity.emoji)
                    .font(.system(size: 26))
                    .offset(x: 12, y: 12)
            }
        }
        .frame(width: 68, height: 68)
        .accessibilityLabel(activity.artworkAccessibilityLabel)
    }

    // MARK: - Detail layout (lane-detail row)

    private var detailBody: some View {
        HStack(alignment: .center, spacing: 14) {
            detailVisualBox
            Text(activity.title)
                .font(.title3.weight(.black))
                .foregroundStyle(canLaunch ? MatherTheme.ink : MatherTheme.ink.opacity(0.55))
                .lineLimit(2)
                .minimumScaleFactor(0.82)
                .multilineTextAlignment(.leading)
            Spacer(minLength: 6)
        }
        .padding(16)
        .frame(maxWidth: .infinity, minHeight: 96, alignment: .leading)
        .background(MatherTheme.card, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke((canLaunch ? tint : MatherTheme.cardSubtitle).opacity(0.16), lineWidth: 1)
        )
        .opacity(canLaunch ? 1 : 0.78)
    }

    private var detailVisualBox: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(tint.opacity(0.12))
            if let artworkKey = activity.id.electronicsArtworkKey {
                ElectronicsCircuitArtwork(key: artworkKey, tint: tint)
                    .padding(12)
            } else {
                visualMotif
                Text(activity.emoji)
                    .font(.system(size: 38))
                    .offset(x: -18, y: -14)
            }
        }
        .frame(width: 104, height: 96)
        .accessibilityLabel(activity.artworkAccessibilityLabel)
    }

    @ViewBuilder
    private var visualMotif: some View {
        switch activity.id {
        case .sumSprint:
            HStack(spacing: 4) {
                ForEach(0..<4, id: \.self) { index in
                    Capsule()
                        .fill(tint.opacity(0.18 + Double(index) * 0.08))
                        .frame(width: 8, height: CGFloat(24 + index * 10))
                }
            }
            .offset(x: 18, y: 12)
        case .roomQuest, .compassAngles:
            Image(systemName: "location.north.line.fill")
                .font(.system(size: 46, weight: .bold))
                .foregroundStyle(tint.opacity(0.35))
                .offset(x: 20, y: 12)
        case .shapeGeometry, .symmetryFold, .twoFingerProtractor:
            Image(systemName: "angle")
                .font(.system(size: 52, weight: .bold))
                .foregroundStyle(tint.opacity(0.35))
                .offset(x: 18, y: 12)
        case .rectangleFactory, .factoryCards:
            Grid(horizontalSpacing: 3, verticalSpacing: 3) {
                ForEach(0..<2, id: \.self) { _ in
                    GridRow {
                        ForEach(0..<3, id: \.self) { _ in
                            RoundedRectangle(cornerRadius: 3)
                                .fill(tint.opacity(0.28))
                                .frame(width: 16, height: 16)
                        }
                    }
                }
            }
            .offset(x: 20, y: 12)
        case .angleCannon, .gravityArtist:
            Image(systemName: "circle.dotted")
                .font(.system(size: 52, weight: .bold))
                .foregroundStyle(tint.opacity(0.35))
                .offset(x: 20, y: 12)
        case .waterCycle:
            Image(systemName: "cloud.rain.fill")
                .font(.system(size: 48, weight: .bold))
                .foregroundStyle(tint.opacity(0.35))
                .offset(x: 20, y: 12)
        case .soundVolume:
            Image(systemName: "speaker.wave.2.fill")
                .font(.system(size: 48, weight: .bold))
                .foregroundStyle(tint.opacity(0.35))
                .offset(x: 20, y: 12)
        case .memoryMatch, .countryCards, .worldAnimalCards, .worldBirdCards, .fruitCards:
            Image(systemName: "rectangle.on.rectangle.angled")
                .font(.system(size: 48, weight: .bold))
                .foregroundStyle(tint.opacity(0.35))
                .offset(x: 20, y: 12)
        case .circuitSpark:
            Image(systemName: "bolt.fill")
                .font(.system(size: 48, weight: .bold))
                .foregroundStyle(tint.opacity(0.35))
                .offset(x: 20, y: 12)
        }
    }

    private var sensorSummary: String {
        activity.id
            .sensorAffordances(with: sensorCapabilities)
            .map(\.displayLabel)
            .joined(separator: ". ")
    }
}
