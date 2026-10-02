import XCTest

@MainActor
final class LearningQuestUITests: XCTestCase {
    func testNumbersPreservesChosenPartsAndFinishesTransfer() {
        let app = launch("quest-numbers")
        step("Learn", in: app)
        tap("quest-count-add", in: app) // Choose seven and three, rather than the initial six and four.
        snapshot(app, "Numbers-Learn")
        tap("quest-primary", in: app)
        step("Remember", in: app)
        tap("quest-choice-3", in: app)
        submitAndContinue(in: app)
        step("Play", in: app)
        for _ in 0..<3 { tap("quest-count-add", in: app) }
        submitAndContinue(in: app)
        step("Challenge", in: app)
        for _ in 0..<5 { tap("quest-count-add", in: app) }
        snapshot(app, "Numbers-Transfer")
        submitAndContinue(in: app)
        step("Challenge", in: app)
        XCTAssertEqual(app.staticTexts["quest-probe-progress"].label, "New task 2 of 2")
        for _ in 0..<6 { tap("quest-count-add", in: app) }
        submitAndContinue(in: app)
        finish(in: app, name: "Numbers")
        tap("Parent Summary", in: app)
        XCTAssertTrue(app.staticTexts["Parts and wholes"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["New context: 2/2 fresh probes correct without an app hint"].exists)
        snapshot(app, "Numbers-Parent-Evidence")
    }

    func testShapesExploresFourCoreShapesBuildsAndTransfers() {
        let app = launch("quest-shapes")
        for shape in ["circle", "triangle", "square", "rectangle"] { tap("quest-shape-select-\(shape)", in: app) }
        tap("quest-shape-turn", in: app)
        snapshot(app, "Shapes-Learn")
        tap("quest-primary", in: app)
        step("Remember", in: app)
        tap("quest-choice-triangle", in: app)
        submitAndContinue(in: app)
        step("Play", in: app)
        for index in [0, 1, 3] { tap("quest-shape-point-\(index)", in: app) }
        submitAndContinue(in: app)
        step("Challenge", in: app)
        XCTAssertFalse(app.buttons["quest-choice-rectangle"].label.lowercased().contains("rectangle"))
        tap("quest-choice-rectangle", in: app)
        snapshot(app, "Shapes-Transfer")
        submitAndContinue(in: app)
        finish(in: app, name: "Shapes")
    }

    func testWaterCyclePredictsChangesAndTransfersToColdCup() {
        let app = launch("quest-water-cycle")
        tap("quest-water-warm", in: app)
        tap("quest-water-cool", in: app)
        snapshot(app, "Water-Learn")
        tap("quest-primary", in: app)
        step("Remember", in: app)
        tap("quest-choice-vapor", in: app)
        submitAndContinue(in: app)
        step("Play", in: app)
        tap("quest-choice-drops", in: app)
        submitAndContinue(in: app)
        step("Challenge", in: app)
        tap("quest-choice-outside", in: app)
        snapshot(app, "Water-Transfer")
        submitAndContinue(in: app)
        finish(in: app, name: "Water")
    }

    func testCircuitPredictsRepairsAndFinishesDifferentArrangement() {
        let app = XCUIApplication()
        for ordinal in 0..<2 {
            app.launchArguments = arguments("quest-circuit-spark", clear: ordinal == 0)
            app.launch()
            XCTAssertTrue(app.staticTexts["learning-quest-circuitSpark"].waitForExistence(timeout: 10))
            tap("quest-switch-first", in: app)
            snapshot(app, "Circuit-Learn")
            tap("quest-primary", in: app)
            step("Remember", in: app)
            tap("quest-choice-closed", in: app)
            submitAndContinue(in: app)
            step("Play", in: app)
            tap("quest-wire-repair", in: app)
            submitAndContinue(in: app)
            step("Challenge", in: app)
            let circuit = app.descendants(matching: .any)["quest-circuit-state"].firstMatch
            XCTAssertTrue(circuit.waitForExistence(timeout: 5))
            XCTAssertTrue(circuit.label.contains("Wire is connected."))
            XCTAssertTrue(circuit.label.contains("First, upper switch is \(ordinal == 0 ? "closed" : "open")."))
            XCTAssertTrue(circuit.label.contains("Second, lower switch is \(ordinal == 0 ? "open" : "closed")."))
            XCTAssertFalse(circuit.label.contains("Bulb is off") || circuit.label.contains("Bulb is lit"))
            tap("quest-choice-off", in: app)
            tap("quest-primary", in: app) // Store the prediction before revealing the repair controls.
            tap(ordinal == 0 ? "quest-switch-second" : "quest-switch-first", in: app)
            snapshot(app, "Circuit-Transfer")
            submitAndContinue(in: app)
            finish(in: app, name: "Circuit")
            app.terminate()
        }
    }

    func testSavingAndRelaunchingRestoresExactNumberTask() {
        let app = launch("quest-numbers")
        tap("quest-count-add", in: app)
        tap("quest-primary", in: app)
        step("Remember", in: app)
        tap("quest-choice-3", in: app)
        tap("quest-save", in: app)
        app.terminate()
        app.launchArguments = arguments("quest-numbers", clear: false)
        app.launch()
        step("Remember", in: app)
        // The previously selected choice survives, so submission is enabled without reselecting.
        XCTAssertTrue(app.buttons["quest-primary"].isEnabled)
        submitAndContinue(in: app)
        step("Play", in: app)
    }

    func testDownloadedCatalogIsVisibleAndSurvivesOfflineRelaunch() {
        let app = XCUIApplication()
        app.launchArguments = Array(arguments("home", clear: false).dropLast(2))
        app.launch()
        XCTAssertTrue(app.buttons["Settings"].waitForExistence(timeout: 10))
        app.buttons["Settings"].tap()
        let version = app.staticTexts["ios-learning-content-version"]
        XCTAssertTrue(version.waitForExistence(timeout: 10))
        let downloaded = NSPredicate(format: "label MATCHES %@", "Version ([2-9]|[1-9][0-9]+).*")
        let update = XCTNSPredicateExpectation(predicate: downloaded, object: version)
        guard XCTWaiter.wait(for: [update], timeout: 180) == .completed else {
            snapshot(app, "External-Catalog-Download-Failed")
            XCTFail("The public content pack did not activate. \(app.debugDescription)")
            return
        }
        let downloadedVersion = version.label
        app.terminate()
        app.launchArguments += ["-uiTest.disableContentRefresh", "YES"]
        app.launch()
        XCTAssertTrue(app.buttons["Settings"].waitForExistence(timeout: 10))
        app.buttons["Settings"].tap()
        XCTAssertTrue(app.staticTexts["ios-learning-content-version"].waitForExistence(timeout: 10))
        XCTAssertEqual(app.staticTexts["ios-learning-content-version"].label, downloadedVersion)
        snapshot(app, "External-Catalog-Offline")
    }

    func testCompactActionsStayVisibleAndOptionalParentReportSaves() {
        let app = launch("quest-numbers")
        XCTAssertTrue(app.buttons["quest-primary"].isHittable)
        XCTAssertTrue(app.buttons["quest-help"].isHittable)
        app.scrollViews.firstMatch.swipeUp()
        XCTAssertTrue(app.buttons["quest-primary"].isHittable)
        XCTAssertTrue(app.buttons["quest-help"].isHittable)
        tap("quest-save", in: app)
        app.terminate()
        app.launchArguments = arguments("home", clear: false)
        app.launch()
        tap("Parent Summary", in: app)
        tap("parent-observation-add", in: app)
        tap("parent-observation-save", in: app)
        snapshot(app, "Parent-Concept-Evidence")
        let report = app.descendants(matching: .any)["parent-offscreen-observation"].firstMatch
        XCTAssertTrue(report.waitForExistence(timeout: 5), app.debugDescription)
    }

    func testParentSummaryCompanionRouteAndDone() {
        let app = XCUIApplication()
        app.launchArguments = arguments("home", clear: true)
        app.launch()
        tap("Parent Summary", in: app)
        tap("parent-summary-companion", in: app)
        XCTAssertTrue(app.staticTexts["companion-recipient"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["companion-recipient"].label.hasPrefix("Local recipient: "))
        snapshot(app, "Parent-Companion-Entry")
        tap("companion-close", in: app)
        XCTAssertTrue(app.buttons["parent-summary-companion"].waitForExistence(timeout: 5))
    }

    func testUnsupportedQuestStorageShowsPausedContextAndQuitWithoutPlayControls() {
        let app = XCUIApplication()
        for key in ["learningQuestCheckpoints.v1", "learningQuestCheckpoints.v1.reviewedVariants.v1"] {
            app.launchArguments = arguments("quest-shapes", clear: false) + ["-" + key, "unsupported-test-value"]
            app.launch()
            XCTAssertTrue(app.staticTexts["quest-paused"].waitForExistence(timeout: 10))
            XCTAssertTrue(app.staticTexts["quest-storage-message"].label.contains("Delete all quest checkpoints in Settings"))
            XCTAssertFalse(app.buttons["quest-primary"].exists)
            XCTAssertFalse(app.buttons["quest-help"].exists)
            XCTAssertFalse(app.buttons["quest-save"].exists)
            snapshot(app, "Quest-Storage-Paused")
            tap("quest-paused-quit", in: app)
            XCTAssertTrue(app.buttons["Parent Summary"].waitForExistence(timeout: 5))
            app.terminate()
        }
    }

    private func launch(_ route: String) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = arguments(route, clear: true)
        app.launch()
        XCTAssertTrue(app.buttons["quest-primary"].waitForExistence(timeout: 10))
        return app
    }
    private func arguments(_ route: String, clear: Bool) -> [String] {
        var result = ["-feature.audioEnabled", "NO", "-feature.hapticsEnabled", "NO", "-feature.testModeEnabled", "YES", "-feature.skipProfilePicker", "YES", "-uiTest.startRoute", route, "-uiTest.disableContentRefresh", "YES"]
        if clear { result += ["-uiTest.clearQuestCheckpoints", "YES"] }
        return result
    }
    private func step(_ title: String, in app: XCUIApplication) {
        let label = app.staticTexts["quest-step"]
        XCTAssertTrue(label.waitForExistence(timeout: 5))
        XCTAssertEqual(label.label, title)
    }
    private func tap(_ identifier: String, in app: XCUIApplication) {
        let button = app.buttons[identifier]
        var didScroll = false
        // Lazy grids and Forms create offscreen buttons only after scrolling.
        // A presented Form is a collection view above the underlying summary.
        for _ in 0..<8 {
            if button.exists, button.isHittable { break }
            let visibleContainer = [.collectionView, .table, .scrollView]
                .lazy
                .compactMap { (type: XCUIElement.ElementType) in
                    app.descendants(matching: type).allElementsBoundByIndex.reversed()
                        .first { $0.exists && $0.isHittable }
                }
                .first
            guard let visibleContainer else { break }
            if button.exists, button.frame.minY < app.windows.firstMatch.frame.minY + 80 {
                visibleContainer.swipeDown()
            } else {
                visibleContainer.swipeUp()
            }
            didScroll = true
        }
        guard button.waitForExistence(timeout: 2) else {
            snapshot(app, "Missing-\(identifier)")
            XCTFail("Missing \(identifier) after bounded visible scrolling")
            return
        }
        guard button.isHittable else {
            snapshot(app, "Unreachable-\(identifier)")
            XCTFail("Unreachable \(identifier) after bounded visible scrolling")
            return
        }
        if didScroll { snapshot(app, "Scrolled-\(identifier)") }
        button.tap()
    }
    private func submitAndContinue(in app: XCUIApplication) {
        tap("quest-primary", in: app)
        XCTAssertTrue(app.staticTexts["quest-feedback"].waitForExistence(timeout: 3))
        tap("quest-primary", in: app)
    }
    private func finish(in app: XCUIApplication, name: String) {
        step("Celebrate", in: app)
        snapshot(app, "\(name)-Celebrate")
        tap("quest-primary", in: app)
        XCTAssertFalse(app.staticTexts["quest-step"].exists)
    }
    private func snapshot(_ app: XCUIApplication, _ name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
