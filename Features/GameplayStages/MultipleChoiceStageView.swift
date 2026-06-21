import SwiftUI

struct MultipleChoiceStageView: View {
    let stage: GameplayStageDefinition
    let attemptID: String
    let actions: GameplayStageFeedbackActions
    let compact: Bool
    let onComplete: (Int, Int, Int) -> Void
    @State private var viewModel: GameplayMultipleChoiceStageViewModel
    @State private var showCorrectCelebration = false
    @State private var delayedAdvanceTask: Task<Void, Never>?

    init(thread: GameplayThreadDefinition, stage: GameplayStageDefinition, round: GameplayRoundDefinition, attemptID: String, actions: GameplayStageFeedbackActions, compact: Bool, onComplete: @escaping (Int, Int, Int) -> Void) {
        self.stage = stage
        self.attemptID = attemptID
        self.actions = actions
        self.compact = compact
        self.onComplete = onComplete
        _viewModel = State(initialValue: GameplayMultipleChoiceStageViewModel(thread: thread, round: round))
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
                                        showsSubtitle: true,
                                        selected: viewModel.isSelectedIncorrect(choice),
                                        correct: viewModel.isSelectedCorrect(choice)
                                    )
                                }
                                .buttonStyle(.plain)
                                .disabled(viewModel.canAdvanceAfterCorrectChoice)
                                .accessibilityLabel(accessibilityLabel(for: choice))
                                .accessibilityHint(viewModel.isSelectedIncorrect(choice) ? "Try another answer." : "")
                            }
                        }

                        if showCorrectCelebration {
                            MultipleChoiceCorrectCelebration(compact: compact)
                                .transition(.scale.combined(with: .opacity))
                                .accessibilityHidden(true)
                        }
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
                Text("Quiz complete")
                    .font(.headline)
                    .foregroundStyle(MatherTheme.ink)
            }
        }
        .padding(compact ? 14 : 20)
        .background(GameplayStagePanel())
        .onDisappear {
            cancelDelayedAdvance()
        }
    }

    @MainActor
    private func choose(_ choice: GameplayDisplayItem) {
        cancelDelayedAdvance()
        let correct = viewModel.choose(choice)
        if correct {
            actions.success()
            withAnimation(.spring(response: 0.28, dampingFraction: 0.64)) {
                showCorrectCelebration = true
            }
            let taskAttemptID = attemptID
            delayedAdvanceTask = Task { @MainActor in
                try? await Task.sleep(nanoseconds: 850_000_000)
                guard !Task.isCancelled, taskAttemptID == attemptID else { return }
                withAnimation(.easeOut(duration: 0.16)) {
                    showCorrectCelebration = false
                }
                guard !Task.isCancelled, taskAttemptID == attemptID else { return }
                if viewModel.advanceAfterCorrectChoice() {
                    onComplete(viewModel.correctCount, viewModel.mistakeCount, 0)
                }
                delayedAdvanceTask = nil
            }
        } else {
            showCorrectCelebration = false
            actions.failure()
        }
    }

    @MainActor
    private func cancelDelayedAdvance() {
        delayedAdvanceTask?.cancel()
        delayedAdvanceTask = nil
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
