import SwiftData
import SwiftUI

struct ProfilePickerView: View {
    @Bindable var appModel: AppModel
    @Query(sort: \StoredKidProfile.createdAt) private var profiles: [StoredKidProfile]
    @State private var showingCreation = false
    @State private var newName = ""
    @State private var selectedEmoji = "🦊"

    private var hasProfiles: Bool { !profiles.isEmpty }

    var body: some View {
        ZStack {
            MatherTheme.background.ignoresSafeArea()
            VStack(spacing: 0) {
                headerSection
                ScrollView {
                    VStack(spacing: 20) {
                        if hasProfiles {
                            profileGrid
                        }
                        addKidSection
                    }
                    .padding(24)
                }
            }
        }
        .interactiveDismissDisabled(true)
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(spacing: 6) {
            Text("Who's playing?")
                .font(.system(size: 34, weight: .black, design: .rounded))
                .foregroundStyle(MatherTheme.ink)
            Text("Pick a profile to get started")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 40)
        .padding(.bottom, 20)
        .padding(.horizontal, 24)
    }

    // MARK: - Profile grid

    private var profileGrid: some View {
        LazyVGrid(
            columns: [GridItem(.flexible(), spacing: 16), GridItem(.flexible(), spacing: 16)],
            spacing: 16
        ) {
            ForEach(profiles) { profile in
                ProfileTile(profile: profile) {
                    appModel.selectProfile(profile)
                }
            }
        }
    }

    // MARK: - Add kid

    private var addKidSection: some View {
        VStack(spacing: 16) {
            if showingCreation {
                creationForm
            } else {
                Button {
                    showingCreation = true
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .foregroundStyle(MatherTheme.accent)
                        Text(hasProfiles ? "Add another kid" : "Create a profile")
                            .font(.headline.weight(.bold))
                            .foregroundStyle(MatherTheme.ink)
                        Spacer()
                    }
                    .padding(20)
                    .background(MatherTheme.card)
                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Creation form

    private var creationForm: some View {
        VStack(spacing: 20) {
            Text("New profile")
                .font(.title3.weight(.bold))
                .frame(maxWidth: .infinity, alignment: .leading)

            emojiPicker

            TextField("Name", text: $newName)
                .font(.title3.weight(.semibold))
                .textFieldStyle(.plain)
                .padding(16)
                .background(MatherTheme.background)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .strokeBorder(MatherTheme.accent.opacity(0.3), lineWidth: 1.5)
                )
                .autocorrectionDisabled()
                .onChange(of: newName) { _, value in
                    if value.count > 20 { newName = String(value.prefix(20)) }
                }

            HStack(spacing: 12) {
                if hasProfiles {
                    Button("Cancel") {
                        showingCreation = false
                        newName = ""
                        selectedEmoji = "🦊"
                    }
                    .buttonStyle(SecondaryTileButtonStyle(fill: Color.secondary.opacity(0.15)))
                }

                Button("Start playing!") {
                    guard !newName.trimmingCharacters(in: .whitespaces).isEmpty else { return }
                    let profile = appModel.profileStore.insert(
                        name: newName.trimmingCharacters(in: .whitespaces),
                        emoji: selectedEmoji
                    )
                    appModel.selectProfile(profile)
                }
                .buttonStyle(SecondaryTileButtonStyle(fill: MatherTheme.accent.opacity(0.85)))
                .disabled(newName.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
        .padding(20)
        .background(MatherTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    // MARK: - Emoji picker

    private var emojiPicker: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Pick a picture")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 6), spacing: 8) {
                ForEach(ProfilePickerView.kidEmojis, id: \.self) { emoji in
                    Button {
                        selectedEmoji = emoji
                    } label: {
                        Text(emoji)
                            .font(.system(size: 30))
                            .frame(width: 48, height: 48)
                            .background(selectedEmoji == emoji ? MatherTheme.accent.opacity(0.2) : Color.clear)
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .strokeBorder(
                                        selectedEmoji == emoji ? MatherTheme.accent : Color.clear,
                                        lineWidth: 2
                                    )
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    static let kidEmojis: [String] = [
        "🦊", "🐶", "🐱", "🐼", "🐨", "🦁",
        "🐸", "🐧", "🦋", "🦄", "🐢", "🐬",
        "🦖", "🐙", "🦀", "🐝", "🦔", "🐿️",
        "🚀", "⭐️", "🌈", "🎈", "🏆", "🎨",
        "⚽️", "🏀", "🎸", "🎯", "🍎", "🍦",
    ]
}

// MARK: - Profile tile

private struct ProfileTile: View {
    let profile: StoredKidProfile
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 10) {
                Text(profile.emoji)
                    .font(.system(size: 52))
                    .frame(width: 80, height: 80)
                    .background(MatherTheme.accent.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))

                Text(profile.name)
                    .font(.headline.weight(.bold))
                    .foregroundStyle(MatherTheme.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
            .background(MatherTheme.card)
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Play as \(profile.name)")
    }
}
