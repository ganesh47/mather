import Foundation
import Observation

@MainActor
@Observable
final class LearningHandoffStore {
    static let storageKey = "mather.learning-companion.v1"
    static let maximumReceipts = 256
    private(set) var storageError: LearningHandoffError?
    private var state = State()
    @ObservationIgnored private let defaults: UserDefaults

    private struct State: Codable {
        var schemaVersion = 1
        var receipts: [LearningHandoffPayload] = []
        var assignments: [LearningHandoffAssignment] = []
        var observations: [ParentRoomQuestObservation] = []
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        refresh()
    }

    /// Read before every write so separate open companion screens cannot overwrite each other.
    private func refresh() {
        guard let data = defaults.data(forKey: Self.storageKey) else {
            if defaults.object(forKey: Self.storageKey) != nil {
                storageError = .damagedLocalStorage
            } else {
                state = State()
                storageError = nil
            }
            return
        }
        do {
            guard data.count <= 512_000 else { throw LearningHandoffError.damagedLocalStorage }
            let loaded = try JSONDecoder().decode(State.self, from: data)
            try validate(loaded)
            state = loaded
            storageError = nil
        } catch { storageError = .damagedLocalStorage }
    }

    func assignment(profileID: String) -> LearningHandoffAssignment? {
        state.assignments.first { $0.profileID == profileID }
    }

    func observations(profileID: String) -> [ParentRoomQuestObservation] {
        state.observations.filter { $0.profileID == profileID }
    }

    func observation(profileID: String, receiptID: UUID) -> ParentRoomQuestObservation? {
        state.observations.first { $0.profileID == profileID && $0.receiptID == receiptID }
    }

    func preview(code: String) throws -> LearningHandoffPayload {
        refresh()
        try requireHealthyStorage()
        let payload = try LearningHandoffCode.decode(code)
        guard !state.receipts.contains(where: { $0.receiptID == payload.receiptID }) else { throw LearningHandoffError.alreadyReceived }
        return payload
    }

    @discardableResult
    func createMission(profileID: String, target: Int, parentApproved: Bool,
                       replacingReceiptID: UUID? = nil) throws -> LearningHandoffAssignment {
        let payload = LearningHandoffPayload(target: target, firstGroup: target == 5 ? 2 : 4)
        return try accept(payload, profileID: profileID, origin: .preparedHere,
                          parentApproved: parentApproved, replacingReceiptID: replacingReceiptID)
    }

    @discardableResult
    func approveImport(code: String, recipientProfileID: String, parentApproved: Bool,
                       replacingReceiptID: UUID? = nil) throws -> LearningHandoffAssignment {
        let payload = try LearningHandoffCode.decode(code)
        return try accept(payload, profileID: recipientProfileID, origin: .enteredCode,
                          parentApproved: parentApproved, replacingReceiptID: replacingReceiptID)
    }

    func exportCode(profileID: String, parentApproved: Bool) throws -> String {
        refresh()
        try requireHealthyStorage()
        try requireParent(parentApproved, profileID: profileID)
        guard let current = assignment(profileID: profileID) else { throw LearningHandoffError.noAssignment }
        return try LearningHandoffCode.encode(current.payload)
    }

    @discardableResult
    func recordObservation(profileID: String, receiptID: UUID, outcome: ParentRoomQuestOutcome,
                           parentApproved: Bool, at: Date = .now) throws -> ParentRoomQuestObservation {
        refresh()
        try requireHealthyStorage()
        try requireParent(parentApproved, profileID: profileID)
        guard let current = assignment(profileID: profileID), current.payload.receiptID == receiptID else { throw LearningHandoffError.assignmentChanged }
        guard observation(profileID: profileID, receiptID: receiptID) == nil else { throw LearningHandoffError.observationAlreadyRecorded }
        let observation = ParentRoomQuestObservation(receiptID: receiptID, profileID: profileID, outcome: outcome, reportedAt: at)
        var next = state
        next.observations.append(observation)
        try save(next)
        return observation
    }

    /// Stops the current mission. Anonymous consumed receipts still prevent replay.
    func unlink(profileID: String) throws {
        refresh()
        try requireHealthyStorage()
        var next = state
        next.assignments.removeAll { $0.profileID == profileID }
        try save(next)
    }

    /// Deletes this learner's companion data, retaining only anonymous replay receipts.
    func reset(profileID: String) throws {
        refresh()
        try requireHealthyStorage()
        var next = state
        next.assignments.removeAll { $0.profileID == profileID }
        next.observations.removeAll { $0.profileID == profileID }
        try save(next)
    }

    /// Deletes all companion data, including replay protection. Does not affect other app stores.
    func resetAll() {
        defaults.removeObject(forKey: Self.storageKey)
        state = State()
        storageError = nil
    }

    private func accept(_ payload: LearningHandoffPayload, profileID: String, origin: LearningHandoffOrigin,
                        parentApproved: Bool, replacingReceiptID: UUID?) throws -> LearningHandoffAssignment {
        refresh()
        try requireHealthyStorage()
        try requireParent(parentApproved, profileID: profileID)
        try payload.validate()
        guard !state.receipts.contains(where: { $0.receiptID == payload.receiptID }) else { throw LearningHandoffError.alreadyReceived }
        if let current = assignment(profileID: profileID) {
            guard let replacingReceiptID else { throw LearningHandoffError.replacementRequired }
            guard current.payload.receiptID == replacingReceiptID else { throw LearningHandoffError.assignmentChanged }
        } else if replacingReceiptID != nil { throw LearningHandoffError.assignmentChanged }
        guard state.receipts.count < Self.maximumReceipts else { throw LearningHandoffError.receiptLimitReached }
        let assignment = LearningHandoffAssignment(profileID: profileID, payload: payload, origin: origin, approvedAt: .now)
        var next = state
        next.assignments.removeAll { $0.profileID == profileID }
        next.assignments.append(assignment)
        next.receipts.append(payload)
        try save(next)
        return assignment
    }

    private func requireHealthyStorage() throws {
        if let storageError { throw storageError }
    }

    private func requireParent(_ approved: Bool, profileID: String) throws {
        guard approved else { throw LearningHandoffError.parentApprovalRequired }
        guard Self.validProfileID(profileID) else { throw LearningHandoffError.recipientRequired }
    }

    private static func validProfileID(_ id: String) -> Bool {
        !id.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && id.utf8.count <= 128 && !id.unicodeScalars.contains { CharacterSet.controlCharacters.contains($0) }
    }

    private func save(_ next: State) throws {
        try validate(next)
        let data = try JSONEncoder().encode(next)
        defaults.set(data, forKey: Self.storageKey)
        state = next
    }

    private func validate(_ candidate: State) throws {
        guard candidate.schemaVersion == 1, candidate.receipts.count <= Self.maximumReceipts,
              candidate.assignments.count <= candidate.receipts.count,
              candidate.observations.count <= candidate.receipts.count else { throw LearningHandoffError.damagedLocalStorage }
        for payload in candidate.receipts { try payload.validate() }
        let ids = candidate.receipts.map(\.receiptID)
        guard Set(ids).count == ids.count,
              Set(candidate.assignments.map(\.profileID)).count == candidate.assignments.count,
              Set(candidate.assignments.map { $0.payload.receiptID }).count == candidate.assignments.count,
              Set(candidate.observations.map(\.receiptID)).count == candidate.observations.count else { throw LearningHandoffError.damagedLocalStorage }
        for assignment in candidate.assignments {
            guard Self.validProfileID(assignment.profileID), candidate.receipts.contains(assignment.payload),
                  assignment.approvedAt.timeIntervalSince1970.isFinite else { throw LearningHandoffError.damagedLocalStorage }
        }
        for observation in candidate.observations {
            guard Self.validProfileID(observation.profileID), ids.contains(observation.receiptID),
                  observation.reportedAt.timeIntervalSince1970.isFinite else { throw LearningHandoffError.damagedLocalStorage }
            if let active = candidate.assignments.first(where: { $0.payload.receiptID == observation.receiptID }),
               active.profileID != observation.profileID { throw LearningHandoffError.damagedLocalStorage }
        }
    }
}
