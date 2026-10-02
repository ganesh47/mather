import Foundation
import Testing
@testable import Mather

@MainActor
struct CompareCampPassportStoreTests {
    @Test
    func completedSessionPersistsAndDuplicateObservationDoesNotAddASticker() throws {
        let suite = "CompareCampPassportTests.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let result = CompareCampSessionResult(
            id: UUID(), categoryID: CompareCampCategory.first.id, activity: .adventure,
            difficulty: .growing, seed: 17, roundsCompleted: 8,
            firstTryCount: 5, helpedRoundCount: 3, completedAt: Date(timeIntervalSince1970: 100)
        )
        let store = CompareCampPassportStore(defaults: defaults)
        store.record(result)
        store.record(result)
        let reloaded = CompareCampPassportStore(defaults: defaults)
        #expect(reloaded.progress.totalSessionCount == 1)
        #expect(reloaded.progress.totalRounds == 8)
        #expect(reloaded.progress.completedCampIDs.contains(result.categoryID))
        #expect(reloaded.progress.sessions.first == result)
    }

    @Test
    func corruptPassportDoesNotPreventNewAdventuresFromSaving() throws {
        let suite = "CompareCampPassportTests.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        defaults.set(Data("broken JSON".utf8), forKey: CompareCampPassportStore.storageKey)
        let store = CompareCampPassportStore(defaults: defaults)
        #expect(store.progress.sessions.isEmpty)
        let result = CompareCampSessionResult(
            id: UUID(), categoryID: CompareCampCategory.first.id, activity: .more,
            difficulty: .small, seed: 2, roundsCompleted: 8,
            firstTryCount: 8, helpedRoundCount: 0, completedAt: Date(timeIntervalSince1970: 200)
        )
        store.record(result)
        #expect(CompareCampPassportStore(defaults: defaults).progress.sessions == [result])
    }
}
