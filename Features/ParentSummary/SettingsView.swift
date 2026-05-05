import Observation
import SwiftUI

struct SettingsView: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Bindable var appModel: AppModel
    let summaries: [StoredSessionSummary]
    let gameSessions: [StoredGameSession]

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
        .alert("Clear all session data?", isPresented: $showingClearConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Clear", role: .destructive) {
                appModel.historyStore.clearAll()
                appModel.gameSessionStore.clearAll()
                appModel.telemetryWriter.clearEventsForActiveProfile()
            }
        } message: {
            Text("This removes saved summaries and telemetry events for the active kid profile.")
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
                .accessibilityIdentifier("settings-add-profile")
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
                let savedCount = summaries.count + gameSessions.count
                Text(savedCount == 0 ? "No history saved yet." : "\(savedCount) saved locally across all games")
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
                Text("Clears saved summaries, cross-game sessions, and telemetry events for the active kid profile on this device.")
                    .font(.subheadline)
                    .foregroundStyle(MatherTheme.cardSubtitle)
                    .fixedSize(horizontal: false, vertical: true)
                Button(role: .destructive) {
                    showingClearConfirmation = true
                } label: {
                    Label("Clear session history", systemImage: "trash")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(DestructiveOutlineButtonStyle())
                .accessibilityIdentifier("settings-clear-history")
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
            .font(.headline.weight(.bold))
            .foregroundStyle(MatherTheme.ink)
            .frame(maxWidth: .infinity, minHeight: 48, alignment: .leading)
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
