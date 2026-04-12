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
        concreteSubmit.tap()

        let bondBlastLabel = app.staticTexts["Bond Blast!"]
        _ = bondBlastLabel.waitForExistence(timeout: 10)
        XCTAssertFalse(app.staticTexts["Break It"].exists, "Expected Bond Blast to replace the old Break It title")

        for (left, right) in [(1, 5), (2, 4), (3, 3)] {
            app.buttons["bond-left-\(left)"].tap()
            app.buttons["bond-right-\(right)"].tap()
        }

        let abstractLabel = app.staticTexts["Write it"]
        _ = abstractLabel.waitForExistence(timeout: 10)

        let submitButton = app.buttons["Check equation"]
        _ = submitButton.waitForExistence(timeout: 5)
        XCTAssertTrue(submitButton.isHittable, "Expected abstract-stage submit to be reachable without additional scrolling")

        app.buttons["equation-digit-3"].firstMatch.tap()
        app.buttons["Part 2, ?"].tap()
        app.buttons["equation-digit-3"].firstMatch.tap()
        submitButton.tap()

        let transferLabel = app.staticTexts["Show it"]
        _ = transferLabel.waitForExistence(timeout: 10)
        XCTAssertFalse(app.staticTexts["Show it again"].exists, "Expected old transfer-stage copy to be removed")

        let transferSubmit = app.buttons["Check my groups"]
        _ = transferSubmit.waitForExistence(timeout: 5)
        XCTAssertTrue(transferSubmit.isHittable, "Expected transfer-stage submit to remain reachable without additional scrolling")
    }

    private func launchWithVS1() -> XCUIApplication {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchArguments = [
            "-feature.audioEnabled", "NO",
            "-feature.hapticsEnabled", "NO",
            "-feature.testModeEnabled", "YES",
            "-feature.verticalSlice1Enabled", "YES"
        ]
        app.launch()
        return app
    }
}
