import Foundation

enum LearningHandoffError: Error, Equatable, LocalizedError {
    case malformedCode, checksumMismatch, unsupportedSchema, unsupportedMission
    case invalidQuantity, invalidReceipt, recipientRequired, parentApprovalRequired
    case alreadyReceived, replacementRequired, assignmentChanged, noAssignment
    case observationAlreadyRecorded, receiptLimitReached, damagedLocalStorage

    var errorDescription: String? {
        switch self {
        case .malformedCode: "Enter all 36 letters and numbers from the mission code. Only spaces and dashes may separate groups."
        case .checksumMismatch: "The code check did not match. Check each group with the parent on the other device."
        case .unsupportedSchema: "This code uses a version this app does not support."
        case .unsupportedMission: "This mission is not supported by this app."
        case .invalidQuantity: "This code contains a quantity outside the reviewed build-5 or build-10 missions."
        case .invalidReceipt: "This code has an invalid mission receipt."
        case .recipientRequired: "A parent must select a local learner before continuing."
        case .parentApprovalRequired: "Parent approval is required."
        case .alreadyReceived: "This device already prepared or received that code. It cannot be reused or assigned to another learner."
        case .replacementRequired: "This learner already has a mission. A parent must explicitly choose to replace it."
        case .assignmentChanged: "The current mission changed after review. Review again before replacing it."
        case .noAssignment: "There is no current mission for this learner."
        case .observationAlreadyRecorded: "A parent observation is already saved for this mission. No duplicate was added."
        case .receiptLimitReached: "This device has reached its local receipt limit. Delete all companion data before preparing more codes."
        case .damagedLocalStorage: "Companion data could not be safely read. Delete all companion data to start again."
        }
    }
}

/// This payload continues an idea. It deliberately contains no learner or performance data.
struct LearningHandoffPayload: Codable, Equatable, Sendable {
    static let supportedSchema: UInt8 = 1
    static let reviewedMission: UInt8 = 1
    let schemaVersion: UInt8
    let missionID: UInt8
    let target: Int
    let firstGroup: Int
    let receiptID: UUID

    init(target: Int, firstGroup: Int, receiptID: UUID = UUID(),
         schemaVersion: UInt8 = supportedSchema, missionID: UInt8 = reviewedMission) {
        self.schemaVersion = schemaVersion
        self.missionID = missionID
        self.target = target
        self.firstGroup = firstGroup
        self.receiptID = receiptID
    }

    var secondGroup: Int { target - firstGroup }
    var title: String { "Build \(target) in two groups" }
    var safetyPrompt: String {
        "Grown-up: place \(target) large, safe blocks or toys on a clear table within reach. Avoid small objects, food, sharp or breakable items. Stay together. No searching, climbing, throwing or walking while watching a screen. Stop whenever you need to."
    }
    var childPrompt: String {
        "With your grown-up, put \(firstGroup) big blocks in one group and \(secondGroup) in another. Touch and count them all. How many altogether? Try moving the groups closer. Do you still have the same number?"
    }
    var parentObservationPrompt: String {
        "After the child tries, report what you saw: did they make both groups and count the whole without your help, with help, or not yet? This is your report, not an app test or proof of mastery."
    }

    func validate() throws {
        guard schemaVersion == Self.supportedSchema else { throw LearningHandoffError.unsupportedSchema }
        guard missionID == Self.reviewedMission else { throw LearningHandoffError.unsupportedMission }
        guard [5, 10].contains(target), firstGroup > 0, firstGroup < target else { throw LearningHandoffError.invalidQuantity }
        guard receiptID != UUID(uuid: (0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0)) else { throw LearningHandoffError.invalidReceipt }
    }
}

/// Self-contained offline code: 20 payload bytes + CRC-16, rendered as six groups of six.
/// The checksum detects typos; it does NOT authenticate the sender or protect confidentiality.
enum LearningHandoffCode {
    static let symbolCount = 36
    private static let alphabet = Array("0123456789ABCDEFGHJKMNPQRSTVWXYZ".utf8)

    static func encode(_ payload: LearningHandoffPayload) throws -> String {
        try payload.validate()
        let receipt = payload.receiptID.uuid
        var bytes: [UInt8] = [payload.schemaVersion, payload.missionID, UInt8(payload.target), UInt8(payload.firstGroup)]
        bytes += withUnsafeBytes(of: receipt) { Array($0) }
        let checksum = crc16(bytes)
        bytes += [UInt8(checksum >> 8), UInt8(checksum & 255)]
        var buffer: UInt32 = 0
        var bits = 0
        var symbols: [UInt8] = []
        for byte in bytes {
            buffer = (buffer << 8) | UInt32(byte)
            bits += 8
            while bits >= 5 {
                bits -= 5
                symbols.append(alphabet[Int((buffer >> bits) & 31)])
            }
        }
        if bits > 0 { symbols.append(alphabet[Int((buffer << (5 - bits)) & 31)]) }
        return stride(from: 0, to: symbols.count, by: 6).map {
            String(decoding: symbols[$0..<min($0 + 6, symbols.count)], as: UTF8.self)
        }.joined(separator: "-")
    }

    static func decode(_ code: String) throws -> LearningHandoffPayload {
        // Bound raw input before normalization, including Unicode or excessive whitespace.
        guard code.utf8.count <= 128 else { throw LearningHandoffError.malformedCode }
        var symbols: [UInt8] = []
        for raw in code.utf8 {
            if [UInt8(32), 45, 9, 10, 13].contains(raw) { continue }
            let symbol = (97...122).contains(raw) ? raw - 32 : raw
            guard alphabet.contains(symbol) else { throw LearningHandoffError.malformedCode }
            symbols.append(symbol)
        }
        guard symbols.count == symbolCount else { throw LearningHandoffError.malformedCode }
        var bytes: [UInt8] = []
        var buffer: UInt32 = 0
        var bits = 0
        for symbol in symbols {
            guard let value = alphabet.firstIndex(of: symbol) else { throw LearningHandoffError.malformedCode }
            buffer = (buffer << 5) | UInt32(value)
            bits += 5
            if bits >= 8 {
                bits -= 8
                bytes.append(UInt8((buffer >> bits) & 255))
            }
        }
        guard bytes.count == 22, bits == 4, buffer & 15 == 0 else { throw LearningHandoffError.malformedCode }
        let check = UInt16(bytes[20]) << 8 | UInt16(bytes[21])
        guard crc16(Array(bytes.prefix(20))) == check else { throw LearningHandoffError.checksumMismatch }
        let id = UUID(uuid: (bytes[4], bytes[5], bytes[6], bytes[7], bytes[8], bytes[9], bytes[10], bytes[11],
                             bytes[12], bytes[13], bytes[14], bytes[15], bytes[16], bytes[17], bytes[18], bytes[19]))
        let payload = LearningHandoffPayload(target: Int(bytes[2]), firstGroup: Int(bytes[3]), receiptID: id,
            schemaVersion: bytes[0], missionID: bytes[1])
        try payload.validate()
        return payload
    }

    private static func crc16(_ bytes: [UInt8]) -> UInt16 {
        var crc: UInt16 = 0xffff
        for byte in bytes {
            crc ^= UInt16(byte) << 8
            for _ in 0..<8 { crc = (crc & 0x8000 != 0) ? (crc << 1) ^ 0x1021 : crc << 1 }
        }
        return crc
    }
}

enum LearningHandoffOrigin: String, Codable, Sendable { case preparedHere, enteredCode }

struct LearningHandoffAssignment: Codable, Equatable, Sendable {
    let profileID: String
    let payload: LearningHandoffPayload
    let origin: LearningHandoffOrigin
    let approvedAt: Date
    var eventID: String { "room-companion.assignment.\(payload.receiptID.uuidString.lowercased())" }
}

enum ParentRoomQuestOutcome: String, Codable, CaseIterable, Sendable {
    case alone, withHelp, notYet
    var title: String {
        switch self { case .alone: "Alone"; case .withHelp: "With help"; case .notYet: "Not yet" }
    }
}

/// Local parent-reported physical observation. Never turn this into an ItemAttempt.
struct ParentRoomQuestObservation: Codable, Equatable, Sendable {
    let receiptID: UUID
    let profileID: String
    let outcome: ParentRoomQuestOutcome
    let reportedAt: Date
    var eventID: String { "room-companion.parent-observation.\(receiptID.uuidString.lowercased())" }
    var helpDescription: String {
        switch outcome { case .alone: "Parent reported no help"; case .withHelp: "Parent reported help"; case .notYet: "Assistance unknown" }
    }
}
