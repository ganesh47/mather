import Foundation
import Observation

struct TVLearner: Identifiable, Codable, Equatable {
    let id: String
    var name: String
}

struct TVLearningContext: Equatable {
    static let familyID = "tv-family"
    let profileID: String
    let name: String
    var familyMode: Bool { profileID == Self.familyID }
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
        guard let data = defaults.data(forKey: key) else { return }
        guard let value = try? JSONDecoder().decode(TVLearningArchive.self, from: data),
              value.schemaVersion == 1,
              Set(value.learners.map(\.id)).count == value.learners.count,
              value.learners.allSatisfy({ !$0.id.isEmpty && $0.id != TVLearningContext.familyID && !$0.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }),
              value.selectedLearnerID == nil || value.learners.contains(where: { $0.id == value.selectedLearnerID }),
              value.attempts.allSatisfy({ Self.valid($0, learners: value.learners) }),
              value.results.allSatisfy({ result in
                  result.profileID == TVLearningContext.familyID || value.learners.contains(where: { $0.id == result.profileID })
              }) else {
            storageMessage = "Saved learning data needs a compatible app version. It has been kept on this device. New learning history is paused."
            return
        }
        archive = value
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
        guard storageMessage == nil else { return false }
        let clean = String(name.trimmingCharacters(in: .whitespacesAndNewlines).prefix(40))
        guard !clean.isEmpty, archive.learners.count < 8 else { return false }
        var value = archive
        let learner = TVLearner(id: UUID().uuidString, name: clean)
        value.learners.append(learner)
        value.selectedLearnerID = learner.id
        return persist(value)
    }

    func selectLearner(_ id: String?) {
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
        guard storageMessage == nil, attempt.profileID == context.profileID,
              Self.valid(attempt, learners: archive.learners) else { return false }
        guard !archive.attempts.contains(where: { $0.id == attempt.id }) else { return true }
        var value = archive
        value.attempts.append(ActivityEvidenceNormalizer.normalized([attempt], after: value.attempts)[0])
        return persist(value)
    }

    @discardableResult
    func save(_ result: ActivityResult) -> Bool {
        guard storageMessage == nil, result.profileID == context.profileID, !result.id.isEmpty,
              result.endedAt >= result.startedAt,
              result.attempts.allSatisfy({ $0.profileID == result.profileID && $0.sessionID == result.id && Self.valid($0, learners: archive.learners) }) else { return false }
        var value = archive
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
        archive = value
        revision += 1
        return true
    }

    private static func valid(_ attempt: ItemAttempt, learners: [TVLearner]) -> Bool {
        guard let profileID = attempt.profileID, let sessionID = attempt.sessionID,
              !sessionID.isEmpty, !attempt.activityID.isEmpty, !attempt.entityID.isEmpty,
              (attempt.contentVersion ?? 0) > 0 else { return false }
        return profileID == TVLearningContext.familyID || learners.contains { $0.id == profileID }
    }
}
