import XCTest

/// Authored mission solutions are also checked against the shared catalog in AngleCannonTests.
@MainActor
final class AngleArcadeUITests: XCTestCase {
    private struct Mission {
        let id: String
        let angleMoves: Int
        let powerMoves: Int
    }
    private let worlds: [(id: String, missions: [Mission])] = [
        ("garden", [.init(id: "garden-guided", angleMoves: 0, powerMoves: 0), .init(id: "garden-raised", angleMoves: 2, powerMoves: 0), .init(id: "garden-fence", angleMoves: 2, powerMoves: 2)]),
        ("builder", [.init(id: "builder-corner", angleMoves: 2, powerMoves: 0), .init(id: "builder-quarter-turn", angleMoves: 6, powerMoves: 0), .init(id: "builder-transfer", angleMoves: -4, powerMoves: 0)]),
        ("moon", [.init(id: "moon-earth", angleMoves: 0, powerMoves: 2), .init(id: "moon-compare", angleMoves: 0, powerMoves: -2), .init(id: "moon-transfer", angleMoves: 2, powerMoves: 2)])
    ]

    override func setUpWithError() throws { continueAfterFailure = false }

    func testAllNineMissionsCompleteAndEachWorldCanReplay() {
        let app = launch(reset: true)
        for world in worlds {
            openWorld(world.id, app: app)
            for (index, mission) in world.missions.enumerated() {
                assertMission(mission.id, app: app)
                move(angle: mission.angleMoves, power: mission.powerMoves)
                XCUIRemote.shared.press(.select)
                waitPrimary(app, label: "Next mission")
                screenshot("\(mission.id) succeeds")
                XCUIRemote.shared.press(.select)
                waitPhase(app, index == 2 ? "worldComplete" : "aiming")
            }
            screenshot("\(world.id) complete")
            XCUIRemote.shared.press(.menu)
            waitPhase(app, "worldSelection")
            openWorld(world.id, app: app)
            assertMission(world.missions[0].id, app: app)
            screenshot("\(world.id) replay")
            XCUIRemote.shared.press(.menu)
            waitPhase(app, "worldSelection")
        }
    }

    func testWorldProgressSurvivesRelaunchAndResumesNextMission() {
        var app = launch(reset: true)
        openWorld("builder", app: app)
        move(angle: 2, power: 0)
        XCUIRemote.shared.press(.select)
        waitPrimary(app, label: "Next mission")
        XCUIRemote.shared.press(.select)
        waitPhase(app, "aiming")
        assertMission("builder-quarter-turn", app: app)
        app.terminate()
        app = launch(reset: false)
        openWorld("builder", app: app)
        assertMission("builder-quarter-turn", app: app)
        screenshot("Saved Builder progress after relaunch")
    }

    func testFlightIgnoresRepeatedInputThenBackgroundCancelsAnotherFlight() {
        let app = launch(reset: true)
        openWorld("garden", app: app)
        XCUIRemote.shared.press(.select)
        XCUIRemote.shared.press(.select)
        XCUIRemote.shared.press(.up)
        waitPrimary(app, label: "Next mission")
        assertMission("garden-guided", app: app)
        XCTAssertEqual(app.staticTexts["angle-arcade-hit-count"].label, "1 of 3 complete")
        XCUIRemote.shared.press(.select)
        waitPhase(app, "aiming")
        move(angle: 2, power: 0)
        XCUIRemote.shared.press(.select)
        backgroundAndActivate(app)
        waitPhase(app, "aiming")
        waitPrimary(app, label: "Launch")
        assertMission("garden-raised", app: app)
        XCTAssertEqual(app.staticTexts["angle-arcade-hit-count"].label, "1 of 3 complete")
        screenshot("Foreground restores cancelled flight with no extra completion")
        XCUIRemote.shared.press(.select)
        waitPrimary(app, label: "Next mission")
        XCTAssertEqual(app.staticTexts["angle-arcade-hit-count"].label, "2 of 3 complete")

        // Foreground focus must return without erasing a completed result.
        backgroundAndActivate(app)
        waitPhase(app, "result")
        waitPrimary(app, label: "Next mission")
        assertMission("garden-raised", app: app)
        XCTAssertEqual(app.staticTexts["angle-arcade-hit-count"].label, "2 of 3 complete")
        XCUIRemote.shared.press(.select)
        waitPhase(app, "aiming")
        assertMission("garden-fence", app: app)
    }

    private func backgroundAndActivate(_ app: XCUIApplication) {
        XCUIDevice.shared.press(.home)
        // Wait for Home to finish backgrounding before requesting activation.
        // Otherwise the pending Home transition can cover the activated game.
        let departed = expectation(
            for: NSPredicate { _, _ in
                app.state == .runningBackground || app.state == .runningBackgroundSuspended
            },
            evaluatedWith: nil
        )
        wait(for: [departed], timeout: 10)
        app.activate()
        XCTAssertTrue(app.wait(for: .runningForeground, timeout: 10), "MatherTV must return to the foreground")
    }

    func testHelpAndMissAllowImmediateRemoteCorrection() {
        let app = launch(reset: true)
        openWorld("moon", app: app)
        XCUIRemote.shared.press(.playPause)
        waitPhase(app, "aiming")
        XCUIRemote.shared.press(.select)
        waitPrimary(app, label: "Try again")
        screenshot("Moon miss with teaching feedback")
        XCUIRemote.shared.press(.up)
        waitPhase(app, "aiming")
        XCUIRemote.shared.press(.up)
        XCUIRemote.shared.press(.select)
        waitPrimary(app, label: "Next mission")
        screenshot("Moon correction after help")
    }

    func testEveryWorldFocusRemainsReadableAndReducedMotionCanLaunch() {
        let app = launch(reset: true, reducedMotion: true)
        for world in ["garden", "builder", "moon"] {
            let card = app.buttons["angle-world-\(world)"]
            let focused = expectation(for: NSPredicate(format: "hasFocus == true"), evaluatedWith: card)
            wait(for: [focused], timeout: 10)
            XCTAssertTrue(card.label.contains("0 of 3 missions complete"))
            screenshot("Reduced Motion focused \(world), all card labels visible")
            XCUIRemote.shared.press(.playPause)
            if world != "moon" { XCUIRemote.shared.press(.right) }
        }
        XCUIRemote.shared.press(.left)
        XCUIRemote.shared.press(.left)
        openWorld("garden", app: app)
        XCUIRemote.shared.press(.select)
        waitPrimary(app, label: "Next mission")
        assertMission("garden-guided", app: app)
        screenshot("Reduced Motion guided Garden success")
    }

    private func launch(reset: Bool, reducedMotion: Bool = false) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["-angle-arcade-ui-test"] + (reset ? ["-angle-arcade-reset-progress"] : []) + (reducedMotion ? ["-angle-arcade-reduce-motion"] : [])
        app.launch()
        waitPhase(app, "worldSelection")
        return app
    }

    private func openWorld(_ id: String, app: XCUIApplication) {
        let cards = ["garden", "builder", "moon"]
        let garden = app.buttons["angle-world-garden"]
        XCTAssertTrue(garden.waitForExistence(timeout: 10))
        // Returning from a mission focuses its world; navigate by observed focus.
        guard let current = cards.firstIndex(where: { app.buttons["angle-world-\($0)"].hasFocus }), let desired = cards.firstIndex(of: id) else {
            XCTFail("World selector must have a focused card")
            return
        }
        for _ in 0..<abs(desired - current) { XCUIRemote.shared.press(desired > current ? .right : .left) }
        let card = app.buttons["angle-world-\(id)"]
        let focus = expectation(for: NSPredicate(format: "hasFocus == true"), evaluatedWith: card)
        wait(for: [focus], timeout: 10)
        XCUIRemote.shared.press(.select)
        waitPhase(app, "aiming")
    }

    private func move(angle: Int, power: Int) {
        for _ in 0..<abs(angle) { XCUIRemote.shared.press(angle > 0 ? .right : .left) }
        for _ in 0..<abs(power) { XCUIRemote.shared.press(power > 0 ? .up : .down) }
    }

    private func assertMission(_ id: String, app: XCUIApplication) {
        XCTAssertTrue(app.staticTexts["angle-mission-\(id)"].exists)
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

    private func waitPrimary(_ app: XCUIApplication, label: String) {
        let primary = app.buttons["angle-arcade-primary"]
        XCTAssertTrue(primary.waitForExistence(timeout: 10))
        let ready = expectation(for: NSPredicate(format: "label == %@ AND hasFocus == true", label), evaluatedWith: primary)
        wait(for: [ready], timeout: 10)
    }

    private func screenshot(_ name: String) {
        let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
