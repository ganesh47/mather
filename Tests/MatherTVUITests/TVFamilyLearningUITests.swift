import XCTest

@MainActor
final class TVFamilyLearningUITests: XCTestCase {
    func testLearnerEvidenceFamilySeparationAndMenuReturn() {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchArguments = ["-tv-family-ui-test", "-tv-family-reset"]
        app.launch()
        XCTAssertTrue(app.staticTexts["tv-family-title"].waitForExistence(timeout: 20))
        XCTAssertEqual(app.staticTexts["tv-family-selected"].label, "Playing: Family play")
        choose(app, app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "Alex")).firstMatch)
        XCTAssertTrue(app.staticTexts["tv-family-evidence"].label.contains("1 with help"))
        XCTAssertTrue(app.staticTexts["tv-family-evidence"].label.contains("0 fresh probes"))
        attach("Selected learner has helped evidence")
        XCUIRemote.shared.press(.playPause)
        XCTAssertEqual(app.staticTexts["tv-family-selected"].label, "Playing: Alex")
        choose(app, app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "Jamie")).firstMatch)
        XCTAssertTrue(app.staticTexts["tv-family-evidence"].label.contains("0 with help"))
        attach("Another learner has separate history")
        choose(app, app.buttons["tv-family-select-family"])
        XCTAssertTrue(app.staticTexts["tv-family-evidence"].label.contains("0 with help"))
        XCUIRemote.shared.press(.menu)
        XCTAssertTrue(app.buttons["tv-mode-memory"].waitForExistence(timeout: 10))
        XCTAssertEqual(app.staticTexts["tv-launcher-learner"].label, "Playing: Family play")
        attach("Launcher retains family context")
        app.terminate()
        app.launchArguments = ["-tv-family-ui-test"]
        app.launch()
        XCTAssertTrue(app.staticTexts["tv-family-title"].waitForExistence(timeout: 20))
        choose(app, app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "Alex")).firstMatch)
        XCTAssertTrue(app.staticTexts["tv-family-evidence"].label.contains("1 with help"))
    }

    func testCompanionRecipientAndConfirmedScopedReset() {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchArguments = ["-tv-family-ui-test", "-tv-family-reset"]
        app.launch()
        XCTAssertTrue(app.staticTexts["tv-family-title"].waitForExistence(timeout: 20))
        choose(app, app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "Alex")).firstMatch)
        choose(app, app.buttons["tv-family-companion"])
        XCTAssertTrue(app.staticTexts["companion-recipient"].waitForExistence(timeout: 10))
        XCTAssertEqual(app.staticTexts["companion-recipient"].label, "Local recipient: Alex")
        attach("TV parent companion recipient")
        choose(app, app.buttons["companion-close"])
        XCTAssertTrue(app.staticTexts["tv-family-title"].waitForExistence(timeout: 10))
        choose(app, app.buttons["tv-family-clear-selected"])
        XCTAssertTrue(app.alerts.firstMatch.waitForExistence(timeout: 5))
        attach("TV parent reset confirmation before cancel")
        XCUIRemote.shared.press(.menu)
        XCTAssertTrue(app.staticTexts["tv-family-title"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["tv-family-evidence"].label.contains("1 with help"))
        choose(app, app.buttons["tv-family-clear-selected"])
        attach("TV parent reset confirmation before clear")
        chooseAlert(app, label: "Clear learning")
        let cleared = expectation(for: NSPredicate(format: "label CONTAINS %@", "0 with help"), evaluatedWith: app.staticTexts["tv-family-evidence"])
        wait(for: [cleared], timeout: 5)
        XCTAssertFalse(app.staticTexts["tv-family-reset-message"].exists, app.debugDescription)
        XCTAssertEqual(app.staticTexts["tv-family-selected"].label, "Playing: Alex")
        attach("TV confirmed learner reset")
    }

    func testSelectedLearnerShapeEvidenceSurvivesRootReentryWithoutDuplicating() {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchArguments = ["-tv-family-ui-test", "-tv-family-reset"]
        app.launch()
        XCTAssertTrue(app.staticTexts["tv-family-title"].waitForExistence(timeout: 20))
        choose(app, app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "Jamie")).firstMatch)
        XCUIRemote.shared.press(.menu)
        choose(app, app.buttons["tv-mode-shapes"])
        XCTAssertTrue(app.buttons["tv-shape-choice-B"].waitForExistence(timeout: 10))
        choose(app, app.buttons["tv-shape-choice-B"])
        XCTAssertTrue(app.buttons["tv-shape-next"].waitForExistence(timeout: 5))
        attach("Selected learner shape answer")
        XCUIRemote.shared.press(.menu)
        choose(app, app.buttons["tv-family-panel"])
        XCTAssertTrue(app.staticTexts["tv-family-evidence"].label.contains("1 answers without app help"))
        XCUIRemote.shared.press(.menu)
        choose(app, app.buttons["tv-mode-shapes"])
        XCTAssertTrue(app.buttons["tv-shape-next"].waitForExistence(timeout: 10))
        XCUIRemote.shared.press(.menu)
        choose(app, app.buttons["tv-family-panel"])
        XCTAssertTrue(app.staticTexts["tv-family-evidence"].label.contains("1 answers without app help"))
        attach("Reentered shape has one durable answer")
    }

    private func chooseAlert(_ app: XCUIApplication, label: String) {
        let matches = app.alerts.buttons.matching(identifier: label)
        XCTAssertTrue(matches.firstMatch.waitForExistence(timeout: 5))
        // tvOS exposes both a focusable wrapper and its nested action.
        for _ in 0..<12 {
            if matches.allElementsBoundByIndex.contains(where: { $0.hasFocus }) {
                XCUIRemote.shared.press(.select)
                return
            }
            let target = matches.firstMatch
            let current = app.buttons.matching(NSPredicate(format: "hasFocus == true")).firstMatch
            XCTAssertTrue(current.waitForExistence(timeout: 5))
            let dx = target.frame.midX - current.frame.midX
            let dy = target.frame.midY - current.frame.midY
            XCUIRemote.shared.press(abs(dy) > 40 ? (dy > 0 ? .down : .up) : (dx > 0 ? .right : .left))
        }
        XCTFail("Could not focus alert action \(label): \(app.debugDescription)")
    }

    private func choose(_ app: XCUIApplication, _ target: XCUIElement) {
        XCTAssertTrue(target.waitForExistence(timeout: 5))
        var previous: String?
        var lastDirection: XCUIRemote.Button?
        for _ in 0..<30 {
            if target.hasFocus { XCUIRemote.shared.press(.select); return }
            let current = app.descendants(matching: .any).matching(NSPredicate(format: "hasFocus == true")).firstMatch
            XCTAssertTrue(current.waitForExistence(timeout: 5))
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
        XCTFail("Could not focus \(target.identifier)")
    }

    private func attach(_ name: String) {
        let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
