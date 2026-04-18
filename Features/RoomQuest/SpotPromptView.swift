import SwiftUI
import UIKit

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
                    Text(station.referenceCaptureState == .captured ? "Recheck the saved \(station.role.title) place." : "Scan to find \(station.role.title).")
                        .font(.title3.weight(.bold))
                        .foregroundStyle(.white.opacity(0.92))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 28)

                    Text("When the place matches, collect \(station.quantity) \(station.quantity == 1 ? "token" : "tokens").")
                        .font(.title.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.84))
                }

                scanStatusCard

                CardSurface {
                    VStack(alignment: .leading, spacing: 12) {
                        Label(engine.currentSpotReferenceLabel, systemImage: station?.referenceCaptureState == .captured ? "photo.badge.checkmark" : "photo")
                            .font(.headline.weight(.semibold))
                            .foregroundStyle(MatherTheme.ink)
                        Divider()
                        VStack(alignment: .leading, spacing: 6) {
                            Text(engine.currentSpotStatusTitle)
                                .font(.title3.weight(.black))
                                .foregroundStyle(MatherTheme.ink)
                            Text(engine.currentSpotSearchGuidance)
                                .font(.subheadline)
                                .foregroundStyle(MatherTheme.cardSubtitle)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
                .padding(.horizontal, 24)

                CardSurface {
                    VStack(alignment: .leading, spacing: 10) {
                        Label("Grown-up helper", systemImage: "figure.and.child.holdinghands")
                            .font(.headline.weight(.semibold))
                            .foregroundStyle(MatherTheme.ink)
                        Text("Kid steps: look, point, hold still, then collect.")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(MatherTheme.ink)
                        Text("If the camera keeps missing the place, a grown-up can tap the fallback button below.")
                            .font(.subheadline)
                            .foregroundStyle(MatherTheme.cardSubtitle)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .padding(.horizontal, 24)

                Spacer()

                Button {
                    engine.verifyCurrentSpotWithCamera()
                } label: {
                    Label(station?.referenceCaptureState == .captured ? "Recheck this place" : "Scan to unlock", systemImage: "camera.viewfinder")
                }
                .accessibilityIdentifier("room-spot-scan-button")
                .buttonStyle(RoomQuestPrimaryButtonStyle())
                .disabled({
                    switch engine.scanState {
                    case .scanning, .celebrating:
                        return true
                    case .idle, .almost, .failed:
                        return station?.referenceCaptureState != .captured
                    }
                }())
                .opacity({
                    switch engine.scanState {
                    case .scanning, .celebrating:
                        return 0.7
                    case .idle, .almost, .failed:
                        return station?.referenceCaptureState == .captured ? 1 : 0.55
                    }
                }())
                .padding(.horizontal, 40)

                Button(station?.role.fallbackButtonTitle ?? "I found it") {
                    engine.markSpotVisited(index: spotIndex)
                }
                .accessibilityIdentifier("room-spot-confirm-button")
                .buttonStyle(.plain)
                .font(.headline.weight(.bold))
                .foregroundStyle(.white.opacity(0.92))
                .padding(.horizontal, 40)
                .padding(.bottom, 40)
            }

            HStack(spacing: 12) {
                roomChromeButton(title: "Pause", systemImage: "pause.circle.fill", accessibilityID: "room-pause-button") {
                    engine.pauseSession()
                }

                roomChromeButton(title: "Home", systemImage: "house.circle.fill", accessibilityID: "room-home-button") {
                    engine.onExitToHome?()
                }
            }
            .padding(24)
        }
    }

    @ViewBuilder
    private var scanStatusCard: some View {
        switch engine.scanState {
        case .idle:
            EmptyView()
        case .scanning(let role):
            CardSurface {
                Label("Scanning for \(role.title)…", systemImage: "camera.metering.center.weighted")
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(MatherTheme.ink)
            }
            .padding(.horizontal, 24)
        case .celebrating(let role, _):
            CardSurface {
                Label("\(role.title) unlocked!", systemImage: "sparkles")
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(MatherTheme.accent)
            }
            .padding(.horizontal, 24)
        case .almost(_, let message):
            CardSurface {
                Label(message, systemImage: "scope")
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(MatherTheme.warm)
            }
            .padding(.horizontal, 24)
        case .failed(_, let message):
            CardSurface {
                Label(message, systemImage: "exclamationmark.triangle.fill")
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(MatherTheme.coral)
            }
            .padding(.horizontal, 24)
        }
    }
}

private func roomChromeButton(title: String, systemImage: String, accessibilityID: String, action: @escaping () -> Void) -> some View {
    Button(action: action) {
        Label(title, systemImage: systemImage)
            .font(.title2.weight(.semibold))
            .foregroundStyle(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(.black.opacity(0.18), in: Capsule())
    }
    .accessibilityIdentifier(accessibilityID)
    .accessibilityLabel(accessibilityID)
    .accessibilityAddTraits(.isButton)
}

/// Primary button style for room phase, large, white fill on coloured background.
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
