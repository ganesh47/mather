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
