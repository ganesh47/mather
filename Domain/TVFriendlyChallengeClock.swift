import Foundation
import Observation

/// A transient, optional pace aid. Expiry never changes game state or learning evidence.
@MainActor @Observable
final class TVFriendlyChallengeClock {
    enum PauseReason: Hashable { case background, options, hint, feedback, expired }

    private(set) var remainingSeconds = 0
    private(set) var elapsedSeconds: TimeInterval = 0
    private(set) var isExpired = false
    private(set) var isRunning = false
    private(set) var pauseReasons: Set<PauseReason> = []
    private var duration: TimeInterval?
    private var anchor: TimeInterval?
    @ObservationIgnored private let now: () -> TimeInterval

    var isEnabled: Bool { duration != nil }
    var isPaused: Bool { isRunning && !pauseReasons.isEmpty }

    init(now: @escaping () -> TimeInterval = { ProcessInfo.processInfo.systemUptime }) {
        self.now = now
    }

    /// Configure before a new round. Preserve interruption reasons until the caller closes them.
    func configure(seconds: Int?) {
        duration = seconds.map { TimeInterval(min(86_400, max(1, $0))) }
        anchor = nil
        isRunning = false
        elapsedSeconds = 0
        isExpired = false
        pauseReasons.remove(.expired)
        updateRemaining()
    }

    func start() {
        elapsedSeconds = 0
        isExpired = false
        pauseReasons.remove(.expired)
        isRunning = isEnabled
        anchor = isRunning && pauseReasons.isEmpty ? now() : nil
        updateRemaining()
    }

    func refresh() {
        guard isRunning, !isExpired, pauseReasons.isEmpty, let anchor else { return }
        let current = now()
        guard current.isFinite, anchor.isFinite else { return }
        elapsedSeconds += max(0, current - anchor)
        self.anchor = current
        if let duration, elapsedSeconds >= duration {
            elapsedSeconds = duration
            isExpired = true
            pauseReasons.insert(.expired)
            self.anchor = nil
        }
        updateRemaining()
    }

    func pause(_ reason: PauseReason) {
        refresh()
        pauseReasons.insert(reason)
        anchor = nil
    }

    func resume(_ reason: PauseReason) {
        guard pauseReasons.remove(reason) != nil else { return }
        if isRunning && !isExpired && pauseReasons.isEmpty { anchor = now() }
    }

    func stop() {
        refresh()
        isRunning = false
        anchor = nil
        pauseReasons.removeAll()
    }

    /// Continue the current game item; callers must not deal or submit an answer here.
    func addMoreTime(seconds: Int = 60) {
        guard let duration else { return }
        refresh()
        self.duration = min(86_400, duration + TimeInterval(max(1, seconds)))
        isExpired = false
        pauseReasons.remove(.expired)
        isRunning = true
        anchor = pauseReasons.isEmpty ? now() : nil
        updateRemaining()
    }

    func chooseUntimed() {
        refresh()
        duration = nil
        anchor = nil
        isRunning = false
        isExpired = false
        pauseReasons.remove(.expired)
        remainingSeconds = 0
    }

    private func updateRemaining() {
        remainingSeconds = duration.map { Int(ceil(max(0, $0 - elapsedSeconds))) } ?? 0
    }
}
