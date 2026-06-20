import SwiftUI

struct MemoryGalleryTVView: View {
    @FocusState private var focusedCategory: MemoryGalleryTVCategory.ID?
    @FocusState private var focusedAnswerID: String?
    @FocusState private var nextButtonFocused: Bool

    @State private var selectedCategory: MemoryGalleryTVCategory = .animals
    @State private var roundIndex = 0
    @State private var selectedAnswerID: String?
    @State private var correctCount = 0

    private var round: MemoryGalleryTVRound {
        MemoryGalleryTVRound.make(category: selectedCategory, index: roundIndex)
    }

    private var answeredCorrectly: Bool {
        MemoryGalleryTVRound.isCorrect(selectionID: selectedAnswerID, for: round)
    }

    var body: some View {
        ZStack {
            MatherTVBackdrop()

            VStack(alignment: .leading, spacing: 34) {
                header
                categoryShelf
                roundStage
            }
            .frame(maxWidth: 1680, maxHeight: .infinity, alignment: .topLeading)
            .padding(.horizontal, 90)
            .padding(.vertical, 66)
        }
        .onAppear {
            focusedCategory = selectedCategory.id
        }
    }

    private var header: some View {
        HStack(alignment: .bottom) {
            VStack(alignment: .leading, spacing: 12) {
                Text("Memory Gallery")
                    .font(.system(size: 70, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .accessibilityIdentifier("tv-memory-gallery-title")

                Text(round.category.prompt)
                    .font(.system(size: 30, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.74))
                    .accessibilityIdentifier("tv-memory-gallery-prompt")
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Memory Gallery. \(round.category.prompt)")

            Spacer(minLength: 24)

            VStack(alignment: .trailing, spacing: 8) {
                Text("\(correctCount)")
                    .font(.system(size: 60, weight: .black, design: .rounded))
                    .foregroundStyle(Color(red: 0.78, green: 0.94, blue: 0.66))

                Text("matched")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.62))
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("\(correctCount) matched")
        }
    }

    private var categoryShelf: some View {
        HStack(spacing: 22) {
            ForEach(MemoryGalleryTVCategory.allCases) { category in
                Button {
                    selectCategory(category)
                } label: {
                    MemoryGalleryCategoryTile(
                        category: category,
                        isFocused: focusedCategory == category.id,
                        isSelected: selectedCategory == category
                    )
                }
                .buttonStyle(.plain)
                .focused($focusedCategory, equals: category.id)
                .accessibilityLabel("\(category.title), \(category.subtitle)")
                .accessibilityHint("Selects the \(category.title) memory category.")
                .accessibilityIdentifier("tv-memory-category-\(category.id)")
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Category shelf")
    }

    private var roundStage: some View {
        HStack(alignment: .top, spacing: 42) {
            promptPanel

            VStack(alignment: .leading, spacing: 22) {
                Text("Choose the matching name")
                    .font(.system(size: 32, weight: .black, design: .rounded))
                    .foregroundStyle(.white)

                answerGrid

                feedbackBar
            }
            .frame(maxWidth: .infinity, alignment: .topLeading)
        }
    }

    private var promptPanel: some View {
        VStack(alignment: .leading, spacing: 26) {
            Text("Picture")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundStyle(Color(red: 0.55, green: 0.88, blue: 1.0))

            MemoryGalleryPromptArtwork(animal: round.promptCard)
                .frame(width: 520, height: 360)
                .accessibilityHidden(true)

            Text(accessibilityName(for: round.promptCard))
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundStyle(.white.opacity(0.44))
                .lineLimit(1)
                .opacity(selectedAnswerID == nil ? 0 : 1)
        }
        .padding(36)
        .frame(width: 600, height: 560, alignment: .leading)
        .background(.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 30, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .stroke(.white.opacity(0.14), lineWidth: 1)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Picture prompt. \(promptAccessibilityLabel(for: round.promptCard)).")
        .accessibilityHint("Move right to choose the matching name.")
        .accessibilityIdentifier("tv-memory-picture-prompt")
    }

    private var answerGrid: some View {
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
                        state: answerState(for: answer)
                    )
                }
                .buttonStyle(.plain)
                .focused($focusedAnswerID, equals: answer.id)
                .disabled(selectedAnswerID != nil)
                .accessibilityLabel(accessibilityName(for: answer))
                .accessibilityHint("Select to match this name with the picture.")
                .accessibilityIdentifier("tv-memory-answer-\(answer.id)")
            }
        }
    }

    @ViewBuilder
    private var feedbackBar: some View {
        if let selectedAnswerID {
            HStack(spacing: 20) {
                Image(systemName: answeredCorrectly ? "checkmark.circle.fill" : "arrow.uturn.backward.circle.fill")
                    .font(.system(size: 38, weight: .bold))
                    .foregroundStyle(answeredCorrectly ? Color(red: 0.78, green: 0.94, blue: 0.66) : Color(red: 1.0, green: 0.78, blue: 0.42))

                VStack(alignment: .leading, spacing: 4) {
                    Text(answeredCorrectly ? "Matched!" : "Try the next picture")
                        .font(.system(size: 28, weight: .black, design: .rounded))
                        .foregroundStyle(.white)

                    Text(answeredCorrectly ? "That was \(accessibilityName(for: round.promptCard))." : "The answer was \(accessibilityName(for: round.promptCard)).")
                        .font(.system(size: 22, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.68))
                }

                Spacer(minLength: 18)

                Button {
                    nextRound()
                } label: {
                    Label("Next picture", systemImage: "forward.fill")
                        .font(.system(size: 24, weight: .black, design: .rounded))
                        .padding(.horizontal, 24)
                        .padding(.vertical, 18)
                }
                .buttonStyle(.plain)
                .focused($nextButtonFocused)
                .background(nextButtonFocused ? .white : Color(red: 0.55, green: 0.88, blue: 1.0).opacity(0.20), in: Capsule())
                .foregroundStyle(nextButtonFocused ? Color(red: 0.07, green: 0.10, blue: 0.16) : .white)
                .accessibilityIdentifier("tv-memory-next-picture")
            }
            .padding(24)
            .frame(width: 802)
            .frame(minHeight: 120)
            .background(.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 26, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 26, style: .continuous)
                    .stroke(.white.opacity(0.14), lineWidth: 1)
            )
            .accessibilityElement(children: .combine)
            .accessibilityLabel(feedbackAccessibilityLabel(selectedAnswerID: selectedAnswerID))
        } else {
            Text("No timer. Take your time and press select when the focused name matches the picture.")
                .font(.system(size: 22, weight: .semibold, design: .rounded))
                .foregroundStyle(.white.opacity(0.58))
                .frame(width: 802, alignment: .leading)
                .frame(minHeight: 120, alignment: .leading)
                .accessibilityIdentifier("tv-memory-no-timer-copy")
        }
    }

    private func selectCategory(_ category: MemoryGalleryTVCategory) {
        selectedCategory = category
        roundIndex = 0
        selectedAnswerID = nil
        focusedCategory = category.id
    }

    private func choose(_ answer: MemoryAnimal) {
        selectedAnswerID = answer.id
        if answer.id == round.correctAnswerID {
            correctCount += 1
        }
        nextButtonFocused = true
    }

    private func nextRound() {
        let nextIndex = roundIndex + 1
        let nextRound = MemoryGalleryTVRound.make(category: selectedCategory, index: nextIndex)
        roundIndex = nextIndex
        selectedAnswerID = nil
        focusedAnswerID = nextRound.answerChoices.first?.id
        nextButtonFocused = false
    }

    private func answerState(for answer: MemoryAnimal) -> MemoryGalleryAnswerTile.State {
        guard let selectedAnswerID else { return .idle }
        if answer.id == round.correctAnswerID { return .correct }
        if answer.id == selectedAnswerID { return .incorrect }
        return .dimmed
    }

    private func feedbackAccessibilityLabel(selectedAnswerID: String) -> String {
        if selectedAnswerID == round.correctAnswerID {
            return "Correct. \(accessibilityName(for: round.promptCard)) matched."
        }
        return "Not a match. The correct answer was \(accessibilityName(for: round.promptCard))."
    }

    private func promptAccessibilityLabel(for animal: MemoryAnimal) -> String {
        switch animal.metadata.deck {
        case .countryFlags:
            return "Flag picture. Match it to the country name."
        default:
            return "Picture of \(accessibilityName(for: animal))."
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
    let animal: MemoryAnimal

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
        switch animal.picture {
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
