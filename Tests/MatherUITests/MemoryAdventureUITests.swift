import XCTest

@MainActor
final class MemoryAdventureUITests: XCTestCase {
    func testAdventureChooserOffersPicturePairsAndHiddenChallenge() {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchArguments = [
            "-feature.audioEnabled", "NO", "-feature.hapticsEnabled", "NO",
            "-feature.testModeEnabled", "YES", "-feature.skipProfilePicker", "YES",
            "-uiTest.startRoute", "memory"
        ]
        app.launch()
        let chooser = app.buttons["memory-deck-menu"]
        XCTAssertTrue(chooser.waitForExistence(timeout: 10))
        chooser.tap()
        let builders = app.buttons["memory-adventure-busyBuilders"]
        XCTAssertTrue(builders.waitForExistence(timeout: 5))
        XCTAssertGreaterThanOrEqual(builders.frame.width, 80)
        XCTAssertGreaterThanOrEqual(builders.frame.height, 80)
        snapshot(app, "Memory-Adventure-Chooser")
        builders.tap()
        XCTAssertTrue(app.staticTexts["0/3 pairs matched"].waitForExistence(timeout: 5))
        let cards = app.otherElements.matching(NSPredicate(format: "identifier BEGINSWITH 'memory-card-'"))
        XCTAssertEqual(cards.count, 6)
        XCTAssertEqual(cards.matching(NSPredicate(format: "identifier ENDSWITH '-label'")).count, 0)
        reveal(cards.element(boundBy: 0), in: app)
        app.scrollViews.firstMatch.swipeUp()
        snapshot(app, "Memory-Builders-Picture-Pairs")

        // Both picture cards share a pair identifier. Match each unique pair
        // through the real board, including the delayed matching feedback.
        let pairIdentifiers = Set(cards.allElementsBoundByIndex.map(\.identifier)).sorted()
        XCTAssertEqual(pairIdentifiers.count, 3)
        for (index, identifier) in pairIdentifiers.enumerated() {
            let pair = cards.matching(identifier: identifier)
            XCTAssertEqual(pair.count, 2)
            pair.element(boundBy: 0).tap()
            pair.element(boundBy: 1).tap()
            XCTAssertTrue(app.staticTexts["\(index + 1)/3 pairs matched"].waitForExistence(timeout: 5))
        }
        let nextRound = app.buttons["Next Round"]
        let tryIt = app.buttons["memory-adventure-try-it"]
        XCTAssertTrue(nextRound.waitForExistence(timeout: 5))
        XCTAssertTrue(nextRound.isEnabled && nextRound.isHittable)
        XCTAssertTrue(tryIt.isEnabled && tryIt.isHittable)
        XCTAssertGreaterThanOrEqual(nextRound.frame.height, 80)
        XCTAssertGreaterThanOrEqual(tryIt.frame.height, 80)
        snapshot(app, "Memory-Builders-Completion")
        nextRound.tap()
        XCTAssertTrue(app.staticTexts["0/3 pairs matched"].waitForExistence(timeout: 5))
        XCTAssertFalse(tryIt.exists)

        let options = app.buttons["memory-play-options"]
        reveal(options, in: app, swipeDown: true)
        options.tap()
        let difficulty = app.buttons["memory-difficulty-menu"]
        reveal(difficulty, in: app, swipeDown: true)
        difficulty.tap()
        app.buttons["Flip!"].tap()
        XCTAssertTrue(app.staticTexts["0/6 pairs matched"].waitForExistence(timeout: 5))
        // LazyVGrid exposes only loaded rows on a compact display. The progress
        // label verifies six pairs; every currently loaded card must be concealed.
        XCTAssertGreaterThan(cards.count, 0)
        XCTAssertEqual(cards.matching(NSPredicate(format: "label == 'Face down memory card'")).count, cards.count)
        let hint = app.buttons["memory-hint"]
        reveal(hint, in: app)
        XCTAssertTrue(hint.isEnabled)
        XCTAssertGreaterThanOrEqual(hint.frame.height, 80)
        hint.tap()
        XCTAssertGreaterThan(cards.matching(NSPredicate(format: "label != 'Face down memory card'")).count, 0)
        reveal(cards.element(boundBy: 0), in: app)
        app.scrollViews.firstMatch.swipeUp()
        snapshot(app, "Memory-Builders-Flip-Challenge")
    }

    private func reveal(_ element: XCUIElement, in app: XCUIApplication, swipeDown: Bool = false) {
        for _ in 0..<6 where !element.isHittable {
            if swipeDown { app.scrollViews.firstMatch.swipeDown() }
            else { app.scrollViews.firstMatch.swipeUp() }
        }
        XCTAssertTrue(element.isHittable)
    }

    private func snapshot(_ app: XCUIApplication, _ name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
