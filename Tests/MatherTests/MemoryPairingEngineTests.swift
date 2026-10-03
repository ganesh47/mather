import Foundation
import Testing
@testable import Mather

@MainActor
@Suite("Memory pairing engine")
struct MemoryPairingEngineTests {
    @Test func equivalentNumberBondAnswersMatchAcrossDifferentPairIDs() async throws {
        let engine = MemoryPairingEngine()
        let source = MemoryDeck.numberBondsTo10[0]
        let equivalent = MemoryAnimal(id: "equivalent-answer", name: source.name,
            canonicalName: source.canonicalName, picture: source.picture,
            metadata: source.metadata, learningArtwork: source.learningArtwork)
        engine.deal(animals: [source, equivalent], mode: .names, faceDown: false)
        let picture = try #require(engine.cards.first { !$0.isLabel })
        let answer = try #require(engine.cards.first { $0.isLabel && $0.pairID != picture.pairID })
        #expect(MemoryPairingEngine.cardsMatch(picture, answer))
        engine.select(picture.id)
        guard case .pair(_, _, let matches) = engine.select(answer.id) else {
            Issue.record("Expected a pair selection"); return
        }
        #expect(matches)
        try await Task.sleep(for: .milliseconds(450))
        #expect(engine.matchedPairs == 1)
        engine.hint()
        let hinted = engine.cards.filter { engine.hintIDs.contains($0.id) }
        try #require(hinted.count == 2)
        #expect(MemoryPairingEngine.cardsMatch(hinted[0], hinted[1]))
        engine.select(hinted[0].id)
        engine.select(hinted[1].id)
        try await Task.sleep(for: .milliseconds(450))
        #expect(engine.isComplete)
    }

    @Test func identicalAnswerLabelsCannotMatchEachOther() throws {
        let engine = MemoryPairingEngine()
        engine.deal(animals: Array(MemoryDeck.numberBondsTo10.prefix(2)), mode: .names, faceDown: true)
        let labels = engine.cards.filter(\.isLabel)
        #expect(labels.count == 2)
        #expect(!MemoryPairingEngine.cardsMatch(labels[0], labels[1]))
    }

    @Test func differentMissingPartAnswersDoNotMatchAcrossPairIDs() throws {
        let engine = MemoryPairingEngine()
        engine.deal(animals: Array(MemoryDeck.numberBondsTo10.prefix(2)), mode: .names, faceDown: false)
        let picture = try #require(engine.cards.first { !$0.isLabel })
        let otherAnswer = try #require(engine.cards.first { $0.isLabel && $0.pairID != picture.pairID })
        #expect(!MemoryPairingEngine.cardsMatch(picture, otherAnswer))
    }
    @Test func modesBuildDistinctCardsWithoutDuplicateIdentities() {
        let engine = MemoryPairingEngine()
        let animal = MemoryDeck.domesticAnimals[0]
        engine.deal(animals: [animal, animal], mode: .pictures, faceDown: true)
        #expect(engine.totalPairs == 1)
        #expect(engine.cards.count == 2)
        #expect(Set(engine.cards.map(\.id)).count == 2)
        #expect(engine.cards.allSatisfy { !$0.isLabel })
        #expect(engine.faceDown)
        engine.deal(animals: [animal], mode: .names, faceDown: false)
        #expect(engine.cards.filter(\.isLabel).count == 1)
        #expect(!engine.faceDown)
    }

    @Test func matchingDisablesRepeatSelectionAndCompletesSmallerPool() async throws {
        let engine = MemoryPairingEngine()
        // Flip mode can request six pairs, but Rescue Crew contains only five.
        engine.deal(animals: Array(MemoryAdventure.rescueCrew.cards.prefix(6)), mode: .pictures, faceDown: true)
        #expect(engine.totalPairs == 5)
        for pairID in MemoryAdventure.rescueCrew.cardIDs {
            let pair = engine.cards.filter { $0.pairID == pairID }
            engine.select(pair[0].id)
            engine.select(pair[0].id)
            #expect(engine.firstSelectedID == pair[0].id)
            engine.select(pair[1].id)
            #expect(engine.isProcessing)
            engine.select(pair[0].id)
            try await Task.sleep(for: .milliseconds(450))
            #expect(engine.cards.filter { $0.pairID == pairID }.allSatisfy { $0.isMatched && !$0.isSelected })
        }
        #expect(engine.matchedPairs == 5)
        #expect(engine.isComplete)
        engine.hint()
        #expect(engine.hintIDs.isEmpty)
    }

    @Test func mismatchKeepsRoundOpenAndClearsFeedback() async throws {
        let engine = MemoryPairingEngine()
        let animals = Array(MemoryDeck.domesticAnimals.prefix(2))
        engine.deal(animals: animals, mode: .names, faceDown: true)
        let first = engine.cards.first { $0.pairID == animals[0].id }!
        let second = engine.cards.first { $0.pairID == animals[1].id }!
        engine.select(first.id)
        engine.select(second.id)
        #expect(engine.mismatchIDs == [first.id, second.id])
        #expect(engine.isProcessing)
        try await Task.sleep(for: .milliseconds(900))
        #expect(!engine.isProcessing)
        #expect(engine.mismatchIDs.isEmpty)
        #expect(engine.cards.allSatisfy { !$0.isSelected && !$0.isMatched })
        #expect(engine.matchedPairs == 0)
        #expect(!engine.isComplete)
    }

    @Test func hintsPrioritizeSelectedPairAndDoNotAwardMatches() async throws {
        let engine = MemoryPairingEngine()
        engine.deal(animals: Array(MemoryDeck.domesticAnimals.prefix(3)), mode: .pictures, faceDown: true)
        let selected = engine.cards[0]
        engine.select(selected.id)
        engine.hint()
        let expected = Set(engine.cards.filter { $0.pairID == selected.pairID }.map(\.id))
        #expect(engine.hintIDs == expected)
        #expect(engine.matchedPairs == 0)
        try await Task.sleep(for: .milliseconds(1_650))
        #expect(engine.hintIDs.isEmpty)
        #expect(engine.firstSelectedID == selected.id)
        #expect(engine.matchedPairs == 0)
    }

    @Test func replacementRoundIgnoresOldMatchMismatchAndHintCallbacks() async throws {
        let engine = MemoryPairingEngine()
        let animals = Array(MemoryDeck.domesticAnimals.prefix(2))
        engine.deal(animals: animals, mode: .pictures, faceDown: false)
        let firstPair = engine.cards.filter { $0.pairID == animals[0].id }
        engine.select(firstPair[0].id)
        engine.select(firstPair[1].id)
        let previousRound = engine.roundID
        engine.deal(animals: animals, mode: .names, faceDown: true)
        #expect(engine.roundID != previousRound)
        engine.select(engine.cards.first { $0.pairID == animals[0].id }!.id)
        engine.select(engine.cards.first { $0.pairID == animals[1].id }!.id)
        engine.deal(animals: animals, mode: .pictures, faceDown: true)
        engine.hint()
        engine.deal(animals: [animals[1]], mode: .names, faceDown: false)
        let currentIDs = engine.cards.map(\.id)
        try await Task.sleep(for: .milliseconds(1_650))
        #expect(engine.cards.map(\.id) == currentIDs)
        #expect(engine.matchedPairs == 0)
        #expect(engine.cards.allSatisfy { !$0.isSelected && !$0.isMatched })
        #expect(engine.hintIDs.isEmpty)
        #expect(engine.mismatchIDs.isEmpty)
        #expect(!engine.isProcessing)
    }

    @Test func abandoningFeedbackAllowsReplayAndEmptyPoolCannotComplete() async throws {
        let engine = MemoryPairingEngine()
        engine.deal(animals: [MemoryDeck.domesticAnimals[0]], mode: .pictures, faceDown: true)
        engine.select(engine.cards[0].id)
        engine.select(engine.cards[1].id)
        engine.cancelPendingFeedback()
        try await Task.sleep(for: .milliseconds(450))
        #expect(!engine.isProcessing)
        #expect(engine.firstSelectedID == nil)
        #expect(engine.matchedPairs == 0)
        #expect(engine.cards.allSatisfy { !$0.isSelected })
        engine.deal(animals: [], mode: .pictures, faceDown: false)
        engine.select(UUID())
        engine.hint()
        #expect(engine.totalPairs == 0)
        #expect(!engine.isComplete)
        #expect(engine.hintIDs.isEmpty)
    }
}
