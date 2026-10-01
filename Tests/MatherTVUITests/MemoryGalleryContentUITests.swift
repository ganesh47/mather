import XCTest

@MainActor
final class MemoryGalleryContentUITests: XCTestCase {
    func testPublicPackActivatesPlaysAndSurvivesRelaunch() throws {
        let feed = URL(string: "https://raw.githubusercontent.com/ganesh47/mather-content/main/memory-gallery/pack.json")!
        let manifest = try XCTUnwrap(JSONSerialization.jsonObject(with: Data(contentsOf: feed)) as? [String: Any])
        let version = try XCTUnwrap(manifest["contentVersion"] as? Int)
        let decks = try XCTUnwrap(manifest["decks"] as? [[String: Any]])
        let vehicleDeck = try XCTUnwrap(decks.first { $0["kind"] as? String == "vehicles" })
        let cards = try XCTUnwrap(vehicleDeck["cards"] as? [[String: Any]])
        let firstCardID = try XCTUnwrap(cards.first?["id"] as? String)
        let app = XCUIApplication()
        app.launch()
        enterGallery(app)
        let downloadedShelf = app.descendants(matching: .any)["tv-memory-content-v\(version)"]
        XCTAssertTrue(downloadedShelf.waitForExistence(timeout: 240), "Published content must finish downloading")
        attachScreenshot("Downloaded gallery")

        waitForFocus(app.buttons["tv-memory-category-animals"])
        XCUIRemote.shared.press(.right)
        waitForFocus(app.buttons["tv-memory-category-vehicles"])
        XCUIRemote.shared.press(.select)
        let answer = app.buttons["tv-memory-answer-\(firstCardID)"]
        XCTAssertTrue(answer.waitForExistence(timeout: 10))
        waitForFocus(answer)
        XCUIRemote.shared.press(.select)
        XCTAssertTrue(app.buttons["tv-memory-next-picture"].waitForExistence(timeout: 10))
        attachScreenshot("Downloaded card answered")

        app.terminate()
        app.launch()
        enterGallery(app)
        XCTAssertTrue(app.descendants(matching: .any)["tv-memory-content-v\(version)"].waitForExistence(timeout: 10), "Completed pack must restore from disk")
        attachScreenshot("Cached gallery after relaunch")
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
