import SwiftUI

// MARK: - Game card state

struct MemoryCard: Identifiable {
    enum Content {
        case picture(MemoryAnimal)
        case label(MemoryAnimal)
    }

    let id: UUID

    init(id: UUID = UUID(), pairId: String, content: Content, isMatched: Bool = false, isSelected: Bool = false) {
        self.id = id
        self.pairId = pairId
        self.content = content
        self.isMatched = isMatched
        self.isSelected = isSelected
    }
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

enum CountryMemoryClueKind: String, CaseIterable, Equatable {
    case flag
    case currency
    case monument
    case capital
    case language

    static let questionChapter: [Self] = [
        .monument, .currency, .flag, .monument, .currency,
        .capital, .monument, .currency, .language, .flag
    ]

    var title: String {
        switch self {
        case .flag: return "Flags"
        case .currency: return "Money"
        case .monument: return "Landmarks"
        case .capital: return "Capitals"
        case .language: return "Languages"
        }
    }

    var prompt: String {
        switch self {
        case .flag: return "Match each flag to its country"
        case .currency: return "Match each money picture to its country"
        case .monument: return "Match each landmark to its country"
        case .capital: return "Match each capital to its country"
        case .language: return "Match each language clue to its country"
        }
    }

    var symbolName: String {
        switch self {
        case .flag: return "flag.fill"
        case .currency: return "banknote.fill"
        case .monument: return "building.2.fill"
        case .capital: return "building.columns.fill"
        case .language: return "text.bubble.fill"
        }
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
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Bindable var appModel: AppModel
    var contentCatalog: IOSLearningCatalog = .bundled

    @State private var deck: [MemoryAnimal] = MemoryDeck.domesticAnimals
    @State private var difficulty: MemoryDifficulty = .easy
    @State private var pairing = MemoryPairingEngine()
    @State private var pairingMode: MemoryPairingEngine.Mode = .pictures
    @State private var adventure: MemoryAdventure?
    @State private var showDeckChooser = false
    @State private var optionsExpanded = false
    @State private var exploreCardID: UUID?
    @State private var roundsPlayed: Int = 0
    @State private var sessionStart: Date = .now
    @State private var showRoundComplete = false
    @State private var deckSelection: DeckSelection = .domestic
    @State private var directEntryKind: MemoryDeckKind? = nil
    @State private var recentPairHistory: [String] = []
    @State private var learningContent: MemoryLearningContent? = nil
    @State private var askSession: MemoryAskConversationSession? = nil
    @State private var latestAskResponse: MemoryAskResponse? = nil
    @State private var descriptionTask: Task<Void, Never>? = nil
    @State private var countryClueKind: CountryMemoryClueKind = .flag
    @State private var evidenceSessionID = UUID().uuidString
    @State private var evidenceProfileID: String
    @State private var attempts: [ItemAttempt] = []
    @State private var supportedAnimalIDs: Set<String> = []

    init(appModel: AppModel, initialDeckKind: MemoryDeckKind? = nil, contentCatalog: IOSLearningCatalog = .bundled) {
        self.appModel = appModel
        self.contentCatalog = contentCatalog
        _evidenceProfileID = State(initialValue: appModel.profileStore.activeProfileId)
        let initialSelection = DeckSelection(kind: initialDeckKind)
        _deck = State(initialValue: contentCatalog.cards(for: initialSelection.kind))
        _deckSelection = State(initialValue: initialSelection)
        _directEntryKind = State(initialValue: Self.directStagedEntryKind(for: initialDeckKind))
        _difficulty = State(initialValue: Self.initialDifficulty(for: initialDeckKind))
    }

    enum DeckSelection: CaseIterable {
        case domestic, birds, vehicles, planets, fishes, countries, countryFlags, indiaStates, waterCycle, fruits, numberBondsTo10

        init(kind: MemoryDeckKind?) {
            switch kind {
            case .domesticAnimals: self = .domestic
            case .birds: self = .birds
            case .vehicles: self = .vehicles
            case .planets: self = .planets
            case .fishes: self = .fishes
            case .countries: self = .countries
            case .countryFlags: self = .countryFlags
            case .indiaStates: self = .indiaStates
            case .waterCycle: self = .waterCycle
            case .fruits: self = .fruits
            case .numberBondsTo10: self = .numberBondsTo10
            case nil: self = .domestic
            }
        }

        var kind: MemoryDeckKind {
            switch self {
            case .domestic: return .domesticAnimals
            case .birds: return .birds
            case .vehicles: return .vehicles
            case .planets: return .planets
            case .fishes: return .fishes
            case .countries: return .countries
            case .countryFlags: return .countryFlags
            case .indiaStates: return .indiaStates
            case .waterCycle: return .waterCycle
            case .fruits: return .fruits
            case .numberBondsTo10: return .numberBondsTo10
            }
        }

        var label: String {
            switch self {
            case .domestic: return "🐄 Animals"
            case .birds: return "🦜 Birds"
            case .vehicles: return "🚗 Vehicles"
            case .planets: return "🪐 Planets"
            case .fishes: return "🐠 Fishes"
            case .countries: return "🌍 Countries & Capitals"
            case .countryFlags: return "🏳️ Countries & Flags"
            case .indiaStates: return "📍 India States & Capitals"
            case .waterCycle: return "💧 Water Cycle"
            case .fruits: return "🍎 Fruits"
            case .numberBondsTo10: return "🔟 Number Bonds"
            }
        }

        var menuLabel: String {
            switch self {
            case .domestic: return "Animals"
            case .birds: return "Birds"
            case .vehicles: return "Vehicles"
            case .planets: return "Planets"
            case .fishes: return "Fishes"
            case .countries: return "Countries & Capitals"
            case .countryFlags: return "Countries & Flags"
            case .indiaStates: return "India States & Capitals"
            case .waterCycle: return "Water Cycle"
            case .fruits: return "Fruits"
            case .numberBondsTo10: return "Number Bonds to 10"
            }
        }

        var animals: [MemoryAnimal] {
            switch self {
            case .domestic: return MemoryDeck.domesticAnimals
            case .birds: return MemoryDeck.birds
            case .vehicles: return MemoryDeck.vehicles
            case .planets: return MemoryDeck.planets
            case .fishes: return MemoryDeck.fishes
            case .countries: return MemoryDeck.countries
            case .countryFlags: return MemoryDeck.countryFlags
            case .indiaStates: return MemoryDeck.indiaStates
            case .waterCycle: return MemoryDeck.waterCycle
            case .fruits: return MemoryDeck.fruits
            case .numberBondsTo10: return MemoryDeck.numberBondsTo10
            }
        }
    }

    private var cards: [MemoryCard] {
        pairing.cards.map { card in
            MemoryCard(id: card.id, pairId: card.pairID,
                       content: card.isLabel ? .label(card.animal) : .picture(card.animal),
                       isMatched: card.isMatched, isSelected: card.isSelected)
        }
    }
    private var matchedPairs: Int { pairing.matchedPairs }
    private var totalPairs: Int { pairing.totalPairs }
    private var targetPairCount: Int { min(difficulty.pairCount, deck.count) }
    private var supportsPicturePairs: Bool {
        ![DeckSelection.countries, .countryFlags, .indiaStates, .numberBondsTo10].contains(deckSelection)
    }
    private var roundPrompt: String {
        let instruction: String
        switch deckSelection {
        case .countryFlags: instruction = countryClueKind.prompt
        case .countries, .indiaStates: instruction = "Match each place to its capital."
        case .numberBondsTo10: instruction = "Match each sum to its answer."
        default:
            instruction = pairingMode == .pictures
                ? "Find two pictures that are the same." : "Match each picture to its name."
        }
        let visibility = difficulty.faceDown ? "Select a card to turn it over." : "The pictures are ready to explore."
        let introduction = adventure?.introduction ?? "\(deckSelection.menuLabel)."
        return "\(introduction) \(instruction) \(visibility)"
    }
    private var isDirectStagedEntry: Bool { directEntryKind != nil }

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
        .sheet(item: $learningContent, onDismiss: {
            descriptionTask?.cancel()
            askSession = nil
            latestAskResponse = nil
        }) { content in
            learningSheet(for: content)
        }
        .sheet(isPresented: $showDeckChooser) {
            MemoryDeckChooserView(selectedAdventure: adventure, selectedDeck: deckSelection) { selectedAdventure, selectedDeck in
                optionsExpanded = false
                adventure = selectedAdventure
                deckSelection = selectedDeck
                let catalogCards = contentCatalog.cards(for: selectedDeck.kind)
                deck = selectedAdventure?.cards(from: catalogCards) ?? catalogCards
                recentPairHistory = []
                directEntryKind = nil
                showDeckChooser = false
                dealRound()
            }
        }
        .onChange(of: pairing.matchedPairs) { oldValue, newValue in
            guard newValue > oldValue else { return }
            appModel.hapticsService.stageSuccess(enabled: appModel.featureFlags.hapticsEnabled)
            if pairing.isComplete {
                roundsPlayed += 1
                if reduceMotion { showRoundComplete = true }
                else { withAnimation { showRoundComplete = true } }
                speak(adventure?.celebration ?? ["Wonderful exploring! All the pairs are together.", "You found every pair!", "What a brilliant adventure!"][roundsPlayed % 3])
            }
        }
        .onAppear {
            sessionStart = .now
            dealRound()
        }
        .onDisappear {
            pairing.cancelPendingFeedback()
            appModel.speechService.stop()
            descriptionTask?.cancel()
            if !attempts.isEmpty {
                appModel.gameplayProgressStore.saveActivityResult(ActivityResult(id: evidenceSessionID, activityID: LabActivityID.memoryMatch.rawValue, title: "Memory Match", startedAt: sessionStart, attempts: attempts, completedStageIDs: roundsPlayed > 0 ? ["match"] : [], profileID: evidenceProfileID, contentVersion: contentCatalog.contentVersion))
            }
            guard roundsPlayed > 0 else { return }
            appModel.gameSessionStore.save(
                gameName: "Memory Match",
                startedAt: sessionStart,
                scoreValue: roundsPlayed,
                scoreLabel: "rounds"
            )
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 16) {
            ViewThatFits(in: .horizontal) {
                HStack(alignment: .top, spacing: 12) {
                    backButton
                    memoryHeaderCopy
                    Spacer(minLength: 0)
                }

                VStack(alignment: .leading, spacing: 8) {
                    backButton
                    memoryHeaderCopy
                }
            }

            CardSurface {
                VStack(alignment: .leading, spacing: 14) {
                    if isDirectStagedEntry {
                        directStagedEntryStatus
                    } else {
                        deckAndDifficultyChooser
                    }
                    roundControls
                }
            }
        }
    }


    private var backButton: some View {
        Button {
            appModel.engine.returnFromGameplay(defaultRoute: .home)
        } label: {
            Image(systemName: "chevron.left")
                .font(.title3.weight(.semibold))
                .foregroundStyle(MatherTheme.accent)
                .frame(width: 80, height: 80)
        }
        .accessibilityLabel("Back")
    }

    private var memoryHeaderCopy: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text("Memory Match")
                .font(.title2.weight(.black))
                .foregroundStyle(MatherTheme.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.82)
            Text("\(matchedPairs)/\(totalPairs) pairs matched")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(MatherTheme.cardSubtitle)
            if Self.supportsLearningDetails(for: deckSelection) {
                Text(Self.learnMoreHintText(for: deckSelection))
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(MatherTheme.cardSubtitle)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityIdentifier("memory-learn-more-hint")
            }
        }
    }

    private var deckAndDifficultyChooser: some View {
        VStack(alignment: .leading, spacing: 14) {
            if horizontalSizeClass == .regular {
                HStack(spacing: 14) {
                    deckSelector
                    playOptionsButton.frame(width: 200)
                }
            } else {
                deckSelector
                playOptionsButton
            }
            if optionsExpanded { expandedPlayOptions }
            if deckSelection == .countryFlags {
                Label(countryClueKind.prompt, systemImage: countryClueKind.symbolName)
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(MatherTheme.ink)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityIdentifier("memory-country-clue-prompt")
            }
        }
    }

    private var expandedPlayOptions: some View {
        VStack(alignment: .leading, spacing: 14) {
            Menu {
                ForEach(MemoryDifficulty.allCases, id: \.label) { selectedDifficulty in
                    Button(selectedDifficulty.label) {
                        difficulty = selectedDifficulty
                        optionsExpanded = false
                        dealRound()
                    }
                }
            } label: {
                controlLabel(title: "Difficulty", value: difficulty.menuLabel, tint: MatherTheme.warm)
            }
            .accessibilityIdentifier("memory-difficulty-menu")

            if supportsPicturePairs {
                HStack(spacing: 12) {
                    ForEach(MemoryPairingEngine.Mode.allCases) { mode in
                        Button {
                            pairingMode = mode
                            optionsExpanded = false
                            dealRound()
                        } label: {
                            Label(mode == .pictures ? "Picture pairs" : "Pictures & names", systemImage: mode == .pictures ? "photo.on.rectangle" : "textformat.abc")
                                .font(.subheadline.weight(.bold))
                                .frame(maxWidth: .infinity, minHeight: 80)
                                .background(pairingMode == mode ? MatherTheme.accent.opacity(0.22) : MatherTheme.background, in: RoundedRectangle(cornerRadius: 18))
                        }
                        .accessibilityIdentifier("memory-mode-\(mode.rawValue)")
                    }
                }
            }
            Text("\(deck.count) cards to explore")
                .font(.caption.weight(.semibold))
                .foregroundStyle(MatherTheme.cardSubtitle)
                .accessibilityIdentifier("memory-deck-card-count")
        }
    }

    private var deckSelector: some View {
        Button { showDeckChooser = true } label: {
            HStack(spacing: 12) {
                if let adventure {
                    Image(adventure.sceneAssetName).resizable().scaledToFit()
                        .frame(width: 76, height: 64).accessibilityHidden(true)
                } else if let first = deck.first {
                    pictureView(for: first, emojiSize: 48)
                        .frame(width: 76, height: 64).accessibilityHidden(true)
                }
                controlLabel(title: "Explore", value: adventure?.title ?? deckSelection.menuLabel, tint: MatherTheme.accent)
            }
            .frame(minHeight: 80)
        }
        .accessibilityIdentifier("memory-deck-menu")
    }

    private var playOptionsButton: some View {
        Button { optionsExpanded.toggle() } label: {
            Label("Play options", systemImage: optionsExpanded ? "chevron.up" : "slider.horizontal.3")
                .font(.headline.bold())
                .frame(maxWidth: .infinity, minHeight: 80)
                .background(MatherTheme.background, in: RoundedRectangle(cornerRadius: 18))
        }
        .accessibilityValue(optionsExpanded ? "Expanded" : "Collapsed")
        .accessibilityIdentifier("memory-play-options")
    }

    private var roundControls: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                Button {
                    guard appModel.profileStore.activeProfileId == evidenceProfileID else { return }
                    pairing.hint()
                    for card in pairing.cards where pairing.hintIDs.contains(card.id) && !card.isLabel {
                        supportedAnimalIDs.insert(card.animal.id)
                        recordMemoryAttempt(for: card.animal, outcome: .help, response: "hint")
                    }
                    speak("Look for the two glowing cards.")
                } label: {
                    Label("Hint", systemImage: "sparkles").frame(maxWidth: .infinity, minHeight: 80)
                }
                .disabled(pairing.isProcessing || pairing.isComplete)
                .accessibilityIdentifier("memory-hint")
                Button { speak(roundPrompt) } label: {
                    Label("Listen", systemImage: "speaker.wave.2.fill").frame(maxWidth: .infinity, minHeight: 80)
                }
                .accessibilityIdentifier("memory-repeat")
            }
            if let card = cards.first(where: { $0.id == exploreCardID }),
               Self.canOpenLearningDetails(for: card, deckSelection: deckSelection, difficulty: difficulty, showRoundComplete: showRoundComplete) {
                Button { handleDoubleTap(card) } label: {
                    Label("Explore \(Self.accessibilityLabel(for: card))", systemImage: "magnifyingglass")
                        .frame(maxWidth: .infinity, minHeight: 80)
                }
                .accessibilityIdentifier("memory-explore")
            }
        }
    }

    private var directStagedEntryStatus: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(deckSelection.menuLabel)
                .font(.headline.weight(.black))
                .foregroundStyle(MatherTheme.ink)
                .accessibilityIdentifier("memory-direct-deck-title")

            Text("Stage \(Self.stageNumber(for: difficulty)) of \(Self.directStageDifficulties.count): \(difficulty.menuLabel)")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(MatherTheme.cardSubtitle)
                .accessibilityIdentifier("memory-direct-stage-label")
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
        .frame(maxWidth: .infinity, minHeight: 80, alignment: .leading)
        .background(MatherTheme.background.opacity(colorScheme == .dark ? 0.4 : 1), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .contentShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private var cardGrid: some View {
        let minimumWidth = horizontalSizeClass == .regular
            ? (difficulty == .easy ? CGFloat(220) : CGFloat(160))
            : ResponsiveLayout.memoryCardMinimumWidth(for: difficulty)
        let columns = [GridItem(.adaptive(minimum: minimumWidth), spacing: 14)]
        return LazyVGrid(columns: columns, spacing: 14) {
            ForEach(cards) { card in
                let displayedCard = Self.displayedCard(card, hinted: pairing.hintIDs.contains(card.id))
                let canLearn = Self.canOpenLearningDetails(for: card, deckSelection: deckSelection, difficulty: difficulty, showRoundComplete: showRoundComplete)
                VStack(spacing: 8) {
                    cardView(card)
                    .aspectRatio(ResponsiveLayout.memoryCardAspectRatio(for: difficulty), contentMode: .fit)
                    .accessibilityIdentifier(Self.accessibilityIdentifier(for: card))
                    .accessibilityLabel(Self.accessibilityLabel(for: displayedCard, difficulty: difficulty))
                    .accessibilityHint(Self.accessibilityHint(for: displayedCard, difficulty: difficulty))
                    .onTapGesture(count: 2) { handleDoubleTap(card) }
                    .onTapGesture { handleTap(card) }
                    .modifier(MemoryLearnMoreAccessibilityModifier(
                        actionName: canLearn ? Self.learnAboutActionName(for: animal(for: card)) : nil,
                        action: { handleDoubleTap(card) }
                    ))
                    if canLearn {
                        Button { handleDoubleTap(card) } label: {
                            Label("Explore", systemImage: "speaker.wave.2.fill")
                                .font(.headline.weight(.bold))
                                .frame(maxWidth: .infinity, minHeight: 80)
                        }
                        .buttonStyle(.bordered)
                        .accessibilityIdentifier("memory-explore-\(card.id)")
                    }
                }
            }
        }
        .frame(maxWidth: ResponsiveLayout.memoryBoardMaxWidth(for: horizontalSizeClass))
        .frame(maxWidth: .infinity)
    }

    @ViewBuilder
    private func cardView(_ card: MemoryCard) -> some View {
        let hinted = pairing.hintIDs.contains(card.id)
        let displayedCard = Self.displayedCard(card, hinted: hinted)
        LearningCardView(model: Self.learningCardModel(for: displayedCard, difficulty: difficulty, isIncorrect: pairing.mismatchIDs.contains(card.id)))
            .overlay {
                if hinted { RoundedRectangle(cornerRadius: 20).stroke(MatherTheme.warm, lineWidth: 5).accessibilityHidden(true) }
            }
            .transaction { transaction in
                if reduceMotion {
                    transaction.animation = nil
                    transaction.disablesAnimations = true
                }
            }
    }

    @ViewBuilder
    private func pictureView(for animal: MemoryAnimal, emojiSize preferredEmojiSize: CGFloat? = nil) -> some View {
        switch animal.picture {
        case .emoji(let emoji):
            Text(emoji)
                .font(.system(size: preferredEmojiSize ?? emojiSize))
                .shadow(color: .black.opacity(0.10), radius: 3, y: 2)
        case .asset(let assetName):
            LearningContentImage(name: assetName)
                .scaledToFit()
                .shadow(color: .black.opacity(0.08), radius: 3, y: 2)
                .padding(4)
        case .text(let value):
            Text(value)
                .font(.system(size: difficulty == .hard ? 18 : 22, weight: .black, design: .rounded))
                .foregroundStyle(MatherTheme.ink)
                .multilineTextAlignment(.center)
                .lineLimit(3)
                .minimumScaleFactor(0.52)
                .padding(10)
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

    static func countryClueKind(forRound round: Int) -> CountryMemoryClueKind {
        let kinds = CountryMemoryClueKind.questionChapter
        return kinds[(round % kinds.count + kinds.count) % kinds.count]
    }

    static func buildCountryClueCards(for animals: [MemoryAnimal], clueKind: CountryMemoryClueKind) -> [MemoryCard] {
        animals.flatMap { animal in
            let clueAnimal = countryClueAnimal(for: animal, clueKind: clueKind)
            let countryLabelAnimal = MemoryAnimal(
                id: clueAnimal.id,
                name: animal.canonicalName,
                canonicalName: animal.canonicalName,
                picture: animal.picture,
                metadata: animal.metadata,
                learningArtwork: animal.learningArtwork
            )
            return [
                MemoryCard(pairId: clueAnimal.id, content: .picture(clueAnimal)),
                MemoryCard(pairId: clueAnimal.id, content: .label(countryLabelAnimal))
            ]
        }
    }

    static func countryClueAnimal(for animal: MemoryAnimal, clueKind: CountryMemoryClueKind) -> MemoryAnimal {
        let picture: MemoryPicture
        switch clueKind {
        case .flag:
            picture = animal.picture
        case .currency:
            picture = animal.learningArtwork.first(where: { $0.assetName.hasPrefix("MemoryCurrency") })
                .map { .asset($0.assetName) } ?? .text(countryFactValue("Currency Symbol", for: animal))
        case .monument:
            picture = animal.learningArtwork.first(where: { $0.assetName.hasPrefix("MemoryMonument") })
                .map { .asset($0.assetName) } ?? .text(countryFactValue("Monument", for: animal))
        case .capital:
            picture = .text(countryFactValue("Capital", for: animal))
        case .language:
            picture = .text(countryFactValue("Language", for: animal))
        }

        return MemoryAnimal(
            id: "\(animal.id)-clue-\(clueKind.rawValue)",
            name: animal.canonicalName,
            canonicalName: animal.canonicalName,
            picture: picture,
            metadata: animal.metadata,
            learningArtwork: animal.learningArtwork
        )
    }

    static func countryFactValue(_ title: String, for animal: MemoryAnimal) -> String {
        animal.detailCards.first(where: { $0.title == title })?.value ?? animal.canonicalName
    }

    static func preferredCountryClueAnimals(
        from deck: [MemoryAnimal],
        pairCount: Int,
        clueKind: CountryMemoryClueKind,
        recentPairHistory: [String]
    ) -> [MemoryAnimal] {
        let recentIDs = Set(recentPairHistory)
        let ordered = deck.filter { !recentIDs.contains($0.id) }.shuffled()
            + deck.filter { recentIDs.contains($0.id) }.shuffled()
        var seenClues: Set<String> = []
        var chosen: [MemoryAnimal] = []

        for animal in ordered {
            let key = countryClueDistinctKey(for: animal, clueKind: clueKind)
                .folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
            guard seenClues.insert(key).inserted else { continue }
            chosen.append(animal)
            if chosen.count == pairCount { break }
        }
        return chosen
    }

    static func countryClueDistinctKey(for animal: MemoryAnimal, clueKind: CountryMemoryClueKind) -> String {
        switch clueKind {
        case .currency:
            return countryFactValue("Currency", for: animal)
        case .capital:
            return countryFactValue("Capital", for: animal)
        case .language:
            return countryFactValue("Language", for: animal)
        case .monument:
            return countryFactValue("Monument", for: animal)
        case .flag:
            return animal.canonicalName
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
        VStack {
            Spacer()

            VStack(spacing: 14) {
                if let adventure {
                    Image(adventure.sceneAssetName).resizable().scaledToFit().frame(height: 130).accessibilityHidden(true)
                }
                Text("🎉 All matched!")
                    .font(.title2.weight(.black))
                    .foregroundStyle(MatherTheme.ink)

                Text(adventure?.celebration ?? Self.roundCompleteMessage(for: deckSelection, roundsPlayed: roundsPlayed))
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(MatherTheme.cardSubtitle)
                    .multilineTextAlignment(.center)

                if let adventure {
                    Button { speak(adventure.tryIt) } label: {
                        Label("Try it!", systemImage: "figure.play").frame(maxWidth: .infinity, minHeight: 80)
                    }
                    .accessibilityIdentifier("memory-adventure-try-it")
                }
                Button {
                    nextRound()
                } label: {
                    Text("Next Round").frame(minHeight: 80)
                }
                .buttonStyle(PrimaryActionButtonStyle())
                .frame(maxWidth: 240, minHeight: 80)
            }
            .padding(24)
            .frame(maxWidth: .infinity)
            .background(RoundedRectangle(cornerRadius: 24, style: .continuous).fill(MatherTheme.card).shadow(color: .black.opacity(0.18), radius: 24, y: 8))
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
        .transition(reduceMotion ? .opacity : .move(edge: .bottom).combined(with: .opacity))
    }

    static func preferredRoundAnimals(from deck: [MemoryAnimal], pairCount: Int, recentPairHistory: [String]) -> [MemoryAnimal] {
        guard pairCount > 0 else { return [] }
        let recentSet = Set(recentPairHistory)
        let ordered = deck.filter { !recentSet.contains($0.id) }.shuffled()
            + deck.filter { recentSet.contains($0.id) }.shuffled()
        var seenNames: Set<String> = []
        var chosen: [MemoryAnimal] = []
        for animal in ordered {
            guard seenNames.insert(animal.canonicalName.lowercased()).inserted else { continue }
            chosen.append(animal)
            if chosen.count == pairCount { break }
        }
        return chosen
    }

    static func updatedRecentPairHistory(previous: [String], newRoundAnimals: [MemoryAnimal], pairCount: Int, deckCount: Int? = nil) -> [String] {
        let effectiveDeckCount = deckCount ?? max(pairCount * 3, pairCount)
        let historyWindow = max(pairCount, effectiveDeckCount - pairCount)
        return Array((previous + newRoundAnimals.map(\.id)).suffix(historyWindow))
    }

    static func deckSummaryText(for deckSelection: DeckSelection) -> String {
        let count = deckSelection.animals.count
        let subject: String
        switch deckSelection {
        case .vehicles: subject = "vehicle"
        default: subject = "learning"
        }
        return "\(count) \(subject) cards to explore"
    }

    static let directStageDifficulties: [MemoryDifficulty] = [.easy, .medium, .hard]

    static func directStagedEntryKind(for initialDeckKind: MemoryDeckKind?) -> MemoryDeckKind? {
        switch initialDeckKind {
        case .fruits, .countries, .numberBondsTo10:
            return initialDeckKind
        case .domesticAnimals, .birds, .vehicles, .planets, .fishes, .countryFlags, .indiaStates, .waterCycle, nil:
            return nil
        }
    }

    static func initialDifficulty(for initialDeckKind: MemoryDeckKind?) -> MemoryDifficulty {
        directStagedEntryKind(for: initialDeckKind) == nil ? .easy : directStageDifficulties[0]
    }

    static func stageNumber(for difficulty: MemoryDifficulty) -> Int {
        (directStageDifficulties.firstIndex(of: difficulty) ?? 0) + 1
    }

    static func nextDirectStageDifficulty(after difficulty: MemoryDifficulty) -> MemoryDifficulty {
        guard let index = directStageDifficulties.firstIndex(of: difficulty) else {
            return directStageDifficulties[0]
        }
        let nextIndex = min(index + 1, directStageDifficulties.count - 1)
        return directStageDifficulties[nextIndex]
    }

    static func shouldHideChooser(for initialDeckKind: MemoryDeckKind?) -> Bool {
        directStagedEntryKind(for: initialDeckKind) != nil
    }

    static func canOpenLearningDetails(for card: MemoryCard, deckSelection: DeckSelection, difficulty: MemoryDifficulty, showRoundComplete: Bool) -> Bool {
        guard supportsLearningDetails(for: deckSelection) else { return false }
        if card.isMatched { return true }
        guard !showRoundComplete else { return false }
        return difficulty.faceDown ? card.isSelected : true
    }

    static func supportsLearningDetails(for deckSelection: DeckSelection) -> Bool {
        !deckSelection.animals.isEmpty
    }

    static func learnMoreHintText(for deckSelection: DeckSelection) -> String {
        supportsLearningDetails(for: deckSelection) ? "Tap Explore to hear and learn more" : ""
    }

    static func roundCompleteMessage(for deckSelection: DeckSelection, roundsPlayed: Int) -> String {
        supportsLearningDetails(for: deckSelection)
            ? "Double-tap a card to learn more, or start the next round."
            : "Round \(roundsPlayed) complete"
    }

    static func learnAboutActionName(for animal: MemoryAnimal) -> String {
        "Learn about \(animal.canonicalName)"
    }

    static func learningContent(for animal: MemoryAnimal, deckSelection: DeckSelection, description: MemoryCardDescription) -> MemoryLearningContent {
        let sourceBadge = learningSourceBadge(for: deckSelection, source: description.source)
        let factChips = description.factChips.map { MemoryFactCard(title: $0.title, value: $0.value) }
        return MemoryLearningContent(
            animal: animal,
            title: description.title,
            shortDescription: description.shortDescription,
            factChips: factChips,
            sourceBadge: sourceBadge,
            readAloudText: learningReadAloudText(for: description.title, summary: description.shortDescription, factChips: factChips, sourceBadge: sourceBadge)
        )
    }

    private func handleDoubleTap(_ card: MemoryCard) {
        guard appModel.profileStore.activeProfileId == evidenceProfileID else { return }
        guard Self.canOpenLearningDetails(for: card, deckSelection: deckSelection, difficulty: difficulty, showRoundComplete: showRoundComplete) else { return }
        let cardAnimal = animal(for: card)
        let selectedAnimal = Self.originalCountryAnimal(for: cardAnimal)
        supportedAnimalIDs.insert(cardAnimal.id)
        recordMemoryAttempt(for: cardAnimal, outcome: .help, response: "explore")
        appModel.speechService.speak(selectedAnimal.canonicalName, enabled: appModel.featureFlags.audioEnabled)
        descriptionTask?.cancel()
        askSession = nil
        latestAskResponse = nil
        learningContent = Self.learningContent(
            for: selectedAnimal,
            deckSelection: deckSelection,
            description: appModel.memoryCardDescribeService.fallbackDescription(for: selectedAnimal)
        )
        descriptionTask = Task { @MainActor in
            let description = await appModel.memoryCardDescribeService.describe(selectedAnimal)
            guard !Task.isCancelled, learningContent?.animal.id == selectedAnimal.id else { return }
            learningContent = Self.learningContent(for: selectedAnimal, deckSelection: deckSelection, description: description)
        }
    }

    @ViewBuilder
    private func learningSheet(for content: MemoryLearningContent) -> some View {
        let animal = content.animal
        let artStyle = Self.artStyle(for: animal.id)

        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 18) {
                    HStack(alignment: .center, spacing: 16) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 24, style: .continuous)
                                .fill(LinearGradient(colors: [artStyle.topColor, artStyle.bottomColor], startPoint: .topLeading, endPoint: .bottomTrailing))
                                .frame(width: 108, height: 108)

                            pictureView(for: animal)
                                .frame(width: 80, height: 80)
                        }
                        .accessibilityHidden(true)

                        VStack(alignment: .leading, spacing: 8) {
                            Text(content.title)
                                .font(.title3.weight(.black))
                                .foregroundStyle(MatherTheme.ink)
                                .accessibilityIdentifier("memory-learning-title")

                            Text(content.shortDescription)
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(MatherTheme.cardSubtitle)
                                .accessibilityIdentifier("memory-learning-description")

                            Text(content.sourceBadge)
                                .font(.caption.weight(.bold))
                                .foregroundStyle(artStyle.ornamentColor)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(Color.white.opacity(colorScheme == .dark ? 0.08 : 0.6), in: Capsule())
                                .accessibilityIdentifier("memory-learning-source-badge")
                        }

                        Spacer(minLength: 0)
                    }

                    Button {
                        appModel.speechService.speakLearningDetails(content.readAloudText, enabled: appModel.featureFlags.audioEnabled)
                    } label: {
                        Label("Read Aloud", systemImage: "speaker.wave.2.fill")
                            .font(.headline.weight(.bold))
                            .frame(maxWidth: .infinity, minHeight: 80)
                    }
                    .buttonStyle(PrimaryActionButtonStyle())
                    .accessibilityIdentifier("memory-learning-read-aloud")

                    if !animal.learningArtwork.isEmpty {
                        Label("Picture clues", systemImage: "photo.on.rectangle.angled")
                            .font(.headline.weight(.black))
                            .foregroundStyle(MatherTheme.ink)

                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 150), spacing: 12)], spacing: 12) {
                            ForEach(animal.learningArtwork, id: \.self) { artwork in
                                VStack(spacing: 8) {
                                    LearningContentImage(name: artwork.assetName)
                                        .scaledToFit()
                                        .frame(maxWidth: .infinity)
                                        .aspectRatio(1, contentMode: .fit)
                                        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))

                                    Text(artwork.title)
                                        .font(.subheadline.weight(.bold))
                                        .foregroundStyle(MatherTheme.ink)
                                        .multilineTextAlignment(.center)
                                        .lineLimit(2)
                                        .minimumScaleFactor(0.8)
                                }
                                .padding(10)
                                .background(MatherTheme.background.opacity(colorScheme == .dark ? 0.45 : 1), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                                .accessibilityElement(children: .combine)
                                .accessibilityLabel("Picture clue: \(artwork.title)")
                            }
                        }
                        .accessibilityIdentifier("memory-learning-picture-clues")
                    }

                    Label(
                        Self.learningFactsSectionTitle(for: animal),
                        systemImage: Self.learningFactsSectionSymbol(for: animal)
                    )
                        .font(.headline.weight(.black))
                        .foregroundStyle(MatherTheme.ink)

                    LazyVGrid(columns: [GridItem(.adaptive(minimum: ResponsiveLayout.memoryLearningFactMinimumWidth(for: horizontalSizeClass)), spacing: 10)], spacing: 10) {
                        ForEach(content.factChips, id: \.self) { fact in
                            HStack(alignment: .top, spacing: 10) {
                                Image(systemName: Self.learningFactSymbol(for: fact))
                                    .font(.body.weight(.bold))
                                    .foregroundStyle(artStyle.ornamentColor)
                                    .frame(width: 24, height: 24)
                                    .background(artStyle.ornamentColor.opacity(0.13), in: Circle())
                                    .accessibilityHidden(true)

                                VStack(alignment: .leading, spacing: 4) {
                                    Text(fact.title)
                                        .font(.caption.weight(.bold))
                                        .foregroundStyle(artStyle.ornamentColor)

                                    Text(fact.value)
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundStyle(MatherTheme.ink)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(12)
                            .background(MatherTheme.background.opacity(colorScheme == .dark ? 0.45 : 1), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                            .accessibilityElement(children: .combine)
                        }
                    }
                    .accessibilityIdentifier("memory-learning-fact-chips")

                    MemoryAskConversationSection(
                        session: askSession,
                        latestResponse: latestAskResponse,
                        startConversation: {
                            Task { @MainActor in
                                askSession = await MemoryAskConversationPolicy().startSession(for: animal)
                                latestAskResponse = nil
                            }
                        },
                        selectTurn: { turn in
                            guard var session = askSession else { return }
                            let response = session.respond(to: .suggestedTurn(id: turn.id))
                            askSession = session
                            latestAskResponse = response
                            appModel.speechService.speakLearningDetails(response.spokenText, enabled: appModel.featureFlags.audioEnabled)
                        },
                        replayLatestAnswer: {
                            guard let latestAskResponse else { return }
                            appModel.speechService.speakLearningDetails(latestAskResponse.spokenText, enabled: appModel.featureFlags.audioEnabled)
                        }
                    )
                }
                .padding(20)
                .frame(maxWidth: ResponsiveLayout.memoryLearningSheetMaxWidth(for: horizontalSizeClass), alignment: .leading)
                .frame(maxWidth: .infinity)
            }
            .background(MatherTheme.background.ignoresSafeArea())
            .navigationTitle("Learn")
            .navigationBarTitleDisplayMode(.inline)
            .safeAreaInset(edge: .bottom) {
                Button {
                    descriptionTask?.cancel()
                    learningContent = nil
                    askSession = nil
                    latestAskResponse = nil
                } label: {
                    Text("Done").font(.headline.bold()).frame(maxWidth: .infinity, minHeight: 80)
                }
                .background(MatherTheme.card)
                .padding(.horizontal, 20)
                .accessibilityIdentifier("memory-learning-done")
            }
        }
        .presentationDetents([.medium, .large])
    }

    private func dealRound() {
        descriptionTask?.cancel()
        let roundAnimals: [MemoryAnimal]
        if deckSelection == .countryFlags {
            countryClueKind = Self.countryClueKind(forRound: roundsPlayed)
            roundAnimals = Self.preferredCountryClueAnimals(from: deck, pairCount: targetPairCount, clueKind: countryClueKind, recentPairHistory: recentPairHistory)
        } else {
            roundAnimals = Self.preferredRoundAnimals(from: deck, pairCount: targetPairCount, recentPairHistory: recentPairHistory)
        }
        recentPairHistory = Self.updatedRecentPairHistory(previous: recentPairHistory, newRoundAnimals: roundAnimals, pairCount: targetPairCount, deckCount: deck.count)
        let animals = deckSelection == .countryFlags
            ? roundAnimals.map { Self.countryClueAnimal(for: $0, clueKind: countryClueKind) } : roundAnimals
        pairing.deal(animals: animals, mode: supportsPicturePairs ? pairingMode : .names, faceDown: difficulty.faceDown)
        learningContent = nil
        askSession = nil
        latestAskResponse = nil
        exploreCardID = nil
        showRoundComplete = false
        speak(roundPrompt)
    }

    private func handleTap(_ card: MemoryCard) {
        guard appModel.profileStore.activeProfileId == evidenceProfileID else { return }
        guard !card.isMatched, !pairing.isProcessing, !card.isSelected else {
            if card.isMatched { exploreCardID = card.id }
            return
        }
        let selection = pairing.select(card.id)
        exploreCardID = card.id
        appModel.hapticsService.counterSettle(enabled: appModel.featureFlags.hapticsEnabled)
        if let selected = cards.first(where: { $0.id == card.id }),
           let text = Self.selectionSpeech(for: selected, difficulty: difficulty) {
            if appModel.featureFlags.audioEnabled && !UIAccessibility.isVoiceOverRunning,
               case .picture(let animal) = selected.content {
                switch animal.picture {
                case .text: break
                case .asset, .emoji:
                    supportedAnimalIDs.insert(animal.id)
                    recordMemoryAttempt(for: animal, outcome: .help, response: "heard name")
                }
            }
            speak(text)
        }
        if case .pair(let first, let second, let matches) = selection {
            let prompt = first.isLabel ? second.animal : first.animal
            let outcome: ItemAttemptOutcome = matches
                ? (supportedAnimalIDs.contains(prompt.id) ? .supportedCorrect : .independentCorrect) : .incorrect
            if !matches { supportedAnimalIDs.insert(prompt.id) }
            recordMemoryAttempt(for: prompt, outcome: outcome,
                                response: first.animal.name + " ↔ " + second.animal.name)
        }
    }

    private func recordMemoryAttempt(for animal: MemoryAnimal, outcome: ItemAttemptOutcome, response: String) {
        let attempt = ItemAttempt(activityID: LabActivityID.memoryMatch.rawValue, conceptID: animal.metadata.deck.rawValue, entityID: animal.id, propertyID: "match", stageID: "match", outcome: outcome, response: response, profileID: evidenceProfileID, sessionID: evidenceSessionID, contentVersion: contentCatalog.contentVersion)
        attempts.append(attempt)
        appModel.gameplayProgressStore.recordAttempts([attempt], sessionID: evidenceSessionID)
    }

    static func spokenTapPrompt(for card: MemoryCard) -> String {
        switch card.content {
        case .label(let animal): return animal.name
        case .picture(let animal):
            if case .text(let prompt) = animal.picture { return prompt }
            return animal.canonicalName
        }
    }

    static func cardsFormValidMatch(_ first: MemoryCard, _ second: MemoryCard) -> Bool {
        switch (first.content, second.content) {
        case (.picture(let picture), .label(let label)), (.label(let label), .picture(let picture)):
            return picture.name.trimmingCharacters(in: .whitespacesAndNewlines).localizedCaseInsensitiveCompare(label.name.trimmingCharacters(in: .whitespacesAndNewlines)) == .orderedSame
        default: return false
        }
    }

    private func speak(_ text: String) {
        guard !UIAccessibility.isVoiceOverRunning else { return }
        appModel.speechService.speak(text, enabled: appModel.featureFlags.audioEnabled)
    }

    private func nextRound() {
        learningContent = nil
        if isDirectStagedEntry {
            difficulty = Self.nextDirectStageDifficulty(after: difficulty)
        }
        if reduceMotion { dealRound() }
        else { withAnimation(.easeOut(duration: 0.2)) { dealRound() } }
    }


    static func displayedCard(_ card: MemoryCard, hinted: Bool) -> MemoryCard {
        MemoryCard(id: card.id, pairId: card.pairId, content: card.content,
                   isMatched: card.isMatched, isSelected: card.isSelected || hinted)
    }

    static func selectionSpeech(for card: MemoryCard, difficulty: MemoryDifficulty) -> String? {
        guard !difficulty.faceDown || card.isSelected || card.isMatched else { return nil }
        switch card.content {
        case .label(let animal): return animal.name
        case .picture(let animal):
            if countryClueKind(for: animal) != nil { return accessibilityLabel(for: card) }
            if case .text(let text) = animal.picture { return text }
            return animal.canonicalName
        }
    }

    static func accessibilityIdentifier(for card: MemoryCard) -> String {
        let kind: String
        switch card.content {
        case .picture:
            kind = "picture"
        case .label:
            kind = "label"
        }
        return "memory-card-\(card.pairId)-\(kind)"
    }

    static func accessibilityLabel(for card: MemoryCard) -> String {
        switch card.content {
        case .picture(let animal):
            if let clueKind = countryClueKind(for: animal) {
                switch clueKind {
                case .flag: return "Flag clue: \(countryFactValue("Colors", for: animal))"
                case .currency: return "Money clue: \(countryFactValue("Currency", for: animal))"
                case .monument: return "Landmark clue: \(countryFactValue("Monument", for: animal))"
                case .capital: return "Capital clue: \(countryFactValue("Capital", for: animal))"
                case .language: return "Official language clue: \(countryFactValue("Language", for: animal))"
                }
            }
            if animal.metadata.deck == .countryFlags {
                return "Flag of \(animal.canonicalName)"
            }
            if case .text(let text) = animal.picture { return text }
            return animal.canonicalName
        case .label(let animal):
            return animal.name
        }
    }

    static func countryClueKind(for animal: MemoryAnimal) -> CountryMemoryClueKind? {
        guard let markerRange = animal.id.range(of: "-clue-") else { return nil }
        return CountryMemoryClueKind(rawValue: String(animal.id[markerRange.upperBound...]))
    }

    static func originalCountryAnimal(for animal: MemoryAnimal) -> MemoryAnimal {
        guard countryClueKind(for: animal) != nil else { return animal }
        return MemoryDeck.countryFlags.first(where: { $0.canonicalName == animal.canonicalName }) ?? animal
    }

    static func accessibilityLabel(for card: MemoryCard, difficulty: MemoryDifficulty) -> String {
        if difficulty.faceDown && !card.isSelected && !card.isMatched {
            return "Face down memory card"
        }

        let state: String
        if card.isMatched {
            state = "matched"
        } else if card.isSelected {
            state = "selected"
        } else {
            state = "visible"
        }
        return "\(accessibilityLabel(for: card)), \(state)"
    }

    static func accessibilityHint(for card: MemoryCard, difficulty: MemoryDifficulty) -> String {
        if card.isMatched {
            return "Matched card."
        }
        if difficulty.faceDown && !card.isSelected {
            return "Tap to turn this card over."
        }
        return "Tap to choose this card."
    }

    static func learningCardModel(for card: MemoryCard, difficulty: MemoryDifficulty, isIncorrect: Bool) -> LearningCardViewModel {
        let display: LearningCardDisplay
        switch card.content {
        case .picture(let pictureAnimal):
            display = Self.learningCardDisplay(for: pictureAnimal.picture)
        case .label(let labelAnimal):
            display = .text(labelAnimal.name)
        }

        return LearningCardViewModel(
            id: card.id.uuidString,
            display: display,
            accessibilityLabel: accessibilityLabel(for: card, difficulty: difficulty),
            accessibilityHint: accessibilityHint(for: card, difficulty: difficulty),
            isFaceDown: difficulty.faceDown && !card.isSelected && !card.isMatched,
            isSelected: card.isSelected,
            isMatched: card.isMatched,
            isIncorrect: isIncorrect
        )
    }

    private static func learningCardDisplay(for picture: MemoryPicture) -> LearningCardDisplay {
        switch picture {
        case .emoji(let emoji):
            return .emoji(emoji)
        case .asset(let assetName):
            return .asset(assetName)
        case .text(let value):
            return .text(value)
        }
    }

    private static func learningSourceBadge(for deckSelection: DeckSelection, source: MemoryCardDescriptionSource) -> String {
        let deckLabel: String
        switch deckSelection {
        case .birds:
            deckLabel = "Bird Guide"
        case .domestic:
            deckLabel = "Animal Guide"
        case .vehicles:
            deckLabel = "Vehicle Guide"
        case .planets:
            deckLabel = "NASA Planetary Photojournal"
        case .fishes:
            deckLabel = "Fish Guide"
        case .countries:
            deckLabel = "Country Guide"
        case .countryFlags:
            deckLabel = "Flag Guide"
        case .indiaStates:
            deckLabel = "India Guide"
        case .waterCycle:
            deckLabel = "Water Cycle Guide"
        case .fruits:
            deckLabel = "Fruit Guide"
        case .numberBondsTo10:
            deckLabel = "Number Bond Guide"
        }

        switch source {
        case .appleIntelligence:
            return "Apple Intelligence + \(deckLabel)"
        case .curatedFallback:
            return deckLabel
        }
    }

    static func learningFactsSectionTitle(for animal: MemoryAnimal) -> String {
        switch animal.metadata.deck {
        case .countries, .countryFlags:
            return "Passport facts"
        default:
            return "What to remember"
        }
    }

    static func learningFactsSectionSymbol(for animal: MemoryAnimal) -> String {
        switch animal.metadata.deck {
        case .countries, .countryFlags:
            return "globe.asia.australia.fill"
        default:
            return "brain.head.profile.fill"
        }
    }

    static func learningFactSymbol(for fact: MemoryFactCard) -> String {
        switch fact.title.lowercased() {
        case "country", "continent", "home", "region", "bucket":
            return "globe.americas.fill"
        case "capital":
            return "building.columns.fill"
        case "language", "official language":
            return "text.bubble.fill"
        case "currency", "money", "banknote":
            return "banknote.fill"
        case "currency symbol", "symbol":
            return "dollarsign.circle.fill"
        case "flag", "colors":
            return "flag.fill"
        case "monument", "landmark", "known for":
            return "building.2.fill"
        case "iso code":
            return "number.square.fill"
        case "map shape":
            return "map.fill"
        default:
            return "sparkles"
        }
    }

    private static func learningReadAloudText(for title: String, summary: String, factChips: [MemoryFactCard], sourceBadge: String) -> String {
        let facts = factChips.map { "\($0.title): \($0.value)." }.joined(separator: " ")
        return "\(title). \(summary) Source: \(sourceBadge). \(facts)"
    }
}

private struct MemoryLearnMoreAccessibilityModifier: ViewModifier {
    let actionName: String?
    let action: () -> Void

    @ViewBuilder
    func body(content: Content) -> some View {
        if let actionName {
            content.accessibilityAction(named: Text(actionName)) {
                action()
            }
        } else {
            content
        }
    }
}

private struct MemoryAskConversationSection: View {
    @Environment(\.colorScheme) private var colorScheme

    let session: MemoryAskConversationSession?
    let latestResponse: MemoryAskResponse?
    let startConversation: () -> Void
    let selectTurn: (MemoryAskSuggestedTurn) -> Void
    let replayLatestAnswer: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let session {
                Text("Ask about this card")
                    .font(.headline.weight(.black))
                    .foregroundStyle(MatherTheme.ink)

                VStack(spacing: 10) {
                    ForEach(session.suggestedTurns) { turn in
                        Button {
                            selectTurn(turn)
                        } label: {
                            Label(turn.question, systemImage: "questionmark.circle.fill")
                                .lineLimit(2)
                                .minimumScaleFactor(0.78)
                                .multilineTextAlignment(.center)
                                .frame(maxWidth: .infinity, minHeight: 80)
                        }
                        .buttonStyle(SecondaryTileButtonStyle(fill: MatherTheme.softBlue.opacity(colorScheme == .dark ? 0.34 : 0.62)))
                        .accessibilityIdentifier("memory-ask-suggested-turn-\(turn.id)")
                    }
                }

                if let latestResponse {
                    VStack(alignment: .leading, spacing: 10) {
                        Text(latestResponse.spokenText)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(MatherTheme.ink)
                            .fixedSize(horizontal: false, vertical: true)
                            .accessibilityIdentifier("memory-ask-latest-answer")

                        Button {
                            replayLatestAnswer()
                        } label: {
                            Label("Replay answer", systemImage: "speaker.wave.2.fill")
                                .font(.subheadline.weight(.bold))
                                .frame(maxWidth: .infinity, minHeight: 52)
                        }
                        .buttonStyle(SecondaryTileButtonStyle(fill: MatherTheme.warm.opacity(colorScheme == .dark ? 0.28 : 0.52)))
                        .accessibilityIdentifier("memory-ask-replay-answer")
                    }
                    .padding(12)
                    .background(MatherTheme.background.opacity(colorScheme == .dark ? 0.45 : 1), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                }
            } else {
                Button {
                    startConversation()
                } label: {
                    Label("Ask about this card", systemImage: "questionmark.bubble.fill")
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                        .frame(maxWidth: .infinity, minHeight: 80)
                }
                .buttonStyle(SecondaryTileButtonStyle(fill: MatherTheme.softBlue.opacity(colorScheme == .dark ? 0.34 : 0.62)))
                .accessibilityIdentifier("memory-ask-about-this-card")
            }
        }
    }
}
