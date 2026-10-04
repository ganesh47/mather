import XCTest

@MainActor
final class MemoryPairsTVUITests: XCTestCase {
    override func setUpWithError() throws { continueAfterFailure = false }

    func testBigBalancedPicturesCollectInStableSlotsAndReplay() throws {
        let app = try launchAdventure()
        try start(app)
        let initial = cards(app).allElementsBoundByIndex
        XCTAssertEqual(initial.count, 6)
        XCTAssertGreaterThan(initial[0].frame.height, 250)
        XCTAssertEqual(initial[0].frame.midY, initial[2].frame.midY, accuracy: 2)
        XCTAssertGreaterThan(initial[3].frame.midY, initial[0].frame.midY)
        screenshot("Busy Builders six large aspect-fit pictures in two balanced rows")
        let frames = Dictionary(uniqueKeysWithValues: initial.map { ($0.identifier, $0.frame) })
        for count in 1...3 {
            let pair = try pairToMatch(app)
            try focus(pair.0, app: app)
            XCUIRemote.shared.press(.select)
            XCUIRemote.shared.press(.select) // Repeated first card must not award a pair.
            XCTAssertEqual(progress(app), "\(count - 1) of 3 pairs")
            try focus(pair.1, app: app)
            XCUIRemote.shared.press(.select)
            XCUIRemote.shared.press(.select) // Repeated second card must not double-collect.
            waitCount(6 - count * 2, app: app)
            XCTAssertEqual(progress(app), "\(count) of 3 pairs")
            XCTAssertEqual(collection(app).value as? String, "\(count) of 3")
            for card in cards(app).allElementsBoundByIndex {
                let original = try XCTUnwrap(frames[card.identifier])
                XCTAssertEqual(card.frame.midX, original.midX, accuracy: 2)
                XCTAssertEqual(card.frame.midY, original.midY, accuracy: 2)
            }
            if count == 1 { screenshot("A pair collected with all remaining cards in their original slots") }
        }
        waitFocus(app.buttons["tv-memory-adventure-again"])
        let completion = app.staticTexts["tv-memory-pairs-completion"]
        XCTAssertTrue(completion.exists)
        waitValue("Complete", element: completion)
        screenshot("Bounded calm final celebration with three actual collected pairs")
        XCUIRemote.shared.press(.playPause)
        XCUIRemote.shared.press(.select)
        waitCount(6, app: app)
        XCTAssertEqual(progress(app), "0 of 3 pairs")
        XCTAssertEqual(collection(app).value as? String, "0 of 3")
        XCTAssertFalse(completion.exists)
    }

    func testMissRepeatedInputOptionsAndBackgroundKeepSameRound() throws {
        let app = try launchAdventure()
        try start(app)
        let initial = cards(app).allElementsBoundByIndex
        let identities = Set(initial.map(\.identifier))
        let first = try XCTUnwrap(initial.first)
        let different = try XCTUnwrap(initial.first { $0.label != first.label })
        try focus(first, app: app)
        XCUIRemote.shared.press(.select)
        try focus(different, app: app)
        XCUIRemote.shared.press(.select)
        XCUIRemote.shared.press(.select)
        XCTAssertEqual(progress(app), "0 of 3 pairs")
        let settled = expectation(for: NSPredicate { _, _ in
            self.cards(app).allElementsBoundByIndex.allSatisfy { ($0.value as? String) == "Ready" }
        }, evaluatedWith: nil)
        wait(for: [settled], timeout: 5)
        XCTAssertEqual(cards(app).count, 6)
        try focus(first, app: app)
        XCUIRemote.shared.press(.select)
        try focus(app.buttons["tv-memory-adventure-options"], app: app)
        XCUIRemote.shared.press(.select)
        waitFocus(app.buttons["tv-memory-adventure-resume"])
        XCUIRemote.shared.press(.select)
        waitCount(6, app: app)
        XCTAssertEqual(Set(cards(app).allElementsBoundByIndex.map(\.identifier)), identities)
        XCTAssertEqual(progress(app), "0 of 3 pairs")
        XCTAssertTrue(cards(app).allElementsBoundByIndex.allSatisfy { ($0.value as? String) == "Ready" })
        let pair = try pairToMatch(app)
        try focus(pair.0, app: app)
        XCUIRemote.shared.press(.select)
        try focus(pair.1, app: app)
        XCUIRemote.shared.press(.select)
        // Leave during the success interval. Either the engine awarded the pair or it was cancelled;
        // the retained grid and count must agree when the view resumes.
        XCUIDevice.shared.press(.home)
        let background = expectation(for: NSPredicate { _, _ in
            app.state == .runningBackground || app.state == .runningBackgroundSuspended
        }, evaluatedWith: nil)
        wait(for: [background], timeout: 10)
        app.activate()
        XCTAssertTrue(app.staticTexts["tv-memory-pairs-progress"].waitForExistence(timeout: 10))
        let resumed = expectation(for: NSPredicate { _, _ in
            self.cards(app).allElementsBoundByIndex.contains { $0.hasFocus }
        }, evaluatedWith: nil)
        wait(for: [resumed], timeout: 10)
        let awarded = progress(app).hasPrefix("1") ? 1 : 0
        XCTAssertEqual(cards(app).count, 6 - 2 * awarded)
        XCTAssertEqual(collection(app).value as? String, "\(awarded) of 3")
        screenshot("Foreground keeps resolved pairs and cancels unresolved feedback")
    }

    func testGentleTimerExpiryMoreTimeAndUntimedKeepCards() throws {
        let app = try launchAdventure(extra: ["-memory-pairs-short-timer"])
        try focus(app.buttons["tv-memory-adventure-timer"], app: app)
        XCUIRemote.shared.press(.select)
        // Accessibility polling can take longer than the intentional two-second expiry.
        // This case expects recovery focus, rather than transient initial card focus.
        try start(app, waitForCardFocus: false)
        let identities = Set(cards(app).allElementsBoundByIndex.map(\.identifier))
        let more = app.buttons["tv-memory-adventure-more-time"]
        let untimed = app.buttons["tv-memory-adventure-untimed"]
        XCTAssertTrue(app.staticTexts["tv-memory-pairs-expired"].waitForExistence(timeout: 10))
        XCTAssertTrue(more.waitForExistence(timeout: 10))
        waitFocus(more)
        XCTAssertEqual(more.identifier, "tv-memory-adventure-more-time")
        XCTAssertEqual(untimed.identifier, "tv-memory-adventure-untimed")
        XCTAssertEqual(app.buttons.matching(identifier: "tv-memory-pairs-expired").count, 0)
        XCTAssertEqual(progress(app), "0 of 3 pairs")
        screenshot("Gentle timer expiry preserves all six cards")
        XCUIRemote.shared.press(.select)
        XCTAssertFalse(more.exists)
        XCTAssertEqual(Set(cards(app).allElementsBoundByIndex.map(\.identifier)), identities)
        try focus(app.buttons["tv-memory-adventure-options"], app: app)
        XCUIRemote.shared.press(.select)
        waitFocus(app.buttons["tv-memory-adventure-resume"])
        try focus(app.buttons["tv-memory-adventure-timer"], app: app)
        XCUIRemote.shared.press(.select) // Turn timer off.
        XCUIRemote.shared.press(.select) // Turn short test timer back on for same cards.
        try focus(app.buttons["tv-memory-adventure-resume"], app: app)
        XCUIRemote.shared.press(.select)
        XCTAssertTrue(more.waitForExistence(timeout: 10))
        XCTAssertTrue(app.staticTexts["tv-memory-pairs-expired"].exists)
        try focus(untimed, app: app)
        XCUIRemote.shared.press(.select)
        XCTAssertFalse(more.exists)
        XCTAssertEqual(Set(cards(app).allElementsBoundByIndex.map(\.identifier)), identities)
        XCTAssertEqual(progress(app), "0 of 3 pairs")
        XCTAssertTrue(app.descendants(matching: .any)["tv-friendly-timer"].label.contains("Untimed"))
        screenshot("Untimed recovery continues the same cards")
    }

    func testReducedMotionHiddenHintAndFourPairLayout() throws {
        let app = try launchAdventure(extra: ["-memory-pairs-reduce-motion"])
        try start(app, id: "four", count: 8)
        let initial = cards(app).allElementsBoundByIndex
        XCTAssertEqual(initial[0].frame.midY, initial[3].frame.midY, accuracy: 2)
        XCTAssertGreaterThan(initial[4].frame.midY, initial[0].frame.midY)
        screenshot("Reduced Motion four visible pairs in two complete rows")
        try focus(app.buttons["tv-memory-adventure-options"], app: app)
        XCUIRemote.shared.press(.select)
        try start(app, id: "hidden", count: 12)
        XCTAssertTrue(cards(app).allElementsBoundByIndex.allSatisfy { $0.label.hasPrefix("Hidden card") })
        try focus(app.buttons["tv-memory-adventure-hint"], app: app)
        XCUIRemote.shared.press(.select)
        let hinted = expectation(for: NSPredicate { _, _ in
            self.cards(app).allElementsBoundByIndex.filter { !$0.label.hasPrefix("Hidden card") }.count == 2
        }, evaluatedWith: nil)
        wait(for: [hinted], timeout: 5)
        XCTAssertEqual(progress(app), "0 of 6 pairs")
        screenshot("Six hidden pairs with a temporary pair hint and static focus")
        XCUIRemote.shared.press(.menu)
        XCTAssertTrue(app.buttons["tv-memory-category-animals"].waitForExistence(timeout: 10))
    }

    func testMuteOptionKeepsRemotePlayAvailable() throws {
        let app = try launchAdventure(extra: ["-memory-pairs-muted"])
        let audio = app.buttons["tv-memory-adventure-audio"]
        XCTAssertEqual(audio.label, "Audio off")
        try focus(audio, app: app)
        XCUIRemote.shared.press(.select)
        XCTAssertEqual(audio.label, "Audio on")
        XCUIRemote.shared.press(.select)
        XCTAssertEqual(audio.label, "Audio off")
        try start(app)
        let pair = try pairToMatch(app)
        try focus(pair.0, app: app)
        XCUIRemote.shared.press(.select)
        try focus(pair.1, app: app)
        XCUIRemote.shared.press(.select)
        waitCount(4, app: app)
        XCTAssertEqual(progress(app), "1 of 3 pairs")
        try focus(app.buttons["tv-memory-adventure-options"], app: app)
        XCUIRemote.shared.press(.select)
        waitFocus(app.buttons["tv-memory-adventure-resume"])
        XCTAssertEqual(audio.label, "Audio off")
        screenshot("Muted app narration retains accessible options and collected pairs")
    }

    func testRescueAndSpaceUseLargeFullPictures() throws {
        for adventure in ["rescueCrew", "spaceTrip"] {
            let app = try launchAdventure(adventure: adventure)
            try start(app)
            XCTAssertEqual(cards(app).count, 6)
            XCTAssertGreaterThan(cards(app).firstMatch.frame.height, 250)
            screenshot("\(adventure) large full pictures")
            if adventure == "rescueCrew" {
                try focus(app.buttons["tv-memory-adventure-options"], app: app)
                XCUIRemote.shared.press(.select)
                try start(app, id: "hidden", count: 10)
                let hiddenCards = cards(app).allElementsBoundByIndex
                XCTAssertEqual(progress(app), "0 of 5 pairs")
                XCTAssertEqual(hiddenCards.count, 10)
                XCTAssertTrue(hiddenCards.allSatisfy { $0.label.hasPrefix("Hidden card") })
                XCTAssertEqual(hiddenCards[0].frame.midY, hiddenCards[4].frame.midY, accuracy: 2)
                XCTAssertEqual(hiddenCards[5].frame.midY, hiddenCards[9].frame.midY, accuracy: 2)
                XCTAssertGreaterThan(hiddenCards[5].frame.midY, hiddenCards[0].frame.midY)
                try focus(hiddenCards[9], app: app)
                XCTAssertTrue(hiddenCards[9].hasFocus)
                screenshot("Rescue requested six pairs uses five actual pairs in two balanced rows")
                let hint = app.buttons["tv-memory-adventure-hint"]
                try focus(hint, app: app)
                XCTAssertTrue(hint.hasFocus)
                XCUIRemote.shared.press(.select)
                let revealed = expectation(for: NSPredicate { _, _ in
                    self.cards(app).allElementsBoundByIndex.filter { !$0.label.hasPrefix("Hidden card") }.count == 2
                }, evaluatedWith: nil)
                wait(for: [revealed], timeout: 5)
                XCTAssertEqual(progress(app), "0 of 5 pairs")
                XCTAssertEqual(cards(app).count, 10)
                screenshot("Rescue five-pair board keeps remote hint reachable")
            }
            XCUIRemote.shared.press(.menu)
            XCTAssertTrue(app.buttons["tv-memory-category-animals"].waitForExistence(timeout: 10))
            app.terminate()
        }
    }

    private func launchAdventure(adventure: String = "busyBuilders", extra: [String] = []) throws -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["-memory-pairs-ui-test"] + extra
        app.launch()
        waitFocus(app.buttons["tv-mode-memory"])
        XCUIRemote.shared.press(.select)
        waitFocus(app.buttons["tv-memory-category-animals"])
        try focus(app.buttons["tv-memory-adventure-\(adventure)"], app: app)
        XCUIRemote.shared.press(.select)
        waitFocus(app.buttons["tv-memory-adventure-start"])
        return app
    }
    private func start(_ app: XCUIApplication, id: String = "start", count: Int = 6, waitForCardFocus: Bool = true) throws {
        try focus(app.buttons["tv-memory-adventure-\(id)"], app: app)
        XCUIRemote.shared.press(.select)
        waitCount(count, app: app)
        guard waitForCardFocus else { return }
        let focused = expectation(for: NSPredicate { _, _ in
            self.cards(app).allElementsBoundByIndex.contains { $0.hasFocus }
        }, evaluatedWith: nil)
        wait(for: [focused], timeout: 10)
    }
    private func cards(_ app: XCUIApplication) -> XCUIElementQuery {
        app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@", "tv-memory-pair-"))
    }
    private func progress(_ app: XCUIApplication) -> String { app.staticTexts["tv-memory-pairs-progress"].label }
    private func collection(_ app: XCUIApplication) -> XCUIElement { app.descendants(matching: .any)["tv-memory-pairs-collection"] }
    private func pairToMatch(_ app: XCUIApplication) throws -> (XCUIElement, XCUIElement) {
        let remaining = cards(app).allElementsBoundByIndex
        let first = try XCTUnwrap(remaining.first)
        let partner = try XCTUnwrap(remaining.first { $0.identifier != first.identifier && $0.label == first.label })
        return (first, partner)
    }
    private func waitCount(_ count: Int, app: XCUIApplication) {
        let settled = expectation(for: NSPredicate { _, _ in self.cards(app).count == count }, evaluatedWith: nil)
        wait(for: [settled], timeout: 10)
    }
    private func waitValue(_ value: String, element: XCUIElement) {
        let settled = expectation(for: NSPredicate(format: "value == %@", value), evaluatedWith: element)
        wait(for: [settled], timeout: 5)
    }
    private func waitFocus(_ element: XCUIElement) {
        XCTAssertTrue(element.waitForExistence(timeout: 15))
        let focused = expectation(for: NSPredicate(format: "hasFocus == true"), evaluatedWith: element)
        wait(for: [focused], timeout: 10)
    }
    private func focus(_ target: XCUIElement, app: XCUIApplication) throws {
        XCTAssertTrue(target.waitForExistence(timeout: 10))
        let availableFocus = expectation(for: NSPredicate { _, _ in
            app.buttons.allElementsBoundByIndex.contains { $0.hasFocus }
        }, evaluatedWith: nil)
        wait(for: [availableFocus], timeout: 10)
        for _ in 0..<20 {
            if target.hasFocus { return }
            let focused = try XCTUnwrap(app.buttons.allElementsBoundByIndex.first { $0.hasFocus })
            let dx = target.frame.midX - focused.frame.midX
            let dy = target.frame.midY - focused.frame.midY
            let horizontal = abs(dx) > max(target.frame.width, focused.frame.width) / 2
            XCUIRemote.shared.press(horizontal ? (dx > 0 ? .right : .left) : (dy > 0 ? .down : .up))
            if focused.hasFocus {
                if horizontal && abs(dy) > 40 { XCUIRemote.shared.press(dy > 0 ? .down : .up) }
                else if !horizontal && abs(dx) > 40 { XCUIRemote.shared.press(dx > 0 ? .right : .left) }
            }
            if focused.hasFocus,
               focused.identifier.hasPrefix("tv-memory-pair-"),
               target.identifier.hasPrefix("tv-memory-pair-") {
                // Collected cards keep empty slots. Two diagonal survivors may need
                // the action row instead of repeatedly swiping into those holes.
                XCUIRemote.shared.press(.down)
                screenshot("Remote focus detour around collected card slots")
            }
        }
        screenshot("Unreachable remote focus \(target.identifier)")
        let hierarchy = XCTAttachment(string: app.debugDescription)
        hierarchy.name = "Unreachable remote focus hierarchy"
        hierarchy.lifetime = .keepAlways
        add(hierarchy)
        XCTFail("Remote focus could not reach \(target.identifier)")
    }
    private func screenshot(_ name: String) {
        let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
