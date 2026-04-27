import Testing
@testable import Mather

struct SliceStateMachineTests {
    @Test
    func loopV2TransitionsAdvanceInRecoveryOrder() {
        #expect(SliceStateMachine.nextStage(after: .storyAnchor, success: true, routeMode: .makeBreakLoopV2) == .concrete)
        #expect(SliceStateMachine.nextStage(after: .concrete, success: true, routeMode: .makeBreakLoopV2) == .gravitySplit)
        #expect(SliceStateMachine.nextStage(after: .gravitySplit, success: true, routeMode: .makeBreakLoopV2) == .sumSprint)
        #expect(SliceStateMachine.nextStage(after: .sumSprint, success: true, routeMode: .makeBreakLoopV2) == .bondMatch)
        #expect(SliceStateMachine.nextStage(after: .bondMatch, success: true, routeMode: .makeBreakLoopV2) == .done)
    }

    @Test
    func validTransitionsAdvanceInOrder() {
        #expect(SliceStateMachine.nextStage(after: .concrete, success: true, showTransfer: true) == .pictorial)
        #expect(SliceStateMachine.nextStage(after: .pictorial, success: true, showTransfer: true) == .abstract)
        #expect(SliceStateMachine.nextStage(after: .abstract, success: true, showTransfer: true) == .transfer)
        #expect(SliceStateMachine.nextStage(after: .transfer, success: true, showTransfer: true) == .done)
    }

    @Test
    func invalidTransitionsAreRejected() {
        #expect(SliceStateMachine.canTransition(from: .concrete, to: .abstract, showTransfer: true) == false)
        #expect(SliceStateMachine.canTransition(from: .abstract, to: .done, showTransfer: true) == false)
        #expect(SliceStateMachine.canTransition(from: .abstract, to: .done, showTransfer: false))
        #expect(SliceStateMachine.canTransition(from: .storyAnchor, to: .concrete, routeMode: .makeBreakLoopV2))
        #expect(SliceStateMachine.canTransition(from: .concrete, to: .abstract, routeMode: .makeBreakLoopV2) == false)
        #expect(SliceStateMachine.canTransition(from: .gravitySplit, to: .bondMatch, routeMode: .makeBreakLoopV2) == false)
    }

    // MARK: - Bond Blast transitions

    @Test
    func bondMatchInsertedAfterTransferOnLastProblem() {
        // With showBondMatch: transfer → bondMatch → done
        #expect(SliceStateMachine.nextStage(after: .transfer, success: true, showTransfer: true, showBondMatch: true) == .bondMatch)
        #expect(SliceStateMachine.nextStage(after: .bondMatch, success: true, showTransfer: true, showBondMatch: true) == .done)
    }

    @Test
    func bondMatchInsertedAfterAbstractWhenNoTransfer() {
        // No transfer + showBondMatch: abstract → bondMatch → done
        #expect(SliceStateMachine.nextStage(after: .abstract, success: true, showTransfer: false, showBondMatch: true) == .bondMatch)
        #expect(SliceStateMachine.nextStage(after: .bondMatch, success: true, showTransfer: false, showBondMatch: false) == .done)
    }

    @Test
    func bondMatchNotInsertedWhenFlagOff() {
        // showBondMatch: false — existing behaviour unchanged
        #expect(SliceStateMachine.nextStage(after: .transfer, success: true, showTransfer: true, showBondMatch: false) == .done)
        #expect(SliceStateMachine.nextStage(after: .abstract, success: true, showTransfer: false, showBondMatch: false) == .done)
    }

    @Test
    func bondMatchCanTransitionValidation() {
        #expect(SliceStateMachine.canTransition(from: .transfer, to: .bondMatch, showTransfer: true, showBondMatch: true))
        #expect(SliceStateMachine.canTransition(from: .bondMatch, to: .done, showTransfer: true, showBondMatch: true))
        // Without showBondMatch, transfer → bondMatch is invalid
        #expect(SliceStateMachine.canTransition(from: .transfer, to: .bondMatch, showTransfer: true, showBondMatch: false) == false)
    }

    // MARK: - Gravity Split transitions

    @Test
    func gravitySplitInsertedAfterAbstractWhenFlagOn() {
        // Gravity Split takes priority over Transfer when showGravitySplit is true
        #expect(SliceStateMachine.nextStage(after: .abstract, success: true, showTransfer: true, showGravitySplit: true) == .gravitySplit)
    }

    @Test
    func gravitySplitLeadsToBondMatchOnLastProblem() {
        #expect(SliceStateMachine.nextStage(after: .gravitySplit, success: true, showTransfer: true, showGravitySplit: true, showBondMatch: true) == .bondMatch)
    }

    @Test
    func gravitySplitLeadsToDoneWhenBondMatchOff() {
        #expect(SliceStateMachine.nextStage(after: .gravitySplit, success: true, showTransfer: true, showGravitySplit: true, showBondMatch: false) == .done)
    }

    @Test
    func gravitySplitSkippedWhenFlagOff() {
        // Default: showGravitySplit omitted → falls back to Transfer
        #expect(SliceStateMachine.nextStage(after: .abstract, success: true, showTransfer: true) == .transfer)
    }


    @Test
    func makeBreakLoopV2UsesFourStagePerTargetRoute() {
        #expect(SliceStateMachine.nextStage(after: .storyAnchor, success: true, showTransfer: true, makeBreakLoopV2Enabled: true) == .concrete)
        #expect(SliceStateMachine.nextStage(after: .concrete, success: true, showTransfer: true, makeBreakLoopV2Enabled: true) == .gravitySplit)
        #expect(SliceStateMachine.nextStage(after: .gravitySplit, success: true, showTransfer: true, showBondMatch: true, makeBreakLoopV2Enabled: true) == .sumSprint)
        #expect(SliceStateMachine.nextStage(after: .sumSprint, success: true, showTransfer: true, showBondMatch: true, makeBreakLoopV2Enabled: true) == .bondMatch)
        #expect(SliceStateMachine.nextStage(after: .bondMatch, success: true, showTransfer: true, showBondMatch: true, makeBreakLoopV2Enabled: true) == .done)
    }

}
