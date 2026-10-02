import Foundation
import Observation

enum AngleArcadePhase: String, Equatable {
    case worldSelection, aiming, flying, result, worldComplete
}

@MainActor
@Observable
final class AngleArcadeEngine {
    private(set) var angle: Double
    private(set) var power: Double
    private(set) var level = AngleArcadeCampaign.levels[0]
    private(set) var phase: AngleArcadePhase = .worldSelection
    private(set) var shot: AngleArcadeShot?
    private(set) var previousShot: AngleArcadeShot?
    private(set) var success = false
    private(set) var misses = 0
    private(set) var progress: AngleArcadeProgress
    private(set) var feedback = ""
    private(set) var attemptID = 0
    private(set) var sessionStartedAt = Date.now
    private(set) var sessionCompletionCount = 0
    private var helpRequested = false
    @ObservationIgnored private let store: AngleArcadeProgressStore

    init(store: AngleArcadeProgressStore = .init(scope: "tv")) {
        self.store = store
        progress = store.load()
        angle = AngleArcadeCampaign.levels[0].startingAngle
        power = AngleArcadeCampaign.levels[0].startingPower
    }

    var aim: AngleArcadeAim { .init(angle: angle, power: power) }
    var currentWorld: AngleArcadeWorld { level.world }
    var preview: AngleArcadeShot? { level.shot(angle: angle, power: power) }
    var showsFullPreview: Bool {
        level.guided || level.id == "garden-raised" || level.id == "moon-earth" || helpRequested
    }
    var prompt: String {
        switch phase {
        case .worldSelection: "Choose a world. Each world has three missions."
        case .aiming: level.prompt
        case .flying: "Watch your shot!"
        case .result: success ? feedback : "\(feedback) \(hint)"
        case .worldComplete: "You finished the \(level.world.title) world! Choose another world or play again."
        }
    }

    var hint: String {
        guard !success else { return level.successExplanation }
        guard let solution = nearestWinningAim() else { return "Try a different aim. You can keep trying." }
        if abs(solution.angle - angle) > 0.001, level.allowsAngle {
            let higher = solution.angle > angle
            if level.kind == .rotation {
                return higher ? "Make a bigger turn. Press right or plus to match the glowing corner." : "Make a smaller turn. Press left or minus to match the glowing corner."
            }
            return higher ? "Lift the angle. Press right or angle plus." : "Lower the angle. Press left or angle minus."
        }
        if abs(solution.power - power) > 0.001, level.allowsPower {
            return solution.power > power ? "Try more power. Press up or push plus." : "Try less power. Press down or push minus."
        }
        return level.kind == .rotation ? "The shape matches. Check it!" : "Your aim is ready. Fire!"
    }

    func beginSession() {
        sessionStartedAt = .now
        sessionCompletionCount = 0
        showWorlds()
    }

    func selectWorld(_ world: AngleArcadeWorld) {
        let levels = AngleArcadeCampaign.levels(in: world)
        guard let next = levels.first(where: { !progress.hasCompleted($0.id) }) ?? levels.first else { return }
        selectLevel(next.id)
    }

    func selectLevel(_ id: String) {
        guard let selected = AngleArcadeCampaign.level(id: id) else { return }
        attemptID &+= 1
        level = selected
        angle = selected.startingAngle
        power = selected.startingPower
        phase = .aiming
        shot = nil
        previousShot = selected.comparisonGravity.flatMap {
            selected.shot(angle: selected.startingAngle, power: selected.startingPower, gravity: $0)
        }
        success = false
        misses = 0
        feedback = ""
        helpRequested = false
        progress.lastLevelID = id
        store.save(progress)
    }

    func startSuggested() {
        if let last = progress.lastLevelID, !progress.hasCompleted(last) {
            selectLevel(last)
        } else {
            selectLevel(progress.nextSuggestedLevelID)
        }
    }

    func adjustAngle(_ direction: Int) {
        guard level.allowsAngle, prepareAdjustment() else { return }
        setAngle(angle + Double(direction) * level.angleStep)
    }

    /// Both buttons and tilt use this method, keeping orientation separate from
    /// the fixed 90-degree internal corner in builder missions.
    func setAngle(_ value: Double) {
        guard value.isFinite, level.allowsAngle, phase == .aiming else { return }
        let clamped = min(max(value, level.angleRange.lowerBound), level.angleRange.upperBound)
        let snapped = (clamped / level.angleStep).rounded() * level.angleStep
        angle = min(max(snapped, level.angleRange.lowerBound), level.angleRange.upperBound)
    }

    func adjustPower(_ direction: Int) {
        guard level.allowsPower, prepareAdjustment() else { return }
        power = AngleArcadeModel.adjustedPower(power, direction: direction)
    }

    @discardableResult
    func submit() -> Bool {
        guard phase == .aiming else { return false }
        attemptID &+= 1
        progress.attemptCounts[level.id, default: 0] += 1
        store.save(progress)
        if level.kind == .rotation {
            completeAttempt(success: level.succeeds(angle: angle, power: power))
        } else if let launch = preview {
            shot = launch
            phase = .flying
        } else {
            return false
        }
        return true
    }

    func finishFlight(expectedAttemptID: Int? = nil) {
        guard phase == .flying, expectedAttemptID == nil || expectedAttemptID == attemptID, let shot else { return }
        completeAttempt(success: shot.hit)
    }

    func cancelFlight() {
        guard phase == .flying else { return }
        attemptID &+= 1
        shot = nil
        phase = .aiming
        feedback = ""
        success = false
    }

    func retry() {
        guard phase == .result, !success else { return }
        if level.comparisonGravity == nil { previousShot = shot }
        shot = nil
        feedback = ""
        phase = .aiming
    }

    func nextMission() {
        guard phase == .result, success else { return }
        let levels = AngleArcadeCampaign.levels(in: level.world)
        guard let index = levels.firstIndex(where: { $0.id == level.id }) else { return }
        if index + 1 < levels.count {
            selectLevel(levels[index + 1].id)
        } else {
            attemptID &+= 1
            phase = .worldComplete
        }
    }

    func showWorlds() {
        attemptID &+= 1
        phase = .worldSelection
        shot = nil
        previousShot = nil
        feedback = ""
        success = false
    }

    func requestHelp() {
        guard phase == .aiming || phase == .result, !success else { return }
        if !helpRequested {
            progress.helpCounts[level.id, default: 0] += 1
            store.save(progress)
        }
        helpRequested = true
    }

    private func prepareAdjustment() -> Bool {
        if phase == .result && !success { retry() }
        return phase == .aiming
    }

    private func completeAttempt(success won: Bool) {
        success = won
        phase = .result
        if won {
            sessionCompletionCount += 1
            var completion = progress.completions[level.id] ?? AngleArcadeCompletion()
            if level.guided || helpRequested { completion.assisted = true }
            else { completion.independent = true }
            progress.completions[level.id] = completion
            feedback = "You did it! \(level.successExplanation)"
        } else {
            misses += 1
            if level.kind == .rotation {
                feedback = "The shape needs another turn."
            } else {
                switch shot?.outcome {
                case .short: feedback = "The shot landed too short."
                case .above: feedback = "The shot went too high."
                case .below: feedback = "The shot went too low."
                case .blocked:
                    let obstacle = level.obstacles.first { $0.id == shot?.obstacleID }?.title.lowercased() ?? "obstacle"
                    feedback = "The shot touched the \(obstacle)."
                case .hit, .none: feedback = "Try another aim."
                }
            }
            if misses >= 2 { requestHelp() }
        }
        store.save(progress)
    }

    private func nearestWinningAim() -> AngleArcadeAim? {
        if level.kind == .rotation {
            return level.rotationTarget.map { .init(angle: $0, power: power) }
        }
        let angles = level.allowsAngle ? stride(from: level.angleRange.lowerBound, through: level.angleRange.upperBound, by: level.angleStep).map { $0 } : [angle]
        let powers = level.allowsPower ? stride(from: AngleArcadeModel.powerRange.lowerBound, through: AngleArcadeModel.powerRange.upperBound, by: AngleArcadeModel.powerStep).map { $0 } : [power]
        var best: AngleArcadeAim?
        var bestDistance = Double.infinity
        for candidateAngle in angles {
            for candidatePower in powers where level.succeeds(angle: candidateAngle, power: candidatePower) {
                let distance = abs(candidateAngle - angle) / level.angleStep + abs(candidatePower - power) / AngleArcadeModel.powerStep
                if distance < bestDistance {
                    best = .init(angle: candidateAngle, power: candidatePower)
                    bestDistance = distance
                }
            }
        }
        return best
    }
}
