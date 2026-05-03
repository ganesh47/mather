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


extension LearningLoopTests {
    func testSoundVolumeIntroUsesStagedSafePagesBeforeActivity() {
        let pages = SoundVolumeContent.introPages

        XCTAssertEqual(pages.map(\.id), ["welcome", "safety", "decibels", "zones", "clues"])
        XCTAssertEqual(pages.last?.primaryActionTitle, "Start Sound Lab")
        XCTAssertTrue(pages[1].subtitle.contains("no microphone permission"))
        XCTAssertTrue(pages[1].subtitle.contains("no loud-noise challenge"))
        XCTAssertTrue(pages[2].subtitle.contains("decibel"))
        XCTAssertTrue(pages[3].subtitle.contains("not a live sound meter"))
    }

    func testSoundVolumeIntroPageLookupClampsOutOfRangeIndexes() {
        let pages = SoundVolumeContent.introPages

        XCTAssertEqual(SoundVolumeContent.clampedIntroPageIndex(-3), 0)
        XCTAssertEqual(SoundVolumeContent.clampedIntroPageIndex(0), 0)
        XCTAssertEqual(SoundVolumeContent.clampedIntroPageIndex(pages.count), pages.count - 1)
        XCTAssertEqual(SoundVolumeContent.clampedIntroPageIndex(pages.count + 5), pages.count - 1)
        XCTAssertEqual(SoundVolumeContent.introPage(for: -1), pages[0])
        XCTAssertEqual(SoundVolumeContent.introPage(for: pages.count + 2), pages[pages.count - 1])
    }

    func testSoundVolumeContentCoversSafeHearingConcepts() {
        let titles = Set(SoundVolumeContent.cards.map(\.title))

        XCTAssertEqual(SoundVolumeContent.cards.count, 9)
        XCTAssertTrue(titles.isSuperset(of: [
            "Decibel (dB)",
            "Quiet",
            "Conversation",
            "Traffic",
            "Siren",
            "Headphones",
            "Pleasant Sound",
            "Noisy Sound",
            "Protect Ears",
        ]))
        XCTAssertTrue(SoundVolumeContent.safetyNote.contains("no screaming"))
        XCTAssertTrue(SoundVolumeContent.safetyNote.contains("microphone meter comes later"))
    }

    func testSoundVolumeQuizScoringUsesCorrectSafeAnswers() {
        let questions = SoundVolumeContent.quizQuestions
        let answers = Dictionary(uniqueKeysWithValues: questions.map { ($0.id, $0.correctChoice) })

        XCTAssertEqual(questions.count, 4)
        XCTAssertEqual(LearningLoopScoring.scoreQuiz(questions: questions, answersByQuestionId: answers), questions.count)
        XCTAssertTrue(questions.contains { $0.correctChoice == "Keep volume low and take breaks" })
        XCTAssertFalse(questions.flatMap(\.choices).contains { $0.localizedCaseInsensitiveContains("scream") })
    }

    func testSoundVolumeMatchPairsUsePictureNameVisualKeys() {
        let pairs = SoundVolumeContent.matchPairs
        let pairIDs = Set(pairs.map(\.id))

        XCTAssertEqual(pairs.count, 6)
        XCTAssertTrue(pairIDs.isSuperset(of: ["whisper-quiet", "talk-normal", "traffic-loud", "siren-too-loud", "birds-pleasant", "headphones-safe"]))
        XCTAssertTrue(pairs.allSatisfy { $0.leftVisualKey?.isEmpty == false })
        XCTAssertTrue(pairs.allSatisfy { $0.rightVisualKey?.isEmpty == false })
        XCTAssertTrue(LearningLoopScoring.isMatch(left: "Siren", right: "Protect ears", pairs: pairs))
        XCTAssertFalse(LearningLoopScoring.isMatch(left: "Siren", right: "Quiet", pairs: pairs))
    }

    func testSoundVolumeMatchRowsShuffleDeterministicallyBySeed() {
        let pairs = SoundVolumeContent.matchPairs
        let first = LearningLoopScoring.shuffledMatchRowOrder(pairs: pairs, seed: 883)
        let repeatOrder = LearningLoopScoring.shuffledMatchRowOrder(pairs: pairs, seed: 883)
        let different = LearningLoopScoring.shuffledMatchRowOrder(pairs: pairs, seed: 884)
        let ordered = LearningLoopScoring.orderedMatchRowOrder(pairs: pairs)

        XCTAssertEqual(first, repeatOrder)
        XCTAssertNotEqual(first, ordered)
        XCTAssertNotEqual(first, different)
        XCTAssertEqual(Set(first.leftPairIds), Set(pairs.map(\.id)))
        XCTAssertEqual(Set(first.rightPairIds), Set(pairs.map(\.id)))
    }

    func testSoundVolumeEstimatedZonesAreExplicitlyEstimatedAndConservative() {
        XCTAssertEqual(SoundVolumeContent.zone(forEstimatedDecibels: 35), .quiet)
        XCTAssertEqual(SoundVolumeContent.zone(forEstimatedDecibels: 60), .normal)
        XCTAssertEqual(SoundVolumeContent.zone(forEstimatedDecibels: 80), .loud)
        XCTAssertEqual(SoundVolumeContent.zone(forEstimatedDecibels: 95), .tooLoud)
        XCTAssertTrue(SoundLoudnessZone.tooLoud.safetyCopy.contains("protect your ears"))
        XCTAssertTrue(SoundLoudnessZone.normal.estimatedRangeLabel.contains("about"))
    }
}

extension LearningLoopTests {
    func testShapeGeometryContentCoversExpectedCardsAndLevels() {
        let titles = Set(ShapeGeometryContent.cards.map(\.title))
        XCTAssertEqual(ShapeGeometryContent.cards.count, 8)
        XCTAssertTrue(titles.isSuperset(of: ["Circle", "Triangle", "Square", "Rectangle", "Oval", "Star", "Heart", "Diamond"]))
        XCTAssertEqual(ShapeGeometryContent.levels.count, 2)
        XCTAssertTrue(ShapeGeometryContent.levels.allSatisfy { !$0.cards.isEmpty && !$0.matchPairs.isEmpty })
    }

    func testShapeGeometryQuizScoringUsesCorrectAnswers() {
        let questions = ShapeGeometryContent.quizQuestions
        let answers = Dictionary(uniqueKeysWithValues: questions.map { ($0.id, $0.correctChoice) })
        XCTAssertEqual(LearningLoopScoring.scoreQuiz(questions: questions, answersByQuestionId: answers), questions.count)
    }

    func testShapeGeometryPairMatchingRequiresDefinedShapeNamePair() {
        let pairs = ShapeGeometryContent.matchPairs
        XCTAssertTrue(LearningLoopScoring.isMatch(left: "Triangle picture", right: "Triangle", pairs: pairs))
        XCTAssertTrue(LearningLoopScoring.isMatch(left: "Circle picture", right: "Circle", pairs: pairs))
        XCTAssertFalse(LearningLoopScoring.isMatch(left: "Triangle picture", right: "Circle", pairs: pairs))
        XCTAssertTrue(pairs.allSatisfy { $0.leftVisualKey?.isEmpty == false && $0.rightVisualKey?.isEmpty == false })
    }

    func testShapeHuntLevelMatchesObjectsToShapeNames() {
        let pairs = ShapeGeometryContent.huntMatchPairs
        XCTAssertTrue(LearningLoopScoring.isMatch(left: "Clock", right: "Circle", pairs: pairs))
        XCTAssertTrue(LearningLoopScoring.isMatch(left: "Kite", right: "Diamond", pairs: pairs))
    }
}
