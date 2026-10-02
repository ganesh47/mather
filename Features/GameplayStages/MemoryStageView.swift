import SwiftUI

struct MemoryStageView: View {
    let stage: GameplayStageDefinition
    let actions: GameplayStageFeedbackActions
    let compact: Bool
    let onComplete: ([ItemAttempt]) -> Void
    let onProgress: ([ItemAttempt], Data) -> Void
    @State private var viewModel: GameplayMatchStageViewModel

    init(thread: GameplayThreadDefinition, stage: GameplayStageDefinition, round: GameplayRoundDefinition, actions: GameplayStageFeedbackActions, compact: Bool, stateData: Data? = nil, onProgress: @escaping ([ItemAttempt], Data) -> Void = { _, _ in }, onComplete: @escaping ([ItemAttempt]) -> Void) {
        self.stage = stage
        self.actions = actions
        self.compact = compact
        self.onComplete = onComplete
        self.onProgress = onProgress
        _viewModel = State(initialValue: stateData.flatMap { try? JSONDecoder().decode(GameplayMatchStageViewModel.self, from: $0) } ?? GameplayMatchStageViewModel(thread: thread, round: round, mode: .easyMemory, turnItemCount: stage.recommendedTurnItemCount))
    }

    var body: some View {
        GameplayPairingStageShell(
            title: stage.title,
            prompt: stage.prompt,
            compact: compact,
            showsStagePrompt: GameplayStageRenderSupport.showsStagePrompt(kind: stage.kind, compact: compact),
            viewModel: $viewModel,
            actions: actions,
            onComplete: onComplete
        )
        .onChange(of: viewModel, initial: true) { _, value in
            if let data = try? JSONEncoder().encode(value) { onProgress(value.evidence.attempts, data) }
        }
    }
}
