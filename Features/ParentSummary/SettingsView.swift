import Observation
import SwiftUI

struct SettingsView: View {
    @Bindable var appModel: AppModel
    let summaries: [StoredSessionSummary]

    @State private var showingClearConfirmation = false
    @State private var showingSafetyRules = false

    private var audioBinding: Binding<Bool> {
        Binding(
            get: { appModel.featureFlags.audioEnabled },
            set: { appModel.featureFlags.audioEnabled = $0 }
        )
    }

    private var hapticsBinding: Binding<Bool> {
        Binding(
            get: { appModel.featureFlags.hapticsEnabled },
            set: { appModel.featureFlags.hapticsEnabled = $0 }
        )
    }

    private var motionBinding: Binding<Bool> {
        Binding(
            get: { appModel.featureFlags.motionControlsEnabled },
            set: { appModel.featureFlags.motionControlsEnabled = $0 }
        )
    }

    private var soundReactionBinding: Binding<Bool> {
        Binding(
            get: { appModel.featureFlags.soundReactionEnabled },
            set: { appModel.featureFlags.soundReactionEnabled = $0 }
        )
    }

    private func smokeStep(_ text: String) -> some View {
        Label(text, systemImage: "checkmark.circle")
            .font(.subheadline)
            .foregroundStyle(.primary)
    }

    private var latestExportURL: URL? {
        if let current = appModel.telemetryWriter.currentExport?.url {
            return current
        }
        guard let latest = summaries.first else { return nil }
        return appModel.telemetryWriter.exportURL(fileName: latest.exportFileName)
    }

    var body: some View {
        ZStack {
            MatherTheme.background.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 20) {
                    CardSurface {
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Settings")
                                .font(.largeTitle.weight(.black))

                            Text("Room Quest")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.secondary)
                            Button("Review Room Quest safety rules") {
                                showingSafetyRules = true
                            }
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(MatherTheme.accent)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.leading, 4)

                            Divider()

                            PlaceMatchThresholdSection(featureFlags: appModel.featureFlags)

                            Divider()

                            Text("Feedback")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.secondary)
                            Toggle("Audio prompts", isOn: audioBinding)
                            Toggle("Haptics", isOn: hapticsBinding)

                            Divider()

                            Text("Advanced")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.secondary)
                            VS1ToggleRow(
                                title: "Motion controls",
                                subtitle: "Lets the child wave the iPad to celebrate correct answers.",
                                isOn: motionBinding
                            )
                            VS1ToggleRow(
                                title: "Clap reaction (mic)",
                                subtitle: "Listens for a clap to trigger celebrations (uses microphone).",
                                isOn: soundReactionBinding
                            )
                        }
                        .font(.title3.weight(.semibold))
                    }

                    CardSurface {
                        VStack(alignment: .leading, spacing: 14) {
                            Text("Export and review")
                                .font(.title2.weight(.bold))
                            Text(latestExportURL == nil ? "Run a session to create the first JSONL export." : "The most recent session export is ready to share from this device.")
                                .foregroundStyle(MatherTheme.cardSubtitle)

                            if let latestExportURL, FileManager.default.fileExists(atPath: latestExportURL.path) {
                                ShareLink(item: latestExportURL) {
                                    Text("Share latest export")
                                        .frame(maxWidth: .infinity)
                                }
                                .buttonStyle(PrimaryActionButtonStyle())
                            }
                        }
                    }

                    CardSurface {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Session history")
                                .font(.title2.weight(.bold))
                            Text("\(summaries.count) saved locally")
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(MatherTheme.cardSubtitle)
                            ForEach(Array(summaries.prefix(8).enumerated()), id: \.element.sessionId) { index, summary in
                                HStack {
                                    VStack(alignment: .leading) {
                                        Text("Session \(index + 1)")
                                            .font(.caption.weight(.bold))
                                            .foregroundStyle(MatherTheme.accent)
                                        Text(summary.startedAt.formatted(date: .abbreviated, time: .shortened))
                                        Text("Accuracy \(Int(summary.firstAttemptAccuracy * 100))%")
                                            .foregroundStyle(MatherTheme.cardSubtitle)
                                    }
                                    Spacer()
                                    Text(summary.exportFileName)
                                        .font(.caption)
                                        .foregroundStyle(MatherTheme.cardSubtitle)
                                }
                                .padding(.vertical, 4)
                                .accessibilityElement(children: .combine)
                                .accessibilityIdentifier("settings-history-session-\(index)")
                            }
                            if summaries.isEmpty {
                                Text("No history yet.")
                                    .foregroundStyle(MatherTheme.cardSubtitle)
                            }
                        }
                    }

                    CardSurface {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Pilot smoke test")
                                .font(.title2.weight(.bold))
                            Text("Run this checklist before each new pilot session:")
                                .font(.subheadline)
                                .foregroundStyle(MatherTheme.cardSubtitle)
                            VStack(alignment: .leading, spacing: 8) {
                                smokeStep("1. Tap Home → Play → Start Session.")
                                smokeStep("2. Verify Make → Gravity Split → Sum Sprint → Bond Blast.")
                                smokeStep("3. Confirm Session Complete screen appears.")
                                smokeStep("4. Return here and tap Share latest export to verify JSONL.")
                            }
                        }
                    }

                    Button(role: .destructive) {
                        showingClearConfirmation = true
                    } label: {
                        Text("Clear session history")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(PrimaryActionButtonStyle())
                    .tint(MatherTheme.danger)

                    HStack(spacing: 16) {
                        Button("Parent Summary") {
                            appModel.engine.showParentSummary()
                        }
                        .buttonStyle(SecondaryTileButtonStyle(fill: MatherTheme.softBlue.opacity(0.7)))

                        Button("Home") {
                            appModel.engine.showHome()
                        }
                        .buttonStyle(SecondaryTileButtonStyle(fill: MatherTheme.warm.opacity(0.7)))
                    }
                }
                .padding(24)
            }
        }
        .sheet(isPresented: $showingSafetyRules) {
            RoomSafetyRulesSheet()
        }
        .alert("Clear all session data?", isPresented: $showingClearConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Clear", role: .destructive) {
                appModel.historyStore.clearAll()
                appModel.telemetryWriter.clearExports()
            }
        } message: {
            Text("This removes saved summaries and local JSONL exports.")
        }
    }
}

// MARK: - Place matching threshold sliders

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
                hint: "Lower = more similar photos required. 0.25 rejects different rooms; 0.50 is lenient."
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
                hint: "Metres. Outdoors: 8 m is reliable. Indoors: GPS is usually skipped by the accuracy cutoff."
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
        featureFlags.placeMatchGPSMatch    = defaults.gpsMatchMetres
        featureFlags.placeMatchGPSClose    = defaults.gpsCloseMetres
        featureFlags.placeMatchGPSCutoff   = defaults.gpsAccuracyCutoff
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

// MARK: - Room Quest safety rules sheet

private struct RoomSafetyRulesSheet: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("Before every Room Quest session, confirm:")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    CardSurface {
                        VStack(alignment: .leading, spacing: 12) {
                            Label("Safety checklist", systemImage: "checklist")
                                .font(.headline.weight(.semibold))
                            safetyItem("Both spot-cards in the same room as this iPad")
                            safetyItem("Spots are away from stairs, windows, and balconies")
                            safetyItem("Spots are away from the kitchen")
                            safetyItem("A parent stays nearby during the room phase")
                            safetyItem("Nothing in the activity rewards running or jumping")
                        }
                    }
                }
                .padding(24)
            }
            .background(MatherTheme.background.ignoresSafeArea())
            .navigationTitle("Room Quest Safety")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private func safetyItem(_ text: String) -> some View {
        Label(text, systemImage: "checkmark.circle.fill")
            .font(.subheadline.weight(.medium))
            .foregroundStyle(MatherTheme.ink)
    }
}
