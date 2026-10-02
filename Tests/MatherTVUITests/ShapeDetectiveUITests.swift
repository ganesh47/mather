import XCTest

@MainActor
final class ShapeDetectiveUITests: XCTestCase {
    override func setUpWithError() throws { continueAfterFailure = false }

    func testRetrySevenCluesFreshProbeAndCalmFiniteEnding() {
        let app = launch(reset: true)
        XCTAssertTrue(app.buttons["tv-shape-choice-A"].label.contains("Three straight sides"))
        screenshot("Shape clue with descriptive accessible choices")
        XCUIRemote.shared.press(.select) // A is a triangle; the first clue asks for no corners.
        XCTAssertTrue(app.staticTexts["Keep investigating"].exists)
        XCTAssertTrue(app.buttons["tv-shape-choice-B"].isEnabled)
        XCTAssertFalse(app.buttons["tv-shape-next"].exists)
        screenshot("Wrong choice gives a property hint and leaves choices open")
        for (index, letter) in ["B", "D", "C", "A", "B", "C", "C"].enumerated() {
            selectChoice(letter, app: app)
            waitFocus(app.buttons["tv-shape-next"])
            if index == 2 {
                XCTAssertTrue(app.staticTexts["tv-shape-feedback"].label.contains("square is also a rectangle"))
                screenshot("Turned square beside non-square rhombus")
            }
            if index == 4 { screenshot("Non-square rhombus properties") }
            if index == 6 { screenshot("New turned thin rectangle probe solved") }
            XCUIRemote.shared.press(.select)
            if index < 6 { waitFocus(app.buttons["tv-shape-choice-A"]) }
        }
        waitFocus(app.buttons["tv-shape-done"])
        XCTAssertTrue(app.staticTexts["tv-shape-summary"].label.contains("6 correct without app hints or retry"))
        XCTAssertTrue(app.staticTexts["tv-shape-summary"].label.contains("1 correct with app support"))
        XCTAssertFalse(app.buttons["tv-shape-next"].exists)
        screenshot("Finite Shape Detective finish")
        XCUIRemote.shared.press(.right)
        waitFocus(app.buttons["tv-shape-room"])
        XCUIRemote.shared.press(.select)
        XCTAssertTrue(app.staticTexts["tv-shape-room-prompt"].exists)
        screenshot("Optional room-object conversation")
        XCUIRemote.shared.press(.menu)
        waitFocus(app.buttons["tv-mode-shapes"])
    }

    func testMenuRelaunchAndForegroundRetainRetryAndHelp() {
        var app = launch(reset: true)
        XCUIRemote.shared.press(.select)
        XCTAssertTrue(app.staticTexts["Keep investigating"].exists)
        XCUIRemote.shared.press(.playPause)
        XCUIRemote.shared.press(.menu)
        waitFocus(app.buttons["tv-mode-shapes"])
        XCUIRemote.shared.press(.select)
        waitFocus(app.buttons["tv-shape-choice-A"])
        XCTAssertTrue(app.staticTexts["Keep investigating"].exists)
        app.terminate()
        app = launch(reset: false)
        XCTAssertTrue(app.staticTexts["Keep investigating"].exists)
        XCUIDevice.shared.press(.home)
        let departed = expectation(for: NSPredicate { _, _ in
            app.state == .runningBackground || app.state == .runningBackgroundSuspended
        }, evaluatedWith: nil)
        wait(for: [departed], timeout: 10)
        app.activate()
        waitFocus(app.buttons["tv-shape-choice-A"])
        selectChoice("B", app: app)
        waitFocus(app.buttons["tv-shape-next"])
        XCTAssertEqual(app.staticTexts["tv-shape-progress"].label, "1 of 7 solved")
        screenshot("Supported retry survives quit relaunch and background")
    }

    func testReducedMotionKeepsRemoteSemanticsAndAccessibleHint() {
        let app = launch(reset: true, reducedMotion: true)
        let a = app.buttons["tv-shape-choice-A"]
        XCTAssertTrue(a.label.contains("Three straight sides and three corners"))
        XCUIRemote.shared.press(.down)
        waitFocus(app.buttons["tv-shape-hint"])
        XCUIRemote.shared.press(.select)
        XCTAssertTrue(app.staticTexts["tv-shape-feedback"].label.contains("Trace the edge"))
        screenshot("Reduced Motion property hint")
        XCUIRemote.shared.press(.up)
        let choiceFocused = expectation(for: NSPredicate { _, _ in
            ["A", "B", "C", "D"].contains { app.buttons["tv-shape-choice-\($0)"].hasFocus }
        }, evaluatedWith: nil)
        wait(for: [choiceFocused], timeout: 10)
        selectChoice("B", app: app)
        waitFocus(app.buttons["tv-shape-next"])
        screenshot("Reduced Motion selected shape and Next focus")
        XCUIRemote.shared.press(.playPause)
        waitFocus(app.buttons["tv-shape-next"])
    }

    private func launch(reset: Bool, reducedMotion: Bool = false) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["-shape-detective-ui-test"] + (reset ? ["-shape-detective-reset-progress"] : []) +
            (reducedMotion ? ["-shape-detective-reduce-motion"] : [])
        app.launch()
        waitFocus(app.buttons["tv-mode-memory"])
        XCUIRemote.shared.press(.down)
        waitFocus(app.buttons["tv-mode-compare"])
        XCUIRemote.shared.press(.right)
        waitFocus(app.buttons["tv-mode-shapes"])
        XCUIRemote.shared.press(.select)
        waitFocus(app.buttons["tv-shape-choice-A"])
        return app
    }

    private func selectChoice(_ letter: String, app: XCUIApplication) {
        let letters = ["A", "B", "C", "D"]
        guard let current = letters.firstIndex(where: { app.buttons["tv-shape-choice-\($0)"].hasFocus }),
              let desired = letters.firstIndex(of: letter) else { XCTFail("A shape must have focus"); return }
        for _ in 0..<abs(desired - current) { XCUIRemote.shared.press(desired > current ? .right : .left) }
        waitFocus(app.buttons["tv-shape-choice-\(letter)"])
        XCUIRemote.shared.press(.select)
    }

    private func waitFocus(_ element: XCUIElement) {
        XCTAssertTrue(element.waitForExistence(timeout: 15))
        let focused = expectation(for: NSPredicate(format: "hasFocus == true"), evaluatedWith: element)
        wait(for: [focused], timeout: 10)
    }

    private func screenshot(_ name: String) {
        let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        attachment.name = name; attachment.lifetime = .keepAlways; add(attachment)
    }
}
