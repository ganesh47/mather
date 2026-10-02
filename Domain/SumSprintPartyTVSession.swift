import Foundation
import Observation

enum SumSprintPartyTVRange: Int, CaseIterable, Codable, Identifiable {
    case through5 = 5, through10 = 10, through20 = 20
    var id: Int { rawValue }
    var title: String { "Through \(rawValue)" }
}

enum SumSprintPartyTVRepresentation: String, Codable {
    case counterTrays, fiveFrames, equationWithParts, numberParts
    var spokenDescription: String {
        switch self {
        case .counterTrays: "Two trays of counters"
        case .fiveFrames: "Counters arranged in rows of five"
        case .equationWithParts: "An addition sentence with two pictured parts"
        case .numberParts: "Two number parts joined to a missing whole"
        }
    }
}

struct SumSprintPartyTVItem: Identifiable, Codable, Equatable {
    let id: String
    let round: SumSprintPartyTVRound
    let representation: SumSprintPartyTVRepresentation
    let isFreshProbe: Bool
    var isProbe: Bool { representation == .numberParts }
    var variantID: String { "\(round.fact.id).\(representation.rawValue)" }
}

enum SumSprintPartyTVSupport: Int, Codable {
    case none, groups, countOn
}

struct SumSprintPartyTVItemProgress: Codable, Equatable {
    var support: SumSprintPartyTVSupport = .none
    var missCount = 0
    var counted = 0
    var selectedAnswer: Int?
    var outcome: ItemAttemptOutcome?
    var exposed = false
    var usedHelp: Bool { support != .none || missCount > 0 || counted > 0 }
}

struct SumSprintPartyTVCheckpoint: Codable, Equatable {
    static let version = 1
    static let activityID = "tv-sum-sprint"
    static let itemCount = 6
    let version: Int
    let sessionID: String
    let profileID: String
    let familyMode: Bool
    let range: SumSprintPartyTVRange
    let startedAt: Date
    let items: [SumSprintPartyTVItem]
    var progress: [SumSprintPartyTVItemProgress]
    var currentIndex = 0
    var attempts: [ItemAttempt] = []
    var completedAt: Date?

    var isComplete: Bool { completedAt != nil }
    var unaidedCount: Int { progress.filter { $0.outcome == .independentCorrect }.count }
    var helpedCount: Int { progress.filter { $0.outcome == .supportedCorrect }.count }
    var freshProbeUnaided: Bool { items.last?.isFreshProbe == true && progress.last?.outcome == .independentCorrect }
    var result: ActivityResult? {
        guard let completedAt else { return nil }
        return ActivityResult(id: sessionID, activityID: Self.activityID, title: "Sum Sprint · \(range.title)",
            startedAt: startedAt, endedAt: completedAt, attempts: attempts,
            completedStageIDs: ["practice", items.last?.isFreshProbe == true ? "fresh-probe" : "transfer"], profileID: profileID, contentVersion: version)
    }

    func isValid(for profileID: String, familyMode: Bool) -> Bool {
        guard version == Self.version, self.profileID == profileID, self.familyMode == familyMode,
              !sessionID.isEmpty, items.count == Self.itemCount, progress.count == items.count,
              (0..<items.count).contains(currentIndex),
              Set(items.map(\.id)).count == items.count,
              Set(items.map { $0.round.fact.id }).count == items.count,
              items.dropLast().allSatisfy({ !$0.isFreshProbe && $0.representation != .numberParts }),
              items.last?.representation == .numberParts,
              Set(attempts.map(\.id)).count == attempts.count else { return false }
        for (index, item) in items.enumerated() {
            let state = progress[index]
            let fact = item.round.fact
            guard fact.addendA > 0, fact.addendB > 0, (2...range.rawValue).contains(fact.sum),
                  item.round.answerChoices.count == 4, Set(item.round.answerChoices).count == 4,
                  item.round.answerChoices.contains(fact.sum),
                  item.round.answerChoices.allSatisfy({ (1...range.rawValue).contains($0) }),
                  state.missCount >= 0, (0...fact.addendB).contains(state.counted),
                  state.selectedAnswer == nil || item.round.answerChoices.contains(state.selectedAnswer!),
                  state.outcome == nil || state.outcome == .independentCorrect || state.outcome == .supportedCorrect,
                  state.outcome == nil || state.selectedAnswer == fact.sum,
                  state.outcome != .independentCorrect || !state.usedHelp,
                  index >= currentIndex || state.outcome != nil,
                  index <= currentIndex || (state == SumSprintPartyTVItemProgress()) else { return false }
        }
        return (!isComplete || (currentIndex == items.count - 1 && progress.allSatisfy { $0.outcome != nil }))
            && attempts.allSatisfy { $0.activityID == Self.activityID && $0.profileID == profileID && $0.sessionID == sessionID }
    }

    static func make(range: SumSprintPartyTVRange, profileID: String, familyMode: Bool, seed: UInt64,
                     sessionID: String = UUID().uuidString, startedAt: Date = Date(),
                     previouslySeenVariants: Set<String> = []) -> Self {
        var generator = SumSprintPartyTVRandom(seed: seed)
        let pool = SumSprintPartyTVRound.facts(through: range.rawValue).shuffled(using: &generator)
        let probe = pool.first { !previouslySeenVariants.contains("\($0.id).numberParts") } ?? pool[0]
        let facts = Array(pool.filter { $0.id != probe.id }.prefix(itemCount - 1)) + [probe]
        let representations: [SumSprintPartyTVRepresentation] = [.counterTrays, .counterTrays, .fiveFrames, .fiveFrames, .equationWithParts, .numberParts]
        let items = facts.enumerated().map { index, fact in
            SumSprintPartyTVItem(id: "\(sessionID).item-\(index)",
                round: SumSprintPartyTVRound(index: index, fact: fact,
                    answerChoices: SumSprintPartyTVRound.answerChoices(for: fact, through: range.rawValue)),
                representation: representations[index],
                isFreshProbe: index == itemCount - 1 && !previouslySeenVariants.contains("\(fact.id).numberParts"))
        }
        return Self(version: version, sessionID: sessionID, profileID: profileID, familyMode: familyMode,
            range: range, startedAt: startedAt, items: items,
            progress: Array(repeating: SumSprintPartyTVItemProgress(), count: itemCount))
    }
}

private struct SumSprintPartyTVRandom: RandomNumberGenerator {
    var state: UInt64
    init(seed: UInt64) { state = seed }
    mutating func next() -> UInt64 {
        state &+= 0x9E3779B97F4A7C15
        var value = state
        value = (value ^ (value >> 30)) &* 0xBF58476D1CE4E5B9
        value = (value ^ (value >> 27)) &* 0x94D049BB133111EB
        return value ^ (value >> 31)
    }
}

/// Absence and unreadable saved data have different preservation rules.
enum SumSprintPartyTVStorageState<Value: Equatable>: Equatable {
    case missing
    case loaded(Value)
    case unsupported

    var isUnsupported: Bool {
        if case .unsupported = self { return true }
        return false
    }
}

/// Separate keys preserve the shipped personal-best record and each child's session.
@MainActor
final class SumSprintPartyTVSessionStore {
    private let defaults: UserDefaults
    private let key: String
    private let profileID: String
    private let familyMode: Bool
    init(defaults: UserDefaults = .standard, profileID: String, familyMode: Bool = true) {
        self.defaults = defaults
        self.profileID = profileID
        self.familyMode = familyMode
        key = "tv.sumSprintParty.learning.v1.\(familyMode ? "family" : "child").\(profileID)"
    }
    var checkpointState: SumSprintPartyTVStorageState<SumSprintPartyTVCheckpoint> {
        guard let value = defaults.object(forKey: key) else { return .missing }
        guard let data = value as? Data,
              let saved = try? JSONDecoder().decode(SumSprintPartyTVCheckpoint.self, from: data),
              saved.isValid(for: profileID, familyMode: familyMode) else { return .unsupported }
        return .loaded(saved)
    }
    var historyState: SumSprintPartyTVStorageState<[SumSprintPartyTVCheckpoint]> {
        guard let value = defaults.object(forKey: key + ".history") else { return .missing }
        guard let data = value as? Data,
              let saved = try? JSONDecoder().decode([SumSprintPartyTVCheckpoint].self, from: data),
              Set(saved.map(\.sessionID)).count == saved.count,
              saved.allSatisfy({ $0.isValid(for: profileID, familyMode: familyMode) }) else { return .unsupported }
        return .loaded(saved)
    }
    var storageMessage: String? {
        guard checkpointState.isUnsupported || historyState.isUnsupported else { return nil }
        return "Your saved learning needs a compatible app version. It has been kept on this TV. Sum Sprint is paused; a grown-up can help."
    }
    func load(profileID: String, familyMode: Bool) -> SumSprintPartyTVCheckpoint? {
        guard profileID == self.profileID, familyMode == self.familyMode else { return nil }
        if case let .loaded(saved) = checkpointState { return saved }
        return nil
    }
    @discardableResult
    func save(_ checkpoint: SumSprintPartyTVCheckpoint) -> Bool {
        guard storageMessage == nil, checkpoint.isValid(for: profileID, familyMode: familyMode),
              let data = try? JSONEncoder().encode(checkpoint) else { return false }
        defaults.set(data, forKey: key)
        return true
    }
    @discardableResult
    func archive(_ checkpoint: SumSprintPartyTVCheckpoint) -> Bool {
        guard storageMessage == nil, checkpoint.isValid(for: profileID, familyMode: familyMode) else { return false }
        guard var history = history() else { return false }
        history.removeAll { $0.sessionID == checkpoint.sessionID }
        history.append(checkpoint)
        guard let data = try? JSONEncoder().encode(history) else { return false }
        defaults.set(data, forKey: key + ".history")
        return true
    }
    func history() -> [SumSprintPartyTVCheckpoint]? {
        switch historyState {
        case .missing: []
        case let .loaded(saved): saved
        case .unsupported: nil
        }
    }
    func clear() {
        defaults.removeObject(forKey: key)
        defaults.removeObject(forKey: key + ".history")
    }
}

@MainActor
@Observable
final class SumSprintPartyTVSession {
    private(set) var checkpoint: SumSprintPartyTVCheckpoint?
    private(set) var isSessionOpen = false
    private(set) var storageMessage: String?
    @ObservationIgnored private let profileID: String
    @ObservationIgnored private let familyMode: Bool
    @ObservationIgnored private let store: SumSprintPartyTVSessionStore
    @ObservationIgnored private let onAttempt: (ItemAttempt) -> Void
    @ObservationIgnored private let onResult: (ActivityResult) -> Void
    @ObservationIgnored private let now: () -> Date

    init(profileID: String = "tv-family", familyMode: Bool = true,
         store: SumSprintPartyTVSessionStore? = nil,
         onAttempt: @escaping (ItemAttempt) -> Void = { _ in },
         onResult: @escaping (ActivityResult) -> Void = { _ in }, now: @escaping () -> Date = Date.init) {
        self.profileID = familyMode ? "tv-family" : profileID
        self.familyMode = familyMode
        self.store = store ?? SumSprintPartyTVSessionStore(profileID: self.profileID, familyMode: familyMode)
        self.onAttempt = onAttempt; self.onResult = onResult; self.now = now
        checkpoint = self.store.load(profileID: self.profileID, familyMode: familyMode)
        storageMessage = self.store.storageMessage
    }

    var currentItem: SumSprintPartyTVItem? { checkpoint.map { $0.items[$0.currentIndex] } }
    var currentProgress: SumSprintPartyTVItemProgress? { checkpoint.map { $0.progress[$0.currentIndex] } }
    var canResume: Bool { storageMessage == nil && checkpoint != nil && checkpoint?.isComplete == false }
    var prompt: String {
        guard let item = currentItem, let progress = currentProgress else { return "Choose a number range with a grown-up. Five practice ideas and one new puzzle. Take your time." }
        if progress.outcome != nil { return "You joined the parts. \(item.round.fact.addendA) plus \(item.round.fact.addendB) is \(item.round.correctAnswer). Select Next to continue." }
        return "\(item.isProbe ? (item.isFreshProbe ? "A new puzzle. " : "A number-parts puzzle. ") : "")\(item.representation.spokenDescription). \(item.round.fact.spokenPrompt) \(scaffold) Swipe to an answer and press Select. Play Pause repeats this question."
    }
    var scaffold: String {
        guard let item = currentItem, let progress = currentProgress else { return "" }
        switch progress.support {
        case .none: return ""
        case .groups: return "The two parts stay the same. Count the first part, then keep counting the second part. Try another total."
        case .countOn: return "Start with \(item.round.fact.addendA). Count on \(item.round.fact.addendB) more. Choose Count one to light up the next counter."
        }
    }

    func start(range: SumSprintPartyTVRange, seed: UInt64 = UInt64.random(in: 0...UInt64.max)) {
        guard ensureWritableStorage() else { return }
        if let checkpoint, !store.archive(checkpoint) { _ = ensureWritableStorage(); return }
        guard let history = store.history() else { _ = ensureWritableStorage(); return }
        let seen = Set(history.flatMap(\.attempts).compactMap(\.itemVariantID))
        checkpoint = .make(range: range, profileID: profileID, familyMode: familyMode, seed: seed, startedAt: now(), previouslySeenVariants: seen)
        isSessionOpen = true
        exposeCurrentItem()
    }
    func resume() {
        guard ensureWritableStorage(), checkpoint != nil else { return }
        isSessionOpen = true
        replayEvidence()
        exposeCurrentItem()
    }
    func showRanges() { isSessionOpen = false }
    func replayEvidence() {
        guard ensureWritableStorage() else { return }
        checkpoint?.attempts.forEach(onAttempt)
        if let result = checkpoint?.result { onResult(result) }
    }
    func choose(_ answer: Int) {
        guard ensureWritableStorage(), isSessionOpen, let item = currentItem, currentProgress?.outcome == nil,
              item.round.answerChoices.contains(answer), let index = checkpoint?.currentIndex else { return }
        checkpoint?.progress[index].selectedAnswer = answer
        if answer == item.round.correctAnswer {
            let outcome: ItemAttemptOutcome = currentProgress?.usedHelp == true ? .supportedCorrect : .independentCorrect
            checkpoint?.progress[index].outcome = outcome
            record(outcome, response: "\(answer)")
        } else {
            checkpoint?.progress[index].missCount += 1
            record(.incorrect, response: "\(answer)")
            requestHelp()
        }
    }
    func requestHelp() {
        guard ensureWritableStorage(), isSessionOpen, currentProgress?.outcome == nil, let index = checkpoint?.currentIndex,
              let progress = currentProgress else { return }
        checkpoint?.progress[index].support = progress.support == .none ? .groups : .countOn
        record(.help, response: scaffold)
    }
    func countNext() {
        guard ensureWritableStorage(), isSessionOpen, let item = currentItem, let progress = currentProgress,
              progress.outcome == nil, progress.support == .countOn,
              progress.counted < item.round.fact.addendB, let index = checkpoint?.currentIndex else { return }
        checkpoint?.progress[index].counted += 1
        persist()
    }
    func advance() {
        guard ensureWritableStorage(), isSessionOpen, checkpoint?.isComplete == false, currentProgress?.outcome != nil,
              let index = checkpoint?.currentIndex else { return }
        if index == SumSprintPartyTVCheckpoint.itemCount - 1 {
            checkpoint?.completedAt = now()
            guard persist() else { return }
            if let checkpoint, store.archive(checkpoint), let result = checkpoint.result { onResult(result) }
        } else {
            checkpoint?.currentIndex += 1
            exposeCurrentItem()
        }
    }
    private func exposeCurrentItem() {
        guard let index = checkpoint?.currentIndex, checkpoint?.isComplete == false,
              currentProgress?.exposed == false else { return }
        checkpoint?.progress[index].exposed = true
        record(.exposure, response: nil)
    }
    private func record(_ outcome: ItemAttemptOutcome, response: String?) {
        guard let checkpoint, let item = currentItem else { return }
        let attempt = ItemAttempt(activityID: SumSprintPartyTVCheckpoint.activityID, conceptID: "number-parts",
            entityID: "addition.\(item.round.fact.id)", propertyID: "through-\(checkpoint.range.rawValue)",
            stageID: item.isProbe ? (item.isFreshProbe ? "fresh-probe" : "transfer") : "practice", outcome: outcome, response: response,
            occurredAt: now(), profileID: checkpoint.profileID, sessionID: checkpoint.sessionID,
            contentVersion: checkpoint.version, itemVariantID: item.variantID,
            appHintUsed: currentProgress.map { $0.support != .none || $0.counted > 0 } ?? false,
            isFreshProbe: item.isFreshProbe, adultHelp: .unknown)
        self.checkpoint?.attempts.append(attempt)
        guard persist() else { return } // Save the event identity before delivery.
        onAttempt(attempt)
    }
    @discardableResult
    private func persist() -> Bool {
        guard let checkpoint, store.save(checkpoint) else { _ = ensureWritableStorage(); return false }
        return true
    }
    private func ensureWritableStorage() -> Bool {
        storageMessage = store.storageMessage
        if storageMessage != nil { isSessionOpen = false; return false }
        return true
    }
}
