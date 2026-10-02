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
        #expect(persistence.history().count == 1)
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
        let (_, persistence) = store()
        var checkpoint = SumSprintPartyTVCheckpoint.make(range: .through5, profileID: "tv-family", familyMode: true, seed: 2)
        checkpoint.currentIndex = 6
        persistence.save(checkpoint)
        #expect(persistence.load(profileID: "tv-family", familyMode: true) == nil)
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
        #expect(!familyStore.history().isEmpty)
        familyStore.clear()
        #expect(familyStore.load(profileID: "tv-family", familyMode: true) == nil)
        #expect(familyStore.history().isEmpty)
        #expect(childStore.load(profileID: "child-a", familyMode: false) == savedChild)
        #expect(defaults.integer(forKey: "tv.sumSprintParty.personalBest") == 27)
    }
}
