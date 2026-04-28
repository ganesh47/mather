import XCTest

/// UI-level screenshot tests that capture key screens of the Mather app.
///
/// These tests navigate through the main user flows and attach full-screen
/// PNG screenshots to the test result bundle. CI extracts and uploads them
/// as workflow artifacts so visual regressions are visible in the Actions tab.
///
/// Note: setUp/tearDown are intentionally not overridden. Swift 6 strict
/// concurrency does not allow @MainActor overrides of the nonisolated
/// XCTestCase lifecycle methods. Instead, each test creates its app
/// via `launch()` and takes ownership of teardown implicitly.
@MainActor
final class ScreenshotTests: XCTestCase {

    private enum UIAppearanceMode: String {
        case light
        case dark

        var launchValue: String { rawValue }
        var nameSuffix: String { rawValue.capitalized }
    }

    // MARK: - Home screen

    func testScreenshot_Home_VS1Disabled() {
        let app = launch()
        _ = app.staticTexts["Mather"].waitForExistence(timeout: 5)
        snapshot(app, "Home-VS1Disabled")
    }

    // MARK: - Appearance regression

    func testScreenshot_AppearanceModes_HomeAndSessionConfig() {
        let light = launchWithVS1(appearance: .light)
        _ = light.staticTexts["Mather"].waitForExistence(timeout: 10)
        snapshot(light, "Appearance-Light-Home")
        light.buttons["Play"].tap()
        _ = light.staticTexts["Session setup"].waitForExistence(timeout: 10)
        snapshot(light, "Appearance-Light-SessionConfig")

        let dark = launchWithVS1(appearance: .dark)
        _ = dark.staticTexts["Mather"].waitForExistence(timeout: 10)
        snapshot(dark, "Appearance-Dark-Home")
        dark.buttons["Play"].tap()
        _ = dark.staticTexts["Session setup"].waitForExistence(timeout: 10)
        snapshot(dark, "Appearance-Dark-SessionConfig")
    }

    // MARK: - Settings screen

    func testScreenshot_Settings_MakeBreakLoopBuiltIn() {
        let app = launch()
        _ = app.staticTexts["Mather"].waitForExistence(timeout: 5)

        app.buttons["Settings"].tap()
        _ = app.staticTexts["Settings"].waitForExistence(timeout: 3)
        XCTAssertFalse(app.switches["settings-loop-v2-toggle"].exists)
        XCTAssertTrue(app.staticTexts["Make it → Gravity Split → Sum Sprint → Bond Blast is built in for every target."].waitForExistence(timeout: 5))
        snapshot(app, "Settings-MakeBreakLoopBuiltIn")

        app.buttons["Home"].tap()
        _ = app.staticTexts["Mather"].waitForExistence(timeout: 3)
        snapshot(app, "Home-MakeBreakLoopBuiltIn")
    }

    // MARK: - Session Config screen

    func testScreenshot_SessionConfig() {
        // Pre-enable VS1 via launch argument to skip Settings navigation.
        let app = launchWithVS1()
        _ = app.staticTexts["Mather"].waitForExistence(timeout: 10)

        let playButton = app.buttons["Play"]
        _ = playButton.waitForExistence(timeout: 5)
        playButton.tap()
        _ = app.staticTexts["Session setup"].waitForExistence(timeout: 10)
        snapshot(app, "SessionConfig")
    }

    // MARK: - Concrete stage

    func testScreenshot_ConcreteBuildView() {
        let app = launchWithVS1()
        _ = app.staticTexts["Mather"].waitForExistence(timeout: 10)

        let playButton = app.buttons["Play"]
        _ = playButton.waitForExistence(timeout: 5)
        playButton.tap()
        _ = app.staticTexts["Session setup"].waitForExistence(timeout: 10)

        let startButton = app.buttons["Start Session"]
        _ = startButton.waitForExistence(timeout: 5)
        startButton.tap()

        let makePredicate = NSPredicate(format: "label BEGINSWITH 'Make '")
        _ = app.staticTexts.element(matching: makePredicate).waitForExistence(timeout: 15)
        snapshot(app, "ConcreteBuild-Initial")
    }

    // MARK: - Haptics / feedback flow

    /// Exercises the failure-then-success path so the screen recording captures
    /// both the failure feedback banner and the celebration state.
    func testScreenshot_ConcreteBuild_FailureThenSuccess() {
        let app = launchWithLegacyVS1AndHaptics()
        _ = app.staticTexts["Mather"].waitForExistence(timeout: 10)

        let playButton = app.buttons["Play"]
        _ = playButton.waitForExistence(timeout: 5)
        playButton.tap()
        _ = app.staticTexts["Session setup"].waitForExistence(timeout: 10)

        let startButton = app.buttons["Start Session"]
        _ = startButton.waitForExistence(timeout: 5)
        startButton.tap()

        let makePredicate = NSPredicate(format: "label BEGINSWITH 'Make '")
        _ = app.staticTexts.element(matching: makePredicate).waitForExistence(timeout: 15)
        snapshot(app, "ConcreteBuild-BeforeInput")

        // Submit with count at 0 to trigger failure feedback
        let submitPredicate = NSPredicate(format: "label BEGINSWITH 'That is '")
        let submitButton = app.buttons.element(matching: submitPredicate)
        _ = submitButton.waitForExistence(timeout: 5)
        submitButton.tap()
        snapshot(app, "ConcreteBuild-FailureFeedback")

        // Fill the deterministic target of 6 with the current two-row concrete model:
        // five warm counters on the top row plus one accent counter on the bottom row.
        let warmRowLastCell = app.otherElements["counter-cell-4"]
        if !warmRowLastCell.waitForExistence(timeout: 3) {
            app.scrollViews.firstMatch.swipeUp()
        }
        _ = warmRowLastCell.waitForExistence(timeout: 5)
        warmRowLastCell.tap()
        let accentRowFirstCell = app.otherElements["counter-cell-5"]
        _ = accentRowFirstCell.waitForExistence(timeout: 5)
        accentRowFirstCell.tap()
        submitButton.tap()

        // After a correct answer the stage advances to Bond Blast in the pictorial slot.
        _ = app.staticTexts["Bond Blast!"].waitForExistence(timeout: 10)
        snapshot(app, "Pictorial-AfterConcreteSuccess")
    }

    func testConcreteBuild_AccentRowLockedUntilWarmFull() throws {
        throw XCTSkip("UI test mode starts on deterministic target 6, which does not expose a real accent row. Warm/accent split logic is covered in VerticalSliceEngineTests until a >10 UI fixture exists.")
    }

    // MARK: - Parent Summary screen

    func testScreenshot_ParentSummary() {
        let app = launch()
        _ = app.staticTexts["Mather"].waitForExistence(timeout: 5)
        app.buttons["Parent Summary"].tap()
        _ = app.staticTexts["Parent Summary"].waitForExistence(timeout: 10)
        snapshot(app, "ParentSummary-Empty")

        // Navigate to Settings from Parent Summary
        let settingsButton = app.buttons["Settings"]
        _ = settingsButton.waitForExistence(timeout: 5)
        settingsButton.tap()
        _ = app.staticTexts["Settings"].waitForExistence(timeout: 10)
        snapshot(app, "Settings-FromParentSummary")

        // Tap clear — confirm dialog should appear
        let clearButton = app.buttons["Clear session history"]
        _ = clearButton.waitForExistence(timeout: 5)
        clearButton.tap()
        _ = app.alerts["Clear all session data?"].waitForExistence(timeout: 5)
        snapshot(app, "Settings-ClearConfirmDialog")

        // Dismiss with Cancel
        app.alerts["Clear all session data?"].buttons["Cancel"].tap()
        snapshot(app, "Settings-AfterCancelClear")
    }

    func testSessionHistoryShowsMultipleSavedSessionsInParentSummaryAndSettings() {
        let app = launchWithSeededHistory(count: 2)
        _ = app.staticTexts["Mather"].waitForExistence(timeout: 5)

        app.buttons["Parent Summary"].tap()
        _ = app.staticTexts["Parent Summary"].waitForExistence(timeout: 10)
        XCTAssertTrue(app.staticTexts["2 saved locally"].waitForExistence(timeout: 5))

        XCTAssertTrue(waitForHistoryRow(app, identifier: "parent-summary-session-1", fallbackLabel: "Session 2", timeout: 5))

        app.buttons["Settings"].tap()
        _ = app.staticTexts["Settings"].waitForExistence(timeout: 10)
        XCTAssertTrue(app.staticTexts["2 saved locally"].waitForExistence(timeout: 5))

        XCTAssertTrue(waitForHistoryRow(app, identifier: "settings-history-session-1", fallbackLabel: "Session 2", timeout: 5))
    }

    // MARK: - iPhone layout / pilot runbook

    /// Verifies the full session flow renders without crash and screenshots the
    /// pilot runbook in Settings — covers the M8 smoke-test acceptance criterion.
    func testScreenshot_PilotRunbook() {
        let app = launchWithLegacyVS1()
        _ = app.staticTexts["Mather"].waitForExistence(timeout: 10)
        snapshot(app, "iPhone-Home")

        // Navigate to Settings and capture the pilot runbook
        app.buttons["Settings"].tap()
        _ = app.staticTexts["Settings"].waitForExistence(timeout: 10)
        XCTAssertFalse(app.switches["settings-loop-v2-toggle"].exists)
        _ = app.staticTexts["Pilot smoke test"].waitForExistence(timeout: 5)
        snapshot(app, "iPhone-Settings-PilotRunbook")
        app.buttons["Home"].tap()

        // Run one full problem to verify no crash on compact layout
        _ = app.buttons["Play"].waitForExistence(timeout: 10)
        app.buttons["Play"].tap()
        _ = app.staticTexts["Session setup"].waitForExistence(timeout: 10)
        snapshot(app, "iPhone-SessionConfig")

        _ = app.buttons["Start Session"].waitForExistence(timeout: 5)
        app.buttons["Start Session"].tap()

        let makePredicate = NSPredicate(format: "label BEGINSWITH 'Make '")
        _ = app.staticTexts.element(matching: makePredicate).waitForExistence(timeout: 15)
        snapshot(app, "iPhone-ConcreteBuild-AdaptiveGrid")

        // Fill the deterministic target of 6 with five warm counters plus one accent counter.
        let warmRowLastCell = app.otherElements["counter-cell-4"]
        if !warmRowLastCell.waitForExistence(timeout: 3) {
            app.scrollViews.firstMatch.swipeUp()
        }
        _ = warmRowLastCell.waitForExistence(timeout: 5)
        warmRowLastCell.tap()
        let accentRowFirstCell = app.otherElements["counter-cell-5"]
        _ = accentRowFirstCell.waitForExistence(timeout: 5)
        accentRowFirstCell.tap()

        let submitPredicate = NSPredicate(format: "label BEGINSWITH 'That is '")
        let submitButton = app.buttons.element(matching: submitPredicate)
        _ = submitButton.waitForExistence(timeout: 5)
        submitButton.tap()

        _ = app.staticTexts["Bond Blast!"].waitForExistence(timeout: 10)
        snapshot(app, "iPhone-SplitView")
    }

    // MARK: - Issue #222 validation lane

    /// Captures deterministic evidence for the reopened issue #222 route:
    /// Make it -> Gravity Split -> Sum Sprint -> Bond Blast.
    ///
    /// The test clears four full loop iterations in one session so the xcresult
    /// includes screenshots and assertions across both low and higher problem targets.
    func testScreenshot_Issue222LoopV2_AcrossFourTargetsIncludingTwelve() {
        let app = launchWithLoopV2()
        _ = app.staticTexts["Mather"].waitForExistence(timeout: 10)

        app.buttons["Play"].tap()
        _ = app.staticTexts["Session setup"].waitForExistence(timeout: 10)
        app.buttons["Start Session"].tap()

        completeLoopV2Problem(
            in: app,
            target: 6,
            concreteCellIndex: 5,
            leftPanCount: 3,
            rightPanCount: 3,
            expectedSumSprintPairs: 2,
            bondPairs: [(1, 5), (2, 4), (3, 3)],
            snapshotPrefix: "Issue222-Target6"
        )

        completeLoopV2Problem(
            in: app,
            target: 9,
            concreteCellIndex: 8,
            leftPanCount: 4,
            rightPanCount: 5,
            // The loop-v2 burst de-duplicates repeated facts for each target.
            // In deterministic UI-test mode, target 9 currently yields two unique
            // Sum Sprint cards, not three.
            expectedSumSprintPairs: 2,
            bondPairs: [(1, 8), (2, 7), (3, 6), (4, 5)],
            snapshotPrefix: "Issue222-Target9",
            skipInitialConcreteSnapshot: true
        )

        completeLoopV2Problem(
            in: app,
            target: 4,
            concreteCellIndex: 3,
            leftPanCount: 1,
            rightPanCount: 3,
            // Target 4 with decomposition (1,3) yields two Sum Sprint cards: "1+3" and "3+1"
            expectedSumSprintPairs: 2,
            bondPairs: [(1, 3), (2, 2)],
            snapshotPrefix: "Issue222-Target4",
            skipInitialConcreteSnapshot: true
        )

        completeLoopV2Problem(
            in: app,
            target: 12,
            concreteCellIndex: 11,
            leftPanCount: 5,
            rightPanCount: 7,
            expectedSumSprintPairs: 3,
            bondPairs: [(1, 11), (2, 10), (3, 9), (4, 8), (5, 7), (6, 6)],
            snapshotPrefix: "Issue222-Target12",
            skipInitialConcreteSnapshot: true
        )
    }

    // MARK: - Helpers

    /// Launches the app with CI-appropriate flags pre-configured via UserDefaults injection.
    private func launch() -> XCUIApplication {
        launchApp(with: [
            "-feature.audioEnabled", "NO",
            "-feature.hapticsEnabled", "NO",
            "-feature.testModeEnabled", "YES"
        ])
    }

    private func launchWithVS1(appearance: UIAppearanceMode? = nil) -> XCUIApplication {
        var launchArguments = [
            "-feature.audioEnabled", "NO",
            "-feature.hapticsEnabled", "NO",
            "-feature.testModeEnabled", "YES",
            "-feature.skipProfilePicker", "YES",
        ]
        if let appearance {
            launchArguments += ["-uiTest.appearance", appearance.launchValue]
        }
        return launchApp(with: launchArguments)
    }

    private func launchWithLoopV2(appearance: UIAppearanceMode? = nil) -> XCUIApplication {
        var launchArguments = [
            "-feature.audioEnabled", "NO",
            "-feature.hapticsEnabled", "NO",
            "-feature.motionControlsEnabled", "NO",
            "-feature.soundReactionEnabled", "NO",
            "-feature.testModeEnabled", "YES",
            "-feature.skipProfilePicker", "YES",
        ]
        if let appearance {
            launchArguments += ["-uiTest.appearance", appearance.launchValue]
        }
        return launchApp(with: launchArguments)
    }

    private func launchWithLegacyVS1(appearance: UIAppearanceMode? = nil) -> XCUIApplication {
        var launchArguments = [
            "-feature.audioEnabled", "NO",
            "-feature.hapticsEnabled", "NO",
            "-feature.makeBreakLoopV2Enabled", "NO",
            "-feature.testModeEnabled", "YES",
            "-feature.skipProfilePicker", "YES",
        ]
        if let appearance {
            launchArguments += ["-uiTest.appearance", appearance.launchValue]
        }
        return launchApp(with: launchArguments)
    }

    /// Launches the explicit legacy route with haptics on — use for tests that exercise success/failure feedback.
    private func launchWithLegacyVS1AndHaptics(appearance: UIAppearanceMode? = nil) -> XCUIApplication {
        var launchArguments = [
            "-feature.audioEnabled", "NO",
            "-feature.hapticsEnabled", "YES",
            "-feature.makeBreakLoopV2Enabled", "NO",
            "-feature.testModeEnabled", "YES",
            "-feature.skipProfilePicker", "YES",
        ]
        if let appearance {
            launchArguments += ["-uiTest.appearance", appearance.launchValue]
        }
        return launchApp(with: launchArguments)
    }

    private func launchWithSeededHistory(count: Int) -> XCUIApplication {
        launchApp(with: [
            "-feature.audioEnabled", "NO",
            "-feature.hapticsEnabled", "NO",
            "-feature.testModeEnabled", "YES",
            "-uiTest.seedHistory", "\(count)"
        ])
    }

    /// Launches with VS1 pre-enabled and Vehicle theme selected via launch argument.
    private func launchWithVehicleTheme(appearance: UIAppearanceMode? = nil) -> XCUIApplication {
        var launchArguments = [
            "-feature.audioEnabled", "NO",
            "-feature.hapticsEnabled", "NO",
            "-feature.testModeEnabled", "YES",
            "-feature.selectedThemeId", "vehicle"
        ]
        if let appearance {
            launchArguments += ["-uiTest.appearance", appearance.launchValue]
        }
        return launchApp(with: launchArguments)
    }

    private func launchApp(with arguments: [String]) -> XCUIApplication {
        continueAfterFailure = false

        let staleApp = XCUIApplication()
        if staleApp.state != .notRunning {
            staleApp.terminate()
            _ = staleApp.wait(for: .notRunning, timeout: 5)
        }

        let app = XCUIApplication()
        app.launchArguments = arguments
        addTeardownBlock {
            app.terminate()
        }
        app.launch()
        return app
    }

    /// Attaches a full-screen screenshot to the test result with `.keepAlways` lifetime.
    private func snapshot(_ app: XCUIApplication, _ name: String) {
        let screenshot = XCUIScreen.main.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    private func completeLoopV2Problem(
        in app: XCUIApplication,
        target: Int,
        concreteCellIndex: Int,
        leftPanCount: Int,
        rightPanCount: Int,
        expectedSumSprintPairs: Int,
        bondPairs: [(Int, Int)],
        snapshotPrefix: String,
        skipInitialConcreteSnapshot: Bool = false
    ) {
        advanceStoryAnchorIfPresent(in: app, snapshotPrefix: snapshotPrefix, shouldSnapshot: !skipInitialConcreteSnapshot)

        let concreteSubmit = app.buttons["That is \(target)"]
        XCTAssertTrue(concreteSubmit.waitForExistence(timeout: 15), "Expected concrete stage for target \(target)")
        if !skipInitialConcreteSnapshot {
            snapshot(app, "\(snapshotPrefix)-Concrete")
        }

        for index in 0...concreteCellIndex {
            let concreteCell = app.otherElements["counter-cell-\(index)"]
            if !concreteCell.waitForExistence(timeout: 3) {
                app.scrollViews.firstMatch.swipeUp()
            }
            XCTAssertTrue(concreteCell.waitForExistence(timeout: 5), "Expected concrete cell \(index) for target \(target)")
            concreteCell.tap()
        }
        concreteSubmit.tap()

        let gravityTitle = app.staticTexts["Gravity Split"]
        XCTAssertTrue(gravityTitle.waitForExistence(timeout: 15), "Expected Gravity Split after concrete target \(target)")
        snapshot(app, "\(snapshotPrefix)-GravitySplit")

        let gravityGoButton = app.buttons["gravity-go-button"]
        if gravityGoButton.waitForExistence(timeout: 3) {
            gravityGoButton.tap()
        }

        for _ in 0..<leftPanCount {
            tapGravityIncrement(
                in: app,
                identifiers: ["gravity-left-add-button", "gravity-left-plus"],
                zoneIdentifier: "gravity-left-zone",
                failureMessage: "Expected a left gravity increment control or zone"
            )
        }
        for _ in 0..<rightPanCount {
            tapGravityIncrement(
                in: app,
                identifiers: ["gravity-right-add-button", "gravity-right-plus"],
                zoneIdentifier: "gravity-right-zone",
                failureMessage: "Expected a right gravity increment control or zone"
            )
        }

        let sumSprintTitle = app.staticTexts["Sum Sprint"]
        XCTAssertTrue(sumSprintTitle.waitForExistence(timeout: 15), "Expected Sum Sprint after Gravity Split target \(target)")
        snapshot(app, "\(snapshotPrefix)-SumSprint")

        completeVisibleSumSprintPairs(in: app, target: target, expectedPairs: expectedSumSprintPairs)

        let bondBlastTitle = app.staticTexts["Bond Blast!"]
        XCTAssertTrue(bondBlastTitle.waitForExistence(timeout: 15), "Expected Bond Blast after Sum Sprint target \(target)")
        snapshot(app, "\(snapshotPrefix)-BondBlast")

        for (left, right) in bondPairs {
            let leftCard = app.buttons["bond-left-\(left)"]
            let rightCard = app.buttons["bond-right-\(right)"]
            XCTAssertTrue(leftCard.waitForExistence(timeout: 5), "Missing left Bond Blast card \(left) for target \(target)")
            XCTAssertTrue(rightCard.waitForExistence(timeout: 5), "Missing right Bond Blast card \(right) for target \(target)")
            leftCard.tap()
            rightCard.tap()
        }
    }


    private func tapGravityIncrement(
        in app: XCUIApplication,
        identifiers: [String],
        zoneIdentifier: String,
        failureMessage: String
    ) {
        if let control = firstExistingControl(in: app, identifiers: identifiers, timeout: 2) {
            control.tap()
            return
        }

        guard let zone = firstExistingControl(in: app, identifiers: [zoneIdentifier], timeout: 5) else {
            XCTFail(failureMessage)
            return
        }

        // Hosted UI review currently loses the compact SwiftUI add control from
        // the accessibility hierarchy even when the surrounding Gravity Split
        // destination zone remains discoverable. Keep the stronger identifier
        // contract above, then fall back to the user-visible interaction point:
        // the add affordance is rendered at the bottom center of each zone.
        zone.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.86)).tap()
    }

    /// Gravity Split is intentionally touch-first now. SwiftUI can expose the
    /// compact bordered add controls as generic accessibility descendants — or,
    /// on hosted iPhone/iPad runners, hide them behind the destination-zone
    /// composition altogether. The issue #222 UI review therefore keeps the
    /// add-control identifier lookup first and falls back to a discoverable zone
    /// element with the same visible user interaction point.
    private func firstExistingControl(in app: XCUIApplication, identifiers: [String], timeout: TimeInterval) -> XCUIElement? {
        let deadline = Date().addingTimeInterval(timeout)
        repeat {
            for identifier in identifiers {
                if let button = firstExistingElement(in: app.buttons, identifier: identifier) {
                    return button
                }
                if let otherElement = firstExistingElement(in: app.otherElements, identifier: identifier) {
                    return otherElement
                }
                if let descendant = firstExistingElement(in: app.descendants(matching: .any), identifier: identifier) {
                    return descendant
                }
            }
            RunLoop.current.run(until: Date().addingTimeInterval(0.2))
        } while Date() < deadline
        return nil
    }

    private func firstExistingElement(in query: XCUIElementQuery, identifier: String) -> XCUIElement? {
        let exact = query[identifier]
        if exact.exists { return exact }

        let prefixed = query.matching(NSPredicate(format: "identifier BEGINSWITH %@", identifier)).firstMatch
        if prefixed.exists { return prefixed }

        return nil
    }

    private func advanceStoryAnchorIfPresent(in app: XCUIApplication, snapshotPrefix: String, shouldSnapshot: Bool) {
        let storyAnchorCard = app.otherElements["story-anchor-card"]
        let storyAnchorStart = app.buttons["story-anchor-start-button"]
        let storyAnchorStartLabel = app.buttons["Start building"]

        guard storyAnchorCard.waitForExistence(timeout: 5) || storyAnchorStart.exists || storyAnchorStartLabel.exists else {
            return
        }

        if shouldSnapshot {
            snapshot(app, "\(snapshotPrefix)-StoryAnchor")
        }

        for _ in 0..<4 {
            if storyAnchorStart.exists && storyAnchorStart.isHittable {
                storyAnchorStart.tap()
                return
            }
            if storyAnchorStartLabel.exists && storyAnchorStartLabel.isHittable {
                storyAnchorStartLabel.tap()
                return
            }
            app.scrollViews.firstMatch.swipeUp()
        }

        XCTFail("Expected Story Anchor start button before concrete stage")
    }

    private func completeVisibleSumSprintPairs(in app: XCUIApplication, target: Int, expectedPairs: Int) {
        let promptPrefix = "sumsprint-prompt-"
        let sumPrefix = "sumsprint-sum-"
        var usedPromptTokens = Set<String>()

        for pairIndex in 0..<expectedPairs {
            let promptButtons = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@", promptPrefix))
            var selectedPrompt: XCUIElement?
            var promptToken = ""

            for index in 0..<promptButtons.count {
                let button = promptButtons.element(boundBy: index)
                let identifier = button.identifier
                guard identifier.hasPrefix(promptPrefix), button.waitForExistence(timeout: 1), button.isHittable else { continue }
                let candidateToken = String(identifier.dropFirst(promptPrefix.count))
                guard !usedPromptTokens.contains(candidateToken) else { continue }
                promptToken = candidateToken
                selectedPrompt = button
                break
            }

            guard let promptButton = selectedPrompt else {
                XCTFail("Expected a new hittable Sum Sprint prompt for target \(target) pair \(pairIndex + 1); already used \(usedPromptTokens)")
                return
            }
            promptButton.tap()

            let sumButtons = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@", sumPrefix))
            var selectedSum: XCUIElement?
            for index in 0..<sumButtons.count {
                let button = sumButtons.element(boundBy: index)
                let identifier = button.identifier
                guard identifier.contains("-for-\(promptToken)"), button.waitForExistence(timeout: 1), button.isHittable else { continue }
                selectedSum = button
                break
            }

            guard let sumButton = selectedSum else {
                XCTFail("Expected a hittable Sum Sprint sum match for prompt token \(promptToken) on target \(target) pair \(pairIndex + 1)")
                return
            }
            sumButton.tap()
            usedPromptTokens.insert(promptToken)
        }
    }

    private func waitForHistoryRow(_ app: XCUIApplication, identifier: String, fallbackLabel: String, timeout: TimeInterval) -> Bool {
        let deadline = Date().addingTimeInterval(timeout)
        let identified = app.descendants(matching: .any)[identifier]
        let labeled = app.staticTexts[fallbackLabel].firstMatch
        while Date() < deadline {
            if identified.exists || labeled.exists {
                return true
            }
            RunLoop.current.run(until: Date().addingTimeInterval(0.2))
        }
        return identified.exists || labeled.exists
    }
}
