import XCTest

/// UI-level screenshot tests that capture key screens of the Mather app.
///
/// These tests navigate through the main user flows and attach full-screen
/// PNG screenshots to the test result bundle. CI extracts and uploads them
/// as workflow artifacts so visual regressions are visible in the Actions tab.
///
/// Naming convention: screenshots are named "<ScreenName>-<State>" so they
/// sort predictably in the artifact viewer.
final class ScreenshotTests: XCTestCase {

    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        // Inject UserDefaults flags via launch args. iOS maps `-key value`
        // pairs to UserDefaults.standard automatically at app launch.
        // audioEnabled=NO prevents AVSpeechSynthesizer noise in CI.
        app.launchArguments = [
            "-feature.audioEnabled", "NO",
            "-feature.hapticsEnabled", "NO",
            "-feature.testModeEnabled", "YES"
        ]
        app.launch()
    }

    override func tearDownWithError() throws {
        app = nil
    }

    // MARK: - Home screen

    func testScreenshot_Home_VS1Disabled() {
        // Default state: VS1 flag is off → "Open Settings" CTA
        _ = app.staticTexts["Mather"].waitForExistence(timeout: 5)
        snapshot("Home-VS1Disabled")
    }

    // MARK: - Settings screen

    func testScreenshot_Settings_EnableVS1() {
        _ = app.staticTexts["Mather"].waitForExistence(timeout: 5)

        // Navigate to Settings via the bottom tile
        app.buttons["Settings"].tap()
        _ = app.staticTexts["Settings"].waitForExistence(timeout: 3)
        snapshot("Settings-BeforeEnableVS1")

        // Enable VS1
        let vs1Toggle = app.switches["Enable VS1"]
        if vs1Toggle.waitForExistence(timeout: 3) {
            vs1Toggle.tap()
        }
        snapshot("Settings-AfterEnableVS1")

        // Back to Home
        app.buttons["Home"].tap()
        _ = app.staticTexts["Mather"].waitForExistence(timeout: 3)
        snapshot("Home-VS1Enabled")
    }

    // MARK: - Session Config screen

    func testScreenshot_SessionConfig() throws {
        _ = app.staticTexts["Mather"].waitForExistence(timeout: 5)

        // Enable VS1 via Settings first
        app.buttons["Settings"].tap()
        _ = app.staticTexts["Settings"].waitForExistence(timeout: 3)
        let vs1Toggle = app.switches["Enable VS1"]
        if vs1Toggle.waitForExistence(timeout: 3), vs1Toggle.value as? String == "0" {
            vs1Toggle.tap()
        }
        app.buttons["Home"].tap()
        _ = app.staticTexts["Mather"].waitForExistence(timeout: 3)

        // Tap Play → SessionConfigView
        app.buttons["Play"].tap()
        _ = app.staticTexts["Session setup"].waitForExistence(timeout: 3)
        snapshot("SessionConfig")
    }

    // MARK: - Concrete stage (first activity screen)

    func testScreenshot_ConcreteBuildView() throws {
        _ = app.staticTexts["Mather"].waitForExistence(timeout: 5)

        // Enable VS1 via Settings
        app.buttons["Settings"].tap()
        _ = app.staticTexts["Settings"].waitForExistence(timeout: 3)
        let vs1Toggle = app.switches["Enable VS1"]
        if vs1Toggle.waitForExistence(timeout: 3), vs1Toggle.value as? String == "0" {
            vs1Toggle.tap()
        }
        app.buttons["Home"].tap()
        _ = app.staticTexts["Mather"].waitForExistence(timeout: 3)

        // Navigate into session
        app.buttons["Play"].tap()
        _ = app.staticTexts["Session setup"].waitForExistence(timeout: 3)
        app.buttons["Start Session"].tap()

        // Concrete stage: "Make it" — wait for the large "Make N" heading
        let makePredicate = NSPredicate(format: "label BEGINSWITH 'Make '")
        let makeText = app.staticTexts.element(matching: makePredicate)
        _ = makeText.waitForExistence(timeout: 5)
        snapshot("ConcreteBuild-Initial")
    }

    // MARK: - Parent Summary screen

    func testScreenshot_ParentSummary() {
        _ = app.staticTexts["Mather"].waitForExistence(timeout: 5)
        app.buttons["Parent Summary"].tap()
        _ = app.waitForExistence(timeout: 3)
        snapshot("ParentSummary")
    }

    // MARK: - Helpers

    private func snapshot(_ name: String) {
        let screenshot = XCUIScreen.main.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
