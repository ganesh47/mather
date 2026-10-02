import Foundation
import Observation

enum QuestStorageState: Equatable { case missing, healthy, unsupported }

enum QuestCheckpointStorageIssue: Equatable {
    case unsupportedCheckpoints, unsupportedVariantHistory, unsupportedPriorAttempts, couldNotSave
    var message: String {
        if self == .unsupportedPriorAttempts {
            return "Earlier quest learning history could not be read. Existing tasks and probe history have been preserved. Ask a parent to check Settings. The earlier learning history must be restored or cleared before this quest can continue."
        }
        let reason = switch self {
        case .unsupportedCheckpoints: "Saved quest checkpoints could not be read."
        case .unsupportedVariantHistory: "Saved quest variant history could not be read."
        case .unsupportedPriorAttempts: "Earlier quest learning history could not be read."
        case .couldNotSave: "This quest could not be saved."
        }
        return reason + " Existing tasks and probe history have been preserved. Ask a parent to check Settings. To start over, use Delete all quest checkpoints in Settings."
    }
}

@MainActor
@Observable
final class QuestCheckpointStore {
    private let storage: ExplorerLabMasteryKeyValueStore
    private let storageKey: String
    private let profileID: () -> String
    private let priorAttempts: () -> [ItemAttempt]?
    private(set) var revision = 0
    private(set) var checkpointState = QuestStorageState.missing
    private(set) var variantHistoryState = QuestStorageState.missing
    private(set) var storageIssue: QuestCheckpointStorageIssue?
    init(storage: ExplorerLabMasteryKeyValueStore = UserDefaults.standard, storageKey: String = "learningQuestCheckpoints.v1", activeProfileID: @escaping () -> String, priorAttempts: @escaping () -> [ItemAttempt]? = { [] }) {
        self.storage = storage; self.storageKey = storageKey; profileID = activeProfileID; self.priorAttempts = priorAttempts
        _ = snapshot()
    }
    /// A detected unsupported value stays paused until an explicit all-profile reset.
    @discardableResult
    func refreshStorage() -> Bool { snapshot() != nil }
    func checkpoint(for quest: LearningQuestID) -> LearningQuestCheckpoint? {
        _ = revision
        return snapshot()?.checkpoints[profileID()]?[quest.rawValue]
    }
    @discardableResult
    func save(_ checkpoint: LearningQuestCheckpoint) -> Bool {
        guard let saved = snapshot(), checkpoint.profileID == profileID(), valid(checkpoint) else { return false }
        var values = saved.checkpoints
        values[checkpoint.profileID, default: [:]][checkpoint.questID.rawValue] = checkpoint
        return persist(values, key: storageKey)
    }
    @discardableResult
    func remove(_ quest: LearningQuestID) -> Bool {
        guard let saved = snapshot() else { return false }
        var values = saved.checkpoints; values[profileID()]?.removeValue(forKey: quest.rawValue)
        return persist(values, key: storageKey)
    }
    var mostRecent: LearningQuestCheckpoint? {
        _ = revision
        return snapshot()?.checkpoints[profileID()]?.values.max { $0.updatedAt < $1.updatedAt }
    }
    /// Rotation advances only when a new session is created, never on resume.
    func nextVariantOrdinal(for quest: LearningQuestID) -> Int? {
        guard let saved = snapshot(), !profileID().isEmpty else { return nil }
        var values = saved.history
        let key = profileID() + "::" + quest.rawValue
        let ordinal = values.ordinals[key, default: 0]
        values.ordinals[key] = ordinal == Int.max ? 0 : ordinal + 1
        return persist(values, key: metadataKey) ? ordinal : nil
    }
    /// The provider must return history owned by the selected profile; nil legacy event
    /// context is allowed only because its containing record supplies that ownership.
    @discardableResult
    func seedKnownProbeHistory() -> Bool {
        guard let saved = snapshot() else { return false }
        guard let attempts = priorAttempts() else { storageIssue = .unsupportedPriorAttempts; return false }
        let child = profileID()
        var history = saved.history
        let original = history.seenNumberProbes[child, default: []]
        var used = original
        used.formUnion(original.map(LearningQuestProbeIdentity.canonical))
        for checkpoint in saved.checkpoints[child, default: [:]].values { used.formUnion(checkpoint.presentedProbeIDs) }
        for attempt in attempts where attempt.profileID == nil || attempt.profileID == child {
            if let id = LearningQuestProbeIdentity.knownProbe(in: attempt) { used.insert(id) }
        }
        guard used != original else { return true }
        history.seenNumberProbes[child] = used
        return persist(history, key: metadataKey)
    }
    /// Unknown history must never claim an item has not been seen.
    func hasSeenProbe(_ id: String) -> Bool {
        guard let saved = snapshot() else { return true }
        let canonical = LearningQuestProbeIdentity.canonical(id)
        return saved.history.seenNumberProbes[profileID(), default: []].contains { LearningQuestProbeIdentity.canonical($0) == canonical }
    }
    @discardableResult
    func markProbeSeen(_ id: String) -> Bool {
        guard let saved = snapshot(), !id.isEmpty, !profileID().isEmpty else { return false }
        var values = saved.history; values.seenNumberProbes[profileID(), default: []].insert(LearningQuestProbeIdentity.canonical(id))
        return persist(values, key: metadataKey)
    }
    @discardableResult
    func reset() -> Bool {
        guard let saved = snapshot() else { return false }
        var values = saved.checkpoints; values.removeValue(forKey: profileID())
        var history = saved.history
        history.ordinals = history.ordinals.filter { !$0.key.hasPrefix(profileID() + "::") }
        history.seenNumberProbes.removeValue(forKey: profileID())
        guard persist(values, key: storageKey) else { return false }
        return persist(history, key: metadataKey)
    }
    /// The only recovery operation that may discard unknown data, for every child.
    func clearAllProfiles() {
        storage.removeObject(forKey: storageKey); storage.removeObject(forKey: metadataKey)
        storageIssue = nil; checkpointState = .missing; variantHistoryState = .missing; revision += 1
    }
    private struct VariantHistory: Codable {
        var ordinals: [String: Int] = [:]
        var seenNumberProbes: [String: Set<String>] = [:]
    }
    private struct Snapshot {
        let checkpoints: [String: [String: LearningQuestCheckpoint]]
        let history: VariantHistory
    }
    private var metadataKey: String { storageKey + ".reviewedVariants.v1" }
    private func snapshot() -> Snapshot? {
        // The external journal has its own recovery operation. A selected-child
        // learning reset clears it before asking this store to reset that child's tasks.
        if storageIssue == .unsupportedPriorAttempts {
            guard priorAttempts() != nil else { return nil }
            storageIssue = nil
        }
        guard storageIssue == nil else { return nil }
        let checkpoints = readCheckpoints(), history = readHistory()
        guard let checkpoints, let history else {
            storageIssue = checkpointState == .unsupported ? .unsupportedCheckpoints : .unsupportedVariantHistory
            return nil
        }
        return Snapshot(checkpoints: checkpoints, history: history)
    }
    private func readHistory() -> VariantHistory? {
        if hasNonDataValue(for: metadataKey) { variantHistoryState = .unsupported; return nil }
        guard let data = storage.data(forKey: metadataKey) else { variantHistoryState = .missing; return VariantHistory() }
        guard let object = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any],
              Set(object.keys) == ["ordinals", "seenNumberProbes"],
              let value = try? JSONDecoder().decode(VariantHistory.self, from: data),
              value.ordinals.allSatisfy({ key, ordinal in
                  guard let split = key.range(of: "::", options: .backwards) else { return false }
                  return !key[..<split.lowerBound].isEmpty && LearningQuestID(rawValue: String(key[split.upperBound...])) != nil && ordinal >= 0
              }),
              value.seenNumberProbes.allSatisfy({ !$0.key.isEmpty && $0.value.allSatisfy { !$0.isEmpty } })
        else { variantHistoryState = .unsupported; return nil }
        variantHistoryState = .healthy; return value
    }
    private func readCheckpoints() -> [String: [String: LearningQuestCheckpoint]]? {
        if hasNonDataValue(for: storageKey) { checkpointState = .unsupported; return nil }
        guard let data = storage.data(forKey: storageKey) else { checkpointState = .missing; return [:] }
        guard let object = (try? JSONSerialization.jsonObject(with: data)) as? [String: [String: [String: Any]]],
              object.values.allSatisfy({ $0.values.allSatisfy(Self.knownCheckpointFields) }),
              let values = try? JSONDecoder().decode([String: [String: LearningQuestCheckpoint]].self, from: data),
              values.allSatisfy({ profile, quests in
                  !profile.isEmpty && quests.allSatisfy { key, value in
                      key == value.questID.rawValue && value.profileID == profile && valid(value)
                  }
              })
        else { checkpointState = .unsupported; return nil }
        checkpointState = .healthy; return values
    }
    /// Unknown fields at any typed level may contain future data; never decode and erase them.
    private static func knownCheckpointFields(_ object: [String: Any]) -> Bool {
        let allowed: Set<String> = ["schemaVersion", "profileID", "questID", "sessionID", "contentVersion", "content", "startedAt", "updatedAt", "step", "guidedPlanID", "returnLaneID", "returnToGames", "completedSteps", "attempts", "selectedChoice", "hasManipulated", "accepted", "supportVisible", "counterCount", "learnedLeftPart", "exploredShapes", "currentShape", "shapeTurnCount", "predictionMade", "selectedPoints", "angleDegrees", "waterState", "wireConnected", "switchClosed", "secondSwitchClosed", "mirrorCells", "folded", "feedback", "numbersVariant", "variantOrdinal", "numberProbeIndex", "numberProbeFreshness", "pilotVariant", "pilotProbeFresh"]
        guard Set(object.keys).isSubset(of: allowed),
              let content = object["content"] as? [String: Any], Set(content.keys) == ["version", "names", "facts"],
              let attempts = object["attempts"] as? [[String: Any]], attempts.allSatisfy({
                  Set($0.keys).isSubset(of: ["id", "activityID", "conceptID", "entityID", "propertyID", "stageID", "outcome", "response", "occurredAt", "profileID", "sessionID", "contentVersion", "itemVariantID", "appHintUsed", "isFreshProbe", "adultHelp"])
              }) else { return false }
        if let variant = object["numbersVariant"] as? [String: Any] {
            guard Set(variant.keys) == ["id", "initialPart", "probes"], let probes = variant["probes"] as? [[String: Any]],
                  probes.allSatisfy({ Set($0.keys) == ["id", "total", "knownPart", "objects", "symbol", "scene"] }) else { return false }
        }
        if let pilot = object["pilotVariant"] as? [String: Any],
           !Set(pilot.keys).isSubset(of: ["id", "questID", "shapeKind", "rotation", "waterVessel", "openSwitch"]) { return false }
        return true
    }
    private func valid(_ value: LearningQuestCheckpoint) -> Bool {
        validVariant(value) && !value.profileID.isEmpty && !value.sessionID.isEmpty && value.schemaVersion == 1
            && value.contentVersion > 0 && value.content.version == value.contentVersion
            && value.startedAt.timeIntervalSince1970.isFinite && value.updatedAt.timeIntervalSince1970.isFinite
            && (0...10).contains(value.counterCount) && (0...10).contains(value.learnedLeftPart)
            && value.mirrorCells.count == 3 && value.selectedPoints.allSatisfy { (0..<5).contains($0) }
            && Set(value.selectedPoints).count == value.selectedPoints.count && (0...360).contains(value.angleDegrees)
            && Set(value.completedSteps).count == value.completedSteps.count
            && ["circle", "triangle", "square", "rectangle"].contains(value.currentShape)
            && Set(value.attempts.map(\.id)).count == value.attempts.count
            && value.attempts.allSatisfy { $0.occurredAt.timeIntervalSince1970.isFinite && ($0.profileID == nil || $0.profileID == value.profileID) && ($0.sessionID == nil || $0.sessionID == value.sessionID) }
    }
    private func validVariant(_ value: LearningQuestCheckpoint) -> Bool {
        guard value.variantOrdinal.map({ $0 >= 0 }) ?? true else { return false }
        if let pilot = value.pilotVariant {
            guard pilot.questID == value.questID, pilot.isReviewed, value.pilotProbeFresh != nil,
                  let ordinal = value.variantOrdinal, LearningPilotVariant.at(quest: value.questID, ordinal: ordinal) == pilot else { return false }
        } else if value.pilotProbeFresh != nil { return false }
        guard let variant = value.numbersVariant else {
            return value.numberProbeIndex == nil && value.numberProbeFreshness == nil
        }
        return value.questID == .numbers && variant.isReviewed
            && value.variantOrdinal.map({ LearningNumbersVariant.at(ordinal: $0) == variant }) == true
            && value.numberProbeIndex.map({ variant.probes.indices.contains($0) }) == true
            && value.numberProbeFreshness?.count == variant.probes.count
            && value.counterCount <= value.numberWhole
    }
    private func persist<T: Encodable>(_ value: T, key: String) -> Bool {
        guard let data = try? JSONEncoder().encode(value) else { storageIssue = .couldNotSave; return false }
        storage.set(data, forKey: key)
        guard storage.data(forKey: key) == data else { storageIssue = .couldNotSave; return false }
        if key == storageKey { checkpointState = .healthy } else { variantHistoryState = .healthy }
        revision += 1; return true
    }
    private func hasNonDataValue(for key: String) -> Bool {
        // The injected storage protocol is Data-only; production defaults can distinguish
        // an absent key from a value stored by an unsupported implementation.
        guard let defaults = storage as? UserDefaults, let value = defaults.object(forKey: key) else { return false }
        return !(value is Data)
    }
}
