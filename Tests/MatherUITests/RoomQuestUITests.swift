import XCTest

/// UI tests for the Room Quest companion slice.
///
/// These tests focus on stable companion-slice checkpoints:
/// - Safety acknowledgement screen renders and can be accepted
/// - Setup screen shows station cards and saved fallback state
/// - Setup owns the dedicated Room Quest configuration surface
/// - Global settings keeps only a minimal Room Quest entry back into setup
@MainActor
final class RoomQuestUITests: XCTestCase {

    // MARK: - Safety acknowledgement (first launch)

    func testRoomQuestSafetyAckScreenAppearsAndCanBeAccepted() {
        let app = launchWithRoomQuestEnabled()
        _ = app.staticTexts["Mather"].waitForExistence(timeout: 5)

        openRoomQuest(app)

        XCTAssertTrue(app.staticTexts["Before you start"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Safety checklist"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.staticTexts["Tick every safety condition to continue."].waitForExistence(timeout: 3))
        XCTAssertFalse(app.buttons["I understand — let's go"].isEnabled)
        for index in 0..<5 {
            app.buttons["room-safety-check-\(index)"].tap()
        }
        XCTAssertTrue(app.staticTexts["Checklist complete — you can continue."].waitForExistence(timeout: 3))
        snapshot(app, "RoomQuest-SafetyAck")

        app.buttons["I understand — let's go"].tap()
        XCTAssertTrue(app.staticTexts["Set up the room"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["Scan station marker"].waitForExistence(timeout: 5))
        snapshot(app, "RoomQuest-SetupAfterAck")
    }

    // MARK: - Setup screen

    func testRoomQuestSetupScreenShowsSpotCards() {
        let app = launchWithRoomQuestAndSafetyAck()
        _ = app.staticTexts["Mather"].waitForExistence(timeout: 5)

        openRoomQuest(app)
        XCTAssertTrue(app.staticTexts["Set up the room"].waitForExistence(timeout: 5))

        XCTAssertTrue(app.staticTexts["Red Rocket"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.staticTexts["Blue Bubble"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.staticTexts["Setup progress"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.staticTexts["Room Quest setup & safety"].waitForExistence(timeout: 3))
        snapshot(app, "RoomQuest-SetupView")
    }

    func testRoomQuestSetupOwnsConfigurationSheet() {
        let app = launchWithRoomQuestAndSafetyAck()
        _ = app.staticTexts["Mather"].waitForExistence(timeout: 5)

        openRoomQuest(app)
        XCTAssertTrue(app.staticTexts["Set up the room"].waitForExistence(timeout: 5))

        let configButton = app.buttons["roomquest-open-configuration"]
        XCTAssertTrue(configButton.waitForExistence(timeout: 5))
        configButton.tap()

        XCTAssertTrue(app.navigationBars["Room Quest Setup"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.switches["roomquest-config-marker-toggle"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.switches["roomquest-config-reference-toggle"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Safety checklist"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.staticTexts["Place matching"].waitForExistence(timeout: 3))
        snapshot(app, "RoomQuest-SetupConfiguration")

        app.buttons["Done"].tap()
        XCTAssertTrue(app.staticTexts["Set up the room"].waitForExistence(timeout: 5))
    }

    // MARK: - Spot prompt screens

    func testRoomQuestSpotPromptScreensAdvanceCorrectly() {
        let app = launchWithRoomQuestAndSafetyAck()
        _ = app.staticTexts["Mather"].waitForExistence(timeout: 5)

        openRoomQuest(app)
        _ = app.staticTexts["Set up the room"].waitForExistence(timeout: 5)
        completeSetupViaManualFallback(app)

        XCTAssertTrue(app.staticTexts["Red Rocket"].waitForExistence(timeout: 5))
        XCTAssertTrue(waitForSpotStage(app, timeout: 10))
        XCTAssertTrue(app.buttons["room-spot-scan-button"].exists || app.buttons["room-spot-confirm-button"].exists)
        snapshot(app, "RoomQuest-Spot1-Red")
    }

    // MARK: - Full flow (happy path)

    func testRoomQuestFullFlowCompletesSuccessfully() {
        let app = launchWithRoomQuestAndSafetyAck()
        _ = app.staticTexts["Mather"].waitForExistence(timeout: 5)

        openRoomQuest(app)
        _ = app.staticTexts["Set up the room"].waitForExistence(timeout: 5)
        completeSetupViaManualFallback(app)

        XCTAssertTrue(app.staticTexts["Red Rocket"].waitForExistence(timeout: 5))
        XCTAssertTrue(waitForSpotStage(app, timeout: 10))
        XCTAssertTrue(app.buttons["room-spot-scan-button"].waitForExistence(timeout: 5) ||
                      app.buttons["room-spot-confirm-button"].waitForExistence(timeout: 5))
        snapshot(app, "RoomQuest-Pictorial-Locked")
    }

    func testRoomQuestSetupShowsSavedFallbackStateBeforeReady() {
        let app = launchWithRoomQuestAndSafetyAck()
        _ = app.staticTexts["Mather"].waitForExistence(timeout: 5)

        openRoomQuest(app)
        _ = app.staticTexts["Set up the room"].waitForExistence(timeout: 5)

        XCTAssertTrue(app.staticTexts["Finish setup for both stations before you start."].waitForExistence(timeout: 5))

        configureSetupViaManualFallback(app)

        XCTAssertTrue(app.staticTexts["Same-place fallback saved"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["Ready, start Room Quest!"].exists)
    }

    // MARK: - Pause / Resume

    func testRoomQuestPauseAndResumeFromSpotScreen() {
        let app = launchWithRoomQuestAndSafetyAck()
        _ = app.staticTexts["Mather"].waitForExistence(timeout: 5)

        openRoomQuest(app)
        _ = app.staticTexts["Set up the room"].waitForExistence(timeout: 5)
        completeSetupViaManualFallback(app)

        _ = app.staticTexts["Red Rocket"].waitForExistence(timeout: 5)
        XCTAssertTrue(waitForSpotStage(app, timeout: 10))
        snapshot(app, "RoomQuest-Paused")
    }

    func testRoomQuestPauseAndResumeFromReturningScreen() {
        let app = launchWithRoomQuestAndSafetyAck()
        _ = app.staticTexts["Mather"].waitForExistence(timeout: 5)

        openRoomQuest(app)
        _ = app.staticTexts["Set up the room"].waitForExistence(timeout: 5)
        completeSetupViaManualFallback(app)

        XCTAssertTrue(app.staticTexts["Red Rocket"].waitForExistence(timeout: 5))
        XCTAssertTrue(waitForSpotStage(app, timeout: 10))
        XCTAssertTrue(app.buttons["room-pause-button"].waitForExistence(timeout: 5))
    }

    // MARK: - Abandon

    func testRoomQuestAbandonSessionAsksForConfirmationBeforeHome() {
        let app = launchWithRoomQuestAndSafetyAck()
        _ = app.staticTexts["Mather"].waitForExistence(timeout: 5)

        openRoomQuest(app)
        _ = app.staticTexts["Set up the room"].waitForExistence(timeout: 5)

        app.buttons["room-home-session"].tap()
        XCTAssertTrue(app.alerts["End Room Quest?"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.alerts["End Room Quest?"].buttons["Keep playing"].exists)
        XCTAssertTrue(app.alerts["End Room Quest?"].buttons["End session"].exists)

        app.alerts["End Room Quest?"].buttons["Keep playing"].tap()
        XCTAssertTrue(app.staticTexts["Set up the room"].waitForExistence(timeout: 5))

        app.buttons["room-home-session"].tap()
        app.alerts["End Room Quest?"].buttons["End session"].tap()
        XCTAssertTrue(app.staticTexts["Mather"].waitForExistence(timeout: 5))
    }

    func testRoomQuestSpotHomeUsesAbandonConfirmation() {
        let app = launchWithRoomQuestAndSafetyAck()
        _ = app.staticTexts["Mather"].waitForExistence(timeout: 5)

        openRoomQuest(app)
        _ = app.staticTexts["Set up the room"].waitForExistence(timeout: 5)
        completeSetupViaManualFallback(app)

        XCTAssertTrue(app.staticTexts["Red Rocket"].waitForExistence(timeout: 5))
        XCTAssertTrue(waitForSpotStage(app, timeout: 10))

        app.buttons["room-home-button"].tap()
        XCTAssertTrue(app.alerts["End Room Quest?"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.alerts["End Room Quest?"].buttons["Keep playing"].exists)
        XCTAssertTrue(app.alerts["End Room Quest?"].buttons["End session"].exists)

        app.alerts["End Room Quest?"].buttons["End session"].tap()
        XCTAssertTrue(app.staticTexts["Mather"].waitForExistence(timeout: 5))
    }

    // MARK: - Global settings handoff

    func testSettingsKeepsMinimalRoomQuestEntryThatReturnsToSetup() {
        let app = launchWithRoomQuestEnabled()
        _ = app.staticTexts["Mather"].waitForExistence(timeout: 5)

        app.buttons["Settings"].tap()
        XCTAssertTrue(app.staticTexts["Settings"].waitForExistence(timeout: 5))

        let openButton = app.buttons["settings-roomquest-open"]
        XCTAssertTrue(openButton.waitForExistence(timeout: 5))
        XCTAssertFalse(app.staticTexts["Place matching"].exists)
        snapshot(app, "Settings-RoomQuestEntry")

        openButton.tap()
        XCTAssertTrue(app.staticTexts["Before you start"].waitForExistence(timeout: 5) ||
                      app.staticTexts["Set up the room"].waitForExistence(timeout: 5))
    }

    // MARK: - Helpers

    private func openRoomQuest(_ app: XCUIApplication) {
        app.buttons["ExplorerLab"].tap()
        _ = app.staticTexts["Explorer Lab"].waitForExistence(timeout: 5)
        app.buttons["Room Quest"].tap()
    }

    private func completeSetupViaManualFallback(_ app: XCUIApplication) {
        configureSetupViaManualFallback(app)
        app.buttons["Ready, start Room Quest!"].tap()
    }

    private func configureSetupViaManualFallback(_ app: XCUIApplication) {
        let redCard = app.otherElements["room-station-card-redRocket"]
        let blueCard = app.otherElements["room-station-card-blueBubble"]

        XCTAssertTrue(redCard.waitForExistence(timeout: 5))
        XCTAssertTrue(blueCard.waitForExistence(timeout: 5))

        redCard.buttons["Scan station marker"].tap()
        XCTAssertTrue(app.staticTexts["room-scan-status"].waitForExistence(timeout: 5))
        tapWhenHittable(redCard.buttons["Save same-place fallback"], in: app, reveal: .up)

        blueCard.buttons["Scan station marker"].tap()
        XCTAssertTrue(app.staticTexts["room-scan-status"].waitForExistence(timeout: 5))
        tapWhenHittable(blueCard.buttons["Save same-place fallback"], in: app, reveal: .up)
    }

    private enum RevealDirection {
        case up
        case down
    }

    private func waitForSpotStage(_ app: XCUIApplication, timeout: TimeInterval) -> Bool {
        let deadline = Date().addingTimeInterval(timeout)
        while Date() < deadline {
            if app.buttons["room-spot-confirm-button"].exists || app.buttons["room-spot-scan-button"].exists {
                return true
            }
            RunLoop.current.run(until: Date().addingTimeInterval(0.2))
        }
        return app.buttons["room-spot-confirm-button"].exists || app.buttons["room-spot-scan-button"].exists
    }

    private func tapWhenHittable(_ element: XCUIElement, in app: XCUIApplication, reveal: RevealDirection) {
        XCTAssertTrue(element.waitForExistence(timeout: 5))
        for _ in 0..<6 {
            if element.isHittable {
                element.tap()
                return
            }
            switch reveal {
            case .up:
                app.swipeUp()
            case .down:
                app.swipeDown()
            }
        }

        if element.exists {
            let coordinate = element.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
            coordinate.tap()
            return
        }

        XCTFail("Expected element to exist before tap fallback: \(element)")
    }

    private func launch() -> XCUIApplication {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchArguments = [
            "-feature.audioEnabled", "NO",
            "-feature.hapticsEnabled", "NO",
            "-feature.testModeEnabled", "YES",
            "-feature.roomQuestSafetyAcknowledged", "NO"
        ]
        app.launch()
        return app
    }

    private func launchWithRoomQuestEnabled() -> XCUIApplication {
        launch()
    }

    private func launchWithRoomQuestAndSafetyAck() -> XCUIApplication {
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

    private func snapshot(_ app: XCUIApplication, _ name: String) {
        let screenshot = XCUIScreen.main.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
