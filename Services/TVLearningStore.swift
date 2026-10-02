import Foundation
import Observation

struct TVLearner: Identifiable, Codable, Equatable {
    let id: String
    var name: String
}

struct TVLearningContext: Equatable, Identifiable {
    static let familyID = "tv-family"
    let profileID: String
    let name: String
    var id: String { profileID }
    var familyMode: Bool { profileID == Self.familyID }
}

/// Parent-only coordinated deletion prevents a saved activity from replaying deleted evidence.
@MainActor
enum TVLearningDataReset {
    static func clearSelected(_ context: TVLearningContext, ledger: TVLearningStore, defaults: UserDefaults = .standard) -> String? {
        guard ledger.storageMessage == nil else { return "Saved TV learning could not be read. It was preserved. Use Delete all TV learning to start over." }
        let companion = LearningHandoffStore(defaults: defaults)
        do { try companion.reset(profileID: context.profileID) }
        catch { return "The companion data was preserved because it could not be read. Open Continue an idea to review its recovery options." }
        guard ledger.clearLearning(profileID: context.profileID) else { return "Learning history could not be cleared. Please try again." }
        SumSprintPartyTVSessionStore(defaults: defaults, profileID: context.profileID, familyMode: context.familyMode).clear()
        ShapeDetectiveTVSessionStore(defaults: defaults, profileID: context.profileID).clear()
        return nil
    }

    static func clearAll(ledger: TVLearningStore, defaults: UserDefaults = .standard) {
        for key in defaults.dictionaryRepresentation().keys where key.hasPrefix("tv.sumSprintParty.learning.v1.") || key.hasPrefix("mather.shape-detective.v1.") {
            defaults.removeObject(forKey: key)
        }
        LearningHandoffStore(defaults: defaults).resetAll()
        ledger.resetAll()
    }
}

private struct TVLearningArchive: Codable {
    var schemaVersion = 1
    var learners: [TVLearner] = []
    var selectedLearnerID: String?
    var attempts: [ItemAttempt] = []
    var results: [ActivityResult] = []
}

/// New attributable learning only. Earlier device score keys are never read into this ledger.
@MainActor
@Observable
final class TVLearningStore {
    private let defaults: UserDefaults
    private let key: String
    private var archive = TVLearningArchive()
    private(set) var storageMessage: String?
    private(set) var revision = 0

    init(defaults: UserDefaults = .standard, key: String = "tv.learningLedger.v1") {
        self.defaults = defaults
        self.key = key
        _ = refresh()
    }

    private func refresh() -> Bool {
        guard let data = defaults.data(forKey: key) else {
            guard defaults.object(forKey: key) == nil else { return pauseStorage() }
            archive = TVLearningArchive()
            storageMessage = nil
            return true
        }
        guard Self.hasOnlyKnownFields(data), let value = try? JSONDecoder().decode(TVLearningArchive.self, from: data),
              value.schemaVersion == 1,
              value.learners.count <= 8,
              Set(value.learners.map(\.id)).count == value.learners.count,
              value.learners.allSatisfy({ !$0.id.isEmpty && $0.id != TVLearningContext.familyID && !$0.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && $0.name.count <= 40 }),
              value.selectedLearnerID == nil || value.learners.contains(where: { $0.id == value.selectedLearnerID }),
              Set(value.attempts.map(\.id)).count == value.attempts.count,
              Set(value.results.map { "\($0.profileID ?? "")|\($0.id)" }).count == value.results.count,
              value.attempts.allSatisfy({ Self.valid($0, learners: value.learners) }),
              value.results.allSatisfy({ result in
                  !result.id.isEmpty && !result.activityID.isEmpty && (result.contentVersion ?? 0) > 0 &&
                  result.startedAt.timeIntervalSince1970.isFinite && result.endedAt.timeIntervalSince1970.isFinite && result.endedAt >= result.startedAt &&
                  (result.profileID == TVLearningContext.familyID || value.learners.contains(where: { $0.id == result.profileID })) &&
                  Set(result.attempts.map(\.id)).count == result.attempts.count &&
                  result.attempts.allSatisfy { event in
                      event.profileID == result.profileID && event.sessionID == result.id && event.activityID == result.activityID &&
                      value.attempts.contains(event)
                  }
              }) else {
            return pauseStorage()
        }
        archive = value
        storageMessage = nil
        return true
    }

    private func pauseStorage() -> Bool {
        storageMessage = "Saved learning data needs a compatible app version. It has been kept on this device. New learning history is paused."
        return false
    }

    private static func hasOnlyKnownFields(_ data: Data) -> Bool {
        let attemptKeys: Set<String> = ["id", "activityID", "conceptID", "entityID", "propertyID", "stageID", "outcome", "response", "occurredAt", "profileID", "sessionID", "contentVersion", "itemVariantID", "appHintUsed", "isFreshProbe", "adultHelp"]
        let resultKeys: Set<String> = ["id", "activityID", "title", "startedAt", "endedAt", "attempts", "completedStageIDs", "profileID", "contentVersion"]
        guard let root = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any],
              Set(root.keys).isSubset(of: ["schemaVersion", "learners", "selectedLearnerID", "attempts", "results"]),
              let learners = root["learners"] as? [[String: Any]], learners.allSatisfy({ Set($0.keys).isSubset(of: ["id", "name"]) }),
              let attempts = root["attempts"] as? [[String: Any]], attempts.allSatisfy({ Set($0.keys).isSubset(of: attemptKeys) }),
              let results = root["results"] as? [[String: Any]] else { return false }
        return results.allSatisfy { result in
            guard Set(result.keys).isSubset(of: resultKeys), let events = result["attempts"] as? [[String: Any]] else { return false }
            return events.allSatisfy { Set($0.keys).isSubset(of: attemptKeys) }
        }
    }

    var learners: [TVLearner] { archive.learners }
    var context: TVLearningContext {
        if let learner = archive.learners.first(where: { $0.id == archive.selectedLearnerID }) {
            return TVLearningContext(profileID: learner.id, name: learner.name)
        }
        return TVLearningContext(profileID: TVLearningContext.familyID, name: "Family play")
    }

    @discardableResult
    func addLearner(name: String) -> Bool {
        guard refresh() else { return false }
        let clean = String(name.trimmingCharacters(in: .whitespacesAndNewlines).prefix(40))
        guard !clean.isEmpty, archive.learners.count < 8 else { return false }
        var value = archive
        let learner = TVLearner(id: UUID().uuidString, name: clean)
        value.learners.append(learner)
        value.selectedLearnerID = learner.id
        return persist(value)
    }

    func selectLearner(_ id: String?) {
        guard refresh() else { return }
        guard id == nil || archive.learners.contains(where: { $0.id == id }) else { return }
        var value = archive
        value.selectedLearnerID = id
        _ = persist(value)
    }

    func attempts(for profileID: String) -> [ItemAttempt] {
        archive.attempts.filter { $0.profileID == profileID }
    }

    func results(for profileID: String) -> [ActivityResult] {
        archive.results.filter { $0.profileID == profileID }.sorted { $0.endedAt > $1.endedAt }
    }

    /// Root also clears activity checkpoints before permitting a new session.
    @discardableResult
    func clearLearning(profileID: String) -> Bool {
        guard refresh() else { return false }
        guard profileID == TVLearningContext.familyID || archive.learners.contains(where: { $0.id == profileID }) else { return false }
        var value = archive
        value.attempts.removeAll { $0.profileID == profileID }
        value.results.removeAll { $0.profileID == profileID }
        return persist(value)
    }

    /// Only exposed behind an explicit parent confirmation in the family guide.
    func resetAll() {
        defaults.removeObject(forKey: key)
        archive = TVLearningArchive()
        storageMessage = nil
        revision += 1
    }

    @discardableResult
    func record(_ attempt: ItemAttempt) -> Bool {
        guard refresh(), attempt.profileID == context.profileID,
              Self.valid(attempt, learners: archive.learners) else { return false }
        if let existing = archive.attempts.first(where: { $0.id == attempt.id }) {
            return existing == attempt.withOutcome(existing.outcome)
        }
        var value = archive
        value.attempts.append(ActivityEvidenceNormalizer.normalized([attempt], after: value.attempts)[0])
        return persist(value)
    }

    @discardableResult
    func save(_ result: ActivityResult) -> Bool {
        guard refresh(), result.profileID == context.profileID, !result.id.isEmpty, !result.activityID.isEmpty, (result.contentVersion ?? 0) > 0,
              result.endedAt >= result.startedAt,
              result.startedAt.timeIntervalSince1970.isFinite, result.endedAt.timeIntervalSince1970.isFinite,
              Set(result.attempts.map(\.id)).count == result.attempts.count,
              result.attempts.allSatisfy({ $0.profileID == result.profileID && $0.sessionID == result.id && $0.activityID == result.activityID && Self.valid($0, learners: archive.learners) }) else { return false }
        var value = archive
        guard result.attempts.allSatisfy({ incoming in
            guard let existing = value.attempts.first(where: { $0.id == incoming.id }) else { return true }
            return existing == incoming.withOutcome(existing.outcome)
        }) else { return false }
        for attempt in result.attempts where !value.attempts.contains(where: { $0.id == attempt.id }) {
            value.attempts.append(ActivityEvidenceNormalizer.normalized([attempt], after: value.attempts)[0])
        }
        let ids = Set(result.attempts.map(\.id))
        let canonical = value.attempts.filter { ids.contains($0.id) }
        let canonicalResult = ActivityResult(id: result.id, activityID: result.activityID, title: result.title,
            startedAt: result.startedAt, endedAt: result.endedAt, attempts: canonical,
            completedStageIDs: result.completedStageIDs, profileID: result.profileID, contentVersion: result.contentVersion)
        if let index = value.results.firstIndex(where: { $0.id == result.id && $0.profileID == result.profileID }) {
            value.results[index] = canonicalResult
        } else { value.results.append(canonicalResult) }
        return persist(value)
    }

    private func persist(_ value: TVLearningArchive) -> Bool {
        guard storageMessage == nil, let data = try? JSONEncoder().encode(value) else { return false }
        defaults.set(data, forKey: key)
        guard defaults.data(forKey: key) == data else { return false }
        archive = value
        revision += 1
        return true
    }

    private static func valid(_ attempt: ItemAttempt, learners: [TVLearner]) -> Bool {
        guard let profileID = attempt.profileID, let sessionID = attempt.sessionID,
              !sessionID.isEmpty, !attempt.activityID.isEmpty, !attempt.entityID.isEmpty, !attempt.stageID.isEmpty, !attempt.conceptID.isEmpty,
              attempt.occurredAt.timeIntervalSince1970.isFinite,
              (attempt.contentVersion ?? 0) > 0 else { return false }
        return profileID == TVLearningContext.familyID || learners.contains { $0.id == profileID }
    }
}
