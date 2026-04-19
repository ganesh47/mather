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

    private func lockGravitySplit(_ engine: VerticalSliceEngine, problem: SliceProblem) {
        let currentLeft = engine.gravitySplitState?.leftCount ?? 0
        let leftDelta = problem.decompositionA - currentLeft
        if leftDelta > 0 {
            for _ in 0..<leftDelta { engine.adjustGravitySplitByTap(delta: 1, side: .left) }
        } else if leftDelta < 0 {
            for _ in 0..<(-leftDelta) { engine.adjustGravitySplitByTap(delta: -1, side: .left) }
        }

        let currentRight = engine.gravitySplitState?.rightCount ?? 0
        let rightDelta = problem.decompositionB - currentRight
        if rightDelta > 0 {
            for _ in 0..<rightDelta { engine.adjustGravitySplitByTap(delta: 1, side: .right) }
        } else if rightDelta < 0 {
            for _ in 0..<(-rightDelta) { engine.adjustGravitySplitByTap(delta: -1, side: .right) }
        }
    }

    private func completeSumSprintBurst(_ engine: VerticalSliceEngine) {
        while let card = engine.sumSprintBurstState?.currentCard {
            for digit in String(card.answer) {
                engine.appendSumSprintDigit(Int(String(digit))!)
            }
            engine.submitSumSprintCard()
        }
    }

    private func waitFor(_ description: String, timeoutNanoseconds: UInt64 = 2_000_000_000, condition: @escaping @MainActor () -> Bool) async {
        let deadline = DispatchTime.now().uptimeNanoseconds + timeoutNanoseconds
        while DispatchTime.now().uptimeNanoseconds < deadline {
            if await MainActor.run(body: condition) { return }
            await Task.yield()
            try? await Task.sleep(nanoseconds: 20_000_000)
        }
        Issue.record("Timed out waiting for \(description)")
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
        await waitFor("pictorial stage after concrete") { engine.currentStage == .pictorial }
        #expect(engine.currentStage == .pictorial)

        await waitFor("bond match state in pictorial") { engine.bondMatchState != nil }
        #expect(engine.bondMatchState != nil)
        completePictorialBondBlast(engine)
        await waitFor("abstract stage after Bond Blast") { engine.currentStage == .abstract }
        #expect(engine.currentStage == .abstract)

        engine.equationLeftInput = String(engine.currentProblem?.decompositionA ?? 0)
        engine.equationRightInput = String(engine.currentProblem?.decompositionB ?? 0)
        engine.submitCurrentStage()
        await waitFor("transfer stage after abstract") { engine.currentStage == .transfer }
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
        await waitFor("pictorial stage after concrete") { engine.currentStage == .pictorial }
        await waitFor("bond match state in pictorial") { engine.bondMatchState != nil }

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
        await waitFor("pictorial stage after concrete") { engine.currentStage == .pictorial }
        await waitFor("bond match state in pictorial") { engine.bondMatchState != nil }
        completePictorialBondBlast(engine)
        await waitFor("abstract stage after Bond Blast") { engine.currentStage == .abstract }
        engine.equationLeftInput = String(problem.decompositionA)
        engine.equationRightInput = String(problem.decompositionB)
        engine.submitCurrentStage()    // abstract → transfer (stageSuccess)
        await waitFor("transfer stage after abstract") { engine.currentStage == .transfer }
        engine.adjustTransfer(by: problem.decompositionA, side: .left)
        engine.adjustTransfer(by: problem.decompositionB, side: .right)
        engine.submitCurrentStage()    // transfer → done (success — problem complete)
        await waitFor("next problem or summary after transfer") { engine.currentStage != .transfer }

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
        await waitFor("pictorial stage after concrete") { engine.currentStage == .pictorial }
        await waitFor("bond match state in pictorial") { engine.bondMatchState != nil }
        completePictorialBondBlast(engine)
        await waitFor("abstract stage after Bond Blast") { engine.currentStage == .abstract }

        #expect(engine.currentStage == .abstract)

        // Enter a valid decomposition different from the stored split
        // e.g. if decompositionA=1, decompositionB=5 for target=6, try 3+3
        let altLeft = problem.target / 2
        let altRight = problem.target - altLeft
        engine.equationLeftInput = String(altLeft)
        engine.equationRightInput = String(altRight)
        engine.submitCurrentStage()
        await waitFor("advance past abstract after valid equation") { engine.currentStage != .abstract }

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
        await waitFor("pictorial stage after concrete") { engine.currentStage == .pictorial }
        await waitFor("bond match state in pictorial") { engine.bondMatchState != nil }
        completePictorialBondBlast(engine)
        await waitFor("abstract stage after Bond Blast") { engine.currentStage == .abstract }
        engine.equationLeftInput = String(problem.decompositionA)
        engine.equationRightInput = String(problem.decompositionB)
        engine.submitCurrentStage()
        await waitFor("transfer stage after abstract") { engine.currentStage == .transfer }
        engine.adjustTransfer(by: problem.decompositionA, side: .left)
        engine.adjustTransfer(by: problem.decompositionB, side: .right)
        engine.submitCurrentStage()  // transfer → bondMatch
        await waitFor("bond match stage after transfer") { engine.currentStage == .bondMatch }

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
        await waitFor("pictorial stage after concrete") { engine.currentStage == .pictorial }
        await waitFor("bond match state in pictorial") { engine.bondMatchState != nil }
        completePictorialBondBlast(engine)
        await waitFor("abstract stage after Bond Blast") { engine.currentStage == .abstract }
        engine.equationLeftInput = String(problem.decompositionA)
        engine.equationRightInput = String(problem.decompositionB)
        engine.submitCurrentStage()
        await waitFor("transfer stage after abstract") { engine.currentStage == .transfer }
        engine.adjustTransfer(by: problem.decompositionA, side: .left)
        engine.adjustTransfer(by: problem.decompositionB, side: .right)
        engine.submitCurrentStage()
        await waitFor("bond match stage after transfer") { engine.currentStage == .bondMatch }
        #expect(engine.currentStage == .bondMatch)

        // Match all pairs
        guard let pairs = engine.bondMatchState?.pairs else { return }
        for pair in pairs {
            engine.matchPair(id: pair.id)
        }
        await waitFor("session summary after completing bond match") { engine.route == .sessionSummary }

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
        await waitFor("pictorial stage after concrete") { engine.currentStage == .pictorial }
        await waitFor("bond match state in pictorial") { engine.bondMatchState != nil }
        engine.submitCurrentStage()
        await waitFor("abstract stage after pictorial submit") { engine.currentStage == .abstract }
        engine.equationLeftInput = String(problem.decompositionA)
        engine.equationRightInput = String(problem.decompositionB)
        engine.submitCurrentStage()
        await waitFor("transfer stage after abstract") { engine.currentStage == .transfer }
        engine.adjustTransfer(by: problem.decompositionA, side: .left)
        engine.adjustTransfer(by: problem.decompositionB, side: .right)
        engine.submitCurrentStage()
        await waitFor("bond match stage after transfer") { engine.currentStage == .bondMatch }

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
        await waitFor("pictorial stage after concrete") { engine.currentStage == .pictorial }
        await waitFor("bond match state in pictorial") { engine.bondMatchState != nil }
        completePictorialBondBlast(engine)
        await waitFor("abstract stage after Bond Blast") { engine.currentStage == .abstract }
        engine.equationLeftInput = String(problem.decompositionA)
        engine.equationRightInput = String(problem.decompositionB)
        engine.submitCurrentStage()
        await waitFor("transfer stage after abstract") { engine.currentStage == .transfer }
        engine.adjustTransfer(by: problem.decompositionA, side: .left)
        engine.adjustTransfer(by: problem.decompositionB, side: .right)
        engine.submitCurrentStage()
        await waitFor("next concrete stage after non-final transfer") { engine.currentStage == .concrete && engine.currentProblemIndex == 1 }

        // Should have advanced to problem 2 (concrete stage), not bondMatch
        #expect(engine.currentStage == .concrete)
        #expect(engine.currentProblemIndex == 1)
    }

    // MARK: - Gravity Split engine tests

    private func advanceToGravitySplit(_ engine: VerticalSliceEngine) async throws {
        guard let problem = engine.currentProblem else { return }
        engine.adjustConcrete(by: problem.target)
        engine.submitCurrentStage()
        await waitFor("pictorial stage after concrete") { engine.currentStage == .pictorial }
        await waitFor("bond match state in pictorial") { engine.bondMatchState != nil }
        let pairIds = engine.bondMatchState?.pairs.map(\.id) ?? []
        for id in pairIds { engine.matchPair(id: id) }
        await waitFor("abstract stage after Bond Blast") { engine.currentStage == .abstract }
        engine.equationLeftInput = String(problem.decompositionA)
        engine.equationRightInput = String(problem.decompositionB)
        engine.submitCurrentStage()
        await waitFor("gravity split stage after abstract") { engine.currentStage == .gravitySplit }
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
        #expect(engine.gravitySplitState?.leftCount == 0)
        #expect(engine.gravitySplitState?.rightCount == 0)
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

        #expect(engine.gravitySplitState?.leftCount == 0)

        engine.adjustGravitySplitByTap(delta: 1, side: .left)
        #expect(engine.gravitySplitState?.leftCount == 1)
        engine.adjustGravitySplitByTap(delta: 1, side: .left)
        #expect(engine.gravitySplitState?.leftCount == 2)
    }

    @Test
    func gravitySplitTiltDoesNotAutoSolveStage() async throws {
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

        engine.adjustGravitySplitByTilt(0.3)
        let countAfterFirst = engine.gravitySplitState?.leftCount
        let rightAfterFirst = engine.gravitySplitState?.rightCount

        engine.adjustGravitySplitByTilt(0.3)
        #expect(engine.gravitySplitState?.leftCount == countAfterFirst)
        #expect(engine.gravitySplitState?.rightCount == rightAfterFirst)
        #expect(engine.gravitySplitState?.isLocked == false)
    }

    @Test
    func gravitySplitStartsFromZeroAndUnsolved() async throws {
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

        #expect(engine.gravitySplitState?.isLocked == false)
        #expect(engine.gravitySplitState?.leftCount == 0)
        #expect(engine.gravitySplitState?.rightCount == 0)
    }

    @Test
    func gravitySplitRequiresTapAdjustmentToLock() async throws {
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
        engine.adjustGravitySplitByTilt(0.3)
        #expect(engine.gravitySplitState?.isLocked == false)

        for _ in 0..<problem.decompositionA { engine.adjustGravitySplitByTap(delta: 1, side: .left) }
        for _ in 0..<problem.decompositionB { engine.adjustGravitySplitByTap(delta: 1, side: .right) }
        await waitFor("gravity split auto-advance after tap lock") {
            engine.currentStage != .gravitySplit
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
        for _ in 0..<problem.decompositionA { engine.adjustGravitySplitByTap(delta: 1, side: .left) }
        for _ in 0..<problem.decompositionB { engine.adjustGravitySplitByTap(delta: 1, side: .right) }
        await waitFor("gravity split auto-advance after tap lock") {
            engine.currentStage != .gravitySplit
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


    @Test
    func makeBreakLoopV2RoutesConcreteToGravitySplitToSumSprintToBondBlast() async throws {
        let flags = FeatureFlagService(defaults: UserDefaults(suiteName: #function)!)
        flags.verticalSlice1Enabled = true
        flags.testModeEnabled = true
        flags.makeBreakLoopV2Enabled = true

        let engine = VerticalSliceEngine(
            featureFlags: flags,
            telemetryWriter: TelemetryWriter(),
            speechService: SpeechService(),
            celebrationDuration: 0,
            saveSummary: { _ in }
        )

        engine.startSession()
        guard let problem = engine.currentProblem else { return }

        engine.adjustConcrete(by: problem.target)
        engine.submitCurrentStage()
        await waitFor("gravity split after concrete") { engine.currentStage == .gravitySplit }
        #expect(engine.currentStage == .gravitySplit)

        lockGravitySplit(engine, problem: problem)
        await waitFor("gravity split lock") { engine.gravitySplitState?.isLocked == true }
        await waitFor("sum sprint after gravity split") { engine.currentStage == .sumSprint }
        #expect(engine.currentStage == .sumSprint)

        completeSumSprintBurst(engine)
        await waitFor("bond blast after sum sprint") { engine.currentStage == .bondMatch }
        #expect(engine.currentStage == .bondMatch)
    }



    @Test
    func makeBreakLoopV2CreatesMicroSumSprintBurstPerTarget() async throws {
        let flags = FeatureFlagService(defaults: UserDefaults(suiteName: #function)!)
        flags.verticalSlice1Enabled = true
        flags.testModeEnabled = true
        flags.makeBreakLoopV2Enabled = true

        let engine = VerticalSliceEngine(
            featureFlags: flags,
            telemetryWriter: TelemetryWriter(),
            speechService: SpeechService(),
            celebrationDuration: 0,
            saveSummary: { _ in }
        )

        engine.startSession()
        guard let problem = engine.currentProblem else { return }
        engine.adjustConcrete(by: problem.target)
        engine.submitCurrentStage()
        await waitFor("gravity split after concrete") { engine.currentStage == .gravitySplit }
        lockGravitySplit(engine, problem: problem)
        await waitFor("sum sprint after gravity split") { engine.currentStage == .sumSprint }
        #expect((engine.sumSprintBurstState?.cards.count ?? 0) >= 1)
        #expect((engine.sumSprintBurstState?.cards.count ?? 0) <= 3)
    }

    @Test
    func makeBreakLoopV2AdvancesToBondBlastAfterBurstCards() async throws {
        let flags = FeatureFlagService(defaults: UserDefaults(suiteName: #function)!)
        flags.verticalSlice1Enabled = true
        flags.testModeEnabled = true
        flags.makeBreakLoopV2Enabled = true

        let engine = VerticalSliceEngine(
            featureFlags: flags,
            telemetryWriter: TelemetryWriter(),
            speechService: SpeechService(),
            celebrationDuration: 0,
            saveSummary: { _ in }
        )

        engine.startSession()
        guard let problem = engine.currentProblem else { return }
        engine.adjustConcrete(by: problem.target)
        engine.submitCurrentStage()
        await waitFor("gravity split after concrete") { engine.currentStage == .gravitySplit }
        lockGravitySplit(engine, problem: problem)
        await waitFor("sum sprint after gravity split") { engine.currentStage == .sumSprint }

        completeSumSprintBurst(engine)

        await waitFor("bond blast after sum sprint burst") { engine.currentStage == .bondMatch }
        #expect(engine.currentStage == .bondMatch)
    }

}
