import SwiftUI

struct MemoryGalleryTVView: View {
    @FocusState private var focusedCategory: MemoryGalleryTVCategory.ID?
    @FocusState private var focusedAnswerID: String?
    @FocusState private var nextButtonFocused: Bool
    @FocusState private var focusedCompletionAction: CompletionAction?

    @State private var game = MemoryGalleryTVGame()

    var body: some View {
        ZStack {
            MatherTVBackdrop()

            switch game.phase {
            case .choosingCategory:
                categoryChooser
            case .playing:
                if let round = game.round {
                    playScreen(round: round)
                }
            case .completed:
                completionScreen
            }
        }
        .onAppear {
            focusFirstCategory()
        }
    }

    private var categoryChooser: some View {
        VStack(alignment: .leading, spacing: 46) {
            VStack(alignment: .leading, spacing: 12) {
                Text("Memory Gallery")
                    .font(.system(size: 70, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .accessibilityIdentifier("tv-memory-gallery-title")

                Text("Pick a gallery, then match six big pictures. No timer—just play.")
                    .font(.system(size: 30, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.74))
                    .accessibilityIdentifier("tv-memory-gallery-prompt")
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Memory Gallery. Pick a gallery, then match six big pictures. There is no timer.")

            categoryShelf

            Label("Swipe to choose a gallery, then press select.", systemImage: "hand.tap.fill")
                .font(.system(size: 24, weight: .semibold, design: .rounded))
                .foregroundStyle(.white.opacity(0.62))
        }
        .frame(maxWidth: 1680, maxHeight: .infinity, alignment: .topLeading)
        .padding(.horizontal, 90)
        .padding(.vertical, 76)
    }

    private var categoryShelf: some View {
        HStack(spacing: 22) {
            ForEach(MemoryGalleryTVCategory.allCases) { category in
                Button {
                    start(category)
                } label: {
                    MemoryGalleryCategoryTile(
                        category: category,
                        isFocused: focusedCategory == category.id,
                        isSelected: false
                    )
                }
                .buttonStyle(.plain)
                .focused($focusedCategory, equals: category.id)
                .accessibilityLabel("\(category.title), \(category.subtitle)")
                .accessibilityHint("Starts a six-picture \(category.title) matching game.")
                .accessibilityIdentifier("tv-memory-category-\(category.id)")
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Category shelf")
    }

    private func playScreen(round: MemoryGalleryTVRound) -> some View {
        VStack(alignment: .leading, spacing: 32) {
            playHeader(round: round)
            roundStage(round: round)
        }
        .frame(maxWidth: 1680, maxHeight: .infinity, alignment: .topLeading)
        .padding(.horizontal, 90)
        .padding(.vertical, 66)
    }

    private func playHeader(round: MemoryGalleryTVRound) -> some View {
        HStack(alignment: .center, spacing: 28) {
            Image(systemName: round.category.symbolName)
                .font(.system(size: 38, weight: .black))
                .frame(width: 68, height: 68)
                .foregroundStyle(Color(red: 0.07, green: 0.12, blue: 0.18))
                .background(.white, in: RoundedRectangle(cornerRadius: 18, style: .continuous))

            VStack(alignment: .leading, spacing: 7) {
                Text(round.category.title)
                    .font(.system(size: 42, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                Text(game.progressText)
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.64))
            }

            Spacer()

            scorePill(title: "Matched", value: game.correctCount, symbol: "checkmark")
            scorePill(title: "Streak", value: game.streak, symbol: "flame.fill")
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(round.category.title). \(game.progressText). \(game.correctCount) matched. Streak \(game.streak).")
    }

    private func scorePill(title: String, value: Int, symbol: String) -> some View {
        HStack(spacing: 13) {
            Image(systemName: symbol)
                .font(.system(size: 25, weight: .black))
            Text("\(value)")
                .font(.system(size: 35, weight: .black, design: .rounded))
            Text(title)
                .font(.system(size: 21, weight: .bold, design: .rounded))
                .foregroundStyle(.white.opacity(0.64))
        }
        .foregroundStyle(Color(red: 0.78, green: 0.94, blue: 0.66))
        .padding(.horizontal, 22)
        .padding(.vertical, 13)
        .background(.white.opacity(0.08), in: Capsule())
    }

    private func roundStage(round: MemoryGalleryTVRound) -> some View {
        HStack(alignment: .top, spacing: 42) {
            promptPanel(round: round)

            VStack(alignment: .leading, spacing: 22) {
                Text(round.choicePrompt)
                    .font(.system(size: 32, weight: .black, design: .rounded))
                    .foregroundStyle(.white)

                answerGrid(round: round)

                feedbackBar(round: round)
            }
            .frame(maxWidth: .infinity, alignment: .topLeading)
        }
    }

    private func promptPanel(round: MemoryGalleryTVRound) -> some View {
        VStack(alignment: .leading, spacing: 20) {
            Text(round.promptTitle)
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundStyle(Color(red: 0.55, green: 0.88, blue: 1.0))

            promptArtwork(round: round)
                .frame(width: 520, height: 310)
                .accessibilityHidden(true)

            if game.hasAnsweredCurrentRound {
                VStack(alignment: .leading, spacing: 8) {
                    Text(accessibilityName(for: round.promptCard))
                        .font(.system(size: 28, weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                        .lineLimit(1)

                    ForEach(Array(round.learningFacts.enumerated()), id: \.offset) { _, fact in
                        Text("\(fact.title): \(fact.value)")
                            .font(.system(size: round.category == .flags ? 18 : 20, weight: .semibold, design: .rounded))
                            .foregroundStyle(.white.opacity(0.68))
                            .lineLimit(round.category == .flags ? 1 : 2)
                            .minimumScaleFactor(0.82)
                    }
                }
                .transition(.opacity.combined(with: .move(edge: .bottom)))
            } else {
                Text("Look closely, then choose.")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.48))
            }
        }
        .padding(36)
        .frame(width: 600, height: 610, alignment: .leading)
        .background(.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 30, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .stroke(.white.opacity(0.14), lineWidth: 1)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Picture prompt. \(promptAccessibilityLabel(for: round)).")
        .accessibilityHint("Move right to choose the matching name.")
        .accessibilityIdentifier("tv-memory-picture-prompt")
    }

    @ViewBuilder
    private func promptArtwork(round: MemoryGalleryTVRound) -> some View {
        if game.hasAnsweredCurrentRound,
           round.category == .flags,
           !round.promptCard.learningArtwork.isEmpty {
            HStack(spacing: 16) {
                ForEach(Array(round.promptCard.learningArtwork.prefix(2)), id: \.self) { artwork in
                    VStack(spacing: 8) {
                        Image(artwork.assetName)
                            .resizable()
                            .scaledToFit()
                            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))

                        Text(artwork.title)
                            .font(.system(size: 17, weight: .bold, design: .rounded))
                            .foregroundStyle(.white.opacity(0.78))
                            .lineLimit(1)
                            .minimumScaleFactor(0.72)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .transition(.opacity)
        } else {
            MemoryGalleryPromptArtwork(picture: round.promptPicture)
        }
    }

    private func answerGrid(round: MemoryGalleryTVRound) -> some View {
        LazyVGrid(
            columns: [
                GridItem(.fixed(390), spacing: 22),
                GridItem(.fixed(390), spacing: 22)
            ],
            spacing: 22
        ) {
            ForEach(round.answerChoices) { answer in
                Button {
                    choose(answer)
                } label: {
                    MemoryGalleryAnswerTile(
                        answer: answer,
                        isFocused: focusedAnswerID == answer.id,
                        state: answerState(for: answer, round: round)
                    )
                }
                .buttonStyle(.plain)
                .focused($focusedAnswerID, equals: answer.id)
                .disabled(game.hasAnsweredCurrentRound)
                .accessibilityLabel(accessibilityName(for: answer))
                .accessibilityHint("Select to match this name with the picture.")
                .accessibilityIdentifier("tv-memory-answer-\(answer.id)")
            }
        }
    }

    @ViewBuilder
    private func feedbackBar(round: MemoryGalleryTVRound) -> some View {
        if let selectedAnswerID = game.selectedAnswerID {
            HStack(spacing: 20) {
                Image(systemName: game.lastAnswerWasCorrect == true ? "checkmark.circle.fill" : "sparkles")
                    .font(.system(size: 38, weight: .bold))
                    .foregroundStyle(game.lastAnswerWasCorrect == true ? Color(red: 0.78, green: 0.94, blue: 0.66) : Color(red: 1.0, green: 0.78, blue: 0.42))

                VStack(alignment: .leading, spacing: 4) {
                    Text(game.lastAnswerWasCorrect == true ? celebrationCopy : "Good try—now you know!")
                        .font(.system(size: 28, weight: .black, design: .rounded))
                        .foregroundStyle(.white)

                    Text(game.lastAnswerWasCorrect == true ? "You found \(accessibilityName(for: round.promptCard))." : "This is \(accessibilityName(for: round.promptCard)).")
                        .font(.system(size: 22, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.68))
                }

                Spacer(minLength: 18)

                Button {
                    nextRound()
                } label: {
                    Label(nextActionTitle, systemImage: game.completedRoundCount == MemoryGalleryTVGame.roundsPerGame ? "sparkles" : "forward.fill")
                        .font(.system(size: 24, weight: .black, design: .rounded))
                        .padding(.horizontal, 24)
                        .padding(.vertical, 18)
                }
                .buttonStyle(.plain)
                .focused($nextButtonFocused)
                .background(nextButtonFocused ? .white : Color(red: 0.55, green: 0.88, blue: 1.0).opacity(0.20), in: Capsule())
                .foregroundStyle(nextButtonFocused ? Color(red: 0.07, green: 0.10, blue: 0.16) : .white)
                .accessibilityIdentifier(game.completedRoundCount == MemoryGalleryTVGame.roundsPerGame ? "tv-memory-see-results" : "tv-memory-next-picture")
            }
            .padding(24)
            .frame(width: 802)
            .frame(minHeight: 120)
            .background(.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 26, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 26, style: .continuous)
                    .stroke(.white.opacity(0.14), lineWidth: 1)
            )
            .accessibilityElement(children: .contain)
            .accessibilityLabel(feedbackAccessibilityLabel(selectedAnswerID: selectedAnswerID, round: round))
        } else {
            Text("No timer. Take your time and press select when the focused name matches the picture.")
                .font(.system(size: 22, weight: .semibold, design: .rounded))
                .foregroundStyle(.white.opacity(0.58))
                .frame(width: 802, alignment: .leading)
                .frame(minHeight: 120, alignment: .leading)
                .accessibilityIdentifier("tv-memory-no-timer-copy")
        }
    }

    private var completionScreen: some View {
        VStack(spacing: 30) {
            ZStack {
                Circle()
                    .fill(Color(red: 0.97, green: 0.80, blue: 0.30).opacity(0.18))
                    .frame(width: 190, height: 190)
                Image(systemName: completionSymbol)
                    .font(.system(size: 94, weight: .black))
                    .foregroundStyle(Color(red: 0.98, green: 0.84, blue: 0.38))
            }

            VStack(spacing: 10) {
                Text(completionTitle)
                    .font(.system(size: 66, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                    .accessibilityIdentifier("tv-memory-completion-title")
                Text("You explored six \(game.category?.title.lowercased() ?? "gallery") pictures.")
                    .font(.system(size: 28, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.70))
            }

            HStack(spacing: 24) {
                completionStat(value: "\(game.correctCount)/\(MemoryGalleryTVGame.roundsPerGame)", label: "matched", symbol: "checkmark.circle.fill")
                completionStat(value: "\(game.bestStreak)", label: "best streak", symbol: "flame.fill")
            }

            HStack(spacing: 24) {
                Button {
                    replay()
                } label: {
                    Label("Play this gallery again", systemImage: "arrow.clockwise")
                        .font(.system(size: 25, weight: .black, design: .rounded))
                        .padding(.horizontal, 30)
                        .padding(.vertical, 21)
                }
                .buttonStyle(.plain)
                .focused($focusedCompletionAction, equals: .replay)
                .foregroundStyle(focusedCompletionAction == .replay ? Color(red: 0.07, green: 0.10, blue: 0.16) : .white)
                .background(focusedCompletionAction == .replay ? .white : .white.opacity(0.10), in: Capsule())
                .accessibilityIdentifier("tv-memory-replay")

                Button {
                    chooseAnotherGallery()
                } label: {
                    Label("Choose another gallery", systemImage: "rectangle.stack.fill")
                        .font(.system(size: 25, weight: .black, design: .rounded))
                        .padding(.horizontal, 30)
                        .padding(.vertical, 21)
                }
                .buttonStyle(.plain)
                .focused($focusedCompletionAction, equals: .chooseGallery)
                .foregroundStyle(focusedCompletionAction == .chooseGallery ? Color(red: 0.07, green: 0.10, blue: 0.16) : .white)
                .background(focusedCompletionAction == .chooseGallery ? .white : .white.opacity(0.10), in: Capsule())
                .accessibilityIdentifier("tv-memory-choose-gallery")
            }
        }
        .frame(maxWidth: 1500, maxHeight: .infinity)
        .padding(70)
        .accessibilityElement(children: .contain)
    }

    private func completionStat(value: String, label: String, symbol: String) -> some View {
        HStack(spacing: 15) {
            Image(systemName: symbol)
                .font(.system(size: 34, weight: .black))
                .foregroundStyle(Color(red: 0.78, green: 0.94, blue: 0.66))
            Text(value)
                .font(.system(size: 43, weight: .black, design: .rounded))
                .foregroundStyle(.white)
            Text(label)
                .font(.system(size: 23, weight: .bold, design: .rounded))
                .foregroundStyle(.white.opacity(0.62))
        }
        .padding(.horizontal, 28)
        .padding(.vertical, 19)
        .background(.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 24, style: .continuous))
    }

    private var celebrationCopy: String {
        switch game.streak {
        case 3...: return "\(game.streak) in a row!"
        case 2: return "Two in a row!"
        default: return "Matched!"
        }
    }

    private var nextActionTitle: String {
        game.completedRoundCount == MemoryGalleryTVGame.roundsPerGame ? "See results" : "Next picture"
    }

    private var completionTitle: String {
        switch game.correctCount {
        case MemoryGalleryTVGame.roundsPerGame: return "Perfect gallery!"
        case 4...: return "Gallery star!"
        default: return "Gallery explored!"
        }
    }

    private var completionSymbol: String {
        game.correctCount == MemoryGalleryTVGame.roundsPerGame ? "star.circle.fill" : "sparkles"
    }

    private func start(_ category: MemoryGalleryTVCategory) {
        game.start(category: category)
        focusFirstAnswer()
    }

    private func choose(_ answer: MemoryAnimal) {
        guard !game.hasAnsweredCurrentRound else { return }
        game.select(answerID: answer.id)
        focusedAnswerID = nil
        Task { @MainActor in
            nextButtonFocused = true
        }
    }

    private func nextRound() {
        game.advance()
        nextButtonFocused = false
        if game.phase == .completed {
            Task { @MainActor in
                focusedCompletionAction = .replay
            }
        } else {
            focusFirstAnswer()
        }
    }

    private func replay() {
        game.replay()
        focusedCompletionAction = nil
        focusFirstAnswer()
    }

    private func chooseAnotherGallery() {
        game.chooseAnotherCategory()
        focusedCompletionAction = nil
        focusFirstCategory()
    }

    private func focusFirstCategory() {
        Task { @MainActor in
            focusedCategory = MemoryGalleryTVCategory.allCases.first?.id
        }
    }

    private func focusFirstAnswer() {
        Task { @MainActor in
            focusedAnswerID = game.round?.answerChoices.first?.id
        }
    }

    private func answerState(for answer: MemoryAnimal, round: MemoryGalleryTVRound) -> MemoryGalleryAnswerTile.State {
        guard let selectedAnswerID = game.selectedAnswerID else { return .idle }
        if answer.id == round.correctAnswerID { return .correct }
        if answer.id == selectedAnswerID { return .incorrect }
        return .dimmed
    }

    private func feedbackAccessibilityLabel(selectedAnswerID: String, round: MemoryGalleryTVRound) -> String {
        if selectedAnswerID == round.correctAnswerID {
            return "Correct. \(accessibilityName(for: round.promptCard)) matched."
        }
        return "Not a match. The correct answer was \(accessibilityName(for: round.promptCard))."
    }

    private func promptAccessibilityLabel(for round: MemoryGalleryTVRound) -> String {
        switch round.countryPromptKind {
        case .flag:
            return "Country flag. Choose the country that has this flag."
        case .monument:
            return "Famous place picture. Choose the country where this place is found."
        case .currency:
            return "Money picture. Choose the country that uses this money."
        case .capital:
            return "Capital city clue. Choose the country that has this capital."
        case .officialLanguage:
            return "Official language clue. Choose the country that uses this language."
        case nil where round.isVehiclePartPrompt:
            return "Picture of the vehicle part called \(accessibilityName(for: round.promptCard))."
        default:
            return "Picture of \(accessibilityName(for: round.promptCard))."
        }
    }

    private func accessibilityName(for animal: MemoryAnimal) -> String {
        switch animal.metadata.deck {
        case .countries, .countryFlags, .indiaStates:
            return animal.canonicalName
        default:
            return animal.name
        }
    }

    private enum CompletionAction: Hashable {
        case replay
        case chooseGallery
    }
}

private struct MemoryGalleryCategoryTile: View {
    let category: MemoryGalleryTVCategory
    let isFocused: Bool
    let isSelected: Bool

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: category.symbolName)
                .font(.system(size: 34, weight: .black))
                .frame(width: 58, height: 58)
                .foregroundStyle(isFocused ? Color(red: 0.08, green: 0.12, blue: 0.18) : .white)
                .background(isFocused ? .white : .white.opacity(0.12), in: RoundedRectangle(cornerRadius: 16, style: .continuous))

            VStack(alignment: .leading, spacing: 4) {
                Text(category.title)
                    .font(.system(size: 28, weight: .black, design: .rounded))
                    .foregroundStyle(isFocused ? Color(red: 0.08, green: 0.12, blue: 0.18) : .white)

                Text(category.subtitle)
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(isFocused ? Color(red: 0.18, green: 0.24, blue: 0.32) : .white.opacity(0.62))
            }

            Spacer(minLength: 0)
        }
        .padding(20)
        .frame(width: 350, height: 114)
        .background(backgroundStyle, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(isSelected ? Color(red: 0.55, green: 0.88, blue: 1.0).opacity(0.9) : .white.opacity(0.12), lineWidth: 2)
        )
        .scaleEffect(isFocused ? 1.05 : 1.0)
        .shadow(color: .black.opacity(isFocused ? 0.32 : 0.12), radius: isFocused ? 20 : 8, x: 0, y: isFocused ? 14 : 5)
        .animation(.spring(response: 0.26, dampingFraction: 0.78), value: isFocused)
    }

    private var backgroundStyle: some ShapeStyle {
        if isFocused {
            return AnyShapeStyle(.white)
        }
        if isSelected {
            return AnyShapeStyle(Color(red: 0.12, green: 0.34, blue: 0.40).opacity(0.82))
        }
        return AnyShapeStyle(.white.opacity(0.08))
    }
}

private struct MemoryGalleryPromptArtwork: View {
    let picture: MemoryPicture

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.97, green: 0.86, blue: 0.45),
                            Color(red: 0.38, green: 0.78, blue: 0.82)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            pictureView
                .frame(width: 360, height: 260)
                .padding(28)
        }
    }

    @ViewBuilder
    private var pictureView: some View {
        switch picture {
        case .emoji(let emoji):
            Text(emoji)
                .font(.system(size: 172))
                .shadow(color: .black.opacity(0.18), radius: 8, y: 6)
        case .asset(let assetName):
            Image(assetName)
                .resizable()
                .scaledToFit()
                .shadow(color: .black.opacity(0.18), radius: 8, y: 6)
        case .text(let value):
            Text(value)
                .font(.system(size: 58, weight: .black, design: .rounded))
                .foregroundStyle(Color(red: 0.07, green: 0.10, blue: 0.16))
                .multilineTextAlignment(.center)
                .lineLimit(3)
                .minimumScaleFactor(0.5)
        }
    }
}

private struct MemoryGalleryAnswerTile: View {
    enum State {
        case idle
        case correct
        case incorrect
        case dimmed
    }

    let answer: MemoryAnimal
    let isFocused: Bool
    let state: State

    var body: some View {
        HStack(spacing: 18) {
            statusIcon

            Text(answerText)
                .font(.system(size: 35, weight: .black, design: .rounded))
                .foregroundStyle(foregroundColor)
                .lineLimit(2)
                .minimumScaleFactor(0.62)
                .multilineTextAlignment(.leading)

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 26)
        .padding(.vertical, 20)
        .frame(width: 390, height: 128, alignment: .leading)
        .background(backgroundStyle, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(strokeColor, lineWidth: 3)
        )
        .scaleEffect(isFocused ? 1.055 : 1.0)
        .opacity(state == .dimmed ? 0.45 : 1)
        .shadow(color: .black.opacity(isFocused ? 0.28 : 0.12), radius: isFocused ? 20 : 8, x: 0, y: isFocused ? 14 : 5)
        .animation(.spring(response: 0.26, dampingFraction: 0.78), value: isFocused)
        .animation(.easeInOut(duration: 0.16), value: state)
    }

    @ViewBuilder
    private var statusIcon: some View {
        switch state {
        case .correct:
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 34, weight: .black))
                .foregroundStyle(Color(red: 0.36, green: 0.63, blue: 0.30))
        case .incorrect:
            Image(systemName: "xmark.circle.fill")
                .font(.system(size: 34, weight: .black))
                .foregroundStyle(Color(red: 0.80, green: 0.28, blue: 0.22))
        case .idle, .dimmed:
            Image(systemName: "circle")
                .font(.system(size: 30, weight: .bold))
                .foregroundStyle(foregroundColor.opacity(0.72))
        }
    }

    private var answerText: String {
        switch answer.metadata.deck {
        case .countries, .countryFlags, .indiaStates:
            return answer.canonicalName
        default:
            return answer.name
        }
    }

    private var foregroundColor: Color {
        isFocused ? Color(red: 0.08, green: 0.12, blue: 0.18) : .white
    }

    private var strokeColor: Color {
        switch state {
        case .correct: return Color(red: 0.78, green: 0.94, blue: 0.66)
        case .incorrect: return Color(red: 1.0, green: 0.60, blue: 0.50)
        case .idle, .dimmed:
            return isFocused ? .white : .white.opacity(0.12)
        }
    }

    private var backgroundStyle: some ShapeStyle {
        if isFocused {
            return AnyShapeStyle(.white)
        }
        switch state {
        case .correct:
            return AnyShapeStyle(Color(red: 0.20, green: 0.50, blue: 0.32).opacity(0.82))
        case .incorrect:
            return AnyShapeStyle(Color(red: 0.52, green: 0.17, blue: 0.17).opacity(0.78))
        case .idle, .dimmed:
            return AnyShapeStyle(.white.opacity(0.08))
        }
    }
}

#Preview {
    MemoryGalleryTVView()
}
