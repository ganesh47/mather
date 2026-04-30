import Foundation
import Testing
@testable import Mather

private final class InMemoryMasteryDefaults: ExplorerLabMasteryKeyValueStore {
    var values: [String: Data] = [:]

    func data(forKey defaultName: String) -> Data? {
        values[defaultName]
    }

    func set(_ value: Data?, forKey defaultName: String) {
        values[defaultName] = value
    }

    func removeObject(forKey defaultName: String) {
        values.removeValue(forKey: defaultName)
    }
}

struct ExplorerLabMasteryStoreTests {
    @Test
    func missingDataLoadsSeededProfile() throws {
        let storage = InMemoryMasteryDefaults()
        let store = ExplorerLabMasteryStore(storage: storage, storageKey: "test.mastery")

        let profile = store.load()

        #expect(profile.lanes.keys.count == CapabilityLaneID.allCases.count)
        let numbers = try #require(profile[.numbers])
        #expect(numbers.conceptConfidence["number-bond"] == .introduced)
    }

    @Test
    func savedProfileRoundTripsMasteryState() throws {
        let storage = InMemoryMasteryDefaults()
        let store = ExplorerLabMasteryStore(storage: storage, storageKey: "test.mastery")
        var profile = ExplorerLabMasteryProfile.emptyExplorerProfile()
        var numbers = try #require(profile[.numbers])
        numbers.markCompleted(.learn)
        numbers.markReviewedCard(id: "numbers-number-bond-five-and-five")
        numbers.setConfidence(.mastered, for: "number-bond")
        profile[.numbers] = numbers

        try store.save(profile)
        let reloaded = store.load()

        let reloadedNumbers = try #require(reloaded[.numbers])
        #expect(reloadedNumbers.completedModes == [.learn])
        #expect(reloadedNumbers.reviewedCardIDs == ["numbers-number-bond-five-and-five"])
        #expect(reloadedNumbers.conceptConfidence["number-bond"] == .mastered)
    }

    @Test
    func corruptDataFallsBackToSeededProfile() throws {
        let storage = InMemoryMasteryDefaults()
        storage.set(Data("not json".utf8), forKey: "test.mastery")
        let store = ExplorerLabMasteryStore(storage: storage, storageKey: "test.mastery")

        let profile = store.load()

        #expect(profile.lanes.keys.count == CapabilityLaneID.allCases.count)
    }

    @Test
    func resetRemovesSavedProfile() throws {
        let storage = InMemoryMasteryDefaults()
        let store = ExplorerLabMasteryStore(storage: storage, storageKey: "test.mastery")
        try store.save(.emptyExplorerProfile())

        store.reset()

        #expect(storage.values["test.mastery"] == nil)
    }
}
