import SwiftUI
import UIKit

/// Per-spot screen shown on the iPad during the room phase.
/// Large colour fill and spoken prompt — child needs no reading ability.
/// Pause button is always visible in the top-trailing corner.
struct SpotPromptView: View {
    @Bindable var engine: RoomQuestEngine
    let spotIndex: Int
    let onRequestAbandon: (String) -> Void

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

            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    Color.clear
                        .frame(height: 88)

                    Text(spotLabel)
                        .font(.system(size: 48, weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)

                    Text(station?.role.icon ?? "✨")
                        .font(.system(size: 72))

                    if let station {
                        Text(station.referenceCaptureState == .captured ? "Recheck the saved \(station.role.title) place." : "Scan to find \(station.role.title).")
                            .font(.title3.weight(.bold))
                            .foregroundStyle(.white.opacity(0.92))
                            .multilineTextAlignment(.center)

                        Text("When the place matches, collect \(station.quantity) \(station.quantity == 1 ? "token" : "tokens").")
                            .font(.title.weight(.semibold))
                            .foregroundStyle(.white.opacity(0.84))
                            .multilineTextAlignment(.center)
                    }

                    scanStatusCard

                    referenceCard

                    helperCard

                    if let imageData = station?.referenceImageJPEGData,
                       let uiImage = UIImage(data: imageData) {
                        CardSurface {
                            HStack(spacing: 12) {
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 80, height: 80)
                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Find this place")
                                        .font(.headline.weight(.bold))
                                        .foregroundStyle(MatherTheme.ink)
                                    Text("Walk to where this photo was taken")
                                        .font(.subheadline)
                                        .foregroundStyle(MatherTheme.cardSubtitle)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                            }
                        }
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
            }
            .safeAreaInset(edge: .bottom) {
                actionBar
            }

            HStack(spacing: 12) {
                roomChromeButton(title: "Pause", systemImage: "pause.circle.fill", accessibilityID: "room-pause-button") {
                    engine.pauseSession()
                }

                roomChromeButton(title: "Home", systemImage: "house.circle.fill", accessibilityID: "room-home-button") {
                    onRequestAbandon("parent_home")
                }
            }
            .padding(24)
        }
    }

    private var referenceCard: some View {
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
    }

    private var helperCard: some View {
        CardSurface {
            VStack(alignment: .leading, spacing: 10) {
                Label("Grown-up helper", systemImage: "figure.and.child.holdinghands")
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(MatherTheme.ink)
                Text("Kid steps: look, point, hold still, then collect.")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(MatherTheme.ink)
                Text(engine.shouldShowSpotManualFallback
                     ? "If the child is at the right place, a grown-up can consent and accept it now."
                     : "Start with a camera check. Fallback stays hidden unless the scan misses, so the camera feels like the real helper.")
                    .font(.subheadline)
                    .foregroundStyle(MatherTheme.cardSubtitle)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    @ViewBuilder
    private var actionBar: some View {
        VStack(spacing: 12) {
            if station?.referenceCaptureState == .captured {
                let isScanBusy: Bool = {
                    switch engine.scanState {
                    case .scanning, .celebrating: return true
                    default: return false
                    }
                }()

                Button {
                    engine.verifyCurrentSpotWithCamera()
                } label: {
                    Label("Recheck this place", systemImage: "camera.viewfinder")
                }
                .accessibilityIdentifier("room-spot-scan-button")
                .buttonStyle(RoomQuestPrimaryButtonStyle())
                .disabled(isScanBusy)
                .opacity(isScanBusy ? 0.7 : 1)
            }

            if engine.shouldShowSpotManualFallback {
                Button(engine.currentSpotParentConsentTitle) {
                    engine.acceptCurrentSpotWithParentConsent()
                }
                .accessibilityIdentifier("room-spot-confirm-button")
                .buttonStyle(.plain)
                .font(.headline.weight(.bold))
                .foregroundStyle(.white.opacity(0.92))
            } else if station?.referenceCaptureState == .captured {
                Text("Try the camera first. Fallback appears only if the scan misses.")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.88))
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 12)
        .padding(.bottom, 24)
        .background {
            LinearGradient(
                colors: [spotColour.opacity(0), spotColour.opacity(0.92), spotColour],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
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
        case .celebrating(let role, _):
            CardSurface {
                Label("\(role.title) unlocked!", systemImage: "sparkles")
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(MatherTheme.accent)
            }
        case .almost(_, let message):
            CardSurface {
                Label(message, systemImage: "scope")
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(MatherTheme.warm)
            }
        case .failed(_, let message):
            CardSurface {
                Label(message, systemImage: "exclamationmark.triangle.fill")
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(MatherTheme.coral)
            }
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
    .accessibilityLabel(title)
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
