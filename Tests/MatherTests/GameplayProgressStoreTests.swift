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
