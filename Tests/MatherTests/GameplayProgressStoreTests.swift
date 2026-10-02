import Foundation
import SwiftData
import Testing
@testable import Mather

@MainActor
struct GameplayProgressStoreTests {
    @Test
    func exposuresPersistAcrossStoreLifecycle() throws {
        let (context, profileId) = try makeGameplayProgressContext()
        let thread = sampleThread()
        let stage = thread.stages[0]
        let round = SpacedRepetitionScheduler.makeRound(thread: thread, stage: stage, seed: 912)

        var store: GameplayProgressStore? = GameplayProgressStore(modelContext: context, activeProfileIdProvider: { profileId })
        store?.markExposed(thread: thread, stage: stage, items: Array(round.items.prefix(1)), at: Date(timeIntervalSince1970: 100))
        store = nil

        let reloaded = GameplayProgressStore(modelContext: context, activeProfileIdProvider: { profileId })
        let fetched = reloaded.storedRecords(forThread: thread.id)

        #expect(fetched.count == 1)
        #expect(fetched[0].exposureCount == 1)
        #expect(fetched[0].profileId == profileId)
        #expect(fetched[0].threadId == thread.id)
    }

    @Test
    func updatesPersistAndFeedSchedulerOrdering() throws {
        let (context, profileId) = try makeGameplayProgressContext()
        let store = GameplayProgressStore(modelContext: context, activeProfileIdProvider: { profileId })
        let thread = sampleThread()
        let stage = thread.stages.first { $0.id == "easy-memory" }!
        let now = Date(timeIntervalSince1970: 2_000)
        let weakKey = GameplayExposureKey(entityID: "country-japan", propertyID: "country-japan-capital", stageID: stage.id)
        let strongKey = GameplayExposureKey(entityID: "country-india", propertyID: "country-india-capital", stageID: stage.id)

        store.apply(
            updates: [
                SpacedRepetitionUpdate(key: strongKey, outcome: .correct, occurredAt: now.addingTimeInterval(-60)),
                SpacedRepetitionUpdate(key: strongKey, outcome: .correct, occurredAt: now.addingTimeInterval(-30)),
                SpacedRepetitionUpdate(key: strongKey, outcome: .correct, occurredAt: now),
                SpacedRepetitionUpdate(key: weakKey, outcome: .incorrect, occurredAt: now)
            ],
            thread: thread
        )

        let weak = store.dueAndWeakRecords(threadID: thread.id, now: now).first
        #expect(weak?.entityId == "country-japan")
        #expect(weak?.confidenceBand == .reviewNeeded)

        let round = store.makeRound(thread: thread, stage: stage, now: now.addingTimeInterval(60 * 60 + 1), seed: 7)
        #expect(round.items.first?.entityID == "country-japan")
    }

    @Test
    func threadSessionsDoNotMutateStoredGameSessionSummaries() throws {
        let (context, profileId) = try makeGameplayProgressContext()
        let progressStore = GameplayProgressStore(modelContext: context, activeProfileIdProvider: { profileId })
        let gameSessionStore = GameSessionStore(modelContext: context, activeProfileIdProvider: { profileId })
        let thread = sampleThread()
        let started = Date(timeIntervalSince1970: 5_000)

        gameSessionStore.save(
            gameName: "Sum Sprint",
            startedAt: started,
            scoreValue: 8,
            scoreLabel: "correct",
            detail: "warmup"
        )
        progressStore.saveThreadSession(
            thread: thread,
            startedAt: started,
            endedAt: started.addingTimeInterval(45),
            results: [GameplayStageResult(id: "r1", stageID: "flashcards", correctCount: 3, mistakeCount: 0, hintsUsed: 0, durationSeconds: 45, completedAt: started.addingTimeInterval(45))]
        )

        #expect(progressStore.threadSessions(forThread: thread.id).count == 1)
        let gameSessions = gameSessionStore.sessions(forGame: "Sum Sprint")
        #expect(gameSessions.count == 1)
        #expect(gameSessions[0].scoreValue == 8)
        #expect(gameSessions[0].detail == "warmup")
    }

    @Test
    func duplicateGameSessionSavesForSameProfileGameAndStartCreateOneRow() throws {
        let (context, profileId) = try makeGameplayProgressContext()
        let gameSessionStore = GameSessionStore(modelContext: context, activeProfileIdProvider: { profileId })
        let started = Date(timeIntervalSince1970: 7_000)

        gameSessionStore.save(
            gameName: "Room Quest",
            startedAt: started,
            scoreValue: 5,
            scoreLabel: "tokens collected"
        )
        gameSessionStore.save(
            gameName: "Room Quest",
            startedAt: started,
            scoreValue: 99,
            scoreLabel: "inflated duplicate"
        )

        let gameSessions = gameSessionStore.sessions(forGame: "Room Quest")
        #expect(gameSessions.count == 1)
        #expect(gameSessions[0].scoreValue == 5)
        #expect(gameSessions[0].scoreLabel == "tokens collected")
    }

    @Test
    func clearActiveProfilePreservesOtherProfileGameSessions() throws {
        let schema = Schema([StoredGameSession.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: config)
        let context = ModelContext(container)
        var activeProfileId = "profile-a"
        let store = GameSessionStore(modelContext: context, activeProfileIdProvider: { activeProfileId })

        store.save(
            gameName: "Sum Sprint",
            startedAt: Date(timeIntervalSince1970: 9_000),
            scoreValue: 4,
            scoreLabel: "profile A"
        )
        activeProfileId = "profile-b"
        store.save(
            gameName: "Room Quest",
            startedAt: Date(timeIntervalSince1970: 10_000),
            scoreValue: 7,
            scoreLabel: "profile B"
        )

        activeProfileId = "profile-a"
        store.clearActiveProfile()

        let fetched = try context.fetch(FetchDescriptor<StoredGameSession>())
        #expect(fetched.count == 1)
        #expect(fetched[0].profileId == "profile-b")
        #expect(fetched[0].gameName == "Room Quest")
        #expect(fetched[0].scoreLabel == "profile B")
    }

    @Test
    func appSchemaIncludesGameplayProgressModels() throws {
        let schema = Schema([
            StoredSessionSummary.self,
            StoredRoomQuestStationReference.self,
            StoredFactRecord.self,
            StoredKidProfile.self,
            StoredTelemetryEvent.self,
            StoredGameSession.self,
            StoredGameplayProgressRecord.self,
            StoredGameplayThreadSession.self
        ])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        _ = try ModelContainer(for: schema, configurations: config)
    }

    @Test
    func itemEventsAreIdempotentAndExposureDoesNotBecomeRecallEvidence() throws {
        let (context, profileID) = try makeGameplayProgressContext()
        let store = GameplayProgressStore(modelContext: context, activeProfileIdProvider: { profileID })
        let exposure = ItemAttempt(activityID: "fruit", conceptID: "taste", entityID: "mango", propertyID: "taste", stageID: "look", outcome: .exposure)
        let help = ItemAttempt(activityID: "fruit", conceptID: "taste", entityID: "mango", propertyID: "taste", stageID: "quiz", outcome: .help)
        let success = ItemAttempt(activityID: "fruit", conceptID: "taste", entityID: "mango", propertyID: "taste", stageID: "quiz", outcome: .supportedCorrect)
        store.recordAttempts([exposure, help, success], sessionID: "one")
        store.recordAttempts([exposure, help, success], sessionID: "one")
        let records = store.allRecords()
        let look = try #require(records.first { $0.stageId == "look" })
        let quiz = try #require(records.first { $0.stageId == "quiz" })
        #expect(look.exposureCount == 1)
        #expect(look.correctCount == 0)
        #expect(look.supportedCorrectCount == 0)
        #expect(look.confidenceBand == .new)
        #expect(quiz.hintCount == 1)
        #expect(quiz.supportedCorrectCount == 1)
        #expect(quiz.correctCount == 0)
        #expect(quiz.confidenceBand == .learning)
        #expect(try JSONDecoder().decode([ItemAttempt].self, from: try #require(quiz.itemAttemptsData)).count == 2)
    }

    @Test
    func migrationRetainsLegacyHistoryWithoutInventingConfidence() throws {
        let (context, profileID) = try makeGameplayProgressContext()
        let legacy = StoredGameplayProgressRecord(uniqueKey: "legacy", profileId: profileID, threadId: "country", entityId: "india", stageId: "quiz",
            exposureCount: 9, correctCount: 7, incorrectCount: 1, supportedCorrectCount: 1, hintCount: 2,
            confidenceBandRawValue: GameplayConfidenceBand.steady.rawValue, lastOutcomeRawValue: GameplayExposureOutcome.correct.rawValue)
        context.insert(legacy)
        let historical = StoredGameplayThreadSession(profileId: profileID, threadId: "country", startedAt: .distantPast, endedAt: .now,
            durationSeconds: 30, totalScore: 80, stars: 3)
        context.insert(historical)
        try context.save()
        let store = GameplayProgressStore(modelContext: context, activeProfileIdProvider: { profileID })
        let migrated = try #require(store.allRecords().first)
        #expect(migrated.evidenceSchemaVersion == 1)
        #expect(migrated.exposureCount == 9)
        #expect(migrated.correctCount == 0)
        #expect(migrated.incorrectCount == 0)
        #expect(migrated.confidenceBand == .new)
        #expect(migrated.consecutiveIndependentCorrect == 0)
        #expect(try JSONDecoder().decode([Int].self, from: try #require(migrated.legacyAggregateCountsData)) == [7, 1, 1, 2])
        #expect(store.allSessions().first?.totalScore == 80)
        _ = store.allRecords()
        #expect(try JSONDecoder().decode([Int].self, from: try #require(migrated.legacyAggregateCountsData)) == [7, 1, 1, 2])
    }

    @Test
    func partialResultsUpsertAndCheckpointAndResetStayWithinSelectedChild() throws {
        let (context, _) = try makeGameplayProgressContext()
        let suiteName = "mather-evidence-tests-" + UUID().uuidString
        let defaults = try #require(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }
        var profileID = "child-one"
        let store = GameplayProgressStore(modelContext: context, activeProfileIdProvider: { profileID }, defaults: defaults)
        let started = Date(timeIntervalSince1970: 500)
        let event = ItemAttempt(activityID: "quest", conceptID: "angle", entityID: "corner", stageID: "predict", outcome: .independentCorrect)
        store.saveActivityResult(ActivityResult(id: "first", activityID: "quest", title: "Quest", startedAt: started, attempts: [event], completedStageIDs: ["predict"]))
        store.saveActivityResult(ActivityResult(id: "first", activityID: "quest", title: "Quest", startedAt: started, attempts: [event], completedStageIDs: ["predict", "transfer"]))
        store.saveCheckpoint(QuestCheckpoint(activityID: "quest", sessionID: "first", startedAt: started, payload: Data([1, 2])))
        #expect(store.allSessions().count == 1)
        #expect(try JSONDecoder().decode([String].self, from: try #require(store.allSessions().first?.completedStageIdsData)) == ["predict", "transfer"])
        #expect(store.allRecords().first?.correctCount == 1)
        profileID = "child-two"
        #expect(store.allSessions().isEmpty)
        #expect(store.allRecords().isEmpty)
        #expect(store.checkpoint(for: "quest") == nil)
        let other = ItemAttempt(activityID: "quest", conceptID: "angle", entityID: "corner", stageID: "predict", outcome: .incorrect)
        store.recordAttempts([other], sessionID: "second")
        store.saveCheckpoint(QuestCheckpoint(activityID: "quest", sessionID: "second", startedAt: started, payload: Data([3, 4])))
        profileID = "child-one"
        store.clearActiveProfile()
        #expect(store.allSessions().isEmpty)
        #expect(store.allRecords().isEmpty)
        #expect(store.checkpoint(for: "quest") == nil)
        profileID = "child-two"
        #expect(store.allRecords().first?.incorrectCount == 1)
        #expect(store.checkpoint(for: "quest")?.sessionID == "second")
        store.clearAllProfiles()
        #expect(store.allRecords().isEmpty)
        #expect(store.checkpoint(for: "quest") == nil)
    }

    @Test
    func helpAfterConfidenceResetsStreakBeforeAnyAnswer() throws {
        let (context, profileID) = try makeGameplayProgressContext()
        let store = GameplayProgressStore(modelContext: context, activeProfileIdProvider: { profileID })
        for sessionID in ["one", "one", "two"] {
            store.recordAttempts([ItemAttempt(activityID: "quest", conceptID: "angle", entityID: "corner", stageID: "predict", outcome: .independentCorrect)], sessionID: sessionID)
        }
        #expect(store.allRecords().first?.confidenceBand == .steady)
        store.recordAttempts([ItemAttempt(activityID: "quest", conceptID: "angle", entityID: "corner", stageID: "predict", outcome: .help)], sessionID: "three")
        #expect(store.allRecords().first?.confidenceBand == .learning)
        #expect(store.allRecords().first?.consecutiveIndependentCorrect == 0)
        #expect(store.allRecords().first?.correctCount == 3)
    }

    @Test
    func resumedThreadUsesFrozenAnswersAndAssetsAfterRemoteContentChanges() throws {
        let (context, profileID) = try makeGameplayProgressContext()
        let suiteName = "mather-frozen-resume-" + UUID().uuidString
        let defaults = try #require(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let store = GameplayProgressStore(modelContext: context, activeProfileIdProvider: { profileID }, defaults: defaults)
        let original = sampleThread()
        let stage = original.stages[0]
        let round = SpacedRepetitionScheduler.makeRound(thread: original, stage: stage, seed: 87)
        let urls = ["flag": URL(fileURLWithPath: "/verified/v1/flag.png")]
        let checkpoint = GameplayThreadCheckpoint(navigation: GameplayStageNavigationState(), round: round,
            stageState: try JSONEncoder().encode(GameplayFlashcardStageViewModel(thread: original, round: round)),
            attempts: [], introductionIndex: 0, introductionFinished: true, sessionID: "frozen", threadSnapshot: original,
            contentVersion: 1, assetURLs: urls, profileID: profileID)
        store.saveCheckpoint(QuestCheckpoint(activityID: original.id, sessionID: "frozen", startedAt: .now,
            payload: try JSONEncoder().encode(checkpoint)))
        let changed = GameplayThreadDefinition(id: original.id, title: "Updated", category: original.category,
            propertyTypes: original.propertyTypes, entities: [GameplayEntity(id: original.entities[0].id, name: "Changed", properties: [
                GameplayProperty(id: original.entities[0].properties[0].id, typeID: "capital", value: "Changed answer")])], stages: original.stages)
        let resumed = GameplayThreadView(thread: changed, contentVersion: 2, assetURLs: ["flag": URL(fileURLWithPath: "/verified/v2/flag.png")], progressStore: store)
        #expect(resumed.thread == original)
        #expect(resumed.contentVersion == 1)
        #expect(resumed.assetURLs == urls)
    }

    @Test
    func contentUpdateResetsConfidenceAndOldPausedAttemptsRemainHistoryOnly() throws {
        let (context, profileID) = try makeGameplayProgressContext()
        let store = GameplayProgressStore(modelContext: context, activeProfileIdProvider: { profileID })
        let thread = sampleThread()
        let stage = try #require(thread.stages.first { $0.kind == .multipleChoice })
        func event(_ outcome: ItemAttemptOutcome, version: Int) -> ItemAttempt {
            ItemAttempt(activityID: thread.id, conceptID: "capital", entityID: "country-india", propertyID: "country-india-capital",
                stageID: stage.id, outcome: outcome, profileID: profileID, contentVersion: version)
        }
        for sessionID in ["one", "one", "two"] { store.recordAttempts([event(.independentCorrect, version: 2)], sessionID: sessionID) }
        #expect(store.allRecords().first?.confidenceBand == .steady)
        _ = store.makeRound(thread: thread, stage: stage, contentVersion: 3)
        let current = try #require(store.allRecords().first)
        #expect(current.evidenceContentVersion == 3)
        #expect(current.confidenceBand == .new)
        #expect(current.consecutiveIndependentCorrect == 0)
        #expect(current.correctCount == 3)
        store.recordAttempts([event(.independentCorrect, version: 2)], sessionID: "paused-two")
        #expect(current.evidenceContentVersion == 3)
        #expect(current.confidenceBand == .new)
        #expect(current.consecutiveIndependentCorrect == 0)
        #expect(current.correctCount == 3)
        #expect(try JSONDecoder().decode([ItemAttempt].self, from: try #require(current.itemAttemptsData)).count == 4)
        store.recordAttempts([event(.independentCorrect, version: 3)], sessionID: "three")
        #expect(current.confidenceBand == .learning)
        #expect(current.consecutiveIndependentCorrect == 1)
        #expect(current.correctCount == 4)
    }

    @Test
    func staleProfileAttemptsAndResultsAreRejectedAndLatestCheckpointIsChildScoped() throws {
        let (context, _) = try makeGameplayProgressContext()
        let suiteName = "mather-profile-context-" + UUID().uuidString
        let defaults = try #require(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }
        var profileID = "first-child"
        let store = GameplayProgressStore(modelContext: context, activeProfileIdProvider: { profileID }, defaults: defaults)
        let started = Date(timeIntervalSince1970: 400)
        store.saveCheckpoint(QuestCheckpoint(activityID: "fruits", sessionID: "fruit", startedAt: started, payload: Data([1])))
        store.saveCheckpoint(QuestCheckpoint(activityID: "shapes", sessionID: "shape", startedAt: started, payload: Data([2])))
        #expect(store.mostRecentCheckpoint()?.activityID == "shapes")
        #expect(store.mostRecentCheckpoint()?.updatedAt != nil)
        let frozenProfile = profileID
        profileID = "second-child"
        #expect(store.mostRecentCheckpoint() == nil)
        let stale = ItemAttempt(activityID: "fruits", conceptID: "taste", entityID: "mango", stageID: "quiz", outcome: .independentCorrect, profileID: frozenProfile)
        store.recordAttempts([stale], sessionID: "stale")
        #expect(store.allRecords().isEmpty)
        let saved = store.saveActivityResult(ActivityResult(activityID: "fruits", title: "Fruits", startedAt: started, attempts: [stale], completedStageIDs: ["quiz"], profileID: frozenProfile))
        #expect(saved == nil)
        #expect(store.allSessions().isEmpty)
        store.saveCheckpoint(QuestCheckpoint(activityID: "stale", sessionID: "stale", startedAt: started, payload: Data([3]), profileID: frozenProfile))
        #expect(store.checkpoint(for: "stale") == nil)
        let accepted = ItemAttempt(activityID: "shapes", conceptID: "sides", entityID: "triangle", stageID: "quiz", outcome: .independentCorrect)
        store.recordAttempts([accepted], sessionID: "second-session")
        let journal = try JSONDecoder().decode([ItemAttempt].self, from: try #require(store.allRecords().first?.itemAttemptsData))
        #expect(journal[0].profileID == profileID)
        #expect(journal[0].sessionID == "second-session")
        #expect(journal[0].contentVersion == 1)
    }

    @Test(arguments: [ItemAttemptOutcome.incorrect, .help])
    func retryCannotTurnSameSessionSupportIntoIndependentEvidence(_ support: ItemAttemptOutcome) throws {
        let (context, profileID) = try makeGameplayProgressContext()
        let store = GameplayProgressStore(modelContext: context, activeProfileIdProvider: { profileID })
        let thread = sampleThread()
        let stage = try #require(thread.stages.first { $0.kind == .multipleChoice })
        let round = SpacedRepetitionScheduler.makeRound(thread: thread, stage: stage, seed: 91)
        var first = GameplayMultipleChoiceStageViewModel(thread: thread, round: round)
        let question = try #require(first.activeQuestion)
        if support == .help {
            _ = first.showHelp()
        } else {
            let wrong = try #require(question.choices.first { !question.isCorrect($0) })
            let accepted = first.choose(wrong)
            #expect(!accepted)
        }
        // Retry really constructs a new view model, whose local support set is empty.
        var retry = GameplayMultipleChoiceStageViewModel(thread: thread, round: round)
        let accepted = retry.choose(question.answer)
        #expect(accepted)
        let supportEvent = try #require(first.evidence.attempts.first)
        let rawCorrect = try #require(retry.evidence.attempts.first)
        #expect(rawCorrect.outcome == .independentCorrect)
        let previous = [supportEvent.withContext(profileID: profileID, sessionID: "retry", contentVersion: 1)]
        let normalized = ActivityEvidenceNormalizer.normalized([rawCorrect.withContext(profileID: profileID, sessionID: "retry", contentVersion: 1)], after: previous)
        #expect(normalized.first?.outcome == .supportedCorrect)
        #expect(normalized.first?.id == rawCorrect.id)
        store.recordAttempts([supportEvent], sessionID: "retry")
        store.recordAttempts([rawCorrect], sessionID: "retry")
        let saved = try #require(store.saveActivityResult(ActivityResult(id: "retry", activityID: thread.id, title: thread.title,
            startedAt: .now, attempts: [supportEvent, rawCorrect, rawCorrect], completedStageIDs: [stage.id])))
        let journal = try JSONDecoder().decode([ItemAttempt].self, from: try #require(saved.itemAttemptsData))
        #expect(journal.map(\.outcome) == [support, .supportedCorrect])
        #expect(saved.totalScore == 10)
        let record = try #require(store.allRecords().first)
        #expect(record.correctCount == 0)
        #expect(record.supportedCorrectCount == 1)
        #expect(record.consecutiveIndependentCorrect == 0)
        let fresh = ItemAttempt(activityID: rawCorrect.activityID, conceptID: rawCorrect.conceptID, entityID: rawCorrect.entityID,
            propertyID: rawCorrect.propertyID, stageID: rawCorrect.stageID, outcome: .independentCorrect)
        store.recordAttempts([fresh], sessionID: "fresh-session")
        #expect(record.correctCount == 1)
        #expect(record.supportedCorrectCount == 1)
        #expect(record.consecutiveIndependentCorrect == 1)
    }

    @Test(arguments: [false, true])
    func mixedChildResultCannotBeArchivedOrScoredForActiveChild(_ explicitlyCurrentProfile: Bool) throws {
        let (context, profileID) = try makeGameplayProgressContext()
        let store = GameplayProgressStore(modelContext: context, activeProfileIdProvider: { profileID })
        let current = ItemAttempt(activityID: "shapes", conceptID: "sides", entityID: "triangle", stageID: "quiz", outcome: .independentCorrect, profileID: profileID)
        let foreign = ItemAttempt(activityID: "shapes", conceptID: "sides", entityID: "square", stageID: "quiz", outcome: .independentCorrect, profileID: "another-child")
        let result = ActivityResult(activityID: "shapes", title: "Shapes", startedAt: .now, attempts: [current, foreign],
            completedStageIDs: ["quiz"], profileID: explicitlyCurrentProfile ? profileID : nil)
        let saved = store.saveActivityResult(result)
        #expect(saved == nil)
        #expect(store.allSessions().isEmpty)
        #expect(store.allRecords().isEmpty)
    }

    @Test
    func catalogActivationResetsBothChildrenWithoutChangingStandaloneEvidenceOrHistory() throws {
        let (context, _) = try makeGameplayProgressContext()
        var profileID = "first-child"
        let store = GameplayProgressStore(modelContext: context, activeProfileIdProvider: { profileID })
        let catalogIDs = [GameplayThreadID.fruits.rawValue, LearningQuestID.shapes.activityID, LabActivityID.memoryMatch.rawValue]
        let standaloneIDs = ["vertical-slice-1", LabActivityID.roomQuest.rawValue, LabActivityID.sumSprint.rawValue, "lane-review-numbers"]
        for child in ["first-child", "second-child"] {
            profileID = child
            for activityID in catalogIDs + standaloneIDs {
                let version = catalogIDs.contains(activityID) ? 2 : 1
                for sessionID in ["one", "one", "two"] {
                    store.recordAttempts([ItemAttempt(activityID: activityID, conceptID: "test", entityID: "item", stageID: "quiz",
                        outcome: .independentCorrect, profileID: child, contentVersion: version)], sessionID: sessionID)
                }
                store.saveActivityResult(ActivityResult(id: activityID, activityID: activityID, title: activityID, startedAt: .now,
                    attempts: [], completedStageIDs: ["quiz"], profileID: child, contentVersion: version))
            }
        }
        let before = try context.fetch(FetchDescriptor<StoredGameplayProgressRecord>())
        let journals = Dictionary(uniqueKeysWithValues: before.map { ($0.uniqueKey, $0.itemAttemptsData) })
        #expect(before.allSatisfy { $0.confidenceBand == .steady })
        store.invalidateCatalogConfidence(contentVersion: 3)
        let after = try context.fetch(FetchDescriptor<StoredGameplayProgressRecord>())
        #expect(after.count == 2 * (catalogIDs.count + standaloneIDs.count))
        for record in after {
            #expect(record.itemAttemptsData == journals[record.uniqueKey]!)
            #expect(record.correctCount == 3)
            if catalogIDs.contains(record.threadId) {
                #expect(record.evidenceContentVersion == 3)
                #expect(record.confidenceBand == .new)
                #expect(record.consecutiveIndependentCorrect == 0)
                #expect(record.nextDueAt == .distantPast)
            } else {
                #expect(record.evidenceContentVersion == 1)
                #expect(record.confidenceBand == .steady)
                #expect(record.consecutiveIndependentCorrect == 3)
            }
        }
        #expect(try context.fetch(FetchDescriptor<StoredGameplayThreadSession>()).count == 2 * (catalogIDs.count + standaloneIDs.count))
    }

    private func makeGameplayProgressContext() throws -> (ModelContext, String) {
        let schema = Schema([
            StoredGameplayProgressRecord.self,
            StoredGameplayThreadSession.self,
            StoredGameSession.self
        ])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: config)
        return (ModelContext(container), "kid-progress")
    }

    private func sampleThread() -> GameplayThreadDefinition {
        GameplayThreadDefinition(
            id: "countries",
            title: "Countries",
            category: GameplayCategory(id: "geography", title: "Geography", subtitle: "Places"),
            propertyTypes: [
                GameplayPropertyType(id: "capital", displayName: "Capital", prompt: "Which capital?"),
                GameplayPropertyType(id: "currency", displayName: "Currency", prompt: "Which money?")
            ],
            entities: [
                GameplayEntity(id: "country-india", name: "India", properties: [
                    GameplayProperty(id: "country-india-capital", typeID: "capital", value: "New Delhi"),
                    GameplayProperty(id: "country-india-currency", typeID: "currency", value: "Indian rupee")
                ]),
                GameplayEntity(id: "country-japan", name: "Japan", properties: [
                    GameplayProperty(id: "country-japan-capital", typeID: "capital", value: "Tokyo"),
                    GameplayProperty(id: "country-japan-currency", typeID: "currency", value: "yen")
                ]),
                GameplayEntity(id: "country-france", name: "France", properties: [
                    GameplayProperty(id: "country-france-capital", typeID: "capital", value: "Paris"),
                    GameplayProperty(id: "country-france-currency", typeID: "currency", value: "euro")
                ])
            ]
        )
    }
}
