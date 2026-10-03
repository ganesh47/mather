import SwiftUI

/// Remote-friendly picture adventures share the same pairing rules as touch play.
struct MemoryPairsTVView: View {
    let adventure: MemoryAdventure
    let quiz: ([MemoryAnimal]) -> Void
    @Environment(MemoryGalleryContentStore.self) private var contentStore
    @Environment(\.dismiss) private var dismiss
    @State private var engine = MemoryPairingEngine()
    @State private var narration = TVNarrationController()
    @State private var playing = false
    @State private var hidden = false
    @State private var pairCount = 3
    @State private var explored: MemoryAnimal?
    @FocusState private var focusedID: String?

    private var visibleExplored: MemoryAnimal? {
        guard let explored else { return nil }
        return !hidden || engine.cards.contains(where: { $0.animal.id == explored.id && ($0.isSelected || $0.isMatched || engine.hintIDs.contains($0.id)) }) ? explored : nil
    }

    private var availableCards: [MemoryAnimal] {
        let category: MemoryGalleryTVCategory = adventure.deckKind == .planets ? .planets : .vehicles
        let downloaded = contentStore.cards(for: category).filter { adventure.cardIDs.contains($0.id) }
        return downloaded.count >= 4 ? downloaded : adventure.cards
    }

    var body: some View {
        ZStack {
            MatherTVBackdrop()
            VStack(spacing: 24) {
                Text(adventure.title).font(.system(size: 54, weight: .black, design: .rounded))
                if playing { board } else { options }
            }
            .foregroundStyle(.white)
            .padding(60)
        }
        .onAppear {
            narration.presentPrompt("\(adventure.introduction) Choose picture pairs or a picture quiz. Swipe to hear the options. Press Play Pause to repeat.")
            focusedID = "start"
        }
        .onPlayPauseCommand { narration.repeatPrompt() }
        .onExitCommand { engine.cancelPendingFeedback(); narration.stop(); dismiss() }
        .onChange(of: focusedID) { _, id in
            guard let id else { return }
            if let card = engine.cards.first(where: { $0.id.uuidString == id }) {
                narration.focus(cardLabel(card))
            } else {
                let labels = ["start": "Three pairs. Pictures stay visible.", "four": "Four pairs. Pictures stay visible.",
                              "hidden": "Hide and seek. Up to six hidden pairs.", "quiz": "Picture quiz.",
                              "back": "Choose another adventure.", "again": "Play again.",
                              "hint": "Show a pair. A hint will make two matching cards glow.", "options": "Adventure options.", "explore": "Explore this picture. Hear what to look for and a fun activity."]
                narration.focus(labels[id])
            }
        }
        .onChange(of: engine.matchedPairs) { _, _ in
            if engine.isComplete {
                narration.announce("\(adventure.celebration) \(adventure.tryIt) Play again or choose another adventure.")
                focusedID = "again"
            } else {
                narration.announce("A pair! \(engine.matchedPairs) of \(engine.totalPairs) found.")
                focusedID = engine.cards.first(where: { !$0.isMatched })?.id.uuidString
            }
        }
                .onChange(of: engine.hintIDs) { _, _ in
            if let card = engine.cards.first(where: { $0.id.uuidString == focusedID }) { narration.focus(cardLabel(card)) }
        }
        .onChange(of: engine.isProcessing) { _, processing in
            if !processing && visibleExplored == nil { explored = nil }
        }
        .onChange(of: engine.mismatchIDs) { _, ids in
            if !ids.isEmpty { narration.announce("Different pictures. Good looking! Try another pair.") }
        }
        .onDisappear { engine.cancelPendingFeedback(); narration.stop() }
    }

    private var options: some View {
        VStack(spacing: 24) {
            Image(adventure.sceneAssetName).resizable().scaledToFit().frame(height: 240)
                .accessibilityHidden(true)
            Text(adventure.introduction).font(.system(size: 25, weight: .semibold, design: .rounded))
            HStack(spacing: 22) {
                action("3 pairs • pictures stay visible", id: "start") { begin(count: 3, faceDown: false) }
                action("4 pairs • pictures stay visible", id: "four") { begin(count: 4, faceDown: false) }
                action("Hide and seek • \(min(6, availableCards.count)) pairs", id: "hidden") { begin(count: 6, faceDown: true) }
            }
            HStack(spacing: 22) {
                action("Picture quiz", id: "quiz") { narration.stop(); quiz(availableCards) }
                action("Choose another adventure", id: "back") { dismiss() }
            }
        }
    }

    private var board: some View {
        VStack(spacing: 22) {
            if engine.isComplete {
                Image(adventure.sceneAssetName).resizable().scaledToFit().frame(height: 150).accessibilityHidden(true)
                Text(adventure.celebration).font(.system(size: 36, weight: .black, design: .rounded))
                Text(adventure.tryIt).font(.system(size: 24, weight: .semibold, design: .rounded))
            } else {
                Text("\(engine.matchedPairs) of \(engine.totalPairs) pairs • Take your time")
                    .font(.system(size: 25, weight: .bold, design: .rounded))
            }
            LazyVGrid(columns: Array(repeating: GridItem(.fixed(tileWidth), spacing: 22), count: engine.totalPairs > 4 ? 6 : 4), spacing: 22) {
                ForEach(engine.cards) { card in
                    Button {
                        engine.select(card.id)
                        if !hidden || engine.cards.first(where: { $0.id == card.id })?.isSelected == true {
                            explored = card.animal
                            narration.announce(card.animal.canonicalName)
                        }
                    } label: {
                        ZStack {
                            RoundedRectangle(cornerRadius: 24).fill(card.isMatched ? Color.green.opacity(0.3) : Color.white.opacity(0.12))
                            if hidden && !card.isSelected && !card.isMatched && !engine.hintIDs.contains(card.id) {
                                Image(systemName: "sparkles").font(.system(size: 65))
                            } else {
                                picture(card.animal.picture).padding(16)
                            }
                            if card.isMatched {
                                Image(systemName: "checkmark.circle.fill").font(.system(size: 28)).frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing).padding(12)
                            }
                        }
                        .frame(width: tileWidth, height: engine.isComplete ? 130 : 175)
                        .overlay(RoundedRectangle(cornerRadius: 24).stroke(
                            engine.hintIDs.contains(card.id) ? Color.yellow :
                                engine.mismatchIDs.contains(card.id) ? Color.orange :
                                card.isSelected ? Color.cyan : Color.clear,
                            lineWidth: 6))
                    }
                    .buttonStyle(.card)
                    .focused($focusedID, equals: card.id.uuidString)
                    .accessibilityLabel(cardLabel(card))
                    .accessibilityIdentifier("tv-memory-pair-\(card.id.uuidString)")
                }
            }
            if let animal = visibleExplored {
                action("Explore \(animal.canonicalName)", id: "explore") {
                    let facts = animal.detailCards.filter { ["look closely", "try it", "fun fact"].contains($0.title.lowercased()) }
                    let text = facts.prefix(2).map { "\($0.title). \($0.value)" }.joined(separator: ". ")
                    narration.presentPrompt("\(animal.canonicalName). \(text)")
                }
            }
            HStack(spacing: 22) {
                if engine.isComplete {
                    action("Play again", id: "again") { begin(count: pairCount, faceDown: hidden) }
                } else {
                    action("Show a pair", id: "hint") { engine.hint(); narration.announce("Look for the two glowing cards.") }
                }
                action("Adventure options", id: "options") { engine.cancelPendingFeedback(); playing = false; explored = nil; focusedID = "start" }
                action("Choose another adventure", id: "back") { dismiss() }
            }
        }
    }

    private var tileWidth: CGFloat { engine.totalPairs > 4 ? 230 : 310 }

    private func begin(count: Int, faceDown: Bool) {
        pairCount = min(count, availableCards.count)
        hidden = faceDown
        explored = nil
        engine.deal(animals: Array(availableCards.shuffled().prefix(pairCount)), mode: .pictures, faceDown: faceDown)
        playing = true
        focusedID = engine.cards.first?.id.uuidString
        narration.presentPrompt(faceDown ? "Choose two cards to find matching pictures. Press Show a pair for a clue. No timer." : "Find two matching pictures. Swipe to a picture and press select. No timer.")
    }

    private func cardLabel(_ card: MemoryPairingEngine.Card) -> String {
        let position = (engine.cards.firstIndex(where: { $0.id == card.id }) ?? 0) + 1
        if hidden && !card.isSelected && !card.isMatched && !engine.hintIDs.contains(card.id) { return "Hidden card \(position). Select to turn over." }
        return "\(card.animal.canonicalName). \(card.isMatched ? "Matched. Select to explore." : "Select to find its pair.")"
    }

    private func action(_ title: String, id: String, perform: @escaping () -> Void) -> some View {
        Button(title, action: perform)
            .font(.system(size: 22, weight: .bold, design: .rounded))
            .focused($focusedID, equals: id)
            .foregroundStyle(focusedID == id ? Color(red: 0.06, green: 0.11, blue: 0.17) : .white)
            .accessibilityIdentifier("tv-memory-adventure-\(id)")
    }

    @ViewBuilder private func picture(_ picture: MemoryPicture) -> some View {
        switch picture {
        case .asset(let name):
            if let url = contentStore.assetURL(named: name), let image = UIImage(contentsOfFile: url.path) {
                Image(uiImage: image).resizable().scaledToFit()
            } else {
                Image(name).resizable().scaledToFit()
            }
        case .emoji(let value): Text(value).font(.system(size: 95))
        case .text(let value): Text(value).font(.system(size: 28, weight: .black, design: .rounded))
        }
    }
}
