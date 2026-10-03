import Foundation

/// Portable, declarative content for the existing gallery mechanics.
struct MemoryGalleryContentPack: Codable, Equatable {
    struct Deck: Codable, Equatable {
        let kind: MemoryDeckKind
        let cards: [MemoryAnimal]
    }

    struct Asset: Codable, Equatable, Sendable {
        let id: String
        let file: String
        let byteCount: Int
        let sha256: String
    }

    let schemaVersion: Int
    let contentVersion: Int
    let decks: [Deck]
    let assets: [Asset]

    enum ValidationError: Error { case invalidPack(String) }

    /// Schema-one catalogs shipped these 36 pictures as app-bundled artwork.
    /// Refreshing their cards does not remove the original image sets from the app.
    static var retainedLegacyBundledAssetNames: Set<String> {
        Set(["A", "B"].flatMap { sheet in
            (1...18).map { "MemoryBird" + sheet + String(format: "%02d", $0) }
        })
    }

    func validate() throws {
        try validate(requiredKinds: Set(MemoryGalleryTVCategory.allCases.map(\.deckKind)))
    }

    /// The iOS catalog is a separate feed; the public TV contract remains four decks.
    func validate(requiredKinds: Set<MemoryDeckKind>) throws {
        func require(_ condition: Bool, _ reason: String) throws {
            guard condition else { throw ValidationError.invalidPack(reason) }
        }
        func validText(_ text: String) -> Bool {
            !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && text.count <= 500
        }
        func validID(_ id: String) -> Bool {
            !id.isEmpty && id.count <= 100
                && id.unicodeScalars.allSatisfy { CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-_").contains($0) }
        }
        try require(schemaVersion == 1 && contentVersion > 0, "Unsupported schema or version")
        try require(decks.count == requiredKinds.count && Set(decks.map(\.kind)) == requiredKinds, "Expected every supported deck exactly once")
        try require(assets.count <= 200, "Too many assets")
        try require(Set(assets.map(\.id)).count == assets.count, "Duplicate asset IDs")
        try require(Set(assets.map(\.file)).count == assets.count, "Duplicate asset filenames")
        var totalBytes = 0
        for asset in assets {
            try require(validID(asset.id) && asset.file == "\(asset.id).png", "Invalid asset path")
            try require((1...10_000_000).contains(asset.byteCount), "Invalid asset size")
            try require(asset.sha256.count == 64 && asset.sha256.allSatisfy { "0123456789abcdef".contains($0) }, "Invalid SHA-256")
            totalBytes += asset.byteCount
        }
        try require(totalBytes <= 100_000_000, "Pack artwork exceeds 100 MB")
        let bundledAssets = Set(MemoryDeck.allDeckAnimals.compactMap(\.imageAssetName)
            + MemoryDeck.allDeckAnimals.flatMap(\.learningArtwork).map(\.assetName))
        let knownAssets = bundledAssets.union(assets.map(\.id)).union(Self.retainedLegacyBundledAssetNames)
        var cardIDs = Set<String>()
        for deck in decks {
            try require((4...250).contains(deck.cards.count), "Deck needs 4–250 cards")
            for card in deck.cards {
                try require(validID(card.id) && cardIDs.insert(card.id).inserted, "Invalid or duplicate card ID")
                try require(card.metadata.deck == deck.kind, "Card deck mismatch")
                try require([card.name, card.canonicalName, card.metadata.category, card.metadata.kind].allSatisfy(validText), "Invalid card text")
                try require((1...12).contains(card.detailCards.count), "Invalid fact count")
                try require(card.detailCards.allSatisfy { validText($0.title) && validText($0.value) }, "Invalid fact text")
                try require(card.learningArtwork.count <= 4, "Too much learning artwork")
                try require(card.learningArtwork.allSatisfy { validText($0.title) && knownAssets.contains($0.assetName) }, "Unknown learning artwork")
                switch card.picture {
                case .asset(let id): try require(knownAssets.contains(id), "Unknown picture asset")
                case .emoji(let text), .text(let text): try require(validText(text), "Empty picture")
                }
                if deck.kind == .countryFlags {
                    let titles = Set(card.detailCards.map { $0.title.lowercased() })
                    try require(titles.isSuperset(of: ["capital", "language", "currency", "monument"]), "Country clues missing")
                }
            }
        }
    }

    func cards(for category: MemoryGalleryTVCategory) -> [MemoryAnimal] {
        decks.first { $0.kind == category.deckKind }?.cards ?? category.deck
    }

    static var bundled: Self {
        Self(schemaVersion: 1, contentVersion: 3,
             decks: MemoryGalleryTVCategory.allCases.map { Deck(kind: $0.deckKind, cards: $0.deck) },
             assets: [])
    }
}
