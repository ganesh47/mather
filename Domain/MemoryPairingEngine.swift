import Foundation
import Observation

@MainActor
@Observable
final class MemoryPairingEngine {
    enum Mode: String, CaseIterable, Identifiable {
        case pictures, names
        var id: String { rawValue }
    }

    struct Card: Identifiable {
        let id: UUID
        let pairID: String
        let animal: MemoryAnimal
        let isLabel: Bool
        var isMatched = false
        var isSelected = false
    }

    enum Selection {
        case ignored
        case first(Card)
        case pair(first: Card, second: Card, matches: Bool)
    }

    private(set) var cards: [Card] = []
    private(set) var matchedPairs = 0
    private(set) var firstSelectedID: UUID?
    private(set) var mismatchIDs: Set<UUID> = []
    private(set) var isProcessing = false
    private(set) var hintIDs: Set<UUID> = []
    private(set) var roundID = UUID()
    private(set) var faceDown = false

    var totalPairs: Int { cards.count / 2 }
    var isComplete: Bool { totalPairs > 0 && matchedPairs == totalPairs }

    @ObservationIgnored private var feedbackTask: Task<Void, Never>?
    @ObservationIgnored private var hintTask: Task<Void, Never>?

    func deal(animals: [MemoryAnimal], mode: Mode, faceDown: Bool) {
        cancelPendingFeedback()
        self.faceDown = faceDown
        matchedPairs = 0
        var seen: Set<String> = []
        cards = animals.filter { seen.insert($0.id).inserted }.flatMap { animal in
            [
                Card(id: UUID(), pairID: animal.id, animal: animal, isLabel: false),
                Card(id: UUID(), pairID: animal.id, animal: animal, isLabel: mode == .names)
            ]
        }.shuffled()
    }

    @discardableResult
    func select(_ id: UUID) -> Selection {
        guard !isProcessing, !isComplete,
              let index = cards.firstIndex(where: { $0.id == id }),
              !cards[index].isMatched, !cards[index].isSelected else { return .ignored }
        clearHint()
        cards[index].isSelected = true
        guard let firstID = firstSelectedID,
              let firstIndex = cards.firstIndex(where: { $0.id == firstID }) else {
            firstSelectedID = id
            return .first(cards[index])
        }
        firstSelectedID = nil
        isProcessing = true
        let first = cards[firstIndex]
        let second = cards[index]
        let matching = Self.cardsMatch(first, second)
        let selection: Set<UUID> = [firstID, id]
        if !matching { mismatchIDs = selection }
        let generation = roundID
        feedbackTask = Task { @MainActor [weak self] in
            do { try await Task.sleep(for: matching ? .milliseconds(350) : .milliseconds(800)) }
            catch { return }
            guard let self, self.roundID == generation else { return }
            for index in self.cards.indices where selection.contains(self.cards[index].id) {
                self.cards[index].isSelected = false
                if matching { self.cards[index].isMatched = true }
            }
            if matching { self.matchedPairs += 1 }
            self.mismatchIDs = []
            self.isProcessing = false
            self.feedbackTask = nil
        }
        return .pair(first: first, second: second, matches: matching)
    }

    /// Picture pairs use identity. Name matching accepts equivalent visible
    /// answers while keeping the distinct missing-part number answers separate.
    static func cardsMatch(_ first: Card, _ second: Card) -> Bool {
        if !first.isLabel && !second.isLabel { return first.pairID == second.pairID }
        guard first.isLabel != second.isLabel else { return false }
        return first.animal.name.trimmingCharacters(in: .whitespacesAndNewlines)
            .localizedCaseInsensitiveCompare(second.animal.name.trimmingCharacters(in: .whitespacesAndNewlines)) == .orderedSame
    }

    func hint() {
        guard !isProcessing, !isComplete else { return }
        clearHint()
        let first = firstSelectedID.flatMap { id in cards.first { $0.id == id } }
            ?? cards.first { !$0.isMatched }
        guard let first else { return }
        let counterpart = cards.first { $0.id != first.id && !$0.isMatched && Self.cardsMatch(first, $0) }
        hintIDs = Set(([first] + (counterpart.map { [$0] } ?? [])).map(\.id))
        let generation = roundID
        hintTask = Task { @MainActor [weak self] in
            do { try await Task.sleep(for: .milliseconds(1_500)) }
            catch { return }
            guard let self, self.roundID == generation else { return }
            self.hintIDs = []
            self.hintTask = nil
        }
    }

    func cancelPendingFeedback() {
        feedbackTask?.cancel()
        feedbackTask = nil
        clearHint()
        roundID = UUID()
        firstSelectedID = nil
        mismatchIDs = []
        isProcessing = false
        for index in cards.indices { cards[index].isSelected = false }
    }

    private func clearHint() {
        hintTask?.cancel()
        hintTask = nil
        hintIDs = []
    }
}
