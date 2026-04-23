import Observation
import SwiftUI

struct VS1ParentSummaryPlaceholderView: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
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
            .frame(maxWidth: ResponsiveLayout.contentMaxWidth(for: horizontalSizeClass))
            .frame(maxWidth: .infinity, alignment: .center)
        }
    }
}

struct VS1SettingsPlaceholderView: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Bindable var appModel: AppModel
    let summaries: [StoredSessionSummary]
    @State private var confirmClear = false

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
                        Text("Make & Break and the current Bond Blast loop are on by default.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
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
            .frame(maxWidth: ResponsiveLayout.contentMaxWidth(for: horizontalSizeClass))
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
