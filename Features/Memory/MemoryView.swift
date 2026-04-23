import SwiftUI

// MARK: - Data model

enum MemoryPicture {
    case emoji(String)
    case asset(String)
}

struct MemoryFactCard: Equatable {
    let title: String
    let value: String
}

struct MemoryAnimal: Identifiable {
    let id: String
    let name: String
    let canonicalName: String
    let picture: MemoryPicture
    let detailCards: [MemoryFactCard]

    init(id: String, name: String, canonicalName: String? = nil, picture: MemoryPicture, detailCards: [MemoryFactCard] = []) {
        self.id = id
        self.name = name
        self.canonicalName = canonicalName ?? name
        self.picture = picture
        self.detailCards = detailCards
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
        case detail(MemoryAnimal, MemoryFactCard)
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
        bird("bird-a01", name: "Macaw", asset: "MemoryBirdA01", home: "South American rainforests", lifespan: "40 to 50 years", weight: "0.9 to 1.2 kg", size: "80 to 90 cm long", colors: "red, yellow, blue"),
        bird("bird-a02", name: "Toucan", asset: "MemoryBirdA02", home: "Central and South American forests", lifespan: "15 to 20 years", weight: "0.3 to 0.5 kg", size: "50 to 60 cm long", colors: "black, yellow, orange"),
        bird("bird-a03", name: "Cockatoo", asset: "MemoryBirdA03", home: "Australia and nearby islands", lifespan: "40 to 70 years", weight: "0.8 to 1.0 kg", size: "45 to 55 cm long", colors: "white and yellow"),
        bird("bird-a04", name: "Hummer", asset: "MemoryBirdA04", home: "Tropical Americas", lifespan: "3 to 5 years", weight: "3 to 6 g", size: "8 to 12 cm long", colors: "green, purple, teal"),
        bird("bird-a05", name: "Blue Macaw", asset: "MemoryBirdA05", home: "South American forests", lifespan: "35 to 50 years", weight: "1.0 to 1.4 kg", size: "85 to 100 cm long", colors: "blue and gold"),
        bird("bird-a06", name: "Kingfisher", asset: "MemoryBirdA06", home: "Asian and Oceanian waterways", lifespan: "6 to 10 years", weight: "30 to 45 g", size: "16 to 20 cm long", colors: "blue and orange"),
        bird("bird-a07", name: "Hummer", asset: "MemoryBirdA07", home: "South American cloud forests", lifespan: "3 to 5 years", weight: "4 to 7 g", size: "10 to 14 cm long", colors: "gold, orange, brown"),
        bird("bird-a08", name: "Kingfisher", asset: "MemoryBirdA08", home: "Woodland streams in Africa and Asia", lifespan: "5 to 10 years", weight: "35 to 50 g", size: "18 to 22 cm long", colors: "blue, white, black"),
        bird("bird-a09", name: "Toucan", asset: "MemoryBirdA09", home: "Tropical South America", lifespan: "15 to 20 years", weight: "0.5 to 0.7 kg", size: "55 to 65 cm long", colors: "black, white, orange"),
        bird("bird-a10", name: "Parrot", asset: "MemoryBirdA10", home: "Tropical forests", lifespan: "20 to 30 years", weight: "0.2 to 0.4 kg", size: "25 to 35 cm long", colors: "green, yellow, red"),
        bird("bird-a11", name: "Palm Bird", asset: "MemoryBirdA11", home: "New Guinea and northern Australia", lifespan: "40 to 60 years", weight: "0.9 to 1.2 kg", size: "55 to 65 cm long", colors: "charcoal and red"),
        bird("bird-a12", name: "Flamingo", asset: "MemoryBirdA12", home: "Warm lakes and lagoons", lifespan: "20 to 30 years", weight: "2 to 3 kg", size: "100 to 140 cm tall", colors: "pink and coral"),
        bird("bird-a13", name: "Blue Bird", asset: "MemoryBirdA13", home: "Forest edges in tropical America", lifespan: "10 to 15 years", weight: "0.2 to 0.3 kg", size: "25 to 35 cm long", colors: "blue and gold"),
        bird("bird-a14", name: "Parrot", asset: "MemoryBirdA14", home: "Oceania rainforests", lifespan: "20 to 35 years", weight: "0.2 to 0.4 kg", size: "30 to 35 cm long", colors: "green and red"),
        bird("bird-a15", name: "Songbird", asset: "MemoryBirdA15", home: "Tropical gardens and forests", lifespan: "6 to 10 years", weight: "25 to 40 g", size: "15 to 18 cm long", colors: "green and yellow"),
        bird("bird-a16", name: "Hoopoe", asset: "MemoryBirdA16", home: "Africa, Europe, and Asia", lifespan: "8 to 10 years", weight: "45 to 90 g", size: "25 to 32 cm long", colors: "cinnamon, black, white"),
        bird("bird-a17", name: "Crested Bird", asset: "MemoryBirdA17", home: "Island forests", lifespan: "10 to 15 years", weight: "0.2 to 0.4 kg", size: "25 to 35 cm long", colors: "white, blue, silver"),
        bird("bird-a18", name: "Ibis", asset: "MemoryBirdA18", home: "South American wetlands", lifespan: "15 to 20 years", weight: "0.8 to 1.2 kg", size: "55 to 65 cm long", colors: "scarlet red"),
        bird("bird-b01", name: "Macaw", asset: "MemoryBirdB01", home: "South American rainforests", lifespan: "35 to 50 years", weight: "0.9 to 1.3 kg", size: "75 to 90 cm long", colors: "blue and gold"),
        bird("bird-b02", name: "Spoonbill", asset: "MemoryBirdB02", home: "American marshes and coasts", lifespan: "10 to 15 years", weight: "1.2 to 1.8 kg", size: "70 to 85 cm long", colors: "pink and white"),
        bird("bird-b03", name: "Finch", asset: "MemoryBirdB03", home: "Northern Australia", lifespan: "4 to 8 years", weight: "12 to 16 g", size: "12 to 14 cm long", colors: "green, yellow, purple"),
        bird("bird-b04", name: "Crowned Bird", asset: "MemoryBirdB04", home: "New Guinea forests", lifespan: "15 to 25 years", weight: "2.0 to 2.5 kg", size: "65 to 75 cm tall", colors: "blue and maroon"),
        bird("bird-b05", name: "Parrot", asset: "MemoryBirdB05", home: "South American forests", lifespan: "25 to 35 years", weight: "0.3 to 0.5 kg", size: "30 to 40 cm long", colors: "red and green"),
        bird("bird-b06", name: "Green Bird", asset: "MemoryBirdB06", home: "African forest canopies", lifespan: "8 to 12 years", weight: "0.2 to 0.4 kg", size: "30 to 40 cm long", colors: "emerald green"),
        bird("bird-b07", name: "Cockatoo", asset: "MemoryBirdB07", home: "Australia", lifespan: "30 to 50 years", weight: "0.5 to 0.8 kg", size: "40 to 50 cm long", colors: "white and yellow"),
        bird("bird-b08", name: "Parrotlet", asset: "MemoryBirdB08", home: "Dry forests of the Americas", lifespan: "8 to 12 years", weight: "25 to 35 g", size: "12 to 15 cm long", colors: "green and blue"),
        bird("bird-b09", name: "Golden Bird", asset: "MemoryBirdB09", home: "Asian mountain forests", lifespan: "6 to 10 years", weight: "0.6 to 0.8 kg", size: "90 to 110 cm long", colors: "gold, red, green"),
        bird("bird-b10", name: "Turaco", asset: "MemoryBirdB10", home: "African forests", lifespan: "10 to 15 years", weight: "0.2 to 0.4 kg", size: "35 to 45 cm long", colors: "green and crimson"),
        bird("bird-b11", name: "Peafowl", asset: "MemoryBirdB11", home: "India and Sri Lanka", lifespan: "15 to 20 years", weight: "4 to 6 kg", size: "90 to 115 cm body length", colors: "blue and emerald"),
        bird("bird-b12", name: "Green Bird", asset: "MemoryBirdB12", home: "Woodland edges", lifespan: "8 to 12 years", weight: "0.2 to 0.3 kg", size: "25 to 35 cm long", colors: "green and yellow"),
        bird("bird-b13", name: "Ibis", asset: "MemoryBirdB13", home: "Tropical wetlands", lifespan: "15 to 20 years", weight: "0.8 to 1.2 kg", size: "55 to 65 cm long", colors: "red and coral"),
        bird("bird-b14", name: "Pink Cockatoo", asset: "MemoryBirdB14", home: "Inland Australia", lifespan: "40 to 60 years", weight: "0.3 to 0.4 kg", size: "35 to 40 cm long", colors: "pink and white"),
        bird("bird-b15", name: "Peafowl", asset: "MemoryBirdB15", home: "Asian grasslands and gardens", lifespan: "15 to 20 years", weight: "3 to 5 kg", size: "85 to 100 cm body length", colors: "blue, green, bronze"),
        bird("bird-b16", name: "Puffin", asset: "MemoryBirdB16", home: "North Atlantic coasts", lifespan: "20 to 25 years", weight: "0.3 to 0.5 kg", size: "28 to 34 cm long", colors: "black, white, orange"),
        bird("bird-b17", name: "Black Palm", asset: "MemoryBirdB17", home: "New Guinea and Australia", lifespan: "40 to 60 years", weight: "0.8 to 1.1 kg", size: "55 to 65 cm long", colors: "charcoal and red"),
        bird("bird-b18", name: "Bee-eater", asset: "MemoryBirdB18", home: "Africa and South Asia", lifespan: "5 to 8 years", weight: "20 to 35 g", size: "20 to 25 cm long", colors: "green, blue, gold"),
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

    private static func bird(_ id: String, name: String, asset: String, home: String, lifespan: String, weight: String, size: String, colors: String) -> MemoryAnimal {
        MemoryAnimal(
            id: id,
            name: name,
            picture: .asset(asset),
            detailCards: [
                MemoryFactCard(title: "Name", value: name),
                MemoryFactCard(title: "Home", value: home),
                MemoryFactCard(title: "Lifespan", value: lifespan),
                MemoryFactCard(title: "Weight", value: weight),
                MemoryFactCard(title: "Size", value: size),
                MemoryFactCard(title: "Colors", value: colors)
            ]
        )
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

        case .detail(_, let factCard):
            ZStack {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(LinearGradient(colors: card.isMatched ? [Color.green.opacity(0.18), Color.green.opacity(0.08)] : [artStyle.topColor.opacity(0.30), artStyle.bottomColor.opacity(0.18)], startPoint: .topLeading, endPoint: .bottomTrailing))

                VStack(spacing: 8) {
                    HStack(spacing: 6) {
                        Image(systemName: artStyle.ornament)
                            .font(.caption.weight(.black))
                        Text("Clue card")
                            .font(.caption2.weight(.bold))
                            .lineLimit(1)
                            .minimumScaleFactor(0.85)
                    }
                    .foregroundStyle(artStyle.ornamentColor)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 5)
                    .background(Color.white.opacity(colorScheme == .dark ? 0.08 : 0.45), in: Capsule())

                    Text(factCard.title)
                        .font(.caption.weight(.bold))
                        .foregroundStyle(artStyle.ornamentColor)
                        .textCase(.uppercase)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)

                    Text(factCard.value)
                        .font(.system(size: Self.detailFontSize(for: difficulty), weight: .black, design: .rounded))
                        .foregroundStyle(MatherTheme.ink)
                        .lineLimit(3)
                        .minimumScaleFactor(Self.detailMinimumScaleFactor(for: difficulty))
                        .allowsTightening(true)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.horizontal, Self.labelHorizontalPadding(for: difficulty))
                        .frame(maxWidth: .infinity, minHeight: cardHeight * 0.40)
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
        case .picture(let animal), .detail(let animal, _): return animal
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

    static func detailFontSize(for difficulty: MemoryDifficulty) -> CGFloat {
        switch difficulty {
        case .easy: return 15
        case .medium: return 14
        case .hard: return 12
        }
    }

    static func detailMinimumScaleFactor(for difficulty: MemoryDifficulty) -> CGFloat {
        switch difficulty {
        case .easy: return 0.76
        case .medium: return 0.70
        case .hard: return 0.62
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
                MemoryCard(pairId: animal.id, content: .detail(animal, preferredFactCard(for: animal)))
            ]
        }
    }

    static func preferredFactCard(for animal: MemoryAnimal) -> MemoryFactCard {
        animal.detailCards.randomElement() ?? MemoryFactCard(title: "Name", value: animal.name)
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
