import Foundation
import Observation

@MainActor
@Observable
final class LearningQuestEngine {
    private(set) var checkpoint: LearningQuestCheckpoint
    private let store: QuestCheckpointStore
    private let profileID: () -> String
    private var sessionStarted = false
    private var sessionPaused = false
    private(set) var requestedQuestID: LearningQuestID?
    var pauseMessage: String? { store.storageIssue?.message ?? (sessionPaused ? QuestCheckpointStorageIssue.couldNotSave.message : nil) }
    var onSpeak: (String) -> Void = { _ in }
    var onAttempt: (ItemAttempt, String) -> Void = { _, _ in }
    var onStageCompleted: (LearningQuestCheckpoint, LearningQuestStep) -> Void = { _, _ in }
    var onCompleted: (LearningQuestCheckpoint, ActivityResult) -> Void = { _, _ in }

    init(store: QuestCheckpointStore, activeProfileID: @escaping () -> String) {
        self.store = store; profileID = activeProfileID
        checkpoint = LearningQuestCheckpoint(profileID: activeProfileID(), questID: .numbers)
    }
    func start(_ quest: LearningQuestID, guidedPlanID: String? = nil, returnLaneID: CapabilityLaneID? = nil, returnToGames: Bool = false, content: LearningQuestContentSnapshot = .bundled) {
        if let guidedPlanID, LearningQuestID.guided(guidedPlanID) != quest { return }
        requestedQuestID = quest; sessionStarted = false; sessionPaused = false
        guard store.refreshStorage() else { pause(); return }
        if let saved = store.checkpoint(for: quest) { checkpoint = saved }
        else {
            guard let ordinal = store.nextVariantOrdinal(for: quest) else { pause(); return }
            let variant = LearningNumbersVariant.at(ordinal: ordinal)
            let pilot = LearningPilotVariant.at(quest: quest, ordinal: ordinal)
            checkpoint = LearningQuestCheckpoint(profileID: profileID(), questID: quest, guidedPlanID: guidedPlanID,
                returnLaneID: returnLaneID, returnToGames: returnToGames, content: content,
                numbersVariant: quest == .numbers ? variant : nil, variantOrdinal: ordinal,
                numberProbeFreshness: quest == .numbers ? variant.probes.map { !store.hasSeenProbe($0.id) } : nil,
                pilotVariant: pilot, pilotProbeFresh: pilot.map { !store.hasSeenProbe($0.id) })
        }
        if let guidedPlanID { checkpoint.guidedPlanID = guidedPlanID }
        if let returnLaneID { checkpoint.returnLaneID = returnLaneID }
        checkpoint.returnToGames = returnToGames
        guard persist() else { return }
        sessionStarted = true
        // Frozen event UUIDs make replay idempotent in the integration ledger.
        for attempt in checkpoint.attempts { onAttempt(attempt, checkpoint.sessionID) }
        for step in checkpoint.completedSteps { onStageCompleted(checkpoint, step) }
        speakPrompt()
    }
    func speakPrompt() {
        guard activeChild else { if pauseMessage != nil { speakPause() }; return }
        onSpeak(checkpoint.feedback.isEmpty ? checkpoint.prompt : "\(checkpoint.feedback) \(checkpoint.prompt)")
    }
    func choose(_ choice: String) {
        guard activeChild, !checkpoint.accepted, checkpoint.choices.contains(where: { $0.id == choice }) else { return }
        checkpoint.selectedChoice = choice
        if let label = checkpoint.choices.first(where: { $0.id == choice })?.label { onSpeak(label) }
        persist()
    }
    func adjustCount(_ delta: Int) {
        guard activeChild, !checkpoint.accepted else { return }
        let total = checkpoint.numberWhole
        checkpoint.counterCount = min(total, max(0, checkpoint.counterCount + delta)); checkpoint.hasManipulated = true
        onSpeak("\(checkpoint.counterCount)"); persist()
    }
    func selectShape(_ shape: String) {
        guard activeChild, checkpoint.step == .learn, ["circle", "triangle", "square", "rectangle"].contains(shape) else { return }
        checkpoint.currentShape = shape
        if !checkpoint.exploredShapes.contains(shape) { checkpoint.exploredShapes.append(shape) }
        checkpoint.hasManipulated = checkpoint.exploredShapes.count == 4 && checkpoint.shapeTurnCount > 0
        onSpeak("\(checkpoint.content.shapeName(shape)). \(checkpoint.content.shapeFact(shape))")
        persist()
    }
    func turnShape() { guard activeChild else { return }; checkpoint.angleDegrees = (checkpoint.angleDegrees + 45) % 360; checkpoint.shapeTurnCount += 1; checkpoint.hasManipulated = checkpoint.exploredShapes.count == 4 && checkpoint.shapeTurnCount > 0; onSpeak("Still a \(checkpoint.content.shapeName(checkpoint.currentShape)). \(checkpoint.content.shapeFact(checkpoint.currentShape))"); persist() }
    func togglePoint(_ index: Int) {
        guard activeChild, (0..<5).contains(index), !checkpoint.accepted else { return }
        if checkpoint.selectedPoints.contains(index) { checkpoint.selectedPoints.removeAll { $0 == index } } else { checkpoint.selectedPoints.append(index) }
        checkpoint.hasManipulated = true; onSpeak("\(checkpoint.selectedPoints.count) corners chosen"); persist()
    }
    func changeAngle(_ delta: Int) { guard activeChild, !checkpoint.accepted else { return }; checkpoint.angleDegrees = min(180, max(0, checkpoint.angleDegrees + delta)); checkpoint.hasManipulated = true; onSpeak(checkpoint.angleDegrees == 90 ? "Square-corner turn" : checkpoint.angleDegrees < 90 ? "Smaller turn" : "Wider turn"); persist() }
    func warmWater() {
        guard activeChild else { return }; checkpoint.waterState = 1
        checkpoint.feedback = (checkpoint.content.facts["water-cycle-evaporation"] ?? "Warmth helped liquid water become invisible gas.") + " Now cool the air."
        onSpeak(checkpoint.feedback); persist()
    }
    func coolWater() {
        guard activeChild, checkpoint.waterState == 1 else { return }; checkpoint.waterState = 2; checkpoint.hasManipulated = true
        checkpoint.feedback = checkpoint.content.facts["water-cycle-condensation"] ?? "Cooling changed water vapor into tiny liquid drops. These drops can make a cloud."
        onSpeak(checkpoint.feedback); persist()
    }
    func repairWire() { guard activeChild, !checkpoint.accepted else { return }; checkpoint.wireConnected.toggle(); checkpoint.hasManipulated = true; onSpeak(checkpoint.wireConnected ? "The wire joins the loop." : "The loop has a gap."); persist() }
    func toggleSwitch(second: Bool = false) {
        guard activeChild, !checkpoint.accepted else { return }
        if second { checkpoint.secondSwitchClosed.toggle() } else { checkpoint.switchClosed.toggle() }
        checkpoint.hasManipulated = true
        let lit = checkpoint.wireConnected && checkpoint.switchClosed && (checkpoint.step != .challenge || checkpoint.secondSwitchClosed)
        onSpeak(lit ? "Complete loop. The pretend bulb lights up." : "An open path keeps the pretend bulb off."); persist()
    }
    func toggleMirrorCell(_ index: Int) { guard activeChild, (0..<3).contains(index), !checkpoint.accepted else { return }; checkpoint.mirrorCells[index].toggle(); checkpoint.hasManipulated = true; onSpeak("Patch changed. Compare it with the other wing."); persist() }
    func fold() { guard activeChild else { return }; checkpoint.folded.toggle(); checkpoint.hasManipulated = true; onSpeak(checkpoint.folded ? "Fold and compare the halves." : "The halves are open again."); persist() }
    func help() {
        guard activeChild, checkpoint.step != .celebrate, !checkpoint.accepted else { return }
        checkpoint.supportVisible = true; checkpoint.feedback = checkpoint.support
        guard record(.help, response: "visual-and-spoken-scaffold") else { return }; onSpeak(checkpoint.support)
    }
    func submit() {
        guard activeChild, checkpoint.canSubmit else { return }
        if checkpoint.step == .celebrate { finish(); return }
        if checkpoint.accepted { advance(); return }
        if checkpoint.step == .learn {
            let previous = checkpoint
            if checkpoint.questID == .numbers { checkpoint.learnedLeftPart = checkpoint.counterCount }
            guard record(.exposure, response: manipulationResponse) else { checkpoint = previous; return }
            guard completeStep() else { return }; advance(); return
        }
        if checkpoint.questID == .circuitSpark && checkpoint.step == .challenge && !checkpoint.predictionMade {
            let correct = checkpoint.selectedChoice == "off"
            let supported = checkpoint.attempts.contains { $0.entityID == checkpoint.targetID + ".prediction" && ($0.outcome == .help || $0.outcome == .incorrect) }
            guard record(correct ? (supported ? .supportedCorrect : .independentCorrect) : .incorrect, response: checkpoint.selectedChoice ?? "none", targetSuffix: "prediction") else { return }
            checkpoint.predictionMade = true; checkpoint.supportVisible = !correct
            checkpoint.feedback = correct ? "Good prediction. Now close both switches and watch the new circuit." : "One open switch breaks the loop. The light stays off. Now close both switches and watch what changes."
            onSpeak(checkpoint.feedback); persist(); return
        }
        let correct = isCorrect
        let currentTarget = checkpoint.targetID + (checkpoint.questID == .circuitSpark && checkpoint.step == .challenge ? ".repair" : "")
        let hadSupport = checkpoint.attempts.contains { $0.entityID == currentTarget && ($0.outcome == .help || $0.outcome == .incorrect || $0.outcome == .supportedCorrect) }
            || (checkpoint.questID == .numbers && checkpoint.step == .play && checkpoint.attempts.contains {
                $0.stageID == "remember" && ($0.outcome == .independentCorrect || $0.outcome == .supportedCorrect)
            }) // This is rehearsal after the same answer was explained.
            || (checkpoint.questID == .circuitSpark && checkpoint.step == .challenge) // Repair follows observed feedback; only the prediction is a probe.
        guard record(correct ? (hadSupport ? .supportedCorrect : .independentCorrect) : .incorrect, response: manipulationResponse, targetSuffix: checkpoint.questID == .circuitSpark && checkpoint.step == .challenge ? "repair" : nil) else { return }
        if checkpoint.questID == .waterCycle && checkpoint.step == .play { checkpoint.waterState = 2 }
        checkpoint.accepted = correct
        checkpoint.feedback = correct ? successExplanation : "\(retryExplanation) You can change your idea and try again."
        if correct && !(checkpoint.questID == .numbers && checkpoint.step == .challenge
            && (checkpoint.numberProbeIndex ?? 0) + 1 < checkpoint.numberProbeCount) { guard completeStep() else { return } }
        onSpeak(checkpoint.feedback); persist()
    }
    private var activeChild: Bool {
        guard sessionStarted, !sessionPaused, checkpoint.profileID == profileID() else { return false }
        guard store.refreshStorage() else { pause(); return false }
        return true
    }
    private var isCorrect: Bool {
        switch (checkpoint.questID, checkpoint.step) {
        case (.numbers, .remember): checkpoint.selectedChoice == String(checkpoint.numberAnswer)
        case (.numbers, .play): checkpoint.counterCount == checkpoint.numberAnswer
        case (.numbers, .challenge): checkpoint.counterCount == checkpoint.numberAnswer
        case (.shapes, .remember): checkpoint.selectedChoice == "triangle"
        case (.shapes, .play): validTriangle
        case (.shapes, .challenge): checkpoint.selectedChoice == checkpoint.shapeTransferKind
        case (.waterCycle, .remember): checkpoint.selectedChoice == "vapor"
        case (.waterCycle, .play): checkpoint.selectedChoice == "drops"
        case (.waterCycle, .challenge): checkpoint.selectedChoice == "outside"
        case (.circuitSpark, .remember): checkpoint.selectedChoice == "closed"
        case (.circuitSpark, .play): checkpoint.wireConnected && checkpoint.switchClosed && checkpoint.hasManipulated
        case (.circuitSpark, .challenge): checkpoint.predictionMade && checkpoint.hasManipulated && checkpoint.switchClosed && checkpoint.secondSwitchClosed && checkpoint.wireConnected
        case (.angles, .remember): checkpoint.selectedChoice == "90"
        case (.angles, .play): checkpoint.angleDegrees == 90
        case (.angles, .challenge): checkpoint.angleDegrees == 120
        case (.symmetry, .remember): checkpoint.selectedChoice == "match"
        case (.symmetry, .play): checkpoint.mirrorCells == [true, false, true]
        case (.symmetry, .challenge): checkpoint.mirrorCells == [false, true, false] && checkpoint.folded
        default: false
        }
    }
    private var validTriangle: Bool {
        guard checkpoint.selectedPoints.count == 3, checkpoint.selectedPoints.allSatisfy({ (0..<5).contains($0) }) else { return false }
        let positions = [(0,0),(2,0),(1,1),(0,2),(2,2)]
        let values = checkpoint.selectedPoints.map { positions[$0] }
        return (values[1].0-values[0].0)*(values[2].1-values[0].1) != (values[2].0-values[0].0)*(values[1].1-values[0].1)
    }
    private var manipulationResponse: String {
        if checkpoint.usesChoices && !(checkpoint.questID == .circuitSpark && checkpoint.step == .challenge && checkpoint.predictionMade) { return checkpoint.selectedChoice ?? "none" }
        switch checkpoint.questID {
        case .numbers: return "placed=\(checkpoint.counterCount)"
        case .shapes: return "shape=\(checkpoint.currentShape);explored=\(checkpoint.exploredShapes);corners=\(checkpoint.selectedPoints.map(String.init).joined(separator: ","))"
        case .waterCycle: return "water-state=\(checkpoint.waterState)"
        case .circuitSpark: return "wire=\(checkpoint.wireConnected);switch=\(checkpoint.switchClosed);second=\(checkpoint.secondSwitchClosed)"
        case .angles: return "turn=\(checkpoint.angleDegrees)"
        case .symmetry: return "patches=\(checkpoint.mirrorCells);folded=\(checkpoint.folded)"
        }
    }
    private var successExplanation: String {
        switch checkpoint.questID {
        case .numbers: return "\(checkpoint.numberKnownPart) and \(checkpoint.numberAnswer) make \(checkpoint.numberWhole). You found the missing part!"
        case .shapes: return checkpoint.step == .play ? "Three corners joined by three straight sides make a triangle." : "You found it. Turning changes direction, not the shape's name."
        case .waterCycle: return "You used the water-changing idea. Warmth helps make invisible gas; cooling helps make liquid drops."
        case .circuitSpark: return "You predicted and repaired the path. A full loop lets the pretend battery light the bulb."
        case .angles: return "You matched the turn. A square corner is ninety degrees; a wider turn opens farther."
        case .symmetry: return "The halves cover each other. Your patches mirror across the fold!"
        }
    }
    private var retryExplanation: String {
        switch checkpoint.questID {
        case .numbers: return checkpoint.counterCount < checkpoint.numberAnswer ? "There is still space in the whole. Count the missing spaces." : "Check the whole: use the picture to find the missing part."
        case .shapes: return "Count corners and straight sides. A triangle has exactly three, joined into a closed shape."
        case .waterCycle: return checkpoint.step == .play ? "Look at what happened: cooling made tiny drops in the cloud." : "Think about warm water becoming gas, and cool gas becoming drops."
        case .circuitSpark: return "Trace the path. A gap or open switch keeps the light off."
        case .angles: return checkpoint.angleDegrees < (checkpoint.step == .challenge ? 120 : 90) ? "Open the gate a little more." : "Close the gate a little to match the guide."
        case .symmetry: return "One patch does not cover its partner. Compare each pair across the fold."
        }
    }
    private func record(_ outcome: ItemAttemptOutcome, response: String, targetSuffix: String? = nil) -> Bool {
        guard activeChild else { return false }
        let suffix = targetSuffix ?? (checkpoint.questID == .circuitSpark && checkpoint.step == .challenge ? (checkpoint.predictionMade ? "repair" : "prediction") : nil)
        let target = checkpoint.targetID + (suffix.map { ".\($0)" } ?? "")
        let attempt = ItemAttempt(activityID: checkpoint.activityID, conceptID: checkpoint.questID.conceptID, entityID: target, propertyID: checkpoint.isTransfer ? "transfer" : "practice", stageID: checkpoint.step.rawValue, outcome: outcome, response: response, profileID: checkpoint.profileID, sessionID: checkpoint.sessionID, contentVersion: checkpoint.contentVersion,
            itemVariantID: checkpoint.questID == .numbers ? (checkpoint.step == .challenge ? checkpoint.numberProbe.id : checkpoint.numbersVariant?.id) : checkpoint.pilotVariant?.id,
            appHintUsed: outcome == .help || outcome == .supportedCorrect || checkpoint.attempts.contains { $0.entityID == target && ($0.outcome == .help || $0.outcome == .incorrect || $0.outcome == .supportedCorrect) },
            isFreshProbe: checkpoint.questID == .numbers ? (checkpoint.step == .challenge ? checkpoint.isFreshNumberProbe : false)
                : checkpoint.pilotVariant != nil ? (checkpoint.step == .challenge && suffix != "repair" ? checkpoint.pilotProbeFresh : false) : nil,
            adultHelp: .unknown)
        let previous = checkpoint
        checkpoint.attempts.append(attempt)
        guard persist() else { checkpoint = previous; return false }
        onAttempt(attempt, checkpoint.sessionID); return true
    }
    private func completeStep() -> Bool {
        guard activeChild else { return false }
        guard !checkpoint.completedSteps.contains(checkpoint.step) else { return true }
        checkpoint.completedSteps.append(checkpoint.step)
        guard persist() else { return false }
        onStageCompleted(checkpoint, checkpoint.step); return true
    }
    private func advance() {
        guard activeChild else { return }
        guard let index = LearningQuestStep.allCases.firstIndex(of: checkpoint.step), index + 1 < LearningQuestStep.allCases.count else { return }
        let anotherNumberProbe = checkpoint.questID == .numbers && checkpoint.step == .challenge
            && (checkpoint.numberProbeIndex ?? 0) + 1 < checkpoint.numberProbeCount
        if anotherNumberProbe { checkpoint.numberProbeIndex = (checkpoint.numberProbeIndex ?? 0) + 1 }
        else { checkpoint.step = LearningQuestStep.allCases[index+1] }
        if checkpoint.step == .challenge {
            if checkpoint.questID == .numbers, !store.markProbeSeen(checkpoint.numberProbe.id) { pause(); return }
            if let pilot = checkpoint.pilotVariant, !store.markProbeSeen(pilot.id) { pause(); return }
        }
        checkpoint.selectedChoice = nil; checkpoint.accepted = false; checkpoint.hasManipulated = false; checkpoint.supportVisible = false; checkpoint.feedback = ""
        checkpoint.counterCount = 0; checkpoint.selectedPoints = []; checkpoint.angleDegrees = 30; checkpoint.waterState = checkpoint.questID == .waterCycle && checkpoint.step == .play ? 1 : 0; checkpoint.predictionMade = false
        checkpoint.wireConnected = checkpoint.step != .play; checkpoint.switchClosed = checkpoint.step != .learn; checkpoint.secondSwitchClosed = false
        if checkpoint.questID == .circuitSpark && checkpoint.step == .challenge, let openSwitch = checkpoint.pilotVariant?.openSwitch {
            checkpoint.switchClosed = openSwitch != 1; checkpoint.secondSwitchClosed = openSwitch != 2
        }
        checkpoint.mirrorCells = checkpoint.step == .challenge ? [true, true, true] : [false, false, true]; checkpoint.folded = false
        guard persist() else { return }; speakPrompt()
    }
    private func finish() {
        guard completeStep() else { return }
        let result = ActivityResult(id: checkpoint.sessionID, activityID: checkpoint.activityID, title: checkpoint.questID.title, startedAt: checkpoint.startedAt, attempts: checkpoint.attempts, completedStageIDs: checkpoint.completedSteps.map(\.rawValue), profileID: checkpoint.profileID, contentVersion: checkpoint.contentVersion)
        let completed = checkpoint
        guard store.remove(checkpoint.questID) else { pause(); return }
        sessionStarted = false; onCompleted(completed, result)
    }
    @discardableResult
    private func persist() -> Bool {
        checkpoint.updatedAt = Date()
        guard store.save(checkpoint) else { pause(); return false }
        return true
    }
    private func pause() { sessionPaused = true; speakPause() }
    private func speakPause() { onSpeak("This quest is paused. Your saved tasks have been kept. Ask a parent to check Settings.") }
}
