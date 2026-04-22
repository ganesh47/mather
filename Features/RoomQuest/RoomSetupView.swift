import SwiftUI
import UIKit

/// Parent setup screen shown before the room phase begins.
/// Displays the spot quantities and safety reminder; parent taps "Ready" when spots are placed.
struct RoomSetupView: View {
    @Bindable var engine: RoomQuestEngine
    @State private var showingConfiguration = false

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Set up the room")
                        .font(.largeTitle.weight(.black))
                    Text("Place both station markers in one room, then finish setup for each station below.")
                        .font(.subheadline)
                        .foregroundStyle(MatherTheme.cardSubtitle)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                RoomQuestSetupConfigurationCard(
                    featureFlags: engine.settings,
                    showingConfiguration: $showingConfiguration
                )

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
                        Label(engine.allStationsRegistered ? "Ready to start" : "Setup progress", systemImage: engine.allStationsRegistered ? "checkmark.seal.fill" : "list.bullet.clipboard")
                            .font(.headline.weight(.semibold))
                            .foregroundStyle(engine.allStationsRegistered ? MatherTheme.accent : MatherTheme.softBlue)
                        Text("\(engine.stations.filter(\.isReadyForRoomQuest).count) of \(engine.stations.count) stations ready")
                            .font(.title3.weight(.bold))
                            .foregroundStyle(MatherTheme.ink)
                        Text("Scan each station marker first. If needed, a grown-up can save the same-place fallback instead.")
                            .font(.subheadline)
                            .foregroundStyle(MatherTheme.cardSubtitle)
                        Text("Both stations must stay in the same room as this iPad.")
                            .font(.subheadline)
                            .foregroundStyle(MatherTheme.cardSubtitle)

                        Text(engine.missingSetupRequirementsMessage)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(engine.allStationsRegistered ? MatherTheme.accent : MatherTheme.coral)

                        switch engine.scanState {
                        case .idle:
                            EmptyView()
                        case .scanning(let role):
                            Label("Scanning \(role.title)… point the camera at its marker.", systemImage: "camera.metering.center.weighted")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(MatherTheme.ink)
                                .accessibilityIdentifier("room-scan-status")
                        case .celebrating(let role, let usedARCelebration):
                            Label(usedARCelebration ? "\(role.title) unlocked with AR sparkle!" : "\(role.title) found!", systemImage: usedARCelebration ? "sparkles.rectangle.stack.fill" : "checkmark.seal.fill")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(MatherTheme.accent)
                                .accessibilityIdentifier("room-scan-status")
                        case .almost(_, let message):
                            Label(message, systemImage: "scope")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(MatherTheme.warm)
                                .accessibilityIdentifier("room-scan-status")
                        case .failed(_, let message):
                            Label(message, systemImage: "exclamationmark.triangle.fill")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(MatherTheme.coral)
                                .accessibilityIdentifier("room-scan-status")
                        }
                    }
                }

                Button("Ready, start Room Quest!") {
                    engine.markSetupComplete()
                }
                .buttonStyle(PrimaryActionButtonStyle())
                .disabled(!engine.allStationsRegistered)
                .opacity(engine.allStationsRegistered ? 1 : 0.55)
            }
            .padding(24)
        }
        .sheet(isPresented: $showingConfiguration) {
            RoomQuestConfigurationScreen(featureFlags: engine.settings)
        }
    }

    private func stationCard(for station: RoomQuestStation) -> some View {
        let colour = station.role == .redRocket ? MatherTheme.warm : MatherTheme.accent

        return VStack(spacing: 12) {
            Text(station.isReadyForRoomQuest ? "Ready to play" : "Needs setup")
                .font(.caption.weight(.bold))
                .foregroundStyle(station.isReadyForRoomQuest ? MatherTheme.accent : MatherTheme.coral)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background((station.isReadyForRoomQuest ? MatherTheme.accent : MatherTheme.coral).opacity(0.14))
                .clipShape(Capsule())
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
            if let method = station.verificationMethod {
                Text(method.badgeTitle)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(colour)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(colour.opacity(0.14))
                    .clipShape(Capsule())
            }

            if station.referenceCaptureState != .notCaptured {
                Text(station.referenceCaptureState.badgeTitle)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(MatherTheme.ink)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(MatherTheme.ink.opacity(0.08))
                    .clipShape(Capsule())
            }

            if let referenceNote = station.referenceNote {
                Text(referenceNote)
                    .font(.caption)
                    .foregroundStyle(MatherTheme.cardSubtitle)
                    .multilineTextAlignment(.center)
            }

            referencePreview(for: station)

            VStack(spacing: 8) {
                Button(station.verificationMethod == .cameraVerified ? "Marker scanned" : "Scan station marker") {
                    engine.verifyStationWithCamera(station.role)
                }
                .buttonStyle(SecondaryTileButtonStyle(fill: colour.opacity(0.18)))
                .foregroundStyle(colour)
                .disabled({ if case .scanning = engine.scanState { return true } else { return false } }())
                .accessibilityIdentifier("room-station-camera-\(station.role.rawValue)")

                Button(station.verificationMethod == .manualConfirmed ? "Same-place fallback saved" : "Save same-place fallback") {
                    engine.confirmStationManually(station.role)
                }
                .buttonStyle(.plain)
                .font(.subheadline.weight(.bold))
                .foregroundStyle(colour.opacity(0.9))
                .accessibilityIdentifier("room-station-manual-\(station.role.rawValue)")
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("room-station-card-\(station.role.rawValue)")
    }

    @ViewBuilder
    private func referencePreview(for station: RoomQuestStation) -> some View {
        if let data = station.referenceImageJPEGData,
           let image = UIImage(data: data) {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .frame(height: 96)
                .frame(maxWidth: .infinity)
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .overlay(alignment: .bottomLeading) {
                    Text("Saved place photo")
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 5)
                        .background(.black.opacity(0.6), in: Capsule())
                        .padding(8)
                }
        } else if station.referenceCaptureState != .notCaptured {
            RoundedRectangle(cornerRadius: 14)
                .fill(MatherTheme.cardSubtitle.opacity(0.12))
                .frame(height: 96)
                .overlay {
                    VStack(spacing: 6) {
                        Image(systemName: station.referenceCaptureState == .captured ? "photo.badge.checkmark" : "checklist")
                            .font(.title3.weight(.semibold))
                        Text(station.referenceCaptureState == .captured ? "Place photo saved" : "Same-place fallback saved")
                            .font(.caption.weight(.semibold))
                    }
                    .foregroundStyle(MatherTheme.ink)
                }
        }
    }
}

private struct RoomQuestSetupConfigurationCard: View {
    @Bindable var featureFlags: FeatureFlagService
    @Binding var showingConfiguration: Bool

    var body: some View {
        CardSurface {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .top, spacing: 12) {
                    VStack(alignment: .leading, spacing: 6) {
                        Label("Room Quest setup & safety", systemImage: "slider.horizontal.3")
                            .font(.headline.weight(.semibold))
                            .foregroundStyle(MatherTheme.ink)
                        Text("Review the checklist, choose camera fallback behavior, and tune place matching before the child starts moving.")
                            .font(.subheadline)
                            .foregroundStyle(MatherTheme.cardSubtitle)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    Spacer()
                }

                VStack(alignment: .leading, spacing: 6) {
                    setupSummaryRow(title: "Safety checklist", value: featureFlags.roomQuestSafetyAcknowledged ? "Reviewed" : "First run shows checklist")
                    setupSummaryRow(title: "Marker scan", value: featureFlags.roomQuestMarkerSetupEnabled ? "On" : "Off")
                    setupSummaryRow(title: "Saved place photo", value: featureFlags.roomQuestReferenceCaptureEnabled ? "On" : "Off")
                }

                Button("Open Room Quest setup & safety") {
                    showingConfiguration = true
                }
                .buttonStyle(SecondaryTileButtonStyle(fill: MatherTheme.softBlue.opacity(0.18)))
                .foregroundStyle(MatherTheme.accent)
                .accessibilityIdentifier("roomquest-open-configuration")
            }
        }
    }

    private func setupSummaryRow(title: String, value: String) -> some View {
        HStack {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(MatherTheme.ink)
            Spacer()
            Text(value)
                .font(.caption.weight(.bold))
                .foregroundStyle(MatherTheme.cardSubtitle)
        }
    }
}

private struct RoomQuestConfigurationScreen: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var featureFlags: FeatureFlagService

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    CardSurface {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Room Quest setup & safety")
                                .font(.title2.weight(.bold))
                            Text("Keep this configuration close to setup so the parent can review it right before play.")
                                .font(.subheadline)
                                .foregroundStyle(MatherTheme.cardSubtitle)
                        }
                    }

                    CardSurface {
                        VStack(alignment: .leading, spacing: 12) {
                            Label("Camera setup", systemImage: "camera.badge.ellipsis")
                                .font(.headline.weight(.semibold))
                            Toggle("Use camera marker scans during setup", isOn: $featureFlags.roomQuestMarkerSetupEnabled)
                                .accessibilityIdentifier("roomquest-config-marker-toggle")
                            Toggle("Save a place photo after a successful scan", isOn: $featureFlags.roomQuestReferenceCaptureEnabled)
                                .accessibilityIdentifier("roomquest-config-reference-toggle")
                            Text("Turn both off if the room phase should run in same-place fallback mode only.")
                                .font(.caption)
                                .foregroundStyle(MatherTheme.cardSubtitle)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }

                    CardSurface {
                        VStack(alignment: .leading, spacing: 12) {
                            Label("Safety checklist", systemImage: "checklist")
                                .font(.headline.weight(.semibold))
                            Text("Review this before every Room Quest session:")
                                .font(.subheadline)
                                .foregroundStyle(MatherTheme.cardSubtitle)
                            RoomQuestSafetyChecklist()
                        }
                    }

                    CardSurface {
                        PlaceMatchThresholdSection(featureFlags: featureFlags)
                    }
                }
                .padding(24)
            }
            .background(MatherTheme.background.ignoresSafeArea())
            .navigationTitle("Room Quest Setup")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

private struct RoomQuestSafetyChecklist: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            safetyItem("Both spot-cards in the same room as this iPad")
            safetyItem("Spots are away from stairs, windows, and balconies")
            safetyItem("Spots are away from the kitchen")
            safetyItem("A parent stays nearby during the room phase")
            safetyItem("Nothing in the activity rewards running or jumping")
            safetyItem("Keep markers easy to see, but do not make the child walk while staring at the screen")
        }
    }

    private func safetyItem(_ text: String) -> some View {
        Label(text, systemImage: "checkmark.circle.fill")
            .font(.subheadline.weight(.medium))
            .foregroundStyle(MatherTheme.ink)
    }
}

private struct PlaceMatchThresholdSection: View {
    @Bindable var featureFlags: FeatureFlagService

    private let defaults = PlaceMatchThresholds.default

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Place matching")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                Spacer()
                Button("Reset") { resetToDefaults() }
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(MatherTheme.accent)
            }

            Text("Tune how strictly the camera and GPS must agree that the child is at the right spot. Lower = stricter. Check the Xcode console for [PlaceMatch] lines to see live distances.")
                .font(.caption)
                .foregroundStyle(MatherTheme.cardSubtitle)
                .fixedSize(horizontal: false, vertical: true)

            ThresholdSliderRow(
                label: "Vision match",
                unit: "",
                value: $featureFlags.placeMatchVisionMatch,
                range: 0.10...0.60,
                step: 0.05,
                defaultValue: Double(defaults.visionMatchDistance),
                format: "%.2f",
                hint: "Lower = more similar photos required. 0.25 rejects different rooms, 0.50 is lenient."
            )

            ThresholdSliderRow(
                label: "Vision close",
                unit: "",
                value: $featureFlags.placeMatchVisionClose,
                range: 0.20...1.00,
                step: 0.05,
                defaultValue: Double(defaults.visionCloseDistance),
                format: "%.2f",
                hint: "\"Almost there\" band. Should be above Vision match."
            )

            ThresholdSliderRow(
                label: "GPS match",
                unit: " m",
                value: $featureFlags.placeMatchGPSMatch,
                range: 3...20,
                step: 1,
                defaultValue: defaults.gpsMatchMetres,
                format: "%.0f",
                hint: "Metres. Outdoors, 8 m is reliable. Indoors, GPS is usually skipped by the accuracy cutoff."
            )

            ThresholdSliderRow(
                label: "GPS close",
                unit: " m",
                value: $featureFlags.placeMatchGPSClose,
                range: 10...50,
                step: 2,
                defaultValue: defaults.gpsCloseMetres,
                format: "%.0f",
                hint: "\"Almost there\" band for GPS. Should be above GPS match."
            )

            ThresholdSliderRow(
                label: "GPS accuracy cutoff",
                unit: " m",
                value: $featureFlags.placeMatchGPSCutoff,
                range: 3...20,
                step: 1,
                defaultValue: defaults.gpsAccuracyCutoff,
                format: "%.0f",
                hint: "Discard GPS fixes worse than this. 10 m blocks unreliable indoor readings."
            )
        }
        .font(.subheadline)
    }

    private func resetToDefaults() {
        featureFlags.placeMatchVisionMatch = Double(defaults.visionMatchDistance)
        featureFlags.placeMatchVisionClose = Double(defaults.visionCloseDistance)
        featureFlags.placeMatchGPSMatch = defaults.gpsMatchMetres
        featureFlags.placeMatchGPSClose = defaults.gpsCloseMetres
        featureFlags.placeMatchGPSCutoff = defaults.gpsAccuracyCutoff
    }
}

private struct ThresholdSliderRow: View {
    let label: String
    let unit: String
    @Binding var value: Double
    let range: ClosedRange<Double>
    let step: Double
    let defaultValue: Double
    let format: String
    let hint: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(label)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(MatherTheme.ink)
                Spacer()
                Text(String(format: format, value) + unit)
                    .font(.subheadline.weight(.black))
                    .foregroundStyle(value == defaultValue ? MatherTheme.cardSubtitle : MatherTheme.accent)
                    .monospacedDigit()
            }
            Slider(value: $value, in: range, step: step)
                .tint(value == defaultValue ? MatherTheme.cardSubtitle : MatherTheme.accent)
            Text(hint)
                .font(.caption)
                .foregroundStyle(MatherTheme.cardSubtitle)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.vertical, 2)
    }
}
