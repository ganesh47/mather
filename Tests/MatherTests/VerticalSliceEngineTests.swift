import Foundation
import Testing
@testable import Mather

@MainActor
struct VerticalSliceEngineTests {
    private func completePictorialBondBlast(_ engine: VerticalSliceEngine) {
        let pairIds = engine.bondMatchState?.pairs.map(\.id) ?? []
        #expect(!pairIds.isEmpty)
        for id in pairIds {
            engine.matchPair(id: id)
        }
    }

    @Test
    func sessionRoutesThroughBondBlastThenWriteItThenTransfer() async throws {
        let flags = FeatureFlagService(defaults: UserDefaults(suiteName: #function)!)
        flags.verticalSlice1Enabled = true
        flags.testModeEnabled = true
        flags.vs1BondMatchEnabled = true

        let engine = VerticalSliceEngine(
            featureFlags: flags,
            telemetryWriter: TelemetryWriter(),
            speechService: SpeechService(),
            celebrationDuration: 0,
            saveSummary: { _ in }
        )

        engine.startSession()
        #expect(engine.currentStage == .concrete)

        engine.adjustConcrete(by: engine.currentProblem?.target ?? 0)
        engine.submitCurrentStage()
        try await Task.sleep(for: .milliseconds(200))
        #expect(engine.currentStage == .pictorial)

        #expect(engine.bondMatchState != nil)
        completePictorialBondBlast(engine)
        try await Task.sleep(for: .milliseconds(200))
        #expect(engine.currentStage == .abstract)

        engine.equationLeftInput = String(engine.currentProblem?.decompositionA ?? 0)
        engine.equationRightInput = String(engine.currentProblem?.decompositionB ?? 0)
        engine.submitCurrentStage()
        try await Task.sleep(for: .milliseconds(200))
        #expect(engine.currentStage == .transfer)
    }

    @Test
    func roomQuestRouteDoesNotForceTransferStageInVs1Engine() {
        let flags = FeatureFlagService(defaults: UserDefaults(suiteName: #function)!)
        flags.verticalSlice1Enabled = true
        flags.testModeEnabled = true
        flags.roomQuestEnabled = true

        let engine = VerticalSliceEngine(
            featureFlags: flags,
            telemetryWriter: TelemetryWriter(),
            speechService: SpeechService(),
            celebrationDuration: 0,
            saveSummary: { _ in }
        )

        engine.showRoomQuest()
        #expect(engine.route == .roomQuest)
        #expect(engine.currentStage == .concrete)
    }

    @Test
    func bondBlastStartsWhenConcreteStageClears() async throws {
        let flags = FeatureFlagService(defaults: UserDefaults(suiteName: #function)!)
        flags.verticalSlice1Enabled = true
        flags.testModeEnabled = true

        let engine = VerticalSliceEngine(
            featureFlags: flags,
            telemetryWriter: TelemetryWriter(),
            speechService: SpeechService(),
            celebrationDuration: 0,
            saveSummary: { _ in }
        )

        engine.startSession()
        guard let problem = engine.currentProblem else {
            Issue.record("Expected deterministic problem")
            return
        }

        engine.adjustConcrete(by: problem.target)
        engine.submitCurrentStage()
        try await Task.sleep(for: .milliseconds(200))

        #expect(engine.currentStage == .pictorial)
        #expect(engine.bondMatchState != nil)
        #expect(problem.decompositionA > 0)
    }

    @Test
    func hapticsStageSuccessFiredOnConcreteStageClear() {
        let flags = FeatureFlagService(defaults: UserDefaults(suiteName: #function)!)
        flags.testModeEnabled = true
        flags.hapticsEnabled = true
        let haptics = HapticsService()

        let engine = VerticalSliceEngine(
            featureFlags: flags,
            telemetryWriter: TelemetryWriter(),
            speechService: SpeechService(),
            hapticsService: haptics,
            saveSummary: { _ in }
        )

        engine.startSession()
        engine.adjustConcrete(by: engine.currentProblem?.target ?? 0)
        engine.submitCurrentStage()

        // Completing an individual stage (not a full problem) fires stageSuccess, not success
        #expect(haptics.stageSuccessFiredCount == 1)
        #expect(haptics.successFiredCount == 0)
        #expect(haptics.failureFiredCount == 0)
    }

    @Test
    func hapticsSuccessFiredOnProblemComplete() async throws {
        let flags = FeatureFlagService(defaults: UserDefaults(suiteName: #function)!)
        flags.testModeEnabled = true
        flags.hapticsEnabled = true
        let haptics = HapticsService()

        let engine = VerticalSliceEngine(
            featureFlags: flags,
            telemetryWriter: TelemetryWriter(),
            speechService: SpeechService(),
            hapticsService: haptics,
            celebrationDuration: 0,
            saveSummary: { _ in }
        )

        engine.startSession()
        guard let problem = engine.currentProblem else { return }

        // Complete all four CPA stages for one problem — await after each so the
        // stage-advance Task (which runs after celebrationDuration: 0) can fire.
        engine.adjustConcrete(by: problem.target)
        engine.submitCurrentStage()    // concrete → pictorial (stageSuccess)
        try await Task.sleep(for: .milliseconds(200))
        completePictorialBondBlast(engine)
        try await Task.sleep(for: .milliseconds(200))
        engine.equationLeftInput = String(problem.decompositionA)
        engine.equationRightInput = String(problem.decompositionB)
        engine.submitCurrentStage()    // abstract → transfer (stageSuccess)
        try await Task.sleep(for: .milliseconds(200))
        engine.adjustTransfer(by: problem.decompositionA, side: .left)
        engine.adjustTransfer(by: problem.decompositionB, side: .right)
        engine.submitCurrentStage()    // transfer → done (success — problem complete)
        try await Task.sleep(for: .milliseconds(200))

        #expect(haptics.successFiredCount == 1)
        #expect(haptics.stageSuccessFiredCount == 3)
        #expect(haptics.failureFiredCount == 0)
    }

    @Test
    func hapticsStageSuccessNotFiredWhenDisabled() {
        let flags = FeatureFlagService(defaults: UserDefaults(suiteName: #function)!)
        flags.testModeEnabled = true
        flags.hapticsEnabled = false
        let haptics = HapticsService()

        let engine = VerticalSliceEngine(
            featureFlags: flags,
            telemetryWriter: TelemetryWriter(),
            speechService: SpeechService(),
            hapticsService: haptics,
            saveSummary: { _ in }
        )

        engine.startSession()
        engine.adjustConcrete(by: engine.currentProblem?.target ?? 0)
        engine.submitCurrentStage()

        #expect(haptics.stageSuccessFiredCount == 0)
        #expect(haptics.successFiredCount == 0)
    }

    @Test
    func hapticsFailureFiredOnWrongAnswer() {
        let flags = FeatureFlagService(defaults: UserDefaults(suiteName: #function)!)
        flags.testModeEnabled = true
        flags.hapticsEnabled = true
        let haptics = HapticsService()

        let engine = VerticalSliceEngine(
            featureFlags: flags,
            telemetryWriter: TelemetryWriter(),
            speechService: SpeechService(),
            hapticsService: haptics,
            saveSummary: { _ in }
        )

        engine.startSession()
        // Leave count at 0 — wrong answer for any target > 0
        engine.submitCurrentStage()

        #expect(haptics.failureFiredCount == 1)
        #expect(haptics.successFiredCount == 0)
    }

    @Test
    func equationAcceptsAlternativeCorrectDecomposition() async throws {
        let flags = FeatureFlagService(defaults: UserDefaults(suiteName: #function)!)
        flags.testModeEnabled = true
        flags.hapticsEnabled = false
        let haptics = HapticsService()

        let engine = VerticalSliceEngine(
            featureFlags: flags,
            telemetryWriter: TelemetryWriter(),
            speechService: SpeechService(),
            hapticsService: haptics,
            celebrationDuration: 0,
            saveSummary: { _ in }
        )

        engine.startSession()
        guard let problem = engine.currentProblem else { return }

        // Advance to abstract stage — await after each submit so the stage-advance Task fires.
        engine.adjustConcrete(by: problem.target)
        engine.submitCurrentStage() // → pictorial
        try await Task.sleep(for: .milliseconds(200))
        completePictorialBondBlast(engine)
        try await Task.sleep(for: .milliseconds(200))

        #expect(engine.currentStage == .abstract)

        // Enter a valid decomposition different from the stored split
        // e.g. if decompositionA=1, decompositionB=5 for target=6, try 3+3
        let altLeft = problem.target / 2
        let altRight = problem.target - altLeft
        engine.equationLeftInput = String(altLeft)
        engine.equationRightInput = String(altRight)
        engine.submitCurrentStage()
        try await Task.sleep(for: .milliseconds(200))

        // Should advance past abstract regardless of which valid decomposition was entered
        #expect(engine.currentStage != .abstract)
        #expect(haptics.failureFiredCount == 0)
    }

    @Test
    func hapticsFailureNotFiredWhenDisabled() {
        let flags = FeatureFlagService(defaults: UserDefaults(suiteName: #function)!)
        flags.testModeEnabled = true
        flags.hapticsEnabled = false
        let haptics = HapticsService()

        let engine = VerticalSliceEngine(
            featureFlags: flags,
            telemetryWriter: TelemetryWriter(),
            speechService: SpeechService(),
            hapticsService: haptics,
            saveSummary: { _ in }
        )

        engine.startSession()
        engine.submitCurrentStage()

        #expect(haptics.failureFiredCount == 0)
    }

    @Test
    func concreteGroupsTrackWarmAndAccentSeparately() {
        let flags = FeatureFlagService(defaults: UserDefaults(suiteName: #function)!)
        flags.testModeEnabled = true

        let engine = VerticalSliceEngine(
            featureFlags: flags,
            telemetryWriter: TelemetryWriter(),
            speechService: SpeechService(),
            saveSummary: { _ in }
        )

        engine.startSession()
        engine.adjustConcrete(by: 3, side: .accent)

        #expect(engine.concreteWarmCount == 0)
        #expect(engine.concreteAccentCount == 3)
        #expect(engine.concreteCount == 3)

        engine.adjustConcrete(by: 2, side: .warm)

        #expect(engine.concreteWarmCount == 2)
        #expect(engine.concreteAccentCount == 3)
        #expect(engine.concreteCount == 5)
    }

    // MARK: - Bond Blast engine tests

    @Test
    func bondMatchStateInitialisedWhenEnteringBondMatchStage() async throws {
        let flags = FeatureFlagService(defaults: UserDefaults(suiteName: #function)!)
        flags.testModeEnabled = true
        flags.vs1BondMatchEnabled = true

        // Use a 1-problem session so the first problem IS the last problem,
        // ensuring showBondMatch = true when transfer completes.
        let engine = VerticalSliceEngine(
            featureFlags: flags,
            telemetryWriter: TelemetryWriter(),
            speechService: SpeechService(),
            celebrationDuration: 0,
            saveSummary: { _ in }
        )
        engine.updateConfig(problemCount: 1)
        engine.startSession()
        guard let problem = engine.currentProblem else { return }

        // Advance through concrete → pictorial → abstract → transfer
        engine.adjustConcrete(by: problem.target)
        engine.submitCurrentStage()
        try await Task.sleep(for: .milliseconds(200))
        completePictorialBondBlast(engine)
        try await Task.sleep(for: .milliseconds(200))
        engine.equationLeftInput = String(problem.decompositionA)
        engine.equationRightInput = String(problem.decompositionB)
        engine.submitCurrentStage()
        try await Task.sleep(for: .milliseconds(200))
        engine.adjustTransfer(by: problem.decompositionA, side: .left)
        engine.adjustTransfer(by: problem.decompositionB, side: .right)
        engine.submitCurrentStage()  // transfer → bondMatch
        try await Task.sleep(for: .milliseconds(200))

        #expect(engine.currentStage == .bondMatch)
        #expect(engine.bondMatchState != nil)
        #expect(engine.bondMatchState?.target == problem.target)
        // For target 6: pairs are (1,5),(2,4),(3,3) = 3 pairs
        #expect((engine.bondMatchState?.pairs.count ?? 0) > 0)
    }

    @Test
    func bondMatchCompletesSessionWhenAllPairsMatched() async throws {
        let flags = FeatureFlagService(defaults: UserDefaults(suiteName: #function)!)
        flags.testModeEnabled = true
        flags.vs1BondMatchEnabled = true

        let engine = VerticalSliceEngine(
            featureFlags: flags,
            telemetryWriter: TelemetryWriter(),
            speechService: SpeechService(),
            celebrationDuration: 0,
            saveSummary: { _ in }
        )
        engine.updateConfig(problemCount: 1)
        engine.startSession()
        guard let problem = engine.currentProblem else { return }

        // Fast-path to bondMatch stage
        engine.adjustConcrete(by: problem.target)
        engine.submitCurrentStage()
        try await Task.sleep(for: .milliseconds(200))
        completePictorialBondBlast(engine)
        try await Task.sleep(for: .milliseconds(200))
        engine.equationLeftInput = String(problem.decompositionA)
        engine.equationRightInput = String(problem.decompositionB)
        engine.submitCurrentStage()
        try await Task.sleep(for: .milliseconds(200))
        engine.adjustTransfer(by: problem.decompositionA, side: .left)
        engine.adjustTransfer(by: problem.decompositionB, side: .right)
        engine.submitCurrentStage()
        try await Task.sleep(for: .milliseconds(200))
        #expect(engine.currentStage == .bondMatch)

        // Match all pairs
        guard let pairs = engine.bondMatchState?.pairs else { return }
        for pair in pairs {
            engine.matchPair(id: pair.id)
        }
        try await Task.sleep(for: .milliseconds(200))

        // All pairs matched → session ends → route should be .sessionSummary
        #expect(engine.route == .sessionSummary)
    }

    @Test
    func bondMatchPairGenerationIsCorrectForTarget6() {
        let pairs = BondMatchState.makePairs(for: 6)
        // Expected: (1,5), (2,4), (3,3)
        #expect(pairs.count == 3)
        #expect(pairs[0].left == 1 && pairs[0].right == 5)
        #expect(pairs[1].left == 2 && pairs[1].right == 4)
        #expect(pairs[2].left == 3 && pairs[2].right == 3)
        // All sum to target
        #expect(pairs.allSatisfy { $0.left + $0.right == 6 })
    }

    @Test
    func bondMatchPairGenerationIsCorrectForTarget10() {
        let pairs = BondMatchState.makePairs(for: 10)
        // Expected: (1,9),(2,8),(3,7),(4,6),(5,5) = 5 pairs
        #expect(pairs.count == 5)
        #expect(pairs.allSatisfy { $0.left + $0.right == 10 })
        #expect(pairs.allSatisfy { $0.left <= $0.right })
    }

    @Test
    func matchPairGracefullyIgnoresUnknownPairId() async throws {
        let flags = FeatureFlagService(defaults: UserDefaults(suiteName: #function)!)
        flags.testModeEnabled = true
        flags.vs1BondMatchEnabled = true

        let engine = VerticalSliceEngine(
            featureFlags: flags,
            telemetryWriter: TelemetryWriter(),
            speechService: SpeechService(),
            celebrationDuration: 0,
            saveSummary: { _ in }
        )
        engine.updateConfig(problemCount: 1)
        engine.startSession()
        guard let problem = engine.currentProblem else { return }

        engine.adjustConcrete(by: problem.target)
        engine.submitCurrentStage()
        try await Task.sleep(for: .milliseconds(200))
        engine.submitCurrentStage()
        try await Task.sleep(for: .milliseconds(200))
        engine.equationLeftInput = String(problem.decompositionA)
        engine.equationRightInput = String(problem.decompositionB)
        engine.submitCurrentStage()
        try await Task.sleep(for: .milliseconds(200))
        engine.adjustTransfer(by: problem.decompositionA, side: .left)
        engine.adjustTransfer(by: problem.decompositionB, side: .right)
        engine.submitCurrentStage()
        try await Task.sleep(for: .milliseconds(200))

        let before = engine.bondMatchState
        engine.matchPair(id: UUID())

        #expect(engine.currentStage == .bondMatch)
        #expect(engine.bondMatchState?.pairs.map(\.isMatched) == before?.pairs.map(\.isMatched))
    }

    @Test
    func bondMatchNotFiredOnIntermediateProblems() async throws {
        let flags = FeatureFlagService(defaults: UserDefaults(suiteName: #function)!)
        flags.testModeEnabled = true
        flags.vs1BondMatchEnabled = true

        let engine = VerticalSliceEngine(
            featureFlags: flags,
            telemetryWriter: TelemetryWriter(),
            speechService: SpeechService(),
            celebrationDuration: 0,
            saveSummary: { _ in }
        )
        engine.updateConfig(problemCount: 4)
        engine.startSession()
        guard let problem = engine.currentProblem else { return }

        // Complete first problem (not last — bondMatch should NOT fire)
        engine.adjustConcrete(by: problem.target)
        engine.submitCurrentStage()
        try await Task.sleep(for: .milliseconds(200))
        engine.submitCurrentStage()
        try await Task.sleep(for: .milliseconds(200))
        engine.equationLeftInput = String(problem.decompositionA)
        engine.equationRightInput = String(problem.decompositionB)
        engine.submitCurrentStage()
        try await Task.sleep(for: .milliseconds(200))
        engine.adjustTransfer(by: problem.decompositionA, side: .left)
        engine.adjustTransfer(by: problem.decompositionB, side: .right)
        engine.submitCurrentStage()
        try await Task.sleep(for: .milliseconds(200))

        // Should have advanced to problem 2 (concrete stage), not bondMatch
        #expect(engine.currentStage == .concrete)
        #expect(engine.currentProblemIndex == 1)
    }

    // MARK: - Gravity Split engine tests

    private func advanceToGravitySplit(_ engine: VerticalSliceEngine) async throws {
        guard let problem = engine.currentProblem else { return }
        engine.adjustConcrete(by: problem.target)
        engine.submitCurrentStage()
        try await Task.sleep(for: .milliseconds(200))
        let pairIds = engine.bondMatchState?.pairs.map(\.id) ?? []
        for id in pairIds { engine.matchPair(id: id) }
        try await Task.sleep(for: .milliseconds(200))
        engine.equationLeftInput = String(problem.decompositionA)
        engine.equationRightInput = String(problem.decompositionB)
        engine.submitCurrentStage()
        try await Task.sleep(for: .milliseconds(200))
        #expect(engine.currentStage == .gravitySplit)
    }

    @Test
    func gravitySplitStateInitialisedOnStageEntry() async throws {
        let flags = FeatureFlagService(defaults: UserDefaults(suiteName: #function)!)
        flags.testModeEnabled = true
        flags.vs1GravitySplitEnabled = true

        let engine = VerticalSliceEngine(
            featureFlags: flags,
            telemetryWriter: TelemetryWriter(),
            speechService: SpeechService(),
            celebrationDuration: 0,
            saveSummary: { _ in }
        )
        engine.startSession()
        try await advanceToGravitySplit(engine)

        guard let target = engine.currentProblem?.target else { return }
        #expect(engine.gravitySplitState != nil)
        // Starts far-left (target − 1) so the scale is visibly unbalanced on entry.
        #expect(engine.gravitySplitState?.leftCount == max(0, target - 1))
        #expect(engine.gravitySplitState?.rightCount == 1)
    }

    @Test
    func gravitySplitAdjustByTapChangesCount() async throws {
        let flags = FeatureFlagService(defaults: UserDefaults(suiteName: #function)!)
        flags.testModeEnabled = true
        flags.vs1GravitySplitEnabled = true

        let engine = VerticalSliceEngine(
            featureFlags: flags,
            telemetryWriter: TelemetryWriter(),
            speechService: SpeechService(),
            celebrationDuration: 0,
            saveSummary: { _ in }
        )
        engine.startSession()
        try await advanceToGravitySplit(engine)

        // Stage starts far-left (target − 1); decrement moves counters right.
        guard let target = engine.currentProblem?.target else { return }
        let startLeft = max(0, target - 1)
        #expect(engine.gravitySplitState?.leftCount == startLeft)

        engine.adjustGravitySplitByTap(delta: -1)
        #expect(engine.gravitySplitState?.leftCount == startLeft - 1)
        engine.adjustGravitySplitByTap(delta: -1)
        #expect(engine.gravitySplitState?.leftCount == startLeft - 2)
    }

    // Neutral-relative tilt: the first tilt sample records the hold position as
    // neutral (Δ=0). A second sample at the SAME value produces zero delta,
    // leaving leftCount unchanged regardless of the absolute device roll.
    // Note: for the symmetric 6=3+3 deterministic problem, the first tilt at Δ=0
    // maps to the midpoint (3) which equals decompositionA → the stage locks.
    // The second call then returns early via the isLocked guard, so count stays stable.
    @Test
    func gravitySplitTiltRecordsNeutralOnFirstSample() async throws {
        let flags = FeatureFlagService(defaults: UserDefaults(suiteName: #function)!)
        flags.testModeEnabled = true
        flags.vs1GravitySplitEnabled = true

        let engine = VerticalSliceEngine(
            featureFlags: flags,
            telemetryWriter: TelemetryWriter(),
            speechService: SpeechService(),
            celebrationDuration: 0,
            saveSummary: { _ in }
        )
        engine.startSession()
        try await advanceToGravitySplit(engine)

        // First call records neutral; Δ=0 maps to midpoint.
        engine.adjustGravitySplitByTilt(0.3)
        let countAfterFirst = engine.gravitySplitState?.leftCount

        // Second call at the SAME value → Δ=0 → count is unchanged.
        engine.adjustGravitySplitByTilt(0.3)
        #expect(engine.gravitySplitState?.leftCount == countAfterFirst)
    }

    // The scale starts at target−1 (far-left, visibly unbalanced) so the child
    // cannot accidentally win just by picking up the device without tapping GO first.
    @Test
    func gravitySplitSymmetricProblemCannotBeAccidentallySolvedBeforeFirstTilt() async throws {
        let flags = FeatureFlagService(defaults: UserDefaults(suiteName: #function)!)
        flags.testModeEnabled = true
        flags.vs1GravitySplitEnabled = true

        let engine = VerticalSliceEngine(
            featureFlags: flags,
            telemetryWriter: TelemetryWriter(),
            speechService: SpeechService(),
            celebrationDuration: 0,
            saveSummary: { _ in }
        )
        engine.startSession()
        try await advanceToGravitySplit(engine)

        guard let problem = engine.currentProblem else { return }

        // Stage starts far-left (target−1 / 1), not at the balanced midpoint.
        #expect(engine.gravitySplitState?.isLocked == false)
        #expect(engine.gravitySplitState?.leftCount == max(0, problem.target - 1))
    }

    // For a symmetric problem (6=3+3) the correct answer IS the midpoint.
    // After GO is tapped and the first tilt sample is observed (Δ=0 from neutral),
    // the scale snaps to the midpoint = the correct decomposition → locks.
    // This is DELIBERATE: the child held the device steady and tapped GO.
    @Test
    func gravitySplitSymmetricProblemLocksWhenHeldAtNeutral() async throws {
        let flags = FeatureFlagService(defaults: UserDefaults(suiteName: #function)!)
        flags.testModeEnabled = true
        flags.vs1GravitySplitEnabled = true

        let engine = VerticalSliceEngine(
            featureFlags: flags,
            telemetryWriter: TelemetryWriter(),
            speechService: SpeechService(),
            celebrationDuration: 0,
            saveSummary: { _ in }
        )
        engine.startSession()
        try await advanceToGravitySplit(engine)

        guard let problem = engine.currentProblem else { return }
        #expect(problem.decompositionA == problem.decompositionB,
                "Test requires a symmetric decomposition — first deterministic problem is 6=3+3")

        // Tilt at any value: first call records that value as neutral, Δ=0 → midpoint = decompositionA → locked.
        engine.adjustGravitySplitByTilt(0.3)
        #expect(engine.gravitySplitState?.isLocked == true)

        // Allow the stage-advance Task to run.
        for _ in 0..<100 {
            if engine.currentStage != .gravitySplit { break }
            await Task.yield()
        }
        #expect(engine.currentStage != .gravitySplit)
    }

    @Test
    func gravitySplitAutoAdvancesWhenLocked() async throws {
        let flags = FeatureFlagService(defaults: UserDefaults(suiteName: #function)!)
        flags.testModeEnabled = true
        flags.vs1GravitySplitEnabled = true

        let engine = VerticalSliceEngine(
            featureFlags: flags,
            telemetryWriter: TelemetryWriter(),
            speechService: SpeechService(),
            celebrationDuration: 0,
            saveSummary: { _ in }
        )
        engine.startSession()
        try await advanceToGravitySplit(engine)

        guard let problem = engine.currentProblem else { return }
        guard let startLeft = engine.gravitySplitState?.leftCount else { return }
        // Tap from the branch's far-left start state to the exact decomposition.
        engine.adjustGravitySplitByTap(delta: problem.decompositionA - startLeft)
        // Drain the MainActor queue so the completeStage Task fires
        for _ in 0..<100 {
            if engine.currentStage != .gravitySplit { break }
            await Task.yield()
        }
        #expect(engine.currentStage != .gravitySplit)
    }

    @Test
    func concreteStageAcceptsCombinedWarmAndAccentTotal() {
        let flags = FeatureFlagService(defaults: UserDefaults(suiteName: #function)!)
        flags.testModeEnabled = true

        let engine = VerticalSliceEngine(
            featureFlags: flags,
            telemetryWriter: TelemetryWriter(),
            speechService: SpeechService(),
            celebrationDuration: 0,
            saveSummary: { _ in }
        )

        engine.startSession()
        guard let problem = engine.currentProblem else { return }

        let warmTarget = min(problem.target, 2)
        let accentTarget = problem.target - warmTarget
        engine.adjustConcrete(by: warmTarget, side: .warm)
        engine.adjustConcrete(by: accentTarget, side: .accent)
        engine.submitCurrentStage()

        #expect(engine.currentProblemState.isCorrect)
    }
}
