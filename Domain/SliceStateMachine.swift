import Foundation

enum SliceStateMachine {
    static func nextStage(after stage: SliceStage, success: Bool, showTransfer: Bool) -> SliceStage {
        guard success else { return stage }

        switch stage {
        case .concrete:
            return .pictorial
        case .pictorial:
            return .abstract
        case .abstract:
            return showTransfer ? .transfer : .done
        case .transfer:
            return .done
        case .done:
            return .done
        }
    }

    static func canTransition(from current: SliceStage, to next: SliceStage, showTransfer: Bool) -> Bool {
        nextStage(after: current, success: true, showTransfer: showTransfer) == next
    }
}
