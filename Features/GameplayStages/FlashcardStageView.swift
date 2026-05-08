import SwiftUI

struct FlashcardStageView: View {
    let stage: GameplayStageDefinition
    let actions: GameplayStageFeedbackActions
    let compact: Bool
    let onComplete: (Int, Int, Int) -> Void
    @State private var viewModel: GameplayFlashcardStageViewModel
    @State private var lastSpokenCardID: String?

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
                Button {
                    viewModel.markExposure()
                    speak(card)
                } label: {
                    GameplayDisplayCard(
                        item: card,
                        compact: compact,
                        prominence: card.isFruitCard || viewModel.cards.count == 1 ? .featured : .normal
                    )
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Open flashcard: \(card.title), \(card.subtitle)")

                VStack(spacing: 8) {
                    Text(viewModel.activeDiscoveryPrompt)
                        .font(.caption.weight(.bold))
                        .foregroundStyle(MatherTheme.ink.opacity(0.72))
                        .multilineTextAlignment(.center)

                    Button(viewModel.spottedActiveCard ? viewModel.spottedFeedbackText : "I spotted it!") {
                        viewModel.markActiveCardSpotted()
                    }
                    .buttonStyle(GameplayStageControlButtonStyle(kind: viewModel.spottedActiveCard ? .secondary : .primary, compact: compact))
                    .accessibilityLabel(viewModel.spottedActiveCard ? viewModel.spottedFeedbackText : "Mark \(card.title) clue spotted")
                }

                HStack(spacing: 10) {
                    Button("Listen again") {
                        viewModel.markExposure()
                        speak(card)
                    }
                    .buttonStyle(GameplayStageControlButtonStyle(kind: .secondary, compact: compact))
                    .accessibilityLabel(viewModel.listenAgainAccessibilityLabel)

                    Button(viewModel.isLastCard ? "Finish stage" : "Next card") {
                        if viewModel.advance() {
                            onComplete(max(1, viewModel.cards.count), 0, 0)
                        } else if let active = viewModel.activeCard {
                            speak(active)
                        }
                    }
                    .buttonStyle(GameplayStageControlButtonStyle(kind: .primary, compact: compact))
                }
            }
        }
        .padding(compact ? 14 : 20)
        .background(GameplayStagePanel())
        .onAppear { speakActiveCardIfNeeded() }
    }

    private func speakActiveCardIfNeeded() {
        guard let card = viewModel.activeCard, lastSpokenCardID != card.id else { return }
        speak(card)
    }

    private func speak(_ card: GameplayDisplayItem) {
        lastSpokenCardID = card.id
        actions.speak(card.spokenText)
    }
}
