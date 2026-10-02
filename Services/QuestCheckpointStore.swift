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
    /// Rotation advances only when a new session is created, never on resume.
    func nextVariantOrdinal(for quest: LearningQuestID) -> Int {
        var values = metadata()
        let key = profileID() + "::" + quest.rawValue
        let ordinal = max(0, values.ordinals[key, default: 0])
        values.ordinals[key] = ordinal == Int.max ? 0 : ordinal + 1
        saveMetadata(values)
        return ordinal
    }
    func hasSeenProbe(_ id: String) -> Bool { metadata().seenNumberProbes[profileID(), default: []].contains(id) }
    func markProbeSeen(_ id: String) {
        var values = metadata(); values.seenNumberProbes[profileID(), default: []].insert(id); saveMetadata(values)
    }
    func reset() {
        var values = all(); values.removeValue(forKey: profileID()); persist(values)
        var history = metadata()
        history.ordinals = history.ordinals.filter { !$0.key.hasPrefix(profileID() + "::") }
        history.seenNumberProbes.removeValue(forKey: profileID()); saveMetadata(history)
    }
    func clearAllProfiles() { storage.removeObject(forKey: storageKey); storage.removeObject(forKey: metadataKey); revision += 1 }
    private struct VariantHistory: Codable {
        var ordinals: [String: Int] = [:]
        var seenNumberProbes: [String: Set<String>] = [:]
    }
    private var metadataKey: String { storageKey + ".reviewedVariants.v1" }
    private func metadata() -> VariantHistory {
        storage.data(forKey: metadataKey).flatMap { try? JSONDecoder().decode(VariantHistory.self, from: $0) } ?? VariantHistory()
    }
    private func saveMetadata(_ value: VariantHistory) { storage.set(try? JSONEncoder().encode(value), forKey: metadataKey) }

    private func valid(_ value: LearningQuestCheckpoint) -> Bool {
        validVariant(value) && value.profileID == profileID() && value.schemaVersion == 1 && value.contentVersion > 0
            && (0...10).contains(value.counterCount) && (0...10).contains(value.learnedLeftPart)
            && value.mirrorCells.count == 3 && value.selectedPoints.allSatisfy { (0..<5).contains($0) }
            && Set(value.selectedPoints).count == value.selectedPoints.count && (0...360).contains(value.angleDegrees)
            && ["circle", "triangle", "square", "rectangle"].contains(value.currentShape)
    }
    private func validVariant(_ value: LearningQuestCheckpoint) -> Bool {
        guard value.variantOrdinal.map({ $0 >= 0 }) ?? true else { return false }
        if let pilot = value.pilotVariant {
            guard pilot.questID == value.questID, pilot.isReviewed, value.pilotProbeFresh != nil else { return false }
        } else if value.pilotProbeFresh != nil { return false }
        guard let variant = value.numbersVariant else {
            return value.numberProbeIndex == nil && value.numberProbeFreshness == nil
        }
        return value.questID == .numbers && variant.isReviewed
            && value.numberProbeIndex.map({ variant.probes.indices.contains($0) }) == true
            && value.numberProbeFreshness?.count == variant.probes.count
            && value.counterCount <= value.numberWhole
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
