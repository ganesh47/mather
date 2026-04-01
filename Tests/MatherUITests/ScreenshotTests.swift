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
        let app = launch()
        _ = app.staticTexts["Mather"].waitForExistence(timeout: 10)
        enableVS1(app)

        let playButton = app.buttons["Play"]
        _ = playButton.waitForExistence(timeout: 5)
        playButton.tap()
        _ = app.staticTexts["Session setup"].waitForExistence(timeout: 10)
        snapshot(app, "SessionConfig")
    }

    // MARK: - Concrete stage

    func testScreenshot_ConcreteBuildView() {
        let app = launch()
        _ = app.staticTexts["Mather"].waitForExistence(timeout: 10)
        enableVS1(app)

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

    // MARK: - Parent Summary screen

    func testScreenshot_ParentSummary() {
        let app = launch()
        _ = app.staticTexts["Mather"].waitForExistence(timeout: 5)
        app.buttons["Parent Summary"].tap()
        _ = app.waitForExistence(timeout: 3)
        snapshot(app, "ParentSummary")
    }

    // MARK: - Helpers

    /// Launches the app with CI-appropriate flags pre-configured via UserDefaults injection.
    private func launch() -> XCUIApplication {
        continueAfterFailure = false
        let app = XCUIApplication()
        // iOS maps `-key value` launch arguments directly to UserDefaults.standard.
        app.launchArguments = [
            "-feature.audioEnabled", "NO",
            "-feature.hapticsEnabled", "NO",
            "-feature.testModeEnabled", "YES"
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

    /// Attaches a full-screen screenshot to the test result with `.keepAlways` lifetime.
    private func snapshot(_ app: XCUIApplication, _ name: String) {
        let screenshot = XCUIScreen.main.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
