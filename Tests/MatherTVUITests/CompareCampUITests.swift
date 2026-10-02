import XCTest

@MainActor
final class CompareCampUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testAdventureBuildsComparesTransfersAndKeepsPassport() {
        let app = launchCamp()
        attachScreenshot("Six regions and a world of camp choices")
        choose(app, "tv-compare-category-apple-orchard")
        attachScreenshot("Six trails and three group sizes")
        choose(app, "tv-compare-start")
        waitForStop(app, 1)
        let firstPair = counts(app)
        var firstJourney = ["\(firstPair.left)/\(firstPair.right)"]
        attachScreenshot("Concrete first stop with generated apple artwork")

        // A check is a real comparison: unequal groups stay playable after a miss.
        choose(app, "tv-compare-check")
        XCTAssertFalse(app.buttons["tv-compare-next"].exists)
        XCTAssertTrue(app.buttons["tv-compare-check"].isEnabled)
        XCTAssertTrue(app.staticTexts["tv-compare-feedback"].label.contains("Keep exploring"))
        attachScreenshot("Build feedback invites another try")
        choose(app, "tv-compare-count-left")
        XCTAssertEqual(tally(app, side: "left"), min(1, firstPair.left))
        choose(app, "tv-compare-count-right")
        XCTAssertEqual(tally(app, side: "right"), min(1, firstPair.right))
        choose(app, "tv-compare-arrange")
        choose(app, "tv-compare-hint")
        attachScreenshot("Counted and paired objects support a real retry")

        // Both bounds are reachable without accidentally answering or advancing.
        while counts(app).left > 0 { choose(app, "tv-compare-remove") }
        XCTAssertFalse(app.buttons["tv-compare-remove"].isEnabled)
        while counts(app).left < 5 { choose(app, "tv-compare-add") }
        XCTAssertFalse(app.buttons["tv-compare-add"].isEnabled)
        XCTAssertEqual(counts(app).right, firstPair.right)
        solveCurrentStop(app)
        XCTAssertFalse(app.buttons["tv-compare-check"].isEnabled)
        advance(app, expecting: 2)

        for stop in 2...8 {
            waitForStop(app, stop)
            if stop <= 3 {
                let pair = counts(app)
                firstJourney.append("\(pair.left)/\(pair.right)")
            }
            if stop == 3 {
                let correct = correctChoiceID(app)
                let wrong = ["left", "same", "right"].first { $0 != correct }!
                choose(app, "tv-compare-answer-\(wrong)")
                XCTAssertFalse(app.buttons["tv-compare-next"].exists)
                XCTAssertTrue(app.buttons["tv-compare-answer-\(correct)"].isEnabled)
                XCTAssertTrue(app.staticTexts["tv-compare-feedback"].label.contains("look again"))
                attachScreenshot("A comparison miss keeps choices available")
            }
            if stop == 5 || stop == 6 {
                XCTAssertTrue(app.staticTexts["tv-compare-progress"].label.contains("Number Discovery"))
                XCTAssertTrue(app.staticTexts["tv-compare-number-comparison"].exists)
                attachScreenshot("Number signs connect the pictured quantities")
            }
            if stop >= 7 {
                XCTAssertTrue(app.staticTexts["tv-compare-progress"].label.contains("Try Somewhere New"))
                XCTAssertNotEqual(app.staticTexts["tv-compare-title"].label, "Apple Orchard")
                attachScreenshot("Transfer stop \(stop) uses a new subject")
            }
            solveCurrentStop(app)
            if stop < 8 { advance(app, expecting: stop + 1) }
        }
        choose(app, "tv-compare-next")
        XCTAssertTrue(app.buttons["tv-compare-replay"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.staticTexts["Trail explored!"].exists)
        XCTAssertTrue(app.staticTexts["Apple Orchard sticker collected"].exists)
        attachScreenshot("Eight discoveries earn an exploration sticker")

        choose(app, "tv-compare-passport")
        XCTAssertTrue(app.staticTexts["tv-compare-passport-title"].waitForExistence(timeout: 5))
        let sticker = app.buttons["tv-compare-sticker-apple-orchard"]
        XCTAssertTrue(sticker.label.contains("Sticker collected"))
        let savedProgress = app.staticTexts["tv-compare-passport-progress"].label
        attachScreenshot("Passport remembers the explored camp")
        choose(app, "tv-compare-passport-back")
        choose(app, "tv-compare-replay")
        waitForStop(app, 1)
        XCTAssertFalse(app.buttons["tv-compare-next"].exists)
        XCTAssertEqual(tally(app, side: "left"), 0)
        XCTAssertEqual(tally(app, side: "right"), 0)
        attachScreenshot("Explore again begins a fresh concrete challenge")
        var replayJourney: [String] = []
        for stop in 1...3 {
            let pair = counts(app)
            replayJourney.append("\(pair.left)/\(pair.right)")
            if stop < 3 {
                solveCurrentStop(app)
                advance(app, expecting: stop + 1)
            }
        }
        XCTAssertNotEqual(replayJourney, firstJourney, "Explore again must offer a new quantity journey")

        // Relaunching loads the device-local passport independently of the session.
        app.terminate()
        app.launch()
        enterCampFromLauncher(app)
        choose(app, "tv-compare-passport")
        XCTAssertEqual(app.staticTexts["tv-compare-passport-progress"].label, savedProgress)
        XCTAssertTrue(app.buttons["tv-compare-sticker-apple-orchard"].label.contains("Sticker collected"))
    }

    func testEveryRegionOffersFourCampsAndGrowingAndBigGroupsRemainPlayable() {
        let app = launchCamp()
        let catalog: [(String, [String])] = [
            ("woodland", ["apple-orchard", "flower-garden", "leaf-trail", "sheep-meadow"]),
            ("ocean", ["clownfish-reef", "goldfish-pond", "seahorse-bay", "angelfish-lagoon"]),
            ("sky", ["macaw-canopy", "peafowl-garden", "flamingo-lake", "puffin-cliffs"]),
            ("space", ["earth-workshop", "mars-workshop", "jupiter-workshop", "saturn-workshop"]),
            ("travel", ["car-camp", "train-station", "boat-harbor", "airplane-field"]),
            ("builders", ["excavator-hill", "bulldozer-trail", "dump-truck-quarry", "mixer-yard"])
        ]
        for (region, categories) in catalog {
            choose(app, "tv-compare-region-\(region)")
            for category in categories {
                XCTAssertTrue(app.buttons["tv-compare-category-\(category)"].exists)
            }
            XCTAssertEqual(app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@", "tv-compare-category-")).count, 4)
            attachScreenshot("Four \(region) camps with distinct subject artwork")
        }
        choose(app, "tv-compare-category-excavator-hill")
        for activity in ["adventure", "more", "fewer", "makeEqual", "difference", "symbols"] {
            XCTAssertTrue(app.buttons["tv-compare-activity-\(activity)"].exists)
        }
        choose(app, "tv-compare-difficulty-growing")
        XCTAssertTrue(app.buttons["tv-compare-difficulty-growing"].label.contains("Selected"))
        choose(app, "tv-compare-start")
        waitForStop(app, 1)
        XCTAssertLessThanOrEqual(counts(app).left, 10)
        XCTAssertLessThanOrEqual(counts(app).right, 10)
        solveCurrentStop(app)
        attachScreenshot("Growing explorer builder camp solves with real objects")

        choose(app, "tv-compare-camps")
        choose(app, "tv-compare-region-space")
        choose(app, "tv-compare-category-saturn-workshop")
        choose(app, "tv-compare-difficulty-big")
        choose(app, "tv-compare-activity-makeEqual")
        choose(app, "tv-compare-start")
        waitForStop(app, 1)
        let right = counts(app).right
        while counts(app).left < 20 { choose(app, "tv-compare-add") }
        XCTAssertEqual(counts(app).left, 20)
        XCTAssertFalse(app.buttons["tv-compare-add"].isEnabled)
        XCTAssertEqual(counts(app).right, right)
        attachScreenshot("Twenty Saturn models remain countable on screen")
        solveCurrentStop(app)
        XCTAssertTrue(app.buttons["tv-compare-next"].exists)
    }

    func testRepeatPromptAndMenuPreserveRemoteNavigationAndFreshReentry() {
        let app = launchCamp()
        choose(app, "tv-compare-category-flower-garden")
        choose(app, "tv-compare-activity-fewer")
        choose(app, "tv-compare-start")
        waitForStop(app, 1)
        let before = counts(app)
        let prompt = app.staticTexts["tv-compare-question"].label
        XCUIRemote.shared.press(.playPause)
        XCTAssertEqual(counts(app).left, before.left)
        XCTAssertEqual(counts(app).right, before.right)
        XCTAssertEqual(app.staticTexts["tv-compare-question"].label, prompt)
        XCTAssertFalse(app.buttons["tv-compare-next"].exists)
        solveCurrentStop(app)
        XCUIRemote.shared.press(.playPause)
        XCTAssertTrue(app.buttons["tv-compare-next"].exists)
        attachScreenshot("Spoken repeat preserves the solved comparison")
        XCUIRemote.shared.press(.menu)
        let compare = app.buttons["tv-mode-compare"]
        XCTAssertTrue(compare.waitForExistence(timeout: 10))
        waitForFocus(compare)
        XCUIRemote.shared.press(.select)
        XCTAssertTrue(app.buttons["tv-compare-category-apple-orchard"].waitForExistence(timeout: 10))
        choose(app, "tv-compare-category-flower-garden")
        XCTAssertTrue(app.buttons["tv-compare-activity-adventure"].label.contains("Selected"))
        XCTAssertTrue(app.buttons["tv-compare-difficulty-small"].label.contains("Selected"))
        choose(app, "tv-compare-start")
        waitForStop(app, 1)
        XCTAssertTrue(app.buttons["tv-compare-check"].exists)
        XCTAssertFalse(app.buttons["tv-compare-next"].exists)
        attachScreenshot("Menu reentry starts a fresh camp choice and trail")
    }

    private func launchCamp() -> XCUIApplication {
        let app = XCUIApplication()
        app.launch()
        enterCampFromLauncher(app)
        return app
    }

    private func enterCampFromLauncher(_ app: XCUIApplication) {
        let memory = app.buttons["tv-mode-memory"]
        XCTAssertTrue(memory.waitForExistence(timeout: 20))
        waitForFocus(memory)
        XCUIRemote.shared.press(.down)
        let compare = app.buttons["tv-mode-compare"]
        waitForFocus(compare)
        XCUIRemote.shared.press(.select)
        XCTAssertTrue(app.buttons["tv-compare-category-apple-orchard"].waitForExistence(timeout: 10))
        waitForFocus(app.buttons["tv-compare-category-apple-orchard"])
    }

    private func solveCurrentStop(_ app: XCUIApplication) {
        if app.buttons["tv-compare-check"].exists {
            let pair = counts(app)
            while counts(app).left < pair.right { choose(app, "tv-compare-add") }
            while counts(app).left > pair.right { choose(app, "tv-compare-remove") }
            choose(app, "tv-compare-check")
        } else {
            choose(app, "tv-compare-answer-\(correctChoiceID(app))")
        }
        XCTAssertTrue(app.buttons["tv-compare-next"].waitForExistence(timeout: 5))
        waitForFocus(app.buttons["tv-compare-next"])
    }

    private func correctChoiceID(_ app: XCUIApplication) -> String {
        let pair = counts(app)
        let question = app.staticTexts["tv-compare-question"].label
        if question.contains("sign") { return pair.left < pair.right ? "less" : pair.left == pair.right ? "equal" : "greater" }
        if question.contains("extra") { return "number-\(abs(pair.left - pair.right))" }
        if pair.left == pair.right { return "same" }
        if question.contains("fewer") { return pair.left < pair.right ? "left" : "right" }
        return pair.left > pair.right ? "left" : "right"
    }

    private func advance(_ app: XCUIApplication, expecting stop: Int) {
        choose(app, "tv-compare-next")
        waitForStop(app, stop)
    }

    private func waitForStop(_ app: XCUIApplication, _ stop: Int) {
        let progress = app.staticTexts["tv-compare-progress"]
        XCTAssertTrue(progress.waitForExistence(timeout: 10))
        let ready = expectation(for: NSPredicate(format: "label BEGINSWITH %@", "Stop \(stop) of 8"), evaluatedWith: progress)
        wait(for: [ready], timeout: 10)
    }

    private func counts(_ app: XCUIApplication) -> (left: Int, right: Int) {
        (quantity(app, side: "left", position: 0), quantity(app, side: "right", position: 0))
    }

    private func tally(_ app: XCUIApplication, side: String) -> Int {
        quantity(app, side: side, position: 1)
    }

    private func quantity(_ app: XCUIApplication, side: String, position: Int) -> Int {
        let group = app.descendants(matching: .any)["tv-compare-\(side)-group"].firstMatch
        XCTAssertTrue(group.exists)
        let numbers = group.label.components(separatedBy: CharacterSet.decimalDigits.inverted).compactMap(Int.init)
        XCTAssertGreaterThan(numbers.count, position, "Expected accessible quantity in \(group.label)")
        return numbers.indices.contains(position) ? numbers[position] : 0
    }

    private func choose(_ app: XCUIApplication, _ identifier: String) {
        let target = app.buttons[identifier]
        if !target.exists { XCTAssertTrue(target.waitForExistence(timeout: 10), "Missing \(identifier)") }
        XCTAssertTrue(target.isEnabled, "Disabled \(identifier)")
        focus(app, target)
        XCUIRemote.shared.press(.select)
    }

    /// Follow the same spatial navigation a child uses, without invoking view actions.
    private func focus(_ app: XCUIApplication, _ target: XCUIElement) {
        var previousControl: String?
        var previousDirection: XCUIRemote.Button?
        for _ in 0..<24 {
            if target.hasFocus { return }
            let current = app.buttons.matching(NSPredicate(format: "hasFocus == true")).firstMatch
            if !current.exists {
                XCTAssertTrue(current.waitForExistence(timeout: 5), "Focus did not settle after the screen changed")
            }
            XCTAssertTrue(current.exists, "No focused control while navigating to \(target.identifier)")
            let dx = target.frame.midX - current.frame.midX
            let dy = target.frame.midY - current.frame.midY
            let differentColumns = target.frame.maxX < current.frame.minX || target.frame.minX > current.frame.maxX
            var direction: XCUIRemote.Button
            if differentColumns {
                direction = dx > 0 ? .right : .left
            } else if abs(dy) > max(40, current.frame.height * 0.55) {
                direction = dy > 0 ? .down : .up
            } else {
                direction = dx > 0 ? .right : .left
            }
            // Sparse headers require entering a row before moving sideways.
            if previousControl == current.identifier, previousDirection == direction {
                direction = direction == .left || direction == .right
                    ? (dy > 0 ? .down : .up)
                    : (dx > 0 ? .right : .left)
            }
            previousControl = current.identifier
            previousDirection = direction
            XCUIRemote.shared.press(direction)
        }
        XCTAssertTrue(target.hasFocus, "Could not reach \(target.identifier). Focus: \(app.buttons.matching(NSPredicate(format: "hasFocus == true")).firstMatch.identifier)")
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
