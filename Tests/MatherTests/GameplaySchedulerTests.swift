import Foundation
import Testing
@testable import Mather

struct GameplaySchedulerTests {
    @Test
    func defaultThreadStagesMatchIssue912Order() {
        #expect(GameplayThreadDefinition.defaultStages.map(\.kind) == [.flashcards, .easyMemory, .flipMemory, .bondBlast, .multipleChoice])
    }

    @Test
    func schedulerPrioritizesMissedDueItemsBeforeMasteredItems() {
        let thread = sampleThread()
        let stage = GameplayStageDefinition(
            id: "bond-blast",
            kind: .bondBlast,
            title: "Bond Blast",
            prompt: "Match facts",
            propertyTypeIDs: ["capital"],
            maximumItemCount: 2
        )
        let now = Date(timeIntervalSince1970: 1_000)
        let indiaKey = GameplayExposureKey(entityID: "country-india", propertyID: "country-india-capital", stageID: stage.id)
        let japanKey = GameplayExposureKey(entityID: "country-japan", propertyID: "country-japan-capital", stageID: stage.id)
        let records: [GameplayExposureKey: GameplayExposureRecord] = [
            indiaKey: GameplayExposureRecord(key: indiaKey, correctCount: 0, mistakeCount: 2, dueAt: now.addingTimeInterval(-10), confidenceBand: .reviewNeeded),
            japanKey: GameplayExposureRecord(key: japanKey, correctCount: 5, mistakeCount: 0, dueAt: now.addingTimeInterval(-10), confidenceBand: .steady)
        ]

        let round = SpacedRepetitionScheduler.makeRound(thread: thread, stage: stage, records: records, now: now, seed: 7)

        #expect(round.items.first?.entityID == "country-india")
        #expect(round.items.map(\.propertyTypeID).allSatisfy { $0 == "capital" })
    }

    @Test
    func schedulerSelectionIsDeterministicForSeed() {
        let thread = sampleThread()
        let stage = GameplayStageDefinition(id: "easy", kind: .easyMemory, title: "Easy", prompt: "Match", maximumItemCount: 3)

        let first = SpacedRepetitionScheduler.makeRound(thread: thread, stage: stage, seed: 42)
        let second = SpacedRepetitionScheduler.makeRound(thread: thread, stage: stage, seed: 42)
        let different = SpacedRepetitionScheduler.makeRound(thread: thread, stage: stage, seed: 43)

        #expect(first.items.map(\.id) == second.items.map(\.id))
        #expect(first.items.map(\.id) != different.items.map(\.id))
    }



    @Test
    func memoryRoundsPreferOneCardPerEntityBeforeRepeats() {
        let thread = sampleThread()
        let stage = GameplayStageDefinition(
            id: "flip-memory",
            kind: .flipMemory,
            title: "Flip",
            prompt: "Match",
            propertyTypeIDs: ["capital", "currency"],
            maximumItemCount: 3
        )

        let round = SpacedRepetitionScheduler.makeRound(thread: thread, stage: stage, seed: 23)

        #expect(round.items.count == 3)
        #expect(Set(round.items.map(\.entityID)).count == round.items.count)
    }

    @Test
    func schedulerPlacesSupportedCorrectBetweenIncorrectAndIndependentCorrect() {
        let thread = sampleThread()
        let stage = GameplayStageDefinition(
            id: "multiple-choice",
            kind: .multipleChoice,
            title: "Quiz",
            prompt: "Choose",
            propertyTypeIDs: ["capital"],
            maximumItemCount: 3
        )
        let now = Date(timeIntervalSince1970: 4_000)
        let indiaKey = GameplayExposureKey(entityID: "country-india", propertyID: "country-india-capital", stageID: stage.id)
        let japanKey = GameplayExposureKey(entityID: "country-japan", propertyID: "country-japan-capital", stageID: stage.id)
        let franceKey = GameplayExposureKey(entityID: "country-france", propertyID: "country-france-capital", stageID: stage.id)
        let records: [GameplayExposureKey: GameplayExposureRecord] = [
            indiaKey: GameplayExposureRecord(key: indiaKey, correctCount: 0, supportedCorrectCount: 0, mistakeCount: 1, lastOutcome: .incorrect, dueAt: now, confidenceBand: .reviewNeeded),
            japanKey: GameplayExposureRecord(key: japanKey, correctCount: 0, supportedCorrectCount: 1, mistakeCount: 0, lastOutcome: .supportedCorrect, dueAt: now, confidenceBand: .learning),
            franceKey: GameplayExposureRecord(key: franceKey, correctCount: 3, supportedCorrectCount: 0, mistakeCount: 0, lastOutcome: .correct, dueAt: now, confidenceBand: .steady)
        ]

        let round = SpacedRepetitionScheduler.makeRound(thread: thread, stage: stage, records: records, now: now, seed: 11)

        #expect(round.items.map(\.entityID) == ["country-india", "country-japan", "country-france"])
    }

    @Test
    func applyingSupportedCorrectUsesMiddleReviewDelay() {
        let key = GameplayExposureKey(entityID: "fruit-mango", propertyID: "fruit-mango-taste", stageID: "easy-memory")
        let now = Date(timeIntervalSince1970: 5_000)

        let records = SpacedRepetitionScheduler.applying(
            updates: [SpacedRepetitionUpdate(key: key, outcome: .supportedCorrect, occurredAt: now)],
            to: [:]
        )

        #expect(records[key]?.confidenceBand == .learning)
        #expect(records[key]?.supportedCorrectCount == 1)
        #expect(records[key]?.dueAt == now.addingTimeInterval(60 * 60 * 12))
    }

    @Test
    func applyingUpdatesMovesMistakesToReviewNeeded() {
        let key = GameplayExposureKey(entityID: "fruit-apple", propertyID: "fruit-apple-taste", stageID: "multiple-choice")
        let now = Date(timeIntervalSince1970: 2_000)

        let records = SpacedRepetitionScheduler.applying(
            updates: [SpacedRepetitionUpdate(key: key, wasCorrect: false, occurredAt: now)],
            to: [:]
        )

        #expect(records[key]?.confidenceBand == .reviewNeeded)
        #expect(records[key]?.mistakeCount == 1)
        #expect((records[key]?.dueAt ?? .distantFuture) < now.addingTimeInterval(60 * 60 * 2))
    }

    @Test
    func scoreSummaryAggregatesAccuracyHintsAndStars() {
        let now = Date(timeIntervalSince1970: 3_000)
        let results = [
            GameplayStageResult(id: "one", stageID: "easy", correctCount: 5, mistakeCount: 0, hintsUsed: 1, durationSeconds: 20, completedAt: now),
            GameplayStageResult(id: "two", stageID: "quiz", correctCount: 4, mistakeCount: 1, hintsUsed: 0, durationSeconds: 25, completedAt: now)
        ]

        let summary = GameplayScoreSummary.summarize(results)

        #expect(summary.correctCount == 9)
        #expect(summary.mistakeCount == 1)
        #expect(summary.durationSeconds == 45)
        #expect(summary.stars == 3)
        #expect(summary.scorePoints == 84)
        #expect(summary.averageSecondsPerAttempt == 4.5)
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
