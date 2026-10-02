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

    init(profileID: String, questID: LearningQuestID, guidedPlanID: String? = nil, returnLaneID: CapabilityLaneID? = nil, returnToGames: Bool = false, content: LearningQuestContentSnapshot = .bundled, now: Date = Date()) {
        schemaVersion = 1; self.content = content
        self.profileID = profileID; self.questID = questID
        sessionID = UUID().uuidString; contentVersion = content.version; startedAt = now; updatedAt = now
        step = .learn; self.guidedPlanID = guidedPlanID; self.returnLaneID = returnLaneID; self.returnToGames = returnToGames
        completedSteps = []; attempts = []; selectedChoice = nil; hasManipulated = false; accepted = false; supportVisible = false
        counterCount = 6; learnedLeftPart = 6; exploredShapes = ["triangle"]; currentShape = "triangle"; shapeTurnCount = 0; predictionMade = false
        selectedPoints = []; angleDegrees = 30; waterState = 0
        wireConnected = true; switchClosed = false; secondSwitchClosed = false; mirrorCells = [true, false, true]; folded = false; feedback = ""
    }
    var activityID: String { questID.activityID }
    var targetID: String { "\(questID.conceptID).\(step.rawValue)" }
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
        case (.numbers, .challenge): return "A new picnic has eight apples. Three are packed. Pack the missing apples in the basket."
        case (.shapes, .learn): return "Meet the circle, triangle, square, and rectangle. Choose each shape and turn it. Its sides and corners stay the same."
        case (.shapes, .remember): return "Find the shape with three corners. It can point in any direction."
        case (.shapes, .play): return "Make a triangle. Choose three corners on the board, then join them."
        case (.shapes, .challenge): return "A door is a rectangle. Which shape is still a rectangle after we turn it?"
        case (.waterCycle, .learn): return "Warm the pond, then cool the air. Watch water become invisible gas, then tiny liquid drops. The arrows help us imagine the gas."
        case (.waterCycle, .remember): return "When sunlight warms a puddle, what can happen to its water?"
        case (.waterCycle, .play): return "Predict first: what does cooling water vapor make? Choose, then cool the air to see."
        case (.waterCycle, .challenge): return "A cold cup is in warm, moist air. Where can tiny drops appear? This is the same cooling idea in a new place."
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
            let answer = 10 - learnedLeftPart
            let values = Array(Set([answer, max(0, answer-1), min(10, answer+1), answer == 0 ? 2 : 0])).sorted().prefix(3)
            return values.map { .init(id: String($0), label: String($0), symbol: String($0)) }
        case .shapes:
            if step == .challenge { return [.init(id: "rectangle", label: "Turned rectangle", symbol: "rectangle"), .init(id: "triangle", label: "Triangle", symbol: "triangle"), .init(id: "circle", label: "Circle", symbol: "circle")] }
            return [.init(id: "square", label: "Square", symbol: "square"), .init(id: "triangle", label: "Turned triangle", symbol: "triangle"), .init(id: "circle", label: "Circle", symbol: "circle")]
        case .waterCycle:
            if step == .challenge { return [.init(id: "outside", label: "Drops on the outside", symbol: "🥤💧"), .init(id: "inside", label: "Drops inside the cup", symbol: "inside"), .init(id: "none", label: "No drops appear", symbol: "none")] }
            return [.init(id: "vapor", label: "Invisible water vapor", symbol: "💧⬆️"), .init(id: "drops", label: "Tiny drops make a cloud", symbol: "☁️💧"), .init(id: "ice", label: "An ice block", symbol: "🧊")]
        case .circuitSpark:
            if step == .challenge { return [.init(id: "off", label: "Light off with a gap", symbol: "🌑"), .init(id: "on", label: "Light on", symbol: "💡")] }
            return [.init(id: "open", label: "A loop with a gap", symbol: "open"), .init(id: "closed", label: "A complete loop", symbol: "closed")]
        case .angles: return [.init(id: "30", label: "Small turn", symbol: "30"), .init(id: "90", label: "Square-corner turn", symbol: "90"), .init(id: "150", label: "Wide turn", symbol: "150")]
        case .symmetry: return [.init(id: "broken", label: "Different halves", symbol: "broken"), .init(id: "match", label: "Matching mirror halves", symbol: "match")]
        }
    }
    var support: String {
        switch questID {
        case .numbers:
            let part = step == .learn ? counterCount : learnedLeftPart
            return step == .challenge ? "Count on from three to eight: four, five, six, seven, eight. Five apples fill the gap." : "Use the ten-frame. \(part) filled spaces leave \(10-part) spaces to fill."
        case .shapes: return step == .play ? "A triangle needs three corners joined by three straight sides. Avoid putting all three in one straight line." : "Count the straight sides and corners. Turning a shape does not change its name."
        case .waterCycle: return step == .remember ? "Warmth helps liquid water become invisible water vapor." : "Cooling water vapor can make tiny liquid drops. Look for a cloud, or drops on a cold cup."
        case .circuitSpark: return "Trace from the pretend battery through the bulb and back. Any gap stops the light. Close every gap to light it."
        case .angles: return "A square corner is a quarter turn. Open more for a wider turn; close a little for a smaller turn."
        case .symmetry: return "Compare the patches one at a time across the middle line. Matching patches cover each other when folded."
        }
    }
}
