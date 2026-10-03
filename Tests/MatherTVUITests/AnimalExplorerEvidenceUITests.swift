import XCTest

@MainActor
final class AnimalExplorerEvidenceUITests: XCTestCase {
    // The frozen 26-species India deck, seed 42, and the production SplitMix64
    // generator start with Indian chameleon. This expectation was calculated
    // from the domain source and the installed tvOS SDK's shuffle implementation;
    // the test uses the ordinary answer button, without an answer-reveal hook.
    private let correctAnswerID = "tv-memory-answer-animal-photo-indian-chameleon"
    private let correctAnimalName = "Indian chameleon"

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testJamieAnimalEvidencePersistsSeparatelyClearsAndStartsANewSession() {
        let app = XCUIApplication()
        app.launchArguments = ["-tv-family-ui-test", "-tv-family-reset", "-animal-explorer-ui-test"]
        app.launch()
        XCTAssertTrue(app.staticTexts["tv-family-title"].waitForExistence(timeout: 20))
        selectLearner("Jamie", app: app)
        assertEvidence(app, supported: 0)
        enterPhotoQuizFromGuide(app)
        answerWithHint(app)
        attach("Jamie's actual correct animal answer after explicit hint")
        returnToGuide(app)
        assertEvidence(app, supported: 1)
        XCTAssertTrue(app.staticTexts["tv-family-next"].label.contains("Naming after browsing or a hint counts as supported practice."))
        let savedJamieEvidence = app.staticTexts["tv-family-evidence"].label
        attach("Jamie has one supported animal answer and zero fresh probes")

        choose(app, app.buttons["tv-family-select-family"])
        XCTAssertEqual(app.staticTexts["tv-family-selected"].label, "Playing: Family play")
        assertEvidence(app, supported: 0)
        selectLearner("Alex", app: app)
        // Alex's one supported Sum Sprint fixture must remain untouched.
        assertEvidence(app, supported: 1)
        XCTAssertTrue(app.staticTexts["tv-family-next"].label.contains("count two small groups together"))
        selectLearner("Jamie", app: app)
        XCTAssertEqual(app.staticTexts["tv-family-evidence"].label, savedJamieEvidence)
        attach("Family and Alex evidence stay separate from Jamie")

        app.terminate()
        app.launchArguments = ["-tv-family-ui-test", "-animal-explorer-ui-test"]
        app.launch()
        XCTAssertTrue(app.staticTexts["tv-family-title"].waitForExistence(timeout: 20))
        XCTAssertEqual(app.staticTexts["tv-family-selected"].label, "Playing: Jamie")
        XCTAssertEqual(app.staticTexts["tv-family-evidence"].label, savedJamieEvidence)
        assertEvidence(app, supported: 1)
        attach("Relaunch preserves exactly one supported animal answer")

        choose(app, app.buttons["tv-family-clear-selected"])
        XCTAssertTrue(app.alerts.firstMatch.waitForExistence(timeout: 5))
        attach("Jamie's scoped learning reset requires confirmation")
        chooseAlert(app, label: "Clear learning")
        let cleared = expectation(for: NSPredicate(format: "label == %@", evidenceSummary(supported: 0)),
            evaluatedWith: app.staticTexts["tv-family-evidence"])
        wait(for: [cleared], timeout: 10)
        XCTAssertFalse(app.staticTexts["tv-family-reset-message"].exists, app.debugDescription)
        XCTAssertEqual(app.staticTexts["tv-family-selected"].label, "Playing: Jamie")
        selectLearner("Alex", app: app)
        assertEvidence(app, supported: 1)
        choose(app, app.buttons["tv-family-select-family"])
        assertEvidence(app, supported: 0)
        selectLearner("Jamie", app: app)
        assertEvidence(app, supported: 0)
        attach("Confirmed reset clears Jamie while preserving other learners")

        enterPhotoQuizFromGuide(app)
        assertNewUnansweredQuiz(app)
        attach("After reset Animals starts a new unanswered quiz")
        returnToGuide(app)
        assertEvidence(app, supported: 0)
        XCTAssertFalse(app.staticTexts["tv-family-next"].label.contains("Naming after browsing or a hint"),
            "Browsing a new quiz must not resurrect the cleared answer")

        enterPhotoQuizFromGuide(app)
        assertNewUnansweredQuiz(app)
        answerWithHint(app)
        returnToGuide(app)
        assertEvidence(app, supported: 1)
        XCTAssertTrue(app.staticTexts["tv-family-next"].label.contains("Naming after browsing or a hint counts as supported practice."))
        attach("Only the new session's actual answer contributes evidence")
    }

    private func enterPhotoQuizFromGuide(_ app: XCUIApplication) {
        XCUIRemote.shared.press(.menu)
        XCTAssertTrue(app.buttons["tv-mode-memory"].waitForExistence(timeout: 10))
        XCTAssertEqual(app.staticTexts["tv-launcher-learner"].label, "Playing: Jamie")
        choose(app, app.buttons["tv-mode-memory"])
        choose(app, app.buttons["tv-memory-category-animals"])
        XCTAssertTrue(app.staticTexts["tv-animal-explorer-title"].waitForExistence(timeout: 10))
        choose(app, app.buttons["tv-animal-collection-india-wildlife"])
        choose(app, app.buttons["tv-animal-start-quiz"])
        assertNewUnansweredQuiz(app)
    }

    private func assertNewUnansweredQuiz(_ app: XCUIApplication) {
        let answer = app.buttons[correctAnswerID]
        XCTAssertTrue(answer.waitForExistence(timeout: 10))
        XCTAssertEqual(answer.label, correctAnimalName)
        XCTAssertTrue(answer.isEnabled)
        XCTAssertEqual(app.staticTexts["tv-animal-quiz-progress"].label, "Picture 1 of 6")
        XCTAssertTrue(app.staticTexts["tv-animal-stat-matched"].label.contains("0 Matched"))
        XCTAssertFalse(app.staticTexts["tv-animal-answer-feedback"].exists)
    }

    private func answerWithHint(_ app: XCUIApplication) {
        choose(app, app.buttons["tv-animal-hint"])
        XCTAssertTrue(app.staticTexts["tv-animal-hint-copy"].waitForExistence(timeout: 5))
        choose(app, app.buttons["tv-animal-hint-back"])
        choose(app, app.buttons[correctAnswerID])
        let feedback = app.staticTexts["tv-animal-answer-feedback"]
        XCTAssertTrue(feedback.waitForExistence(timeout: 5))
        XCTAssertEqual(feedback.label, "Correct. \(correctAnimalName) matched.")
        XCTAssertTrue(app.staticTexts["tv-animal-stat-matched"].label.contains("1 Matched"))
        XCTAssertFalse(app.buttons[correctAnswerID].isEnabled)
        XCTAssertTrue(app.buttons["tv-memory-next-picture"].exists)
    }

    private func returnToGuide(_ app: XCUIApplication) {
        XCUIRemote.shared.press(.menu)
        XCTAssertTrue(app.staticTexts["tv-animal-explorer-title"].waitForExistence(timeout: 5))
        XCUIRemote.shared.press(.menu)
        XCTAssertTrue(app.buttons["tv-memory-category-animals"].waitForExistence(timeout: 5))
        XCUIRemote.shared.press(.menu)
        XCTAssertTrue(app.buttons["tv-mode-memory"].waitForExistence(timeout: 5))
        choose(app, app.buttons["tv-family-panel"])
        XCTAssertTrue(app.staticTexts["tv-family-title"].waitForExistence(timeout: 5))
        XCTAssertEqual(app.staticTexts["tv-family-selected"].label, "Playing: Jamie")
    }

    private func selectLearner(_ name: String, app: XCUIApplication) {
        choose(app, app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", name)).firstMatch)
        XCTAssertEqual(app.staticTexts["tv-family-selected"].label, "Playing: \(name)")
    }

    private func evidenceSummary(supported: Int) -> String {
        "0 answers without app help · \(supported) with help · 0 fresh probes without app help"
    }

    private func assertEvidence(_ app: XCUIApplication, supported: Int) {
        XCTAssertEqual(app.staticTexts["tv-family-evidence"].label, evidenceSummary(supported: supported))
    }

    private func chooseAlert(_ app: XCUIApplication, label: String) {
        let matches = app.alerts.buttons.matching(identifier: label)
        XCTAssertTrue(matches.firstMatch.waitForExistence(timeout: 5))
        // tvOS can expose a focusable wrapper as well as its nested alert action.
        for _ in 0..<16 {
            if matches.allElementsBoundByIndex.contains(where: { $0.hasFocus }) {
                XCUIRemote.shared.press(.select)
                return
            }
            let current = app.buttons.matching(NSPredicate(format: "hasFocus == true")).firstMatch
            XCTAssertTrue(current.waitForExistence(timeout: 5))
            let target = matches.firstMatch
            let dx = target.frame.midX - current.frame.midX
            let dy = target.frame.midY - current.frame.midY
            XCUIRemote.shared.press(abs(dy) > 40 ? (dy > 0 ? .down : .up) : (dx > 0 ? .right : .left))
        }
        XCTFail("Could not focus confirmed alert action \(label)")
    }

    private func choose(_ app: XCUIApplication, _ target: XCUIElement) {
        XCTAssertTrue(target.waitForExistence(timeout: 10), target.identifier)
        var previous: String?
        var lastDirection: XCUIRemote.Button?
        for _ in 0..<40 {
            if target.hasFocus { XCUIRemote.shared.press(.select); return }
            let current = app.descendants(matching: .any).matching(NSPredicate(format: "hasFocus == true")).firstMatch
            // A learner label update can briefly leave no exposed focused element.
            guard current.waitForExistence(timeout: 1) else {
                XCUIRemote.shared.press(.down)
                continue
            }
            let dx = target.frame.midX - current.frame.midX
            let dy = target.frame.midY - current.frame.midY
            var direction: XCUIRemote.Button = abs(dy) > 40 ? (dy > 0 ? .down : .up) : (dx > 0 ? .right : .left)
            if current.identifier == previous && direction == lastDirection {
                direction = direction == .up || direction == .down ? (dx > 0 ? .right : .left) : (dy > 0 ? .down : .up)
            }
            previous = current.identifier
            lastDirection = direction
            XCUIRemote.shared.press(direction)
        }
        XCTFail("Could not focus \(target.identifier): \(app.debugDescription)")
    }

    private func attach(_ name: String) {
        let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
