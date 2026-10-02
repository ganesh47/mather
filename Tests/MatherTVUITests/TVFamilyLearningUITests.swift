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
        choose(app, app.alerts.buttons["Cancel"])
        XCTAssertTrue(app.staticTexts["tv-family-evidence"].label.contains("1 with help"))
        choose(app, app.buttons["tv-family-clear-selected"])
        choose(app, app.alerts.buttons["Clear learning"])
        XCTAssertTrue(app.staticTexts["tv-family-evidence"].label.contains("0 with help"))
        XCTAssertEqual(app.staticTexts["tv-family-selected"].label, "Playing: Alex")
        attach("TV confirmed learner reset")
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
