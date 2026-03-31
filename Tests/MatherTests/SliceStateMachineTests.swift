import Testing
@testable import Mather

struct SliceStateMachineTests {
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
    }
}
