import SwiftUI

@MainActor
struct MemoryDeckChooserView: View {
    @Environment(\.dismiss) private var dismiss
    let selectedAdventure: MemoryAdventure?
    let selectedDeck: MemoryView.DeckSelection
    let select: (MemoryAdventure?, MemoryView.DeckSelection) -> Void

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    Text("Pick an adventure").font(.title2.bold())
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 160))], spacing: 16) {
                        ForEach(MemoryAdventure.allCases) { adventure in
                            Button {
                                select(adventure, MemoryView.DeckSelection(kind: adventure.deckKind))
                            } label: {
                                VStack(spacing: 10) {
                                    Image(adventure.sceneAssetName).resizable().scaledToFit().frame(height: 130).accessibilityHidden(true)
                                    Text(adventure.title).font(.headline)
                                    if selectedAdventure == adventure { Image(systemName: "checkmark.circle.fill") }
                                }
                                .frame(maxWidth: .infinity, minHeight: 200)
                                .background(MatherTheme.accent.opacity(0.12), in: RoundedRectangle(cornerRadius: 24))
                            }
                            .accessibilityLabel(adventure.title)
                            .accessibilityAddTraits(selectedAdventure == adventure ? .isSelected : [])
                            .accessibilityHint(adventure.introduction)
                            .accessibilityIdentifier("memory-adventure-\(adventure.id)")
                        }
                    }
                    Text("Explore every deck").font(.title2.bold())
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 160))], spacing: 16) {
                        ForEach(MemoryView.DeckSelection.allCases, id: \.menuLabel) { deck in
                            Button { select(nil, deck) } label: {
                                VStack(spacing: 10) {
                                    if let picture = deck.animals.first?.picture { preview(picture).frame(height: 100) }
                                    Text(deck.menuLabel).font(.headline).multilineTextAlignment(.center)
                                    if selectedAdventure == nil && selectedDeck == deck { Image(systemName: "checkmark.circle.fill") }
                                }
                                .frame(maxWidth: .infinity, minHeight: 180)
                                .background(MatherTheme.card, in: RoundedRectangle(cornerRadius: 24))
                            }
                            .accessibilityLabel(deck.menuLabel)
                            .accessibilityAddTraits(selectedAdventure == nil && selectedDeck == deck ? .isSelected : [])
                            .accessibilityIdentifier("memory-deck-\(deck.animals.first?.metadata.deck.rawValue ?? deck.menuLabel)")
                        }
                    }
                }
                .padding(24)
            }
            .foregroundStyle(MatherTheme.ink)
            .background(MatherTheme.background)
            .navigationTitle("Memory adventures")
            .safeAreaInset(edge: .bottom) {
                Button { dismiss() } label: {
                    Text("Done").font(.headline.bold()).frame(maxWidth: .infinity, minHeight: 80)
                }
                .background(MatherTheme.card)
                .padding(.horizontal, 24)
            }
        }
    }

    @ViewBuilder private func preview(_ picture: MemoryPicture) -> some View {
        switch picture {
        case .asset(let name): Image(name).resizable().scaledToFit().accessibilityHidden(true)
        case .emoji(let value): Text(value).font(.system(size: 72)).accessibilityHidden(true)
        case .text(let value): Text(value).font(.title.bold()).minimumScaleFactor(0.5)
        }
    }
}
