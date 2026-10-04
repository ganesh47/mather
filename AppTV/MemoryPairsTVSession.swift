import Foundation
import Observation

/// Transient TV presentation only. Pair identities, timing and counts belong to the shared engine.
@MainActor
@Observable
final class MemoryPairsTVSession {
    let engine = MemoryPairingEngine()
    private(set) var collectedIDs: Set<UUID> = []
    private(set) var successIDs: Set<UUID> = []
    private(set) var feedbackIDs: Set<UUID> = []
    private(set) var collectionRevision = 0
    private(set) var celebrationVisible = false
    private(set) var feedback = "Find two matching pictures."
    @ObservationIgnored private var presentationTask: Task<Void, Never>?
    @ObservationIgnored private var generation = UUID()

    var isFeedbackActive: Bool { engine.isProcessing || !feedbackIDs.isEmpty }
    var isComplete: Bool { engine.isComplete && engine.cards.allSatisfy { collectedIDs.contains($0.id) } }
    var remainingCards: [MemoryPairingEngine.Card] { engine.cards.filter { !collectedIDs.contains($0.id) } }
    var collectedAnimals: [MemoryAnimal] {
        var seen: Set<String> = []
        return engine.cards.filter { collectedIDs.contains($0.id) && seen.insert($0.pairID).inserted }.map(\.animal)
    }

    func begin(animals: [MemoryAnimal], hidden: Bool) {
        cancelTransientWork()
        collectedIDs = []
        successIDs = []
        feedbackIDs = []
        celebrationVisible = false
        feedback = "Find two matching pictures."
        engine.deal(animals: animals, mode: .pictures, faceDown: hidden)
        collectionRevision += 1
    }

    @discardableResult
    func select(_ id: UUID) -> MemoryPairingEngine.Selection {
        guard !isFeedbackActive else { return .ignored }
        let selection = engine.select(id)
        switch selection {
        case .ignored: break
        case .first(let card): feedback = "\(card.animal.canonicalName) selected. Find its pair."
        case .pair(let first, let second, let matches):
            feedbackIDs = [first.id, second.id]
            successIDs = matches ? feedbackIDs : []
            feedback = matches ? "A pair!" : "Different pictures. Keep looking."
        }
        return selection
    }

    /// Called only after the engine has resolved its 350ms/800ms feedback.
    func settleFeedback(reduceMotion: Bool) {
        guard !engine.isProcessing, !feedbackIDs.isEmpty else { return }
        guard !successIDs.isEmpty else {
            feedbackIDs = []
            feedback = "Try another pair."
            return
        }
        let ids = successIDs
        let token = generation
        presentationTask?.cancel()
        presentationTask = Task { @MainActor [weak self] in
            do {
                if !reduceMotion { try await Task.sleep(for: .milliseconds(300)) }
                guard let self, !Task.isCancelled, self.generation == token,
                      self.engine.cards.filter({ ids.contains($0.id) }).allSatisfy(\.isMatched) else { return }
                self.collectedIDs.formUnion(ids)
                self.successIDs = []
                self.feedbackIDs = []
                self.feedback = self.isComplete ? "Every pair found." : "A pair collected. Find another pair."
                self.collectionRevision += 1
                if self.isComplete && !reduceMotion {
                    self.celebrationVisible = true
                    try await Task.sleep(for: .milliseconds(900))
                    guard !Task.isCancelled, self.generation == token else { return }
                    self.celebrationVisible = false
                }
                self.presentationTask = nil
            } catch { }
        }
    }

    /// Keeps already awarded matches, while abandoning unresolved selections on departure.
    func cancelTransientWork() {
        generation = UUID()
        presentationTask?.cancel()
        presentationTask = nil
        engine.cancelPendingFeedback()
        let confirmed = Set(engine.cards.filter(\.isMatched).map(\.id))
        if !confirmed.isSubset(of: collectedIDs) {
            collectedIDs.formUnion(confirmed)
            collectionRevision += 1
        }
        successIDs = []
        feedbackIDs = []
        celebrationVisible = false
        feedback = isComplete ? "Every pair found." : "Find two matching pictures."
    }

    deinit { presentationTask?.cancel() }
}
