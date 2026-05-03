import CoreMotion
import Foundation
import Observation

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
    private var startDate: Date?

    private(set) var progress = StepWalkProgress(requiredSteps: 1)
    private(set) var mode: StepCountMode = .idle

    init(pedometer: CMPedometer = CMPedometer()) {
        self.pedometer = pedometer
    }

    var isStepCountingAvailable: Bool {
        CMPedometer.isStepCountingAvailable()
    }

    var isComplete: Bool { progress.isComplete }
    var countedSteps: Int { progress.countedSteps }
    var requiredSteps: Int { progress.requiredSteps }

    func start(requiredSteps: Int) {
        stop()
        progress = StepWalkProgress(requiredSteps: requiredSteps)
        startDate = Date()

        guard isStepCountingAvailable else {
            mode = .manualFallback(reason: "Step sensing is not available here. Tap each small step instead.")
            return
        }

        mode = .pedometer
        pedometer.startUpdates(from: startDate ?? Date()) { [weak self] data, error in
            Task { @MainActor [weak self] in
                guard let self else { return }
                if error != nil {
                    self.pedometer.stopUpdates()
                    self.mode = .manualFallback(reason: "Motion permission was not available. Tap each small step instead.")
                    return
                }
                guard let data else { return }
                self.progress.setCountedSteps(data.numberOfSteps.intValue)
            }
        }
    }

    func stop() {
        pedometer.stopUpdates()
        startDate = nil
        mode = .idle
    }

    func useManualFallback(reason: String = "Tap after each small careful step.") {
        pedometer.stopUpdates()
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
}
