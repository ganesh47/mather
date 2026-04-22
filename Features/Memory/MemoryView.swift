import SwiftUI

// MARK: - Data model

enum MemoryPicture {
    case emoji(String)
    case asset(String)
}

struct MemoryAnimal: Identifiable {
    let id: String
    let name: String
    let canonicalName: String
    let picture: MemoryPicture

    init(id: String, name: String, canonicalName: String? = nil, picture: MemoryPicture) {
        self.id = id
        self.name = name
        self.canonicalName = canonicalName ?? name
        self.picture = picture
    }

    var selectionKey: String {
        id
    }

    var emoji: String? {
        guard case let .emoji(value) = picture else { return nil }
        return value
    }

    var imageAssetName: String? {
        guard case let .asset(value) = picture else { return nil }
        return value
    }
}

struct MemoryCard: Identifiable {
    enum Content {
        case picture(MemoryAnimal)
        case label(MemoryAnimal)
    }

    let id = UUID()
    let pairId: String
    let content: Content
    var isMatched: Bool = false
    var isSelected: Bool = false
}

struct MemoryArtStyle {
    let topColor: Color
    let bottomColor: Color
    let badgeColor: Color
    let badgeHighlight: Color
    let ornament: String
    let ornamentColor: Color
}

// MARK: - Decks

enum MemoryDeck {
    static let domesticAnimals: [MemoryAnimal] = [
        MemoryAnimal(id: "cow", name: "Cow", picture: .emoji("🐄")),
        MemoryAnimal(id: "dog", name: "Dog", picture: .emoji("🐕")),
        MemoryAnimal(id: "cat", name: "Cat", picture: .emoji("🐈")),
        MemoryAnimal(id: "sheep", name: "Sheep", picture: .emoji("🐑")),
        MemoryAnimal(id: "pig", name: "Pig", picture: .emoji("🐖")),
        MemoryAnimal(id: "horse", name: "Horse", picture: .emoji("🐎")),
        MemoryAnimal(id: "rabbit", name: "Rabbit", picture: .emoji("🐇")),
        MemoryAnimal(id: "duck", name: "Duck", picture: .emoji("🦆")),
        MemoryAnimal(id: "rooster", name: "Rooster", picture: .emoji("🐓")),
        MemoryAnimal(id: "goat", name: "Goat", picture: .emoji("🐐")),
        MemoryAnimal(id: "turkey", name: "Turkey", picture: .emoji("🦃")),
        MemoryAnimal(id: "goldfish", name: "Goldfish", picture: .emoji("🐟")),
        MemoryAnimal(id: "mouse", name: "Mouse", picture: .emoji("🐁")),
        MemoryAnimal(id: "frog", name: "Frog", picture: .emoji("🐸")),
        MemoryAnimal(id: "camel", name: "Camel", picture: .emoji("🐪")),
        MemoryAnimal(id: "llama", name: "Llama", picture: .emoji("🦙")),
        MemoryAnimal(id: "donkey", name: "Donkey", picture: .emoji("🫏")),
        MemoryAnimal(id: "ox", name: "Ox", picture: .emoji("🐂")),
    ]

    static let birds: [MemoryAnimal] = [
        bird("bird-a01", "Macaw 01", asset: "MemoryBirdA01"),
        bird("bird-a02", "Toucan 02", asset: "MemoryBirdA02"),
        bird("bird-a03", "Cockatoo 03", asset: "MemoryBirdA03"),
        bird("bird-a04", "Hummer 04", asset: "MemoryBirdA04"),
        bird("bird-a05", "Blue Macaw 05", asset: "MemoryBirdA05"),
        bird("bird-a06", "Kingfisher 06", asset: "MemoryBirdA06"),
        bird("bird-a07", "Hummer 07", asset: "MemoryBirdA07"),
        bird("bird-a08", "Kingfisher 08", asset: "MemoryBirdA08"),
        bird("bird-a09", "Toucan 09", asset: "MemoryBirdA09"),
        bird("bird-a10", "Parrot 10", asset: "MemoryBirdA10"),
        bird("bird-a11", "Palm Bird 11", asset: "MemoryBirdA11"),
        bird("bird-a12", "Flamingo 12", asset: "MemoryBirdA12"),
        bird("bird-a13", "Blue Bird 13", asset: "MemoryBirdA13"),
        bird("bird-a14", "Parrot 14", asset: "MemoryBirdA14"),
        bird("bird-a15", "Songbird 15", asset: "MemoryBirdA15"),
        bird("bird-a16", "Hoopoe 16", asset: "MemoryBirdA16"),
        bird("bird-a17", "Crested Bird 17", asset: "MemoryBirdA17"),
        bird("bird-a18", "Ibis 18", asset: "MemoryBirdA18"),
        bird("bird-b01", "Macaw 21", asset: "MemoryBirdB01"),
        bird("bird-b02", "Spoonbill 22", asset: "MemoryBirdB02"),
        bird("bird-b03", "Finch 23", asset: "MemoryBirdB03"),
        bird("bird-b04", "Crowned Bird 24", asset: "MemoryBirdB04"),
        bird("bird-b05", "Parrot 25", asset: "MemoryBirdB05"),
        bird("bird-b06", "Green Bird 26", asset: "MemoryBirdB06"),
        bird("bird-b07", "Cockatoo 27", asset: "MemoryBirdB07"),
        bird("bird-b08", "Parrotlet 28", asset: "MemoryBirdB08"),
        bird("bird-b09", "Golden Bird 29", asset: "MemoryBirdB09"),
        bird("bird-b10", "Turaco 30", asset: "MemoryBirdB10"),
        bird("bird-b11", "Peafowl 31", asset: "MemoryBirdB11"),
        bird("bird-b12", "Green Bird 32", asset: "MemoryBirdB12"),
        bird("bird-b13", "Ibis 33", asset: "MemoryBirdB13"),
        bird("bird-b14", "Pink Cockatoo 34", asset: "MemoryBirdB14"),
        bird("bird-b15", "Peafowl 35", asset: "MemoryBirdB15"),
        bird("bird-b16", "Puffin 36", asset: "MemoryBirdB16"),
        bird("bird-b17", "Black Palm 37", asset: "MemoryBirdB17"),
        bird("bird-b18", "Bee-eater 38", asset: "MemoryBirdB18"),
    ]

    static let vehicles: [MemoryAnimal] = [
        MemoryAnimal(id: "car", name: "Car", picture: .emoji("🚗")),
        MemoryAnimal(id: "bus", name: "Bus", picture: .emoji("🚌")),
        MemoryAnimal(id: "train", name: "Train", picture: .emoji("🚂")),
        MemoryAnimal(id: "plane", name: "Plane", picture: .emoji("✈️")),
        MemoryAnimal(id: "boat", name: "Boat", picture: .emoji("⛵")),
        MemoryAnimal(id: "bike", name: "Bike", picture: .emoji("🚲")),
        MemoryAnimal(id: "truck", name: "Truck", picture: .emoji("🚚")),
        MemoryAnimal(id: "tractor", name: "Tractor", picture: .emoji("🚜")),
        MemoryAnimal(id: "helicopter", name: "Copter", picture: .emoji("🚁")),
        MemoryAnimal(id: "rocket", name: "Rocket", picture: .emoji("🚀")),
        MemoryAnimal(id: "scooter", name: "Scooter", picture: .emoji("🛵")),
        MemoryAnimal(id: "taxi", name: "Taxi", picture: .emoji("🚕")),
    ]

    static let allAnimalsById: [String: MemoryAnimal] = {
        Dictionary(uniqueKeysWithValues: (domesticAnimals + birds + vehicles).map { ($0.id, $0) })
    }()

    private static func bird(_ id: String, _ name: String, asset: String) -> MemoryAnimal {
        MemoryAnimal(id: id, name: name, picture: .asset(asset))
    }
}

// MARK: - Game difficulty

enum MemoryDifficulty: CaseIterable {
    case easy
    case medium
    case hard

    var pairCount: Int {
        switch self {
        case .easy: return 3
        case .medium: return 4
        case .hard: return 6
        }
    }

    var faceDown: Bool { self == .hard }

    var label: String {
        switch self {
        case .easy: return "Easy"
        case .medium: return "Medium"
        case .hard: return "Flip!"
        }
    }

    var menuLabel: String {
        switch self {
        case .easy: return "Easy"
        case .medium: return "Medium"
        case .hard: return "Flip mode"
        }
    }

    var columns: Int {
        switch self {
        case .easy: return 3
        case .medium: return 4
        case .hard: return 4
        }
    }
}

struct MemoryView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Bindable var appModel: AppModel

    @State private var deck: [MemoryAnimal] = MemoryDeck.domesticAnimals
    @State private var difficulty: MemoryDifficulty = .easy
    @State private var cards: [MemoryCard] = []
    @State private var firstSelected: MemoryCard? = nil
    @State private var matchedPairs: Int = 0
    @State private var roundsPlayed: Int = 0
    @State private var mismatchIds: Set<UUID> = []
    @State private var isProcessingMismatch = false
    @State private var showRoundComplete = false
    @State private var deckSelection: DeckSelection = .domestic
    @State private var recentPairHistory: [String] = []

    enum DeckSelection: CaseIterable {
        case domestic, birds, vehicles

        var label: String {
            switch self {
            case .domestic: return "🐄 Animals"
            case .birds: return "🦜 Birds"
            case .vehicles: return "🚗 Vehicles"
            }
        }

        var menuLabel: String {
            switch self {
            case .domestic: return "Animals"
            case .birds: return "Birds"
            case .vehicles: return "Vehicles"
            }
        }

        var animals: [MemoryAnimal] {
            switch self {
            case .domestic: return MemoryDeck.domesticAnimals
            case .birds: return MemoryDeck.birds
            case .vehicles: return MemoryDeck.vehicles
            }
        }
    }

    private var totalPairs: Int { difficulty.pairCount }

    var body: some View {
        ZStack {
            MatherTheme.background.ignoresSafeArea()
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    header
                        .padding(.horizontal, 20)
                        .padding(.top, 16)
                        .padding(.bottom, 12)

                    cardGrid
                        .padding(.horizontal, 20)
                        .padding(.bottom, 20)
                }
            }

            if showRoundComplete { roundCompleteOverlay }
        }
        .onAppear { dealRound() }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top, spacing: 12) {
                Button {
                    appModel.engine.showLab()
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(MatherTheme.accent)
                        .frame(width: 44, height: 44)
                }
                .accessibilityLabel("Back")

                VStack(alignment: .leading, spacing: 2) {
                    Text("Memory Match")
                        .font(.title2.weight(.black))
                        .foregroundStyle(MatherTheme.ink)
                    Text("\(matchedPairs)/\(totalPairs) pairs matched")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(MatherTheme.cardSubtitle)
                }

                Spacer(minLength: 0)
            }

            CardSurface {
                VStack(alignment: .leading, spacing: 14) {
                    Text("Choose a deck and level")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(MatherTheme.cardSubtitle)

                    VStack(spacing: 10) {
                        Menu {
                            ForEach(DeckSelection.allCases, id: \.label) { selectedDeck in
                                Button(selectedDeck.label) {
                                    deckSelection = selectedDeck
                                    deck = selectedDeck.animals
                                    recentPairHistory = []
                                    dealRound()
                                }
                            }
                        } label: {
                            controlLabel(title: "Deck", value: deckSelection.menuLabel, tint: MatherTheme.accent)
                        }
                        .accessibilityIdentifier("memory-deck-menu")

                        Menu {
                            ForEach(MemoryDifficulty.allCases, id: \.label) { selectedDifficulty in
                                Button(selectedDifficulty.label) {
                                    difficulty = selectedDifficulty
                                    dealRound()
                                }
                            }
                        } label: {
                            controlLabel(title: "Difficulty", value: difficulty.menuLabel, tint: MatherTheme.warm)
                        }
                        .accessibilityIdentifier("memory-difficulty-menu")
                    }
                }
            }
        }
    }

    private func controlLabel(title: String, value: String, tint: Color) -> some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(MatherTheme.cardSubtitle)
                Text(value)
                    .font(.headline.weight(.bold))
                    .foregroundStyle(MatherTheme.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
            }

            Spacer(minLength: 12)

            Image(systemName: "chevron.up.chevron.down")
                .font(.caption.weight(.bold))
                .foregroundStyle(tint)
                .padding(10)
                .background(tint.opacity(colorScheme == .dark ? 0.24 : 0.12), in: Capsule())
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(MatherTheme.background.opacity(colorScheme == .dark ? 0.4 : 1), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .contentShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private var cardGrid: some View {
        let columns = Array(repeating: GridItem(.flexible(), spacing: 14), count: difficulty.columns)
        return LazyVGrid(columns: columns, spacing: 14) {
            ForEach(cards) { card in
                cardView(card)
                    .onTapGesture { handleTap(card) }
            }
        }
    }

    @ViewBuilder
    private func cardView(_ card: MemoryCard) -> some View {
        let isMismatch = mismatchIds.contains(card.id)
        let isFlipped = difficulty.faceDown && !card.isSelected && !card.isMatched

        ZStack {
            if isFlipped {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(LinearGradient(colors: [MatherTheme.accent.opacity(0.7), MatherTheme.softBlue.opacity(0.7)], startPoint: .topLeading, endPoint: .bottomTrailing))
                Text("?")
                    .font(.system(size: 40, weight: .black, design: .rounded))
                    .foregroundStyle(.white.opacity(0.6))
            } else {
                cardFace(card)
            }
        }
        .frame(height: cardHeight)
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(card.isSelected ? MatherTheme.accent : (card.isMatched ? Color.green : Color.clear), lineWidth: card.isSelected ? 3 : 2)
        )
        .scaleEffect(card.isMatched ? 0.92 : 1.0)
        .opacity(card.isMatched ? 0.45 : 1.0)
        .rotationEffect(isMismatch ? .degrees(-3) : .zero)
        .animation(.spring(response: 0.25, dampingFraction: 0.6), value: card.isSelected)
        .animation(.easeOut(duration: 0.3), value: card.isMatched)
        .animation(isMismatch ? .easeInOut(duration: 0.08).repeatCount(3, autoreverses: true) : .default, value: isMismatch)
    }

    @ViewBuilder
    private func cardFace(_ card: MemoryCard) -> some View {
        let animal = animal(for: card)
        let artStyle = Self.artStyle(for: animal.id)

        switch card.content {
        case .picture(let pictureAnimal):
            ZStack {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(LinearGradient(colors: card.isMatched ? [Color.green.opacity(0.24), Color.green.opacity(0.10)] : [artStyle.topColor, artStyle.bottomColor], startPoint: .topLeading, endPoint: .bottomTrailing))

                Circle()
                    .fill(Color.white.opacity(colorScheme == .dark ? 0.08 : 0.24))
                    .frame(width: cardHeight * 0.72, height: cardHeight * 0.72)
                    .offset(x: cardHeight * 0.16, y: -cardHeight * 0.18)

                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color.white.opacity(colorScheme == .dark ? 0.08 : 0.16))
                    .frame(width: cardHeight * 0.52, height: cardHeight * 0.16)
                    .offset(x: -cardHeight * 0.14, y: cardHeight * 0.24)
                    .rotationEffect(.degrees(-10))

                Image(systemName: artStyle.ornament)
                    .font(.system(size: difficulty == .hard ? 12 : 14, weight: .black))
                    .foregroundStyle(artStyle.ornamentColor.opacity(0.95))
                    .padding(8)
                    .background(Color.white.opacity(colorScheme == .dark ? 0.10 : 0.22), in: Circle())
                    .offset(x: -cardHeight * 0.28, y: -cardHeight * 0.26)

                Circle()
                    .fill(LinearGradient(colors: [artStyle.badgeHighlight, artStyle.badgeColor], startPoint: .top, endPoint: .bottom))
                    .frame(width: cardHeight * 0.62, height: cardHeight * 0.62)
                    .shadow(color: artStyle.badgeColor.opacity(0.25), radius: 10, y: 6)

                Circle()
                    .strokeBorder(Color.white.opacity(colorScheme == .dark ? 0.16 : 0.55), lineWidth: 3)
                    .frame(width: cardHeight * 0.62, height: cardHeight * 0.62)

                pictureView(for: pictureAnimal)
                    .frame(width: cardHeight * 0.64, height: cardHeight * 0.64)
            }

        case .label(let labelAnimal):
            ZStack {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(LinearGradient(colors: card.isMatched ? [Color.green.opacity(0.18), Color.green.opacity(0.08)] : [artStyle.topColor.opacity(0.30), artStyle.bottomColor.opacity(0.18)], startPoint: .topLeading, endPoint: .bottomTrailing))

                VStack(spacing: 8) {
                    HStack(spacing: 6) {
                        Image(systemName: artStyle.ornament)
                            .font(.caption.weight(.black))
                        Text("Match the picture")
                            .font(.caption2.weight(.bold))
                            .lineLimit(1)
                            .minimumScaleFactor(0.85)
                    }
                    .foregroundStyle(artStyle.ornamentColor)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 5)
                    .background(Color.white.opacity(colorScheme == .dark ? 0.08 : 0.45), in: Capsule())

                    Text(labelAnimal.name)
                        .font(.system(size: Self.labelFontSize(for: difficulty), weight: .black, design: .rounded))
                        .foregroundStyle(MatherTheme.ink)
                        .lineLimit(2)
                        .minimumScaleFactor(Self.labelMinimumScaleFactor(for: difficulty))
                        .allowsTightening(true)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.horizontal, Self.labelHorizontalPadding(for: difficulty))
                        .frame(maxWidth: .infinity, minHeight: cardHeight * 0.34)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 10)
            }
        }
    }

    @ViewBuilder
    private func pictureView(for animal: MemoryAnimal) -> some View {
        switch animal.picture {
        case .emoji(let emoji):
            Text(emoji)
                .font(.system(size: emojiSize))
                .shadow(color: .black.opacity(0.10), radius: 3, y: 2)
        case .asset(let assetName):
            Image(assetName)
                .resizable()
                .scaledToFit()
                .shadow(color: .black.opacity(0.08), radius: 3, y: 2)
                .padding(4)
        }
    }

    private func animal(for card: MemoryCard) -> MemoryAnimal {
        switch card.content {
        case .picture(let animal), .label(let animal): return animal
        }
    }

    static func labelFontSize(for difficulty: MemoryDifficulty) -> CGFloat {
        switch difficulty {
        case .easy: return 18
        case .medium: return 16
        case .hard: return 14
        }
    }

    static func labelMinimumScaleFactor(for difficulty: MemoryDifficulty) -> CGFloat {
        switch difficulty {
        case .easy: return 0.82
        case .medium: return 0.72
        case .hard: return 0.58
        }
    }

    static func labelHorizontalPadding(for difficulty: MemoryDifficulty) -> CGFloat {
        switch difficulty {
        case .easy: return 8
        case .medium: return 6
        case .hard: return 4
        }
    }

    static func artStyle(for pairId: String) -> MemoryArtStyle {
        if pairId.hasPrefix("bird-") {
            let birdStyles: [MemoryArtStyle] = [
                MemoryArtStyle(topColor: MatherTheme.warm.opacity(0.28), bottomColor: MatherTheme.coral.opacity(0.18), badgeColor: MatherTheme.warm, badgeHighlight: Color.white.opacity(0.95), ornament: "sun.max.fill", ornamentColor: MatherTheme.coral),
                MemoryArtStyle(topColor: MatherTheme.softBlue.opacity(0.30), bottomColor: MatherTheme.accent.opacity(0.18), badgeColor: MatherTheme.accent, badgeHighlight: Color.white.opacity(0.92), ornament: "drop.fill", ornamentColor: MatherTheme.softBlue),
                MemoryArtStyle(topColor: MatherTheme.accent.opacity(0.24), bottomColor: MatherTheme.warm.opacity(0.18), badgeColor: MatherTheme.accent, badgeHighlight: Color.white.opacity(0.92), ornament: "sparkles", ornamentColor: MatherTheme.warm),
                MemoryArtStyle(topColor: MatherTheme.panelDeep.opacity(0.24), bottomColor: MatherTheme.softBlue.opacity(0.16), badgeColor: MatherTheme.panelDeep, badgeHighlight: Color.white.opacity(0.84), ornament: "moon.stars.fill", ornamentColor: MatherTheme.softBlue),
                MemoryArtStyle(topColor: MatherTheme.coral.opacity(0.22), bottomColor: MatherTheme.warm.opacity(0.16), badgeColor: MatherTheme.coral, badgeHighlight: Color.white.opacity(0.92), ornament: "heart.fill", ornamentColor: MatherTheme.warm),
                MemoryArtStyle(topColor: MatherTheme.softBlue.opacity(0.24), bottomColor: MatherTheme.background.opacity(0.12), badgeColor: MatherTheme.softBlue, badgeHighlight: Color.white.opacity(0.96), ornament: "leaf.fill", ornamentColor: MatherTheme.accent),
                MemoryArtStyle(topColor: MatherTheme.warm.opacity(0.24), bottomColor: MatherTheme.panel.opacity(0.16), badgeColor: MatherTheme.panel, badgeHighlight: Color.white.opacity(0.92), ornament: "bird.fill", ornamentColor: MatherTheme.coral),
                MemoryArtStyle(topColor: MatherTheme.accent.opacity(0.22), bottomColor: MatherTheme.coral.opacity(0.14), badgeColor: MatherTheme.accent, badgeHighlight: Color.white.opacity(0.94), ornament: "rainbow", ornamentColor: MatherTheme.coral)
            ]
            let styleIndex = abs(pairId.hashValue) % birdStyles.count
            return birdStyles[styleIndex]
        }

        switch pairId {
        case "cow", "sheep", "rabbit", "llama", "goat":
            return MemoryArtStyle(topColor: MatherTheme.warm.opacity(0.30), bottomColor: MatherTheme.accent.opacity(0.22), badgeColor: MatherTheme.warm, badgeHighlight: Color.white.opacity(0.92), ornament: "sparkles", ornamentColor: MatherTheme.accent)
        case "dog", "cat", "mouse", "pig", "donkey":
            return MemoryArtStyle(topColor: MatherTheme.softBlue.opacity(0.28), bottomColor: MatherTheme.accent.opacity(0.16), badgeColor: MatherTheme.softBlue, badgeHighlight: Color.white.opacity(0.90), ornament: "heart.fill", ornamentColor: MatherTheme.coral)
        case "horse", "camel", "ox", "tractor", "truck":
            return MemoryArtStyle(topColor: MatherTheme.warm.opacity(0.22), bottomColor: MatherTheme.panelDeep.opacity(0.18), badgeColor: MatherTheme.panel, badgeHighlight: MatherTheme.warm.opacity(0.88), ornament: "sun.max.fill", ornamentColor: MatherTheme.warm)
        case "duck", "swan", "goose", "boat":
            return MemoryArtStyle(topColor: MatherTheme.softBlue.opacity(0.30), bottomColor: MatherTheme.background.opacity(0.10), badgeColor: MatherTheme.softBlue, badgeHighlight: Color.white.opacity(0.95), ornament: "drop.fill", ornamentColor: MatherTheme.accent)
        case "rooster", "turkey", "chicken", "babychick", "hatchedchick":
            return MemoryArtStyle(topColor: MatherTheme.coral.opacity(0.28), bottomColor: MatherTheme.warm.opacity(0.18), badgeColor: MatherTheme.coral, badgeHighlight: MatherTheme.warm.opacity(0.86), ornament: "star.fill", ornamentColor: MatherTheme.warm)
        case "goldfish", "frog":
            return MemoryArtStyle(topColor: MatherTheme.accent.opacity(0.24), bottomColor: MatherTheme.warm.opacity(0.18), badgeColor: MatherTheme.accent, badgeHighlight: MatherTheme.warm.opacity(0.88), ornament: "bubbles.and.sparkles.fill", ornamentColor: MatherTheme.softBlue)
        case "car", "bus", "taxi", "scooter", "bike":
            return MemoryArtStyle(topColor: MatherTheme.coral.opacity(0.24), bottomColor: MatherTheme.warm.opacity(0.16), badgeColor: MatherTheme.coral, badgeHighlight: Color.white.opacity(0.90), ornament: "road.lanes", ornamentColor: MatherTheme.panelDeep)
        case "train", "plane", "helicopter", "rocket":
            return MemoryArtStyle(topColor: MatherTheme.softBlue.opacity(0.28), bottomColor: MatherTheme.accent.opacity(0.18), badgeColor: MatherTheme.accent, badgeHighlight: Color.white.opacity(0.92), ornament: "wind", ornamentColor: MatherTheme.softBlue)
        default:
            return MemoryArtStyle(topColor: MatherTheme.panel.opacity(0.22), bottomColor: MatherTheme.softBlue.opacity(0.16), badgeColor: MatherTheme.panel, badgeHighlight: Color.white.opacity(0.90), ornament: "sparkles", ornamentColor: MatherTheme.accent)
        }
    }

    static func buildCards(for animals: [MemoryAnimal]) -> [MemoryCard] {
        animals.flatMap { animal in
            [
                MemoryCard(pairId: animal.id, content: .picture(animal)),
                MemoryCard(pairId: animal.id, content: .label(animal))
            ]
        }
    }

    private var cardHeight: CGFloat {
        switch difficulty {
        case .easy: return 140
        case .medium: return 130
        case .hard: return 110
        }
    }

    private var emojiSize: CGFloat {
        switch difficulty {
        case .easy: return 56
        case .medium: return 48
        case .hard: return 40
        }
    }

    private var roundCompleteOverlay: some View {
        ZStack {
            Color.black.opacity(0.35)
                .ignoresSafeArea()
                .onTapGesture { nextRound() }

            VStack(spacing: 20) {
                Text("🎉")
                    .font(.system(size: 72))
                Text("All matched!")
                    .font(.system(size: 36, weight: .black, design: .rounded))
                    .foregroundStyle(MatherTheme.ink)
                Text("Round \(roundsPlayed) complete")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(MatherTheme.cardSubtitle)

                Button("Next Round") {
                    nextRound()
                }
                .buttonStyle(PrimaryActionButtonStyle())
                .frame(maxWidth: 240)
            }
            .padding(36)
            .background(RoundedRectangle(cornerRadius: 24, style: .continuous).fill(MatherTheme.card).shadow(color: .black.opacity(0.18), radius: 24, y: 8))
        }
        .transition(.opacity.combined(with: .scale(scale: 0.95)))
    }

    static func preferredRoundAnimals(from deck: [MemoryAnimal], pairCount: Int, recentPairHistory: [String]) -> [MemoryAnimal] {
        let recentSet = Set(recentPairHistory)
        let freshPool = deck.filter { !recentSet.contains($0.id) }
        let primaryPool = freshPool.count >= pairCount ? freshPool : deck

        var chosen = Array(primaryPool.shuffled().prefix(pairCount))
        if chosen.count < pairCount {
            let chosenIds = Set(chosen.map(\.id))
            chosen.append(contentsOf: deck.filter { !chosenIds.contains($0.id) }.shuffled().prefix(pairCount - chosen.count))
        }
        return chosen
    }

    static func updatedRecentPairHistory(previous: [String], newRoundAnimals: [MemoryAnimal], pairCount: Int) -> [String] {
        let historyWindow = max(pairCount * 2, pairCount)
        return Array((previous + newRoundAnimals.map(\.id)).suffix(historyWindow))
    }

    private func dealRound() {
        let roundAnimals = Self.preferredRoundAnimals(from: deck, pairCount: totalPairs, recentPairHistory: recentPairHistory)
        recentPairHistory = Self.updatedRecentPairHistory(previous: recentPairHistory, newRoundAnimals: roundAnimals, pairCount: totalPairs)
        cards = Self.buildCards(for: roundAnimals).shuffled()
        firstSelected = nil
        matchedPairs = 0
        mismatchIds = []
        isProcessingMismatch = false
        showRoundComplete = false
    }

    private func handleTap(_ card: MemoryCard) {
        guard !card.isMatched, !isProcessingMismatch, !card.isSelected else { return }

        if let idx = cards.firstIndex(where: { $0.id == card.id }) {
            cards[idx].isSelected = true
        }
        appModel.hapticsService.counterSettle(enabled: appModel.featureFlags.hapticsEnabled)

        guard let first = firstSelected else {
            firstSelected = card
            return
        }

        firstSelected = nil

        if first.pairId == card.pairId {
            Task { @MainActor in
                try? await Task.sleep(for: .milliseconds(300))
                markMatched(pairId: card.pairId)
            }
        } else {
            isProcessingMismatch = true
            mismatchIds = [first.id, card.id]
            Task { @MainActor in
                try? await Task.sleep(for: .milliseconds(600))
                deselect(id: first.id)
                deselect(id: card.id)
                mismatchIds = []
                isProcessingMismatch = false
            }
        }
    }

    private func markMatched(pairId: String) {
        for idx in cards.indices where cards[idx].pairId == pairId {
            cards[idx].isMatched = true
            cards[idx].isSelected = false
        }
        matchedPairs += 1
        appModel.hapticsService.stageSuccess(enabled: appModel.featureFlags.hapticsEnabled)

        if matchedPairs == totalPairs {
            roundsPlayed += 1
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                showRoundComplete = true
            }
            appModel.speechService.speak("Amazing! All matched!", enabled: appModel.featureFlags.audioEnabled)
        }
    }

    private func deselect(id: UUID) {
        if let idx = cards.firstIndex(where: { $0.id == id }) {
            cards[idx].isSelected = false
        }
    }

    private func nextRound() {
        withAnimation(.easeOut(duration: 0.2)) {
            showRoundComplete = false
        }
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(250))
            dealRound()
        }
    }
}
