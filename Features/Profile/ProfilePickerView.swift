import SwiftUI

struct ProfilePickerView: View {
    @Bindable var store: KidProfileStore
    let onPicked: () -> Void

    @State private var showingAddForm = false
    @State private var newName = ""
    @State private var newEmoji = KidProfileStore.emojiChoices[0]

    private let columns = [GridItem(.adaptive(minimum: 110, maximum: 160), spacing: 16)]

    var body: some View {
        NavigationStack {
            ZStack {
                MatherTheme.background.ignoresSafeArea()
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        Text("Who's playing?")
                            .font(.system(size: 32, weight: .black, design: .rounded))
                            .foregroundStyle(MatherTheme.ink)
                            .padding(.top, 8)

                        LazyVGrid(columns: columns, spacing: 16) {
                            ForEach(store.profiles, id: \.id) { profile in
                                profileTile(profile)
                            }
                            addTile
                        }

                        if showingAddForm {
                            addForm
                                .transition(.move(edge: .bottom).combined(with: .opacity))
                        }
                    }
                    .padding(24)
                    .animation(.spring(duration: 0.3), value: showingAddForm)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }

    private func profileTile(_ profile: StoredKidProfile) -> some View {
        Button {
            store.setActiveProfile(id: profile.id)
            onPicked()
        } label: {
            VStack(spacing: 8) {
                Text(profile.emoji)
                    .font(.system(size: 52))
                    .frame(width: 80, height: 80)
                    .background(MatherTheme.card)
                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))

                Text(profile.name)
                    .font(.headline.weight(.bold))
                    .foregroundStyle(MatherTheme.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                store.activeProfileId == profile.id
                    ? MatherTheme.accent.opacity(0.12)
                    : MatherTheme.card.opacity(0.5)
            )
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .strokeBorder(
                        store.activeProfileId == profile.id ? MatherTheme.accent : Color.clear,
                        lineWidth: 2
                    )
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(profile.name), \(profile.emoji)")
    }

    private var addTile: some View {
        Button {
            withAnimation { showingAddForm = true }
        } label: {
            VStack(spacing: 8) {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 44))
                    .foregroundStyle(MatherTheme.accent)
                    .frame(width: 80, height: 80)
                    .background(MatherTheme.card)
                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))

                Text("Add Kid")
                    .font(.headline.weight(.bold))
                    .foregroundStyle(MatherTheme.accent)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(MatherTheme.card.opacity(0.5))
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private var addForm: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("New profile")
                .font(.title3.weight(.black))
                .foregroundStyle(MatherTheme.ink)

            TextField("Name", text: $newName)
                .font(.title3.weight(.semibold))
                .textFieldStyle(.roundedBorder)
                .autocorrectionDisabled()
                .onChange(of: newName) { _, v in
                    if v.count > 20 { newName = String(v.prefix(20)) }
                }

            Text("Pick an emoji")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 52), spacing: 8)], spacing: 8) {
                ForEach(KidProfileStore.emojiChoices, id: \.self) { emoji in
                    Button {
                        newEmoji = emoji
                    } label: {
                        Text(emoji)
                            .font(.system(size: 32))
                            .frame(width: 52, height: 52)
                            .background(newEmoji == emoji ? MatherTheme.accent.opacity(0.2) : MatherTheme.card)
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .strokeBorder(newEmoji == emoji ? MatherTheme.accent : Color.clear, lineWidth: 2)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }

            HStack(spacing: 12) {
                Button("Cancel") {
                    newName = ""
                    newEmoji = KidProfileStore.emojiChoices[0]
                    withAnimation { showingAddForm = false }
                }
                .buttonStyle(SecondaryTileButtonStyle(fill: MatherTheme.card))

                Button("Save & Play") {
                    guard !newName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
                    store.addProfile(name: newName, emoji: newEmoji)
                    onPicked()
                }
                .buttonStyle(SecondaryTileButtonStyle(fill: MatherTheme.accent.opacity(0.85)))
                .disabled(newName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .padding(20)
        .background(MatherTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }
}
