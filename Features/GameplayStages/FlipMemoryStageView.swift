import SwiftUI

struct FlipMemoryStageView: View {
    let stage: GameplayStageDefinition
    let actions: GameplayStageFeedbackActions
    let compact: Bool
    let onComplete: (Int, Int, Int) -> Void
    @State private var viewModel: GameplayMatchStageViewModel

    init(thread: GameplayThreadDefinition, stage: GameplayStageDefinition, round: GameplayRoundDefinition, actions: GameplayStageFeedbackActions, compact: Bool, onComplete: @escaping (Int, Int, Int) -> Void) {
        self.stage = stage
        self.actions = actions
        self.compact = compact
        self.onComplete = onComplete
        _viewModel = State(initialValue: GameplayMatchStageViewModel(thread: thread, round: round, mode: .flipMemory))
    }

    var body: some View {
        GameplayPairingStageShell(title: stage.title, prompt: "Pick a card, then find its hidden match.", compact: compact, viewModel: $viewModel, actions: actions, onComplete: onComplete)
    }
}
