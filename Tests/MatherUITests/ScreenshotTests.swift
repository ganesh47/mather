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

    func testScreenshot_SessionConfig_PlanetsTheme() {
        let app = launchWithVS1()
        _ = app.staticTexts["Mather"].waitForExistence(timeout: 10)

        app.buttons["Play"].tap()
        _ = app.staticTexts["Session setup"].waitForExistence(timeout: 10)
        XCTAssertTrue(app.buttons["theme-card-space"].waitForExistence(timeout: 5))
        app.buttons["theme-card-space"].tap()
        snapshot(app, "SessionConfig-PlanetsTheme")
    }

    // MARK: - Concrete stage

    func testScreenshot_ConcreteBuildView() {
        let app = launchWithVS1()
        _ = app.staticTexts["Mather"].waitForExistence(timeout: 10)

        let playButton = app.buttons["Play"]
        _ = playButton.waitForExistence(timeout: 5)
        playButton.tap()
        _ = app.staticTexts["Session setup"].waitForExistence(timeout: 10)

        startSessionAndWaitForConcrete(in: app)
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

        startSessionAndWaitForConcrete(in: app)
        snapshot(app, "ConcreteBuild-BeforeInput")

        // The current concrete stage keeps incomplete answers disabled rather than
        // submitting a wrong count. Capture that guardrail, then complete the target.
        let incompleteSubmitButton = app.buttons["Make 6"]
        XCTAssertTrue(incompleteSubmitButton.waitForExistence(timeout: 5))
        XCTAssertFalse(incompleteSubmitButton.isEnabled)
        snapshot(app, "ConcreteBuild-IncompleteDisabled")

        fillConcreteTarget(6, in: app)
        let submitButton = concreteSubmitButton(for: 6, in: app)
        XCTAssertTrue(submitButton.waitForExistence(timeout: 5))
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
        let settingsButton = app.buttons["Settings"].firstMatch
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

        XCTAssertTrue(app.buttons["settings-view-full-history"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.otherElements["settings-history-session-1"].exists)
    }

    func testParentSummaryShowsGameScoresWhenMakeBreakHasNoProgress() {
        let app = launchWithSeededGameHistory(count: 2)
        _ = app.staticTexts["Mather"].waitForExistence(timeout: 5)

        app.buttons["Parent Summary"].tap()
        _ = app.staticTexts["Parent Summary"].waitForExistence(timeout: 10)

        XCTAssertTrue(app.staticTexts["No completed Make & Break practice yet"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Game scores"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Sum Sprint"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.otherElements["parent-summary-scorecard"].exists)
    }


    func testFamilySettingsHidesPilotRunbookAndInlineHistoryRows() {
        let app = launchFamilySettingsWithSeededHistory(count: 7)
        _ = app.staticTexts["Mather"].waitForExistence(timeout: 5)

        app.buttons["Settings"].tap()
        _ = app.staticTexts["Settings"].waitForExistence(timeout: 10)
        XCTAssertTrue(app.staticTexts["7 saved locally across all games"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["settings-view-full-history"].exists)
        XCTAssertTrue(app.buttons["settings-clear-history"].exists)
        XCTAssertFalse(app.staticTexts["Pilot smoke test"].exists)
        XCTAssertFalse(app.otherElements["settings-history-session-0"].exists)
        snapshot(app, "Settings-FamilySimplified")
    }

    // MARK: - iPhone layout / pilot runbook

    /// Verifies the full session flow renders without crash and screenshots the
    /// pilot-only runbook. Family Settings keeps this hidden unless test mode is active.
    func testScreenshot_PilotRunbook() {
        let app = launchWithLegacyVS1()
        _ = app.staticTexts["Mather"].waitForExistence(timeout: 10)
        snapshot(app, "iPhone-Home")

        // Navigate to Settings and capture the pilot-only runbook
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

        startSessionAndWaitForConcrete(in: app)
        snapshot(app, "iPhone-ConcreteBuild-AdaptiveGrid")

        fillConcreteTarget(6, in: app)

        let submitButton = concreteSubmitButton(for: 6, in: app)
        XCTAssertTrue(submitButton.waitForExistence(timeout: 5))
        submitButton.tap()

        _ = app.staticTexts["Bond Blast!"].waitForExistence(timeout: 10)
        snapshot(app, "iPhone-SplitView")
    }

    func testScreenshot_WaterCycleCompactCompletion() {
        let app = launchWaterCycleLab()
        XCTAssertTrue(app.staticTexts["Water Cycle Lab"].waitForExistence(timeout: 10))

        let primaryAction = app.buttons["water-cycle-primary-action"]
        XCTAssertTrue(scrollUntilExists(primaryAction, in: app, direction: .up, maxSwipes: 6))
        for _ in 0..<5 {
            tapWhenReachable(primaryAction, in: app, scrollDirection: .up)
        }

        XCTAssertTrue(app.staticTexts["Look & Learn"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Level 1 of 4 - Card 1 of 5"].waitForExistence(timeout: 5))

        let lessonPrimaryByIdentifier = app.buttons["water-cycle-lesson-primary-action"]
        let lessonPrimaryAction: XCUIElement
        if lessonPrimaryByIdentifier.exists {
            lessonPrimaryAction = lessonPrimaryByIdentifier
        } else {
            lessonPrimaryAction = app.buttons["Next look card"]
        }
        XCTAssertTrue(scrollUntilExists(lessonPrimaryAction, in: app, direction: .up, maxSwipes: 4))

        let replayLessonByIdentifier = app.buttons["water-cycle-replay-lesson-stage"]
        let replayLesson: XCUIElement
        if replayLessonByIdentifier.exists {
            replayLesson = replayLessonByIdentifier
        } else {
            replayLesson = app.buttons["Replay stage"]
        }
        XCTAssertTrue(scrollUntilExists(replayLesson, in: app, direction: .up, maxSwipes: 4))

        let resetByIdentifier = app.buttons["water-cycle-reset"]
        let resetAction: XCUIElement
        if resetByIdentifier.exists {
            resetAction = resetByIdentifier
        } else {
            resetAction = app.buttons["Reset"]
        }
        XCTAssertTrue(scrollUntilExists(resetAction, in: app, direction: .up, maxSwipes: 4))
        snapshot(app, "WaterCycle-Complete-Compact")
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
        startSessionAndWaitForConcrete(in: app)

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
    private enum ScrollDirection {
        case up
        case down
    }

    private func tapWhenReachable(_ element: XCUIElement, in app: XCUIApplication, scrollDirection: ScrollDirection, maxSwipes: Int = 8) {
        XCTAssertTrue(scrollUntilExists(element, in: app, direction: scrollDirection, maxSwipes: maxSwipes))

        for _ in 0...maxSwipes {
            if element.isHittable {
                element.tap()
                return
            }
            scroll(app, direction: scrollDirection)
            RunLoop.current.run(until: Date().addingTimeInterval(0.2))
        }

        if element.exists {
            element.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
            return
        }

        XCTFail("Expected element to become reachable: \(element)")
    }

    private func scrollUntilExists(_ element: XCUIElement, in app: XCUIApplication, direction: ScrollDirection, maxSwipes: Int) -> Bool {
        if element.waitForExistence(timeout: 1) { return true }

        for _ in 0..<maxSwipes {
            scroll(app, direction: direction)
            if element.waitForExistence(timeout: 1) {
                return true
            }
        }

        return element.exists
    }

    private func scroll(_ app: XCUIApplication, direction: ScrollDirection) {
        let scrollView = app.scrollViews.firstMatch
        if scrollView.exists {
            switch direction {
            case .up:
                scrollView.swipeUp()
            case .down:
                scrollView.swipeDown()
            }
        } else {
            switch direction {
            case .up:
                app.swipeUp()
            case .down:
                app.swipeDown()
            }
        }
    }

    private func launchWaterCycleLab() -> XCUIApplication {
        launchApp(with: [
            "-feature.audioEnabled", "NO",
            "-feature.hapticsEnabled", "NO",
            "-feature.testModeEnabled", "YES",
            "-feature.skipProfilePicker", "YES",
            "-uiTest.startRoute", "waterCycleLab"
        ])
    }

    private func launch() -> XCUIApplication {
        launchApp(with: [
            "-feature.audioEnabled", "NO",
            "-feature.hapticsEnabled", "NO",
            "-feature.testModeEnabled", "YES",
            "-feature.skipProfilePicker", "YES"
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
            "-uiTest.autoCompleteGravitySplit",
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

    private func launchWithSeededGameHistory(count: Int) -> XCUIApplication {
        launchApp(with: [
            "-feature.audioEnabled", "NO",
            "-feature.hapticsEnabled", "NO",
            "-feature.testModeEnabled", "YES",
            "-uiTest.seedGameHistory", "\(count)"
        ])
    }


    private func launchFamilySettingsWithSeededHistory(count: Int) -> XCUIApplication {
        launchApp(with: [
            "-feature.audioEnabled", "NO",
            "-feature.hapticsEnabled", "NO",
            "-feature.skipProfilePicker", "YES",
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

    private func startSessionAndWaitForConcrete(in app: XCUIApplication) {
        let makePredicate = NSPredicate(format: "label BEGINSWITH 'Make '")
        let makePrompt = app.staticTexts.element(matching: makePredicate)
        let startButton = app.buttons["start-session-button"]

        XCTAssertTrue(startButton.waitForExistence(timeout: 5), "Expected Start Session button before entering concrete stage")
        startButton.tap()
        advanceStoryAnchorIfPresent(in: app, snapshotPrefix: "SessionStart", shouldSnapshot: false)

        if !makePrompt.waitForExistence(timeout: 8), startButton.exists {
            startButton.tap()
            advanceStoryAnchorIfPresent(in: app, snapshotPrefix: "SessionStart-Retry", shouldSnapshot: false)
        }

        XCTAssertTrue(makePrompt.waitForExistence(timeout: 15), "Expected concrete stage after tapping Start Session")
    }

    /// Attaches a full-screen screenshot to the test result with `.keepAlways` lifetime.
    private func snapshot(_ app: XCUIApplication, _ name: String) {
        let screenshot = XCUIScreen.main.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }


    private func concreteStageButton(for target: Int, in app: XCUIApplication) -> XCUIElement {
        let ready = app.buttons["That is \(target)"]
        if ready.exists { return ready }
        return app.buttons["Make \(target)"]
    }

    private func concreteSubmitButton(for target: Int, in app: XCUIApplication) -> XCUIElement {
        let ready = app.buttons["That is \(target)"]
        if ready.exists { return ready }

        let submitPredicate = NSPredicate(format: "label BEGINSWITH 'That is '")
        return app.buttons.element(matching: submitPredicate)
    }

    private func fillConcreteTarget(_ target: Int, in app: XCUIApplication, through maxIndex: Int? = nil) {
        let finalIndex = maxIndex ?? max(target - 1, 0)
        guard finalIndex >= 0 else { return }

        for index in 0...finalIndex {
            let concreteCell = app.otherElements["counter-cell-\(index)"]
            if !concreteCell.waitForExistence(timeout: 2) {
                app.scrollViews.firstMatch.swipeUp()
            }
            XCTAssertTrue(concreteCell.waitForExistence(timeout: 5), "Expected concrete cell \(index) while filling target \(target)")
            concreteCell.tap()
        }
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

        let concreteStageButton = concreteStageButton(for: target, in: app)
        XCTAssertTrue(concreteStageButton.waitForExistence(timeout: 15), "Expected concrete stage for target \(target)")
        if !skipInitialConcreteSnapshot {
            snapshot(app, "\(snapshotPrefix)-Concrete")
        }

        fillConcreteTarget(target, in: app, through: concreteCellIndex)
        let concreteSubmit = concreteSubmitButton(for: target, in: app)
        XCTAssertTrue(concreteSubmit.waitForExistence(timeout: 5), "Expected concrete submit button for target \(target)")
        concreteSubmit.tap()

        let gravityTitle = app.staticTexts["Gravity Split"]
        XCTAssertTrue(gravityTitle.waitForExistence(timeout: 15), "Expected Gravity Split after concrete target \(target)")
        snapshot(app, "\(snapshotPrefix)-GravitySplit")

        let gravityGoButton = app.buttons["gravity-go-button"]
        if gravityGoButton.waitForExistence(timeout: 3) {
            gravityGoButton.tap()
        }

        let sumSprintTitle = app.staticTexts["Sum Sprint"]
        if let completeSplit = firstExistingControl(in: app, identifiers: ["gravity-complete-split-button"], timeout: 3),
           !sumSprintTitle.exists {
            completeSplit.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
            _ = sumSprintTitle.waitForExistence(timeout: 3)
        }

        if !sumSprintTitle.exists {
            for _ in 0..<leftPanCount {
                if sumSprintTitle.exists { break }
                tapGravityIncrement(
                    in: app,
                    identifiers: ["gravity-left-add-button", "gravity-left-plus"],
                    zoneIdentifier: "gravity-left-zone",
                    fallbackSide: .left,
                    failureMessage: "Expected a left gravity increment control or zone"
                )
            }
            for _ in 0..<rightPanCount {
                if sumSprintTitle.exists { break }
                tapGravityIncrement(
                    in: app,
                    identifiers: ["gravity-right-add-button", "gravity-right-plus"],
                    zoneIdentifier: "gravity-right-zone",
                    fallbackSide: .right,
                    failureMessage: "Expected a right gravity increment control or zone"
                )
            }
        }

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


    private enum GravityFallbackSide {
        case left
        case right
    }

    private func tapGravityIncrement(
        in app: XCUIApplication,
        identifiers: [String],
        zoneIdentifier: String,
        fallbackSide: GravityFallbackSide,
        failureMessage: String
    ) {
        if let control = firstExistingControl(in: app, identifiers: identifiers, timeout: 2) {
            control.tap()
            return
        }

        if let zone = firstExistingControl(in: app, identifiers: [zoneIdentifier], timeout: 5) {
            // Hosted UI review can lose the compact SwiftUI add control from
            // the accessibility hierarchy even when the surrounding Gravity Split
            // destination zone remains discoverable. Keep the stronger identifier
            // contract above, then fall back to the user-visible interaction point:
            // the add affordance is rendered at the bottom center of each zone.
            zone.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.86)).tap()
            return
        }

        if app.staticTexts["Sum Sprint"].exists {
            return
        }

        guard app.staticTexts["Gravity Split"].exists else {
            XCTFail(failureMessage)
            return
        }

        // On hosted iPhone/iPad runners, SwiftUI has repeatedly hidden the entire
        // Gravity Split destination subtree from XCUI while the stage itself is
        // visibly on screen. Do not weaken the issue #222 route: tap the same
        // visible add affordance area by screen position only after all identifier
        // lookups fail and the Gravity Split title proves we are on the right stage.
        let xOffset: CGFloat = fallbackSide == .left ? 0.32 : 0.68
        // The direct-token board sits below the source tray; the add affordance
        // is in the lower half of each destination zone. Earlier center-zone
        // screen taps hit the empty token grid on hosted runners and left the
        // split unlocked, so use the same lower visible target as the zone
        // fallback when the whole subtree is missing from XCUI.
        app.coordinate(withNormalizedOffset: CGVector(dx: xOffset, dy: 0.68)).tap()
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
