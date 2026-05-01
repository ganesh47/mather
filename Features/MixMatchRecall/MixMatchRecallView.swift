import SwiftUI

enum LearningCardDisplay: Equatable, Hashable {
    case emoji(String)
    case asset(String)
    case text(String)
    case choice(String)
}

struct LearningCardViewModel: Identifiable, Equatable, Hashable {
    let id: String
    let display: LearningCardDisplay
    let accessibilityLabel: String
    let accessibilityHint: String?
    var isFaceDown: Bool
    var isSelected: Bool
    var isMatched: Bool
    var isIncorrect: Bool

    init(
        id: String,
        display: LearningCardDisplay,
        accessibilityLabel: String,
        accessibilityHint: String? = nil,
        isFaceDown: Bool = false,
        isSelected: Bool = false,
        isMatched: Bool = false,
        isIncorrect: Bool = false
    ) {
        self.id = id
        self.display = display
        self.accessibilityLabel = accessibilityLabel
        self.accessibilityHint = accessibilityHint
        self.isFaceDown = isFaceDown
        self.isSelected = isSelected
        self.isMatched = isMatched
        self.isIncorrect = isIncorrect
    }
}

struct MixMatchRecallChoice: Identifiable, Equatable, Hashable {
    let id: String
    let card: LearningCardViewModel
    let isCorrect: Bool

    init(id: String, card: LearningCardViewModel, isCorrect: Bool) {
        self.id = id
        self.card = card
        self.isCorrect = isCorrect
    }
}

struct MixMatchRecallAttempt: Equatable {
    let choiceID: String
    let isCorrect: Bool
}

struct MixMatchRecallChoiceEvaluator: Equatable {
    let correctChoiceIDs: Set<String>

    init(correctChoiceIDs: Set<String>) {
        self.correctChoiceIDs = correctChoiceIDs
    }

    func attempt(choiceID: String) -> MixMatchRecallAttempt {
        MixMatchRecallAttempt(choiceID: choiceID, isCorrect: correctChoiceIDs.contains(choiceID))
    }
}

struct MixMatchRecallFeedbackState: Equatable {
    private(set) var selectedChoiceID: String?
    private(set) var matchedChoiceID: String?
    private(set) var incorrectChoiceID: String?
    private(set) var isResolving = false

    var hasActiveFeedback: Bool {
        selectedChoiceID != nil || matchedChoiceID != nil || incorrectChoiceID != nil || isResolving
    }

    mutating func markAttempt(_ attempt: MixMatchRecallAttempt) {
        selectedChoiceID = attempt.choiceID
        isResolving = true
        if attempt.isCorrect {
            matchedChoiceID = attempt.choiceID
            incorrectChoiceID = nil
        } else {
            matchedChoiceID = nil
            incorrectChoiceID = attempt.choiceID
        }
    }

    mutating func clear() {
        selectedChoiceID = nil
        matchedChoiceID = nil
        incorrectChoiceID = nil
        isResolving = false
    }
}

extension LearningCard {
    var mixMatchPromptCard: LearningCardViewModel {
        let display: LearningCardDisplay
        if let assetName = prompt.assetName {
            display = .asset(assetName)
        } else if let displayText = prompt.displayText {
            display = .text(displayText)
        } else {
            display = .text(prompt.speechText)
        }

        return LearningCardViewModel(
            id: "\(id).prompt",
            display: display,
            accessibilityLabel: prompt.speechText,
            accessibilityHint: "Choose the matching answer."
        )
    }

    var mixMatchChoices: [MixMatchRecallChoice] {
        choices.map { choice in
            MixMatchRecallChoice(
                id: choice.id,
                card: LearningCardViewModel(
                    id: choice.id,
                    display: .choice(choice.answer.displayText ?? choice.answer.speechText),
                    accessibilityLabel: choice.answer.speechText,
                    accessibilityHint: "Answer choice."
                ),
                isCorrect: choice.isCorrect
            )
        }
    }
}

@MainActor
struct LearningCardView: View {
    @Environment(\.colorScheme) private var colorScheme
    let model: LearningCardViewModel
    var minTouchSize: CGFloat = 80

    var body: some View {
        GeometryReader { proxy in
            let cardHeight = max(proxy.size.height, minTouchSize)

            ZStack {
                if model.isFaceDown {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(LinearGradient(colors: [MatherTheme.accent.opacity(0.72), MatherTheme.softBlue.opacity(0.70)], startPoint: .topLeading, endPoint: .bottomTrailing))
                    Text("?")
                        .font(.system(size: min(48, max(34, cardHeight * 0.34)), weight: .black, design: .rounded))
                        .foregroundStyle(.white.opacity(0.72))
                } else {
                    cardFace(cardHeight: cardHeight)
                }
            }
            .frame(minWidth: minTouchSize, minHeight: minTouchSize)
            .contentShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(borderColor, lineWidth: model.isSelected || model.isIncorrect ? 3 : 2)
            )
            .scaleEffect(model.isMatched ? 0.92 : 1.0)
            .opacity(model.isMatched ? 0.68 : 1.0)
            .rotationEffect(model.isIncorrect ? .degrees(-3) : .zero)
            .animation(.spring(response: 0.25, dampingFraction: 0.6), value: model.isSelected)
            .animation(.easeOut(duration: 0.3), value: model.isMatched)
            .animation(model.isIncorrect ? .easeInOut(duration: 0.08).repeatCount(3, autoreverses: true) : .default, value: model.isIncorrect)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(model.accessibilityLabel))
        .accessibilityHint(Text(model.accessibilityHint ?? ""))
    }

    private var borderColor: Color {
        if model.isIncorrect { return MatherTheme.danger }
        if model.isSelected { return MatherTheme.accent }
        if model.isMatched { return .green }
        return .clear
    }

    @ViewBuilder
    private func cardFace(cardHeight: CGFloat) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(backgroundGradient)

            Circle()
                .fill(Color.white.opacity(colorScheme == .dark ? 0.08 : 0.24))
                .frame(width: cardHeight * 0.72, height: cardHeight * 0.72)
                .offset(x: cardHeight * 0.16, y: -cardHeight * 0.18)

            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.white.opacity(colorScheme == .dark ? 0.08 : 0.16))
                .frame(width: cardHeight * 0.52, height: cardHeight * 0.16)
                .offset(x: -cardHeight * 0.14, y: cardHeight * 0.24)
                .rotationEffect(.degrees(-10))

            displayContent(cardHeight: cardHeight)
                .padding(8)
        }
    }

    private var backgroundGradient: LinearGradient {
        let colors: [Color]
        if model.isMatched {
            colors = [Color.green.opacity(0.24), Color.green.opacity(0.10)]
        } else {
            colors = [MatherTheme.panel.opacity(0.28), MatherTheme.softBlue.opacity(0.18)]
        }
        return LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing)
    }

    @ViewBuilder
    private func displayContent(cardHeight: CGFloat) -> some View {
        switch model.display {
        case .emoji(let emoji):
            Text(emoji)
                .font(.system(size: min(58, max(34, cardHeight * 0.42))))
                .shadow(color: .black.opacity(0.10), radius: 3, y: 2)
        case .asset(let assetName):
            Image(assetName)
                .resizable()
                .scaledToFit()
                .shadow(color: .black.opacity(0.08), radius: 3, y: 2)
                .padding(4)
        case .text(let value), .choice(let value):
            Text(value)
                .font(.system(size: min(24, max(16, cardHeight * 0.18)), weight: .black, design: .rounded))
                .foregroundStyle(MatherTheme.ink)
                .multilineTextAlignment(.center)
                .lineLimit(3)
                .minimumScaleFactor(0.55)
                .allowsTightening(true)
                .padding(10)
        }
    }
}

@MainActor
struct MixMatchRecallView: View {
    private static let correctFeedbackDuration: Duration = .milliseconds(520)
    private static let incorrectFeedbackDuration: Duration = .milliseconds(420)

    let prompt: LearningCardViewModel?
    let choices: [MixMatchRecallChoice]
    private let evaluator: MixMatchRecallChoiceEvaluator
    let onCorrect: (MixMatchRecallAttempt) -> Void
    let onIncorrect: (MixMatchRecallAttempt) -> Void
    @State private var feedback = MixMatchRecallFeedbackState()
    @State private var feedbackTask: Task<Void, Never>?

    init(
        prompt: LearningCardViewModel? = nil,
        choices: [MixMatchRecallChoice],
        onCorrect: @escaping (MixMatchRecallAttempt) -> Void,
        onIncorrect: @escaping (MixMatchRecallAttempt) -> Void
    ) {
        self.prompt = prompt
        self.choices = choices
        self.evaluator = MixMatchRecallChoiceEvaluator(correctChoiceIDs: Set(choices.filter(\.isCorrect).map(\.id)))
        self.onCorrect = onCorrect
        self.onIncorrect = onIncorrect
    }

    init(
        learningCard: LearningCard,
        onCorrect: @escaping (MixMatchRecallAttempt) -> Void,
        onIncorrect: @escaping (MixMatchRecallAttempt) -> Void
    ) {
        self.init(
            prompt: learningCard.mixMatchPromptCard,
            choices: learningCard.mixMatchChoices,
            onCorrect: onCorrect,
            onIncorrect: onIncorrect
        )
    }

    var body: some View {
        VStack(spacing: 16) {
            if let prompt {
                LearningCardView(model: prompt)
                    .frame(minHeight: 112)
                    .accessibilityIdentifier("mix-match-prompt-card")
            }

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 112), spacing: 12)], spacing: 12) {
                ForEach(choices) { choice in
                    Button {
                        handleChoice(choice)
                    } label: {
                        LearningCardView(model: feedbackCard(for: choice), minTouchSize: 80)
                            .frame(minHeight: 96)
                    }
                    .buttonStyle(.plain)
                    .disabled(feedback.isResolving)
                    .accessibilityIdentifier("mix-match-choice-\(choice.id)")
                    .accessibilityAddTraits(.isButton)
                }
            }
        }
        .onDisappear {
            feedbackTask?.cancel()
        }
    }

    private func feedbackCard(for choice: MixMatchRecallChoice) -> LearningCardViewModel {
        var card = choice.card
        card.isSelected = feedback.selectedChoiceID == choice.id
        card.isMatched = feedback.matchedChoiceID == choice.id
        card.isIncorrect = feedback.incorrectChoiceID == choice.id
        return card
    }

    private func handleChoice(_ choice: MixMatchRecallChoice) {
        guard !feedback.isResolving else { return }
        let attempt = evaluator.attempt(choiceID: choice.id)
        feedbackTask?.cancel()

        withAnimation(.spring(response: 0.25, dampingFraction: 0.62)) {
            feedback.markAttempt(attempt)
        }

        let feedbackDuration = attempt.isCorrect
            ? Self.correctFeedbackDuration
            : Self.incorrectFeedbackDuration

        feedbackTask = Task { @MainActor in
            do {
                try await Task.sleep(for: feedbackDuration)
            } catch {
                return
            }

            if attempt.isCorrect {
                onCorrect(attempt)
            } else {
                onIncorrect(attempt)
            }

            withAnimation(.easeOut(duration: 0.12)) {
                feedback.clear()
            }
        }
    }
}
