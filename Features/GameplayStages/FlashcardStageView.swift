import SwiftUI

struct FlashcardStageView: View {
    let stage: GameplayStageDefinition
    let actions: GameplayStageFeedbackActions
    let compact: Bool
    let onComplete: ([ItemAttempt]) -> Void
    let onProgress: ([ItemAttempt], Data) -> Void
    @State private var viewModel: GameplayFlashcardStageViewModel
    @State private var lastSpokenCardID: String?
    @State private var showsPropertyExplorer = false
    let thread: GameplayThreadDefinition

    init(thread: GameplayThreadDefinition, stage: GameplayStageDefinition, round: GameplayRoundDefinition, actions: GameplayStageFeedbackActions, compact: Bool, stateData: Data? = nil, onProgress: @escaping ([ItemAttempt], Data) -> Void = { _, _ in }, onComplete: @escaping ([ItemAttempt]) -> Void) {
        self.stage = stage
        self.thread = thread
        self.actions = actions
        self.compact = compact
        self.onComplete = onComplete
        self.onProgress = onProgress
        _viewModel = State(initialValue: stateData.flatMap { try? JSONDecoder().decode(GameplayFlashcardStageViewModel.self, from: $0) } ?? GameplayFlashcardStageViewModel(thread: thread, round: round))
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
                        showsSubtitle: false,
                        prominence: .featured
                    )
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Open flashcard: \(card.title), \(card.subtitle)")

                Button(showsPropertyExplorer ? "Close clues" : "Explore more clues") {
                    showsPropertyExplorer.toggle()
                    if showsPropertyExplorer { actions.speak("Choose a clue to hear more.") }
                }
                .buttonStyle(GameplayStageControlButtonStyle(kind: .secondary, compact: compact))
                if showsPropertyExplorer, let entity = thread.entities.first(where: { $0.id == card.entityID }) {
                    ForEach(entity.properties) { property in
                        Button {
                            viewModel.markExposure()
                            actions.speak(property.value + ". " + property.explanation)
                        } label: {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(thread.propertyTypes.first { $0.id == property.typeID }?.displayName ?? "Clue").font(.headline)
                                Text(property.value).font(.subheadline)
                            }.frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .buttonStyle(GameplayStageControlButtonStyle(kind: .secondary, compact: compact))
                        .accessibilityLabel("Hear clue: " + property.value)
                    }
                }
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
                        showsPropertyExplorer = false
                        if viewModel.advance() {
                            onComplete(viewModel.evidence.attempts)
                        } else if let active = viewModel.activeCard {
                            viewModel.markExposure()
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
        .onChange(of: viewModel, initial: true) { _, value in
            if let data = try? JSONEncoder().encode(value) { onProgress(value.evidence.attempts, data) }
        }
    }

    private func speakActiveCardIfNeeded() {
        guard let card = viewModel.activeCard, lastSpokenCardID != card.id else { return }
        viewModel.markExposure()
        speak(card)
    }

    private func speak(_ card: GameplayDisplayItem) {
        lastSpokenCardID = card.id
        actions.speak(card.spokenText)
    }
}
