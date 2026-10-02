import Foundation
import Observation

enum ShapeDetectiveKind: String, Codable, CaseIterable {
    case circle, triangle, square, rectangle, nonSquareRhombus

    var title: String {
        switch self {
        case .nonSquareRhombus: "rhombus"
        default: rawValue
        }
    }

    var outlineDescription: String {
        switch self {
        case .circle: "A round curved edge with no corners."
        case .triangle: "Three straight sides and three corners."
        case .square: "Four equal straight sides and four square corners."
        case .rectangle: "Four square corners. Two longer sides and two shorter sides."
        case .nonSquareRhombus: "Four equal straight sides. Two narrow corners and two wide corners."
        }
    }
}

/// Geometry is content, not a label announcing the answer. Rotation and uniform
/// scaling never change the defining properties of a figure.
struct ShapeDetectiveFigure: Equatable {
    let kind: ShapeDetectiveKind
    var rotation: Double = 0
    var scale: Double = 1
    var narrowTriangle = false
    var rectangleWidth: Double = 0.84
    var rectangleHeight: Double = 0.46

    var vertices: [ShapeDetectiveVertex] {
        switch kind {
        case .circle: return []
        case .square: return [.init(x: 0.1, y: 0.1), .init(x: 0.9, y: 0.1), .init(x: 0.9, y: 0.9), .init(x: 0.1, y: 0.9)]
        case .rectangle:
            let x = (1 - rectangleWidth) / 2, y = (1 - rectangleHeight) / 2
            return [.init(x: x, y: y), .init(x: 1 - x, y: y), .init(x: 1 - x, y: 1 - y), .init(x: x, y: 1 - y)]
        case .triangle:
            return narrowTriangle ? [.init(x: 0.37, y: 0.05), .init(x: 0.60, y: 0.95), .init(x: 0.18, y: 0.83)] : [.init(x: 0.5, y: 0.05), .init(x: 0.95, y: 0.88), .init(x: 0.05, y: 0.88)]
        case .nonSquareRhombus: return [.init(x: 0.5, y: 0.23), .init(x: 0.96, y: 0.5), .init(x: 0.5, y: 0.77), .init(x: 0.04, y: 0.5)]
        }
    }
}

struct ShapeDetectiveVertex: Equatable { let x: Double; let y: Double }

struct ShapeDetectiveChoice: Identifiable, Equatable {
    let id: String
    let figure: ShapeDetectiveFigure
    let letter: String
    var label: String { "Shape \(letter)" }
    var spokenDescription: String { "\(label). \(figure.kind.outlineDescription)" }
}

struct ShapeDetectiveInvestigation: Identifiable, Equatable {
    let id: String
    let clue: String
    let answer: ShapeDetectiveKind
    let hint: String
    let fact: String
    let choices: [ShapeDetectiveChoice]
    var isProbe = false
    var answerID: String { choices.first { $0.figure.kind == answer }!.id }
}

enum ShapeDetectiveCatalog {
    static let version = 1

    private static func item(_ id: String, clue: String, answer: ShapeDetectiveKind, hint: String, fact: String,
                             figures: [ShapeDetectiveFigure], probe: Bool = false) -> ShapeDetectiveInvestigation {
        .init(id: id, clue: clue, answer: answer, hint: hint, fact: fact,
              choices: figures.enumerated().map { index, figure in
                  .init(id: "\(id)-\(index)", figure: figure, letter: ["A", "B", "C", "D"][index])
              }, isProbe: probe)
    }

    static let practice: [ShapeDetectiveInvestigation] = [
        item("curved-edge", clue: "Find the shape with no corners and one curved edge.", answer: .circle,
             hint: "Trace the edge. Look for a curve all the way around, with no pointy corners.",
             fact: "A circle has no corners. Making it smaller does not change that.",
             figures: [.init(kind: .triangle, rotation: 25), .init(kind: .circle, scale: 0.63), .init(kind: .square, rotation: 15), .init(kind: .rectangle, rotation: 90)]),
        item("three-sides", clue: "Find exactly three straight sides and three corners.", answer: .triangle,
             hint: "Count each straight side once. A triangle can be tall, narrow, or turned.",
             fact: "This narrow, turned triangle still has exactly three sides.",
             figures: [.init(kind: .rectangle, rotation: 25), .init(kind: .square, scale: 0.62), .init(kind: .nonSquareRhombus), .init(kind: .triangle, rotation: 100, narrowTriangle: true)]),
        item("square-corners", clue: "Find four equal sides AND four square corners.", answer: .square,
             hint: "Equal sides are one clue. Also check that every corner is a square corner, like the corner of a book.",
             fact: "A turned square is still a square. A square is also a rectangle because it has four square corners.",
             figures: [.init(kind: .nonSquareRhombus, rotation: 20), .init(kind: .rectangle), .init(kind: .square, rotation: 45, scale: 0.72), .init(kind: .triangle)]),
        item("tall-rectangle", clue: "Find four square corners, with two longer and two shorter sides.", answer: .rectangle,
             hint: "Check all four corners. Then compare nearby sides: one is longer than the next.",
             fact: "This tall rectangle has four square corners. Rectangles can stand tall or lie wide. Squares are rectangles too, with all sides equal.",
             figures: [.init(kind: .rectangle, rotation: 90, scale: 0.78), .init(kind: .nonSquareRhombus, rotation: 90), .init(kind: .circle), .init(kind: .square, rotation: 45)]),
        item("rhombus-corners", clue: "Find four equal sides, with narrow and wide corners instead of square corners.", answer: .nonSquareRhombus,
             hint: "Compare the corners. A square has four square corners; this clue asks for narrow and wide corners.",
             fact: "This rhombus has four equal sides but no square corners. Equal sides alone do not make a square.",
             figures: [.init(kind: .square, rotation: 45), .init(kind: .nonSquareRhombus, rotation: 55, scale: 0.86), .init(kind: .rectangle, rotation: 45), .init(kind: .triangle, rotation: 40)]),
        item("triangle-turn", clue: "Find three straight sides, even when the shape is turned.", answer: .triangle,
             hint: "Start at a corner and count the sides until you return to the start.",
             fact: "Turning and resizing a triangle do not add any sides.",
             figures: [.init(kind: .circle, scale: 0.6), .init(kind: .nonSquareRhombus, rotation: 120), .init(kind: .triangle, rotation: 205, scale: 0.63), .init(kind: .square, rotation: 10)])
    ]

    /// A finite reviewed pool, reserved on first exposure. After exhaustion,
    /// replay is explicitly a revisit and is never reported as a fresh probe.
    static let probes: [ShapeDetectiveInvestigation] = (0..<12).map { index in
        let angle = [23.0, 67, 112, 158, 203, 247, 292, 338, 31, 76, 121, 166][index]
        let answerSlot = (index + 2) % 4
        var figures: [ShapeDetectiveFigure] = [
            .init(kind: .square, rotation: angle + 20, scale: 0.64),
            .init(kind: .nonSquareRhombus, rotation: angle - 35, scale: 0.8),
            .init(kind: .triangle, rotation: angle + 75, narrowTriangle: true)
        ]
        figures.insert(.init(kind: .rectangle, rotation: angle, scale: 0.82,
                             rectangleWidth: 0.82, rectangleHeight: 0.26 + Double(index) * 0.012), at: answerSlot)
        return item("fresh-rectangle-\(index)", clue: "Find four square corners, with two longer and two shorter sides.", answer: .rectangle,
                    hint: "The direction and size are different. Check the corners and compare nearby sides.",
                    fact: "You checked the properties of this turned rectangle. Its direction does not change its corners or sides.",
                    figures: figures, probe: true)
    }

    static func probe(id: String) -> ShapeDetectiveInvestigation? { probes.first { $0.id == id } }
}

struct ShapeDetectiveCheckpoint: Codable, Equatable {
    var version = ShapeDetectiveCatalog.version
    var sessionID = UUID().uuidString
    let profileID: String
    let familyMode: Bool
    var startedAt = Date()
    let probeID: String
    let probeIsFresh: Bool
    var index = 0
    var solved = false
    var hintLevel = 0
    var misses = 0
    var lastChoiceID: String?
    var attempts: [ItemAttempt] = []
    var completedIDs: [String] = []
    var endedAt: Date?
    var roomPromptShown = false

    var rounds: [ShapeDetectiveInvestigation] {
        ShapeDetectiveCatalog.practice + [ShapeDetectiveCatalog.probe(id: probeID)!]
    }

    func isValid(for profileID: String) -> Bool {
        guard version == ShapeDetectiveCatalog.version, self.profileID == profileID,
              UUID(uuidString: sessionID) != nil, ShapeDetectiveCatalog.probe(id: probeID) != nil,
              (0...7).contains(index), (0...2).contains(hintLevel), misses >= 0 else { return false }
        let expectedCount = index + (solved && index < 7 ? 1 : 0)
        guard completedIDs == Array(rounds.prefix(expectedCount).map(\.id)),
              (index == 7) == (endedAt != nil), index < 7 || !solved else { return false }
        if let lastChoiceID, index < 7, !rounds[index].choices.contains(where: { $0.id == lastChoiceID }) { return false }
        let exposedIDs = Set(rounds.prefix(min(index + 1, 7)).map(\.id))
        guard Set(attempts.map(\.id)).count == attempts.count else { return false }
        var exposed = Set<String>()
        var supported = Set<String>()
        var correctIDs: [String] = []
        for attempt in attempts {
            guard attempt.activityID == ShapeDetectiveTVSession.activityID, attempt.profileID == profileID,
                  attempt.sessionID == sessionID, attempt.contentVersion == version,
                  let variant = attempt.itemVariantID, exposedIDs.contains(variant),
                  let item = rounds.first(where: { $0.id == variant }),
                  attempt.conceptID == "shape-properties", attempt.entityID == item.answer.rawValue,
                  attempt.propertyID == item.id, attempt.stageID == (item.isProbe ? "transfer" : "investigation"),
                  attempt.isFreshProbe == (item.isProbe && probeIsFresh), attempt.appHintUsed != nil else { return false }
            switch attempt.outcome {
            case .exposure:
                guard exposed.insert(variant).inserted, attempt.response == nil else { return false }
            case .help:
                guard exposed.contains(variant), !correctIDs.contains(variant), attempt.appHintUsed == true,
                      ["property-clue", "trace-sides-and-corners"].contains(attempt.response ?? "") else { return false }
                supported.insert(variant)
            case .incorrect:
                guard exposed.contains(variant), !correctIDs.contains(variant),
                      item.choices.contains(where: { $0.id == attempt.response && $0.id != item.answerID }) else { return false }
                supported.insert(variant)
            case .independentCorrect, .supportedCorrect:
                guard exposed.contains(variant), !correctIDs.contains(variant), attempt.response == item.answerID else { return false }
                if attempt.outcome == .independentCorrect && (supported.contains(variant) || attempt.appHintUsed == true) { return false }
                correctIDs.append(variant)
            }
        }
        guard correctIDs == completedIDs else { return false }
        if index < rounds.count {
            let currentAttempts = attempts.filter { $0.itemVariantID == rounds[index].id }
            guard misses == currentAttempts.filter({ $0.outcome == .incorrect }).count,
                  hintLevel == currentAttempts.filter({ $0.outcome == .help }).count else { return false }
        }
        return true
    }
}

@MainActor
@Observable
final class ShapeDetectiveTVSession {
    nonisolated static let activityID = "tv-shape-detective"
    private(set) var checkpoint: ShapeDetectiveCheckpoint
    private(set) var storageIssue: ShapeDetectiveStorageIssue?
    @ObservationIgnored private let store: ShapeDetectiveTVSessionStore
    @ObservationIgnored private let onAttempt: (ItemAttempt) -> Void
    @ObservationIgnored private let onResult: (ActivityResult) -> Void

    init(profileID: String = "tv-family", familyMode: Bool = true,
         store: ShapeDetectiveTVSessionStore? = nil,
         onAttempt: @escaping (ItemAttempt) -> Void = { _ in }, onResult: @escaping (ActivityResult) -> Void = { _ in }) {
        let store = store ?? .init(profileID: profileID)
        self.store = store
        self.onAttempt = onAttempt
        self.onResult = onResult
        switch store.loadState() {
        case .ready(let saved): checkpoint = saved
        case .empty: checkpoint = Self.newCheckpoint(profileID: profileID, familyMode: familyMode, store: store)
        case .blocked(let issue):
            // Placeholder only: no write, exposure, fresh claim, or callback.
            checkpoint = .init(profileID: profileID, familyMode: familyMode,
                               probeID: ShapeDetectiveCatalog.probes[0].id, probeIsFresh: false)
            storageIssue = issue
            return
        }
        // Replaying frozen IDs repairs an interrupted write at the shared ledger.
        checkpoint.attempts.forEach(onAttempt)
        if let result { onResult(result) }
        exposeCurrentItem()
    }

    var isComplete: Bool { storageIssue == nil && checkpoint.index == checkpoint.rounds.count }
    var current: ShapeDetectiveInvestigation? { storageIssue != nil || isComplete ? nil : checkpoint.rounds[checkpoint.index] }
    var unaidedCount: Int { checkpoint.attempts.filter { $0.outcome == .independentCorrect }.count }
    var supportedCount: Int { checkpoint.attempts.filter { $0.outcome == .supportedCorrect }.count }
    var prompt: String {
        if storageIssue != nil { return "This saved investigation needs a parent. Your saved work is kept safe. Return to all games; a parent can review and reset it when ready." }
        guard let current else { return "Investigation complete. You checked seven shapes. You can finish, look for a shape in your room, or investigate again." }
        if checkpoint.solved { return "Mystery solved! \(current.fact) Select Next to continue." }
        let support = checkpoint.hintLevel > 0 ? " \(current.hint)" : ""
        let context = current.isProbe ? (checkpoint.probeIsFresh ? "A new shape check. " : "A shape check again. ") : ""
        return "\(context)\(current.clue)\(support) Swipe across the shapes and select. Play Pause repeats the clue."
    }
    var feedback: String {
        guard let current else { return "You finished your investigation." }
        if checkpoint.solved { return "Mystery solved! \(current.fact)" }
        return checkpoint.misses > 0 ? "Keep investigating. \(current.hint)" : checkpoint.hintLevel > 0 ? current.hint : "Check the shapes, then select."
    }
    var result: ActivityResult? {
        guard storageIssue == nil, let endedAt = checkpoint.endedAt else { return nil }
        return .init(id: checkpoint.sessionID, activityID: Self.activityID, title: "Shape Detective",
                     startedAt: checkpoint.startedAt, endedAt: endedAt, attempts: checkpoint.attempts,
                     completedStageIDs: checkpoint.completedIDs, profileID: checkpoint.profileID, contentVersion: checkpoint.version)
    }

    @discardableResult
    func choose(_ choiceID: String) -> Bool {
        guard canUseStorage(), let current, !checkpoint.solved, let choice = current.choices.first(where: { $0.id == choiceID }) else { return false }
        let correct = choice.figure.kind == current.answer
        let supported = checkpoint.hintLevel > 0 || checkpoint.misses > 0
        checkpoint.lastChoiceID = choiceID
        if correct {
            checkpoint.solved = true
            checkpoint.completedIDs.append(current.id)
            record(supported ? .supportedCorrect : .independentCorrect, response: choiceID)
        } else {
            checkpoint.misses += 1
            record(.incorrect, response: choiceID)
            requestHint()
        }
        persist()
        return correct
    }

    func requestHint() {
        guard canUseStorage(), current != nil, !checkpoint.solved else { return }
        guard checkpoint.hintLevel < 2 else { return }
        checkpoint.hintLevel += 1
        record(.help, response: checkpoint.hintLevel == 1 ? "property-clue" : "trace-sides-and-corners")
        persist()
    }

    func advance() {
        guard canUseStorage(), current != nil, checkpoint.solved else { return }
        checkpoint.index += 1
        checkpoint.solved = false
        checkpoint.hintLevel = 0
        checkpoint.misses = 0
        checkpoint.lastChoiceID = nil
        if isComplete { checkpoint.endedAt = Date() }
        persist()
        if let result { onResult(result) } else { exposeCurrentItem() }
    }

    func showRoomPrompt() {
        guard canUseStorage(), isComplete else { return }
        checkpoint.roomPromptShown = true
        persist()
        // This optional conversation is not a verified response or transfer.
    }

    func replay() {
        guard canUseStorage(), isComplete else { return }
        checkpoint = Self.newCheckpoint(profileID: checkpoint.profileID, familyMode: checkpoint.familyMode, store: store)
        exposeCurrentItem()
    }

    private static func newCheckpoint(profileID: String, familyMode: Bool, store: ShapeDetectiveTVSessionStore) -> ShapeDetectiveCheckpoint {
        let unused = ShapeDetectiveCatalog.probes.first { !store.usedProbeIDs.contains($0.id) }
        return .init(profileID: profileID, familyMode: familyMode,
                     probeID: (unused ?? ShapeDetectiveCatalog.probes[0]).id, probeIsFresh: unused != nil)
    }

    private func exposeCurrentItem() {
        guard let current, !checkpoint.attempts.contains(where: { $0.itemVariantID == current.id && $0.outcome == .exposure }) else { return }
        if current.isProbe, !store.reserveProbe(current.id) { checkStorageIssue(); return }
        record(.exposure)
        persist()
    }

    private func record(_ outcome: ItemAttemptOutcome, response: String? = nil) {
        guard let current else { return }
        let attempt = ItemAttempt(activityID: Self.activityID, conceptID: "shape-properties", entityID: current.answer.rawValue,
                                  propertyID: current.id, stageID: current.isProbe ? "transfer" : "investigation",
                                  outcome: outcome, response: response, profileID: checkpoint.profileID,
                                  sessionID: checkpoint.sessionID, contentVersion: checkpoint.version, itemVariantID: current.id,
                                  appHintUsed: checkpoint.hintLevel > 0, isFreshProbe: current.isProbe && checkpoint.probeIsFresh,
                                  adultHelp: .unknown)
        checkpoint.attempts.append(attempt)
        guard persist() else { return } // Local durability precedes the external callback.
        onAttempt(attempt)
    }

    private func canUseStorage() -> Bool {
        guard storageIssue == nil else { return false }
        checkStorageIssue()
        return storageIssue == nil
    }

    private func checkStorageIssue() {
        if case .blocked(let issue) = store.loadState() { storageIssue = issue }
    }

    @discardableResult
    private func persist() -> Bool {
        guard storageIssue == nil else { return false }
        guard store.save(checkpoint) else {
            checkStorageIssue()
            if storageIssue == nil { storageIssue = .corruptCheckpoint }
            return false
        }
        return true
    }
}
