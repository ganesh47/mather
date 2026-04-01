import UIKit

@MainActor
final class HapticsService {
    private(set) var successFiredCount = 0
    private(set) var failureFiredCount = 0
    private(set) var stageSuccessFiredCount = 0

    /// Light haptic for completing an individual CPA stage (not a full problem).
    func stageSuccess(enabled: Bool) {
        guard enabled else { return }
        stageSuccessFiredCount += 1
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    /// Medium haptic for completing a full problem (all stages done).
    func success(enabled: Bool) {
        guard enabled else { return }
        successFiredCount += 1
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }

    func failure(enabled: Bool) {
        guard enabled else { return }
        failureFiredCount += 1
        UINotificationFeedbackGenerator().notificationOccurred(.warning)
    }

    func resetCounts() {
        successFiredCount = 0
        failureFiredCount = 0
        stageSuccessFiredCount = 0
    }
}
