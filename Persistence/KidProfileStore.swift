import Foundation
import Observation
import SwiftData

@MainActor
@Observable
final class KidProfileStore {
    static let emojiChoices = ["🦊", "🐼", "🐨", "🦖", "🦁", "🐳", "🦄", "🐸", "🐯", "🐙"]

    private let modelContext: ModelContext
    private let defaults: UserDefaults
    private let activeProfileDefaultsKey = "activeKidProfileId"

    private(set) var activeProfileId: String = ""

    init(modelContext: ModelContext, defaults: UserDefaults = .standard) {
        self.modelContext = modelContext
        self.defaults = defaults
        bootstrapDefaultProfileIfNeeded()
    }

    var profiles: [StoredKidProfile] {
        let descriptor = FetchDescriptor<StoredKidProfile>(sortBy: [SortDescriptor(\StoredKidProfile.createdAt)])
        return (try? modelContext.fetch(descriptor)) ?? []
    }

    var activeProfile: StoredKidProfile? {
        profiles.first(where: { $0.id == activeProfileId })
    }

    func addProfile(name: String, emoji: String) {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return }
        let cleanEmoji = emoji.isEmpty ? Self.emojiChoices[0] : emoji
        let profile = StoredKidProfile(name: trimmedName, emoji: cleanEmoji)
        modelContext.insert(profile)
        try? modelContext.save()
        setActiveProfile(id: profile.id)
    }

    func setActiveProfile(id: String) {
        guard profiles.contains(where: { $0.id == id }) else { return }
        activeProfileId = id
        defaults.set(id, forKey: activeProfileDefaultsKey)
    }

    private func bootstrapDefaultProfileIfNeeded() {
        if profiles.isEmpty {
            let defaultProfile = StoredKidProfile(name: "Kiddo", emoji: "🦊")
            modelContext.insert(defaultProfile)
            try? modelContext.save()
        }

        let savedProfileId = defaults.string(forKey: activeProfileDefaultsKey)
        if let savedProfileId, profiles.contains(where: { $0.id == savedProfileId }) {
            activeProfileId = savedProfileId
            return
        }

        if let first = profiles.first {
            setActiveProfile(id: first.id)
        }
    }
}
