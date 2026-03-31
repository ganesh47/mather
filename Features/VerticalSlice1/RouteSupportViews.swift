import Observation
import SwiftUI

struct VS1ParentSummaryPlaceholderView: View {
    @Bindable var appModel: AppModel
    let summaries: [StoredSessionSummary]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                VS1TitleBlock(
                    eyebrow: "Parent",
                    title: "Session summary",
                    subtitle: "A minimal placeholder that keeps the app shell usable until the dedicated parent thread lands."
                )

                VS1Card {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Recent sessions")
                            .font(.headline.weight(.bold))
                        ForEach(summaries.prefix(5), id: \.sessionId) { summary in
                            VStack(alignment: .leading, spacing: 4) {
                                Text(summary.objectiveTitle)
                                    .font(.headline.weight(.semibold))
                                Text(summary.startedAt.formatted(date: .abbreviated, time: .shortened))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.vertical, 6)
                        }
                    }
                }

                VS1SecondaryButton(title: "Back", systemImage: "chevron.left") {
                    appModel.engine.showHome()
                }
            }
            .padding(24)
            .frame(maxWidth: 760)
            .frame(maxWidth: .infinity, alignment: .center)
        }
    }
}

struct VS1SettingsPlaceholderView: View {
    @Bindable var appModel: AppModel
    let summaries: [StoredSessionSummary]
    @State private var confirmClear = false

    private var verticalSliceBinding: Binding<Bool> {
        Binding(
            get: { appModel.featureFlags.verticalSlice1Enabled },
            set: { appModel.featureFlags.verticalSlice1Enabled = $0 }
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

    private var testModeBinding: Binding<Bool> {
        Binding(
            get: { appModel.featureFlags.testModeEnabled },
            set: { appModel.featureFlags.testModeEnabled = $0 }
        )
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                VS1TitleBlock(
                    eyebrow: "Settings",
                    title: "Local controls",
                    subtitle: "Feature flag, audio, and export helpers stay on-device for this alpha."
                )

                VS1Card {
                    VStack(alignment: .leading, spacing: 12) {
                        VS1ToggleRow(
                            title: "VS1 enabled",
                            subtitle: "Let the child flow show its current slice routes.",
                            isOn: verticalSliceBinding
                        )
                        VS1ToggleRow(
                            title: "Audio enabled",
                            subtitle: "Keep prompts and neutral feedback audible.",
                            isOn: audioBinding
                        )
                        VS1ToggleRow(
                            title: "Haptics enabled",
                            subtitle: "Reserved for later implementation, kept as a visible setting.",
                            isOn: hapticsBinding
                        )
                        VS1ToggleRow(
                            title: "Test mode",
                            subtitle: "Deterministic ordering for repeatable pilot checks.",
                            isOn: testModeBinding
                        )
                    }
                }

                VS1Card {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("History")
                            .font(.headline.weight(.bold))
                        Text("\(summaries.count) stored summaries")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        VS1SecondaryButton(title: "Clear session history", systemImage: "trash") {
                            confirmClear = true
                        }
                    }
                }

                VS1SecondaryButton(title: "Back", systemImage: "chevron.left") {
                    appModel.engine.showHome()
                }
            }
            .padding(24)
            .frame(maxWidth: 760)
            .frame(maxWidth: .infinity, alignment: .center)
        }
        .confirmationDialog("Clear all session summaries?", isPresented: $confirmClear, titleVisibility: .visible) {
            Button("Clear", role: .destructive) {
                appModel.historyStore.clearAll()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This removes only local summaries and export metadata.")
        }
    }
}
