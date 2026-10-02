import Foundation
import Observation

@MainActor
@Observable
final class QuestCheckpointStore {
    private let storage: ExplorerLabMasteryKeyValueStore
    private let storageKey: String
    private let profileID: () -> String
    private(set) var revision = 0
    init(storage: ExplorerLabMasteryKeyValueStore = UserDefaults.standard, storageKey: String = "learningQuestCheckpoints.v1", activeProfileID: @escaping () -> String) {
        self.storage = storage; self.storageKey = storageKey; profileID = activeProfileID
    }
    func checkpoint(for quest: LearningQuestID) -> LearningQuestCheckpoint? {
        _ = revision
        guard let checkpoint = all()[profileID()]?[quest.rawValue], valid(checkpoint), checkpoint.questID == quest else { return nil }
        return checkpoint
    }
    func save(_ checkpoint: LearningQuestCheckpoint) {
        guard checkpoint.profileID == profileID() else { return }
        var values = all(); values[checkpoint.profileID, default: [:]][checkpoint.questID.rawValue] = checkpoint
        persist(values)
    }
    func remove(_ quest: LearningQuestID) {
        var values = all(); values[profileID()]?.removeValue(forKey: quest.rawValue); persist(values)
    }
    var mostRecent: LearningQuestCheckpoint? {
        _ = revision
        return all()[profileID()]?.values.filter(valid).max { $0.updatedAt < $1.updatedAt }
    }
    func reset() { var values = all(); values.removeValue(forKey: profileID()); persist(values) }
    func clearAllProfiles() { storage.removeObject(forKey: storageKey); revision += 1 }
    private func valid(_ value: LearningQuestCheckpoint) -> Bool {
        value.profileID == profileID() && value.schemaVersion == 1 && value.contentVersion > 0
            && (0...10).contains(value.counterCount) && (0...10).contains(value.learnedLeftPart)
            && value.mirrorCells.count == 3 && value.selectedPoints.allSatisfy { (0..<5).contains($0) }
            && Set(value.selectedPoints).count == value.selectedPoints.count && (0...360).contains(value.angleDegrees)
            && ["circle", "triangle", "square", "rectangle"].contains(value.currentShape)
    }
    private func all() -> [String: [String: LearningQuestCheckpoint]] {
        guard let data = storage.data(forKey: storageKey), let values = try? JSONDecoder().decode([String: [String: LearningQuestCheckpoint]].self, from: data) else { return [:] }
        return values
    }
    private func persist(_ values: [String: [String: LearningQuestCheckpoint]]) {
        guard let data = try? JSONEncoder().encode(values) else { return }
        storage.set(data, forKey: storageKey); revision += 1
    }
}
