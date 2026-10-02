import XCTest

@MainActor
final class SumSprintPartyUITests: XCTestCase {
    override func setUpWithError() throws { continueAfterFailure = false }

    func testFiniteThroughFiveSessionHasFreshProbeAndCalmFinish() throws {
        let app = launch(reset: true)
        start(range: 5, app: app)
        var pictureIDs: [String] = []
        for index in 0..<6 {
            let picture = app.descendants(matching: .any)["tv-sum-sprint-picture-prompt"].firstMatch
            XCTAssertTrue(picture.waitForExistence(timeout: 10))
            pictureIDs.append(picture.value as? String ?? "")
            XCTAssertEqual(app.staticTexts["tv-sum-sprint-progress"].label, "\(index + 1) of 6")
            if index == 5 {
                XCTAssertTrue(picture.label.contains("missing whole"))
                XCTAssertFalse(picture.label.contains("Count the first part"))
                screenshot("Fresh number-parts probe")
            }
            choose(total: try total(app), app: app)
            waitFocus(app.buttons["tv-sum-sprint-next-fact"])
            XCUIRemote.shared.press(.select)
        }
        XCTAssertEqual(Set(pictureIDs).count, 6)
        XCTAssertTrue(app.descendants(matching: .any)["tv-sum-sprint-finish"].firstMatch.waitForExistence(timeout: 10))
        XCTAssertEqual(app.staticTexts["tv-sum-sprint-outcomes"].label, "6 without app hints · 0 with counting help")
        XCTAssertFalse(app.buttons["tv-sum-sprint-next-fact"].exists)
        XCTAssertTrue(app.buttons["tv-sum-sprint-all-done"].exists)
        screenshot("Calm finite session finish")
        waitFocus(app.buttons["tv-sum-sprint-another-session"])
        XCUIRemote.shared.press(.right)
        waitFocus(app.buttons["tv-sum-sprint-all-done"])
        XCUIRemote.shared.press(.select)
        waitFocus(app.buttons["tv-mode-sprint"])
        XCUIRemote.shared.press(.select)
        XCTAssertTrue(app.buttons["tv-sum-sprint-range-5"].waitForExistence(timeout: 10))
    }

    func testMissAllowsCorrectionAndHelpSurvivesMenuAndRelaunch() throws {
        var app = launch(reset: true)
        start(range: 10, app: app)
        let picture = app.descendants(matching: .any)["tv-sum-sprint-picture-prompt"].firstMatch
        let original = picture.value as? String
        let correct = try total(app)
        let wrong = try XCTUnwrap(answerButtons(app).first { Int($0.label) != correct })
        focusAnswer(wrong, app: app)
        XCUIRemote.shared.press(.select)
        XCTAssertTrue(wrong.isEnabled)
        XCTAssertFalse(app.buttons["tv-sum-sprint-next-fact"].exists)
        XCTAssertTrue(picture.label.contains("Count the first part"))
        XCTAssertEqual(picture.value as? String, original)
        screenshot("Wrong total remains open with counting scaffold")
        XCUIRemote.shared.press(.playPause)
        XCTAssertEqual(picture.value as? String, original)
        XCUIRemote.shared.press(.menu)
        waitFocus(app.buttons["tv-mode-sprint"])
        XCUIRemote.shared.press(.select)
        waitFocus(app.buttons["tv-sum-sprint-resume"])
        XCUIRemote.shared.press(.select)
        XCTAssertEqual(picture.value as? String, original)
        app.terminate()
        app = launch(reset: false)
        waitFocus(app.buttons["tv-sum-sprint-resume"])
        XCUIRemote.shared.press(.select)
        let resumed = app.descendants(matching: .any)["tv-sum-sprint-picture-prompt"].firstMatch
        XCTAssertEqual(resumed.value as? String, original)
        XCTAssertTrue(resumed.label.contains("Count the first part"))
        choose(total: correct, app: app)
        XCTAssertTrue(app.staticTexts["Counting helped you join the parts!"].exists)
        screenshot("Helped correction after relaunch")
    }

    func testRemoteCountingAndForegroundRestoreKeepFrozenItem() throws {
        let app = launch(reset: true)
        start(range: 20, app: app)
        let picture = app.descendants(matching: .any)["tv-sum-sprint-picture-prompt"].firstMatch
        let original = picture.value as? String
        XCUIRemote.shared.press(.down); XCUIRemote.shared.press(.down)
        waitFocus(app.buttons["tv-sum-sprint-help"])
        XCUIRemote.shared.press(.select); XCUIRemote.shared.press(.select)
        XCUIRemote.shared.press(.right)
        waitFocus(app.buttons["tv-sum-sprint-count"])
        XCUIRemote.shared.press(.select)
        XCTAssertTrue(app.staticTexts["tv-sum-sprint-counted"].waitForExistence(timeout: 10))
        let counted = app.staticTexts["tv-sum-sprint-counted"].label
        screenshot("Count-on lights one counter per Select")
        XCUIDevice.shared.press(.home)
        let background = expectation(for: NSPredicate { _, _ in app.state == .runningBackground || app.state == .runningBackgroundSuspended }, evaluatedWith: nil)
        wait(for: [background], timeout: 10)
        app.activate()
        XCTAssertTrue(app.wait(for: .runningForeground, timeout: 10))
        XCTAssertEqual(picture.value as? String, original)
        XCTAssertEqual(app.staticTexts["tv-sum-sprint-counted"].label, counted)
        let focused = expectation(for: NSPredicate { _, _ in self.answerButtons(app).contains { $0.hasFocus } }, evaluatedWith: nil)
        wait(for: [focused], timeout: 10)
        choose(total: try total(app), app: app)
        XCTAssertTrue(app.staticTexts["Counting helped you join the parts!"].exists)
    }

    func testUnsupportedHistoryShowsRecoveryInsteadOfStartingOrResuming() {
        let app = launch(reset: true, extraArguments: ["-sum-sprint-unsupported-history-fixture"])
        let message = app.staticTexts["tv-sum-sprint-storage-message"]
        XCTAssertTrue(message.waitForExistence(timeout: 10))
        XCTAssertTrue(message.label.contains("kept on this TV"))
        XCTAssertFalse(app.buttons["tv-sum-sprint-range-5"].exists)
        XCTAssertFalse(app.buttons["tv-sum-sprint-resume"].exists)
        XCTAssertFalse(app.descendants(matching: .any)["tv-sum-sprint-picture-prompt"].firstMatch.exists)
        waitFocus(app.buttons["tv-sum-sprint-recovery-exit"])
        XCUIRemote.shared.press(.playPause)
        screenshot("Unsupported history is preserved with a recovery message")
        XCUIRemote.shared.press(.menu)
        waitFocus(app.buttons["tv-mode-sprint"])
        XCUIRemote.shared.press(.select)
        XCTAssertTrue(message.waitForExistence(timeout: 10))
        XCTAssertFalse(app.buttons["tv-sum-sprint-range-5"].exists)
    }

    private func launch(reset: Bool, extraArguments: [String] = []) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["-sum-sprint-ui-test"] + (reset ? ["-sum-sprint-reset-progress"] : []) + extraArguments
        app.launch()
        let sprint = app.buttons["tv-mode-sprint"]
        XCTAssertTrue(sprint.waitForExistence(timeout: 10))
        XCUIRemote.shared.press(.right); XCUIRemote.shared.press(.right)
        waitFocus(sprint)
        XCUIRemote.shared.press(.select)
        XCTAssertTrue(app.staticTexts["tv-sum-sprint-title"].waitForExistence(timeout: 10))
        return app
    }
    private func start(range: Int, app: XCUIApplication) {
        let card = app.buttons["tv-sum-sprint-range-\(range)"]
        XCTAssertTrue(card.waitForExistence(timeout: 10), app.debugDescription)
        if range >= 10 { XCUIRemote.shared.press(.right) }
        if range == 20 { XCUIRemote.shared.press(.right) }
        waitFocus(card)
        XCUIRemote.shared.press(.select)
        XCTAssertTrue(app.descendants(matching: .any)["tv-sum-sprint-picture-prompt"].firstMatch.waitForExistence(timeout: 10))
    }
    private func total(_ app: XCUIApplication) throws -> Int {
        let label = app.descendants(matching: .any)["tv-sum-sprint-picture-prompt"].firstMatch.label
        let expression = try NSRegularExpression(pattern: "What is ([0-9]+) plus ([0-9]+)")
        let match = try XCTUnwrap(expression.firstMatch(in: label, range: NSRange(label.startIndex..., in: label)))
        let a = try XCTUnwrap(Range(match.range(at: 1), in: label))
        let b = try XCTUnwrap(Range(match.range(at: 2), in: label))
        return try XCTUnwrap(Int(label[a])) + XCTUnwrap(Int(label[b]))
    }
    private func answerButtons(_ app: XCUIApplication) -> [XCUIElement] {
        app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@", "tv-sum-sprint-answer-")).allElementsBoundByIndex
    }
    private func choose(total: Int, app: XCUIApplication) {
        focusAnswer(app.buttons["tv-sum-sprint-answer-\(total)"], app: app)
        XCUIRemote.shared.press(.select)
    }
    private func focusAnswer(_ answer: XCUIElement, app: XCUIApplication) {
        XCTAssertTrue(answer.waitForExistence(timeout: 10))
        let directions: [XCUIRemote.Button] = [.up, .left, .up, .left]
        for direction in directions { XCUIRemote.shared.press(direction) }
        guard let index = answerButtons(app).firstIndex(where: { $0.identifier == answer.identifier }) else { XCTFail("Answer must exist"); return }
        if index >= 2 { XCUIRemote.shared.press(.down) }
        if index % 2 == 1 { XCUIRemote.shared.press(.right) }
        waitFocus(answer)
    }
    private func waitFocus(_ element: XCUIElement) {
        XCTAssertTrue(element.waitForExistence(timeout: 10))
        let focused = expectation(for: NSPredicate(format: "hasFocus == true"), evaluatedWith: element)
        wait(for: [focused], timeout: 10)
    }
    private func screenshot(_ name: String) {
        let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        attachment.name = name; attachment.lifetime = .keepAlways; add(attachment)
    }
}
