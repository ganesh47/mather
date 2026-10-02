import XCTest

@MainActor
final class AngleArcadeUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testGuidedHitThenCorrectShortShotWithoutExtraRetry() {
        let app = launchArcade()
        assertMetric(app, identifier: "angle-arcade-angle", contains: "35")
        assertMetric(app, identifier: "angle-arcade-power", contains: "77")
        attachScreenshot("Guided first aim")

        fire(app, expecting: "Next target")
        XCTAssertTrue(app.staticTexts["Great aim!"].exists)
        attachScreenshot("Guided hit at the target")
        XCUIRemote.shared.press(.select)
        waitForPrimary(app, label: "Fire")
        assertMetric(app, identifier: "angle-arcade-angle", contains: "45")
        assertMetric(app, identifier: "angle-arcade-power", contains: "75")
        XCTAssertTrue(app.staticTexts["Target 2 of 3"].exists)
        attachScreenshot("Next target needs an adjustment")

        // At the minimum power, the ball lands before reaching the target.
        for _ in 0..<7 {
            XCUIRemote.shared.press(.down)
        }
        assertMetric(app, identifier: "angle-arcade-power", contains: "40")
        fire(app, expecting: "Try again")
        XCTAssertTrue(app.staticTexts["Too short"].exists)
        attachScreenshot("Short shot offers useful feedback")

        // A direction press immediately opens aiming again; no Select retry is needed.
        XCUIRemote.shared.press(.up)
        waitForPrimary(app, label: "Fire")
        assertMetric(app, identifier: "angle-arcade-power", contains: "45")
        XCTAssertFalse(app.staticTexts["Too short"].exists)
        for _ in 0..<8 {
            XCUIRemote.shared.press(.up)
        }
        assertMetric(app, identifier: "angle-arcade-power", contains: "85")
        attachScreenshot("Corrected aim after a miss")
        fire(app, expecting: "Next target")
        attachScreenshot("Corrected shot hits Moon dock")
        XCUIRemote.shared.press(.select)
        waitForPrimary(app, label: "Fire")
        XCTAssertTrue(app.staticTexts["Target 3 of 3"].exists)
    }

    func testEveryTargetAndWrapRequireAimingAfterGuidedShot() {
        let app = launchArcade()
        fire(app, expecting: "Next target")
        XCUIRemote.shared.press(.select)
        waitForPrimary(app, label: "Fire")

        for (progress, startingPower, winningPower) in [
            ("Target 2 of 3", "75", "85"),
            ("Target 3 of 3", "84", "94"),
            ("Target 1 of 3", "67", "77")
        ] {
            XCTAssertTrue(app.staticTexts[progress].exists)
            assertMetric(app, identifier: "angle-arcade-power", contains: startingPower)
            fire(app, expecting: "Try again")
            attachScreenshot("\(progress) starts with a correctable miss")
            XCUIRemote.shared.press(.up)
            waitForPrimary(app, label: "Fire")
            XCUIRemote.shared.press(.up)
            assertMetric(app, identifier: "angle-arcade-power", contains: winningPower)
            fire(app, expecting: "Next target")
            XCUIRemote.shared.press(.select)
            waitForPrimary(app, label: "Fire")
        }
        XCTAssertTrue(app.staticTexts["Target 2 of 3"].exists)
        assertMetric(app, identifier: "angle-arcade-power", contains: "75")
    }

    func testRepeatPromptAndMenuDuringFlightAllowFreshReentry() {
        let app = launchArcade()
        XCUIRemote.shared.press(.playPause)
        waitForPrimary(app, label: "Fire")
        assertMetric(app, identifier: "angle-arcade-power", contains: "77")

        // Leaving during flight must cancel the pending result and narration.
        XCUIRemote.shared.press(.select)
        XCUIRemote.shared.press(.menu)
        let arcade = app.buttons["tv-mode-angle"]
        XCTAssertTrue(arcade.waitForExistence(timeout: 10))
        waitForFocus(arcade)
        attachScreenshot("Menu returns focus to Angle Arcade")
        XCUIRemote.shared.press(.select)
        waitForPrimary(app, label: "Fire")
        assertMetric(app, identifier: "angle-arcade-power", contains: "77")
        XCTAssertTrue(app.staticTexts["Target 1 of 3"].exists)
        fire(app, expecting: "Next target")
        attachScreenshot("Fresh guided shot after reentry")
    }

    func testAngleControlsAndPowerLimitOfferUsefulCorrectionHints() {
        let app = launchArcade()
        fire(app, expecting: "Next target")
        XCUIRemote.shared.press(.select)
        waitForPrimary(app, label: "Fire")

        for _ in 0..<5 {
            XCUIRemote.shared.press(.left)
            XCUIRemote.shared.press(.up)
        }
        assertMetric(app, identifier: "angle-arcade-angle", contains: "20")
        assertMetric(app, identifier: "angle-arcade-power", contains: "100")
        fire(app, expecting: "Try again")
        XCTAssertEqual(app.staticTexts["angle-arcade-result"].label, "Too low")
        XCTAssertTrue(app.staticTexts.matching(NSPredicate(format: "label CONTAINS %@", "Try a higher angle →")).firstMatch.exists)
        attachScreenshot("At maximum power the hint suggests a higher angle")

        XCUIRemote.shared.press(.right)
        waitForPrimary(app, label: "Fire")
        assertMetric(app, identifier: "angle-arcade-angle", contains: "25")
        XCTAssertEqual(app.staticTexts["angle-arcade-result"].label, "Ready")
        for _ in 0..<8 {
            XCUIRemote.shared.press(.right)
        }
        assertMetric(app, identifier: "angle-arcade-angle", contains: "65")
        fire(app, expecting: "Try again")
        XCTAssertEqual(app.staticTexts["angle-arcade-result"].label, "Too high")
        XCTAssertTrue(app.staticTexts.matching(NSPredicate(format: "label CONTAINS %@", "Try less power ↓")).firstMatch.exists)
        attachScreenshot("High angle miss suggests less power")
    }

    func testRepeatedSelectAndAdjustmentDuringFlightDoNotSkipOrCountTwice() {
        let app = launchArcade()
        XCUIRemote.shared.press(.select)
        // Send these inputs back to back, before querying UI or waiting for a result.
        XCUIRemote.shared.press(.select)
        XCUIRemote.shared.press(.up)
        let primary = app.buttons["angle-arcade-fire-replay-button"]
        if primary.label == "Flying…" {
            attachScreenshot("Repeated input while the ball is flying")
        }
        waitForPrimary(app, label: "Next target")
        XCTAssertEqual(app.staticTexts["angle-arcade-hit-count"].label, "1 hit")
        XCTAssertEqual(app.staticTexts["angle-arcade-target-progress"].label, "Target 1 of 3")
        assertMetric(app, identifier: "angle-arcade-power", contains: "77")
        attachScreenshot("One hit after repeated flight inputs")
    }

    func testBackgroundDuringFlightCancelsResultAndAllowsAnotherShot() {
        let app = launchArcade()
        XCUIRemote.shared.press(.select)
        XCUIDevice.shared.press(.home)
        app.activate()
        waitForPrimary(app, label: "Fire")
        XCTAssertEqual(app.staticTexts["angle-arcade-hit-count"].label, "0 hits")
        XCTAssertEqual(app.staticTexts["angle-arcade-result"].label, "Ready")
        attachScreenshot("Cancelled flight after foregrounding")
        fire(app, expecting: "Next target")
        XCTAssertEqual(app.staticTexts["angle-arcade-hit-count"].label, "1 hit")
        attachScreenshot("New shot works after foregrounding")

        // Foreground focus must also return without erasing a completed result.
        XCUIDevice.shared.press(.home)
        app.activate()
        waitForPrimary(app, label: "Next target")
        XCTAssertEqual(app.staticTexts["angle-arcade-hit-count"].label, "1 hit")
        XCTAssertEqual(app.staticTexts["angle-arcade-result"].label, "Great aim!")
        XCUIRemote.shared.press(.select)
        waitForPrimary(app, label: "Fire")
        XCTAssertEqual(app.staticTexts["angle-arcade-target-progress"].label, "Target 2 of 3")
    }

    private func launchArcade() -> XCUIApplication {
        let app = XCUIApplication()
        app.launch()
        let memory = app.buttons["tv-mode-memory"]
        XCTAssertTrue(memory.waitForExistence(timeout: 20))
        waitForFocus(memory)
        XCUIRemote.shared.press(.right)
        let arcade = app.buttons["tv-mode-angle"]
        waitForFocus(arcade)
        XCUIRemote.shared.press(.select)
        waitForPrimary(app, label: "Fire")
        return app
    }

    private func fire(_ app: XCUIApplication, expecting label: String) {
        waitForPrimary(app, label: "Fire")
        XCUIRemote.shared.press(.select)
        waitForPrimary(app, label: label)
    }

    private func waitForPrimary(_ app: XCUIApplication, label: String) {
        let primary = app.buttons["angle-arcade-fire-replay-button"]
        XCTAssertTrue(primary.waitForExistence(timeout: 10))
        let ready = expectation(
            for: NSPredicate(format: "label == %@ AND enabled == true AND hasFocus == true", label),
            evaluatedWith: primary
        )
        wait(for: [ready], timeout: 10)
    }

    private func assertMetric(_ app: XCUIApplication, identifier: String, contains value: String) {
        let metric = app.descendants(matching: .any)[identifier].firstMatch
        XCTAssertTrue(metric.waitForExistence(timeout: 5))
        let updated = expectation(for: NSPredicate(format: "value CONTAINS %@", value), evaluatedWith: metric)
        wait(for: [updated], timeout: 5)
    }

    private func waitForFocus(_ element: XCUIElement) {
        let focused = expectation(for: NSPredicate(format: "hasFocus == true"), evaluatedWith: element)
        wait(for: [focused], timeout: 10)
    }

    private func attachScreenshot(_ name: String) {
        let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
