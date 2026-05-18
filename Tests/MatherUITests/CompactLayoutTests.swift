import UIKit
import XCTest

@MainActor
final class CompactLayoutTests: XCTestCase {

    func testIPadHomeRegularLayoutUsesSimpleChildLauncherTiles() throws {
        guard UIDevice.current.userInterfaceIdiom == .pad else {
            throw XCTSkip("iPad regular-layout regression only runs on iPad simulators")
        }

        let app = launchWithVS1()
        XCTAssertTrue(app.staticTexts["Mather"].waitForExistence(timeout: 10))

        XCTAssertTrue(app.buttons["Play"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["ExplorerLab"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["GamesEntry"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["Play"].staticTexts["Targets"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["ExplorerLab"].staticTexts["Labs"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["GamesEntry"].staticTexts["Games"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.staticTexts["Make & Break"].exists, "Home launcher should avoid copy-heavy child tiles")
    }


    func testExplorerLabStreamPickerUsesSimpleReadableCardsOnIPhone() throws {
        guard UIDevice.current.userInterfaceIdiom == .phone else {
            throw XCTSkip("Compact Explorer Lab picker regression only runs on iPhone simulators")
        }

        let app = launchExplorerLab()
        XCTAssertTrue(app.staticTexts["Explorer Lab"].waitForExistence(timeout: 10))
        XCTAssertFalse(app.staticTexts["Pick a stream to explore"].exists)
        XCTAssertFalse(app.staticTexts["Pick a stream"].exists)
        XCTAssertFalse(app.staticTexts["Choose a subject stream first"].exists)

        let numbers = app.buttons["lab-stream-card-numbers"]
        let geometry = app.buttons["lab-stream-card-geometry"]
        XCTAssertTrue(numbers.waitForExistence(timeout: 5))
        XCTAssertTrue(geometry.waitForExistence(timeout: 5))
        XCTAssertTrue(numbers.isHittable, "Expected the first Lab stream card to be reachable on compact iPhone")
        XCTAssertTrue(geometry.isHittable, "Expected the second Lab stream card to be reachable on compact iPhone")
    }

    func testHomeCompactUsesFirstViewportBelowChildTiles() throws {
        guard UIDevice.current.userInterfaceIdiom == .phone else {
            throw XCTSkip("Compact home first-viewport regression only runs on iPhone simulators")
        }

        let app = launchWithVS1()
        XCTAssertTrue(app.staticTexts["Mather"].waitForExistence(timeout: 10))

        let games = app.buttons["GamesEntry"]
        let nextUp = app.buttons["home-child-next-up"]
        let parentControls = app.otherElements["home-parent-controls"]

        XCTAssertTrue(games.waitForExistence(timeout: 5))
        XCTAssertTrue(nextUp.waitForExistence(timeout: 5))
        XCTAssertTrue(parentControls.waitForExistence(timeout: 5))
        XCTAssertTrue(nextUp.isHittable, "Expected child-first next-up action to occupy the compact home lower viewport")
        XCTAssertGreaterThanOrEqual(nextUp.frame.minY, games.frame.maxY, "Expected the lower band to sit after child launcher tiles")
        XCTAssertGreaterThanOrEqual(parentControls.frame.minY, nextUp.frame.maxY, "Expected parent controls to read as secondary controls after child actions")
    }

    func testChildSessionStartSkipsParentUnlockButParentControlsStayLocked() throws {
        let app = launchWithoutParentBypass()
        XCTAssertTrue(app.staticTexts["Mather"].waitForExistence(timeout: 10))

        app.buttons["Play"].tap()
        XCTAssertTrue(app.staticTexts["Session setup"].waitForExistence(timeout: 10))
        XCTAssertFalse(app.staticTexts["Parent unlock"].exists)

        app.buttons["Back to Home"].tap()
        XCTAssertTrue(app.staticTexts["Mather"].waitForExistence(timeout: 10))

        XCTAssertTrue(app.buttons["Settings"].waitForExistence(timeout: 5))
        app.buttons["Settings"].tap()
        let unlockButton = app.buttons["parent-unlock-hold-button"]
        XCTAssertTrue(unlockButton.waitForExistence(timeout: 5))
        unlockButton.press(forDuration: 1.1)
        XCTAssertTrue(app.staticTexts["Settings"].waitForExistence(timeout: 10))
    }

    func testGeometryGuidedPathCardsUseReadableShortActionsOnIPhone() throws {
        guard UIDevice.current.userInterfaceIdiom == .phone else {
            throw XCTSkip("Compact guided path regression only runs on iPhone simulators")
        }

        let app = launchGeometryLane()
        XCTAssertTrue(app.staticTexts["Guided path"].waitForExistence(timeout: 10))

        let shapeCard = app.otherElements["guided-plan-card-geometry-shape-names"]
        let shapeAction = app.buttons["guided-plan-action-geometry-shape-names"]
        XCTAssertTrue(shapeCard.waitForExistence(timeout: 5))
        XCTAssertTrue(shapeAction.waitForExistence(timeout: 5))
        XCTAssertTrue(shapeAction.staticTexts["Start"].exists, "Expected guided path CTA to use short visible copy")
        XCTAssertGreaterThanOrEqual(shapeAction.frame.height, 44, "Expected guided path CTA to keep a 44 pt hit target")
        XCTAssertGreaterThanOrEqual(shapeAction.frame.width, 44, "Expected guided path CTA to keep a 44 pt hit target")
        XCTAssertTrue(shapeAction.label.contains("Start Shape Lab"), "Expected the accessibility label to keep the full guided path context")
    }

    func testBondBlastTargetTwelveKeepsLowAndMiddlePairsReachableOnIPhone() throws {
        guard UIDevice.current.userInterfaceIdiom == .phone else {
            throw XCTSkip("Compact Bond Blast reachability regression only runs on iPhone simulators")
        }

        let app = launchBondBlastFinale(target: 12)
        XCTAssertTrue(app.staticTexts["Bond Blast!"].waitForExistence(timeout: 10))

        let firstLeft = app.buttons["bond-left-1"]
        let firstRight = app.buttons["bond-right-11"]
        XCTAssertTrue(firstLeft.waitForExistence(timeout: 5))
        XCTAssertTrue(firstLeft.isHittable, "Expected the first target-12 Bond Blast source card to be reachable")
        firstLeft.tap()
        XCTAssertTrue(firstRight.waitForExistence(timeout: 5))
        XCTAssertTrue(firstRight.isHittable, "Expected 1 + 11 target-12 match to be reachable")

        let finalLeft = app.buttons["bond-left-6"]
        let finalRight = app.buttons["bond-right-6"]
        if !finalLeft.isHittable || !finalRight.isHittable {
            app.scrollViews.firstMatch.swipeUp()
        }
        XCTAssertTrue(finalLeft.waitForExistence(timeout: 5))
        XCTAssertTrue(finalLeft.isHittable, "Expected the bottom target-12 Bond Blast source card to be reachable after the in-card scroll")
        finalLeft.tap()
        XCTAssertTrue(finalRight.waitForExistence(timeout: 5))
        XCTAssertTrue(finalRight.isHittable, "Expected 6 + 6 target-12 match to be reachable after the in-card scroll")
    }

    func testGravitySplitSuccessCTAIsVisibleAndAdvancesOnIPhone() throws {
        guard UIDevice.current.userInterfaceIdiom == .phone else {
            throw XCTSkip("Compact Gravity Split CTA regression only runs on iPhone simulators")
        }

        let app = launchWithVS1()
        XCTAssertTrue(app.staticTexts["Mather"].waitForExistence(timeout: 10))

        app.buttons["Play"].tap()
        XCTAssertTrue(app.staticTexts["Session setup"].waitForExistence(timeout: 10))
        app.buttons["Start Session"].tap()
        advanceStoryAnchorIfPresent(app)

        XCTAssertTrue(app.buttons["That is 6"].waitForExistence(timeout: 10))
        app.otherElements["counter-cell-4"].tap()
        app.otherElements["counter-cell-5"].tap()
        app.buttons["That is 6"].tap()

        XCTAssertTrue(app.staticTexts["Gravity Split"].waitForExistence(timeout: 10))
        app.buttons["gravity-complete-split-button"].tap()

        let successCTA = app.otherElements["gravity-split-success-progression"]
        let nextButton = app.buttons["gravity-split-next-button"]
        XCTAssertTrue(successCTA.waitForExistence(timeout: 5), "Expected the Gravity Split success CTA to stay visible on compact layouts")
        XCTAssertTrue(nextButton.waitForExistence(timeout: 5))
        XCTAssertTrue(nextButton.isHittable, "Expected the Gravity Split success CTA button to be reachable")
        nextButton.tap()
        XCTAssertTrue(app.staticTexts["Sum Sprint"].waitForExistence(timeout: 10))
    }

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


    func testSessionSetupCompactTargetCapUsesSingleScrollablePresetControl() {
        let app = launchWithVS1()
        _ = app.staticTexts["Mather"].waitForExistence(timeout: 10)

        app.buttons["Play"].tap()
        _ = app.staticTexts["Session setup"].waitForExistence(timeout: 10)

        XCTAssertTrue(app.buttons["theme-card-vehicle"].waitForExistence(timeout: 5))
        app.buttons["theme-card-vehicle"].tap()
        XCTAssertTrue(app.buttons["theme-card-space"].waitForExistence(timeout: 5))
        app.buttons["theme-card-space"].tap()

        let targetCap50 = app.buttons["target-cap-up-to-50"]
        if !targetCap50.waitForExistence(timeout: 3) {
            app.scrollViews.firstMatch.swipeUp()
        }
        XCTAssertTrue(targetCap50.waitForExistence(timeout: 5))
        XCTAssertTrue(targetCap50.isHittable, "Expected target-cap preset cards to be reachable on compact setup")
        targetCap50.tap()
        XCTAssertFalse(app.steppers["target-cap-stepper"].exists, "Expected setup to expose only preset target-cap cards, not duplicate plus/minus controls")

        let start = app.buttons["start-session-button"]
        if !start.isHittable {
            app.scrollViews.firstMatch.swipeUp()
        }
        XCTAssertTrue(start.waitForExistence(timeout: 5))
        XCTAssertTrue(start.isHittable, "Expected Start Session to be reachable by scrolling on compact setup")
        for _ in 0..<3 where app.buttons["start-session-button"].frame.maxY > app.frame.maxY - 24 {
            app.swipeUp()
        }
        let spacedStart = app.buttons["start-session-button"]
        XCTAssertLessThanOrEqual(
            spacedStart.frame.maxY,
            app.frame.maxY - 24,
            "Expected Start Session to keep comfortable bottom spacing above the compact safe area"
        )

        let back = app.buttons["back-to-home-button"]
        if !back.isHittable {
            app.scrollViews.firstMatch.swipeUp()
        }
        XCTAssertTrue(back.waitForExistence(timeout: 5))
        XCTAssertTrue(back.isHittable, "Expected Back to Home to remain reachable by scrolling on compact setup")
    }

    func testStoryAnchorCompactVehicleSessionKeepsBannerAndStorySeparated() {
        let app = launchWithVS1()
        _ = app.staticTexts["Mather"].waitForExistence(timeout: 10)

        app.buttons["Play"].tap()
        _ = app.staticTexts["Session setup"].waitForExistence(timeout: 10)

        XCTAssertTrue(app.buttons["theme-card-vehicle"].waitForExistence(timeout: 5))
        app.buttons["theme-card-vehicle"].tap()

        let targetCap50 = app.buttons["target-cap-up-to-50"]
        if !targetCap50.waitForExistence(timeout: 3) {
            app.scrollViews.firstMatch.swipeUp()
        }
        XCTAssertTrue(targetCap50.waitForExistence(timeout: 5))
        targetCap50.tap()

        let startSession = app.buttons["start-session-button"]
        if !startSession.isHittable {
            app.scrollViews.firstMatch.swipeUp()
        }
        XCTAssertTrue(startSession.waitForExistence(timeout: 5))
        startSession.tap()

        let banner = app.otherElements["feedback-banner"]
        let storyCard = app.otherElements["story-anchor-card"]
        let spokenIntro = app.descendants(matching: .any)["story-anchor-spoken-intro"]
        let reminder = app.descendants(matching: .any)["story-anchor-reminder-pill"]
        let startBuilding = app.buttons["story-anchor-start-button"]

        XCTAssertTrue(banner.waitForExistence(timeout: 5), "Expected story-stage feedback banner before the Story Anchor card")
        XCTAssertTrue(storyCard.waitForExistence(timeout: 5), "Expected Story Anchor card before advancing to concrete")
        XCTAssertTrue(spokenIntro.waitForExistence(timeout: 5), "Expected visible story copy on the Story Anchor card")
        XCTAssertTrue(reminder.waitForExistence(timeout: 5), "Expected reminder pill on the Story Anchor card")
        XCTAssertTrue(startBuilding.waitForExistence(timeout: 5), "Expected Start building button on the Story Anchor card")
        XCTAssertTrue(startBuilding.isHittable, "Expected Start building to be reachable on compact Story Anchor")

        XCTAssertGreaterThanOrEqual(
            storyCard.frame.minY,
            banner.frame.maxY,
            "Expected the content-sized Story Anchor card to be laid out below the feedback banner"
        )
        XCTAssertGreaterThanOrEqual(
            spokenIntro.frame.minY,
            banner.frame.maxY,
            "Expected the story sentence to stay out of the feedback banner area"
        )
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

    func testWaterCycleCompactCompletionKeepsControlsReachable() {
        let app = launch()
        _ = app.staticTexts["Mather"].waitForExistence(timeout: 10)

        openExplorerLab(app)
        app.buttons["Water Cycle Lab"].tap()
        XCTAssertTrue(app.staticTexts["Water Cycle Lab"].waitForExistence(timeout: 10))

        let primaryAction = app.buttons["water-cycle-primary-action"]
        XCTAssertTrue(primaryAction.waitForExistence(timeout: 5))
        for _ in 0..<5 {
            XCTAssertTrue(primaryAction.isHittable, "Expected Water Cycle primary action to remain reachable")
            primaryAction.tap()
        }

        XCTAssertTrue(app.staticTexts["Cycle complete"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["water-cycle-primary-action"].isHittable)
        XCTAssertTrue(app.buttons["water-cycle-replay-prompt"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["water-cycle-reset"].waitForExistence(timeout: 5))
    }


    private func advanceStoryAnchorIfPresent(_ app: XCUIApplication) {
        let startBuilding = app.buttons["story-anchor-start-button"]
        if startBuilding.waitForExistence(timeout: 3) {
            startBuilding.tap()
        }
    }

    private func launchBondBlastFinale(target: Int) -> XCUIApplication {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchArguments = [
            "-feature.audioEnabled", "NO",
            "-feature.hapticsEnabled", "NO",
            "-feature.motionControlsEnabled", "NO",
            "-feature.soundReactionEnabled", "NO",
            "-feature.testModeEnabled", "YES",
            "-uiTest.startRoute", "bondBlast",
            "-uiTest.bondBlastTarget", "\(target)"
        ]
        app.launch()
        return app
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

    private func launchExplorerLab() -> XCUIApplication {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchArguments = [
            "-feature.audioEnabled", "NO",
            "-feature.hapticsEnabled", "NO",
            "-feature.testModeEnabled", "YES",
            "-feature.skipProfilePicker", "YES",
            "-uiTest.startRoute", "lab"
        ]
        app.launch()
        return app
    }

    private func launchGeometryLane() -> XCUIApplication {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchArguments = [
            "-feature.audioEnabled", "NO",
            "-feature.hapticsEnabled", "NO",
            "-feature.testModeEnabled", "YES",
            "-feature.skipProfilePicker", "YES",
            "-uiTest.startRoute", "geometryLane"
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
            "-feature.testModeEnabled", "YES",
            "-feature.skipProfilePicker", "YES"
        ]
        app.launch()
        return app
    }

    private func launchWithoutParentBypass() -> XCUIApplication {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchArguments = [
            "-feature.audioEnabled", "NO",
            "-feature.hapticsEnabled", "NO",
            "-feature.testModeEnabled", "NO",
            "-feature.skipProfilePicker", "YES"
        ]
        app.launch()
        return app
    }
}
