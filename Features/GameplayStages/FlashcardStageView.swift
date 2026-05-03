import SwiftUI

struct FlashcardStageView: View {
    let stage: GameplayStageDefinition
    let actions: GameplayStageFeedbackActions
    let compact: Bool
    let onComplete: (Int, Int, Int) -> Void
    @State private var viewModel: GameplayFlashcardStageViewModel

    init(thread: GameplayThreadDefinition, stage: GameplayStageDefinition, round: GameplayRoundDefinition, actions: GameplayStageFeedbackActions, compact: Bool, onComplete: @escaping (Int, Int, Int) -> Void) {
        self.stage = stage
        self.actions = actions
        self.compact = compact
        self.onComplete = onComplete
        _viewModel = State(initialValue: GameplayFlashcardStageViewModel(thread: thread, round: round))
    }

    var body: some View {
        VStack(spacing: compact ? 12 : 18) {
            GameplayStageTitle(stage: stage, detail: viewModel.progressText)
            if let card = viewModel.activeCard {
                GameplayDisplayCard(item: card, compact: compact)
                    .accessibilityLabel("Flashcard: \(card.title), \(card.subtitle)")
                HStack(spacing: 10) {
                    Button("Listen again") {
                        viewModel.markExposure()
                        actions.speak(card.spokenText)
                    }
                    .buttonStyle(GameplayStageControlButtonStyle(kind: .secondary, compact: compact))
                    .accessibilityLabel(viewModel.listenAgainAccessibilityLabel)

                    Button(viewModel.isLastCard ? "Finish stage" : "Next card") {
                        if viewModel.advance() {
                            onComplete(max(1, viewModel.cards.count), 0, 0)
                        } else if let active = viewModel.activeCard {
                            actions.speak(active.spokenText)
                        }
                    }
                    .buttonStyle(GameplayStageControlButtonStyle(kind: .primary, compact: compact))
                }
            }
        }
        .padding(compact ? 14 : 20)
        .background(GameplayStagePanel())
    }
}
