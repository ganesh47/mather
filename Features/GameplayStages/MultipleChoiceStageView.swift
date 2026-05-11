import SwiftUI

struct MultipleChoiceStageView: View {
    let stage: GameplayStageDefinition
    let actions: GameplayStageFeedbackActions
    let compact: Bool
    let onComplete: (Int, Int, Int) -> Void
    @State private var viewModel: GameplayMultipleChoiceStageViewModel
    @State private var celebratingChoiceID: String?

    init(thread: GameplayThreadDefinition, stage: GameplayStageDefinition, round: GameplayRoundDefinition, actions: GameplayStageFeedbackActions, compact: Bool, onComplete: @escaping (Int, Int, Int) -> Void) {
        self.stage = stage
        self.actions = actions
        self.compact = compact
        self.onComplete = onComplete
        _viewModel = State(initialValue: GameplayMultipleChoiceStageViewModel(thread: thread, round: round))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: compact ? 12 : 18) {
            GameplayStageTitle(stage: stage, detail: viewModel.progressText, compact: compact)
            if let question = viewModel.activeQuestion {
                Text(question.prompt)
                    .font(compact ? .title3.bold() : .title.bold())
                    .foregroundStyle(MatherTheme.ink)
                    .accessibilityAddTraits(.isHeader)
                LazyVGrid(columns: [GridItem(.adaptive(minimum: compact ? 142 : 190), spacing: 12)], spacing: 12) {
                    ForEach(question.choices) { choice in
                        Button {
                            handleChoice(choice)
                        } label: {
                            GameplayDisplayCard(
                                item: choice,
                                compact: compact,
                                showsSubtitle: !compact,
                                selected: viewModel.selectedChoiceID == choice.id,
                                correct: celebratingChoiceID == choice.id
                            )
                        }
                        .buttonStyle(.plain)
                        .disabled(viewModel.selectedChoiceIsCorrect)
                        .accessibilityLabel("Choice: \(choice.title), \(choice.subtitle)")
                    }
                }
                if let selectedChoiceID = viewModel.selectedChoiceID,
                   let selected = question.choices.first(where: { $0.id == selectedChoiceID }) {
                    Text(question.isCorrect(selected) ? "Nice — next question coming up!" : "Try again — choose a different card.")
                        .font(.caption.weight(.black))
                        .foregroundStyle(question.isCorrect(selected) ? MatherTheme.accent : MatherTheme.coral)
                        .accessibilityIdentifier("MultipleChoiceStageFeedback")
                }
            } else {
                Text("Quiz complete")
                    .font(.headline)
                    .foregroundStyle(MatherTheme.ink)
            }
        }
        .padding(compact ? 14 : 20)
        .background(GameplayStagePanel())
    }

    private func handleChoice(_ choice: GameplayDisplayItem) {
        let correct = viewModel.choose(choice)
        if correct {
            actions.success()
            celebratingChoiceID = choice.id
            Task { @MainActor in
                try? await Task.sleep(nanoseconds: 550_000_000)
                guard celebratingChoiceID == choice.id else { return }
                viewModel.advanceAfterCorrectAnswer()
                celebratingChoiceID = nil
                if viewModel.isComplete { onComplete(viewModel.correctCount, viewModel.mistakeCount, 0) }
            }
        } else {
            actions.failure()
        }
    }
}
