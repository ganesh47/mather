import XCTest
@testable import Mather

final class ShapeGeometryContentTests: XCTestCase {
    func testShapeDeckCoversBasicAndExpandedShapes() {
        let titles = Set(ShapeGeometryContent.cards.map(\.title))

        XCTAssertEqual(ShapeGeometryContent.cards.count, 8)
        XCTAssertTrue(titles.isSuperset(of: [
            "Circle", "Triangle", "Square", "Rectangle",
            "Oval", "Diamond", "Star", "Heart",
        ]))
        XCTAssertEqual(Set(ShapeGeometryContent.cards.map(\.id)).count, ShapeGeometryContent.cards.count)
    }

    func testShapeLevelsGroupDeterministicFourCardRounds() throws {
        XCTAssertEqual(ShapeGeometryContent.levels.map(\.id), ["basic-shapes", "expanded-shapes"])

        for level in ShapeGeometryContent.levels {
            XCTAssertEqual(level.cardIDs.count, 4)
            XCTAssertEqual(level.cards(from: ShapeGeometryContent.cards).count, 4)
            XCTAssertEqual(level.quizQuestions(from: ShapeGeometryContent.quizQuestions).count, 4)
            XCTAssertEqual(level.matchPairs(from: ShapeGeometryContent.matchPairs).count, 4)
        }

        let basic = try XCTUnwrap(ShapeGeometryContent.level(withID: "basic-shapes"))
        XCTAssertEqual(basic.cardIDs, ["circle", "triangle", "square", "rectangle"])
    }

    func testShapeQuizQuestionsAcceptOnlyCorrectChoices() {
        for question in ShapeGeometryContent.quizQuestions {
            XCTAssertTrue(question.isCorrect(question.correctChoice), question.id)
            for wrongChoice in question.choices where wrongChoice != question.correctChoice {
                XCTAssertFalse(question.isCorrect(wrongChoice), question.id)
            }
        }
    }

    func testShapeMatchPairsCarryPictureAndNamePresentation() {
        XCTAssertEqual(ShapeGeometryContent.matchPairs.count, ShapeGeometryContent.cards.count)
        XCTAssertTrue(ShapeGeometryContent.matchPairs.allSatisfy { $0.id.hasPrefix("shape-match-") })
        XCTAssertTrue(ShapeGeometryContent.matchPairs.allSatisfy { $0.left == $0.right })
        XCTAssertTrue(ShapeGeometryContent.matchPairs.allSatisfy { $0.leftVisualKey?.isEmpty == false })

        let pairs = ShapeGeometryContent.matchPairs
        XCTAssertTrue(LearningLoopScoring.isMatch(left: "Rectangle", right: "Rectangle", pairs: pairs))
        XCTAssertFalse(LearningLoopScoring.isMatch(left: "Rectangle", right: "Triangle", pairs: pairs))
    }

    func testShapeSummaryScoresCompletionForOneLevel() throws {
        let level = try XCTUnwrap(ShapeGeometryContent.level(withID: "expanded-shapes"))
        let questions = level.quizQuestions(from: ShapeGeometryContent.quizQuestions)
        let pairs = level.matchPairs(from: ShapeGeometryContent.matchPairs)
        let answers = Dictionary(uniqueKeysWithValues: questions.map { ($0.id, $0.correctChoice) })
        let summary = LearningLoopScoring.summary(
            questions: questions,
            answersByQuestionId: answers,
            matchedPairIds: Set(pairs.map(\.id)),
            pairs: pairs
        )

        XCTAssertEqual(summary.quizCorrect, 4)
        XCTAssertEqual(summary.matchedPairs, 4)
        XCTAssertEqual(summary.starCount, 3)
    }
}
