import XCTest

@MainActor
final class CompactLayoutTests: XCTestCase {
    func testAbstractStageSubmitIsReachableWithoutSwipe() {
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

        let pictorialLabel = app.staticTexts.element(matching: NSPredicate(format: "label BEGINSWITH 'Break '"))
        _ = pictorialLabel.waitForExistence(timeout: 10)
        let leftBucketCount = app.staticTexts["0"]
        XCTAssertTrue(leftBucketCount.waitForExistence(timeout: 5), "Expected pictorial stage to start blank instead of prefilled")
        app.buttons["Use this break"].tap()

        let abstractLabel = app.staticTexts["Write it"]
        _ = abstractLabel.waitForExistence(timeout: 10)

        let submitButton = app.buttons["Check equation"]
        _ = submitButton.waitForExistence(timeout: 5)
        XCTAssertTrue(submitButton.isHittable, "Expected abstract-stage submit to be reachable without additional scrolling")
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
