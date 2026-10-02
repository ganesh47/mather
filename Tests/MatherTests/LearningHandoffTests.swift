import Foundation
import Testing
@testable import Mather

@Suite("Manual parent mission continuation")
@MainActor
struct LearningHandoffTests {
    // Generated independently with Python base64.b32encode + binascii.crc_hqx, not this encoder.
    private let code = "040GM1-0J6HB7-G4HMAS-W9NF6Y-Y0938N-KR5R80"
    private let receipt = UUID(uuidString: "12345678-1234-5678-9abc-def012345678")!

    private func defaults() -> UserDefaults {
        UserDefaults(suiteName: "mather.companion.synthetic.\(UUID().uuidString)")!
    }

    @Test func independentlyGeneratedGoldenCodePreservesReviewedMissionAndReceipt() throws {
        let decoded = try LearningHandoffCode.decode(code)
        #expect(decoded.receiptID == receipt)
        #expect(decoded.target == 10)
        #expect(decoded.firstGroup == 4)
        #expect(decoded.secondGroup == 6)
        #expect(try LearningHandoffCode.encode(decoded) == code)
        #expect(try LearningHandoffCode.decode(code.lowercased().replacingOccurrences(of: "-", with: " \n")) == decoded)
        #expect(decoded.safetyPrompt.contains("No searching, climbing"))
    }

    @Test func everyReviewedPartitionRoundTripsWithoutNamesOrEvidence() throws {
        for target in [5, 10] {
            for firstGroup in 1..<target {
                let payload = LearningHandoffPayload(target: target, firstGroup: firstGroup)
                let encoded = try LearningHandoffCode.encode(payload)
                #expect(encoded.split(separator: "-").count == 6)
                #expect(encoded.filter { $0 != "-" }.count == 36)
                #expect(try LearningHandoffCode.decode(encoded) == payload)
                let object = try #require(JSONSerialization.jsonObject(with: JSONEncoder().encode(payload)) as? [String: Any])
                #expect(Set(object.keys) == ["schemaVersion", "missionID", "target", "firstGroup", "receiptID"])
            }
        }
    }

    @Test func unsupportedOrUnsafePayloadsAreRejectedEvenWithCorrectChecksums() {
        #expect(throws: LearningHandoffError.unsupportedSchema) { try LearningHandoffCode.decode("080GM1-0J6HB7-G4HMAS-W9NF6Y-Y0938N-KRE32G") }
        #expect(throws: LearningHandoffError.unsupportedMission) { try LearningHandoffCode.decode("0410M1-0J6HB7-G4HMAS-W9NF6Y-Y0938N-KRBG80") }
        #expect(throws: LearningHandoffError.invalidQuantity) { try LearningHandoffCode.decode("040GP1-0J6HB7-G4HMAS-W9NF6Y-Y0938N-KRVRGG") }
        #expect(throws: LearningHandoffError.invalidQuantity) { try LearningHandoffCode.decode("040GM0-0J6HB7-G4HMAS-W9NF6Y-Y0938N-KRDPC0") }
        #expect(throws: LearningHandoffError.invalidReceipt) { try LearningHandoffCode.decode("040GM1-000000-000000-000000-000000-00BYR0") }
        #expect(throws: LearningHandoffError.invalidQuantity) { try LearningHandoffCode.encode(.init(target: 255, firstGroup: 1)) }
        #expect(throws: LearningHandoffError.invalidQuantity) { try LearningHandoffCode.encode(.init(target: 5, firstGroup: 5)) }
    }

    @Test func typingErrorsExtraSymbolsUnicodeAndNoncanonicalPaddingAreRejected() {
        #expect(throws: LearningHandoffError.checksumMismatch) { try LearningHandoffCode.decode("040GM1-0J6HB7-G4HMAS-W9NF6Y-Y0938N-KR5R00") }
        #expect(throws: LearningHandoffError.malformedCode) { try LearningHandoffCode.decode(code + "0") }
        #expect(throws: LearningHandoffError.malformedCode) { try LearningHandoffCode.decode(String(code.dropLast())) }
        #expect(throws: LearningHandoffError.malformedCode) { try LearningHandoffCode.decode(code.replacingOccurrences(of: "0", with: "O")) }
        #expect(throws: LearningHandoffError.malformedCode) { try LearningHandoffCode.decode(code.replacingOccurrences(of: "-", with: "–")) }
        #expect(throws: LearningHandoffError.malformedCode) { try LearningHandoffCode.decode("040GM1-0J6HB7-G4HMAS-W9NF6Y-Y0938N-KR5R81") }
        #expect(throws: LearningHandoffError.malformedCode) { try LearningHandoffCode.decode(String(repeating: " ", count: 129) + code) }
    }

    @Test func previewAndCancellationDoNotConsumeOrAssignAnything() throws {
        let storage = defaults()
        let store = LearningHandoffStore(defaults: storage)
        #expect(try store.preview(code: code).receiptID == receipt)
        #expect(store.assignment(profileID: "synthetic-A") == nil)
        #expect(storage.data(forKey: LearningHandoffStore.storageKey) == nil)
        #expect(try store.preview(code: code).receiptID == receipt)
    }

    @Test func recipientAndParentApprovalAreRequiredBeforeAnyMutation() {
        let storage = defaults()
        let store = LearningHandoffStore(defaults: storage)
        #expect(throws: LearningHandoffError.parentApprovalRequired) {
            try store.approveImport(code: code, recipientProfileID: "synthetic-A", parentApproved: false)
        }
        for invalid in ["", " \n", "id\n", String(repeating: "x", count: 129)] {
            #expect(throws: LearningHandoffError.recipientRequired) {
                try store.approveImport(code: code, recipientProfileID: invalid, parentApproved: true)
            }
        }
        #expect(storage.data(forKey: LearningHandoffStore.storageKey) == nil)
        #expect(throws: LearningHandoffError.parentApprovalRequired) {
            try store.createMission(profileID: "synthetic-A", target: 5, parentApproved: false)
        }
    }

    @Test func syntheticOfflineDeviceToDeviceFlowMapsOnlyExplicitRecipient() throws {
        let handheld = LearningHandoffStore(defaults: defaults())
        let tvStorage = defaults()
        tvStorage.set("synthetic unknown device history", forKey: "existing.family.history")
        let tv = LearningHandoffStore(defaults: tvStorage)
        let source = try handheld.createMission(profileID: "synthetic-A", target: 5, parentApproved: true)
        let exported = try handheld.exportCode(profileID: "synthetic-A", parentApproved: true)
        let imported = try tv.approveImport(code: exported, recipientProfileID: "synthetic-B", parentApproved: true)
        #expect(imported.payload == source.payload)
        #expect(imported.profileID == "synthetic-B")
        #expect(imported.origin == .enteredCode)
        #expect(tv.assignment(profileID: "synthetic-A") == nil)
        #expect(tv.observations(profileID: "synthetic-B").isEmpty)
        #expect(tvStorage.string(forKey: "existing.family.history") == "synthetic unknown device history")
        #expect(throws: LearningHandoffError.parentApprovalRequired) {
            try tv.exportCode(profileID: "synthetic-B", parentApproved: false)
        }
    }

    @Test func receivedReceiptCannotReplayOrBeRemappedAfterRelaunch() throws {
        let storage = defaults()
        let first = try LearningHandoffStore(defaults: storage).approveImport(code: code, recipientProfileID: "synthetic-A", parentApproved: true)
        let relaunched = LearningHandoffStore(defaults: storage)
        #expect(relaunched.assignment(profileID: "synthetic-A")?.eventID == first.eventID)
        #expect(throws: LearningHandoffError.alreadyReceived) { try relaunched.preview(code: code) }
        for recipient in ["synthetic-A", "synthetic-B"] {
            #expect(throws: LearningHandoffError.alreadyReceived) {
                try relaunched.approveImport(code: code, recipientProfileID: recipient, parentApproved: true)
            }
        }
    }

    @Test func competingMissionNeedsExplicitReplacementAndStaleApprovalFails() throws {
        let store = LearningHandoffStore(defaults: defaults())
        let first = try store.createMission(profileID: "synthetic-A", target: 5, parentApproved: true)
        #expect(throws: LearningHandoffError.replacementRequired) {
            try store.approveImport(code: code, recipientProfileID: "synthetic-A", parentApproved: true)
        }
        #expect(store.assignment(profileID: "synthetic-A") == first)
        let newer = try store.createMission(profileID: "synthetic-A", target: 10, parentApproved: true, replacingReceiptID: first.payload.receiptID)
        #expect(throws: LearningHandoffError.assignmentChanged) {
            try store.approveImport(code: code, recipientProfileID: "synthetic-A", parentApproved: true, replacingReceiptID: first.payload.receiptID)
        }
        #expect(store.assignment(profileID: "synthetic-A") == newer)
        let imported = try store.approveImport(code: code, recipientProfileID: "synthetic-A", parentApproved: true, replacingReceiptID: newer.payload.receiptID)
        #expect(imported.payload.receiptID == receipt)
    }

    @Test func separateOpenStoresRefreshBeforeWritingAndNeverResurrectDeletedData() throws {
        let storage = defaults()
        let one = LearningHandoffStore(defaults: storage)
        let two = LearningHandoffStore(defaults: storage)
        let a = try one.createMission(profileID: "synthetic-A", target: 5, parentApproved: true)
        _ = try two.createMission(profileID: "synthetic-B", target: 10, parentApproved: true)
        #expect(LearningHandoffStore(defaults: storage).assignment(profileID: "synthetic-A") == a)
        two.resetAll()
        #expect(throws: LearningHandoffError.assignmentChanged) {
            try one.recordObservation(profileID: "synthetic-A", receiptID: a.payload.receiptID, outcome: .alone, parentApproved: true)
        }
        #expect(LearningHandoffStore(defaults: storage).assignment(profileID: "synthetic-A") == nil)
    }

    @Test func observationIsParentReportedOnlyUnknownUntilReportedAndStableOnRelaunch() throws {
        let storage = defaults()
        let store = LearningHandoffStore(defaults: storage)
        let mission = try store.approveImport(code: code, recipientProfileID: "synthetic-A", parentApproved: true)
        #expect(store.observation(profileID: "synthetic-A", receiptID: receipt) == nil)
        #expect(throws: LearningHandoffError.parentApprovalRequired) {
            try store.recordObservation(profileID: "synthetic-A", receiptID: receipt, outcome: .alone, parentApproved: false)
        }
        let observation = try store.recordObservation(profileID: "synthetic-A", receiptID: receipt, outcome: .notYet, parentApproved: true)
        #expect(observation.helpDescription == "Assistance unknown")
        #expect(observation.eventID != mission.eventID)
        #expect(throws: LearningHandoffError.observationAlreadyRecorded) {
            try store.recordObservation(profileID: "synthetic-A", receiptID: receipt, outcome: .withHelp, parentApproved: true)
        }
        #expect(LearningHandoffStore(defaults: storage).observations(profileID: "synthetic-A") == [observation])
        #expect(try store.exportCode(profileID: "synthetic-A", parentApproved: true) == code)
    }

    @Test func unlinkAndLearnerResetKeepReplayProtectionWhileAllResetDeletesIt() throws {
        let storage = defaults()
        let store = LearningHandoffStore(defaults: storage)
        _ = try store.approveImport(code: code, recipientProfileID: "synthetic-A", parentApproved: true)
        _ = try store.recordObservation(profileID: "synthetic-A", receiptID: receipt, outcome: .withHelp, parentApproved: true)
        let other = try store.createMission(profileID: "synthetic-B", target: 5, parentApproved: true)
        try store.unlink(profileID: "synthetic-A")
        #expect(store.assignment(profileID: "synthetic-A") == nil)
        #expect(store.observations(profileID: "synthetic-A").count == 1)
        try store.reset(profileID: "synthetic-A")
        #expect(store.observations(profileID: "synthetic-A").isEmpty)
        #expect(store.assignment(profileID: "synthetic-B") == other)
        let data = try #require(storage.data(forKey: LearningHandoffStore.storageKey))
        #expect(!String(decoding: data, as: UTF8.self).contains("synthetic-A"))
        #expect(throws: LearningHandoffError.alreadyReceived) { try store.preview(code: code) }
        store.resetAll()
        #expect(storage.object(forKey: LearningHandoffStore.storageKey) == nil)
        #expect(try store.preview(code: code).receiptID == receipt)
    }

    @Test func corruptFutureSchemaAndWrongTypedStorageFailClosedUntilAllReset() {
        for invalid: Any in [Data("{bad}".utf8), Data("{\"schemaVersion\":2,\"receipts\":[],\"assignments\":[],\"observations\":[]}".utf8), "wrong type"] {
            let storage = defaults()
            storage.set(invalid, forKey: LearningHandoffStore.storageKey)
            let store = LearningHandoffStore(defaults: storage)
            #expect(store.storageError == .damagedLocalStorage)
            #expect(throws: LearningHandoffError.damagedLocalStorage) {
                try store.approveImport(code: code, recipientProfileID: "synthetic-A", parentApproved: true)
            }
            #expect(storage.object(forKey: LearningHandoffStore.storageKey) != nil)
            store.resetAll()
            #expect(store.storageError == nil)
        }
    }

    @Test func receiptLimitDoesNotSilentlyForgetOldReplayProtection() throws {
        let store = LearningHandoffStore(defaults: defaults())
        var previous: UUID?
        var firstCode: String?
        for index in 0..<LearningHandoffStore.maximumReceipts {
            let next = try store.createMission(profileID: "synthetic-A", target: 5, parentApproved: true, replacingReceiptID: previous)
            previous = next.payload.receiptID
            if index == 0 { firstCode = try store.exportCode(profileID: "synthetic-A", parentApproved: true) }
        }
        #expect(throws: LearningHandoffError.receiptLimitReached) {
            try store.createMission(profileID: "synthetic-A", target: 5, parentApproved: true, replacingReceiptID: previous)
        }
        #expect(throws: LearningHandoffError.alreadyReceived) { try store.preview(code: #require(firstCode)) }
    }
}
