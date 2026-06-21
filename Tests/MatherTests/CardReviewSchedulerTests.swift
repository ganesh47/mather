import Foundation
import Testing
@testable import Mather

struct CardReviewSchedulerTests {
    private let now = Date(timeIntervalSinceReferenceDate: 1_000_000)

    @Test
    func independentCorrectExpandsReviewInterval() {
        let scheduler = CardReviewScheduler(now: now)
        let first = scheduler.progress(after: .correct, from: CardProgress())
        let second = scheduler.progress(after: .correct, from: first)

        #expect(first.timesSeen == 1)
        #expect(first.correctCount == 1)
        #expect(first.currentCorrectStreak == 1)
        #expect(scheduler.nextReviewDate(for: first) == now.addingTimeInterval(24 * 60 * 60))

        #expect(second.timesSeen == 2)
        #expect(second.correctCount == 2)
        #expect(second.currentCorrectStreak == 2)
        #expect(scheduler.nextReviewDate(for: second) == now.addingTimeInterval(3 * 24 * 60 * 60))
    }

    @Test
    func supportedCorrectRecordsSuccessButKeepsCardCloser() {
        let scheduler = CardReviewScheduler(now: now)
        let supported = scheduler.progress(after: .supportedCorrect, from: CardProgress())

        #expect(supported.timesSeen == 1)
        #expect(supported.correctCount == 1)
        #expect(supported.incorrectCount == 0)
        #expect(supported.currentCorrectStreak == 0)
        #expect(supported.lastReviewResult == .supportedCorrect)
        #expect(scheduler.nextReviewDate(for: supported) == now.addingTimeInterval(30 * 60))
    }

    @Test
    func incorrectReturnsSoonAndResetsStreak() {
        let scheduler = CardReviewScheduler(now: now)
        let prior = CardProgress(timesSeen: 4, correctCount: 4, incorrectCount: 0, currentCorrectStreak: 4)
        let missed = scheduler.progress(after: .incorrect, from: prior)

        #expect(missed.timesSeen == 5)
        #expect(missed.correctCount == 4)
        #expect(missed.incorrectCount == 1)
        #expect(missed.currentCorrectStreak == 0)
        #expect(missed.lastReviewResult == .incorrect)
        #expect(scheduler.nextReviewDate(for: missed) == now.addingTimeInterval(5 * 60))
    }

    @Test
    func injectedClockMakesDueDecisionsDeterministic() {
        let reviewedAt = now.addingTimeInterval(-24 * 60 * 60)
        let dueCard = makeCard(
            id: "due",
            laneID: .numbers,
            conceptID: "number-bond",
            progress: CardProgress(
                timesSeen: 1,
                correctCount: 1,
                currentCorrectStreak: 1,
                lastReviewedAt: reviewedAt,
                lastReviewResult: .correct
            )
        )
        let futureCard = makeCard(
            id: "future",
            laneID: .geometry,
            conceptID: "shape",
            progress: CardProgress(
                timesSeen: 1,
                correctCount: 1,
                currentCorrectStreak: 1,
                lastReviewedAt: now,
                lastReviewResult: .correct
            )
        )
        let scheduler = CardReviewScheduler(clock: { now })

        #expect(scheduler.isDue(dueCard))
        #expect(!scheduler.isDue(futureCard))
        #expect(scheduler.reviewQueue(from: [futureCard, dueCard], limit: 10).map(\.id) == ["due"])
    }

    @Test
    func defaultInitializerUsesLiveClockForDueDecisions() {
        let reviewedAt = Date().addingTimeInterval(-24 * 60 * 60 - 1)
        let dueCard = makeCard(
            id: "live-due",
            laneID: .numbers,
            conceptID: "number-bond",
            progress: CardProgress(
                timesSeen: 1,
                correctCount: 1,
                currentCorrectStreak: 1,
                lastReviewedAt: reviewedAt,
                lastReviewResult: .correct
            )
        )
        let scheduler = CardReviewScheduler()

        #expect(scheduler.isDue(dueCard))
    }

    @Test
    func reviewQueueInterleavesByLaneAndConceptWithinDueWindow() {
        let scheduler = CardReviewScheduler(now: now)
        let cards = [
            makeCard(id: "numbers-a-1", laneID: .numbers, conceptID: "a"),
            makeCard(id: "numbers-a-2", laneID: .numbers, conceptID: "a"),
            makeCard(id: "geometry-a-1", laneID: .geometry, conceptID: "a"),
            makeCard(id: "physics-b-1", laneID: .physics, conceptID: "b"),
        ]

        let queue = scheduler.reviewQueue(from: cards, limit: 4)

        #expect(queue.map(\.id) == [
            "geometry-a-1",
            "physics-b-1",
            "numbers-a-1",
            "numbers-a-2",
        ])
    }

    @Test
    func reviewQueueHandlesLimitsAndEmptyInputs() {
        let scheduler = CardReviewScheduler(now: now)
        let card = makeCard(id: "card", laneID: .numbers, conceptID: "number-bond")

        #expect(scheduler.reviewQueue(from: [], limit: 3).isEmpty)
        #expect(scheduler.reviewQueue(from: [card], limit: 0).isEmpty)
        #expect(scheduler.reviewQueue(from: [card], limit: 10).map(\.id) == ["card"])
    }

    private func makeCard(
        id: String,
        laneID: CapabilityLaneID,
        conceptID: ConceptId,
        progress: CardProgress = CardProgress()
    ) -> LearningCard {
        let answer = CardAnswer(id: "answer-\(id)", speechText: "answer")
        return LearningCard(
            id: id,
            laneID: laneID,
            conceptID: conceptID,
            stage: .review,
            ageBand: .ages4To12,
            prompt: CardPrompt(id: "prompt-\(id)", speechText: "prompt"),
            answer: answer,
            choices: [CardChoice(answer: answer, isCorrect: true)],
            progress: progress
        )
    }
}
