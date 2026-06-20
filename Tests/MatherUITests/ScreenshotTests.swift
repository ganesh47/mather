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
        requireExists(app.staticTexts["Mather"], timeout: 5)
        snapshot(app, "Home-VS1Disabled")
    }

    // MARK: - Appearance regression

    func testScreenshot_AppearanceModes_HomeAndSessionConfig() {
        let light = launchWithVS1(appearance: .light)
        requireExists(light.staticTexts["Mather"], timeout: 10)
        snapshot(light, "Appearance-Light-Home")
        light.buttons["Play"].tap()
        requireExists(light.staticTexts["Session setup"], timeout: 10)
        snapshot(light, "Appearance-Light-SessionConfig")

        let dark = launchWithVS1(appearance: .dark)
        requireExists(dark.staticTexts["Mather"], timeout: 10)
        snapshot(dark, "Appearance-Dark-Home")
        dark.buttons["Play"].tap()
        requireExists(dark.staticTexts["Session setup"], timeout: 10)
        snapshot(dark, "Appearance-Dark-SessionConfig")
    }

    // MARK: - Settings screen

    func testScreenshot_Settings_MakeBreakLoopBuiltIn() {
        let app = launch()
        requireExists(app.staticTexts["Mather"], timeout: 5)

        app.buttons["Settings"].tap()
        requireExists(app.staticTexts["Settings"], timeout: 3)
        XCTAssertFalse(app.switches["settings-loop-v2-toggle"].exists)
        XCTAssertTrue(app.staticTexts["Make it → Gravity Split → Sum Sprint → Bond Blast is built in for every target."].waitForExistence(timeout: 5))
        snapshot(app, "Settings-MakeBreakLoopBuiltIn")

        app.buttons["Home"].tap()
        requireExists(app.staticTexts["Mather"], timeout: 3)
        snapshot(app, "Home-MakeBreakLoopBuiltIn")
    }

    // MARK: - Session Config screen

    func testScreenshot_SessionConfig() {
        // Pre-enable VS1 via launch argument to skip Settings navigation.
        let app = launchWithVS1()
        requireExists(app.staticTexts["Mather"], timeout: 10)

        let playButton = app.buttons["Play"]
        requireExists(playButton, timeout: 5)
        playButton.tap()
        requireExists(app.staticTexts["Session setup"], timeout: 10)
        snapshot(app, "SessionConfig")
    }

    func testScreenshot_SessionConfig_PlanetsTheme() {
        let app = launchWithVS1()
        requireExists(app.staticTexts["Mather"], timeout: 10)

        app.buttons["Play"].tap()
        requireExists(app.staticTexts["Session setup"], timeout: 10)
        XCTAssertTrue(app.buttons["theme-card-space"].waitForExistence(timeout: 5))
        app.buttons["theme-card-space"].tap()
        snapshot(app, "SessionConfig-PlanetsTheme")
    }

    // MARK: - Concrete stage

    func testScreenshot_ConcreteBuildView() {
        let app = launchWithVS1()
        requireExists(app.staticTexts["Mather"], timeout: 10)

        let playButton = app.buttons["Play"]
        requireExists(playButton, timeout: 5)
        playButton.tap()
        requireExists(app.staticTexts["Session setup"], timeout: 10)

        startSessionAndWaitForConcrete(in: app)
        snapshot(app, "ConcreteBuild-Initial")
    }

    // MARK: - Haptics / feedback flow

    /// Exercises the failure-then-success path so the screen recording captures
    /// both the failure feedback banner and the celebration state.
    func testScreenshot_ConcreteBuild_FailureThenSuccess() {
        let app = launchWithLegacyVS1AndHaptics()
        requireExists(app.staticTexts["Mather"], timeout: 10)

        let playButton = app.buttons["Play"]
        requireExists(playButton, timeout: 5)
        playButton.tap()
        requireExists(app.staticTexts["Session setup"], timeout: 10)

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
        requireExists(app.staticTexts["Bond Blast!"], timeout: 10)
        snapshot(app, "Pictorial-AfterConcreteSuccess")
    }

    func testConcreteBuild_AccentRowLockedUntilWarmFull() throws {
        throw XCTSkip("UI test mode starts on deterministic target 6, which does not expose a real accent row. Warm/accent split logic is covered in VerticalSliceEngineTests until a >10 UI fixture exists.")
    }

    // MARK: - Parent Summary screen

    func testScreenshot_ParentSummary() {
        let app = launch()
        requireExists(app.staticTexts["Mather"], timeout: 5)
        app.buttons["Parent Summary"].tap()
        requireExists(app.staticTexts["Parent Summary"], timeout: 10)
        snapshot(app, "ParentSummary-Empty")

        // Navigate to Settings from Parent Summary
        let settingsButton = app.buttons["Settings"].firstMatch
        requireExists(settingsButton, timeout: 5)
        settingsButton.tap()
        requireExists(app.staticTexts["Settings"], timeout: 10)
        snapshot(app, "Settings-FromParentSummary")

        // Tap clear — confirm dialog should appear
        let clearButton = app.buttons["Clear session history"]
        requireExists(clearButton, timeout: 5)
        clearButton.tap()
        requireExists(app.alerts["Clear all session data?"], timeout: 5)
        snapshot(app, "Settings-ClearConfirmDialog")

        // Dismiss with Cancel
        app.alerts["Clear all session data?"].buttons["Cancel"].tap()
        snapshot(app, "Settings-AfterCancelClear")
    }

    func testSessionHistoryShowsMultipleSavedSessionsInParentSummaryAndSettings() {
        let app = launchWithSeededHistory(count: 2)
        requireExists(app.staticTexts["Mather"], timeout: 5)

        app.buttons["Parent Summary"].tap()
        requireExists(app.staticTexts["Parent Summary"], timeout: 10)
        XCTAssertTrue(app.staticTexts["2 saved locally"].waitForExistence(timeout: 5))

        XCTAssertTrue(waitForHistoryRow(app, identifier: "parent-summary-session-1", fallbackLabel: "Session 2", timeout: 5))

        app.buttons["Settings"].tap()
        requireExists(app.staticTexts["Settings"], timeout: 10)
        XCTAssertTrue(app.staticTexts["2 saved locally"].waitForExistence(timeout: 5))

        XCTAssertTrue(app.buttons["settings-view-full-history"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.otherElements["settings-history-session-1"].exists)
    }

    func testParentSummaryShowsGameScoresWhenMakeBreakHasNoProgress() {
        let app = launchWithSeededGameHistory(count: 2)
        requireExists(app.staticTexts["Mather"], timeout: 5)

        app.buttons["Parent Summary"].tap()
        requireExists(app.staticTexts["Parent Summary"], timeout: 10)

        XCTAssertTrue(app.staticTexts["No completed Make & Break practice yet"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Game scores"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Sum Sprint"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.otherElements["parent-summary-scorecard"].exists)
    }


    func testFamilySettingsHidesPilotRunbookAndInlineHistoryRows() {
        let app = launchFamilySettingsWithSeededHistory(count: 7)
        requireExists(app.staticTexts["Mather"], timeout: 5)

        openParentLockedSettings(in: app)
        requireExists(app.staticTexts["Settings"], timeout: 10)
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
        requireExists(app.staticTexts["Mather"], timeout: 10)
        snapshot(app, "iPhone-Home")

        // Navigate to Settings and capture the pilot-only runbook
        app.buttons["Settings"].tap()
        requireExists(app.staticTexts["Settings"], timeout: 10)
        XCTAssertFalse(app.switches["settings-loop-v2-toggle"].exists)
        requireExists(app.staticTexts["Pilot smoke test"], timeout: 5)
        snapshot(app, "iPhone-Settings-PilotRunbook")
        app.buttons["Home"].tap()

        // Run one full problem to verify no crash on compact layout
        requireExists(app.buttons["Play"], timeout: 10)
        app.buttons["Play"].tap()
        requireExists(app.staticTexts["Session setup"], timeout: 10)
        snapshot(app, "iPhone-SessionConfig")

        startSessionAndWaitForConcrete(in: app)
        snapshot(app, "iPhone-ConcreteBuild-AdaptiveGrid")

        fillConcreteTarget(6, in: app)

        let submitButton = concreteSubmitButton(for: 6, in: app)
        XCTAssertTrue(submitButton.waitForExistence(timeout: 5))
        submitButton.tap()

        requireExists(app.staticTexts["Bond Blast!"], timeout: 10)
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
        requireExists(app.staticTexts["Mather"], timeout: 10)

        app.buttons["Play"].tap()
        requireExists(app.staticTexts["Session setup"], timeout: 10)
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

    // MARK: - Deep crash sweep

    func testDeepCrashSweep_ExplorerLabAndCoreSurfaces() {
        let shell = launchForCrashSweep()
        requireExists(shell.staticTexts["Mather"], timeout: 10)

        shell.buttons["Settings"].tap()
        requireExists(shell.staticTexts["Settings"], timeout: 10)
        assertAlive(shell, "settings")

        shell.buttons["Home"].tap()
        requireExists(shell.staticTexts["Mather"], timeout: 10)

        shell.buttons["Parent Summary"].tap()
        requireExists(shell.staticTexts["Parent Summary"], timeout: 10)
        assertAlive(shell, "parent summary")

        let makeBreak = launchForCrashSweep()
        requireExists(makeBreak.staticTexts["Mather"], timeout: 10)
        makeBreak.buttons["Play"].tap()
        requireExists(makeBreak.staticTexts["Session setup"], timeout: 10)
        startSessionAndWaitForConcrete(in: makeBreak)
        assertAlive(makeBreak, "make and break concrete stage")

        fillConcreteTarget(6, in: makeBreak)
        tapButton(labelBeginsWith: "That is ", in: makeBreak)
        XCTAssertTrue(
            makeBreak.staticTexts["Gravity Split"].waitForExistence(timeout: 15)
                || makeBreak.staticTexts["Sum Sprint"].waitForExistence(timeout: 15)
                || makeBreak.staticTexts["Bond Blast!"].waitForExistence(timeout: 15)
        )
        assertAlive(makeBreak, "make and break post-concrete transition")

        verifyCrashSweepGameEntry("Sum Sprint", expects: "Sum Sprint") { app in
            tapButton(labelBeginsWith: "Relaxed", in: app)
            XCTAssertTrue(app.staticTexts.element(matching: NSPredicate(format: "label BEGINSWITH 'Card '")).waitForExistence(timeout: 10))
        }

        verifyCrashSweepGameEntry("Room Quest", expects: "Set up the room") { app in
            completeCrashSweepRoomQuestManualFallback(in: app)
            requireExists(app.staticTexts["Red Rocket"], timeout: 10)
        }

        verifyCrashSweepGameEntry("Symmetry Fold", expects: "Symmetry Fold") { app in
            requireExists(app.otherElements["symmetry-fold-scene"], timeout: 10)
        }

        verifyCrashSweepGameEntry("Rectangle Factory", expects: "Rectangle Factory") { app in
            requireExists(app.buttons["rectangle-factory-reset"], timeout: 10)
        }

        verifyCrashSweepGameEntry("Angle Cannon", expects: "Angle Cannon") { app in
            requireExists(app.buttons["angle-cannon-fire-button"], timeout: 10)
            app.buttons["angle-cannon-fire-button"].tap()
        }

        verifyCrashSweepGameEntry("Protractor", expects: "Two-Finger Protractor") { app in
            requireExists(app.otherElements["protractor-angle-match-prelude"], timeout: 10)
            let firstCard = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH 'protractor-angle-card-'")).firstMatch
            requireExists(firstCard, timeout: 10)
            firstCard.tap()
        }

        verifyCrashSweepGameEntry("Gravity Artist", expects: "Gravity Quest") { app in
            requireExists(app.buttons["gravity-crisp-action-button"], timeout: 10)
            app.buttons["gravity-crisp-action-button"].tap()
        }

        verifyCrashSweepGameEntry("Compass Walk", expects: "Compass Walk") { app in
            tapButton(labelBeginsWith: "START", in: app)
            let fallback = app.buttons.element(matching: NSPredicate(format: "label BEGINSWITH %@", "I'm facing"))
            if fallback.waitForExistence(timeout: 12) {
                fallback.tap()
            }
        }

        verifyCrashSweepGameEntry("Memory Match", expects: "Memory Match") { app in
            requireExists(app.buttons["memory-deck-menu"], timeout: 10)
            requireExists(app.buttons["memory-difficulty-menu"], timeout: 10)
        }
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

    private func launchForCrashSweep() -> XCUIApplication {
        launchApp(with: [
            "-feature.audioEnabled", "NO",
            "-feature.hapticsEnabled", "NO",
            "-feature.motionControlsEnabled", "NO",
            "-feature.soundReactionEnabled", "NO",
            "-feature.testModeEnabled", "YES",
            "-feature.skipProfilePicker", "YES",
            "-feature.roomQuestSafetyAcknowledged", "YES",
            "-feature.roomQuestMarkerSetupEnabled", "YES",
            "-feature.roomQuestReferenceCaptureEnabled", "YES",
            "-uiTest.autoCompleteGravitySplit"
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

    private func verifyCrashSweepGameEntry(
        _ gameName: String,
        expects expectedText: String,
        exercise: (XCUIApplication) -> Void
    ) {
        let app = launchForCrashSweep()
        openExplorerLabForCrashSweep(in: app)

        let gameTile = app.buttons.element(matching: NSPredicate(format: "label CONTAINS %@", gameName))
        XCTAssertTrue(scrollUntilExists(gameTile, in: app, direction: .up, maxSwipes: 8), "Missing game tile: \(gameName)")
        tapWhenReachable(gameTile, in: app, scrollDirection: .up, maxSwipes: 4)

        requireExists(app.staticTexts[expectedText], timeout: 15)
        assertAlive(app, "\(gameName) opened")

        exercise(app)
        assertAlive(app, "\(gameName) exercised")
    }

    private func openExplorerLabForCrashSweep(in app: XCUIApplication) {
        requireExists(app.staticTexts["Mather"], timeout: 10)
        app.buttons["GamesEntry"].tap()
        requireExists(app.staticTexts["Explorer Lab"], timeout: 10)
    }

    private func completeCrashSweepRoomQuestManualFallback(in app: XCUIApplication) {
        let redCard = app.otherElements["room-station-card-redRocket"]
        let blueCard = app.otherElements["room-station-card-blueBubble"]
        requireExists(redCard, timeout: 10)
        requireExists(blueCard, timeout: 10)

        redCard.buttons["Scan station marker"].tap()
        requireExists(app.staticTexts["room-scan-status"], timeout: 5)
        tapWhenReachable(redCard.buttons["Save same-place fallback"], in: app, scrollDirection: .up)

        blueCard.buttons["Scan station marker"].tap()
        requireExists(app.staticTexts["room-scan-status"], timeout: 5)
        tapWhenReachable(blueCard.buttons["Save same-place fallback"], in: app, scrollDirection: .up)

        requireExists(app.buttons["Ready, start Room Quest!"], timeout: 5)
        app.buttons["Ready, start Room Quest!"].tap()
    }

    private func tapCrashSweepCounter(_ identifier: String, in app: XCUIApplication) {
        let counter = app.otherElements[identifier]
        if !counter.waitForExistence(timeout: 3) {
            app.scrollViews.firstMatch.swipeUp()
        }
        requireExists(counter, timeout: 5)
        counter.tap()
    }

    private func tapButton(labelBeginsWith prefix: String, in app: XCUIApplication) {
        let button = app.buttons.element(matching: NSPredicate(format: "label BEGINSWITH %@", prefix))
        requireExists(button, timeout: 10)
        button.tap()
    }

    private func assertAlive(_ app: XCUIApplication, _ checkpoint: String) {
        XCTAssertNotEqual(app.state, .notRunning, "App crashed or exited at checkpoint: \(checkpoint)")
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

    private func openParentLockedSettings(in app: XCUIApplication) {
        app.buttons["Settings"].tap()
        if app.staticTexts["Parent unlock"].waitForExistence(timeout: 2) {
            let unlockButton = app.buttons["parent-unlock-hold-button"]
            XCTAssertTrue(unlockButton.waitForExistence(timeout: 5))
            unlockButton.press(forDuration: 1.1)
        }
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
        waitForLoopV2ConcreteStage(in: app, target: target, snapshotPrefix: snapshotPrefix, shouldSnapshotStoryAnchor: !skipInitialConcreteSnapshot)

        let concreteStageButton = concreteStageButton(for: target, in: app)
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
        var reachedSumSprintAfterCompleteSplit = false
        if let completeSplit = firstExistingControl(in: app, identifiers: ["gravity-complete-split-button"], timeout: 3),
           !sumSprintTitle.exists {
            completeSplit.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
            reachedSumSprintAfterCompleteSplit = sumSprintTitle.waitForExistence(timeout: 3)
        }

        if !reachedSumSprintAfterCompleteSplit && !sumSprintTitle.exists {
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

    private func waitForLoopV2ConcreteStage(
        in app: XCUIApplication,
        target: Int,
        snapshotPrefix: String,
        shouldSnapshotStoryAnchor: Bool
    ) {
        let concreteStageButton = concreteStageButton(for: target, in: app)
        let deadline = Date().addingTimeInterval(30)
        var attemptedStoryAnchor = false

        repeat {
            if concreteStageButton.exists {
                return
            }

            if !attemptedStoryAnchor,
               storyAnchorIsPresent(in: app) {
                advanceStoryAnchorIfPresent(in: app, snapshotPrefix: snapshotPrefix, shouldSnapshot: shouldSnapshotStoryAnchor)
                attemptedStoryAnchor = true
            }

            RunLoop.current.run(until: Date().addingTimeInterval(0.25))
        } while Date() < deadline

        XCTAssertTrue(concreteStageButton.waitForExistence(timeout: 1), "Expected concrete stage for target \(target)")
    }

    private func storyAnchorIsPresent(in app: XCUIApplication) -> Bool {
        app.otherElements["story-anchor-card"].exists
            || app.buttons["story-anchor-start-button"].exists
            || app.buttons["Start building"].exists
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

    // MARK: - UX Review — Phase 1/2/3/4 verification

    /// Phase 1: GameplayThreadView should show exactly one Back button (in topChrome).
    /// Verifies the duplicate bottom Back button has been removed.
    func testScreenshot_UXReview_ShapeThread_SingleBackButton() {
        let app = launchApp(with: [
            "-feature.audioEnabled", "NO",
            "-feature.hapticsEnabled", "NO",
            "-feature.testModeEnabled", "YES",
            "-feature.skipProfilePicker", "YES",
            "-uiTest.startRoute", "shapeGeometry"
        ])

        XCTAssertTrue(app.staticTexts["Shape Names"].waitForExistence(timeout: 10))
        snapshot(app, "UXReview-ShapeThread-FlashcardStage")

        let topBack = app.buttons["GameplayStageTopBackButton"]
        XCTAssertTrue(topBack.waitForExistence(timeout: 5), "Expected single Back button in topChrome")

        let bottomBack = app.buttons["GameplayStageBackButton"]
        XCTAssertFalse(bottomBack.exists, "Duplicate bottom Back button must not exist")

        snapshot(app, "UXReview-ShapeThread-NavChrome")
    }

    /// Phase 3/4: Lab Games tab renders GameActivityCard in grid layout.
    func testScreenshot_UXReview_LabGamesGrid() {
        let app = launchApp(with: [
            "-feature.audioEnabled", "NO",
            "-feature.hapticsEnabled", "NO",
            "-feature.testModeEnabled", "YES",
            "-feature.skipProfilePicker", "YES",
            "-uiTest.startRoute", "labGames"
        ])

        requireExists(app.staticTexts["Games"], timeout: 10)
        snapshot(app, "UXReview-LabGames-GridCards")
    }

    /// Phase 3: Geometry lane detail renders sparse icon-name game launchers.
    func testScreenshot_UXReview_GeometryLaneIconNameLaunchers() {
        let app = launchApp(with: [
            "-feature.audioEnabled", "NO",
            "-feature.hapticsEnabled", "NO",
            "-feature.testModeEnabled", "YES",
            "-feature.skipProfilePicker", "YES",
            "-uiTest.startRoute", "geometryLane"
        ])

        requireExists(app.staticTexts["Geometry Lab"], timeout: 10)
        snapshot(app, "UXReview-GeometryLane-IconNameLaunchers")
    }

    /// Phase 4: Shape Names thread navigates through flashcards → name match stages.
    func testScreenshot_UXReview_ShapeThread_Stages() {
        let app = launchApp(with: [
            "-feature.audioEnabled", "NO",
            "-feature.hapticsEnabled", "NO",
            "-feature.testModeEnabled", "YES",
            "-feature.skipProfilePicker", "YES",
            "-uiTest.startRoute", "shapeGeometry"
        ])

        XCTAssertTrue(app.staticTexts["Shape Names"].waitForExistence(timeout: 10))
        snapshot(app, "UXReview-ShapeThread-01-Flashcards")

        let nextBtn = app.buttons["GameplayStageNextButton"]
        if nextBtn.waitForExistence(timeout: 3) {
            nextBtn.tap()
            requireExists(app.staticTexts["Name Match"], timeout: 5)
            snapshot(app, "UXReview-ShapeThread-02-NameMatch")
        }
    }

    @discardableResult
    private func requireExists(
        _ element: XCUIElement,
        timeout: TimeInterval,
        _ message: String? = nil,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> XCUIElement {
        XCTAssertTrue(
            element.waitForExistence(timeout: timeout),
            message ?? "Expected \(element) to exist before continuing",
            file: file,
            line: line
        )
        return element
    }
}
