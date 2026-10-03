import Foundation
import Testing
@testable import Mather

struct AngleArcadeCampaignTests {
    @Test func nineAuthoredMissionsCoverThreeOpenWorlds() {
        #expect(AngleArcadeCampaign.levels.count == 9)
        #expect(Set(AngleArcadeCampaign.levels.map(\.id)).count == 9)
        for world in AngleArcadeWorld.allCases {
            #expect(AngleArcadeCampaign.levels(in: world).count == 3)
        }
    }

    @Test func everyAuthoredSolutionSucceedsWithItsAllowedControls() {
        for level in AngleArcadeCampaign.levels {
            let solution = level.authoredSolution
            #expect(level.succeeds(angle: solution.angle, power: solution.power), "\(level.id) solution")
            #expect(level.angleRange.contains(solution.angle))
            if !level.allowsAngle { #expect(solution.angle == level.startingAngle) }
            if !level.allowsPower { #expect(solution.power == level.startingPower) }
            #expect(solution.angle.truncatingRemainder(dividingBy: level.angleStep) == 0)
            #expect(solution.power.truncatingRemainder(dividingBy: 5) == 0)
            #expect(level.succeeds(angle: level.startingAngle, power: level.startingPower) == level.guided)
        }
    }

    @Test func earlyChallengesNeedTwoAdjustmentsAndTransfersAtMostFour() {
        for id in ["garden-raised", "builder-corner", "moon-earth", "moon-compare"] {
            let level = AngleArcadeCampaign.level(id: id)!
            #expect(controlDistance(level.startingAngle, level.startingPower, level.authoredSolution, level: level) <= 2)
        }
        for id in ["garden-fence", "builder-transfer", "moon-transfer"] {
            let level = AngleArcadeCampaign.level(id: id)!
            #expect(controlDistance(level.startingAngle, level.startingPower, level.authoredSolution, level: level) <= 4)
        }
    }

    @Test func rotationKeepsSquareCornerSeparateFromOrientation() {
        let rotationLevels = AngleArcadeCampaign.levels.filter { $0.kind == .rotation }
        #expect(rotationLevels.count == 3)
        for level in rotationLevels {
            #expect(level.referenceAngle == 90)
            #expect(level.target == nil)
            #expect(!level.allowsPower)
            #expect(level.shot(angle: level.startingAngle, power: 75) == nil)
            #expect(level.angleRange == 0...120)
            #expect(level.angleStep == 15)
        }
        let quarterTurn = AngleArcadeCampaign.level(id: "builder-quarter-turn")!
        #expect(quarterTurn.rotationTarget! - quarterTurn.startingAngle == 90)
    }

    @Test func sameShotMakesMeaningfulEarthMoonComparison() {
        let moon = AngleArcadeCampaign.level(id: "moon-compare")!
        let earthShot = moon.shot(angle: moon.startingAngle, power: moon.startingPower, gravity: moon.comparisonGravity)!
        let moonShot = moon.shot(angle: moon.startingAngle, power: moon.startingPower)!
        #expect(earthShot.hit)
        #expect(moonShot.outcome == .above)
        #expect(moonShot.heightAtTarget - earthShot.heightAtTarget > 50)
        #expect(moonShot.landingX > earthShot.landingX)
        #expect(moon.succeeds(angle: moon.authoredSolution.angle, power: moon.authoredSolution.power))
    }

    @Test func fixedBoundsContainEveryPermittedLaunchAndTarget() {
        for level in AngleArcadeCampaign.levels where level.kind == .launch {
            let angles = level.allowsAngle ? stride(from: 20.0, through: 75.0, by: 5).map { $0 } : [level.startingAngle]
            let powers = level.allowsPower ? stride(from: 40.0, through: 100.0, by: 5).map { $0 } : [level.startingPower]
            for angle in angles {
                for power in powers {
                    let shot = level.shot(angle: angle, power: power)!
                    let radius = level.projectileRadius
                    #expect(shot.path.allSatisfy { $0.x - radius >= level.bounds.minX && $0.x + radius <= level.bounds.maxX && $0.y - radius >= level.bounds.minY && $0.y + radius <= level.bounds.maxY })
                }
            }
            let target = level.target!
            #expect(target.distance - target.radius >= level.bounds.minX)
            #expect(target.distance + target.radius <= level.bounds.maxX)
            #expect(target.height + target.radius <= level.bounds.maxY)
        }
    }

    private func controlDistance(_ angle: Double, _ power: Double, _ solution: AngleArcadeAim, level: AngleArcadeLevel) -> Double {
        abs(solution.angle - angle) / level.angleStep + abs(solution.power - power) / AngleArcadeModel.powerStep
    }
}

@MainActor
struct AngleArcadeEngineTests {
    private func engine() -> AngleArcadeEngine {
        AngleArcadeEngine(store: .init(defaults: UserDefaults(suiteName: "angle-engine-tests-\(UUID())")!, scope: "child"))
    }

    @Test func launchAcceptsOneCompletionAndRejectsStaleFlightCallbacks() {
        let engine = engine()
        engine.selectLevel("garden-guided")
        #expect(engine.submit())
        let cancelledAttempt = engine.attemptID
        #expect(engine.phase == .flying)
        #expect(!engine.submit())
        engine.adjustAngle(1)
        #expect(engine.angle == 35)
        engine.cancelFlight()
        #expect(engine.phase == .aiming)
        #expect(engine.submit())
        engine.finishFlight(expectedAttemptID: cancelledAttempt)
        #expect(engine.phase == .flying)
        #expect(engine.sessionCompletionCount == 0)
        engine.finishFlight(expectedAttemptID: engine.attemptID)
        #expect(engine.phase == .result)
        #expect(engine.success)
        engine.finishFlight()
        #expect(engine.sessionCompletionCount == 1)
        #expect(engine.progress.attemptCounts["garden-guided"] == 2)
        #expect(engine.progress.completion(for: "garden-guided")?.assisted == true)
    }

    @Test func rotationUsesSnappedControlsAndImmediateResultWithoutLaunch() {
        let engine = engine()
        engine.selectLevel("builder-corner")
        engine.adjustPower(1)
        #expect(engine.power == 75)
        engine.setAngle(44)
        #expect(engine.angle == 45)
        #expect(engine.submit())
        #expect(engine.phase == .result)
        #expect(engine.success)
        #expect(engine.shot == nil)
        engine.setAngle(90)
        #expect(engine.angle == 45)
        #expect(engine.level.referenceAngle == 90)
    }

    @Test func assistanceDoesNotEraseIndependentCompletionAndIsNotMastery() {
        let engine = engine()
        engine.selectLevel("builder-corner")
        engine.requestHelp()
        engine.requestHelp()
        #expect(engine.progress.helpCounts["builder-corner"] == 1)
        engine.setAngle(45)
        engine.submit()
        #expect(engine.progress.completion(for: "builder-corner")?.assisted == true)
        #expect(engine.progress.completion(for: "builder-corner")?.independent == false)
        engine.selectLevel("builder-corner")
        engine.setAngle(45)
        engine.submit()
        #expect(engine.progress.completion(for: "builder-corner")?.independent == true)
        #expect(engine.progress.completion(for: "builder-corner")?.assisted == true)
        #expect(engine.progress.completedCount(in: .builder) == 1)
    }

    @Test func twoMissesOfferHelpAndAdjustingAfterMissOpensAiming() {
        let engine = engine()
        engine.selectLevel("moon-compare")
        #expect(!engine.showsFullPreview)
        for _ in 0..<2 {
            engine.submit()
            engine.finishFlight()
            #expect(!engine.success)
            engine.retry()
        }
        #expect(engine.showsFullPreview)
        #expect(engine.misses == 2)
        #expect(engine.progress.helpCounts["moon-compare"] == 1)
        #expect(engine.previousShot?.gravity == 98)
        engine.submit()
        engine.finishFlight()
        engine.adjustPower(-1)
        #expect(engine.phase == .aiming)
        #expect(engine.power == 75)
        engine.adjustPower(-1)
        engine.submit()
        engine.finishFlight()
        #expect(engine.success)
        #expect(engine.progress.completion(for: "moon-compare")?.assisted == true)
    }

    @Test func oneMissThenSuccessIsAssistedBeforeAutomaticHelp() {
        let engine = engine()
        engine.selectLevel("builder-corner")
        engine.submit()
        #expect(engine.phase == .result)
        #expect(!engine.success)
        #expect(engine.misses == 1)
        #expect(engine.progress.helpCounts["builder-corner"] == nil)
        engine.retry()
        engine.setAngle(45)
        engine.submit()
        #expect(engine.success)
        #expect(engine.sessionCompletionCount == 1)
        #expect(engine.progress.completion(for: "builder-corner")?.assisted == true)
        #expect(engine.progress.completion(for: "builder-corner")?.independent == false)

        // A fresh later mission can still add independent evidence to the passport.
        engine.selectLevel("builder-corner")
        engine.setAngle(45)
        engine.submit()
        #expect(engine.progress.completion(for: "builder-corner")?.independent == true)
        #expect(engine.progress.completion(for: "builder-corner")?.assisted == true)
    }

    @Test func worldCompletionAndSessionRestartHaveExplicitBoundaries() {
        let engine = engine()
        engine.selectLevel("builder-transfer")
        engine.setAngle(30)
        engine.submit()
        engine.nextMission()
        #expect(engine.phase == .worldComplete)
        #expect(engine.sessionCompletionCount == 1)
        engine.beginSession()
        #expect(engine.phase == .worldSelection)
        #expect(engine.sessionCompletionCount == 0)
        #expect(engine.progress.hasCompleted("builder-transfer"))
        engine.selectWorld(.moon)
        #expect(engine.level.id == "moon-earth")
        engine.selectLevel("not-a-level")
        #expect(engine.level.id == "moon-earth")
    }
}

@MainActor
struct AngleArcadeProgressStoreTests {
    @Test func separateScopesPersistAndSanitizeUnknownIDs() throws {
        let defaults = UserDefaults(suiteName: "angle-progress-tests-\(UUID())")!
        let first = AngleArcadeProgressStore(defaults: defaults, scope: "first-child")
        let second = AngleArcadeProgressStore(defaults: defaults, scope: "second-child")
        var value = AngleArcadeProgress()
        value.completions["builder-corner"] = .init(assisted: false, independent: true)
        value.completions["obsolete-mission"] = .init(assisted: true, independent: false)
        value.attemptCounts = ["builder-corner": 3, "obsolete-mission": 9, "moon-earth": -4]
        value.lastLevelID = "obsolete-mission"
        first.save(value)
        let loaded = try #require(first.load())
        #expect(loaded.completions.count == 1)
        #expect(loaded.completion(for: "builder-corner")?.independent == true)
        #expect(loaded.attemptCounts == ["builder-corner": 3])
        #expect(loaded.lastLevelID == nil)
        #expect(second.load() == AngleArcadeProgress())
    }

    @Test(arguments: ["corrupt", "future-schema", "future-field", "future-completion-field", "invalid-counter", "wrong-type"])
    func unreadableProgressSurvivesSaveAndEnteringWorld(_ fixture: String) throws {
        let suite = "angle-progress-version-tests-\(UUID())"
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        let key = "mather.angle-arcade.progress.v1.test"
        let store = AngleArcadeProgressStore(defaults: defaults, scope: "test")
        var root = try #require(JSONSerialization.jsonObject(with: JSONEncoder().encode(AngleArcadeProgress())) as? [String: Any])
        switch fixture {
        case "future-schema": root["schemaVersion"] = 2
        case "future-field": root["futureCheckpoint"] = ["keep": "opaque"]
        case "future-completion-field": root["completions"] = ["builder-corner": ["assisted": true, "independent": false, "futureEvidence": "keep"]]
        case "invalid-counter": root["attemptCounts"] = ["builder-corner": -1]
        default: break
        }
        let raw: Data
        if fixture == "corrupt" { raw = Data("invalid json".utf8) }
        else { raw = try JSONSerialization.data(withJSONObject: root) }
        if fixture == "wrong-type" { defaults.set("retained non-Data payload", forKey: key) }
        else { defaults.set(raw, forKey: key) }
        #expect(store.load() == nil)
        #expect(store.storageState == .unsupported)
        #expect(!store.save(AngleArcadeProgress()))
        let engine = AngleArcadeEngine(store: store)
        #expect(engine.pauseMessage != nil)
        engine.beginSession()
        engine.selectWorld(.builder)
        engine.selectLevel("builder-corner")
        engine.startSuggested()
        engine.requestHelp()
        #expect(!engine.submit())
        #expect(engine.phase == .worldSelection)
        #expect(engine.attemptID == 0)
        #expect(engine.sessionCompletionCount == 0)
        if fixture == "wrong-type" { #expect(defaults.string(forKey: key) == "retained non-Data payload") }
        else { #expect(defaults.data(forKey: key) == raw) }
    }

    @Test func aFuturePayloadRestoredWhilePlayingBlocksSubmissionAndCompletion() throws {
        let suite = "angle-progress-inflight-tests-\(UUID())"
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        let key = "mather.angle-arcade.progress.v1.test"
        let store = AngleArcadeProgressStore(defaults: defaults, scope: "test")
        var future = AngleArcadeProgress()
        future.schemaVersion = 2
        let raw = try JSONEncoder().encode(future)
        let aiming = AngleArcadeEngine(store: store)
        aiming.selectWorld(.garden)
        defaults.set(raw, forKey: key)
        #expect(!aiming.submit())
        #expect(aiming.pauseMessage != nil)
        #expect(aiming.progress.attemptCounts.isEmpty)
        #expect(defaults.data(forKey: key) == raw)

        store.clear()
        let flying = AngleArcadeEngine(store: store)
        flying.selectWorld(.garden)
        #expect(flying.submit())
        #expect(flying.phase == .flying)
        let attempt = flying.attemptID
        defaults.set(raw, forKey: key)
        flying.finishFlight(expectedAttemptID: attempt)
        #expect(flying.pauseMessage != nil)
        #expect(!flying.success)
        #expect(flying.sessionCompletionCount == 0)
        #expect(flying.progress.completions.isEmpty)
        #expect(defaults.data(forKey: key) == raw)
    }

    @Test func explicitParentResetClearsOnlyTheChosenScopeAndAllowsPlay() throws {
        let suite = "angle-progress-reset-tests-\(UUID())"
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        let selected = AngleArcadeProgressStore(defaults: defaults, scope: "selected")
        let other = AngleArcadeProgressStore(defaults: defaults, scope: "other")
        var saved = AngleArcadeProgress()
        saved.completions["builder-corner"] = .init(assisted: true)
        #expect(other.save(saved))
        let otherKey = "mather.angle-arcade.progress.v1.other"
        let otherBytes = defaults.data(forKey: otherKey)
        let selectedKey = "mather.angle-arcade.progress.v1.selected"
        defaults.set(Data("retain until confirmation".utf8), forKey: selectedKey)
        let engine = AngleArcadeEngine(store: selected)
        #expect(engine.pauseMessage != nil)
        engine.clearProgressAfterParentConfirmation()
        #expect(defaults.object(forKey: selectedKey) == nil)
        #expect(selected.storageState == .missing)
        #expect(engine.pauseMessage == nil)
        #expect(engine.progress.completions.isEmpty)
        #expect(defaults.data(forKey: otherKey) == otherBytes)
        engine.selectWorld(.builder)
        #expect(engine.phase == .aiming)
        #expect(selected.load()?.lastLevelID == "builder-corner")
        #expect(other.load()?.hasCompleted("builder-corner") == true)
    }
}
