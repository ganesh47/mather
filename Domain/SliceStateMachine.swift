import Foundation

enum SliceStateMachine {
    /// Compute the next stage after `stage` succeeds.
    ///
    /// - Parameters:
    ///   - stage: The stage that just completed successfully.
    ///   - success: Must be `true`; failure returns `stage` unchanged.
    ///   - showTransfer: Whether the Transfer stage is enabled for this session.
    ///   - showBondMatch: Whether the Bond Blast finale should follow the last
    ///     transfer (or abstract, when transfer is disabled). The engine passes
    ///     `true` only on the last problem of the session when
    ///     `featureFlags.vs1BondMatchEnabled` is set.
    static func nextStage(
        after stage: SliceStage,
        success: Bool,
        showTransfer: Bool,
        showBondMatch: Bool = false
    ) -> SliceStage {
        guard success else { return stage }

        switch stage {
        case .concrete:
            return .pictorial
        case .pictorial:
            return .abstract
        case .abstract:
            if showTransfer { return .transfer }
            return showBondMatch ? .bondMatch : .done
        case .transfer:
            return showBondMatch ? .bondMatch : .done
        case .bondMatch:
            return .done
        case .done:
            return .done
        }
    }

    static func canTransition(
        from current: SliceStage,
        to next: SliceStage,
        showTransfer: Bool,
        showBondMatch: Bool = false
    ) -> Bool {
        nextStage(after: current, success: true, showTransfer: showTransfer, showBondMatch: showBondMatch) == next
    }
}
