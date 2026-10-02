import SwiftUI

struct MultipleChoiceStageView: View {
    let stage: GameplayStageDefinition
    let attemptID: String
    let actions: GameplayStageFeedbackActions
    let compact: Bool
    let onComplete: ([ItemAttempt]) -> Void
    let onProgress: ([ItemAttempt], Data) -> Void
    @State private var viewModel: GameplayMultipleChoiceStageViewModel

    init(thread: GameplayThreadDefinition, stage: GameplayStageDefinition, round: GameplayRoundDefinition, attemptID: String, actions: GameplayStageFeedbackActions, compact: Bool, stateData: Data? = nil, onProgress: @escaping ([ItemAttempt], Data) -> Void = { _, _ in }, onComplete: @escaping ([ItemAttempt]) -> Void) {
        self.stage = stage
        self.attemptID = attemptID
        self.actions = actions
        self.compact = compact
        self.onComplete = onComplete
        self.onProgress = onProgress
        _viewModel = State(initialValue: stateData.flatMap { try? JSONDecoder().decode(GameplayMultipleChoiceStageViewModel.self, from: $0) } ?? GameplayMultipleChoiceStageViewModel(thread: thread, round: round))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: compact ? 12 : 18) {
            GameplayStageTitle(stage: stage, detail: viewModel.progressText)
            if let question = viewModel.activeQuestion {
                VStack(alignment: .leading, spacing: compact ? 10 : 14) {
                    Text(question.prompt)
                        .font(compact ? .title3.bold() : .title.bold())
                        .foregroundStyle(MatherTheme.ink)
                        .fixedSize(horizontal: false, vertical: true)
                        .accessibilityAddTraits(.isHeader)

                    ZStack {
                        LazyVGrid(columns: choiceColumns(for: question), spacing: 12) {
                            ForEach(question.choices) { choice in
                                Button {
                                    choose(choice)
                                } label: {
                                    GameplayDisplayCard(
                                        item: choice,
                                        compact: compact,
                                        showsSubtitle: viewModel.canAdvanceAfterCorrectChoice || viewModel.helpedChoiceID == choice.id,
                                        selected: viewModel.isSelectedIncorrect(choice) || viewModel.helpedChoiceID == choice.id,
                                        correct: viewModel.isSelectedCorrect(choice)
                                    )
                                }
                                .buttonStyle(.plain)
                                .disabled(viewModel.canAdvanceAfterCorrectChoice)
                                .accessibilityLabel(accessibilityLabel(for: choice))
                                .accessibilityHint(viewModel.isSelectedIncorrect(choice) ? "Try another answer." : "")
                            }
                        }


                    }

                    if let helpText = viewModel.helpText {
                        Text(helpText).font(.headline).foregroundStyle(MatherTheme.ink)
                    }
                    HStack(spacing: 12) {
                        Button("Listen again") { narrateQuestion() }
                            .buttonStyle(GameplayStageControlButtonStyle(kind: .secondary, compact: compact))
                        Button("Help me") { actions.speak(viewModel.showHelp()) }
                            .buttonStyle(GameplayStageControlButtonStyle(kind: .secondary, compact: compact))
                            .disabled(viewModel.canAdvanceAfterCorrectChoice)
                    }
                    if viewModel.canAdvanceAfterCorrectChoice {
                        Button(viewModel.activeIndex == viewModel.questions.count - 1 ? "Finish stage" : "Next question") {
                            if viewModel.advanceAfterCorrectChoice() { onComplete(viewModel.evidence.attempts) }
                        }
                        .buttonStyle(GameplayStageControlButtonStyle(kind: .primary, compact: compact))
                        .accessibilityIdentifier("MultipleChoiceNextButton")
                    }
                    if let selectedChoiceID = viewModel.selectedChoiceID {
                        let wasCorrect = viewModel.selectedChoiceWasCorrect == true
                        Text(wasCorrect ? "You found it!" : "Try that one again.")
                            .font(.headline.weight(.bold))
                            .foregroundStyle(wasCorrect ? MatherTheme.coral : MatherTheme.ink.opacity(0.72))
                            .fixedSize(horizontal: false, vertical: true)
                            .accessibilityIdentifier("MultipleChoiceFeedbackText")
                            .id(selectedChoiceID)
                    }
                }
            } else {
                Text("You explored these clues.")
                    .font(.headline)
                    .foregroundStyle(MatherTheme.ink)
                Button("Continue exploring") { onComplete(viewModel.evidence.attempts) }
                    .buttonStyle(GameplayStageControlButtonStyle(kind: .primary, compact: compact))
                    .accessibilityIdentifier("MultipleChoiceContinueExploringButton")
            }
        }
        .padding(compact ? 14 : 20)
        .background(GameplayStagePanel())
        .onAppear { narrateQuestion() }
        .onChange(of: viewModel.activeIndex) { _, _ in narrateQuestion() }
        .onChange(of: viewModel, initial: true) { _, value in
            if let data = try? JSONEncoder().encode(value) { onProgress(value.evidence.attempts, data) }
        }
    }

    private func choose(_ choice: GameplayDisplayItem) {
        let correct = viewModel.choose(choice)
        if correct {
            actions.success()
            let explanation = viewModel.activeQuestion.flatMap { viewModel.explanationsByItemID[$0.id] } ?? ""
            actions.speak("You found it! " + choice.title + ". " + explanation + " Continue when you’re ready.")
        } else {
            actions.failure()
            actions.speak("Try another answer. You can ask for help.")
        }
    }

    private func narrateQuestion() {
        guard let question = viewModel.activeQuestion else {
            actions.speak("You explored these clues. Tap Continue exploring when ready.")
            return
        }
        actions.speak(question.prompt + ". Choices: " + question.choices.map(\.title).joined(separator: ", "))
    }

    private func choiceColumns(for question: GameplayMultipleChoiceQuestion) -> [GridItem] {
        let hasLongChoice = question.choices.contains { choice in
            choice.title.count > (compact ? 14 : 24) || choice.subtitle.count > (compact ? 18 : 30)
        }
        if compact && hasLongChoice {
            return [GridItem(.flexible(), spacing: 12)]
        }
        return [
            GridItem(.flexible(), spacing: 12),
            GridItem(.flexible(), spacing: 12)
        ]
    }

    private func accessibilityLabel(for choice: GameplayDisplayItem) -> String {
        let label = [choice.title, choice.subtitle]
            .filter { !$0.isEmpty }
            .joined(separator: ", ")
        return label.isEmpty ? "Choice" : "Choice: \(label)"
    }
}

private struct MultipleChoiceCorrectCelebration: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let compact: Bool

    var body: some View {
        ZStack {
            Circle()
                .fill(MatherTheme.warm.opacity(0.86))
                .frame(width: compact ? 112 : 142, height: compact ? 112 : 142)
            Image(systemName: "sparkles")
                .font(.system(size: compact ? 48 : 62, weight: .black, design: .rounded))
                .foregroundStyle(MatherTheme.coral)
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: compact ? 34 : 42, weight: .black, design: .rounded))
                .foregroundStyle(MatherTheme.accent)
                .offset(x: compact ? 38 : 48, y: compact ? 34 : 42)
        }
        .shadow(color: MatherTheme.coral.opacity(0.22), radius: 18, x: 0, y: 10)
        .scaleEffect(reduceMotion ? 1 : 1.08)
        .animation(reduceMotion ? nil : .spring(response: 0.26, dampingFraction: 0.58), value: reduceMotion)
    }
}
