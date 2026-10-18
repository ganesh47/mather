import XCTest

@MainActor
final class WorldQuestUITests: XCTestCase {
    override func setUpWithError() throws { continueAfterFailure = false }

    func testPracticeMapSubmissionAndRevealNeverExposeCandidateNames() {
        let app = launchQuest()
        XCUIRemote.shared.press(.select)
        let map = app.buttons["world-quest-map"]
        XCTAssertTrue(map.waitForExistence(timeout: 15))
        waitForReady(app)
        let prompt = app.staticTexts["world-quest-prompt"].label
        XCTAssertTrue(prompt.hasPrefix("Find "))
        XCTAssertTrue(map.label.contains("Location in"))
        XCTAssertFalse(map.label.contains("United States"), "Initial candidate name must stay hidden")
        screenshot("World Quest unlabeled map")
        XCUIRemote.shared.press(.select)
        // The neutral start may or may not be the target; either branch must remain playable.
        if app.buttons["world-quest-next"].exists {
            XCUIRemote.shared.press(.select)
            waitForReady(app)
        }
        focusToolbar(app)
        focusRight(app.buttons["world-quest-reveal"])
        XCUIRemote.shared.press(.select)
        XCTAssertTrue(app.buttons["world-quest-next"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["world-quest-feedback"].label.hasPrefix("Here is "))
        screenshot("World Quest answer reveal")
        waitForFocus(app.buttons["world-quest-next"])
        XCUIRemote.shared.press(.select)
        waitForReady(app)
        XCTAssertTrue(app.staticTexts["world-quest-prompt"].label.hasPrefix("Find "))
        XCUIRemote.shared.press(.playPause)
        XCTAssertFalse(app.buttons["world-quest-next"].exists)
        XCUIRemote.shared.press(.menu)
        let launcher = app.buttons["tv-mode-worldQuest"]
        XCTAssertTrue(launcher.waitForExistence(timeout: 10))
        waitForFocus(launcher)
    }

    func testTimedCountdownRevealAndInterruptionResume() {
        let app = launchQuest()
        // Start is focused. Its upward neighbor is Explore; move to Timed.
        XCUIRemote.shared.press(.up)
        let explore = app.buttons["world-quest-mode-Explore"]
        waitForFocus(explore)
        XCUIRemote.shared.press(.right)
        XCUIRemote.shared.press(.right)
        let timed = app.buttons["world-quest-mode-Timed"]
        waitForFocus(timed)
        XCUIRemote.shared.press(.select)
        XCUIRemote.shared.press(.down)
        if !app.buttons["world-quest-start"].hasFocus { XCUIRemote.shared.press(.left) }
        waitForFocus(app.buttons["world-quest-start"])
        XCUIRemote.shared.press(.select)
        XCTAssertTrue(app.staticTexts["world-quest-timer"].waitForExistence(timeout: 10))
        // Interrupt the initial spoken prompt, before the answer clock starts.
        XCUIDevice.shared.press(.home)
        XCTAssertTrue(app.wait(for: .runningBackground, timeout: 10))
        app.activate()
        let resume = app.buttons["world-quest-resume"]
        XCTAssertTrue(resume.waitForExistence(timeout: 10))
        waitForFocus(resume)
        screenshot("World Quest paused after interruption")
        let paused = app.staticTexts["world-quest-timer"].label
        XCUIRemote.shared.press(.playPause)
        XCTAssertEqual(app.staticTexts["world-quest-timer"].label, paused)
        XCUIRemote.shared.press(.select)
        XCTAssertTrue(app.buttons["world-quest-next"].waitForExistence(timeout: 35))
        XCTAssertEqual(app.staticTexts["world-quest-timer"].label, "0s")
        screenshot("World Quest timed answer revealed")
    }

    func testExploreAndRegionalZoom() {
        let app = launchQuest()
        XCUIRemote.shared.press(.up)
        waitForFocus(app.buttons["world-quest-mode-Explore"])
        XCUIRemote.shared.press(.select)
        XCUIRemote.shared.press(.down)
        waitForFocus(app.buttons["world-quest-start"])
        XCUIRemote.shared.press(.select)
        let map = app.buttons["world-quest-map"]
        XCTAssertTrue(map.waitForExistence(timeout: 10))
        XCTAssertFalse(app.staticTexts["world-quest-prompt"].label.hasPrefix("Find "))
        XCUIRemote.shared.press(.select)
        XCTAssertTrue(app.staticTexts["world-quest-feedback"].label.contains(" is in "))
        focusToolbar(app)
        XCUIRemote.shared.press(.right)
        waitForFocus(app.buttons["world-quest-zoom-Region"])
        XCUIRemote.shared.press(.select)
        waitForFocus(map)
        screenshot("World Quest regional exploration and overview")
        XCUIRemote.shared.press(.right)
        XCUIRemote.shared.press(.select)
        XCTAssertFalse(map.label.hasPrefix("Find "))
        XCUIRemote.shared.press(.menu)
        waitForFocus(app.buttons["tv-mode-worldQuest"])
    }

    func testTenCorrectLocationsCompletePassportAndReplay() {
        let app = launchQuest()
        XCUIRemote.shared.press(.select)
        // Shortest geographic routes from the fixed neutral USA focus in Starter.
        let routes: [String: [XCUIRemote.Button]] = [
            "United States": [], "Canada": [.up], "Brazil": [.down],
            "United Kingdom": [.up, .right], "South Africa": [.down, .down],
            "France": [.up, .right, .down], "Egypt": [.down, .down, .up],
            "Australia": [.down, .down, .right], "Italy": [.up, .right, .down, .down],
            "India": [.down, .down, .up, .right], "Japan": [.down, .down, .right, .up],
            "China": [.down, .down, .up, .right, .up]
        ]
        for _ in 0..<10 {
            waitForReady(app)
            let prompt = app.staticTexts["world-quest-prompt"].label
            let name = String(prompt.dropFirst("Find ".count).dropLast())
            guard let route = routes[name] else { XCTFail("Unknown target: \(prompt)"); return }
            for direction in route { XCUIRemote.shared.press(direction) }
            XCUIRemote.shared.press(.select)
            let next = app.buttons["world-quest-next"]
            XCTAssertTrue(next.waitForExistence(timeout: 5))
            XCTAssertTrue(app.staticTexts["world-quest-feedback"].label.contains("You found"))
            waitForFocus(next)
            XCUIRemote.shared.press(.select)
        }
        XCTAssertTrue(app.buttons["world-quest-replay"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.staticTexts["world-quest-passport"].exists)
        screenshot("World Quest completed passport")
        waitForFocus(app.buttons["world-quest-replay"])
        XCUIRemote.shared.press(.select)
        waitForFocus(app.buttons["world-quest-start"])
    }

    private func launchQuest() -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["-feature.worldQuestEnabled", "YES", "-worldQuest.seed", "42"]
        app.launch()
        waitForFocus(app.buttons["tv-mode-memory"])
        XCUIRemote.shared.press(.right)
        XCUIRemote.shared.press(.right)
        XCUIRemote.shared.press(.down)
        waitForFocus(app.buttons["tv-mode-worldQuest"])
        XCUIRemote.shared.press(.select)
        waitForFocus(app.buttons["world-quest-start"])
        return app
    }

    private func waitForReady(_ app: XCUIApplication) {
        // Initial prompt speech is deliberately excluded from response time.
        // Wait for the real synth rather than a test-only fast timer.
        let ready = NSPredicate { _, _ in
            let timer = app.staticTexts["world-quest-timer"]
            return !timer.exists || timer.label != "20s"
        }
        if app.staticTexts["world-quest-timer"].exists {
            XCTAssertEqual(XCTWaiter.wait(for: [XCTNSPredicateExpectation(predicate: ready, object: nil)], timeout: 25), .completed)
        } else {
            // In practice readiness is exposed through the map's enabled state.
            let map = app.buttons["world-quest-map"]
            XCTAssertTrue(map.waitForExistence(timeout: 10))
            XCTAssertEqual(XCTWaiter.wait(for: [XCTNSPredicateExpectation(predicate: NSPredicate(format: "value == %@", "Ready"), object: map)], timeout: 25), .completed)
        }
    }

    private func focusToolbar(_ app: XCUIApplication) {
        let world = app.buttons["world-quest-zoom-World"]
        for _ in 0..<20 {
            if world.hasFocus { return }
            XCUIRemote.shared.press(.up)
        }
        waitForFocus(world)
    }

    private func focusRight(_ element: XCUIElement) {
        for _ in 0..<8 {
            if element.hasFocus { return }
            XCUIRemote.shared.press(.right)
        }
        waitForFocus(element)
    }

    private func waitForFocus(_ element: XCUIElement) {
        XCTAssertTrue(element.exists || element.waitForExistence(timeout: 20))
        if !element.hasFocus {
            XCTAssertEqual(XCTWaiter.wait(for: [XCTNSPredicateExpectation(predicate: NSPredicate(format: "hasFocus == true"), object: element)], timeout: 10), .completed)
        }
    }

    private func screenshot(_ name: String) {
        let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
