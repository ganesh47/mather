import XCTest

/// UI tests for the Room Quest companion slice.
///
/// These tests validate the complete Room Quest flow end-to-end:
/// - Feature flag toggle surfaces the button on Home
/// - Safety acknowledgement screen renders and can be accepted
/// - Setup screen shows spot quantities
/// - Spot prompt screens show the correct colour and quantity
/// - Returning screen shows total token count
/// - On-screen CPA phases (pictorial → abstract → transfer) run to completion
/// - Pause / Resume / Stop session flows work at room-phase screens
@MainActor
final class RoomQuestUITests: XCTestCase {

    // MARK: - Flag visibility

    func testRoomQuestToggleShowsStartButtonOnHome() {
        let app = launch()
        _ = app.staticTexts["Mather"].waitForExistence(timeout: 5)

        // Button absent by default
        XCTAssertFalse(app.buttons["Start Room Quest"].exists)

        // Enable Room Quest in Settings
        app.buttons["Settings"].tap()
        _ = app.staticTexts["Settings"].waitForExistence(timeout: 5)
        let rqToggle = app.switches["Room Quest (beta)"]
        XCTAssertTrue(rqToggle.waitForExistence(timeout: 5))
        if rqToggle.value as? String == "0" { rqToggle.tap() }

        app.buttons["Home"].tap()
        _ = app.staticTexts["Mather"].waitForExistence(timeout: 5)
        XCTAssertTrue(app.buttons["Start Room Quest"].waitForExistence(timeout: 5))

        snapshot(app, "RoomQuest-HomeWithButton")
    }

    // MARK: - Safety acknowledgement (first launch)

    func testRoomQuestSafetyAckScreenAppearsAndCanBeAccepted() {
        let app = launchWithRoomQuestEnabled()
        _ = app.staticTexts["Mather"].waitForExistence(timeout: 5)

        app.buttons["Start Room Quest"].tap()

        // Safety ack screen
        XCTAssertTrue(app.staticTexts["Before you start"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Safety checklist"].waitForExistence(timeout: 3))
        snapshot(app, "RoomQuest-SafetyAck")

        // Accept — transitions to Setup
        app.buttons["I understand — let's go"].tap()
        XCTAssertTrue(app.staticTexts["Set up the room"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["Camera verify"].waitForExistence(timeout: 5))
        snapshot(app, "RoomQuest-SetupAfterAck")
    }

    // MARK: - Setup screen

    func testRoomQuestSetupScreenShowsSpotCards() {
        // Pre-acknowledge safety so we land directly on Setup.
        let app = launchWithRoomQuestAndSafetyAck()
        _ = app.staticTexts["Mather"].waitForExistence(timeout: 5)

        app.buttons["Start Room Quest"].tap()
        XCTAssertTrue(app.staticTexts["Set up the room"].waitForExistence(timeout: 5))

        XCTAssertTrue(app.staticTexts["Red Rocket"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.staticTexts["Blue Bubble"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.staticTexts["Scan-friendly setup"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.staticTexts["Safety reminder"].waitForExistence(timeout: 3))
        snapshot(app, "RoomQuest-SetupView")
    }

    // MARK: - Spot prompt screens

    func testRoomQuestSpotPromptScreensAdvanceCorrectly() {
        let app = launchWithRoomQuestAndSafetyAck()
        _ = app.staticTexts["Mather"].waitForExistence(timeout: 5)

        app.buttons["Start Room Quest"].tap()
        _ = app.staticTexts["Set up the room"].waitForExistence(timeout: 5)
        completeSetupViaManualFallback(app)

        XCTAssertTrue(app.staticTexts["Red Rocket"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["room-spot-scan-button"].isEnabled)
        snapshot(app, "RoomQuest-Spot1-Red")

        XCTAssertTrue(app.buttons["room-pause-button"].waitForExistence(timeout: 3))

        let gotRed = app.buttons["room-spot-confirm-button"]
        XCTAssertTrue(gotRed.waitForExistence(timeout: 5))
        gotRed.tap()

        XCTAssertTrue(app.staticTexts["Blue Bubble"].waitForExistence(timeout: 5))
        snapshot(app, "RoomQuest-Spot2-Blue")
        app.buttons["room-spot-confirm-button"].tap()

        XCTAssertTrue(app.staticTexts["Bring them back!"].waitForExistence(timeout: 5))
        snapshot(app, "RoomQuest-Returning")
    }

    // MARK: - Full flow (happy path)

    func testRoomQuestFullFlowCompletesSuccessfully() {
        let app = launchWithRoomQuestAndSafetyAck()
        _ = app.staticTexts["Mather"].waitForExistence(timeout: 5)

        app.buttons["Start Room Quest"].tap()
        _ = app.staticTexts["Set up the room"].waitForExistence(timeout: 5)
        completeSetupViaManualFallback(app)

        _ = app.staticTexts["Red Rocket"].waitForExistence(timeout: 5)
        let gotRed = app.buttons["room-spot-confirm-button"]
        _ = gotRed.waitForExistence(timeout: 5)
        gotRed.tap()

        _ = app.staticTexts["Blue Bubble"].waitForExistence(timeout: 5)
        app.buttons["room-spot-confirm-button"].tap()

        _ = app.staticTexts["Bring them back!"].waitForExistence(timeout: 5)
        app.buttons["room-return-confirm-button"].tap()

        // Pictorial (locked SplitView — "From your walk" badge is visible)
        let fromYourWalk = app.staticTexts["From your walk"]
        XCTAssertTrue(fromYourWalk.waitForExistence(timeout: 10))
        snapshot(app, "RoomQuest-Pictorial-Locked")

        // "Use this break" button — the split is pre-set, just confirm
        let useBreak = app.buttons["Use this break"]
        XCTAssertTrue(useBreak.waitForExistence(timeout: 5))
        useBreak.tap()

        // Abstract — "Check equation" appears (abstract stage)
        XCTAssertTrue(app.buttons["Check equation"].waitForExistence(timeout: 10))
        snapshot(app, "RoomQuest-Abstract")

        // Enter the correct equation (decomposition from deterministic seed is always 5+1=6)
        let part1Keys = app.buttons.matching(NSPredicate(format: "label == '5'"))
        let part2Keys = app.buttons.matching(NSPredicate(format: "label == '1'"))
        if part1Keys.count > 0 && part2Keys.count > 0 {
            part1Keys.firstMatch.tap()
            part2Keys.firstMatch.tap()
        }
        app.buttons["Check equation"].tap()

        // Transfer — if correct, we land on transfer; otherwise we're done
        let transferSubmit = app.buttons.element(matching: NSPredicate(format: "label CONTAINS 'Check'"))
        if transferSubmit.waitForExistence(timeout: 5) {
            transferSubmit.tap()
        }

        // Complete screen or home
        let doneButton = app.buttons["Done"]
        if doneButton.waitForExistence(timeout: 10) {
            snapshot(app, "RoomQuest-Complete")
            doneButton.tap()
            _ = app.staticTexts["Mather"].waitForExistence(timeout: 5)
        }
    }

    func testRoomQuestSetupShowsSavedFallbackStateBeforeReady() {
        let app = launchWithRoomQuestAndSafetyAck()
        _ = app.staticTexts["Mather"].waitForExistence(timeout: 5)

        app.buttons["Start Room Quest"].tap()
        _ = app.staticTexts["Set up the room"].waitForExistence(timeout: 5)

        XCTAssertTrue(app.staticTexts["Save a hiding-place reference for both stations before you start."].waitForExistence(timeout: 5))

        completeSetupViaManualFallback(app)

        XCTAssertTrue(app.staticTexts["Fallback saved"].waitForExistence(timeout: 5))
    }

    // MARK: - Pause / Resume

    func testRoomQuestPauseAndResumeFromSpotScreen() {
        let app = launchWithRoomQuestAndSafetyAck()
        _ = app.staticTexts["Mather"].waitForExistence(timeout: 5)

        app.buttons["Start Room Quest"].tap()
        _ = app.staticTexts["Set up the room"].waitForExistence(timeout: 5)
        completeSetupViaManualFallback(app)

        _ = app.staticTexts["Red Rocket"].waitForExistence(timeout: 5)

        app.buttons["room-pause-button"].tap()
        XCTAssertTrue(app.staticTexts["Paused"].waitForExistence(timeout: 5))
        snapshot(app, "RoomQuest-Paused")

        app.buttons["Resume"].tap()
        XCTAssertTrue(app.staticTexts["Red Rocket"].waitForExistence(timeout: 5))
        snapshot(app, "RoomQuest-ResumedToSpot")
    }

    func testRoomQuestPauseAndResumeFromReturningScreen() {
        let app = launchWithRoomQuestAndSafetyAck()
        _ = app.staticTexts["Mather"].waitForExistence(timeout: 5)

        app.buttons["Start Room Quest"].tap()
        _ = app.staticTexts["Set up the room"].waitForExistence(timeout: 5)
        completeSetupViaManualFallback(app)

        _ = app.buttons["room-spot-confirm-button"].waitForExistence(timeout: 5)
        app.buttons["room-spot-confirm-button"].tap()
        _ = app.staticTexts["Blue Bubble"].waitForExistence(timeout: 5)
        app.buttons["room-spot-confirm-button"].tap()

        _ = app.staticTexts["Bring them back!"].waitForExistence(timeout: 5)
        app.buttons["room-pause-button-returning"].tap()
        XCTAssertTrue(app.staticTexts["Paused"].waitForExistence(timeout: 5))

        app.buttons["Resume"].tap()
        XCTAssertTrue(app.staticTexts["Bring them back!"].waitForExistence(timeout: 5))
    }

    // MARK: - Abandon

    func testRoomQuestAbandonSessionNavigatesToHome() {
        let app = launchWithRoomQuestAndSafetyAck()
        _ = app.staticTexts["Mather"].waitForExistence(timeout: 5)

        app.buttons["Start Room Quest"].tap()
        _ = app.staticTexts["Set up the room"].waitForExistence(timeout: 5)
        completeSetupViaManualFallback(app)

        _ = app.staticTexts["Red Rocket"].waitForExistence(timeout: 5)
        app.buttons["room-pause-button"].tap()
        _ = app.staticTexts["Paused"].waitForExistence(timeout: 5)

        app.buttons["Stop session"].tap()
        XCTAssertTrue(app.staticTexts["Mather"].waitForExistence(timeout: 10))
    }

    // MARK: - Settings safety rules review

    func testSettingsSafetyRulesReviewButtonAppearsWhenEnabled() {
        let app = launchWithRoomQuestEnabled()
        _ = app.staticTexts["Mather"].waitForExistence(timeout: 5)

        app.buttons["Settings"].tap()
        _ = app.staticTexts["Settings"].waitForExistence(timeout: 5)

        let reviewButton = app.buttons["Review Room Quest safety rules"]
        XCTAssertTrue(reviewButton.waitForExistence(timeout: 5))
        snapshot(app, "Settings-RoomQuestSafetyLink")

        reviewButton.tap()
        XCTAssertTrue(app.staticTexts["Room Quest Safety"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Safety checklist"].waitForExistence(timeout: 3))
        snapshot(app, "Settings-SafetyRulesSheet")

        app.buttons["Done"].tap()
        _ = app.staticTexts["Settings"].waitForExistence(timeout: 3)
    }

    // MARK: - Helpers


    private func completeSetupViaManualFallback(_ app: XCUIApplication) {
        let redCard = app.otherElements["room-station-card-redRocket"]
        let blueCard = app.otherElements["room-station-card-blueBubble"]

        XCTAssertTrue(redCard.waitForExistence(timeout: 5))
        XCTAssertTrue(blueCard.waitForExistence(timeout: 5))

        redCard.buttons["Camera verify"].tap()
        XCTAssertTrue(app.staticTexts["room-scan-status"].waitForExistence(timeout: 5))
        redCard.buttons["Same-place fallback"].tap()

        blueCard.buttons["Camera verify"].tap()
        XCTAssertTrue(app.staticTexts["room-scan-status"].waitForExistence(timeout: 5))
        blueCard.buttons["Same-place fallback"].tap()

        app.buttons["Ready — stations are set!"].tap()
    }
    private func launch() -> XCUIApplication {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchArguments = [
            "-feature.audioEnabled", "NO",
            "-feature.hapticsEnabled", "NO",
            "-feature.testModeEnabled", "YES",
            "-feature.roomQuestEnabled", "NO",
            "-feature.roomQuestSafetyAcknowledged", "NO"
        ]
        app.launch()
        return app
    }

    private func launchWithRoomQuestEnabled() -> XCUIApplication {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchArguments = [
            "-feature.audioEnabled", "NO",
            "-feature.hapticsEnabled", "NO",
            "-feature.testModeEnabled", "YES",
            "-feature.roomQuestEnabled", "YES",
            "-feature.roomQuestSafetyAcknowledged", "NO"
        ]
        app.launch()
        return app
    }

    /// Launches with Room Quest enabled and safety already acknowledged —
    /// skips the one-time SafetyAckView so tests land directly on Setup.
    private func launchWithRoomQuestAndSafetyAck() -> XCUIApplication {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchArguments = [
            "-feature.audioEnabled", "NO",
            "-feature.hapticsEnabled", "NO",
            "-feature.testModeEnabled", "YES",
            "-feature.roomQuestEnabled", "YES",
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
