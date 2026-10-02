import XCTest

/// Run using scripts/prepare_learning_companion_qa.sh. No release-root launch hooks needed.
@MainActor
final class LearningCompanionProofUITests: XCTestCase {
    func testParentPreparationObservationAndNoHorizontalOverflow() {
        let app = launch()
        XCTAssertTrue(app.staticTexts["companion-recipient"].waitForExistence(timeout: 10))
        select(app.buttons["companion-build-5"], in: app)
        XCTAssertTrue(app.staticTexts["companion-message"].label.contains("Parent approval"))
        confirmParent(app)
        select(app.buttons["companion-build-5"], in: app)
        XCTAssertTrue(app.buttons["companion-approve"].waitForExistence(timeout: 5))
        snapshot(app, "ParentReview")
        select(app.buttons["companion-approve"], in: app)
        select(app.buttons["companion-start"], in: app)
        XCTAssertTrue(app.staticTexts.containing(NSPredicate(format: "label CONTAINS %@", "App performance: not measured")).firstMatch.exists)
        select(app.buttons["companion-show-picture"], in: app)
        snapshot(app, "PhysicalMissionPicture")
        select(app.buttons["companion-report-withHelp"], in: app)
        XCTAssertTrue(app.staticTexts["companion-observation"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["companion-observation"].label.contains("Parent reported help"))
        assertInsideScreen(app.buttons["companion-parent-controls"], app: app)
        snapshot(app, "ParentObservation")
        #if !os(tvOS)
        select(app.buttons["companion-parent-controls"], in: app)
        select(app.buttons["companion-delete-learner"], in: app)
        let confirmations = app.buttons.matching(identifier: "Confirm deletion")
        XCTAssertTrue(confirmations.firstMatch.waitForExistence(timeout: 5))
        select(confirmations.firstMatch, in: app)
        XCTAssertFalse(app.buttons["companion-start"].exists)
        XCTAssertTrue(app.staticTexts["companion-message"].label.contains("updated"))
        snapshot(app, "ParentDeletion")
        #endif
    }

    #if !os(tvOS)
    func testManualEntryReviewImportReplayAndExportOnCompactPhone() {
        let app = launch()
        confirmParent(app)
        let field = app.textFields["companion-code-field"]
        scrollTo(field, in: app)
        field.tap()
        field.typeText("040GM1-0J6HB7-G4HMAS-W9NF6Y-Y0938N-KR5R80")
        app.swipeUp()
        select(app.buttons["companion-review-code"], in: app)
        select(app.buttons["companion-approve"], in: app)
        select(app.buttons["companion-export"], in: app)
        let code = app.staticTexts["companion-export-code"]
        scrollTo(code, in: app)
        XCTAssertEqual(code.label, "040GM1-0J6HB7-G4HMAS-W9NF6Y-Y0938N-KR5R80")
        assertInsideScreen(code, app: app)
        snapshot(app, "ExportCode")
        select(app.buttons["companion-hide-code"], in: app)
        scrollTo(field, in: app)
        field.tap()
        field.typeText("040GM1-0J6HB7-G4HMAS-W9NF6Y-Y0938N-KR5R80")
        select(app.buttons["companion-review-code"], in: app)
        XCTAssertTrue(app.staticTexts["companion-message"].label.contains("already prepared or received"))
    }
    #else
    func testTVKeyboardRouteIsReachableAndCodeEntryHasFocus() {
        let app = launch()
        confirmParent(app)
        let field = app.textFields["companion-code-field"]
        focus(field, in: app)
        XCTAssertTrue(field.hasFocus)
        assertInsideScreen(field, app: app)
        XCUIRemote.shared.press(.select)
        XCTAssertTrue(app.keyboards.firstMatch.waitForExistence(timeout: 5))
        snapshot(app, "TVKeyboardInput")
        field.typeText("040GM1-0J6HB7-G4HMAS-W9NF6Y-Y0938N-KR5R80")
        XCUIRemote.shared.press(.menu)
        select(app.buttons["companion-review-code"], in: app)
        XCTAssertTrue(app.buttons["companion-approve"].waitForExistence(timeout: 5))
        select(app.buttons["companion-approve"], in: app)
        XCTAssertTrue(app.staticTexts["Current mission: Build 10 in two groups"].exists)
        select(app.buttons["companion-export"], in: app)
        let group = app.staticTexts["companion-code-group-1"]
        XCTAssertTrue(group.waitForExistence(timeout: 5))
        XCTAssertEqual(group.label, "Group 1: 0, 4, 0, G, M, 1")
        snapshot(app, "TVReceivedExportCode")
    }
    #endif

    private func launch() -> XCUIApplication {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchArguments = ["-companion-reset"]
        app.launch()
        return app
    }

    private func confirmParent(_ app: XCUIApplication) {
        #if os(tvOS)
        let toggle = app.switches["companion-parent-confirmation"]
        focus(toggle, in: app)
        XCUIRemote.shared.press(.select)
        #else
        let toggle = app.switches["companion-parent-confirmation"]
        scrollTo(toggle, in: app)
        toggle.tap()
        #endif
    }

    private func select(_ element: XCUIElement, in app: XCUIApplication) {
        #if os(tvOS)
        focus(element, in: app)
        XCUIRemote.shared.press(.select)
        #else
        scrollTo(element, in: app)
        element.tap()
        #endif
    }

    #if os(tvOS)
    private func focus(_ target: XCUIElement, in app: XCUIApplication) {
        XCTAssertTrue(target.waitForExistence(timeout: 5), target.identifier)
        for _ in 0..<60 {
            if target.hasFocus { return }
            let current = app.descendants(matching: .any).matching(NSPredicate(format: "hasFocus == true")).firstMatch
            XCTAssertTrue(current.exists, "No focused control")
            let y = target.frame.midY - current.frame.midY
            let x = target.frame.midX - current.frame.midX
            if abs(y) > 20 { XCUIRemote.shared.press(y > 0 ? .down : .up) }
            else { XCUIRemote.shared.press(x > 0 ? .right : .left) }
        }
        XCTFail("Could not focus \(target.identifier)")
    }
    #else
    private func scrollTo(_ element: XCUIElement, in app: XCUIApplication) {
        XCTAssertTrue(element.waitForExistence(timeout: 5), element.identifier)
        for _ in 0..<12 {
            if element.isHittable, element.frame.minY >= app.frame.minY, element.frame.maxY <= app.frame.maxY - 10 { return }
            if element.frame.minY < app.frame.minY { app.swipeDown() } else { app.swipeUp() }
        }
    }
    #endif

    private func assertInsideScreen(_ element: XCUIElement, app: XCUIApplication) {
        XCTAssertGreaterThanOrEqual(element.frame.minX, app.frame.minX)
        XCTAssertLessThanOrEqual(element.frame.maxX, app.frame.maxX)
    }

    private func snapshot(_ app: XCUIApplication, _ name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "Companion-\(name)"
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
