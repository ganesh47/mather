import XCTest

/// UI-level screenshot tests that capture key screens of the Mather app.
///
/// These tests navigate through the main user flows and attach full-screen
/// PNG screenshots to the test result bundle. CI extracts and uploads them
/// as workflow artifacts so visual regressions are visible in the Actions tab.
///
/// Note: setUp/tearDown are intentionally not overridden. Swift 6 strict
/// concurrency does not allow @MainActor overrides of the nonisolated
/// XCTestCase lifecycle methods. Instead, each test creates its app
/// via `launch()` and takes ownership of teardown implicitly.
@MainActor
final class ScreenshotTests: XCTestCase {

    // MARK: - Home screen

    func testScreenshot_Home_VS1Disabled() {
        let app = launch()
        _ = app.staticTexts["Mather"].waitForExistence(timeout: 5)
        snapshot(app, "Home-VS1Disabled")
    }

    // MARK: - Settings screen

    func testScreenshot_Settings_EnableVS1() {
        let app = launch()
        _ = app.staticTexts["Mather"].waitForExistence(timeout: 5)

        app.buttons["Settings"].tap()
        _ = app.staticTexts["Settings"].waitForExistence(timeout: 3)
        snapshot(app, "Settings-BeforeEnableVS1")

        let vs1Toggle = app.switches["Make & Break to 10"]
        if vs1Toggle.waitForExistence(timeout: 3) {
            vs1Toggle.tap()
        }
        snapshot(app, "Settings-AfterEnableVS1")

        app.buttons["Home"].tap()
        _ = app.staticTexts["Mather"].waitForExistence(timeout: 3)
        snapshot(app, "Home-VS1Enabled")
    }

    // MARK: - Session Config screen

    func testScreenshot_SessionConfig() {
        // Pre-enable VS1 via launch argument to skip Settings navigation.
        let app = launchWithVS1()
        _ = app.staticTexts["Mather"].waitForExistence(timeout: 10)

        let playButton = app.buttons["Play"]
        _ = playButton.waitForExistence(timeout: 5)
        playButton.tap()
        _ = app.staticTexts["Session setup"].waitForExistence(timeout: 10)
        snapshot(app, "SessionConfig")
    }

    // MARK: - Concrete stage

    func testScreenshot_ConcreteBuildView() {
        // Pre-enable VS1 via launch argument to skip Settings navigation.
        // This test runs first alphabetically and bears cold-start overhead;
        // removing the enableVS1() round-trip keeps it within CI time budget.
        let app = launchWithVS1()
        _ = app.staticTexts["Mather"].waitForExistence(timeout: 10)

        let playButton = app.buttons["Play"]
        _ = playButton.waitForExistence(timeout: 5)
        playButton.tap()
        _ = app.staticTexts["Session setup"].waitForExistence(timeout: 10)

        let startButton = app.buttons["Start Session"]
        _ = startButton.waitForExistence(timeout: 5)
        startButton.tap()

        let makePredicate = NSPredicate(format: "label BEGINSWITH 'Make '")
        _ = app.staticTexts.element(matching: makePredicate).waitForExistence(timeout: 15)
        snapshot(app, "ConcreteBuild-Initial")
    }

    // MARK: - Haptics / feedback flow

    /// Exercises the failure-then-success path so the screen recording captures
    /// both the failure feedback banner and the celebration state.
    func testScreenshot_ConcreteBuild_FailureThenSuccess() {
        let app = launchWithVS1AndHaptics()
        _ = app.staticTexts["Mather"].waitForExistence(timeout: 10)

        let playButton = app.buttons["Play"]
        _ = playButton.waitForExistence(timeout: 5)
        playButton.tap()
        _ = app.staticTexts["Session setup"].waitForExistence(timeout: 10)

        let startButton = app.buttons["Start Session"]
        _ = startButton.waitForExistence(timeout: 5)
        startButton.tap()

        let makePredicate = NSPredicate(format: "label BEGINSWITH 'Make '")
        _ = app.staticTexts.element(matching: makePredicate).waitForExistence(timeout: 15)
        snapshot(app, "ConcreteBuild-BeforeInput")

        // Submit with count at 0 to trigger failure feedback
        let submitPredicate = NSPredicate(format: "label BEGINSWITH 'That is '")
        let submitButton = app.buttons.element(matching: submitPredicate)
        _ = submitButton.waitForExistence(timeout: 5)
        submitButton.tap()
        snapshot(app, "ConcreteBuild-FailureFeedback")

        // Fill the deterministic target of 6 with the current two-row concrete model:
        // five warm counters on the top row plus one accent counter on the bottom row.
        let warmRowLastCell = app.otherElements["counter-cell-4"]
        if !warmRowLastCell.waitForExistence(timeout: 3) {
            app.scrollViews.firstMatch.swipeUp()
        }
        _ = warmRowLastCell.waitForExistence(timeout: 5)
        warmRowLastCell.tap()
        let accentRowFirstCell = app.otherElements["counter-cell-5"]
        _ = accentRowFirstCell.waitForExistence(timeout: 5)
        accentRowFirstCell.tap()
        submitButton.tap()

        // After a correct answer the stage advances to pictorial — wait for it
        let breakPredicate = NSPredicate(format: "label BEGINSWITH 'Break '")
        _ = app.staticTexts.element(matching: breakPredicate).waitForExistence(timeout: 10)
        snapshot(app, "Pictorial-AfterConcreteSuccess")
    }

    func testConcreteBuild_AccentRowDoesNotFillWarmRow() {
        let app = launchWithVS1()
        _ = app.staticTexts["Mather"].waitForExistence(timeout: 10)

        let playButton = app.buttons["Play"]
        _ = playButton.waitForExistence(timeout: 5)
        playButton.tap()
        _ = app.staticTexts["Session setup"].waitForExistence(timeout: 10)

        let startButton = app.buttons["Start Session"]
        _ = startButton.waitForExistence(timeout: 5)
        startButton.tap()

        let makePredicate = NSPredicate(format: "label BEGINSWITH 'Make '")
        _ = app.staticTexts.element(matching: makePredicate).waitForExistence(timeout: 15)

        let greenCell = app.otherElements["counter-cell-7"]
        _ = greenCell.waitForExistence(timeout: 5)
        greenCell.tap()

        XCTAssertEqual(app.staticTexts["warm-count-label"].label, "0")
        XCTAssertEqual(app.staticTexts["accent-count-label"].label, "3")
    }

    // MARK: - Parent Summary screen

    func testScreenshot_ParentSummary() {
        let app = launch()
        _ = app.staticTexts["Mather"].waitForExistence(timeout: 5)
        app.buttons["Parent Summary"].tap()
        _ = app.staticTexts["Parent Summary"].waitForExistence(timeout: 10)
        snapshot(app, "ParentSummary-Empty")

        // Navigate to Settings from Parent Summary
        let settingsButton = app.buttons["Settings"]
        _ = settingsButton.waitForExistence(timeout: 5)
        settingsButton.tap()
        _ = app.staticTexts["Settings"].waitForExistence(timeout: 10)
        snapshot(app, "Settings-FromParentSummary")

        // Tap clear — confirm dialog should appear
        let clearButton = app.buttons["Clear session history"]
        _ = clearButton.waitForExistence(timeout: 5)
        clearButton.tap()
        _ = app.alerts["Clear all session data?"].waitForExistence(timeout: 5)
        snapshot(app, "Settings-ClearConfirmDialog")

        // Dismiss with Cancel
        app.alerts["Clear all session data?"].buttons["Cancel"].tap()
        snapshot(app, "Settings-AfterCancelClear")
    }

    func testSessionHistoryShowsMultipleSavedSessionsInParentSummaryAndSettings() {
        let app = launchWithSeededHistory(count: 2)
        _ = app.staticTexts["Mather"].waitForExistence(timeout: 5)

        app.buttons["Parent Summary"].tap()
        _ = app.staticTexts["Parent Summary"].waitForExistence(timeout: 10)
        XCTAssertTrue(app.staticTexts["2 saved locally"].waitForExistence(timeout: 5))

        let parentSecond = app.staticTexts["Session 2"].firstMatch
        XCTAssertTrue(parentSecond.waitForExistence(timeout: 5))
        XCTAssertTrue(parentSecond.isHittable)

        app.buttons["Settings"].tap()
        _ = app.staticTexts["Settings"].waitForExistence(timeout: 10)
        XCTAssertTrue(app.staticTexts["2 saved locally"].waitForExistence(timeout: 5))

        let settingsSecond = app.staticTexts["Session 2"].firstMatch
        XCTAssertTrue(settingsSecond.waitForExistence(timeout: 5))
        XCTAssertTrue(settingsSecond.isHittable)
    }

    // MARK: - iPhone layout / pilot runbook

    /// Verifies the full session flow renders without crash and screenshots the
    /// pilot runbook in Settings — covers the M8 smoke-test acceptance criterion.
    func testScreenshot_PilotRunbook() {
        let app = launchWithVS1()
        _ = app.staticTexts["Mather"].waitForExistence(timeout: 10)
        snapshot(app, "iPhone-Home")

        // Navigate to Settings and capture the pilot runbook
        app.buttons["Settings"].tap()
        _ = app.staticTexts["Settings"].waitForExistence(timeout: 10)
        _ = app.staticTexts["Pilot smoke test"].waitForExistence(timeout: 5)
        snapshot(app, "iPhone-Settings-PilotRunbook")
        app.buttons["Home"].tap()

        // Run one full problem to verify no crash on compact layout
        _ = app.buttons["Play"].waitForExistence(timeout: 10)
        app.buttons["Play"].tap()
        _ = app.staticTexts["Session setup"].waitForExistence(timeout: 10)
        snapshot(app, "iPhone-SessionConfig")

        _ = app.buttons["Start Session"].waitForExistence(timeout: 5)
        app.buttons["Start Session"].tap()

        let makePredicate = NSPredicate(format: "label BEGINSWITH 'Make '")
        _ = app.staticTexts.element(matching: makePredicate).waitForExistence(timeout: 15)
        snapshot(app, "iPhone-ConcreteBuild-AdaptiveGrid")

        // Fill the deterministic target of 6 with five warm counters plus one accent counter.
        let warmRowLastCell = app.otherElements["counter-cell-4"]
        if !warmRowLastCell.waitForExistence(timeout: 3) {
            app.scrollViews.firstMatch.swipeUp()
        }
        _ = warmRowLastCell.waitForExistence(timeout: 5)
        warmRowLastCell.tap()
        let accentRowFirstCell = app.otherElements["counter-cell-5"]
        _ = accentRowFirstCell.waitForExistence(timeout: 5)
        accentRowFirstCell.tap()

        let submitPredicate = NSPredicate(format: "label BEGINSWITH 'That is '")
        let submitButton = app.buttons.element(matching: submitPredicate)
        _ = submitButton.waitForExistence(timeout: 5)
        submitButton.tap()

        let breakPredicate = NSPredicate(format: "label BEGINSWITH 'Break '")
        _ = app.staticTexts.element(matching: breakPredicate).waitForExistence(timeout: 10)
        snapshot(app, "iPhone-SplitView")
    }

    // MARK: - Helpers

    /// Launches the app with CI-appropriate flags pre-configured via UserDefaults injection.
    private func launch() -> XCUIApplication {
        continueAfterFailure = false
        let app = XCUIApplication()
        // iOS maps `-key YES/NO` launch arguments to UserDefaults as NSNumber(bool:).
        app.launchArguments = [
            "-feature.audioEnabled", "NO",
            "-feature.hapticsEnabled", "NO",
            "-feature.testModeEnabled", "YES"
        ]
        app.launch()
        return app
    }

    /// Launches with VS1 pre-enabled via launch argument.
    /// Use this instead of launch() + enableVS1() when the test doesn't need
    /// to exercise the Settings toggle flow — it removes 3 screen navigations
    /// from the critical path, which matters for the first (cold) test in CI.
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

    /// Navigates to Settings, enables VS1, returns to Home.
    private func enableVS1(_ app: XCUIApplication) {
        let settingsButton = app.buttons["Settings"]
        _ = settingsButton.waitForExistence(timeout: 5)
        settingsButton.tap()
        _ = app.staticTexts["Settings"].waitForExistence(timeout: 10)
        let toggle = app.switches["Make & Break to 10"]
        if toggle.waitForExistence(timeout: 10), toggle.value as? String == "0" {
            toggle.tap()
        }
        let homeButton = app.buttons["Home"]
        _ = homeButton.waitForExistence(timeout: 5)
        homeButton.tap()
        _ = app.staticTexts["Mather"].waitForExistence(timeout: 10)
    }

    /// Launches with VS1 pre-enabled and haptics on — use for tests that exercise success/failure feedback.
    private func launchWithVS1AndHaptics() -> XCUIApplication {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchArguments = [
            "-feature.audioEnabled", "NO",
            "-feature.hapticsEnabled", "YES",
            "-feature.testModeEnabled", "YES",
            "-feature.verticalSlice1Enabled", "YES"
        ]
        app.launch()
        return app
    }

    private func launchWithSeededHistory(count: Int) -> XCUIApplication {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchArguments = [
            "-feature.audioEnabled", "NO",
            "-feature.hapticsEnabled", "NO",
            "-feature.testModeEnabled", "YES",
            "-uiTest.seedHistory", "\(count)"
        ]
        app.launch()
        return app
    }

    /// Launches with VS1 pre-enabled and Vehicle theme selected via launch argument.
    private func launchWithVehicleTheme() -> XCUIApplication {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchArguments = [
            "-feature.audioEnabled", "NO",
            "-feature.hapticsEnabled", "NO",
            "-feature.testModeEnabled", "YES",
            "-feature.verticalSlice1Enabled", "YES",
            "-feature.selectedThemeId", "vehicle"
        ]
        app.launch()
        return app
    }

    /// Attaches a full-screen screenshot to the test result with `.keepAlways` lifetime.
    private func snapshot(_ app: XCUIApplication, _ name: String) {
        let screenshot = XCUIScreen.main.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
