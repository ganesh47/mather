import UIKit

@MainActor
final class HapticsService {
    private(set) var successFiredCount = 0
    private(set) var failureFiredCount = 0

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
    }
}
