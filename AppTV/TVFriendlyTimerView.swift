import SwiftUI

struct TVFriendlyTimerView: View {
    let clock: TVFriendlyChallengeClock

    var body: some View {
        Label(label, systemImage: clock.isEnabled ? "clock" : "leaf")
            .font(.system(size: 22, weight: .semibold, design: .rounded))
            .foregroundStyle(.white.opacity(0.86))
            .accessibilityLabel(label)
            .accessibilityIdentifier("tv-friendly-timer")
            .task(id: clock.isRunning) {
                while clock.isRunning && !Task.isCancelled {
                    clock.refresh()
                    do { try await Task.sleep(for: .milliseconds(250)) }
                    catch { return }
                }
            }
    }

    private var label: String {
        guard clock.isEnabled else { return "Untimed · Take your time" }
        if clock.isExpired { return "Take a breath · Keep playing" }
        let time = "\(clock.remainingSeconds / 60):\(String(format: "%02d", clock.remainingSeconds % 60))"
        return "Gentle timer \(time)" + (clock.isPaused ? " · Paused" : "")
    }
}
