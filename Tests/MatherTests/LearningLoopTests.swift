import XCTest
@testable import Mather

final class LearningLoopTests: XCTestCase {
    func testWaterCycleContentCoversExpectedCards() {
        let titles = Set(WaterCycleContent.cards.map(\.title))
        XCTAssertEqual(WaterCycleContent.cards.count, 7)
        XCTAssertTrue(titles.isSuperset(of: ["Evaporation", "Condensation", "Cloud", "Rain", "Pond", "Sun", "Water Vapour"]))
    }

    func testQuizScoringUsesCorrectAnswers() {
        let questions = WaterCycleContent.quizQuestions
        let answers = Dictionary(uniqueKeysWithValues: questions.map { ($0.id, $0.correctChoice) })
        XCTAssertEqual(LearningLoopScoring.scoreQuiz(questions: questions, answersByQuestionId: answers), questions.count)
    }

    func testQuizScoringRejectsWrongAnswers() {
        let questions = WaterCycleContent.quizQuestions
        XCTAssertEqual(
            LearningLoopScoring.scoreQuiz(questions: questions, answersByQuestionId: ["sun-warms-water": "Freezes it"]),
            0
        )
    }

    func testPairMatchingRequiresDefinedCauseEffectPair() {
        let pairs = WaterCycleContent.matchPairs
        XCTAssertTrue(LearningLoopScoring.isMatch(left: "Sun", right: "Evaporation", pairs: pairs))
        XCTAssertTrue(LearningLoopScoring.isMatch(left: "Cloud", right: "Rain", pairs: pairs))
        XCTAssertFalse(LearningLoopScoring.isMatch(left: "Sun", right: "Rain", pairs: pairs))
    }

    func testSummaryComputesStarsFromQuizAndMatches() {
        let questions = WaterCycleContent.quizQuestions
        let answers = Dictionary(uniqueKeysWithValues: questions.map { ($0.id, $0.correctChoice) })
        let matchedIds = Set(WaterCycleContent.matchPairs.map(\.id))
        let summary = LearningLoopScoring.summary(
            questions: questions,
            answersByQuestionId: answers,
            matchedPairIds: matchedIds,
            pairs: WaterCycleContent.matchPairs
        )
        XCTAssertEqual(summary.quizCorrect, 3)
        XCTAssertEqual(summary.matchedPairs, 5)
        XCTAssertEqual(summary.starCount, 3)
    }
}

extension LearningLoopTests {
    func testMatchAttemptLocksCorrectPairImmediately() {
        let pairs = WaterCycleContent.matchPairs
        let first = pairs[0]

        let result = LearningLoopScoring.matchAttempt(
            selectedPairId: first.id,
            targetPairId: first.id,
            pairs: pairs,
            matchedPairIds: []
        )

        XCTAssertEqual(result, .locked(pairId: first.id, feedback: first.feedback))
    }

    func testMatchAttemptRejectsWrongPairWithoutProgress() {
        let pairs = WaterCycleContent.matchPairs
        let result = LearningLoopScoring.matchAttempt(
            selectedPairId: pairs[0].id,
            targetPairId: pairs[1].id,
            pairs: pairs,
            matchedPairIds: []
        )

        XCTAssertEqual(result, .mismatch(feedback: "Not that pair yet — try another match."))
    }

    func testMatchAttemptDoesNotRelockMatchedCards() {
        let pairs = WaterCycleContent.matchPairs
        let first = pairs[0]

        let result = LearningLoopScoring.matchAttempt(
            selectedPairId: first.id,
            targetPairId: first.id,
            pairs: pairs,
            matchedPairIds: [first.id]
        )

        XCTAssertEqual(result, .alreadyMatched)
    }

    func testWaterCycleMatchPairsCarryVisualKeysForCompactBondStyleBoard() {
        XCTAssertTrue(WaterCycleContent.matchPairs.allSatisfy { $0.leftVisualKey?.isEmpty == false })
        XCTAssertTrue(WaterCycleContent.matchPairs.allSatisfy { $0.rightVisualKey?.isEmpty == false })
    }
}
