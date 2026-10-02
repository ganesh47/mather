import Foundation
import Observation

/// Optional parent reports are local context, separate from app-observed answers.
enum ParentOffscreenOutcome: String, CaseIterable, Codable, Identifiable {
    case usedIdeaAlone, usedIdeaWithAdultHelp, notYet
    var id: String { rawValue }
    var title: String {
        switch self {
        case .usedIdeaAlone: "Used the idea without adult help"
        case .usedIdeaWithAdultHelp: "Used the idea with adult help"
        case .notYet: "Not yet / unsure"
        }
    }
}

struct ParentOffscreenObservation: Identifiable, Codable, Equatable {
    let id: UUID
    let profileID: String
    let questID: LearningQuestID
    let occurredAt: Date
    let outcome: ParentOffscreenOutcome
    let prompt: String
}

enum ParentObservationStorageIssue: Equatable {
    case unreadableHistory, couldNotSave
    var message: String {
        switch self {
        case .unreadableHistory: "Saved parent observations could not be read. The existing history has been preserved, so new reports cannot be saved. If you want to start over, use Delete all parent reports in Settings."
        case .couldNotSave: "This parent observation could not be saved. Please try again."
        }
    }
}

@MainActor
@Observable
final class ParentOffscreenObservationStore {
    private let storage: ExplorerLabMasteryKeyValueStore
    private let storageKey: String
    private(set) var revision = 0
    private(set) var storageIssue: ParentObservationStorageIssue?
    init(storage: ExplorerLabMasteryKeyValueStore = UserDefaults.standard, storageKey: String = "parentOffscreenObservations.v1") {
        self.storage = storage; self.storageKey = storageKey
        if readHistory() == nil { storageIssue = .unreadableHistory }
    }
    func observations(profileID: String) -> [ParentOffscreenObservation] {
        _ = revision
        return (readHistory() ?? []).filter { $0.profileID == profileID }.sorted { $0.occurredAt > $1.occurredAt }
    }
    @discardableResult
    func record(profileID: String, questID: LearningQuestID, outcome: ParentOffscreenOutcome, now: Date = Date()) -> ParentOffscreenObservation? {
        guard !profileID.isEmpty, now.timeIntervalSince1970.isFinite else { return nil }
        guard let history = readHistory() else { storageIssue = .unreadableHistory; return nil }
        let observation = ParentOffscreenObservation(id: UUID(), profileID: profileID, questID: questID,
            occurredAt: now, outcome: outcome, prompt: questID.offscreenPrompt)
        // Bound this child's history without discarding another child's reports.
        var values = history.filter { $0.profileID != profileID }
        let ownHistory = history.filter { $0.profileID == profileID }.sorted { $0.occurredAt > $1.occurredAt }
        values += Array(([observation] + ownHistory).prefix(30))
        guard persist(values) else { return nil }
        return observation
    }
    @discardableResult
    func clearSelectedProfile(profileID: String) -> Bool {
        guard let history = readHistory() else { storageIssue = .unreadableHistory; return false }
        return persist(history.filter { $0.profileID != profileID })
    }
    /// Only an explicit all-profile reset may discard unknown or unreadable history.
    func clearAllProfiles() { storage.removeObject(forKey: storageKey); storageIssue = nil; revision += 1 }
    private func readHistory() -> [ParentOffscreenObservation]? {
        guard let data = storage.data(forKey: storageKey) else { return [] }
        // Preserve the original array format. Extra fields may belong to a future version;
        // decoding then re-encoding them would silently erase information.
        let keys: Set<String> = ["id", "profileID", "questID", "occurredAt", "outcome", "prompt"]
        guard let objects = (try? JSONSerialization.jsonObject(with: data)) as? [[String: Any]],
              objects.allSatisfy({ Set($0.keys) == keys }),
              let values = try? JSONDecoder().decode([ParentOffscreenObservation].self, from: data),
              Set(values.map(\.id)).count == values.count,
              values.allSatisfy({ !$0.profileID.isEmpty && !$0.prompt.isEmpty && $0.occurredAt.timeIntervalSince1970.isFinite })
        else { return nil }
        return values
    }
    private func persist(_ values: [ParentOffscreenObservation]) -> Bool {
        guard let data = try? JSONEncoder().encode(values) else { storageIssue = .couldNotSave; return false }
        storage.set(data, forKey: storageKey)
        guard storage.data(forKey: storageKey) == data else { storageIssue = .couldNotSave; return false }
        storageIssue = nil; revision += 1; return true
    }
}
