import Foundation
import Testing
@testable import Mather

struct SpacedRepetitionSchedulerTests {
    private let now = Date(timeIntervalSince1970: 1_000)

    @Test
    func schedulerPrioritizesDueWeakItemsBeforeNewSteadyAndMasteredItems() {
        let weak = GameplayRepetitionKey(entityID: "weak")
        let new = GameplayRepetitionKey(entityID: "new")
        let steady = GameplayRepetitionKey(entityID: "steady")
        let mastered = GameplayRepetitionKey(entityID: "mastered")
        let candidates = [mastered, steady, new, weak]
        let states: [GameplayRepetitionKey: GameplayRepetitionState] = [
            weak: GameplayRepetitionState(
                key: weak,
                exposureCount: 3,
                correctCount: 1,
                incorrectCount: 2,
                nextDueAt: now.addingTimeInterval(-60),
                confidenceBand: .reviewNeeded
            ),
            steady: GameplayRepetitionState(
                key: steady,
                exposureCount: 3,
                correctCount: 3,
                incorrectCount: 0,
                nextDueAt: now.addingTimeInterval(-60),
                confidenceBand: .steady
            ),
            mastered: GameplayRepetitionState(
                key: mastered,
                exposureCount: 6,
                correctCount: 6,
                incorrectCount: 0,
                nextDueAt: now.addingTimeInterval(86_400),
                confidenceBand: .mastered
            )
        ]

        let selected = SpacedRepetitionScheduler().selectKeys(
            from: candidates,
            states: states,
            limit: 4,
            now: now
        )

        #expect(selected == [weak, steady, new, mastered])
    }

    @Test
    func updatingStateMovesIncorrectOrHintedWorkIntoReviewNeeded() {
        let key = GameplayRepetitionKey(entityID: "india", propertyTypeID: "capital", propertyValueID: "india-capital")
        let sessionID = UUID()
        let event = GameplayExposureEvent(
            key: key,
            stageKind: .easyMemory,
            sessionID: sessionID,
            seenAt: now,
            wasCorrect: true,
            attempts: 2,
            usedHint: true
        )

        let state = SpacedRepetitionScheduler().updatedState(
            from: GameplayRepetitionState(key: key),
            with: event,
            at: now
        )

        #expect(state.exposureCount == 1)
        #expect(state.correctCount == 1)
        #expect(state.confidenceBand == .reviewNeeded)
        #expect(state.nextDueAt > now)
        #expect(state.lastStageKind == .easyMemory)
        #expect(state.lastSessionID == sessionID)
    }

    @Test
    func buildRoundReturnsDeterministicEntityAndPropertySelection() {
        let thread = GameplayThreadDefinition.sampleForSchedulerTests()
        let scheduler = SpacedRepetitionScheduler()
        let allKeys = scheduler.repetitionKeys(for: thread)
        let weakKey = GameplayRepetitionKey(entityID: "india", propertyTypeID: "capital", propertyValueID: "india-capital")
        let states = Dictionary(uniqueKeysWithValues: allKeys.map { key in
            (
                key,
                GameplayRepetitionState(
                    key: key,
                    exposureCount: key == weakKey ? 3 : 5,
                    correctCount: key == weakKey ? 1 : 5,
                    incorrectCount: key == weakKey ? 2 : 0,
                    nextDueAt: key == weakKey ? now.addingTimeInterval(-60) : now.addingTimeInterval(86_400),
                    confidenceBand: key == weakKey ? .reviewNeeded : .mastered
                )
            )
        })

        let round = scheduler.buildRound(
            for: thread,
            stageKind: .bondBlast,
            states: states,
            itemLimit: 2,
            now: now,
            seed: 42
        )

        #expect(round.stageKind == .bondBlast)
        #expect(round.entityIDs.contains("india"))
        #expect(round.propertyTypeIDs.contains("capital"))
        #expect(round.seed == 42)
    }

    @Test
    func inMemoryStoreAppliesExposureEvents() {
        let key = GameplayRepetitionKey(entityID: "mango")
        let sessionID = UUID()
        var store = InMemoryGameplayRepetitionStore()
        store.apply([
            GameplayExposureEvent(
                key: key,
                stageKind: .flashcards,
                sessionID: sessionID,
                seenAt: now,
                wasCorrect: nil
            )
        ], at: now)

        let state = store.states(for: [key])[key]
        #expect(state?.exposureCount == 1)
        #expect(state?.lastStageKind == .flashcards)
    }
}

private extension GameplayThreadDefinition {
    static func sampleForSchedulerTests() -> GameplayThreadDefinition {
        let capital = GameplayPropertyType(id: "capital", title: "Capital", learningPriority: 1)
        let currency = GameplayPropertyType(id: "currency", title: "Currency", learningPriority: 2)
        return GameplayThreadDefinition(
            id: "countries",
            title: "Countries",
            category: .countries,
            entities: [
                GameplayEntity(
                    id: "india",
                    name: "India",
                    visual: .emoji("🇮🇳"),
                    explanation: "India is in Asia.",
                    properties: [
                        GameplayProperty(id: "india-capital", typeID: "capital", value: "New Delhi"),
                        GameplayProperty(id: "india-currency", typeID: "currency", value: "Rupee")
                    ]
                ),
                GameplayEntity(
                    id: "japan",
                    name: "Japan",
                    visual: .emoji("🇯🇵"),
                    explanation: "Japan is an island country.",
                    properties: [
                        GameplayProperty(id: "japan-capital", typeID: "capital", value: "Tokyo")
                    ]
                )
            ],
            propertyTypes: [capital, currency]
        )
    }
}
