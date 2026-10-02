import XCTest

/// Uses the authored catalog solution contract checked by AngleCannonTests.
@MainActor
final class AngleArcadeCampaignUITests: XCTestCase {
    private let solutions: [(world: String, missions: [(id: String, angleMoves: Int, powerMoves: Int)])] = [
        ("garden", [("garden-guided", 0, 0), ("garden-raised", 2, 0), ("garden-fence", 2, 2)]),
        ("builder", [("builder-corner", 2, 0), ("builder-quarter-turn", 6, 0), ("builder-transfer", -4, 0)]),
        ("moon", [("moon-earth", 0, 2), ("moon-compare", 0, -2), ("moon-transfer", 2, 2)])
    ]

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testAllWorldsCompleteWithTouchAndCanReplay() {
        let app = launch(reset: true)
        for world in solutions {
            tap(app, "angle-world-\(world.world)")
            waitPhase(app, "aiming")
            for (index, mission) in world.missions.enumerated() {
                XCTAssertTrue(app.staticTexts["angle-mission-\(mission.id)"].exists)
                adjust(app, angle: mission.angleMoves, power: mission.powerMoves)
                tap(app, "angle-arcade-primary")
                waitPrimary(app, "Next mission")
                screenshot("Touch solution \(mission.id)")
                tap(app, "angle-arcade-primary")
                waitPhase(app, index == 2 ? "worldComplete" : "aiming")
            }
            screenshot("\(world.world) complete on iPad")
            tap(app, "angle-arcade-worlds")
            waitPhase(app, "worldSelection")
            tap(app, "angle-world-\(world.world)")
            waitPhase(app, "aiming")
            XCTAssertTrue(app.staticTexts["angle-mission-\(world.missions[0].id)"].exists)
            tap(app, "angle-arcade-worlds")
            waitPhase(app, "worldSelection")
        }
    }

    func testTouchHelpRotationAndSavedProgress() {
        var app = launch(reset: true)
        tap(app, "angle-world-builder")
        waitPhase(app, "aiming")
        tap(app, "angle-arcade-help")
        XCTAssertTrue(app.staticTexts["angle-mission-builder-corner"].exists)
        // Help must reveal a representation without choosing the winning angle.
        let angle = app.descendants(matching: .any)["angle-arcade-angle"].firstMatch
        XCTAssertEqual(angle.value as? String, "15")
        XCUIDevice.shared.orientation = .landscapeLeft
        _ = reachableButton(app, "angle-angle-increase")
        _ = reachableButton(app, "angle-arcade-primary")
        adjust(app, angle: 2, power: 0)
        tap(app, "angle-arcade-primary")
        waitPrimary(app, "Next mission")
        screenshot("Builder touch correction in landscape")
        tap(app, "angle-arcade-primary")
        waitPhase(app, "aiming")
        XCUIDevice.shared.orientation = .portrait
        _ = reachableButton(app, "angle-angle-increase")
        screenshot("Builder next mission in portrait")
        app.terminate()
        app = launch(reset: false)
        tap(app, "angle-world-builder")
        waitPhase(app, "aiming")
        XCTAssertTrue(app.staticTexts["angle-mission-builder-quarter-turn"].exists)
    }

    func testMissCanBeAdjustedDirectlyAndFlightCancelsOnBackground() {
        let app = launch(reset: true)
        tap(app, "angle-world-moon")
        waitPhase(app, "aiming")
        tap(app, "angle-arcade-primary")
        waitPrimary(app, "Try again")
        screenshot("Moon miss on touch controls")
        tap(app, "angle-power-increase")
        waitPhase(app, "aiming")
        tap(app, "angle-power-increase")
        tap(app, "angle-arcade-primary")
        XCUIDevice.shared.press(.home)
        let departed = expectation(for: NSPredicate { _, _ in app.state == .runningBackground || app.state == .runningBackgroundSuspended }, evaluatedWith: nil)
        wait(for: [departed], timeout: 10)
        app.activate()
        waitPhase(app, "aiming")
        XCTAssertTrue(app.staticTexts["angle-mission-moon-earth"].exists)
        tap(app, "angle-arcade-primary")
        waitPrimary(app, "Next mission")
        screenshot("Touch flight recovered after foregrounding")
    }

    private func launch(reset: Bool) -> XCUIApplication {
        XCUIDevice.shared.orientation = .portrait
        let app = XCUIApplication()
        app.launchArguments = ["-angle-arcade-ui-test"] + (reset ? ["-angle-arcade-reset-progress"] : [])
        app.launch()
        waitPhase(app, "worldSelection")
        return app
    }

    private func adjust(_ app: XCUIApplication, angle: Int, power: Int) {
        for _ in 0..<abs(angle) { tap(app, angle > 0 ? "angle-angle-increase" : "angle-angle-decrease") }
        for _ in 0..<abs(power) { tap(app, power > 0 ? "angle-power-increase" : "angle-power-decrease") }
    }

    private func tap(_ app: XCUIApplication, _ identifier: String) {
        reachableButton(app, identifier).tap()
    }

    private func reachableButton(_ app: XCUIApplication, _ identifier: String) -> XCUIElement {
        let button = app.buttons[identifier]
        XCTAssertTrue(button.waitForExistence(timeout: 10))
        let scroll = app.scrollViews["angle-arcade-scroll"].firstMatch
        for _ in 0..<7 {
            if button.isHittable { return button }
            guard scroll.exists else { break }
            let upwards = button.frame.minY >= scroll.frame.minY
            let start = scroll.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: upwards ? 0.85 : 0.2))
            let end = scroll.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: upwards ? 0.2 : 0.85))
            start.press(forDuration: 0.05, thenDragTo: end)
        }
        if !button.isHittable {
            screenshot("Unreachable touch control \(identifier)")
            let hierarchy = XCTAttachment(string: app.debugDescription)
            hierarchy.name = "Hierarchy for unreachable \(identifier)"
            hierarchy.lifetime = .keepAlways
            add(hierarchy)
        }
        XCTAssertTrue(button.isHittable, "Touch control must be reachable: \(identifier)")
        return button
    }

    private func waitPrimary(_ app: XCUIApplication, _ label: String) {
        let primary = app.buttons["angle-arcade-primary"]
        XCTAssertTrue(primary.waitForExistence(timeout: 10))
        let ready = expectation(for: NSPredicate(format: "label == %@", label), evaluatedWith: primary)
        wait(for: [ready], timeout: 10)
    }

    private func waitPhase(_ app: XCUIApplication, _ phase: String) {
        let element = app.descendants(matching: .any)["angle-arcade-phase"].firstMatch
        XCTAssertTrue(element.waitForExistence(timeout: 10))
        let state = expectation(for: NSPredicate(format: "value == %@", phaseValue(phase)), evaluatedWith: element)
        wait(for: [state], timeout: 10)
    }

    private func phaseValue(_ phase: String) -> String {
        ["worldSelection": "Choose a world", "aiming": "Aiming", "flying": "Flying", "result": "Result", "worldComplete": "World complete"][phase] ?? phase
    }

    private func screenshot(_ name: String) {
        let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
