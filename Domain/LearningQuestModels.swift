import Foundation

/// Content is frozen at launch. Downloaded facts and names can change; the app's
/// manipulation rules and answer keys remain typed and validated in code.
struct LearningQuestContentSnapshot: Codable, Equatable {
    let version: Int
    let names: [String: String]
    let facts: [String: String]
    static var bundled: Self { Self(catalog: .bundled) }
    init(catalog: IOSLearningCatalog) {
        version = catalog.contentVersion
        let entities = [GameplayThreadID.shapes, .waterCycle, .electronics].flatMap { catalog.thread(for: $0).entities }
        names = Dictionary(entities.map { ($0.id, $0.name) }, uniquingKeysWith: { first, _ in first })
        facts = Dictionary(entities.map { entity in
            let description = entity.properties.first { $0.typeID == "simpleExplanation" }?.value ?? entity.summary
            return (entity.id, description)
        }, uniquingKeysWith: { first, _ in first })
    }
    func shapeName(_ shape: String) -> String { names["shape-\(shape)"] ?? shape.capitalized }
    func shapeFact(_ shape: String) -> String {
        facts["shape-\(shape)"] ?? "Turn the shape and compare its sides and corners."
    }
}

enum LearningQuestID: String, CaseIterable, Codable, Hashable, Identifiable {
    case numbers, shapes, waterCycle, circuitSpark, angles, symmetry
    var id: String { rawValue }
    static let pilots: [Self] = [.numbers, .shapes, .waterCycle, .circuitSpark]
    var title: String {
        switch self {
        case .numbers: "Ten Together"
        case .shapes: "Shape Builders"
        case .waterCycle: "A Drop's Journey"
        case .circuitSpark: "Light Repair"
        case .angles: "Open the Gate"
        case .symmetry: "Mirror Garden"
        }
    }
    var emoji: String {
        switch self { case .numbers: "🌱"; case .shapes: "🔺"; case .waterCycle: "💧"; case .circuitSpark: "💡"; case .angles: "🚪"; case .symmetry: "🦋" }
    }
    var laneID: CapabilityLaneID {
        switch self { case .numbers: .numbers; case .shapes, .angles, .symmetry: .geometry; case .waterCycle: .physics; case .circuitSpark: .electronics }
    }
    var conceptID: String {
        switch self { case .numbers: "number-bond"; case .shapes: "shape"; case .waterCycle: "water-cycle"; case .circuitSpark: "closed-circuit"; case .angles: "angle"; case .symmetry: "symmetry" }
    }
    var activityID: String { "quest-\(rawValue)" }
    static func matching(conceptID: String?) -> Self? {
        guard let conceptID else { return nil }
        if conceptID == "number-bond" || conceptID == "number-bonds" { return .numbers }
        return allCases.first { $0.conceptID == conceptID }
    }
    static func guided(_ planID: String) -> Self? {
        switch planID {
        case "numbers-number-bonds-to-10": .numbers
        case "geometry-shape-names": .shapes
        case "geometry-angles-basic": .angles
        case "geometry-symmetry-folds": .symmetry
        default: nil
        }
    }
}

enum LearningQuestStep: String, CaseIterable, Codable, Hashable {
    case learn, remember, play, challenge, celebrate
    var title: String { rawValue.capitalized }
    var guidedStage: GuidedLabStage {
        switch self { case .learn: .learn; case .remember: .remember; case .play: .play; case .challenge: .blast; case .celebrate: .score }
    }
}

/// Reviewed answer keys remain bundled; the full selected variant is frozen in the checkpoint.
struct LearningNumberProbe: Codable, Equatable {
    let id: String
    let total: Int
    let knownPart: Int
    let objects: String
    let symbol: String
    let scene: String
    var answer: Int { total - knownPart }
    var prompt: String { "\(scene) has \(total) \(objects). \(knownPart) are packed. Pack the missing \(objects)." }
}

struct LearningNumbersVariant: Codable, Equatable {
    let id: String
    let initialPart: Int
    let probes: [LearningNumberProbe]
    static let reviewed: [Self] = [
        .init(id: "numbers-v1-picnic", initialPart: 6, probes: [
            .init(id: "picnic-8-3", total: 8, knownPart: 3, objects: "apples", symbol: "🍎", scene: "A picnic"),
            .init(id: "coat-7-1", total: 7, knownPart: 1, objects: "buttons", symbol: "🔵", scene: "A coat kit")]),
        .init(id: "numbers-v1-building", initialPart: 4, probes: [
            .init(id: "tower-9-4", total: 9, knownPart: 4, objects: "blocks", symbol: "🧱", scene: "A tower kit"),
            .init(id: "beach-6-2", total: 6, knownPart: 2, objects: "shells", symbol: "🐚", scene: "A beach bag")]),
        .init(id: "numbers-v1-market", initialPart: 2, probes: [
            .init(id: "market-7-3", total: 7, knownPart: 3, objects: "pears", symbol: "🍐", scene: "A market bag"),
            .init(id: "path-9-6", total: 9, knownPart: 6, objects: "stones", symbol: "🟤", scene: "A path kit")])
    ]
    var isReviewed: Bool { Self.reviewed.contains(self) }
    static func at(ordinal: Int) -> Self { reviewed[max(0, ordinal) % reviewed.count] }
}

/// Small reviewed variations change context or arrangement, never the answer rules.
struct LearningPilotVariant: Codable, Equatable {
    let id: String
    let questID: LearningQuestID
    let shapeKind: String?
    let rotation: Int?
    let waterVessel: String?
    let openSwitch: Int?
    static func reviewed(for quest: LearningQuestID) -> [Self] {
        switch quest {
        case .shapes: [
            .init(id: "shape-door-rectangle", questID: quest, shapeKind: "rectangle", rotation: 35, waterVessel: nil, openSwitch: nil),
            .init(id: "shape-sign-triangle", questID: quest, shapeKind: "triangle", rotation: 110, waterVessel: nil, openSwitch: nil)]
        case .waterCycle: [
            .init(id: "water-cold-cup", questID: quest, shapeKind: nil, rotation: nil, waterVessel: "cup", openSwitch: nil),
            .init(id: "water-cold-bottle", questID: quest, shapeKind: nil, rotation: nil, waterVessel: "bottle", openSwitch: nil)]
        case .circuitSpark: [
            .init(id: "circuit-second-switch-open", questID: quest, shapeKind: nil, rotation: nil, waterVessel: nil, openSwitch: 2),
            .init(id: "circuit-first-switch-open", questID: quest, shapeKind: nil, rotation: nil, waterVessel: nil, openSwitch: 1)]
        default: []
        }
    }
    static func at(quest: LearningQuestID, ordinal: Int) -> Self? {
        let bank = reviewed(for: quest)
        return bank.isEmpty ? nil : bank[max(0, ordinal) % bank.count]
    }
    var isReviewed: Bool { Self.reviewed(for: questID).contains(self) }
}

/// Known legacy tasks are aliases of the reviewed defaults, not new probes.
enum LearningQuestProbeIdentity {
    static func canonical(_ id: String) -> String { id == "legacy-picnic-8-3" ? "picnic-8-3" : id }
    static func legacyDefault(for quest: LearningQuestID) -> String? {
        switch quest {
        case .numbers: "picnic-8-3"
        case .shapes: "shape-door-rectangle"
        case .waterCycle: "water-cold-cup"
        case .circuitSpark: "circuit-second-switch-open"
        default: nil
        }
    }
    static func knownProbe(in attempt: ItemAttempt) -> String? {
        guard let quest = LearningQuestID.allCases.first(where: { $0.activityID == attempt.activityID }) else { return nil }
        let known = Set(quest == .numbers ? LearningNumbersVariant.reviewed.flatMap(\.probes).map(\.id)
            : LearningPilotVariant.reviewed(for: quest).map(\.id))
        let legacyTarget = quest.conceptID + ".challenge"
        if attempt.entityID == legacyTarget || (quest == .circuitSpark && [legacyTarget + ".prediction", legacyTarget + ".repair"].contains(attempt.entityID)) {
            return legacyDefault(for: quest)
        }
        let prefix = quest.conceptID + ".probe."
        if attempt.entityID.hasPrefix(prefix) {
            var id = String(attempt.entityID.dropFirst(prefix.count))
            if quest == .circuitSpark {
                for suffix in [".prediction", ".repair"] where id.hasSuffix(suffix) { id.removeLast(suffix.count) }
            }
            id = canonical(id)
            return known.contains(id) ? id : nil
        }
        // Pilot variant IDs also occur on practice events; only transfer-stage
        // events can establish that such a probe has already been presented.
        guard attempt.propertyID == "transfer" || ["challenge", "transfer"].contains(attempt.stageID),
              let variant = attempt.itemVariantID else { return nil }
        let id = canonical(variant)
        return known.contains(id) ? id : nil
    }
}

/// Frozen child and content identity, actual responses, and manipulation state.
/// A checkpoint restores the exact task; it never restores another child's evidence.
struct LearningQuestCheckpoint: Codable, Equatable {
    let schemaVersion: Int
    let profileID: String
    let questID: LearningQuestID
    let sessionID: String
    let contentVersion: Int
    let content: LearningQuestContentSnapshot
    let startedAt: Date
    var updatedAt: Date
    var step: LearningQuestStep
    var guidedPlanID: String?
    var returnLaneID: CapabilityLaneID?
    var returnToGames: Bool
    var completedSteps: [LearningQuestStep]
    var attempts: [ItemAttempt]
    var selectedChoice: String?
    var hasManipulated: Bool
    var accepted: Bool
    var supportVisible: Bool
    var counterCount: Int
    var learnedLeftPart: Int
    var exploredShapes: [String]
    var currentShape: String
    var shapeTurnCount: Int
    var predictionMade: Bool
    var selectedPoints: [Int]
    var angleDegrees: Int
    var waterState: Int
    var wireConnected: Bool
    var switchClosed: Bool
    var secondSwitchClosed: Bool
    var mirrorCells: [Bool]
    var folded: Bool
    var feedback: String
    // Optional additions keep pre-bank saved tasks exactly resumable.
    var numbersVariant: LearningNumbersVariant?
    var variantOrdinal: Int?
    var numberProbeIndex: Int?
    var numberProbeFreshness: [Bool]?
    var pilotVariant: LearningPilotVariant?
    var pilotProbeFresh: Bool?

    init(profileID: String, questID: LearningQuestID, guidedPlanID: String? = nil, returnLaneID: CapabilityLaneID? = nil, returnToGames: Bool = false, content: LearningQuestContentSnapshot = .bundled, numbersVariant: LearningNumbersVariant? = .reviewed[0], variantOrdinal: Int? = 0, numberProbeFreshness: [Bool]? = nil, pilotVariant: LearningPilotVariant? = nil, pilotProbeFresh: Bool? = nil, now: Date = Date()) {
        schemaVersion = 1; self.content = content
        self.numbersVariant = questID == .numbers ? numbersVariant : nil
        self.variantOrdinal = variantOrdinal
        self.pilotVariant = pilotVariant; self.pilotProbeFresh = pilotProbeFresh
        numberProbeIndex = questID == .numbers && numbersVariant != nil ? 0 : nil
        self.numberProbeFreshness = questID == .numbers ? (numberProbeFreshness ?? numbersVariant?.probes.map { _ in true }) : nil
        self.profileID = profileID; self.questID = questID
        sessionID = UUID().uuidString; contentVersion = content.version; startedAt = now; updatedAt = now
        step = .learn; self.guidedPlanID = guidedPlanID; self.returnLaneID = returnLaneID; self.returnToGames = returnToGames
        completedSteps = []; attempts = []; selectedChoice = nil; hasManipulated = false; accepted = false; supportVisible = false
        counterCount = questID == .numbers ? (numbersVariant?.initialPart ?? 6) : 6; learnedLeftPart = counterCount; exploredShapes = ["triangle"]; currentShape = "triangle"; shapeTurnCount = 0; predictionMade = false
        selectedPoints = []; angleDegrees = 30; waterState = 0
        wireConnected = true; switchClosed = false; secondSwitchClosed = false; mirrorCells = [true, false, true]; folded = false; feedback = ""
    }
    var activityID: String { questID.activityID }
    var numberProbe: LearningNumberProbe {
        guard let numbersVariant else { return .init(id: "legacy-picnic-8-3", total: 8, knownPart: 3, objects: "apples", symbol: "🍎", scene: "A new picnic") }
        return numbersVariant.probes[min(max(0, numberProbeIndex ?? 0), numbersVariant.probes.count - 1)]
    }
    var shapeTransferKind: String { pilotVariant?.shapeKind ?? "rectangle" }
    var shapeTransferRotation: Int { pilotVariant?.rotation ?? 35 }
    var waterVessel: String { pilotVariant?.waterVessel ?? "cup" }
    var numberWhole: Int { step == .challenge ? numberProbe.total : 10 }
    var numberKnownPart: Int { step == .challenge ? numberProbe.knownPart : learnedLeftPart }
    var numberAnswer: Int { numberWhole - numberKnownPart }
    var numberProbeCount: Int { numbersVariant?.probes.count ?? 1 }
    var isFreshNumberProbe: Bool? { numberProbeFreshness.flatMap { values in
        let index = numberProbeIndex ?? 0
        return values.indices.contains(index) ? values[index] : nil
    } }
    var currentProbeID: String? {
        questID == .numbers ? LearningQuestProbeIdentity.canonical(numberProbe.id)
            : pilotVariant?.id ?? LearningQuestProbeIdentity.legacyDefault(for: questID)
    }
    var presentedProbeIDs: Set<String> {
        var ids = Set(attempts.compactMap(LearningQuestProbeIdentity.knownProbe))
        guard step == .challenge || step == .celebrate || completedSteps.contains(.challenge) else { return ids }
        if let variant = numbersVariant {
            let count = step == .celebrate || completedSteps.contains(.challenge) ? variant.probes.count : (numberProbeIndex ?? 0) + 1
            ids.formUnion(variant.probes.prefix(count).map(\.id))
        } else if let id = currentProbeID { ids.insert(id) }
        return ids
    }
    var circuitAccessibilityDescription: String {
        let wire = wireConnected ? "Wire is connected." : "Wire has a gap."
        let first = "First, upper switch is \(switchClosed ? "closed" : "open")."
        let second = step == .challenge ? " Second, lower switch is \(secondSwitchClosed ? "closed" : "open")." : ""
        let states = "Pretend battery and bulb. \(wire) \(first)\(second)"
        if step == .challenge && !predictionMade { return states + " Predict what the bulb will do." }
        let lit = wireConnected && switchClosed && (step != .challenge || secondSwitchClosed)
        return states + (lit ? " Bulb is lit." : " Bulb is off.")
    }
    var targetID: String {
        if questID == .numbers && numbersVariant != nil {
            if step == .challenge { return "number-bond.probe.\(numberProbe.id)" }
            return "number-bond.whole-10.part-\(learnedLeftPart)"
        }
        if step == .challenge, let pilotVariant { return "\(questID.conceptID).probe.\(pilotVariant.id)" }
        return "\(questID.conceptID).\(step.rawValue)"
    }
    var isTransfer: Bool { step == .challenge }
    var usesChoices: Bool {
        step == .remember || (questID == .shapes && step == .challenge) || (questID == .waterCycle && step != .learn) || (questID == .circuitSpark && step == .challenge)
    }
    var primaryLabel: String {
        if step == .celebrate { return "Done" }
        if accepted || (step == .learn && hasManipulated) { return "Next" }
        return "Try it"
    }
    var canSubmit: Bool {
        if step == .celebrate || accepted { return true }
        if step == .learn { return hasManipulated }
        if questID == .circuitSpark && step == .challenge && predictionMade { return true }
        if usesChoices { return selectedChoice != nil }
        return true
    }
}

struct LearningQuestChoice: Identifiable, Equatable {
    let id: String
    let label: String
    let symbol: String
}

extension LearningQuestCheckpoint {
    var prompt: String {
        if step == .celebrate { return "You explored, tried, and used your idea in a new way. Choose Done, or try another quest!" }
        switch (questID, step) {
        case (.numbers, .learn): return "Move seeds between the two gardens. Can you change the parts while keeping all ten?"
        case (.numbers, .remember): return "You left \(learnedLeftPart) seeds in this garden. How many are in the other garden to make ten? Choose, then tap Try it."
        case (.numbers, .play): return "Pack the missing seeds beside your \(learnedLeftPart). Use plus or minus, then check the whole ten."
        case (.numbers, .challenge): return numberProbe.prompt
        case (.shapes, .learn): return "Meet the circle, triangle, square, and rectangle. Choose each shape and turn it. Its sides and corners stay the same."
        case (.shapes, .remember): return "Find the shape with three corners. It can point in any direction."
        case (.shapes, .play): return "Make a triangle. Choose three corners on the board, then join them."
        case (.shapes, .challenge): return shapeTransferKind == "triangle" ? "A sign is a triangle. Which shape is still a triangle after we turn it?" : "A door is a rectangle. Which shape is still a rectangle after we turn it?"
        case (.waterCycle, .learn): return "Warm the pond, then cool the air. Watch water become invisible gas, then tiny liquid drops. The arrows help us imagine the gas."
        case (.waterCycle, .remember): return "When sunlight warms a puddle, what can happen to its water?"
        case (.waterCycle, .play): return "Predict first: what does cooling water vapor make? Choose, then cool the air to see."
        case (.waterCycle, .challenge): return "A cold \(waterVessel) is in warm, moist air. Where can tiny drops appear? This is the same cooling idea in a new place."
        case (.circuitSpark, .learn): return "This is a pretend battery and bulb. Open and close the switch. Watch the light when the loop changes."
        case (.circuitSpark, .remember): return "Which pretend circuit can light the bulb? Find a complete loop."
        case (.circuitSpark, .play): return "The light is off because a wire has a gap. Tap the gap to repair the loop, then try the switch."
        case (.circuitSpark, .challenge): return predictionMade ? "Now close both switches in the new loop. Watch the light, then tap Try it to check your repair." : "A new loop has two switches. One is open. Predict the light, then close both switches to test your idea."
        case (.angles, .learn): return "Open and close the gate. Notice a small turn, a square corner, and a wide turn."
        case (.angles, .remember): return "Find a square-corner turn. It is a quarter turn, also called ninety degrees."
        case (.angles, .play): return "Open the gate until it makes a square corner. You can use the plus and minus buttons."
        case (.angles, .challenge): return "A wider doorway needs a wider turn. Match the new wide-turn guide."
        case (.symmetry, .learn): return "Fold the butterfly. Matching halves cover each other. Unfold it and look again."
        case (.symmetry, .remember): return "Which butterfly has matching mirror halves?"
        case (.symmetry, .play): return "Repair the right wing so it mirrors the left wing. Tap a patch to change it."
        case (.symmetry, .challenge): return "A new butterfly has different patches. Make its two halves match, then fold to check."
        default: return "Try your idea."
        }
    }
    var choices: [LearningQuestChoice] {
        switch questID {
        case .numbers:
            let answer: Int = numberAnswer
            let candidates: [Int] = Array(0...numberWhole)
            let alternatives: [Int] = candidates.filter { candidate in candidate != answer }
            let distractors: [Int] = alternatives.sorted { (left: Int, right: Int) -> Bool in
                let leftDistance: Int = abs(left - answer)
                let rightDistance: Int = abs(right - answer)
                if leftDistance == rightDistance { return left < right }
                return leftDistance < rightDistance
            }
            let nearest: [Int] = Array(distractors.prefix(2))
            let values: [Int] = ([answer] + nearest).sorted()
            return values.map { value in LearningQuestChoice(id: String(value), label: String(value), symbol: String(value)) }
        case .shapes:
            if step == .challenge {
                let kinds: [String] = shapeTransferKind == "triangle" ? ["circle", "rectangle", "triangle"] : ["rectangle", "triangle", "circle"]
                return zip(kinds, ["one", "two", "three"]).map { kind, position in
                    LearningQuestChoice(id: kind, label: "Picture \(position)", symbol: kind)
                }
            }
            return [LearningQuestChoice(id: "square", label: "Picture one", symbol: "square"), LearningQuestChoice(id: "triangle", label: "Picture two", symbol: "triangle"), LearningQuestChoice(id: "circle", label: "Picture three", symbol: "circle")]
        case .waterCycle:
            if step == .challenge { return [LearningQuestChoice(id: "outside", label: "Drops on the outside", symbol: "🥤💧"), LearningQuestChoice(id: "inside", label: "Drops inside the cup", symbol: "inside"), LearningQuestChoice(id: "none", label: "No drops appear", symbol: "none")] }
            return [LearningQuestChoice(id: "vapor", label: "Invisible water vapor", symbol: "💧⬆️"), LearningQuestChoice(id: "drops", label: "Tiny drops make a cloud", symbol: "☁️💧"), LearningQuestChoice(id: "ice", label: "An ice block", symbol: "🧊")]
        case .circuitSpark:
            if step == .challenge { return [LearningQuestChoice(id: "off", label: "Light off", symbol: "🌑"), LearningQuestChoice(id: "on", label: "Light on", symbol: "💡")] }
            return [LearningQuestChoice(id: "open", label: "Picture one", symbol: "open"), LearningQuestChoice(id: "closed", label: "Picture two", symbol: "closed")]
        case .angles: return [LearningQuestChoice(id: "30", label: "Picture one", symbol: "30"), LearningQuestChoice(id: "90", label: "Picture two", symbol: "90"), LearningQuestChoice(id: "150", label: "Picture three", symbol: "150")]
        case .symmetry: return [LearningQuestChoice(id: "broken", label: "Picture one", symbol: "broken"), LearningQuestChoice(id: "match", label: "Picture two", symbol: "match")]
        }
    }
    var support: String {
        switch questID {
        case .numbers:
            if step == .learn { return "Move one seed at a time. Count both gardens: the whole stays ten." }
            return "Start with \(numberKnownPart). Count the empty places up to \(numberWhole). Place one counter in each empty place, then check the whole."
        case .shapes: return step == .play ? "A triangle needs three corners joined by three straight sides. Avoid putting all three in one straight line." : "Count the straight sides and corners. Turning a shape does not change its name."
        case .waterCycle: return step == .remember ? "Warmth helps liquid water become invisible water vapor." : "Cooling water vapor can make tiny liquid drops. Look for a cloud, or drops on a cold cup."
        case .circuitSpark: return "Trace from the pretend battery through the bulb and back. Any gap stops the light. Close every gap to light it."
        case .angles: return "A square corner is a quarter turn. Open more for a wider turn; close a little for a smaller turn."
        case .symmetry: return "Compare the patches one at a time across the middle line. Matching patches cover each other when folded."
        }
    }
}

extension LearningQuestID {
    var conceptTitle: String {
        switch self {
        case .numbers: "Parts and wholes"
        case .shapes: "Sides, corners and rotation"
        case .waterCycle: "Evaporation and condensation"
        case .circuitSpark: "Complete pretend circuits"
        case .angles: "Comparing turns"
        case .symmetry: "Mirror halves"
        }
    }
    var offscreenPrompt: String {
        switch self {
        case .numbers: "Put eight blocks on a tray. Hide three under a cup. Ask how many are still visible, then uncover and check that both parts make eight. Try six blocks with a different hidden part next time."
        case .shapes: "Find a rectangular book cover and a triangular paper cutout. Turn each one. Ask your child to trace the sides and corners and explain what stayed the same."
        case .waterCycle: "Wipe the outside of a cold cup dry and place it in warm, moist room air. Predict where drops may form. Look together later; explain that water vapor in the air cooled into liquid drops."
        case .circuitSpark: "Draw a pretend battery, bulb and loop on paper. Leave one gap. Ask your child to trace the path back to the battery and draw a repair. Use drawings, never a wall socket."
        case .angles: "Open a book a little, to a square corner, then wider. Ask your child to compare the turns and find a square corner on a sheet of paper."
        case .symmetry: "Fold paper in half. Make three marks near the fold on one side. Ask where matching marks would go on the other side, then fold to compare."
        }
    }
}
