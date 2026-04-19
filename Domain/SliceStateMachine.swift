import Foundation

enum SliceStateMachine {
    static func nextStage(
        after stage: SliceStage,
        success: Bool,
        routeMode: SliceRouteMode
    ) -> SliceStage {
        guard success else { return stage }

        switch routeMode {
        case .makeBreakLoopV2:
            switch stage {
            case .concrete: return .gravitySplit
            case .gravitySplit: return .sumSprint
            case .sumSprint: return .bondMatch
            case .bondMatch, .pictorial, .abstract, .transfer: return .done
            case .done: return .done
            }
        case let .legacy(showTransfer, showGravitySplit, showBondMatch):
            return nextStage(
                after: stage,
                success: success,
                showTransfer: showTransfer,
                showGravitySplit: showGravitySplit,
                showBondMatch: showBondMatch
            )
        }
    }

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
        showBondMatch: Bool = false,
        makeBreakLoopV2Enabled: Bool = false
    ) -> SliceStage {
        guard success else { return stage }

        switch stage {
        case .concrete:
            if makeBreakLoopV2Enabled { return .gravitySplit }
            return .pictorial
        case .pictorial:
            return .abstract
        case .abstract:
            if showGravitySplit { return .gravitySplit }
            if showTransfer     { return .transfer }
            return showBondMatch ? .bondMatch : .done
        case .gravitySplit:
            return makeBreakLoopV2Enabled ? .sumSprint : (showBondMatch ? .bondMatch : .done)
        case .sumSprint:
            return .bondMatch
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
        routeMode: SliceRouteMode
    ) -> Bool {
        nextStage(after: current, success: true, routeMode: routeMode) == next
    }

    static func canTransition(
        from current: SliceStage,
        to next: SliceStage,
        showTransfer: Bool,
        showGravitySplit: Bool = false,
        showBondMatch: Bool = false,
        makeBreakLoopV2Enabled: Bool = false
    ) -> Bool {
        nextStage(
            after: current,
            success: true,
            showTransfer: showTransfer,
            showGravitySplit: showGravitySplit,
            showBondMatch: showBondMatch,
            makeBreakLoopV2Enabled: makeBreakLoopV2Enabled
        ) == next
    }
}
