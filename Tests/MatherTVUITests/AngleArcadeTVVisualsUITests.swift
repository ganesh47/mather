import XCTest

/// Native screenshots complement assertions: they are the gate for visual geometry and contrast.
@MainActor
final class AngleArcadeTVVisualsUITests: XCTestCase {
    override func setUpWithError() throws { continueAfterFailure = false }

    func testGardenFenceContactAndCorrectionKeepHonestResults() {
        let app = launch()
        openWorld("garden", app: app)
        XCUIRemote.shared.press(.select)
        waitPrimary("Next mission", app: app)
        XCUIRemote.shared.press(.select)
        waitPrimary("Launch", app: app)
        move(angle: 2)
        XCUIRemote.shared.press(.select)
        waitPrimary("Next mission", app: app)
        XCUIRemote.shared.press(.select)
        waitPrimary("Launch", app: app)
        XCTAssertTrue(app.staticTexts["angle-mission-garden-fence"].exists)
        XCTAssertEqual(angle(in: app), "35 degrees")
        screenshot("TV Garden fence — exact initial wedge obstacle and target")

        XCUIRemote.shared.press(.select)
        waitPrimary("Try again", app: app)
        XCTAssertEqual(scene(in: app).value as? String, "The shot touched the fence.")
        XCTAssertEqual(app.staticTexts["angle-arcade-hit-count"].label, "2 of 3 complete")
        XCTAssertFalse(app.staticTexts["angle-arcade-degree-reveal"].exists)
        screenshot("TV Garden blocked contact — no success reward")

        move(angle: 2, power: 2)
        waitPrimary("Launch", app: app)
        XCTAssertEqual(angle(in: app), "45 degrees")
        screenshot("TV Garden corrected aim — turret wedge and engine preview")
        XCUIRemote.shared.press(.select)
        waitPrimary("Next mission", app: app)
        XCTAssertEqual(app.staticTexts["angle-arcade-hit-count"].label, "3 of 3 complete")
        XCTAssertEqual(app.staticTexts["angle-arcade-degree-reveal"].label, "Launch 45 degrees")
        XCTAssertTrue((scene(in: app).value as? String)?.hasPrefix("You did it!") == true)
        XCUIRemote.shared.press(.up)
        XCTAssertEqual(angle(in: app), "45 degrees")
        XCTAssertEqual(app.staticTexts["angle-arcade-hit-count"].label, "3 of 3 complete")
        screenshot("TV Garden successful contact and degree discovery")
    }

    func testBuilderCornerAndQuarterTurnKeepExactRotationMeaning() {
        let app = launch()
        openWorld("builder", app: app)
        XCTAssertTrue((scene(in: app).value as? String)?.hasPrefix("The whole square turns. Its corner stays the same.") == true)
        screenshot("TV Builder initial rigid square and dotted target")
        move(angle: 2)
        XCTAssertEqual(angle(in: app), "45 degrees")
        screenshot("TV Builder turned rigid square — both arms and square corner")
        XCUIRemote.shared.press(.select)
        waitPrimary("Next mission", app: app)
        XCTAssertEqual(app.staticTexts["angle-arcade-degree-reveal"].label, "Direction 45 degrees")
        XCUIRemote.shared.press(.select)
        waitPrimary("Check turn", app: app)
        XCTAssertTrue(app.staticTexts["angle-mission-builder-quarter-turn"].exists)
        XCTAssertEqual(angle(in: app), "0 degrees")
        XCTAssertTrue((scene(in: app).value as? String)?.hasPrefix("Turn the gate around its hinge") == true)
        move(angle: 6)
        XCTAssertEqual(angle(in: app), "90 degrees")
        screenshot("TV Builder quarter-turn gate — fixed hinge and 90 degree aim")
        XCUIRemote.shared.press(.select)
        waitPrimary("Next mission", app: app)
        XCTAssertEqual(app.staticTexts["angle-arcade-degree-reveal"].label, "Turned 90 degrees")
        XCTAssertEqual(app.staticTexts["angle-arcade-hit-count"].label, "2 of 3 complete")
        screenshot("TV Builder quarter-turn discovery")
    }

    func testReducedMotionMoonComparisonKeepsEarthTraceAndStaticOutcomes() {
        let app = launch(reducedMotion: true)
        openWorld("moon", app: app)
        screenshot("TV Earth launch world before the Moon comparison")
        move(power: 2)
        XCUIRemote.shared.press(.select)
        waitPrimary("Next mission", app: app)
        XCUIRemote.shared.press(.select)
        waitPrimary("Launch", app: app)
        XCTAssertTrue(app.staticTexts["angle-mission-moon-compare"].exists)
        XCTAssertTrue(app.staticTexts["Earth path"].exists)
        screenshot("TV Reduced Motion Moon — fixed aim and actual Earth trace")

        XCUIRemote.shared.press(.select)
        waitPrimary("Try again", app: app)
        XCTAssertEqual(scene(in: app).value as? String, "The shot went too high.")
        XCTAssertEqual(app.staticTexts["angle-arcade-hit-count"].label, "1 of 3 complete")
        XCTAssertFalse(app.staticTexts["angle-arcade-degree-reveal"].exists)
        screenshot("TV Reduced Motion Moon miss — static final flight without reward")
        move(power: -2)
        waitPrimary("Launch", app: app)
        XCTAssertTrue(app.staticTexts["Earth path"].exists)
        XCTAssertEqual(angle(in: app), "45 degrees")
        XCUIRemote.shared.press(.select)
        waitPrimary("Next mission", app: app)
        XCTAssertEqual(app.staticTexts["angle-arcade-hit-count"].label, "2 of 3 complete")
        XCTAssertEqual(app.staticTexts["angle-arcade-degree-reveal"].label, "Launch 45 degrees")
        XCUIRemote.shared.press(.up)
        XCTAssertEqual(app.staticTexts["angle-arcade-hit-count"].label, "2 of 3 complete")
        screenshot("TV Reduced Motion Moon success — static contact and degree discovery")
    }

    private func launch(reducedMotion: Bool = false) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["-angle-arcade-ui-test", "-angle-arcade-reset-progress"] + (reducedMotion ? ["-angle-arcade-reduce-motion"] : [])
        app.launch()
        let garden = app.buttons["angle-world-garden"]
        XCTAssertTrue(garden.waitForExistence(timeout: 10))
        waitFocus(garden)
        return app
    }

    private func openWorld(_ id: String, app: XCUIApplication) {
        let worlds = ["garden", "builder", "moon"]
        guard let current = worlds.firstIndex(where: { app.buttons["angle-world-\($0)"].hasFocus }), let desired = worlds.firstIndex(of: id) else {
            XCTFail("A world card must have focus")
            return
        }
        for _ in 0..<abs(desired - current) { XCUIRemote.shared.press(desired > current ? .right : .left) }
        waitFocus(app.buttons["angle-world-\(id)"])
        XCUIRemote.shared.press(.select)
        waitPrimary(id == "builder" ? "Check turn" : "Launch", app: app)
    }

    private func move(angle: Int = 0, power: Int = 0) {
        for _ in 0..<abs(angle) { XCUIRemote.shared.press(angle > 0 ? .right : .left) }
        for _ in 0..<abs(power) { XCUIRemote.shared.press(power > 0 ? .up : .down) }
    }

    private func scene(in app: XCUIApplication) -> XCUIElement {
        app.descendants(matching: .any)["angle-arcade-scene"].firstMatch
    }

    private func angle(in app: XCUIApplication) -> String? {
        app.descendants(matching: .any)["angle-arcade-angle"].firstMatch.value as? String
    }

    private func waitPrimary(_ label: String, app: XCUIApplication) {
        let primary = app.buttons["angle-arcade-primary"]
        XCTAssertTrue(primary.waitForExistence(timeout: 10))
        let ready = expectation(for: NSPredicate(format: "label == %@ AND hasFocus == true", label), evaluatedWith: primary)
        wait(for: [ready], timeout: 10)
    }

    private func waitFocus(_ element: XCUIElement) {
        let focused = expectation(for: NSPredicate(format: "hasFocus == true"), evaluatedWith: element)
        wait(for: [focused], timeout: 10)
    }

    private func screenshot(_ name: String) {
        let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
