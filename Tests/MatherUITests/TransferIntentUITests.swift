import XCTest

@MainActor
final class TransferIntentUITests: XCTestCase {
    func testTransferScreenKeepsTheEquationVisibleAndExplainsTheIntent() {
        let app = launchWithVS1()
        _ = app.staticTexts["Mather"].waitForExistence(timeout: 10)

        app.buttons["Play"].tap()
        _ = app.staticTexts["Session setup"].waitForExistence(timeout: 10)
        app.buttons["Start Session"].tap()

        let concreteLabel = app.staticTexts.element(matching: NSPredicate(format: "label BEGINSWITH 'Make '"))
        _ = concreteLabel.waitForExistence(timeout: 15)

        let lastCell = app.otherElements["counter-cell-9"]
        if !lastCell.waitForExistence(timeout: 3) {
            app.scrollViews.firstMatch.swipeUp()
        }
        _ = lastCell.waitForExistence(timeout: 5)
        lastCell.tap()

        let concreteSubmit = app.buttons.element(matching: NSPredicate(format: "label BEGINSWITH 'That is '"))
        _ = concreteSubmit.waitForExistence(timeout: 5)
        concreteSubmit.tap()

        let pictorialLabel = app.staticTexts.element(matching: NSPredicate(format: "label BEGINSWITH 'Break '"))
        _ = pictorialLabel.waitForExistence(timeout: 10)
        app.buttons["Use this break"].tap()

        let abstractLabel = app.staticTexts["Write it"]
        _ = abstractLabel.waitForExistence(timeout: 10)

        let partOne = app.buttons.containing(.staticText, identifier: "Part 1").firstMatch
        let partTwo = app.buttons.containing(.staticText, identifier: "Part 2").firstMatch
        _ = partOne.waitForExistence(timeout: 5)
        partOne.tap()
        app.buttons["0"].tap()
        if let targetValue = concreteLabel.label.split(separator: " ").last, let target = Int(targetValue) {
            let rightValue = max(target - 0, 0)
            partTwo.tap()
            app.buttons["\(rightValue)"].tap()
        }
        app.buttons["Check equation"].tap()

        let transferInstruction = app.staticTexts["Show the same equation with counters again."]
        XCTAssertTrue(transferInstruction.waitForExistence(timeout: 10))
        XCTAssertTrue(app.otherElements["transfer-equation"].exists)
        XCTAssertTrue(app.buttons["Check the same equation"].exists)
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
