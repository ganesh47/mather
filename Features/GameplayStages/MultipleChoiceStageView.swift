import SwiftUI

struct MultipleChoiceStageView: View {
    let stage: GameplayStageDefinition
    let actions: GameplayStageFeedbackActions
    let compact: Bool
    let onComplete: (Int, Int, Int) -> Void
    @State private var viewModel: GameplayMultipleChoiceStageViewModel

    init(thread: GameplayThreadDefinition, stage: GameplayStageDefinition, round: GameplayRoundDefinition, actions: GameplayStageFeedbackActions, compact: Bool, onComplete: @escaping (Int, Int, Int) -> Void) {
        self.stage = stage
        self.actions = actions
        self.compact = compact
        self.onComplete = onComplete
        _viewModel = State(initialValue: GameplayMultipleChoiceStageViewModel(thread: thread, round: round))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: compact ? 12 : 18) {
            GameplayStageTitle(stage: stage, detail: viewModel.progressText)
            if let question = viewModel.activeQuestion {
                Text(question.prompt)
                    .font(compact ? .title3.bold() : .title.bold())
                    .foregroundStyle(MatherTheme.ink)
                    .accessibilityAddTraits(.isHeader)
                LazyVGrid(columns: [GridItem(.adaptive(minimum: compact ? 142 : 190), spacing: 12)], spacing: 12) {
                    ForEach(question.choices) { choice in
                        Button {
                            let correct = viewModel.choose(choice)
                            if correct { actions.success() } else { actions.failure() }
                            if viewModel.isComplete { onComplete(viewModel.correctCount, viewModel.mistakeCount, 0) }
                        } label: {
                            GameplayDisplayCard(item: choice, compact: compact, showsSubtitle: true)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Choice: \(choice.title), \(choice.subtitle)")
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
    }
}
