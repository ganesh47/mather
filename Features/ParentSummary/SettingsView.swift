import Observation
import SwiftUI

struct SettingsView: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Bindable var appModel: AppModel
    let summaries: [StoredSessionSummary]
    let gameSessions: [StoredGameSession]

    @State private var showingClearConfirmation = false
    @State private var showingReportDeletion = false
    @State private var showingQuestDeletion = false
    @State private var reportStore = ParentOffscreenObservationStore()
    @State private var resetProfileID: String?
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

    private var activeProfileBinding: Binding<String> {
        Binding(
            get: { appModel.profileStore.activeProfileId },
            set: { appModel.profileStore.setActiveProfile(id: $0) }
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
                    if ResponsiveLayout.isWide(horizontalSizeClass) {
                        LazyVGrid(columns: ResponsiveLayout.settingsColumns(for: horizontalSizeClass), alignment: .leading, spacing: 20) {
                            settingsCard
                            profilesCard
                            historySummaryCard
                            dataResetCard
                            if appModel.featureFlags.testModeEnabled {
                                smokeTestCard
                            }
                        }
                    } else {
                        VStack(spacing: 16) {
                            settingsCard
                            profilesCard
                            historySummaryCard
                            dataResetCard
                            if appModel.featureFlags.testModeEnabled {
                                smokeTestCard
                            }
                        }
                    }

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
        .alert("Clear this child's learning data?", isPresented: $showingClearConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Clear", role: .destructive) {
                if appModel.profileStore.activeProfileId == resetProfileID { appModel.clearActiveProfileLearningData() }
                else { appModel.learningDataResetIssue = "The selected child changed. Choose the child again before clearing learning data." }
                reportStore = ParentOffscreenObservationStore()
            }
        } message: {
            Text("This removes summaries, learning attempts, saved quest steps, Explorer and Angle progress, telemetry, parent reports and companion assignments for the selected child on this device. Other children keep their history. Anonymous consumed mission receipts remain.")
        }
        .alert("Delete all parent reports?", isPresented: $showingReportDeletion) {
            Button("Cancel", role: .cancel) {}
            Button("Delete all parent reports", role: .destructive) {
                reportStore.clearAllProfiles()
                appModel.learningDataResetIssue = nil
            }
        } message: {
            Text("This deletes parent offscreen reports for every child on this device, including unreadable saved reports. App learning attempts remain. This cannot be undone.")
        }
        .alert("Delete all quest checkpoints?", isPresented: $showingQuestDeletion) {
            Button("Cancel", role: .cancel) {}
            Button("Delete all quest checkpoints", role: .destructive) {
                appModel.questCheckpointStore.clearAllProfiles()
                appModel.learningDataResetIssue = nil
            }
        } message: {
            Text("This deletes saved guided quest steps and reviewed variant and probe history for every child on this device, including unreadable saved checkpoints. Learning attempts and parent reports remain. This cannot be undone.")
        }
    }

    private var settingsCard: some View {
        CardSurface {
            VStack(alignment: .leading, spacing: 18) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Settings")
                        .font(.largeTitle.weight(.black))
                    Text("Quick parent controls. History and data actions stay compact here.")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(MatherTheme.cardSubtitle)
                        .fixedSize(horizontal: false, vertical: true)
                }

                settingsSection(title: "Learning content", systemImage: "arrow.down.circle.fill") {
                    Text("Version \(appModel.iosLearningContentStore.catalog.contentVersion)")
                        .font(.headline.bold()).accessibilityIdentifier("ios-learning-content-version")
                    Text(appModel.iosLearningContentStore.catalog.contentVersion > IOSLearningCatalog.bundled.contentVersion
                         ? "Verified downloaded content is saved on this device and works offline. Updates appear between activities."
                         : "Bundled content is available offline. Verified updates download automatically when this device is online.")
                        .font(.subheadline).foregroundStyle(MatherTheme.cardSubtitle).fixedSize(horizontal: false, vertical: true)
                    if appModel.iosLearningContentStore.isRefreshing {
                        Text("Downloading and checking a content update. Current content stays available.")
                            .font(.caption).foregroundStyle(MatherTheme.cardSubtitle)
                            .accessibilityIdentifier("ios-learning-content-update-status")
                    } else if appModel.iosLearningContentStore.lastRefreshError != nil {
                        Text("The latest update could not be checked. The saved content remains available.")
                            .font(.caption).foregroundStyle(MatherTheme.cardSubtitle)
                    }
                }

                settingsSection(title: "Child experience", systemImage: "sparkles") {
                    Text("Make & Break route")
                        .font(.headline.weight(.bold))
                    Text("Make it → Gravity Split → Sum Sprint → Bond Blast is built in for every target.")
                        .font(.subheadline)
                        .foregroundStyle(MatherTheme.cardSubtitle)
                        .fixedSize(horizontal: false, vertical: true)
                    RoomQuestSettingsEntry(appModel: appModel)
                }

                settingsSection(title: "Feedback", systemImage: "speaker.wave.2.fill") {
                    Toggle("Audio prompts", isOn: audioBinding)
                        .tint(MatherTheme.accent)
                    Toggle("Haptics", isOn: hapticsBinding)
                        .tint(MatherTheme.accent)
                }

                settingsSection(title: "Advanced controls", systemImage: "slider.horizontal.3") {
                    VS1ToggleRow(
                        title: "Motion controls",
                        subtitle: "Lets the child wave the iPad to celebrate correct answers.",
                        isOn: motionBinding
                    )
                    VS1ToggleRow(
                        title: "Clap reaction (mic)",
                        subtitle: "Off by default. If a parent turns it on, Mather asks for microphone access and only listens for a clap to trigger celebrations.",
                        isOn: soundReactionBinding
                    )
                 }
             }
        }
    }

    private func settingsSection<Content: View>(title: String, systemImage: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(title, systemImage: systemImage)
                .font(.headline.weight(.black))
                .foregroundStyle(MatherTheme.ink)
            content()
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(MatherTheme.panel.opacity(0.45))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private var profilesCard: some View {
        CardSurface {
            VStack(alignment: .leading, spacing: 14) {
                Text("Kid profiles")
                    .font(.title2.weight(.bold))
                Text("Each child keeps learning attempts, saved steps, and history separate. Parent Summary shows the selected child.")
                    .foregroundStyle(MatherTheme.cardSubtitle)

                activeProfilePicker
                profileInputLayout

                Button("Add profile") {
                    appModel.profileStore.addProfile(name: newProfileName, emoji: newProfileEmoji)
                    newProfileName = ""
                }
                .buttonStyle(PrimaryActionButtonStyle())
                .accessibilityIdentifier("settings-add-profile")
            }
        }
    }

    private var profileOptions: [KidProfileOption] {
        appModel.profileStore.profiles.map { profile in
            KidProfileOption(id: profile.id, label: "\(profile.emoji) \(profile.name)")
        }
    }

    private var activeProfilePicker: some View {
        Picker("Active profile", selection: activeProfileBinding) {
            ForEach(profileOptions) { option in
                Text(option.label)
                    .tag(option.id)
            }
        }
    }

    @ViewBuilder
    private var profileInputLayout: some View {
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

    private var historySummaryCard: some View {
        CardSurface {
            VStack(alignment: .leading, spacing: 12) {
                Text("Session history")
                    .font(.title2.weight(.bold))
                let savedCount = summaries.count + gameSessions.count + appModel.gameplayProgressStore.allSessions().count
                Text(savedCount == 0 ? "No history saved yet." : "\(savedCount) saved locally for this child")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(MatherTheme.cardSubtitle)
                    .accessibilityIdentifier("settings-history-summary")
                Text("Open Parent Summary for the full timeline, trends, and next-step guidance.")
                    .font(.caption)
                    .foregroundStyle(MatherTheme.cardSubtitle)
                    .fixedSize(horizontal: false, vertical: true)

                Button {
                    appModel.engine.showParentSummary()
                } label: {
                    Label("View full history", systemImage: "chart.line.uptrend.xyaxis")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(SecondaryTileButtonStyle(fill: MatherTheme.softBlue.opacity(0.7)))
                .accessibilityIdentifier("settings-view-full-history")
            }
        }
    }

    private var dataResetCard: some View {
        CardSurface {
            VStack(alignment: .leading, spacing: 12) {
                Text("Data reset")
                    .font(.title2.weight(.bold))
                Text("Clears this child's learning attempts, summaries, quest checkpoints, Explorer and Angle progress, telemetry, parent reports and companion assignment on this device.")
                    .font(.subheadline)
                    .foregroundStyle(MatherTheme.cardSubtitle)
                    .fixedSize(horizontal: false, vertical: true)
                Button(role: .destructive) {
                    resetProfileID = appModel.profileStore.activeProfileId
                    showingClearConfirmation = true
                } label: {
                    Label("Clear session history", systemImage: "trash")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(DestructiveOutlineButtonStyle())
                .accessibilityIdentifier("settings-clear-history")
                if let issue = appModel.learningDataResetIssue {
                    Text(issue).foregroundStyle(.red).accessibilityIdentifier("settings-reset-issue")
                }
                if let issue = reportStore.storageIssue {
                    Text(issue.message).foregroundStyle(.red)
                    Button("Delete all parent reports", role: .destructive) { showingReportDeletion = true }
                        .buttonStyle(DestructiveOutlineButtonStyle())
                        .accessibilityIdentifier("settings-delete-all-parent-reports")
                }
                if let issue = appModel.questCheckpointStore.storageIssue {
                    Text(issue.message).foregroundStyle(.red)
                    Button("Delete all quest checkpoints", role: .destructive) { showingQuestDeletion = true }
                        .buttonStyle(DestructiveOutlineButtonStyle())
                        .accessibilityIdentifier("settings-delete-all-quest-checkpoints")
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

private struct KidProfileOption: Identifiable {
    let id: String
    let label: String
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
            .font(.headline.weight(.bold))
            .foregroundStyle(MatherTheme.ink)
            .frame(maxWidth: .infinity, minHeight: 80, alignment: .leading)
            .padding(.horizontal, 12)
            .background(MatherTheme.softBlue.opacity(0.45))
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .accessibilityIdentifier("settings-roomquest-open")

            Text(appModel.featureFlags.roomQuestSafetyAcknowledged ? "Safety checklist already acknowledged on this device." : "The one-time safety checklist appears when you open Room Quest.")
                .font(.caption)
                .foregroundStyle(MatherTheme.cardSubtitle)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}


private struct DestructiveOutlineButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline.weight(.bold))
            .foregroundStyle(MatherTheme.danger)
            .padding(.vertical, 14)
            .padding(.horizontal, 16)
            .background(configuration.isPressed ? MatherTheme.danger.opacity(0.16) : MatherTheme.danger.opacity(0.08))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(MatherTheme.danger.opacity(0.55), lineWidth: 1.5)
            )
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}
