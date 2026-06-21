import CoreMotion
import Foundation
import Observation

typealias PedometerUpdateHandler = (CMPedometerData?, Error?) -> Void
typealias PedometerUpdatesStarter = (Date, @escaping PedometerUpdateHandler) -> Void

/// Pure, testable progress helper for small-step walking challenges.
struct StepWalkProgress: Equatable {
    let requiredSteps: Int
    private(set) var countedSteps: Int

    init(requiredSteps: Int, countedSteps: Int = 0) {
        self.requiredSteps = max(1, requiredSteps)
        self.countedSteps = max(0, countedSteps)
    }

    var remainingSteps: Int { max(0, requiredSteps - countedSteps) }
    var isComplete: Bool { countedSteps >= requiredSteps }
    var fractionComplete: Double { min(1, Double(countedSteps) / Double(requiredSteps)) }

    mutating func setCountedSteps(_ steps: Int) {
        countedSteps = max(0, steps)
    }

    mutating func addManualStep() {
        countedSteps += 1
    }
}

enum StepCountMode: Equatable {
    case idle
    case pedometer
    case manualFallback(reason: String)
}

/// Wraps CMPedometer behind a tiny observable surface with a simulator/manual fallback.
/// The game never requires hardware or Motion & Fitness permission to complete.
@MainActor
@Observable
final class StepCountService {
    nonisolated(unsafe) private let pedometer: CMPedometer
    private let stepCountingAvailable: () -> Bool
    private let startPedometerUpdates: PedometerUpdatesStarter
    private let noStepUpdateFallbackDelay: Duration
    private var noStepUpdateFallbackTask: Task<Void, Never>?
    private var startDate: Date?
    private var activeSessionID: UUID?

    private(set) var progress = StepWalkProgress(requiredSteps: 1)
    private(set) var mode: StepCountMode = .idle

    init(
        pedometer: CMPedometer = CMPedometer(),
        stepCountingAvailable: @escaping () -> Bool = { CMPedometer.isStepCountingAvailable() },
        startPedometerUpdates: PedometerUpdatesStarter? = nil,
        noStepUpdateFallbackDelay: Duration = .seconds(3)
    ) {
        self.pedometer = pedometer
        self.stepCountingAvailable = stepCountingAvailable
        self.startPedometerUpdates = startPedometerUpdates ?? { date, handler in
            pedometer.startUpdates(from: date, withHandler: handler)
        }
        self.noStepUpdateFallbackDelay = noStepUpdateFallbackDelay
    }

    var isStepCountingAvailable: Bool {
        stepCountingAvailable()
    }

    var isComplete: Bool { progress.isComplete }
    var countedSteps: Int { progress.countedSteps }
    var requiredSteps: Int { progress.requiredSteps }

    func start(requiredSteps: Int) {
        stop()
        progress = StepWalkProgress(requiredSteps: requiredSteps)
        startDate = Date()
        let sessionID = UUID()
        activeSessionID = sessionID

        guard isStepCountingAvailable else {
            mode = .manualFallback(reason: "Step sensing is not available here. Tap each small step instead.")
            return
        }

        mode = .pedometer
        scheduleNoStepUpdateFallback(for: sessionID)
        startPedometerUpdates(startDate ?? Date()) { [weak self] data, error in
            Task { @MainActor [weak self] in
                guard let self else { return }
                guard self.activeSessionID == sessionID else { return }
                if error != nil {
                    self.useManualFallback(reason: "Motion permission was not available. Tap each small step instead.")
                    return
                }
                guard let data else { return }
                self.progress.setCountedSteps(data.numberOfSteps.intValue)
                if self.progress.countedSteps > 0 {
                    self.noStepUpdateFallbackTask?.cancel()
                    self.noStepUpdateFallbackTask = nil
                }
            }
        }
    }

    func stop() {
        noStepUpdateFallbackTask?.cancel()
        noStepUpdateFallbackTask = nil
        pedometer.stopUpdates()
        startDate = nil
        activeSessionID = nil
        mode = .idle
    }

    func useManualFallback(reason: String = "Tap after each small careful step.") {
        noStepUpdateFallbackTask?.cancel()
        noStepUpdateFallbackTask = nil
        pedometer.stopUpdates()
        activeSessionID = nil
        mode = .manualFallback(reason: reason)
    }

    func addManualStep() {
        if case .manualFallback = mode {
            progress.addManualStep()
        } else if mode == .idle {
            mode = .manualFallback(reason: "Tap after each small careful step.")
            progress.addManualStep()
        }
    }

    // Exposed for tests and previews so no hardware/permission is required.
    func applyCountedSteps(_ steps: Int) {
        progress.setCountedSteps(steps)
    }

    private func scheduleNoStepUpdateFallback(for sessionID: UUID) {
        noStepUpdateFallbackTask?.cancel()
        let delay = noStepUpdateFallbackDelay
        noStepUpdateFallbackTask = Task { @MainActor [weak self] in
            try? await Task.sleep(for: delay)
            guard !Task.isCancelled, let self else { return }
            guard self.activeSessionID == sessionID else { return }
            guard case .pedometer = self.mode, self.progress.countedSteps == 0 else { return }
            self.useManualFallback(reason: "If step sensing does not start, tap after each small careful step.")
        }
    }
}
