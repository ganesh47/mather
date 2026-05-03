import SwiftUI

struct CountryCardsView: View {
    @Bindable var appModel: AppModel
    @State private var mode: CountryCardsMode = .flashcards
    @State private var cardIndex = 0
    @State private var bucketGame = CountryContinentBucketGame()
    @State private var selectedCountryID: String = CountryCardsDeck.starterCountries.first?.id ?? ""
    @State private var bucketFeedback = "Pick a country, then tap its continent bucket."

    private var currentCard: CountryFlashcard {
        let cards = CountryCardsDeck.deterministicFlashcards
        return cards[cardIndex % max(cards.count, 1)]
    }

    var body: some View {
        ZStack {
            MatherTheme.background.ignoresSafeArea()
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 18) {
                    header
                    modePicker

                    switch mode {
                    case .flashcards:
                        flashcardPanel
                    case .continentBuckets:
                        bucketPanel
                    }
                }
                .padding(22)
            }
        }
        .navigationTitle("Country Cards")
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Button {
                    appModel.engine.showLabLane(.mapWorld)
                } label: {
                    Label("Map & World", systemImage: "chevron.left")
                        .font(.headline.weight(.black))
                        .foregroundStyle(MatherTheme.accent)
                        .frame(minHeight: 56)
                }
                .buttonStyle(.plain)

                Spacer()

                Button {
                    appModel.engine.showHome()
                } label: {
                    Image(systemName: "house.fill")
                        .font(.title2.weight(.semibold))
                        .foregroundStyle(MatherTheme.accent)
                        .frame(width: 56, height: 56)
                }
                .accessibilityLabel("Home")
            }

            Label("Country Cards", systemImage: "map.fill")
                .font(.system(size: 34, weight: .black, design: .rounded))
                .foregroundStyle(MatherTheme.ink)
            Text("Flashcards for country names, capitals, languages, flags, currency, and shapes on the map — then sort countries into continent buckets.")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(MatherTheme.cardSubtitle)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .background(MatherTheme.card, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    private var modePicker: some View {
        Picker("Country game mode", selection: $mode) {
            ForEach(CountryCardsMode.allCases) { mode in
                Text(mode.label).tag(mode)
            }
        }
        .pickerStyle(.segmented)
        .accessibilityLabel("Country game mode")
    }

    private var flashcardPanel: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Flashcard \(cardIndex + 1) of \(CountryCardsDeck.deterministicFlashcards.count)")
                .font(.caption.weight(.black))
                .foregroundStyle(MatherTheme.accent)

            VStack(alignment: .leading, spacing: 12) {
                Text(currentCard.country.flagEmoji)
                    .font(.system(size: 64))
                    .accessibilityHidden(true)
                Text(currentCard.prompt)
                    .font(.title3.weight(.black))
                    .foregroundStyle(MatherTheme.cardSubtitle)
                Text(currentCard.answer)
                    .font(.system(size: 36, weight: .black, design: .rounded))
                    .foregroundStyle(MatherTheme.ink)
                    .minimumScaleFactor(0.75)
                Text(currentCard.detail)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(MatherTheme.cardSubtitle)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(20)
            .background(MatherTheme.card, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(MatherTheme.accent.opacity(0.18), lineWidth: 1)
            )
            .accessibilityElement(children: .combine)
            .accessibilityLabel(currentCard.country.accessibilitySummary)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                factChip("Country", currentCard.country.name)
                factChip("Capital", currentCard.country.capital)
                factChip("Language", currentCard.country.language)
                factChip("Currency", currentCard.country.currency)
                factChip("Shape", currentCard.country.mapShape)
                factChip("Continent", currentCard.country.continent)
            }

            HStack(spacing: 12) {
                Button("Previous") { previousCard() }
                    .buttonStyle(CountryCardsButtonStyle(tint: MatherTheme.softBlue))
                Button("Next card") { nextCard() }
                    .buttonStyle(CountryCardsButtonStyle(tint: MatherTheme.accent))
            }
        }
    }

    private var bucketPanel: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label("Continent bucket mode", systemImage: "tray.full.fill")
                .font(.title3.weight(.black))
                .foregroundStyle(MatherTheme.ink)
            Text(bucketGame.completionLabel)
                .font(.caption.weight(.black))
                .foregroundStyle(MatherTheme.accent)
            Text(bucketFeedback)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(MatherTheme.cardSubtitle)
                .fixedSize(horizontal: false, vertical: true)

            VStack(alignment: .leading, spacing: 10) {
                Text("Countries to sort")
                    .font(.headline.weight(.black))
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                    ForEach(CountryCardsDeck.starterCountries) { country in
                        Button {
                            selectedCountryID = country.id
                            bucketFeedback = "Now place \(country.flagEmoji) \(country.name) into a continent bucket."
                        } label: {
                            HStack {
                                Text(country.flagEmoji)
                                Text(country.name)
                                    .font(.caption.weight(.black))
                                Spacer(minLength: 0)
                                if bucketGame.placedCountryIDs.contains(country.id) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(MatherTheme.accent)
                                }
                            }
                            .padding(10)
                            .frame(maxWidth: .infinity, minHeight: 54, alignment: .leading)
                            .background(country.id == selectedCountryID ? MatherTheme.accent.opacity(0.14) : MatherTheme.card, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                        }
                        .buttonStyle(.plain)
                        .disabled(bucketGame.placedCountryIDs.contains(country.id))
                    }
                }
            }

            VStack(alignment: .leading, spacing: 10) {
                Text("Continent buckets")
                    .font(.headline.weight(.black))
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                    ForEach(CountryCardsDeck.continents, id: \.self) { continent in
                        Button {
                            placeSelectedCountry(in: continent)
                        } label: {
                            VStack(alignment: .leading, spacing: 6) {
                                Image(systemName: "shippingbox.fill")
                                    .foregroundStyle(MatherTheme.accent)
                                Text(continent)
                                    .font(.headline.weight(.black))
                                    .foregroundStyle(MatherTheme.ink)
                                Text(bucketContents(for: continent))
                                    .font(.caption2.weight(.semibold))
                                    .foregroundStyle(MatherTheme.cardSubtitle)
                                    .lineLimit(2)
                            }
                            .frame(maxWidth: .infinity, minHeight: 112, alignment: .topLeading)
                            .padding(12)
                            .background(MatherTheme.card, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Place selected country in \(continent)")
                    }
                }
            }
        }
        .padding(16)
        .background(MatherTheme.card.opacity(0.72), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    private func factChip(_ title: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title.uppercased())
                .font(.caption2.weight(.black))
                .foregroundStyle(MatherTheme.accent)
            Text(value)
                .font(.caption.weight(.semibold))
                .foregroundStyle(MatherTheme.ink)
                .lineLimit(2)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity, minHeight: 64, alignment: .leading)
        .padding(10)
        .background(MatherTheme.card, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private func nextCard() {
        cardIndex = (cardIndex + 1) % CountryCardsDeck.deterministicFlashcards.count
    }

    private func previousCard() {
        cardIndex = (cardIndex - 1 + CountryCardsDeck.deterministicFlashcards.count) % CountryCardsDeck.deterministicFlashcards.count
    }

    private func placeSelectedCountry(in continent: String) {
        guard let country = CountryCardsDeck.country(id: selectedCountryID) else { return }
        if bucketGame.place(countryID: selectedCountryID, in: continent) {
            bucketFeedback = "Nice! \(country.flagEmoji) \(country.name) belongs in \(continent)."
            if let next = bucketGame.remainingCountries.first {
                selectedCountryID = next.id
            }
        } else {
            bucketFeedback = "Try again: \(country.name) is not in \(continent). Look for the map clue."
        }
    }

    private func bucketContents(for continent: String) -> String {
        let names = CountryCardsDeck.starterCountries
            .filter { bucketGame.placedCountryIDs.contains($0.id) && $0.continent == continent }
            .map(\.name)
        return names.isEmpty ? "Drop countries here" : names.joined(separator: ", ")
    }
}

private enum CountryCardsMode: String, CaseIterable, Identifiable {
    case flashcards
    case continentBuckets

    var id: String { rawValue }

    var label: String {
        switch self {
        case .flashcards: return "Flashcards"
        case .continentBuckets: return "Buckets"
        }
    }
}

private struct CountryCardsButtonStyle: ButtonStyle {
    let tint: Color

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline.weight(.black))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity, minHeight: 58)
            .background(tint.opacity(configuration.isPressed ? 0.72 : 1), in: Capsule())
    }
}
