import Observation
import SwiftUI

struct SettingsView: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Bindable var appModel: AppModel
    let summaries: [StoredSessionSummary]

    @State private var showingClearConfirmation = false
    @State private var newProfileName = ""
    @State private var newProfileEmoji = KidProfileStore.emojiChoices[0]

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

    var body: some View {
        ZStack {
            MatherTheme.background.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 20) {
                    LazyVGrid(columns: ResponsiveLayout.settingsColumns(for: horizontalSizeClass), alignment: .leading, spacing: 20) {
                        settingsCard
                        profilesCard
                        historyCard
                        smokeTestCard
                    }

                    Button(role: .destructive) {
                        showingClearConfirmation = true
                    } label: {
                        Text("Clear session history")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(PrimaryActionButtonStyle())
                    .tint(MatherTheme.danger)

                    Group {
                        if ResponsiveLayout.isWide(horizontalSizeClass) {
                            HStack(spacing: 16) {
                                footerButtons
                            }
                        } else {
                            VStack(spacing: 12) {
                                footerButtons
                            }
                        }
                    }
                }
                .padding(ResponsiveLayout.contentPadding(for: horizontalSizeClass))
                .frame(maxWidth: ResponsiveLayout.contentMaxWidth(for: horizontalSizeClass))
                .frame(maxWidth: .infinity)
            }
        }
        .alert("Clear all session data?", isPresented: $showingClearConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Clear", role: .destructive) {
                appModel.historyStore.clearAll()
                appModel.telemetryWriter.clearEventsForActiveProfile()
            }
        } message: {
            Text("This removes saved summaries and telemetry events for the active kid profile.")
        }
    }

    private var settingsCard: some View {
        CardSurface {
            VStack(alignment: .leading, spacing: 16) {
                Text("Settings")
                    .font(.largeTitle.weight(.black))

                Text("Make & Break")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .padding(.top, 4)
                Text("The repeated Make it → Gravity Split → Sum Sprint → Bond Blast route is now built in for every target.")
                    .font(.subheadline)
                    .foregroundStyle(MatherTheme.cardSubtitle)
                    .fixedSize(horizontal: false, vertical: true)

                Divider()

                RoomQuestSettingsEntry(appModel: appModel)

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
                    subtitle: "On by default. Listens for a clap to trigger celebrations when microphone access is available.",
                    isOn: soundReactionBinding
                )
            }
            .font(.title3.weight(.semibold))
        }
    }

    private var profilesCard: some View {
        CardSurface {
            VStack(alignment: .leading, spacing: 14) {
                Text("Kid profiles")
                    .font(.title2.weight(.bold))
                Text("Each profile keeps session data separate. Parent summary combines all profiles.")
                    .foregroundStyle(MatherTheme.cardSubtitle)

                Picker("Active profile", selection: Binding(
                    get: { appModel.profileStore.activeProfileId },
                    set: { appModel.profileStore.setActiveProfile(id: $0) }
                )) {
                    ForEach(appModel.profileStore.profiles, id: \.id) { profile in
                        Text("\(profile.emoji) \(profile.name)")
                            .tag(profile.id)
                    }
                }

                Group {
                    if ResponsiveLayout.isWide(horizontalSizeClass) {
                        HStack(alignment: .top, spacing: 12) {
                            profileInputs
                        }
                    } else {
                        VStack(alignment: .leading, spacing: 12) {
                            profileInputs
                        }
                    }
                }

                Button("Add profile") {
                    appModel.profileStore.addProfile(name: newProfileName, emoji: newProfileEmoji)
                    newProfileName = ""
                }
                .buttonStyle(PrimaryActionButtonStyle())
            }
        }
    }

    private var profileInputs: some View {
        Group {
            TextField("New profile name", text: $newProfileName)
                .textFieldStyle(.roundedBorder)

            Picker("Emoji", selection: $newProfileEmoji) {
                ForEach(KidProfileStore.emojiChoices, id: \.self) { emoji in
                    Text(emoji).tag(emoji)
                }
            }
            .pickerStyle(.menu)
        }
    }

    private var historyCard: some View {
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
                        Text(summary.exportFileName.replacingOccurrences(of: "swiftdata://session/", with: "Session ID "))
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
    }

    private var smokeTestCard: some View {
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
                    smokeStep("4. Confirm events are writing to the on-device SwiftData telemetry store.")
                }
            }
        }
    }

    private var footerButtons: some View {
        Group {
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
}

private struct RoomQuestSettingsEntry: View {
    let appModel: AppModel

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Room Quest")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            Text("Safety, camera setup, and place-matching tuning now live inside Room Quest setup.")
                .font(.subheadline)
                .foregroundStyle(MatherTheme.cardSubtitle)
                .fixedSize(horizontal: false, vertical: true)

            Button("Open Room Quest setup") {
                appModel.engine.showRoomQuest()
            }
            .font(.subheadline.weight(.medium))
            .foregroundStyle(MatherTheme.accent)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.leading, 4)
            .accessibilityIdentifier("settings-roomquest-open")

            Text(appModel.featureFlags.roomQuestSafetyAcknowledged ? "Safety checklist already acknowledged on this device." : "The one-time safety checklist appears when you open Room Quest.")
                .font(.caption)
                .foregroundStyle(MatherTheme.cardSubtitle)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}
