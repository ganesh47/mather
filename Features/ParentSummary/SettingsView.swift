import Observation
import SwiftUI

struct SettingsView: View {
    @Bindable var appModel: AppModel
    let summaries: [StoredSessionSummary]

    @State private var showingClearConfirmation = false

    private var verticalSliceBinding: Binding<Bool> {
        Binding(
            get: { appModel.featureFlags.verticalSlice1Enabled },
            set: { appModel.featureFlags.verticalSlice1Enabled = $0 }
        )
    }

    private var testModeBinding: Binding<Bool> {
        Binding(
            get: { appModel.featureFlags.testModeEnabled },
            set: { appModel.featureFlags.testModeEnabled = $0 }
        )
    }

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

                            Toggle("Make & Break to 10", isOn: verticalSliceBinding)
                                .lineLimit(1)
                                .minimumScaleFactor(0.85)
                            Toggle("Test mode", isOn: testModeBinding)
                            Toggle("Audio prompts", isOn: audioBinding)
                            Toggle("Haptics", isOn: hapticsBinding)
                        }
                        .font(.title3.weight(.semibold))
                    }

                    CardSurface {
                        VStack(alignment: .leading, spacing: 14) {
                            Text("Export and review")
                                .font(.title2.weight(.bold))
                            Text(latestExportURL == nil ? "Run a session to create the first JSONL export." : "The most recent session export is ready to share from this device.")
                                .foregroundStyle(.secondary)

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
                                .foregroundStyle(.secondary)
                            ForEach(Array(summaries.prefix(8).enumerated()), id: \.element.sessionId) { index, summary in
                                HStack {
                                    VStack(alignment: .leading) {
                                        Text("Session \(index + 1)")
                                            .font(.caption.weight(.bold))
                                            .foregroundStyle(MatherTheme.accent)
                                        Text(summary.startedAt.formatted(date: .abbreviated, time: .shortened))
                                        Text("Accuracy \(Int(summary.firstAttemptAccuracy * 100))%")
                                            .foregroundStyle(.secondary)
                                    }
                                    Spacer()
                                    Text(summary.exportFileName)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                .padding(.vertical, 4)
                                .accessibilityElement(children: .combine)
                                .accessibilityIdentifier("settings-history-session-\(index)")
                            }
                            if summaries.isEmpty {
                                Text("No history yet.")
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }

                    CardSurface {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Pilot smoke test")
                                .font(.title2.weight(.bold))
                            Text("Run this checklist before each new pilot session:")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            VStack(alignment: .leading, spacing: 8) {
                                smokeStep("1. Enable Make & Break to 10 (toggle above).")
                                smokeStep("2. Tap Home → Play → Start Session.")
                                smokeStep("3. Complete one full problem (Make → Break → Write → Show).")
                                smokeStep("4. Confirm Session Complete screen appears.")
                                smokeStep("5. Return here and tap Share latest export to verify JSONL.")
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
                        Button("Home") {
                            appModel.engine.showHome()
                        }
                        .buttonStyle(SecondaryTileButtonStyle(fill: MatherTheme.softBlue.opacity(0.7)))

                        Button("Parent Summary") {
                            appModel.engine.showParentSummary()
                        }
                        .buttonStyle(SecondaryTileButtonStyle(fill: MatherTheme.warm.opacity(0.7)))
                    }
                }
                .padding(24)
            }
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
