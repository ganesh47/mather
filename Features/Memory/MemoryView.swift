import SwiftUI

// MARK: - Data model

struct MemoryAnimal: Identifiable {
    let id: String
    let emoji: String
    let name: String
}

struct MemoryCard: Identifiable {
    enum Content {
        case picture(emoji: String)
        case label(name: String)
    }

    let id = UUID()
    let pairId: String        // matches the MemoryAnimal.id
    let content: Content
    var isMatched: Bool = false
    var isSelected: Bool = false
}

// MARK: - Decks

enum MemoryDeck {
    static let domesticAnimals: [MemoryAnimal] = [
        MemoryAnimal(id: "cow",      emoji: "🐄", name: "Cow"),
        MemoryAnimal(id: "dog",      emoji: "🐕", name: "Dog"),
        MemoryAnimal(id: "cat",      emoji: "🐈", name: "Cat"),
        MemoryAnimal(id: "sheep",    emoji: "🐑", name: "Sheep"),
        MemoryAnimal(id: "pig",      emoji: "🐖", name: "Pig"),
        MemoryAnimal(id: "horse",    emoji: "🐎", name: "Horse"),
        MemoryAnimal(id: "rabbit",   emoji: "🐇", name: "Rabbit"),
        MemoryAnimal(id: "duck",     emoji: "🦆", name: "Duck"),
        MemoryAnimal(id: "rooster",  emoji: "🐓", name: "Rooster"),
        MemoryAnimal(id: "goat",     emoji: "🐐", name: "Goat"),
        MemoryAnimal(id: "turkey",   emoji: "🦃", name: "Turkey"),
        MemoryAnimal(id: "goldfish", emoji: "🐟", name: "Goldfish"),
    ]

    static let birds: [MemoryAnimal] = [
        MemoryAnimal(id: "parrot",    emoji: "🦜", name: "Parrot"),
        MemoryAnimal(id: "flamingo",  emoji: "🦩", name: "Flamingo"),
        MemoryAnimal(id: "peacock",   emoji: "🦚", name: "Peacock"),
        MemoryAnimal(id: "eagle",     emoji: "🦅", name: "Eagle"),
        MemoryAnimal(id: "owl",       emoji: "🦉", name: "Owl"),
        MemoryAnimal(id: "penguin",   emoji: "🐧", name: "Penguin"),
        MemoryAnimal(id: "swan",      emoji: "🦢", name: "Swan"),
        MemoryAnimal(id: "duck",      emoji: "🦆", name: "Duck"),
        MemoryAnimal(id: "rooster",   emoji: "🐓", name: "Rooster"),
        MemoryAnimal(id: "turkey",    emoji: "🦃", name: "Turkey"),
        MemoryAnimal(id: "dove",      emoji: "🕊️", name: "Dove"),
        MemoryAnimal(id: "blackbird", emoji: "🐦⬛", name: "Blackbird"),
    ]

    static let vehicles: [MemoryAnimal] = [
        MemoryAnimal(id: "car",        emoji: "🚗", name: "Car"),
        MemoryAnimal(id: "bus",        emoji: "🚌", name: "Bus"),
        MemoryAnimal(id: "train",      emoji: "🚂", name: "Train"),
        MemoryAnimal(id: "plane",      emoji: "✈️", name: "Plane"),
        MemoryAnimal(id: "boat",       emoji: "⛵", name: "Boat"),
        MemoryAnimal(id: "bike",       emoji: "🚲", name: "Bike"),
        MemoryAnimal(id: "truck",      emoji: "🚚", name: "Truck"),
        MemoryAnimal(id: "tractor",    emoji: "🚜", name: "Tractor"),
        MemoryAnimal(id: "helicopter", emoji: "🚁", name: "Copter"),
        MemoryAnimal(id: "rocket",     emoji: "🚀", name: "Rocket"),
        MemoryAnimal(id: "scooter",    emoji: "🛵", name: "Scooter"),
        MemoryAnimal(id: "taxi",       emoji: "🚕", name: "Taxi"),
    ]
}

// MARK: - Game difficulty

enum MemoryDifficulty: CaseIterable {
    case easy    // 3 pairs, all face-up
    case medium  // 4 pairs, all face-up
    case hard    // 6 pairs, face-down (flip to reveal)

    var pairCount: Int {
        switch self {
        case .easy:   return 3
        case .medium: return 4
        case .hard:   return 6
        }
    }

    var faceDown: Bool { self == .hard }

    var label: String {
        switch self {
        case .easy:   return "Easy"
        case .medium: return "Medium"
        case .hard:   return "Flip!"
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
        case .easy:   return 3    // 3×2
        case .medium: return 4    // 4×2
        case .hard:   return 4    // 4×3
        }
    }
}

// MARK: - Main view

struct MemoryView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Bindable var appModel: AppModel

    // MARK: Game state
    @State private var deck: [MemoryAnimal] = MemoryDeck.domesticAnimals
    @State private var difficulty: MemoryDifficulty = .easy
    @State private var cards: [MemoryCard] = []
    @State private var firstSelected: MemoryCard? = nil
    @State private var matchedPairs: Int = 0
    @State private var roundsPlayed: Int = 0
    @State private var mismatchIds: Set<UUID> = []
    @State private var isProcessingMismatch: Bool = false
    @State private var showRoundComplete: Bool = false
    @State private var deckSelection: DeckSelection = .domestic

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

    // MARK: Body

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

            if showRoundComplete {
                roundCompleteOverlay
            }
        }
        .onAppear { dealRound() }
    }

    // MARK: - Header

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

    // MARK: - Card grid

    private var cardGrid: some View {
        let columns = Array(
            repeating: GridItem(.flexible(), spacing: 14),
            count: difficulty.columns
        )
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
                // Back of card (face-down mode)
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [MatherTheme.accent.opacity(0.7), MatherTheme.softBlue.opacity(0.7)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
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
                .strokeBorder(
                    card.isSelected ? MatherTheme.accent : (card.isMatched ? Color.green : Color.clear),
                    lineWidth: card.isSelected ? 3 : 2
                )
        )
        .scaleEffect(card.isMatched ? 0.92 : 1.0)
        .opacity(card.isMatched ? 0.45 : 1.0)
        .rotationEffect(isMismatch ? .degrees(-3) : .zero)
        .animation(.spring(response: 0.25, dampingFraction: 0.6), value: card.isSelected)
        .animation(.easeOut(duration: 0.3), value: card.isMatched)
        .animation(
            isMismatch ? .easeInOut(duration: 0.08).repeatCount(3, autoreverses: true) : .default,
            value: isMismatch
        )
    }

    @ViewBuilder
    private func cardFace(_ card: MemoryCard) -> some View {
        switch card.content {
        case .picture(let emoji):
            ZStack {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(card.isMatched ? Color.green.opacity(0.15) : MatherTheme.warm.opacity(0.18))
                Text(emoji)
                    .font(.system(size: emojiSize))
            }

        case .label(let name):
            ZStack {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(card.isMatched ? Color.green.opacity(0.15) : MatherTheme.softBlue.opacity(0.18))
                Text(name)
                    .font(.system(size: Self.labelFontSize(for: difficulty), weight: .black, design: .rounded))
                    .foregroundStyle(MatherTheme.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(Self.labelMinimumScaleFactor(for: difficulty))
                    .allowsTightening(true)
                    .truncationMode(.tail)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Self.labelHorizontalPadding(for: difficulty))
                    .padding(.vertical, 8)
                    .frame(maxWidth: .infinity)
            }
        }
    }

    static func labelFontSize(for difficulty: MemoryDifficulty) -> CGFloat {
        switch difficulty {
        case .easy: return 22
        case .medium: return 20
        case .hard: return 18
        }
    }

    static func labelMinimumScaleFactor(for difficulty: MemoryDifficulty) -> CGFloat {
        switch difficulty {
        case .easy: return 0.82
        case .medium: return 0.76
        case .hard: return 0.68
        }
    }

    static func labelHorizontalPadding(for difficulty: MemoryDifficulty) -> CGFloat {
        switch difficulty {
        case .easy: return 10
        case .medium: return 8
        case .hard: return 6
        }
    }

    private var cardHeight: CGFloat {
        switch difficulty {
        case .easy:   return 140
        case .medium: return 130
        case .hard:   return 110
        }
    }

    private var emojiSize: CGFloat {
        switch difficulty {
        case .easy:   return 56
        case .medium: return 48
        case .hard:   return 40
        }
    }

    // MARK: - Round complete overlay

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
            .background(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(MatherTheme.card)
                    .shadow(color: .black.opacity(0.18), radius: 24, y: 8)
            )
        }
        .transition(.opacity.combined(with: .scale(scale: 0.95)))
    }

    // MARK: - Game logic

    private func dealRound() {
        let shuffled = deck.shuffled().prefix(totalPairs)
        var newCards: [MemoryCard] = []
        for animal in shuffled {
            newCards.append(MemoryCard(pairId: animal.id, content: .picture(emoji: animal.emoji)))
            newCards.append(MemoryCard(pairId: animal.id, content: .label(name: animal.name)))
        }
        cards = newCards.shuffled()
        firstSelected = nil
        matchedPairs = 0
        mismatchIds = []
        isProcessingMismatch = false
        showRoundComplete = false
    }

    private func handleTap(_ card: MemoryCard) {
        guard !card.isMatched, !isProcessingMismatch else { return }
        guard !card.isSelected else { return }

        // Update selection state
        if let idx = cards.firstIndex(where: { $0.id == card.id }) {
            cards[idx].isSelected = true
        }
        appModel.hapticsService.counterSettle(enabled: appModel.featureFlags.hapticsEnabled)

        guard let first = firstSelected else {
            // First card of a pair
            firstSelected = card
            return
        }

        // Second card selected — evaluate
        firstSelected = nil

        if first.pairId == card.pairId {
            // Match!
            Task { @MainActor in
                try? await Task.sleep(for: .milliseconds(300))
                markMatched(pairId: card.pairId)
            }
        } else {
            // Mismatch — shake then deselect
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
            appModel.speechService.speak(
                "Amazing! All matched!",
                enabled: appModel.featureFlags.audioEnabled
            )
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
