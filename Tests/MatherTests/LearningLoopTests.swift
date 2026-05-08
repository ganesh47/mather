import XCTest
@testable import Mather

final class LearningLoopTests: XCTestCase {

    // MARK: - Water cycle gameplay thread (System B — GameplayThreadDefinition)

    func testWaterCycleThreadCoversExpectedEntities() {
        let thread = GameplayThreadCatalog.waterCycle
        let names = Set(thread.entities.map(\.name))
        XCTAssertTrue(names.isSuperset(of: ["Evaporation", "Condensation", "Precipitation", "Collection"]))
        XCTAssertFalse(thread.entities.isEmpty)
        XCTAssertFalse(thread.stages.isEmpty)
    }

    func testWaterCycleThreadEntitiesCarryVisualKeys() {
        let thread = GameplayThreadCatalog.waterCycle
        XCTAssertTrue(thread.entities.allSatisfy { $0.visualKey?.isEmpty == false })
    }

    func testWaterCycleThreadHasFlashcardsAsFirstStage() {
        let thread = GameplayThreadCatalog.waterCycle
        XCTAssertEqual(thread.stages.first?.kind, .flashcards)
    }

    // MARK: - LearningLoopScoring utility (independent of content source)

    func testQuizScoringUsesCorrectAnswers() {
        let questions = [
            ConceptQuizQuestion(id: "q1", prompt: "Q1?", choices: ["A", "B", "C"], correctChoice: "A", feedback: "Yes."),
            ConceptQuizQuestion(id: "q2", prompt: "Q2?", choices: ["X", "Y", "Z"], correctChoice: "Y", feedback: "Yes."),
        ]
        let correct = Dictionary(uniqueKeysWithValues: questions.map { ($0.id, $0.correctChoice) })
        XCTAssertEqual(LearningLoopScoring.scoreQuiz(questions: questions, answersByQuestionId: correct), 2)
    }

    func testQuizScoringRejectsWrongAnswers() {
        let questions = [
            ConceptQuizQuestion(id: "q1", prompt: "Q1?", choices: ["A", "B", "C"], correctChoice: "A", feedback: "Yes."),
        ]
        XCTAssertEqual(
            LearningLoopScoring.scoreQuiz(questions: questions, answersByQuestionId: ["q1": "B"]),
            0
        )
    }

    func testPairMatchingRequiresDefinedPair() {
        let pairs = [
            ConceptMatchPair(id: "ab", left: "A", right: "B", feedback: "A matches B."),
            ConceptMatchPair(id: "cd", left: "C", right: "D", feedback: "C matches D."),
        ]
        XCTAssertTrue(LearningLoopScoring.isMatch(left: "A", right: "B", pairs: pairs))
        XCTAssertFalse(LearningLoopScoring.isMatch(left: "A", right: "D", pairs: pairs))
    }

    func testSummaryComputesStarsFromQuizAndMatches() {
        let questions = [
            ConceptQuizQuestion(id: "q1", prompt: "Q1?", choices: ["A", "B"], correctChoice: "A", feedback: "Yes."),
            ConceptQuizQuestion(id: "q2", prompt: "Q2?", choices: ["X", "Y"], correctChoice: "Y", feedback: "Yes."),
            ConceptQuizQuestion(id: "q3", prompt: "Q3?", choices: ["M", "N"], correctChoice: "M", feedback: "Yes."),
        ]
        let pairs = [
            ConceptMatchPair(id: "ab", left: "A", right: "B", feedback: "ok"),
            ConceptMatchPair(id: "cd", left: "C", right: "D", feedback: "ok"),
        ]
        let answers = Dictionary(uniqueKeysWithValues: questions.map { ($0.id, $0.correctChoice) })
        let summary = LearningLoopScoring.summary(
            questions: questions,
            answersByQuestionId: answers,
            matchedPairIds: Set(pairs.map(\.id)),
            pairs: pairs
        )
        XCTAssertEqual(summary.quizCorrect, 3)
        XCTAssertEqual(summary.matchedPairs, 2)
        XCTAssertEqual(summary.starCount, 3)
    }

    func testMatchAttemptLocksCorrectPairImmediately() {
        let pairs = [
            ConceptMatchPair(id: "p1", left: "L", right: "R", feedback: "Locked."),
        ]
        let result = LearningLoopScoring.matchAttempt(
            selectedPairId: "p1",
            targetPairId: "p1",
            pairs: pairs,
            matchedPairIds: []
        )
        XCTAssertEqual(result, .locked(pairId: "p1", feedback: "Locked."))
    }

    func testMatchAttemptRejectsWrongPairWithoutProgress() {
        let pairs = [
            ConceptMatchPair(id: "p1", left: "L", right: "R", feedback: "Locked."),
            ConceptMatchPair(id: "p2", left: "X", right: "Y", feedback: "Locked."),
        ]
        let result = LearningLoopScoring.matchAttempt(
            selectedPairId: "p1",
            targetPairId: "p2",
            pairs: pairs,
            matchedPairIds: []
        )
        XCTAssertEqual(result, .mismatch(feedback: "Not that pair yet — try another match."))
    }

    func testMatchAttemptDoesNotRelockMatchedCards() {
        let pairs = [
            ConceptMatchPair(id: "p1", left: "L", right: "R", feedback: "Locked."),
        ]
        let result = LearningLoopScoring.matchAttempt(
            selectedPairId: "p1",
            targetPairId: "p1",
            pairs: pairs,
            matchedPairIds: ["p1"]
        )
        XCTAssertEqual(result, .alreadyMatched)
    }
}

extension LearningLoopTests {
    func testSoundVolumeIntroUsesStagedSafePagesBeforeActivity() {
        let pages = SoundVolumeContent.introPages

        XCTAssertEqual(pages.map(\.id), ["welcome", "safety", "decibels", "zones", "clues"])
        XCTAssertEqual(pages.last?.primaryActionTitle, "Start Sound Lab")
        XCTAssertTrue(pages[1].subtitle.contains("no shouting"))
        XCTAssertTrue(pages[1].subtitle.contains("no points"))
        XCTAssertTrue(pages[1].subtitle.contains("no loud-noise challenge"))
        XCTAssertTrue(pages[2].subtitle.contains("decibel"))
        XCTAssertTrue(pages[3].subtitle.contains("estimate"))
        XCTAssertTrue(pages[3].subtitle.contains("not a calibrated safety tool"))
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
        XCTAssertTrue(SoundVolumeContent.safetyNote.contains("no shouting"))
        XCTAssertTrue(SoundVolumeContent.safetyNote.contains("no points for loudness"))
    }

    func testSoundVolumeCardsExposeExplicitHearingSafePlaybackExamples() {
        let examples = SoundVolumeContent.cards.compactMap(\.soundExample)

        XCTAssertEqual(examples.count, SoundVolumeContent.cards.count)
        XCTAssertEqual(Set(examples).count, SoundVolumeContent.cards.count)
        XCTAssertTrue(examples.allSatisfy { !$0.label.isEmpty })
        XCTAssertTrue(examples.allSatisfy { $0.accessibilityLabel.contains("Play hearing-safe") })
    }

    func testSoundVolumePlaybackProfilesStayShortAndLowAmplitude() {
        for example in SoundVolumeContent.cards.compactMap(\.soundExample) {
            XCTAssertLessThanOrEqual(example.profile.durationSeconds, SoundExampleKind.hearingSafeMaximumDurationSeconds)
            XCTAssertLessThanOrEqual(example.profile.peakAmplitude, SoundExampleKind.hearingSafeMaximumPeakAmplitude)
            XCTAssertGreaterThan(example.profile.durationSeconds, 0)
            XCTAssertGreaterThan(example.profile.peakAmplitude, 0)
        }
    }


    func testSoundMeterReadingBucketsArePureAndConservative() {
        XCTAssertEqual(SoundMeterReading.bucket(forRMS: 0.001), .quiet)
        XCTAssertEqual(SoundMeterReading.bucket(forRMS: 0.01), .comfortable)
        XCTAssertEqual(SoundMeterReading.bucket(forRMS: 0.10), .busy)
        XCTAssertEqual(SoundMeterReading.bucket(forRMS: 0.50), .protect)

        let overRange = SoundMeterReading(rms: 2)
        XCTAssertEqual(overRange.rms, 1)
        XCTAssertEqual(overRange.bucket, .protect)
        XCTAssertLessThanOrEqual(overRange.estimatedDecibels, 100)
    }

    func testSoundMeterCopyIsLocalOnlyAndDoesNotRewardLoudness() {
        XCTAssertTrue(SoundMeterReading.privacyCopy.contains("Local microphone meter only"))
        XCTAssertTrue(SoundMeterReading.privacyCopy.contains("stores no audio"))
        XCTAssertTrue(SoundMeterReading.privacyCopy.contains("sends no audio"))
        XCTAssertTrue(SoundMeterReading.safetyCopy.contains("Do not shout"))
        XCTAssertTrue(SoundMeterReading.safetyCopy.contains("scream"))
        XCTAssertTrue(SoundMeterReading.safetyCopy.contains("try to make the meter higher"))
        XCTAssertFalse(SoundMeterLevelBucket.allCases.map(\.targetCopy).joined(separator: " ").localizedCaseInsensitiveContains("louder"))
    }

    func testSoundMeterStartupPreflightDoesNotTouchAudioWhenUnavailableOrDenied() {
        XCTAssertEqual(
            SoundMeterStartupPreflight(isInputAvailable: false, authorization: .granted).startupDecision(),
            .fail(.unavailable)
        )
        XCTAssertEqual(
            SoundMeterStartupPreflight(isInputAvailable: true, authorization: .denied).startupDecision(),
            .fail(.denied)
        )
        XCTAssertEqual(
            SoundMeterStartupPreflight(isInputAvailable: true, authorization: .unknown).startupDecision(),
            .fail(.unavailable)
        )
    }

    func testSoundMeterStartupPreflightRequestsBeforeStartingEngine() {
        XCTAssertEqual(
            SoundMeterStartupPreflight(isInputAvailable: true, authorization: .undetermined).startupDecision(),
            .requestPermission
        )
        XCTAssertEqual(
            SoundMeterStartupPreflight(isInputAvailable: true, authorization: .granted).startupDecision(),
            .startMeter
        )
        XCTAssertTrue(SoundMeterPermissionState.requestingPermission.guidance.contains("no-mic learning mode"))
    }

    func testSoundPitchChallengeStateTeachesPitchWithoutMicrophone() {
        var state = SoundPitchChallengeState(challenge: SoundVolumeContent.pitchChallenge)
        XCTAssertFalse(state.isAnswered)
        XCTAssertTrue(state.feedback.contains("No microphone"))
        XCTAssertEqual(SoundVolumeContent.pitchBands, [.low, .middle, .high])
        XCTAssertTrue(SoundPitchBand.low.teachingCopy.contains("deep"))
        XCTAssertTrue(SoundPitchBand.high.teachingCopy.contains("bright"))

        state.select(.low)
        XCTAssertTrue(state.isAnswered)
        XCTAssertFalse(state.isCorrect)
        XCTAssertTrue(state.feedback.contains("Not that one"))

        state.select(.high)
        XCTAssertTrue(state.isCorrect)
        XCTAssertEqual(state.feedback, SoundVolumeContent.pitchChallenge.feedback)
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

    // MARK: - Shape thread (System B — GameplayThreadDefinition)

    func testShapeThreadCoversExpectedEntities() {
        let thread = GameplayThreadCatalog.shapes
        let names = Set(thread.entities.map(\.name))
        XCTAssertTrue(names.isSuperset(of: ["Circle", "Triangle", "Square", "Rectangle", "Oval", "Diamond", "Star", "Heart"]))
        XCTAssertEqual(thread.entities.count, 12)
    }

    func testShapeThreadEntitiesCarryVisualKeys() {
        let thread = GameplayThreadCatalog.shapes
        XCTAssertTrue(thread.entities.allSatisfy { $0.visualKey?.isEmpty == false })
    }

    func testShapeThreadHasFlashcardsAsFirstStage() {
        let thread = GameplayThreadCatalog.shapes
        XCTAssertEqual(thread.stages.first?.kind, .flashcards)
    }
}
