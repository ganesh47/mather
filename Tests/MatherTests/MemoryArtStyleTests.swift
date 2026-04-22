import Testing
@testable import Mather

@Suite("MemoryArtStyle")
struct MemoryArtStyleTests {

    @MainActor
    @Test func birdsDeckUsesMultipleArtTreatments() {
        let ornaments = Set(MemoryDeck.birds.map { MemoryView.artStyle(for: $0.id).ornament })
        #expect(ornaments.count >= 6)
    }

    @MainActor
    @Test func domesticDeckUsesMultipleArtTreatments() {
        let ornaments = Set(MemoryDeck.domesticAnimals.map { MemoryView.artStyle(for: $0.id).ornament })
        #expect(ornaments.count >= 4)
    }

    @MainActor
    @Test func representativePairsMapToStableArtThemes() {
        #expect(MemoryView.artStyle(for: "bird-a01").ornament == MemoryView.artStyle(for: "bird-a01").ornament)
        #expect(MemoryView.artStyle(for: "duck").ornament == "drop.fill")
        #expect(MemoryView.artStyle(for: "dog").ornament == "heart.fill")
        #expect(MemoryView.artStyle(for: "rocket").ornament == "wind")
    }
}
