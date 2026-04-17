import Foundation

enum SliceStateMachine {
    /// Compute the next stage after `stage` succeeds.
    ///
    /// - Parameters:
    ///   - stage: The stage that just completed successfully.
    ///   - success: Must be `true`; failure returns `stage` unchanged.
    ///   - showTransfer: Whether the Transfer (Show it) stepper stage is enabled.
    ///   - showGravitySplit: Whether the Gravity Split balance stage replaces Transfer.
    ///     When `true`, Abstract advances to `.gravitySplit` instead of `.transfer`.
    ///     Mutually exclusive with `showTransfer` — Gravity Split takes priority.
    ///   - showBondMatch: Whether the Bond Blast finale should follow the last
    ///     transfer/gravity-split (or abstract when both are disabled). The engine
    ///     passes `true` only on the last problem when `featureFlags.vs1BondMatchEnabled` is set.
    static func nextStage(
        after stage: SliceStage,
        success: Bool,
        showTransfer: Bool,
        showGravitySplit: Bool = false,
        showBondMatch: Bool = false
    ) -> SliceStage {
        guard success else { return stage }

        switch stage {
        case .concrete:
            return .pictorial
        case .pictorial:
            return .abstract
        case .abstract:
            if showGravitySplit { return .gravitySplit }
            if showTransfer     { return .transfer }
            return showBondMatch ? .bondMatch : .done
        case .gravitySplit:
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
        showGravitySplit: Bool = false,
        showBondMatch: Bool = false
    ) -> Bool {
        nextStage(
            after: current,
            success: true,
            showTransfer: showTransfer,
            showGravitySplit: showGravitySplit,
            showBondMatch: showBondMatch
        ) == next
    }
}
