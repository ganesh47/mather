import Foundation
import Testing
@testable import Mather

struct GameplayScoringTests {
    @Test
    func stageScoreRewardsFirstTryAndTracksHintsStreakAndTime() {
        let sessionID = UUID()
        var score = GameplayStageScore(
            sessionID: sessionID,
            stageKind: .multipleChoice,
            startedAt: Date(timeIntervalSince1970: 10)
        )

        score.recordAnswer(correct: true, firstTry: true)
        score.recordAnswer(correct: true, firstTry: true)
        score.recordAnswer(correct: false, firstTry: false)
        score.recordAnswer(correct: true, firstTry: false, usedHint: true)
        score.finish(at: Date(timeIntervalSince1970: 70))

        #expect(score.correctCount == 3)
        #expect(score.incorrectCount == 1)
        #expect(score.attempts == 4)
        #expect(score.hintsUsed == 1)
        #expect(score.bestStreak == 2)
        #expect(score.accuracy == 0.75)
        #expect(score.elapsedSeconds == 60)
        #expect(score.points == 28)
    }

    @Test
    func sessionScoreAggregatesStageTotalsAndStars() {
        let sessionID = UUID()
        let startedAt = Date(timeIntervalSince1970: 100)
        var flashcards = GameplayStageScore(sessionID: sessionID, stageKind: .flashcards, startedAt: startedAt)
        flashcards.recordAnswer(correct: true, firstTry: true)
        flashcards.recordAnswer(correct: true, firstTry: true)
        flashcards.finish(at: startedAt.addingTimeInterval(30))

        var quiz = GameplayStageScore(sessionID: sessionID, stageKind: .multipleChoice, startedAt: startedAt.addingTimeInterval(30))
        quiz.recordAnswer(correct: true, firstTry: true)
        quiz.recordAnswer(correct: false, firstTry: false)
        quiz.finish(at: startedAt.addingTimeInterval(75))

        let session = GameplaySessionScore(
            id: sessionID,
            threadID: "countries",
            startedAt: startedAt,
            stageScores: [flashcards, quiz]
        )

        #expect(session.totalCorrect == 3)
        #expect(session.totalIncorrect == 1)
        #expect(session.totalAttempts == 4)
        #expect(session.totalElapsedSeconds == 75)
        #expect(session.accuracy == 0.75)
        #expect(session.starRating == 2)
        #expect(session.totalPoints == flashcards.points + quiz.points)
    }
}
