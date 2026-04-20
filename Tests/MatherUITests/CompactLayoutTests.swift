import XCTest

@MainActor
final class CompactLayoutTests: XCTestCase {
    func testVS1CompactFlowShowsUpdatedCopyAndKeepsCoreActionsReachableWithoutSwipe() {
        let app = launchWithVS1()
        _ = app.staticTexts["Mather"].waitForExistence(timeout: 10)

        app.buttons["Play"].tap()
        _ = app.staticTexts["Session setup"].waitForExistence(timeout: 10)

        app.buttons["Start Session"].tap()

        let makeLabel = app.staticTexts.element(matching: NSPredicate(format: "label BEGINSWITH 'Make '"))
        _ = makeLabel.waitForExistence(timeout: 15)

        let warmRowLastCell = app.otherElements["counter-cell-4"]
        if !warmRowLastCell.waitForExistence(timeout: 3) {
            app.scrollViews.firstMatch.swipeUp()
        }
        _ = warmRowLastCell.waitForExistence(timeout: 5)
        warmRowLastCell.tap()

        let accentRowFirstCell = app.otherElements["counter-cell-5"]
        _ = accentRowFirstCell.waitForExistence(timeout: 5)
        accentRowFirstCell.tap()

        let concreteSubmit = app.buttons.element(matching: NSPredicate(format: "label BEGINSWITH 'That is '"))
        _ = concreteSubmit.waitForExistence(timeout: 5)
        XCTAssertTrue(concreteSubmit.isHittable, "Expected concrete-stage submit to remain reachable without additional scrolling")
        concreteSubmit.tap()

        let bondBlastLabel = app.staticTexts["Bond Blast!"]
        _ = bondBlastLabel.waitForExistence(timeout: 10)
        XCTAssertFalse(app.staticTexts["Break It"].exists, "Expected Bond Blast to replace the old Break It title")

        let leftOne = app.buttons["bond-left-1"]
        let rightFive = app.buttons["bond-right-5"]
        _ = leftOne.waitForExistence(timeout: 5)
        _ = rightFive.waitForExistence(timeout: 5)
        XCTAssertTrue(leftOne.isHittable, "Expected Bond Blast actions to be reachable without additional scrolling")
        XCTAssertTrue(rightFive.isHittable, "Expected Bond Blast actions to be reachable without additional scrolling")
    }

    func testRoomQuestCompactSpotScreenKeepsPrimaryActionReachableWithoutSwipe() {
        let app = launch()
        _ = app.staticTexts["Mather"].waitForExistence(timeout: 10)

        openExplorerLab(app)
        app.buttons["Room Quest"].tap()
        _ = app.staticTexts["Set up the room"].waitForExistence(timeout: 10)

        configureRoomQuestSetupViaManualFallback(app)
        app.buttons["Ready, start Room Quest!"].tap()

        XCTAssertTrue(app.staticTexts["Red Rocket"].waitForExistence(timeout: 10))

        let scanButton = app.buttons["room-spot-scan-button"]
        let scanLabelButton = app.buttons["Recheck this place"]
        let fallbackButton = app.buttons["room-spot-confirm-button"]

        let foundPrimaryAction = scanButton.waitForExistence(timeout: 2)
            || scanLabelButton.waitForExistence(timeout: 2)
            || fallbackButton.waitForExistence(timeout: 2)
        XCTAssertTrue(foundPrimaryAction, "Expected a Room Quest primary action to appear on the compact spot screen")

        let visiblePrimaryAction = scanButton.exists ? scanButton : (scanLabelButton.exists ? scanLabelButton : fallbackButton)
        XCTAssertTrue(visiblePrimaryAction.isHittable, "Expected Room Quest primary action to stay reachable without scrolling on compact layouts")
    }

    func testMemoryCompactHeaderKeepsControlsReachableWithoutCrowding() {
        let app = launch()
        _ = app.staticTexts["Mather"].waitForExistence(timeout: 10)

        openExplorerLab(app)
        app.buttons["Memory Match"].tap()
        _ = app.staticTexts["Memory Match"].waitForExistence(timeout: 10)

        let deckMenu = app.buttons["memory-deck-menu"]
        let difficultyMenu = app.buttons["memory-difficulty-menu"]
        XCTAssertTrue(deckMenu.waitForExistence(timeout: 5))
        XCTAssertTrue(difficultyMenu.waitForExistence(timeout: 5))
        XCTAssertTrue(deckMenu.isHittable, "Expected Memory deck control to remain reachable on compact layouts")
        XCTAssertTrue(difficultyMenu.isHittable, "Expected Memory difficulty control to remain reachable on compact layouts")
    }

    private func configureRoomQuestSetupViaManualFallback(_ app: XCUIApplication) {
        let redCard = app.otherElements["room-station-card-redRocket"]
        let blueCard = app.otherElements["room-station-card-blueBubble"]

        XCTAssertTrue(redCard.waitForExistence(timeout: 5))
        XCTAssertTrue(blueCard.waitForExistence(timeout: 5))

        redCard.buttons["Scan station marker"].tap()
        XCTAssertTrue(app.staticTexts["room-scan-status"].waitForExistence(timeout: 5))
        tapWhenHittable(redCard.buttons["Save same-place fallback"], in: app)

        blueCard.buttons["Scan station marker"].tap()
        XCTAssertTrue(app.staticTexts["room-scan-status"].waitForExistence(timeout: 5))
        tapWhenHittable(blueCard.buttons["Save same-place fallback"], in: app)
    }

    private func tapWhenHittable(_ element: XCUIElement, in app: XCUIApplication) {
        XCTAssertTrue(element.waitForExistence(timeout: 5))
        for _ in 0..<6 {
            if element.isHittable {
                element.tap()
                return
            }
            app.swipeUp()
        }
        if element.exists {
            element.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
            return
        }
        XCTFail("Expected element to exist before tap fallback: \(element)")
    }

    private func openExplorerLab(_ app: XCUIApplication) {
        app.buttons["ExplorerLab"].tap()
        _ = app.staticTexts["Explorer Lab"].waitForExistence(timeout: 5)
    }

    private func launch() -> XCUIApplication {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchArguments = [
            "-feature.audioEnabled", "NO",
            "-feature.hapticsEnabled", "NO",
            "-feature.testModeEnabled", "YES",
            "-feature.roomQuestSafetyAcknowledged", "YES"
        ]
        app.launch()
        return app
    }

    private func launchWithVS1() -> XCUIApplication {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchArguments = [
            "-feature.audioEnabled", "NO",
            "-feature.hapticsEnabled", "NO",
            "-feature.testModeEnabled", "YES"
        ]
        app.launch()
        return app
    }
}
