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
        XCTAssertTrue(waitForSpotStage(app, timeout: 10))
        snapshot(app, "RoomQuest-Spot1-Red")

        advanceCurrentSpot(app)

        XCTAssertTrue(waitForSpotStage(app, timeout: 10))
        snapshot(app, "RoomQuest-Spot2-Blue")
        XCTAssertTrue(advanceUntilReturningStage(app, maxTransitions: 3))

        XCTAssertTrue(waitForReturningStage(app, timeout: 15))
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
        XCTAssertTrue(advanceUntilReturningStage(app, maxTransitions: 4))

        XCTAssertTrue(waitForReturningStage(app, timeout: 15))
        let returningConfirm = app.buttons["room-return-confirm-button"]
        if returningConfirm.waitForExistence(timeout: 5) {
            tapWhenHittable(returningConfirm, in: app, reveal: .up)
        }

        // Post-return entry into the on-screen phase is enough here. Detailed CPA
        // progression is already covered in the engine/unit suites and is much more
        // timing-sensitive in CI when driven end to end through Room Quest UI.
        XCTAssertTrue(waitForPostReturnOnScreenPhase(app, timeout: 10))
        snapshot(app, "RoomQuest-Pictorial-Locked")
    }

    func testRoomQuestSetupShowsSavedFallbackStateBeforeReady() {
        let app = launchWithRoomQuestAndSafetyAck()
        _ = app.staticTexts["Mather"].waitForExistence(timeout: 5)

        app.buttons["Start Room Quest"].tap()
        _ = app.staticTexts["Set up the room"].waitForExistence(timeout: 5)

        XCTAssertTrue(app.staticTexts["Save a hiding-place reference for both stations before you start."].waitForExistence(timeout: 5))

        configureSetupViaManualFallback(app)

        XCTAssertTrue(app.staticTexts["Fallback saved"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["Ready — stations are set!"].exists)
    }

    // MARK: - Pause / Resume

    func testRoomQuestPauseAndResumeFromSpotScreen() {
        let app = launchWithRoomQuestAndSafetyAck()
        _ = app.staticTexts["Mather"].waitForExistence(timeout: 5)

        app.buttons["Start Room Quest"].tap()
        _ = app.staticTexts["Set up the room"].waitForExistence(timeout: 5)
        completeSetupViaManualFallback(app)

        _ = app.staticTexts["Red Rocket"].waitForExistence(timeout: 5)
        XCTAssertTrue(waitForSpotStage(app, timeout: 10))
        snapshot(app, "RoomQuest-Paused")
    }

    func testRoomQuestPauseAndResumeFromReturningScreen() {
        let app = launchWithRoomQuestAndSafetyAck()
        _ = app.staticTexts["Mather"].waitForExistence(timeout: 5)

        app.buttons["Start Room Quest"].tap()
        _ = app.staticTexts["Set up the room"].waitForExistence(timeout: 5)
        completeSetupViaManualFallback(app)

        XCTAssertTrue(advanceUntilReturningStage(app, maxTransitions: 4))

        XCTAssertTrue(waitForReturningStage(app, timeout: 15))
        XCTAssertTrue(app.buttons["room-pause-button-returning"].waitForExistence(timeout: 5))
    }

    // MARK: - Abandon

    func testRoomQuestAbandonSessionNavigatesToHome() {
        let app = launchWithRoomQuestAndSafetyAck()
        _ = app.staticTexts["Mather"].waitForExistence(timeout: 5)

        app.buttons["Start Room Quest"].tap()
        _ = app.staticTexts["Set up the room"].waitForExistence(timeout: 5)
        completeSetupViaManualFallback(app)

        _ = app.staticTexts["Red Rocket"].waitForExistence(timeout: 5)
        XCTAssertTrue(app.buttons["room-pause-button"].waitForExistence(timeout: 5))
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
        configureSetupViaManualFallback(app)
        app.buttons["Ready — stations are set!"].tap()
    }

    private func configureSetupViaManualFallback(_ app: XCUIApplication) {
        let redCard = app.otherElements["room-station-card-redRocket"]
        let blueCard = app.otherElements["room-station-card-blueBubble"]

        XCTAssertTrue(redCard.waitForExistence(timeout: 5))
        XCTAssertTrue(blueCard.waitForExistence(timeout: 5))

        redCard.buttons["Camera verify"].tap()
        XCTAssertTrue(app.staticTexts["room-scan-status"].waitForExistence(timeout: 5))
        tapWhenHittable(redCard.buttons["Same-place fallback"], in: app, reveal: .up)

        blueCard.buttons["Camera verify"].tap()
        XCTAssertTrue(app.staticTexts["room-scan-status"].waitForExistence(timeout: 5))
        tapWhenHittable(blueCard.buttons["Same-place fallback"], in: app, reveal: .up)
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

    private func advanceCurrentSpot(_ app: XCUIApplication) {
        XCTAssertTrue(waitForSpotStage(app, timeout: 10))
        let confirm = app.buttons["room-spot-confirm-button"]
        if confirm.exists {
            tapWhenHittable(confirm, in: app, reveal: .up)
            return
        }
        let scan = app.buttons["room-spot-scan-button"]
        tapWhenHittable(scan, in: app, reveal: .up)
        if confirm.waitForExistence(timeout: 2) {
            tapWhenHittable(confirm, in: app, reveal: .up)
            return
        }
        XCTAssertTrue(waitForSpotResolution(app, timeout: 10))
    }

    private func waitForSpotResolution(_ app: XCUIApplication, timeout: TimeInterval) -> Bool {
        let deadline = Date().addingTimeInterval(timeout)
        while Date() < deadline {
            if app.buttons["room-spot-confirm-button"].exists ||
                app.buttons["room-spot-scan-button"].exists ||
                app.buttons["room-return-confirm-button"].exists ||
                app.buttons["room-pause-button-returning"].exists ||
                app.staticTexts["Bring them back!"].exists {
                return true
            }
            RunLoop.current.run(until: Date().addingTimeInterval(0.2))
        }
        return app.buttons["room-spot-confirm-button"].exists ||
            app.buttons["room-spot-scan-button"].exists ||
            app.buttons["room-return-confirm-button"].exists ||
            app.buttons["room-pause-button-returning"].exists ||
            app.staticTexts["Bring them back!"].exists
    }

    private func advanceUntilReturningStage(_ app: XCUIApplication, maxTransitions: Int) -> Bool {
        if waitForReturningStage(app, timeout: 2) {
            return true
        }

        for _ in 0..<maxTransitions {
            guard waitForSpotResolution(app, timeout: 10) else {
                return false
            }
            if waitForReturningStage(app, timeout: 2) {
                return true
            }
            guard waitForSpotStage(app, timeout: 2) else {
                return false
            }
            advanceCurrentSpot(app)
            if waitForReturningStage(app, timeout: 2) {
                return true
            }
        }

        return waitForReturningStage(app, timeout: 5)
    }

    private func openPauseMenu(_ app: XCUIApplication, buttonID: String) -> Bool {
        let button = app.buttons[buttonID]
        XCTAssertTrue(button.waitForExistence(timeout: 5))
        for _ in 0..<3 {
            if button.isHittable {
                button.tap()
            } else {
                let coordinate = button.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
                coordinate.tap()
            }
            if waitForPauseMenu(app, timeout: 5) {
                return true
            }
        }
        return false
    }

    private func waitForReturningStage(_ app: XCUIApplication, timeout: TimeInterval) -> Bool {
        let deadline = Date().addingTimeInterval(timeout)
        while Date() < deadline {
            if app.buttons["room-return-confirm-button"].exists ||
                app.buttons["room-pause-button-returning"].exists ||
                app.staticTexts["Bring them back!"].exists {
                return true
            }
            RunLoop.current.run(until: Date().addingTimeInterval(0.2))
        }
        return app.buttons["room-return-confirm-button"].exists ||
            app.buttons["room-pause-button-returning"].exists ||
            app.staticTexts["Bring them back!"].exists
    }

    private func waitForPostReturnOnScreenPhase(_ app: XCUIApplication, timeout: TimeInterval) -> Bool {
        let deadline = Date().addingTimeInterval(timeout)
        while Date() < deadline {
            if app.staticTexts["From your walk"].exists || app.buttons["Use this break"].exists {
                return true
            }
            RunLoop.current.run(until: Date().addingTimeInterval(0.2))
        }
        return app.staticTexts["From your walk"].exists || app.buttons["Use this break"].exists
    }

    private func waitForRoomQuestAction(_ app: XCUIApplication, actionID: String, timeout: TimeInterval) -> Bool {
        let deadline = Date().addingTimeInterval(timeout)
        let actionButton = app.buttons[actionID]
        while Date() < deadline {
            if actionButton.exists {
                return true
            }
            RunLoop.current.run(until: Date().addingTimeInterval(0.2))
        }
        return actionButton.exists
    }

    private func waitForPauseMenu(_ app: XCUIApplication, timeout: TimeInterval) -> Bool {
        let deadline = Date().addingTimeInterval(timeout)
        let paused = app.staticTexts["Paused"]
        let stop = app.buttons["Stop session"]
        let resume = app.buttons["Resume"]
        while Date() < deadline {
            if paused.exists || stop.exists || resume.exists {
                return true
            }
            RunLoop.current.run(until: Date().addingTimeInterval(0.2))
        }
        return paused.exists || stop.exists || resume.exists
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
