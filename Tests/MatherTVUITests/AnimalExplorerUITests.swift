import XCTest

@MainActor
final class AnimalExplorerUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testIndiaPhotoBrowsingShowsFactsAndOfflineCreditsAndReturnsToGallery() throws {
        let app = launchExplorer()
        XCTAssertTrue(app.descendants(matching: .any)["tv-animal-photo-bank-v1"].exists)
        let indiaDescription = app.staticTexts.matching(identifier: "tv-animal-collection-description")
            .matching(NSPredicate(format: "label CONTAINS %@", "Species found in India")).firstMatch
        XCTAssertTrue(indiaDescription.exists)
        XCTAssertTrue(indiaDescription.label.contains("Species found in India"))
        attach("India animal photo browser")
        choose(app, app.buttons["tv-animal-collection-all-animals"])
        XCTAssertTrue(app.buttons["tv-animal-collection-all-animals"].label.contains("31 animal photos"))
        let photos = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@", "tv-animal-card-"))
        let first = try XCTUnwrap(photos.allElementsBoundByIndex.first)
        choose(app, first)
        XCTAssertTrue(app.staticTexts["tv-animal-detail-title"].waitForExistence(timeout: 5))
        let credits = app.descendants(matching: .any).matching(identifier: "tv-animal-photo-credits")
            .matching(NSPredicate(format: "label CONTAINS %@ AND label CONTAINS %@", "License:", "Source:")).firstMatch
        XCTAssertTrue(credits.exists)
        XCTAssertTrue(credits.label.contains("License:"))
        XCTAssertTrue(credits.label.contains("Source:"))
        attach("Animal detail and offline source credit")
        XCUIRemote.shared.press(.menu)
        XCTAssertTrue(app.staticTexts["tv-animal-explorer-title"].waitForExistence(timeout: 5))
        waitForFocus(first)
        XCUIRemote.shared.press(.menu)
        XCTAssertTrue(app.buttons["tv-memory-category-animals"].waitForExistence(timeout: 5))
        waitForFocus(app.buttons["tv-memory-category-animals"])
    }

    func testPhotoQuizUsesFourNamesAndActualAnswerFeedbackWithoutPrematureReveal() throws {
        let app = launchExplorer()
        choose(app, app.buttons["tv-animal-start-quiz"])
        let answers = answerButtons(app)
        XCTAssertTrue(answers.firstMatch.waitForExistence(timeout: 5))
        XCTAssertEqual(answers.count, 4)
        XCTAssertEqual(Set(answers.allElementsBoundByIndex.map(\.identifier)).count, 4)
        XCTAssertEqual(Set(answers.allElementsBoundByIndex.map(\.label)).count, 4)
        let picture = app.descendants(matching: .any)["tv-memory-picture-prompt"]
        XCTAssertTrue(picture.exists)
        for answer in answers.allElementsBoundByIndex {
            XCTAssertFalse(picture.label.localizedCaseInsensitiveContains(answer.label), "Picture description must not silently read an answer name")
        }
        XCTAssertTrue(app.staticTexts["tv-memory-no-timer-copy"].exists)
        attach("Real photo name quiz, untimed by default")
        let selected = try XCTUnwrap(answers.allElementsBoundByIndex.first)
        let selectedName = selected.label
        choose(app, selected)
        let feedback = app.staticTexts["tv-animal-answer-feedback"]
        XCTAssertTrue(feedback.waitForExistence(timeout: 5))
        let correct = feedback.label.hasPrefix("Correct.")
        XCTAssertTrue(correct || feedback.label.hasPrefix("Not a match."))
        if correct { XCTAssertTrue(feedback.label.contains(selectedName)) }
        let matched = app.staticTexts["tv-animal-stat-matched"]
        XCTAssertTrue(matched.label.contains(correct ? "1 Matched" : "0 Matched"))
        XCTAssertEqual(app.staticTexts["tv-animal-quiz-progress"].label, "Picture 1 of 6")
        XCTAssertTrue(answers.allElementsBoundByIndex.allSatisfy { !$0.isEnabled }, "Answered choices must reject a duplicate answer")
        waitForFocus(app.buttons["tv-memory-next-picture"])
        attach("Actual answer reveal and stable score")
        XCUIRemote.shared.press(.menu)
        XCTAssertTrue(app.staticTexts["tv-animal-explorer-title"].waitForExistence(timeout: 5))
    }

    func testHintOptionsMuteAndReduceMotionKeepTheSameUnansweredPicture() {
        let app = launchExplorer(extraArguments: ["-animal-explorer-reduce-motion"])
        choose(app, app.buttons["tv-animal-start-quiz"])
        let originalIDs = Set(answerButtons(app).allElementsBoundByIndex.map(\.identifier))
        choose(app, app.buttons["tv-animal-hint"])
        XCTAssertTrue(app.staticTexts["tv-animal-hint-copy"].waitForExistence(timeout: 5))
        attach("Paused picture hint")
        XCUIRemote.shared.press(.menu)
        XCTAssertEqual(Set(answerButtons(app).allElementsBoundByIndex.map(\.identifier)), originalIDs)
        choose(app, app.buttons["tv-animal-quiz-options"])
        XCTAssertTrue(app.staticTexts["tv-animal-options-title"].waitForExistence(timeout: 5))
        choose(app, app.buttons["tv-animal-option-sound"])
        XCTAssertTrue(app.buttons["tv-animal-option-sound"].label.contains("Sound off"))
        XCUIRemote.shared.press(.menu)
        XCTAssertEqual(Set(answerButtons(app).allElementsBoundByIndex.map(\.identifier)), originalIDs)
        XCTAssertEqual(app.staticTexts["tv-animal-quiz-progress"].label, "Picture 1 of 6")
        XCTAssertTrue(app.staticTexts["tv-memory-no-timer-copy"].exists)
        attach("Muted quiz with Reduce Motion")
    }

    func testGentleTimerExpiryMoreTimeHintAndUntimedPreserveTheQuestion() {
        let app = launchExplorer(extraArguments: ["-animal-explorer-fast-timer"])
        choose(app, app.buttons["tv-animal-options"])
        choose(app, app.buttons["tv-animal-option-friendly-timer"])
        choose(app, app.buttons["tv-animal-options-back"])
        choose(app, app.buttons["tv-animal-start-quiz"])
        let originalIDs = Set(answerButtons(app).allElementsBoundByIndex.map(\.identifier))
        XCTAssertTrue(app.staticTexts["tv-animal-time-expired"].waitForExistence(timeout: 12))
        waitForFocus(app.buttons["tv-animal-more-time"])
        XCTAssertTrue(app.staticTexts["tv-animal-stat-matched"].label.contains("0 Matched"))
        XCTAssertEqual(app.staticTexts["tv-animal-quiz-progress"].label, "Picture 1 of 6")
        XCTAssertEqual(Set(answerButtons(app).allElementsBoundByIndex.map(\.identifier)), originalIDs)
        attach("Gentle timer expiry offers another breath")
        choose(app, app.buttons["tv-animal-more-time"])
        XCTAssertFalse(app.staticTexts["tv-animal-time-expired"].exists)
        choose(app, app.buttons["tv-animal-hint"])
        XCTAssertTrue(app.staticTexts["tv-animal-hint-copy"].waitForExistence(timeout: 5))
        XCUIRemote.shared.press(.menu)
        choose(app, app.buttons["tv-animal-quiz-options"])
        choose(app, app.buttons["tv-animal-option-no-timer"])
        choose(app, app.buttons["tv-animal-options-back"])
        XCTAssertTrue(app.staticTexts["tv-memory-no-timer-copy"].waitForExistence(timeout: 5))
        XCTAssertEqual(Set(answerButtons(app).allElementsBoundByIndex.map(\.identifier)), originalIDs)
        XCTAssertEqual(app.staticTexts["tv-animal-quiz-progress"].label, "Picture 1 of 6")
        XCTAssertFalse(app.staticTexts["tv-animal-answer-feedback"].exists)
        attach("Same unanswered photograph after choosing untimed")
    }

    func testBackgroundFromHintAndOptionsRestoresPausedScreenAndSameQuestion() throws {
        let app = launchExplorer()
        choose(app, app.buttons["tv-animal-options"])
        choose(app, app.buttons["tv-animal-option-friendly-timer"])
        choose(app, app.buttons["tv-animal-options-back"])
        choose(app, app.buttons["tv-animal-start-quiz"])
        let originalIDs = Set(answerButtons(app).allElementsBoundByIndex.map(\.identifier))
        let beforeHint = try timerSeconds(app)
        let hintNavigationStarted = ProcessInfo.processInfo.systemUptime
        choose(app, app.buttons["tv-animal-hint"])
        let hintPauseConfirmed = ProcessInfo.processInfo.systemUptime
        XCUIRemote.shared.press(.home)
        Thread.sleep(forTimeInterval: 2)
        app.activate()
        XCTAssertTrue(app.staticTexts["tv-animal-hint-copy"].waitForExistence(timeout: 10))
        waitForFocus(app.buttons["tv-animal-hint-back"])
        let hintResumeRequested = ProcessInfo.processInfo.systemUptime
        XCUIRemote.shared.press(.menu)
        XCTAssertEqual(Set(answerButtons(app).allElementsBoundByIndex.map(\.identifier)), originalIDs)
        let afterHint = try timerSeconds(app)
        assertTimerPreserved(before: beforeHint, after: afterHint,
            navigationStarted: hintNavigationStarted, pauseConfirmed: hintPauseConfirmed,
            resumeRequested: hintResumeRequested, timerReadAt: ProcessInfo.processInfo.systemUptime)
        let beforeOptions = try timerSeconds(app)
        let optionsNavigationStarted = ProcessInfo.processInfo.systemUptime
        choose(app, app.buttons["tv-animal-quiz-options"])
        let optionsPauseConfirmed = ProcessInfo.processInfo.systemUptime
        XCUIRemote.shared.press(.home)
        Thread.sleep(forTimeInterval: 2)
        app.activate()
        XCTAssertTrue(app.staticTexts["tv-animal-options-title"].waitForExistence(timeout: 10))
        waitForFocus(app.buttons["tv-animal-option-no-timer"])
        let optionsResumeRequested = ProcessInfo.processInfo.systemUptime
        XCUIRemote.shared.press(.menu)
        XCTAssertEqual(Set(answerButtons(app).allElementsBoundByIndex.map(\.identifier)), originalIDs)
        let afterOptions = try timerSeconds(app)
        assertTimerPreserved(before: beforeOptions, after: afterOptions,
            navigationStarted: optionsNavigationStarted, pauseConfirmed: optionsPauseConfirmed,
            resumeRequested: optionsResumeRequested, timerReadAt: ProcessInfo.processInfo.systemUptime)
        XCTAssertEqual(app.staticTexts["tv-animal-quiz-progress"].label, "Picture 1 of 6")
        XCTAssertFalse(app.staticTexts["tv-animal-answer-feedback"].exists)
        attach("Background hint and options preserve the same paused question")
    }

    private func assertTimerPreserved(before: Int, after: Int, navigationStarted: TimeInterval,
        pauseConfirmed: TimeInterval, resumeRequested: TimeInterval, timerReadAt: TimeInterval,
        file: StaticString = #filePath, line: UInt = #line) {
        let activeSeconds = (pauseConfirmed - navigationStarted) + (timerReadAt - resumeRequested)
        let allowedDrop = Int(ceil(activeSeconds)) + 1
        XCTAssertGreaterThanOrEqual(after, before - allowedDrop,
            "Timer must exclude the \(resumeRequested - pauseConfirmed)s paused interval; active navigation took \(activeSeconds)s (allowing integer display rounding)",
            file: file, line: line)
    }

    func testPhotoQuizCompletesAndReplayStartsAFreshSession() {
        let app = launchExplorer()
        choose(app, app.buttons["tv-animal-start-quiz"])
        for index in 0..<6 {
            let answer = answerButtons(app).firstMatch
            XCTAssertTrue(answer.waitForExistence(timeout: 5))
            choose(app, answer)
            choose(app, app.buttons[index == 5 ? "tv-memory-see-results" : "tv-memory-next-picture"])
        }
        XCTAssertTrue(app.staticTexts["tv-memory-completion-title"].waitForExistence(timeout: 5))
        waitForFocus(app.buttons["tv-memory-replay"])
        attach("Animal photo quiz completed")
        XCUIRemote.shared.press(.select)
        XCTAssertEqual(app.staticTexts["tv-animal-quiz-progress"].label, "Picture 1 of 6")
        XCTAssertTrue(app.staticTexts["tv-animal-stat-matched"].label.contains("0 Matched"))
        XCTAssertFalse(app.staticTexts["tv-animal-answer-feedback"].exists)
        attach("Animal photo quiz replay")
    }

    func testIllustratedAnimalQuizRemainsSeparateAndReachable() {
        let app = launchExplorer()
        choose(app, app.buttons["tv-animal-classic-quiz"])
        XCTAssertTrue(answerButtons(app).firstMatch.waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["tv-memory-no-timer-copy"].exists)
        XCTAssertFalse(app.staticTexts["tv-animal-explorer-title"].exists)
        XCTAssertFalse(app.staticTexts["tv-animal-quiz-progress"].exists)
        attach("Original illustrated animal name quiz retained")
    }

    private func launchExplorer(extraArguments: [String] = []) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["-animal-explorer-ui-test"] + extraArguments
        app.launch()
        choose(app, app.buttons["tv-mode-memory"])
        choose(app, app.buttons["tv-memory-category-animals"])
        XCTAssertTrue(app.staticTexts["tv-animal-explorer-title"].waitForExistence(timeout: 10))
        return app
    }

    private func answerButtons(_ app: XCUIApplication) -> XCUIElementQuery {
        app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@", "tv-memory-answer-"))
    }

    private func timerSeconds(_ app: XCUIApplication) throws -> Int {
        // The shared timer intentionally exposes one node and hides its children.
        let timer = app.descendants(matching: .any)["tv-animal-timer"]
        XCTAssertTrue(timer.waitForExistence(timeout: 5))
        XCTAssertEqual(app.descendants(matching: .any).matching(identifier: "tv-animal-timer").count, 1)
        let label = timer.label
        let expression = try NSRegularExpression(pattern: "[0-9]+:[0-9]{2}")
        let match = try XCTUnwrap(expression.firstMatch(in: label, range: NSRange(label.startIndex..., in: label)))
        let range = try XCTUnwrap(Range(match.range, in: label))
        let parts = label[range].split(separator: ":")
        let minutes = try XCTUnwrap(Int(parts[0]))
        let seconds = try XCTUnwrap(Int(parts[1]))
        return minutes * 60 + seconds
    }

    private func choose(_ app: XCUIApplication, _ target: XCUIElement) {
        XCTAssertTrue(target.waitForExistence(timeout: 10), target.identifier)
        for _ in 0..<40 {
            if target.hasFocus { XCUIRemote.shared.press(.select); return }
            let focused = app.buttons.allElementsBoundByIndex.first { $0.hasFocus }
                ?? app.descendants(matching: .any).allElementsBoundByIndex.first { $0.hasFocus }
            guard let focused else { XCTFail("No focused control while seeking \(target.identifier)"); return }
            let dx = target.frame.midX - focused.frame.midX
            let dy = target.frame.midY - focused.frame.midY
            let horizontal = abs(dx) > max(target.frame.width, focused.frame.width) / 2
            XCUIRemote.shared.press(horizontal ? (dx > 0 ? .right : .left) : (dy > 0 ? .down : .up))
            if focused.hasFocus {
                if horizontal && abs(dy) > 40 { XCUIRemote.shared.press(dy > 0 ? .down : .up) }
                else if !horizontal && abs(dx) > 40 { XCUIRemote.shared.press(dx > 0 ? .right : .left) }
            }
        }
        XCTFail("Could not reach \(target.identifier): \(app.debugDescription)")
    }

    private func waitForFocus(_ element: XCUIElement) {
        let focused = expectation(for: NSPredicate(format: "hasFocus == true"), evaluatedWith: element)
        wait(for: [focused], timeout: 10)
    }

    private func attach(_ name: String) {
        let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
