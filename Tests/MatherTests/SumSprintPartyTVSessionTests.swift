import Foundation
import Testing
@testable import Mather

@MainActor
struct SumSprintPartyTVSessionTests {
    private func store(profile: String = "tv-family", family: Bool = true) -> (UserDefaults, SumSprintPartyTVSessionStore) {
        let name = "SumSprintSessionTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: name)!
        return (defaults, SumSprintPartyTVSessionStore(defaults: defaults, profileID: profile, familyMode: family))
    }

    @Test func reviewedRangesHaveBoundedUniqueFactsAndChoices() {
        for range in SumSprintPartyTVRange.allCases {
            let facts = SumSprintPartyTVRound.facts(through: range.rawValue)
            #expect(Set(facts.map(\.sum)) == Set(2...range.rawValue))
            #expect(Set(facts.map(\.id)).count == facts.count)
            for fact in facts {
                let choices = SumSprintPartyTVRound.answerChoices(for: fact, through: range.rawValue)
                #expect(choices.count == 4)
                #expect(Set(choices).count == 4)
                #expect(choices.contains(fact.sum))
                #expect(choices.allSatisfy { (1...range.rawValue).contains($0) })
            }
        }
        #expect(SumSprintPartyTVRound.facts(through: 7).isEmpty)
    }

    @Test func eachRangeHasFivePracticeItemsAndAFreshChangedRepresentationProbe() throws {
        for range in SumSprintPartyTVRange.allCases {
            let checkpoint = SumSprintPartyTVCheckpoint.make(range: range, profileID: "tv-family", familyMode: true, seed: 17)
            #expect(checkpoint.isValid(for: "tv-family", familyMode: true))
            #expect(checkpoint.items.count == 6)
            let probe = try #require(checkpoint.items.last)
            #expect(probe.isFreshProbe)
            #expect(probe.representation == .numberParts)
            #expect(!checkpoint.items.dropLast().contains { $0.round.fact.id == probe.round.fact.id || $0.representation == probe.representation })
            #expect(checkpoint.progress.allSatisfy { !$0.usedHelp })
        }
    }

    @Test func generationFreezesFactsChoicesAndIdentityForGivenSeed() {
        let first = SumSprintPartyTVCheckpoint.make(range: .through10, profileID: "child", familyMode: false, seed: 88, sessionID: "fixed", startedAt: .distantPast)
        let second = SumSprintPartyTVCheckpoint.make(range: .through10, profileID: "child", familyMode: false, seed: 88, sessionID: "fixed", startedAt: .distantPast)
        #expect(first == second)
        #expect(first.items != SumSprintPartyTVCheckpoint.make(range: .through10, profileID: "child", familyMode: false, seed: 89).items)
    }

    @Test func wrongAnswerStaysOpenWithoutRevealingTotalOrRemovingProgress() throws {
        let (_, persistence) = store()
        let session = SumSprintPartyTVSession(store: persistence)
        session.start(range: .through5, seed: 17)
        let item = try #require(session.currentItem)
        let wrong = try #require(item.round.answerChoices.first { $0 != item.round.correctAnswer })
        session.choose(wrong)
        #expect(session.currentItem == item)
        #expect(session.currentProgress?.outcome == nil)
        #expect(session.currentProgress?.support == .groups)
        #expect(session.checkpoint?.currentIndex == 0)
        #expect(!session.prompt.contains(" is \(item.round.correctAnswer)."))
        session.choose(item.round.correctAnswer)
        #expect(session.currentProgress?.outcome == .supportedCorrect)
        #expect(session.checkpoint?.helpedCount == 1)
    }

    @Test func countOnMovesOneCounterPerSelectAndStopsAtThePartBoundary() throws {
        let (_, persistence) = store()
        let session = SumSprintPartyTVSession(store: persistence)
        session.start(range: .through20, seed: 3)
        let item = try #require(session.currentItem)
        session.countNext()
        #expect(session.currentProgress?.counted == 0)
        session.requestHelp(); session.requestHelp()
        for count in 1...item.round.fact.addendB {
            session.countNext()
            #expect(session.currentProgress?.counted == count)
        }
        session.countNext()
        #expect(session.currentProgress?.counted == item.round.fact.addendB)
        session.choose(item.round.correctAnswer)
        #expect(session.currentProgress?.outcome == .supportedCorrect)
    }

    @Test func helpedRetrySurvivesRelaunchAndReplaysIdenticalEventIDs() throws {
        let (_, persistence) = store()
        let session = SumSprintPartyTVSession(store: persistence)
        session.start(range: .through10, seed: 17)
        session.requestHelp(); session.requestHelp(); session.countNext()
        let frozen = try #require(session.checkpoint)
        var delivered: [ItemAttempt] = []
        let restored = SumSprintPartyTVSession(store: persistence, onAttempt: { delivered.append($0) })
        #expect(restored.checkpoint == frozen)
        restored.resume()
        #expect(delivered == frozen.attempts)
        #expect(restored.checkpoint?.attempts == frozen.attempts)
        restored.choose(try #require(restored.currentItem).round.correctAnswer)
        #expect(restored.currentProgress?.outcome == .supportedCorrect)
        let correct = try #require(restored.checkpoint?.attempts.last)
        #expect(correct.appHintUsed == true)
        #expect(correct.adultHelp == .unknown)
        #expect(correct.itemVariantID == restored.currentItem?.variantID)
    }

    @Test func aFreshProbeStartsWithoutSupportAfterHelpedPractice() throws {
        let (_, persistence) = store()
        let session = SumSprintPartyTVSession(store: persistence)
        session.start(range: .through5, seed: 17)
        for _ in 0..<5 {
            session.requestHelp()
            session.choose(try #require(session.currentItem).round.correctAnswer)
            session.advance()
        }
        #expect(session.currentItem?.isFreshProbe == true)
        #expect(session.currentProgress?.usedHelp == false)
        let exposure = try #require(session.checkpoint?.attempts.last)
        #expect(exposure.outcome == .exposure)
        #expect(exposure.appHintUsed == false)
        #expect(exposure.isFreshProbe == true)
        session.choose(try #require(session.currentItem).round.correctAnswer)
        #expect(session.currentProgress?.outcome == .independentCorrect)
        session.advance()
        #expect(session.checkpoint?.freshProbeUnaided == true)
        #expect(session.checkpoint?.unaidedCount == 1)
        #expect(session.checkpoint?.helpedCount == 5)
    }

    @Test func sessionIsFiniteAndRepeatedSelectDoesNotDuplicateAnswersOrResults() throws {
        let (_, persistence) = store()
        var results: [ActivityResult] = []
        let session = SumSprintPartyTVSession(store: persistence, onResult: { results.append($0) })
        session.start(range: .through20, seed: 18)
        for _ in 0..<6 {
            let answer = try #require(session.currentItem).round.correctAnswer
            session.choose(answer)
            let events = session.checkpoint?.attempts
            session.choose(answer); session.requestHelp(); session.countNext()
            #expect(session.checkpoint?.attempts == events)
            session.advance()
        }
        session.advance(); session.choose(1)
        #expect(session.checkpoint?.isComplete == true)
        #expect(results.count == 1)
        #expect(results.first?.completedStageIDs == ["practice", "fresh-probe"])
        #expect(results.first?.attempts.count == 12)
        #expect(persistence.history()?.count == 1)
    }

    @Test func completionCanReplayAfterCrashBetweenSavingAndLedgerDelivery() throws {
        let (_, persistence) = store()
        let session = SumSprintPartyTVSession(store: persistence)
        session.start(range: .through5, seed: 18)
        for _ in 0..<6 { session.choose(try #require(session.currentItem).round.correctAnswer); session.advance() }
        let result = try #require(session.checkpoint?.result)
        var replayed: [ActivityResult] = []
        let restored = SumSprintPartyTVSession(store: persistence, onResult: { replayed.append($0) })
        restored.replayEvidence()
        #expect(replayed == [result])
    }

    @Test func profileAndFamilyCheckpointsAreIsolatedAndLegacyBestIsPreserved() throws {
        let (defaults, familyStore) = store()
        defaults.set(27, forKey: "tv.sumSprintParty.personalBest")
        let family = SumSprintPartyTVSession(profileID: "child-a", familyMode: true, store: familyStore)
        family.start(range: .through5, seed: 1)
        #expect(family.checkpoint?.profileID == "tv-family")
        let childAStore = SumSprintPartyTVSessionStore(defaults: defaults, profileID: "child-a", familyMode: false)
        let childA = SumSprintPartyTVSession(profileID: "child-a", familyMode: false, store: childAStore)
        #expect(!childA.canResume)
        childA.start(range: .through10, seed: 1)
        #expect(childA.checkpoint?.profileID == "child-a")
        let childB = SumSprintPartyTVSession(profileID: "child-b", familyMode: false,
            store: SumSprintPartyTVSessionStore(defaults: defaults, profileID: "child-b", familyMode: false))
        #expect(!childB.canResume)
        #expect(defaults.integer(forKey: "tv.sumSprintParty.personalBest") == 27)
        #expect(familyStore.load(profileID: "tv-family", familyMode: true)?.sessionID == family.checkpoint?.sessionID)
    }

    @Test func startingAnotherSessionArchivesAnUnfinishedSessionInsteadOfErasingIt() throws {
        let (_, persistence) = store()
        let session = SumSprintPartyTVSession(store: persistence)
        session.start(range: .through5, seed: 2); session.requestHelp()
        let previous = try #require(session.checkpoint)
        session.start(range: .through10, seed: 3)
        #expect(persistence.history() == [previous])
        #expect(session.checkpoint?.sessionID != previous.sessionID)
        #expect(session.checkpoint?.range == .through10)
    }

    @Test func malformedCheckpointIsRejectedRatherThanIndexingInvalidItems() throws {
        let (defaults, persistence) = store()
        var checkpoint = SumSprintPartyTVCheckpoint.make(range: .through5, profileID: "tv-family", familyMode: true, seed: 2)
        checkpoint.currentIndex = 6
        defaults.set(try JSONEncoder().encode(checkpoint), forKey: "tv.sumSprintParty.learning.v1.family.tv-family")
        #expect(persistence.load(profileID: "tv-family", familyMode: true) == nil)
        #expect(persistence.checkpointState == .unsupported)
        checkpoint.currentIndex = 0
        checkpoint.progress[0].support = .groups
        checkpoint.progress[0].selectedAnswer = checkpoint.items[0].round.correctAnswer
        checkpoint.progress[0].outcome = .independentCorrect
        #expect(!checkpoint.isValid(for: "tv-family", familyMode: true))
        #expect(!checkpoint.isValid(for: "another-child", familyMode: true))
    }

    @Test func probeSelectionAvoidsPreviouslyExposedVariantsAndLabelsExhaustionHonestly() throws {
        let (_, persistence) = store()
        let session = SumSprintPartyTVSession(store: persistence)
        var variants: Set<String> = []
        for _ in 0..<6 {
            session.start(range: .through5, seed: 17)
            for _ in 0..<5 { session.choose(try #require(session.currentItem).round.correctAnswer); session.advance() }
            let probe = try #require(session.currentItem)
            #expect(probe.isFreshProbe)
            #expect(!variants.contains(probe.variantID))
            variants.insert(probe.variantID)
            session.choose(probe.round.correctAnswer); session.advance()
        }
        #expect(variants.count == 6)
        session.start(range: .through5, seed: 17)
        for _ in 0..<5 { session.choose(try #require(session.currentItem).round.correctAnswer); session.advance() }
        #expect(session.currentItem?.isProbe == true)
        #expect(session.currentItem?.isFreshProbe == false)
        session.choose(try #require(session.currentItem).round.correctAnswer); session.advance()
        #expect(session.checkpoint?.freshProbeUnaided == false)
        #expect(session.checkpoint?.attempts.last?.isFreshProbe == false)
        #expect(session.checkpoint?.result?.completedStageIDs == ["practice", "transfer"])
    }

    @Test func clearRemovesOnlyTheFrozenProfilesLearningSessionAndHistory() throws {
        let (defaults, familyStore) = store()
        defaults.set(27, forKey: "tv.sumSprintParty.personalBest")
        let family = SumSprintPartyTVSession(store: familyStore)
        family.start(range: .through5, seed: 1)
        family.start(range: .through5, seed: 2)
        let childStore = SumSprintPartyTVSessionStore(defaults: defaults, profileID: "child-a", familyMode: false)
        let child = SumSprintPartyTVSession(profileID: "child-a", familyMode: false, store: childStore)
        child.start(range: .through10, seed: 1)
        let savedChild = try #require(child.checkpoint)
        #expect(familyStore.history()?.isEmpty == false)
        familyStore.clear()
        #expect(familyStore.load(profileID: "tv-family", familyMode: true) == nil)
        #expect(familyStore.history()?.isEmpty == true)
        #expect(childStore.load(profileID: "child-a", familyMode: false) == savedChild)
        #expect(defaults.integer(forKey: "tv.sumSprintParty.personalBest") == 27)
    }

    @Test func storageStatesDistinguishMissingLoadedAndUnsupportedValues() throws {
        let (defaults, persistence) = store()
        #expect(persistence.checkpointState == .missing)
        #expect(persistence.historyState == .missing)
        let checkpoint = SumSprintPartyTVCheckpoint.make(range: .through5, profileID: "tv-family", familyMode: true, seed: 2)
        #expect(persistence.save(checkpoint))
        #expect(persistence.archive(checkpoint))
        #expect(persistence.checkpointState == .loaded(checkpoint))
        #expect(persistence.historyState == .loaded([checkpoint]))
        defaults.set("not encoded data", forKey: "tv.sumSprintParty.learning.v1.family.tv-family")
        #expect(persistence.checkpointState == .unsupported)
        #expect(persistence.storageMessage != nil)
        #expect(!persistence.save(checkpoint))
        #expect(defaults.string(forKey: "tv.sumSprintParty.learning.v1.family.tv-family") == "not encoded data")
    }

    @Test func futureCheckpointAndValidHistoryArePreservedWhenStartingOrSaving() throws {
        let (defaults, persistence) = store()
        let key = "tv.sumSprintParty.learning.v1.family.tv-family"
        let checkpoint = SumSprintPartyTVCheckpoint.make(range: .through5, profileID: "tv-family", familyMode: true, seed: 2)
        #expect(persistence.archive(checkpoint))
        let originalHistory = try #require(defaults.data(forKey: key + ".history"))
        var future = try #require(JSONSerialization.jsonObject(with: JSONEncoder().encode(checkpoint)) as? [String: Any])
        future["version"] = 99
        let original = try JSONSerialization.data(withJSONObject: future)
        defaults.set(original, forKey: key)
        var events: [ItemAttempt] = []
        let session = SumSprintPartyTVSession(store: persistence, onAttempt: { events.append($0) })
        session.start(range: .through10, seed: 3); session.resume(); session.replayEvidence()
        #expect(session.storageMessage != nil)
        #expect(!session.isSessionOpen)
        #expect(!session.canResume)
        #expect(events.isEmpty)
        #expect(!persistence.save(checkpoint))
        #expect(!persistence.archive(checkpoint))
        #expect(defaults.data(forKey: key) == original)
        #expect(defaults.data(forKey: key + ".history") == originalHistory)
    }

    @Test func unknownHistoryBlocksProbeClaimsAndKeepsCompletedCheckpointBytes() throws {
        let (defaults, persistence) = store()
        let key = "tv.sumSprintParty.learning.v1.family.tv-family"
        let session = SumSprintPartyTVSession(store: persistence)
        session.start(range: .through5, seed: 17)
        for _ in 0..<6 { session.choose(try #require(session.currentItem).round.correctAnswer); session.advance() }
        let checkpointBytes = try #require(defaults.data(forKey: key))
        let historyBytes = Data("future-or-damaged-history".utf8)
        defaults.set(historyBytes, forKey: key + ".history")
        var events: [ItemAttempt] = []
        var results: [ActivityResult] = []
        let restored = SumSprintPartyTVSession(store: persistence,
            onAttempt: { events.append($0) }, onResult: { results.append($0) })
        restored.replayEvidence(); restored.resume(); restored.start(range: .through5, seed: 17)
        #expect(persistence.historyState == .unsupported)
        #expect(persistence.history() == nil)
        #expect(restored.storageMessage != nil)
        #expect(!restored.isSessionOpen)
        #expect(events.isEmpty)
        #expect(results.isEmpty)
        #expect(defaults.data(forKey: key) == checkpointBytes)
        #expect(defaults.data(forKey: key + ".history") == historyBytes)
    }

    @Test func historyValidatesScopeVersionProgressAndDuplicateSessionIdentities() throws {
        let (defaults, persistence) = store()
        let key = "tv.sumSprintParty.learning.v1.family.tv-family.history"
        let checkpoint = SumSprintPartyTVCheckpoint.make(range: .through5, profileID: "tv-family", familyMode: true, seed: 2)
        let wrongProfile = SumSprintPartyTVCheckpoint.make(range: .through5, profileID: "other-child", familyMode: false, seed: 2)
        var wrongProgress = checkpoint
        wrongProgress.currentIndex = 100
        var future = try #require(JSONSerialization.jsonObject(with: JSONEncoder().encode(checkpoint)) as? [String: Any])
        future["version"] = 2
        let fixtures = [try JSONEncoder().encode([wrongProfile]), try JSONEncoder().encode([wrongProgress]),
            try JSONEncoder().encode([checkpoint, checkpoint]), try JSONSerialization.data(withJSONObject: [future])]
        for fixture in fixtures {
            defaults.set(fixture, forKey: key)
            #expect(persistence.historyState == .unsupported)
            #expect(!persistence.archive(checkpoint))
            #expect(!persistence.save(checkpoint))
            #expect(defaults.data(forKey: key) == fixture)
        }
    }

    @Test func malformedCheckpointIsNotOverwrittenAndInvalidNewWritesAreRejected() {
        let (defaults, persistence) = store()
        let key = "tv.sumSprintParty.learning.v1.family.tv-family"
        let original = Data("not-json".utf8)
        defaults.set(original, forKey: key)
        let valid = SumSprintPartyTVCheckpoint.make(range: .through5, profileID: "tv-family", familyMode: true, seed: 2)
        #expect(!persistence.save(valid))
        #expect(!persistence.archive(valid))
        #expect(defaults.data(forKey: key) == original)
        #expect(defaults.object(forKey: key + ".history") == nil)
        persistence.clear()
        var invalid = valid
        invalid.currentIndex = 100
        #expect(!persistence.save(invalid))
        #expect(!persistence.archive(invalid))
        #expect(persistence.checkpointState == .missing)
        #expect(persistence.historyState == .missing)
    }

    @Test func corruptionAppearingDuringPlayPausesWithoutDeliveringNewEvidence() throws {
        let (defaults, persistence) = store()
        let key = "tv.sumSprintParty.learning.v1.family.tv-family"
        var events: [ItemAttempt] = []
        let session = SumSprintPartyTVSession(store: persistence, onAttempt: { events.append($0) })
        session.start(range: .through5, seed: 17)
        let item = try #require(session.currentItem)
        let original = try #require(defaults.data(forKey: key))
        let history = Data("unsupported".utf8)
        defaults.set(history, forKey: key + ".history")
        let delivered = events
        session.choose(item.round.correctAnswer); session.requestHelp(); session.countNext(); session.advance()
        #expect(events == delivered)
        #expect(session.storageMessage != nil)
        #expect(!session.isSessionOpen)
        #expect(defaults.data(forKey: key) == original)
        #expect(defaults.data(forKey: key + ".history") == history)
    }

    @Test func explicitScopedResetAllowsLearningAgainAfterUnsupportedStorage() {
        let (defaults, persistence) = store()
        defaults.set(Data("unsupported".utf8), forKey: "tv.sumSprintParty.learning.v1.family.tv-family.history")
        defaults.set(27, forKey: "tv.sumSprintParty.personalBest")
        let session = SumSprintPartyTVSession(store: persistence)
        #expect(session.storageMessage != nil)
        persistence.clear()
        session.start(range: .through5, seed: 17)
        #expect(session.storageMessage == nil)
        #expect(session.isSessionOpen)
        #expect(session.checkpoint?.items.last?.isFreshProbe == true)
        #expect(defaults.integer(forKey: "tv.sumSprintParty.personalBest") == 27)
    }
}
