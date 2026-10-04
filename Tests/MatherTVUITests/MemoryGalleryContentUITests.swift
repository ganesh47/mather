import XCTest

@MainActor
final class MemoryGalleryContentUITests: XCTestCase {
    override func setUpWithError() throws { continueAfterFailure = false }

    func testPublicPackActivatesPlaysAndSurvivesRelaunch() throws {
        let feed = URL(string: "https://raw.githubusercontent.com/ganesh47/mather-content/main/memory-gallery/pack.json")!
        let manifest = try XCTUnwrap(JSONSerialization.jsonObject(with: Data(contentsOf: feed)) as? [String: Any])
        let version = max(3, try XCTUnwrap(manifest["contentVersion"] as? Int))
        let decks = try XCTUnwrap(manifest["decks"] as? [[String: Any]])
        let vehicleDeck = try XCTUnwrap(decks.first { $0["kind"] as? String == "vehicles" })
        let cards = try XCTUnwrap(vehicleDeck["cards"] as? [[String: Any]])
        let cardIDs = Set(cards.compactMap { $0["id"] as? String })
        let app = XCUIApplication()
        app.launch()
        enterGallery(app)
        let downloadedShelf = app.descendants(matching: .any)["tv-memory-content-v\(version)"]
        XCTAssertTrue(downloadedShelf.waitForExistence(timeout: 240), "Newest bundled or published content must be playable")
        attachScreenshot("Newest available gallery")

        waitForFocus(app.buttons["tv-memory-category-animals"])
        XCUIRemote.shared.press(.right)
        waitForFocus(app.buttons["tv-memory-category-vehicles"])
        XCUIRemote.shared.press(.select)
        let answers = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@", "tv-memory-answer-"))
        XCTAssertTrue(answers.firstMatch.waitForExistence(timeout: 10))
        let answer = try XCTUnwrap(answers.allElementsBoundByIndex.first { $0.hasFocus })
        XCTAssertTrue(cardIDs.contains(String(answer.identifier.dropFirst("tv-memory-answer-".count))))
        XCUIRemote.shared.press(.select)
        XCTAssertTrue(app.buttons["tv-memory-next-picture"].waitForExistence(timeout: 10))
        attachScreenshot("Current gallery card answered")

        app.terminate()
        app.launch()
        enterGallery(app)
        XCTAssertTrue(app.descendants(matching: .any)["tv-memory-content-v\(version)"].waitForExistence(timeout: 10), "Newest content must remain available after relaunch")
        attachScreenshot("Current gallery after relaunch")
    }

    func testAdventureStartsWithThreeVisiblePairsAndOffersHint() throws {
        let app = XCUIApplication()
        app.launch()
        enterGallery(app)
        waitForFocus(app.buttons["tv-memory-category-animals"])
        XCUIRemote.shared.press(.down)
        let adventure = app.buttons["tv-memory-adventure-busyBuilders"]
        waitForFocus(adventure)
        XCUIRemote.shared.press(.select)
        let start = app.buttons["tv-memory-adventure-start"]
        XCTAssertTrue(start.waitForExistence(timeout: 10))
        waitForFocus(start)
        XCUIRemote.shared.press(.select)
        let cards = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@", "tv-memory-pair-"))
        XCTAssertTrue(cards.firstMatch.waitForExistence(timeout: 10))
        XCTAssertEqual(cards.count, 6)
        XCTAssertTrue(app.buttons["tv-memory-adventure-hint"].exists)
        attachScreenshot("Three visible adventure pairs")
        let hint = app.buttons["tv-memory-adventure-hint"]
        try focusByDirection(hint, app: app)
        XCUIRemote.shared.press(.select)
        attachScreenshot("Adventure hint glows")
        for found in 1...3 {
            let remaining = cards.allElementsBoundByIndex
            let first = try XCTUnwrap(remaining.first)
            let partner = try XCTUnwrap(remaining.first { $0.identifier != first.identifier && $0.label == first.label })
            try focusByDirection(first, app: app)
            XCUIRemote.shared.press(.select)
            try focusByDirection(partner, app: app)
            XCUIRemote.shared.press(.select)
            let collected = expectation(for: NSPredicate { _, _ in cards.count == 6 - found * 2 }, evaluatedWith: nil)
            wait(for: [collected], timeout: 5)
            XCTAssertEqual(app.staticTexts["tv-memory-pairs-progress"].label, "\(found) of 3 pairs")
            XCTAssertEqual(app.descendants(matching: .any)["tv-memory-pairs-collection"].value as? String, "\(found) of 3")
            let focusRestored = expectation(for: NSPredicate { _, _ in
                app.buttons.allElementsBoundByIndex.contains { $0.hasFocus }
            }, evaluatedWith: nil)
            wait(for: [focusRestored], timeout: 5)
        }
        let again = app.buttons["tv-memory-adventure-again"]
        XCTAssertTrue(again.waitForExistence(timeout: 10))
        waitForFocus(again)
        attachScreenshot("Adventure pairs completed")
        XCUIRemote.shared.press(.select)
        XCTAssertEqual(cards.count, 6)
        XCTAssertFalse(again.exists)
        attachScreenshot("Adventure replay")
        XCUIRemote.shared.press(.menu)
        XCTAssertTrue(app.buttons["tv-memory-category-animals"].waitForExistence(timeout: 10))
        attachScreenshot("Gallery after Menu")
    }

    func testAdventureQuizRevealsFactsAndCompletes() throws {
        let app = XCUIApplication()
        app.launch()
        enterGallery(app)
        attachScreenshot("Illustrated gallery chooser")
        waitForFocus(app.buttons["tv-memory-category-animals"])
        XCUIRemote.shared.press(.down)
        waitForFocus(app.buttons["tv-memory-adventure-busyBuilders"])
        XCUIRemote.shared.press(.select)
        let quiz = app.buttons["tv-memory-adventure-quiz"]
        XCTAssertTrue(quiz.waitForExistence(timeout: 10))
        waitForFocus(app.buttons["tv-memory-adventure-start"])
        try focusByDirection(quiz, app: app)
        XCUIRemote.shared.press(.select)
        for index in 0..<6 {
            let answers = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@", "tv-memory-answer-"))
            XCTAssertTrue(answers.firstMatch.waitForExistence(timeout: 10))
            waitForFocus(answers.firstMatch)
            XCUIRemote.shared.press(.playPause)
            XCUIRemote.shared.press(.select)
            let next = app.buttons[index == 5 ? "tv-memory-see-results" : "tv-memory-next-picture"]
            XCTAssertTrue(next.waitForExistence(timeout: 10))
            waitForFocus(next)
            if index == 0 { attachScreenshot("Adventure quiz picture and fact reveal") }
            XCUIRemote.shared.press(.select)
        }
        XCTAssertTrue(app.staticTexts["tv-memory-completion-title"].waitForExistence(timeout: 10))
        waitForFocus(app.buttons["tv-memory-replay"])
        attachScreenshot("Adventure quiz completed")
    }

    private func focusByDirection(_ target: XCUIElement, app: XCUIApplication) throws {
        for _ in 0..<12 {
            if target.hasFocus { return }
            let focused = try XCTUnwrap(app.buttons.allElementsBoundByIndex.first { $0.hasFocus })
            let dx = target.frame.midX - focused.frame.midX
            let dy = target.frame.midY - focused.frame.midY
            let horizontal = abs(dx) > max(target.frame.width, focused.frame.width) / 2
            if horizontal { XCUIRemote.shared.press(dx > 0 ? .right : .left) }
            else { XCUIRemote.shared.press(dy > 0 ? .down : .up) }
            if focused.hasFocus {
                if horizontal && abs(dy) > 40 { XCUIRemote.shared.press(dy > 0 ? .down : .up) }
                else if !horizontal && abs(dx) > 40 { XCUIRemote.shared.press(dx > 0 ? .right : .left) }
            }
        }
        XCTFail("Remote focus could not reach \(target.identifier)")
    }

    private func enterGallery(_ app: XCUIApplication) {
        let memory = app.buttons["tv-mode-memory"]
        XCTAssertTrue(memory.waitForExistence(timeout: 20))
        waitForFocus(memory)
        XCUIRemote.shared.press(.select)
        XCTAssertTrue(app.buttons["tv-memory-category-animals"].waitForExistence(timeout: 20))
    }

    private func waitForFocus(_ element: XCUIElement) {
        let focused = expectation(for: NSPredicate(format: "hasFocus == true"), evaluatedWith: element)
        wait(for: [focused], timeout: 10)
    }

    private func attachScreenshot(_ name: String) {
        let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
